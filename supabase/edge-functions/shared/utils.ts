// supabase/edge-functions/shared/utils.ts
// Shared utilities for all Edge Functions

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public details?: unknown
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export async function handleCors(req: Request) {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}

export function errorResponse(error: unknown, status = 500) {
  const message =
    error instanceof Error ? error.message : "Internal server error";
  return new Response(JSON.stringify({ error: message, success: false }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function successResponse<T>(data: T, status = 200) {
  return new Response(JSON.stringify({ success: true, data }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function validateEnv(...vars: string[]): Record<string, string> {
  const env: Record<string, string> = {};
  for (const v of vars) {
    const value = Deno.env.get(v);
    if (!value) {
      throw new ApiError(500, `Missing environment variable: ${v}`);
    }
    env[v] = value;
  }
  return env;
}
