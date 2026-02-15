import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

interface TTLockTokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user_id: string;
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

    const { code, state, org_id } = await req.json();

    if (!code || !org_id) {
      return new Response(
        JSON.stringify({ error: "Missing code or org_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const clientId = Deno.env.get("TTLOCK_CLIENT_ID");
    const clientSecret = Deno.env.get("TTLOCK_CLIENT_SECRET");
    const baseUrl = Deno.env.get("TTLOCK_BASE_URL") || "https://api.ttlock.eu";
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!clientId || !clientSecret || !supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing configuration" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Exchange code for tokens
    const tokenRes = await fetch(`${baseUrl}/oauth/token`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code,
        client_id: clientId,
        client_secret: clientSecret,
      }).toString(),
    });

    if (!tokenRes.ok) {
      throw new Error(`TTLock token exchange failed: ${tokenRes.statusText}`);
    }

    const tokenData = (await tokenRes.json()) as TTLockTokenResponse;

    // Initialize Supabase client with service role
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Store tokens in database (encrypted)
    const { data, error } = await supabase
      .from("integrations_ttlock")
      .upsert(
        {
          org_id,
          access_token: tokenData.access_token,
          refresh_token: tokenData.refresh_token,
          token_expires_at: new Date(
            Date.now() + tokenData.expires_in * 1000
          ).toISOString(),
          ttlock_user_id: tokenData.user_id,
          ttlock_client_id: clientId,
          is_active: true,
        },
        { onConflict: "org_id" }
      );

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "TTLock integration connected",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("TTLock callback error:", error);
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
