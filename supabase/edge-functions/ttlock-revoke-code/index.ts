import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") || "";

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: userData, error: authError } = await supabase.auth.getUser();
    if (authError || !userData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { access_code_id, org_id } = await req.json();
    if (!access_code_id || !org_id) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || supabaseAnonKey
    );

    // Get access code with lock info
    const { data: accessCode } = await supabaseAdmin
      .from("access_codes")
      .select("*, locks(*)")
      .eq("id", access_code_id)
      .single();

    if (!accessCode) {
      return new Response(JSON.stringify({ error: "Access code not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get TTLock credentials
    const { data: ttlockIntegration } = await supabaseAdmin
      .from("integrations_ttlock")
      .select("*")
      .eq("org_id", org_id)
      .single();

    if (ttlockIntegration && accessCode.ttlock_code_id) {
      const baseUrl = Deno.env.get("TTLOCK_BASE_URL") || "https://api.ttlock.eu";

      // Delete code on TTLock
      await fetch(`${baseUrl}/v3/code/delete`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${ttlockIntegration.access_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          lockId: accessCode.locks?.ttlock_lock_id,
          clientId: accessCode.locks?.ttlock_client_id,
          codeId: accessCode.ttlock_code_id,
        }),
      });
    }

    // Update access_code status
    await supabaseAdmin
      .from("access_codes")
      .update({ status: "revoked" })
      .eq("id", access_code_id);

    return new Response(
      JSON.stringify({ success: true, message: "Code revoked" }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Revoke code error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Internal server error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
