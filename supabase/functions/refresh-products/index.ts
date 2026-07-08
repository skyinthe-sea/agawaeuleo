// supabase/functions/refresh-products/index.ts
//
// 아가왜울어 — 쿠팡 파트너스 제품 캐시 갱신 Edge Function
//
// 트리거: pg_cron (하루 1~2회) 또는 수동 curl 호출 (README 참고).
// 흐름(설계서 §6.1 / §7.3):
//   symptoms(is_active) 순회 → 증상별 product_keywords(없으면 name) 순차 검색
//   → 상위 N=10개 딥링크 생성 → products upsert(onConflict: symptom_id,coupang_pid)
//   → 갱신 배치에 없는 기존 제품은 is_active=false → 증상 간 sleep(rate-limit).
//
// 비밀값(설계서 §8.1/§8.3): COUPANG_ACCESS_KEY / COUPANG_SECRET_KEY 는
//   Supabase Secrets 에만 존재. 앱/리포지토리에 절대 하드코딩 금지.
//
// 호출 보호: Authorization 헤더가 CRON_SECRET 과 일치할 때만 실행.
// 승인 전 폴백(설계서 §6.4): 쿠팡 키가 없으면 no-op 성공 반환(수동 큐레이션 모드).

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

// ─── 상수 ────────────────────────────────────────────────────────────────
const N = 10; // 증상당 저장할 상위 제품 수
const SEARCH_LIMIT = 10; // 키워드당 검색 요청 limit
const MAX_RETRIES = 3; // 지수 백오프 최대 재시도
const BASE_BACKOFF_MS = 500; // 지수 백오프 기준 대기
// 증상/키워드 간 sleep (rate-limit 회피). 환경변수로 조정 가능(기본 1200ms).
const SLEEP_BETWEEN_MS = Number(Deno.env.get("REFRESH_SLEEP_MS") ?? "1200");

const COUPANG_HOST = "https://api-gateway.coupang.com";
const SEARCH_PATH =
  "/v2/providers/affiliate_open_api/apis/openapi/products/search";
const DEEPLINK_PATH =
  "/v2/providers/affiliate_open_api/apis/openapi/v1/deeplink";

// ─── 유틸 ────────────────────────────────────────────────────────────────
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

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

class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

// ─── 쿠팡 파트너스 HMAC 서명 (CEA 알고리즘) ──────────────────────────────
// 공식 규격(쿠팡 Open API 문서 / Node·Python 예제 기준):
//   signed-date = GMT 기준 `yyMMddTHHmmssZ` (예: 260708T123456Z)
//   message     = signed-date + HTTP_METHOD + PATH + QUERY   (구분자 없이 연결)
//                 - PATH 는 앞의 '/' 포함, 쿼리스트링은 미포함
//                 - QUERY 는 '?' 없이 실제 요청과 100% 동일한 문자열(인코딩 포함)
//   signature   = HmacSHA256(secretKey, message) 를 hex 로 인코딩
//   Authorization = "CEA algorithm=HmacSHA256, access-key=<AK>, "
//                 + "signed-date=<datetime>, signature=<sig>"

/** GMT 기준 signed-date: yyMMddTHHmmssZ */
function signedDate(): string {
  // toISOString: 2026-07-08T12:34:56.789Z → slice(2,19): 26-07-08T12:34:56
  return new Date().toISOString().slice(2, 19).replace(/[:-]/g, "") + "Z";
}

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(message));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function buildAuthorization(
  method: string,
  path: string,
  query: string,
  accessKey: string,
  secretKey: string,
): Promise<string> {
  const datetime = signedDate();
  const message = datetime + method + path + query;
  const signature = await hmacSha256Hex(secretKey, message);
  return (
    `CEA algorithm=HmacSHA256, access-key=${accessKey}, ` +
    `signed-date=${datetime}, signature=${signature}`
  );
}

// ─── 쿠팡 API 호출 ───────────────────────────────────────────────────────
interface CoupangProduct {
  productId: number | string;
  productName: string;
  productImage?: string;
  productPrice?: number;
  productUrl: string;
  rank?: number;
}

