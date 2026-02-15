import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

interface TTLockLock {
  lockId: number;
  clientId: string;
  lockName: string;
  lockModel: string;
  featureValue: number;
  lockStatus: number;
  electricQuantity: number;
  longitude: number;
  latitude: number;
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

    // Get auth header
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

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase config" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify JWT with Supabase
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data, error: authError } = await supabase.auth.getUser();
    if (authError || !data.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = data.user.id;
    const { org_id } = await req.json();

    if (!org_id) {
      return new Response(JSON.stringify({ error: "Missing org_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get TTLock credentials from database
    const supabaseAdmin = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || supabaseAnonKey
    );

    const { data: ttlockIntegration, error: fetchError } = await supabaseAdmin
      .from("integrations_ttlock")
      .select("*")
      .eq("org_id", org_id)
      .single();

    if (fetchError || !ttlockIntegration) {
      return new Response(
        JSON.stringify({ error: "TTLock integration not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const baseUrl = Deno.env.get("TTLOCK_BASE_URL") || "https://api.ttlock.eu";

    // Fetch locks from TTLock API
    const locksRes = await fetch(`${baseUrl}/v3/lock/list`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${ttlockIntegration.access_token}`,
        "Content-Type": "application/json",
      },
    });

    if (!locksRes.ok) {
      return new Response(
        JSON.stringify({ error: "Failed to fetch locks from TTLock" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { list: ttlockLocks } = await locksRes.json();

    // Upsert locks into database
    const locks = (ttlockLocks as TTLockLock[]).map((lock) => ({
      org_id,
      ttlock_lock_id: lock.lockId,
      ttlock_client_id: lock.clientId,
      name: lock.lockName,
      model: lock.lockModel,
      feature_value: lock.featureValue,
      status: lock.lockStatus,
      electric_quantity: lock.electricQuantity,
      longitude: lock.longitude,
      latitude: lock.latitude,
      is_active: true,
    }));

    const { data: upsertedLocks, error: upsertError } = await supabaseAdmin
      .from("locks")
      .upsert(locks, {
        onConflict: "org_id,ttlock_lock_id,ttlock_client_id",
      });

    if (upsertError) {
      throw upsertError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        synced_count: upsertedLocks?.length || 0,
        message: "Locks synchronized",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Sync locks error:", error);
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
