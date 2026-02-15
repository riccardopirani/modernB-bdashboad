import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

interface SendMessageRequest {
  org_id: string;
  to: string;
  channel: "email" | "sms";
  template_id?: string;
  subject?: string;
  body: string;
  metadata?: Record<string, string>;
}

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

    const { org_id, to, channel, subject, body, metadata } =
      (await req.json()) as SendMessageRequest;

    if (!org_id || !to || !channel || !body) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || supabaseAnonKey
    );

    let messageId: string | null = null;
    let deliveryStatus = "sent";

    if (channel === "email") {
      // Use Resend or similar provider
      const resendApiKey = Deno.env.get("RESEND_API_KEY");
      const fromEmail = Deno.env.get("FROM_EMAIL") || "noreply@lockflow.app";

      if (resendApiKey) {
        const res = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: fromEmail,
            to: [to],
            subject: subject || "Your Access Code",
            html: body,
          }),
        });

        const result = await res.json();
        messageId = result.id;
        deliveryStatus = res.ok ? "sent" : "failed";
      } else {
        // Fallback: log message (no provider configured)
        console.log(`[MOCK EMAIL] To: ${to}, Subject: ${subject}, Body: ${body}`);
        deliveryStatus = "mock_sent";
      }
    } else if (channel === "sms") {
      // Use Twilio or similar provider
      const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID");
      const twilioToken = Deno.env.get("TWILIO_AUTH_TOKEN");
      const twilioFrom = Deno.env.get("TWILIO_FROM_NUMBER");

      if (twilioSid && twilioToken && twilioFrom) {
        const res = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`,
          {
            method: "POST",
            headers: {
              Authorization: `Basic ${btoa(`${twilioSid}:${twilioToken}`)}`,
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: new URLSearchParams({
              From: twilioFrom,
              To: to,
              Body: body,
            }).toString(),
          }
        );

        const result = await res.json();
        messageId = result.sid;
        deliveryStatus = res.ok ? "sent" : "failed";
      } else {
        console.log(`[MOCK SMS] To: ${to}, Body: ${body}`);
        deliveryStatus = "mock_sent";
      }
    }

    // Log message
    await supabaseAdmin.from("message_logs").insert({
      org_id,
      channel,
      recipient: to,
      subject,
      body,
      external_id: messageId,
      status: deliveryStatus,
      metadata,
    });

    return new Response(
      JSON.stringify({
        success: true,
        message_id: messageId,
        status: deliveryStatus,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Send message error:", error);
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