/** 상품검색: GET /products/search?keyword=..&limit=.. */
async function coupangSearch(
  keyword: string,
  accessKey: string,
  secretKey: string,
): Promise<CoupangProduct[]> {
  // 서명 대상 query 와 실제 요청 URL 의 query 는 반드시 동일해야 한다.
  const query = `keyword=${encodeURIComponent(keyword)}&limit=${SEARCH_LIMIT}`;
  const auth = await buildAuthorization(
    "GET",
    SEARCH_PATH,
    query,
    accessKey,
    secretKey,
  );
  const res = await fetch(`${COUPANG_HOST}${SEARCH_PATH}?${query}`, {
    method: "GET",
    headers: { Authorization: auth, "Content-Type": "application/json" },
  });
  if (!res.ok) {
    throw new HttpError(res.status, await res.text().catch(() => ""));
  }
  const body = await res.json();
  // 응답 래퍼: { rCode, rMessage, data: { landingUrl, productData: [...] } }
  // 방어적으로 data.productData 또는 data(배열) 모두 수용.
  const items: CoupangProduct[] = body?.data?.productData ??
    (Array.isArray(body?.data) ? body.data : []);
  return Array.isArray(items) ? items : [];
}

/** 딥링크 생성: POST /v1/deeplink { coupangUrls: [...] } → originalUrl→link 맵 */
async function coupangDeeplinks(
  urls: string[],
  accessKey: string,
  secretKey: string,
): Promise<Map<string, string>> {
  const map = new Map<string, string>();
  if (urls.length === 0) return map;
  const auth = await buildAuthorization(
    "POST",
    DEEPLINK_PATH,
    "", // 딥링크는 쿼리스트링 없음(본문은 서명 대상 아님)
    accessKey,
    secretKey,
  );
  const res = await fetch(`${COUPANG_HOST}${DEEPLINK_PATH}`, {
    method: "POST",
    headers: { Authorization: auth, "Content-Type": "application/json" },
    body: JSON.stringify({ coupangUrls: urls }),
  });
  if (!res.ok) {
    throw new HttpError(res.status, await res.text().catch(() => ""));
  }
  const body = await res.json();
  // 응답: { rCode, rMessage, data: [{ originalUrl, shortenUrl, landingUrl }] }
  const data: Array<Record<string, string>> = body?.data ?? [];
  for (const d of data) {
    const link = d.shortenUrl || d.landingUrl;
    if (d.originalUrl && link) map.set(d.originalUrl, link);
  }
  return map;
}

/** 지수 백오프 재시도. 네트워크 오류·429·5xx 만 재시도. */
async function withRetry<T>(fn: () => Promise<T>, label: string): Promise<T> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      const status = err instanceof HttpError ? err.status : undefined;
      const retryable = status === undefined || status === 429 || status >= 500;
      if (!retryable || attempt === MAX_RETRIES) break;
      const wait = BASE_BACKOFF_MS * 2 ** attempt +
        Math.floor(Math.random() * 250);
      console.warn(
        `[refresh] ${label} 시도 ${attempt + 1} 실패(${
          status ?? "network"
        }) → ${wait}ms 후 재시도`,
      );
      await sleep(wait);
    }
  }
  throw lastErr;
}

// ─── 증상 1건 갱신 ───────────────────────────────────────────────────────
interface SymptomRow {
  id: string;
  name: string;
  product_keywords?: string[] | null;
}

