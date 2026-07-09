// supabase/functions/cleanup-anonymous/index.ts
//
// 아가왜울어 — 유휴 익명 계정 정리 Edge Function (설계서 §3.3)
//
// 목적: 게스트 우선 정책상 앱은 부팅 시 익명(anonymous) 로그인을 생성한다. 앱을 한 번만
//   열고 이탈한 유저의 익명 계정이 누적되면 auth.users 가 무한히 불어난다. 이 함수는
//   is_anonymous = true 이면서 마지막 활동이 90일을 초과한 익명 유저를 파기한다.
//   개인 데이터(babies·tracking_logs·favorites 등)는 user_id FK 의 on delete cascade
//   (0001_schema.sql·0002_rls.sql)로 함께 삭제되므로 별도 정리 로직이 필요 없다.
//
// 트리거: pg_cron (주 1회) 또는 수동 curl 호출 (README 참고).
//
// 호출 보호: refresh-products 와 동일 패턴 — Authorization 헤더(`Bearer ` 제거 후)가
//   CRON_SECRET 과 상수시간 비교로 일치할 때만 실행한다(`--no-verify-jwt` 로 배포).
//   ★ 이 함수는 auth.admin.deleteUser 로 계정을 파기하므로 반드시 CRON_SECRET 뒤에
//     둔다. delete-account 와 달리 "본인 JWT" 가 아니라 서버 공유 비밀로 보호한다.
//
// 비밀값: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 는 Edge 런타임에 자동 주입된다.
//   service_role 키는 절대 클라이언트로 내려보내지 않는다.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

// ─── 상수 ────────────────────────────────────────────────────────────────
// 마지막 활동 후 이 일수를 초과한 익명 계정을 삭제 대상으로 본다.
const INACTIVE_DAYS = Number(Deno.env.get("CLEANUP_INACTIVE_DAYS") ?? "90");
const INACTIVE_MS = INACTIVE_DAYS * 24 * 60 * 60 * 1000;
// listUsers 페이지 크기(Admin API 최대치는 프로젝트 설정에 따름 — 안전하게 200).
const PER_PAGE = 200;
// 안전장치: 한 번의 호출에서 삭제할 최대 계정 수(폭주 방지). 초과분은 다음 실행에서 처리.
const MAX_DELETIONS = Number(Deno.env.get("CLEANUP_MAX_DELETIONS") ?? "500");

// ─── 유틸 ────────────────────────────────────────────────────────────────
function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** 헤더/시크릿 비교(상수시간 비교로 타이밍 노출 최소화). */
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

// Admin listUsers 가 돌려주는 유저(필요 필드만).
interface AdminUser {
  id: string;
  is_anonymous?: boolean;
  created_at?: string;
  updated_at?: string;
  last_sign_in_at?: string | null;
}

/** 익명 유저의 "마지막 활동" 시각(ms). 토큰 갱신 시 갱신되는 필드들의 최댓값. */
function lastActiveMs(u: AdminUser): number {
  const candidates = [u.last_sign_in_at, u.updated_at, u.created_at]
    .map((v) => (v ? Date.parse(v) : NaN))
    .filter((n) => !Number.isNaN(n));
  return candidates.length ? Math.max(...candidates) : 0;
}

/** 익명이면서 마지막 활동이 임계치를 초과한 유저 id 를 페이지네이션으로 수집. */
async function collectStaleAnonymousIds(
  admin: SupabaseClient,
  nowMs: number,
): Promise<string[]> {
  const ids: string[] = [];
  for (let page = 1; ; page++) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage: PER_PAGE,
    });
    if (error) {
      throw new Error(`listUsers 실패(page=${page}): ${error.message}`);
    }
    const users = (data?.users ?? []) as AdminUser[];
    for (const u of users) {
      if (u.is_anonymous !== true) continue;
      if (nowMs - lastActiveMs(u) > INACTIVE_MS) ids.push(u.id);
      if (ids.length >= MAX_DELETIONS) return ids;
    }
    // 마지막 페이지(반환 수 < 페이지 크기)면 종료.
    if (users.length < PER_PAGE) break;
  }
  return ids;
}

// ─── 엔트리포인트 ────────────────────────────────────────────────────────
Deno.serve(async (req: Request): Promise<Response> => {
  // (1) 호출 보호: Authorization === CRON_SECRET ('Bearer ' 접두사 허용).
  const cronSecret = Deno.env.get("CRON_SECRET") ?? "";
  const provided = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  if (cronSecret.length === 0 || !safeEqual(provided, cronSecret)) {
    return jsonResponse({ ok: false, error: "unauthorized" }, 401);
  }

  // (2) service_role 클라이언트(Admin API = 서버 전용, RLS 우회).
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    console.error("[cleanup-anon] SUPABASE_URL/SERVICE_ROLE_KEY 미설정 — 실행 불가.");
    return jsonResponse(
      { ok: false, error: "supabase env not configured" },
      500,
    );
  }
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const nowMs = Date.now();

  // (3) 대상 수집.
  let staleIds: string[];
  try {
    staleIds = await collectStaleAnonymousIds(admin, nowMs);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[cleanup-anon] 대상 조회 실패:", msg);
    return jsonResponse({ ok: false, error: msg }, 500);
  }

  // (4) 순차 삭제. 개별 실패는 기록 후 계속(부분 성공 허용).
  let deleted = 0;
  const failed: Array<{ id: string; error: string }> = [];
  for (const id of staleIds) {
    const { error } = await admin.auth.admin.deleteUser(id);
    if (error) {
      failed.push({ id, error: error.message });
      console.error(`[cleanup-anon] deleteUser 실패 id=${id}:`, error.message);
      continue;
    }
    deleted++;
  }

  const summary = {
    ok: true,
    inactiveDays: INACTIVE_DAYS,
    candidates: staleIds.length,
    deleted,
    failed,
    // candidates 가 MAX_DELETIONS 에 도달했으면 다음 실행에서 잔여분을 계속 처리.
    truncated: staleIds.length >= MAX_DELETIONS,
  };
  console.log("[cleanup-anon] 완료:", JSON.stringify(summary));
  return jsonResponse(summary);
});
