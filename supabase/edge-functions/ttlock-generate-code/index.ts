import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

interface GenerateCodeRequest {
  lock_id: string;
  access_code_id: string;
  code: string;
  valid_from: number; // Unix timestamp
  valid_until: number; // Unix timestamp
}

interface TTLockCodeResponse {
  codeId: number;
  code: string;
  createTime: number;
  startDate: number;
  endDate: number;
  status: number;
}

serve(async (req) => {
  // Handle CORS
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

    // Verify JWT
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    const supabase = createClient(supabaseUrl || "", supabaseAnonKey || "", {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: userData, error: authError } = await supabase.auth.getUser();
    if (authError || !userData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const {
      lock_id,
      access_code_id,
      code,
      valid_from,
      valid_until,
      org_id,
    } = (await req.json()) as GenerateCodeRequest & { org_id: string };

    if (!lock_id || !access_code_id || !code || !valid_from || !valid_until || !org_id) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      supabaseUrl || "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || supabaseAnonKey || ""
    );

    // Get lock details
    const { data: lock } = await supabaseAdmin
      .from("locks")
      .select("*")
      .eq("id", lock_id)
      .single();

    if (!lock) {
      return new Response(JSON.stringify({ error: "Lock not found" }), {
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

    if (!ttlockIntegration) {
      return new Response(
        JSON.stringify({ error: "TTLock integration not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const baseUrl = Deno.env.get("TTLOCK_BASE_URL") || "https://api.ttlock.eu";

    // Generate code on TTLock API
    const codeRes = await fetch(`${baseUrl}/v3/code/create`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${ttlockIntegration.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        lockId: lock.ttlock_lock_id,
        clientId: lock.ttlock_client_id,
        code,
        startDate: valid_from,
        endDate: valid_until,
      }),
    });

    if (!codeRes.ok) {
      const error = await codeRes.text();
      throw new Error(`TTLock API error: ${error}`);
    }

    const codeData = (await codeRes.json()) as TTLockCodeResponse;

    // Update access_code record with TTLock response
    const { error: updateError } = await supabaseAdmin
      .from("access_codes")
      .update({
        ttlock_code_id: codeData.codeId,
        status: "active",
      })
      .eq("id", access_code_id);

    if (updateError) {
      throw updateError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        ttlock_code_id: codeData.codeId,
        code: codeData.code,
        message: "Access code generated",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Generate code error:", error);
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