async function refreshSymptom(
  db: SupabaseClient,
  s: SymptomRow,
  accessKey: string,
  secretKey: string,
): Promise<number> {
  const keywords = s.product_keywords?.length ? s.product_keywords : [s.name];

  // 1) 키워드 순차 검색 + 중복 제거(productId 기준), 상위 N 수집.
  const seen = new Set<string>();
  const merged: CoupangProduct[] = [];
  for (let k = 0; k < keywords.length; k++) {
    if (merged.length >= N) break;
    const kw = keywords[k];
    const items = await withRetry(
      () => coupangSearch(kw, accessKey, secretKey),
      `search "${kw}"`,
    );
    for (const it of items) {
      if (it?.productId == null || !it?.productUrl) continue;
      const pid = String(it.productId);
      if (seen.has(pid)) continue;
      seen.add(pid);
      merged.push(it);
      if (merged.length >= N) break;
    }
    // 키워드 간에도 rate-limit 회피 sleep (마지막 키워드 제외).
    if (k < keywords.length - 1) await sleep(SLEEP_BETWEEN_MS);
  }

  // 결과가 비면(전송 성공했으나 0건): 이전 캐시 유지 위해 갱신/비활성화 skip.
  if (merged.length === 0) {
    console.warn(
      `[refresh] symptom=${s.id}(${s.name}) 검색 결과 0건 — 이전 캐시 유지`,
    );
    return 0;
  }

  // 2) 딥링크 일괄 생성. 실패해도 productUrl(트래킹 포함) 폴백으로 진행.
  let deeplinkMap = new Map<string, string>();
  try {
    deeplinkMap = await withRetry(
      () =>
        coupangDeeplinks(
          merged.map((it) => it.productUrl),
          accessKey,
          secretKey,
        ),
      `deeplink symptom=${s.id}`,
    );
  } catch (err) {
    console.warn(
      `[refresh] symptom=${s.id} 딥링크 생성 실패 — productUrl 폴백 사용:`,
      err instanceof Error ? err.message : String(err),
    );
  }

  const nowIso = new Date().toISOString();
  const rows = merged.map((it, i) => ({
    symptom_id: s.id,
    coupang_pid: String(it.productId),
    title: it.productName,
    image_url: it.productImage ?? null,
    price: typeof it.productPrice === "number"
      ? Math.round(it.productPrice)
      : null,
    // deeplink 는 NOT NULL — 딥링크 실패 시 트래킹 포함 productUrl 로 폴백.
    deeplink: deeplinkMap.get(it.productUrl) ?? it.productUrl,
    rank_index: i,
    is_active: true,
    fetched_at: nowIso,
  }));

  // 3) upsert (onConflict: symptom_id,coupang_pid). rank_index/is_active 갱신.
  const { error: upErr } = await db
    .from("products")
    .upsert(rows, { onConflict: "symptom_id,coupang_pid" });
  if (upErr) {
    throw new Error(`upsert 실패 symptom=${s.id}: ${upErr.message}`);
  }

  // 4) 이번 배치에 없는 기존 활성 제품 → is_active=false.
  const fetchedPids = new Set(rows.map((r) => r.coupang_pid));
  const { data: existing, error: exErr } = await db
    .from("products")
    .select("coupang_pid")
    .eq("symptom_id", s.id)
    .eq("is_active", true);
  if (exErr) {
    throw new Error(`기존 제품 조회 실패 symptom=${s.id}: ${exErr.message}`);
  }
  const stale = (existing ?? [])
    .map((r: { coupang_pid: string }) => r.coupang_pid)
    .filter((pid: string) => !fetchedPids.has(pid));
  if (stale.length > 0) {
    const { error: deErr } = await db
      .from("products")
      .update({ is_active: false })
      .eq("symptom_id", s.id)
      .in("coupang_pid", stale);
    if (deErr) {
      throw new Error(`비활성화 실패 symptom=${s.id}: ${deErr.message}`);
    }
  }

  return rows.length;
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

  // (2) 착수 전 폴백(§6.4): 쿠팡 키 없으면 no-op 성공(수동 큐레이션 모드).
  const accessKey = Deno.env.get("COUPANG_ACCESS_KEY") ?? "";
  const secretKey = Deno.env.get("COUPANG_SECRET_KEY") ?? "";
  if (!accessKey || !secretKey) {
    console.log(
      "[refresh] COUPANG_ACCESS_KEY/SECRET_KEY 미설정 — 수동 큐레이션 모드. " +
        "갱신을 건너뛰고 성공 반환합니다(§6.4).",
    );
    return jsonResponse({
      ok: true,
      mode: "manual-curation",
      message: "Coupang keys not configured; refresh skipped (no-op).",
    });
  }

  // (3) Supabase service_role 클라이언트(products 쓰기 = 서버 전용, RLS 우회).
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    console.error("[refresh] SUPABASE_URL/SERVICE_ROLE_KEY 미설정 — 실행 불가.");
    return jsonResponse(
      { ok: false, error: "supabase env not configured" },
      500,
    );
  }
  const db = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // (4) 활성 증상 로드.
  const { data: symptoms, error: symErr } = await db
    .from("symptoms")
    .select("id, name, product_keywords")
    .eq("is_active", true)
    .order("order_index", { ascending: true });
  if (symErr) {
    console.error("[refresh] symptoms 조회 실패:", symErr.message);
    return jsonResponse({ ok: false, error: symErr.message }, 500);
  }

  const list = (symptoms ?? []) as SymptomRow[];
  let updatedProducts = 0;
  let processed = 0;
  const failed: Array<{ id: string; name: string; error: string }> = [];

  // (5) 증상별 순차 처리. 개별 실패는 이전 캐시 유지 후 계속(§6.3).
  for (let i = 0; i < list.length; i++) {
    const s = list[i];
    try {
      const count = await refreshSymptom(db, s, accessKey, secretKey);
      updatedProducts += count;
      processed++;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(
        `[refresh] symptom=${s.id}(${s.name}) 실패 — 이전 캐시 유지:`,
        msg,
      );
      failed.push({ id: s.id, name: s.name, error: msg });
    }
    // 증상 간 sleep (rate-limit 회피). 마지막 증상 제외.
    if (i < list.length - 1) await sleep(SLEEP_BETWEEN_MS);
  }

  const summary = {
    ok: true,
    mode: "live",
    symptoms: list.length,
    processed,
    updatedProducts,
    failedSymptoms: failed,
  };
  console.log("[refresh] 완료:", JSON.stringify(summary));
  return jsonResponse(summary);
});
