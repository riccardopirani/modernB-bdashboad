import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

interface TTLockAuthRequest {
  org_id: string;
}

interface TTLockAuthResponse {
  authorization_url: string;
  state: string;
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

    const { org_id } = (await req.json()) as TTLockAuthRequest;

    if (!org_id) {
      return new Response(
        JSON.stringify({ error: "Missing org_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const clientId = Deno.env.get("TTLOCK_CLIENT_ID");
    const redirectUri = Deno.env.get("TTLOCK_REDIRECT_URI");
    const baseUrl = Deno.env.get("TTLOCK_BASE_URL") || "https://api.ttlock.eu";

    if (!clientId || !redirectUri) {
      return new Response(
        JSON.stringify({ error: "TTLock credentials not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Generate state for CSRF protection
    const state = crypto.getRandomValues(new Uint8Array(16));
    const stateString = Array.from(state)
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // Store state in org metadata (you could use a separate table)
    // For now, just include it in the response

    const authUrl = new URL(`${baseUrl}/oauth/authorize`);
    authUrl.searchParams.append("client_id", clientId);
    authUrl.searchParams.append("redirect_uri", redirectUri);
    authUrl.searchParams.append("response_type", "code");
    authUrl.searchParams.append("state", stateString);
    authUrl.searchParams.append("scope", "lock:read lock:write code:read code:write");

    const response: TTLockAuthResponse = {
      authorization_url: authUrl.toString(),
      state: stateString,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
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
