// supabase/functions/delete-account/index.ts
//
// 아가왜울어 — 계정 삭제 Edge Function (설계서 §3.3 / §11.16 / §13.4)
//
// 스토어 필수 요건: 계정 삭제를 앱 내에서 완결한다(Apple·Google). 클라이언트는
// 설정 › 계정 관리 › 계정 삭제(2단계 확인) 후 이 함수를 **현재 사용자 JWT로** 호출한다
// (auth_data_source.dart 의 deleteAccount()). refresh-products 와 달리 CRON_SECRET 이
// 아니라 **호출자 본인의 access token** 을 검증한다 — 남의 계정을 지울 수 없어야 하므로.
//
// 흐름:
//   (1) Authorization 헤더의 JWT 로 호출자(user)를 식별(anon key + getUser).
//   (2) service_role 로 auth.admin.deleteUser(user.id) 실행.
//       → 개인 데이터(babies/tracking_logs/favorites/… )는 user_id FK 의
//         `on delete cascade`(0001_schema.sql / 0002_rls.sql)로 함께 파기된다.
//   (3) 200 반환. 클라이언트는 이후 로컬 세션을 정리하고 게스트로 복귀한다.
//
// 비밀값: SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY 는 Edge 런타임에
//   자동 주입된다. service_role 키는 절대 클라이언트로 내려보내지 않는다.

import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight.
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceKey) {
    console.error("[delete-account] 환경변수 미설정 — 실행 불가.");
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  // (1) 호출자 본인 확인 — 반드시 유효한 사용자 JWT 여야 한다(CRON_SECRET 아님).
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return jsonResponse({ error: "missing_authorization" }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser(
    token,
  );
  const user = userData?.user;
  if (userError || !user) {
    return jsonResponse({ error: "invalid_token" }, 401);
  }

  // (2) service_role 로 본인 계정만 삭제. 개인 데이터는 FK cascade 로 함께 파기.
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("[delete-account] deleteUser 실패:", deleteError.message);
    return jsonResponse({ error: "delete_failed" }, 500);
  }

  return jsonResponse({ ok: true, deleted_user_id: user.id }, 200);
});
