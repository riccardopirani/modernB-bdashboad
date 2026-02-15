import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface StripeEvent {
  id: string;
  object: string;
  api_version: string;
  created: number;
  data: {
    object: Record<string, unknown>;
    previous_attributes?: Record<string, unknown>;
  };
  livemode: boolean;
  pending_webhooks: number;
  request: {
    id: string | null;
    idempotency_key: string | null;
  };
  type: string;
}

interface StripeSubscription {
  id: string;
  customer: string;
  status: string;
  current_period_start: number;
  current_period_end: number;
  cancel_at_period_end: boolean;
  canceled_at?: number;
}

// Verify Stripe webhook signature
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  // Simplified verification - in production use crypto
  // This is a placeholder that should use HMAC-SHA256
  return true;
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      return new Response(JSON.stringify({ error: "Missing signature" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
    if (!webhookSecret) {
      return new Response(
        JSON.stringify({ error: "Webhook secret not configured" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const payload = await req.text();

    // Verify signature
    if (!verifyWebhookSignature(payload, signature, webhookSecret)) {
      return new Response(JSON.stringify({ error: "Invalid signature" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const event = JSON.parse(payload) as StripeEvent;

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase config" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (event.type === "customer.subscription.updated") {
      const subscription = event.data.object as StripeSubscription;

      // Get organization from stripe customer
      const { data: stripeCustomer } = await supabase
        .from("stripe_customers")
        .select("org_id")
        .eq("stripe_customer_id", subscription.customer)
        .single();

      if (!stripeCustomer) {
        return new Response(
          JSON.stringify({ error: "Customer not found" }),
          {
            status: 404,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      // Determine plan from subscription metadata or item
      const planName =
        (subscription as unknown as Record<string, unknown>).metadata?.plan ||
        "pro";

      // Update or create subscription record
      const { error: subError } = await supabase
        .from("stripe_subscriptions")
        .upsert(
          {
            org_id: stripeCustomer.org_id,
            stripe_subscription_id: subscription.id,
            stripe_customer_id: subscription.customer,
            status: subscription.status,
            plan_name: planName,
            current_period_start: new Date(
              subscription.current_period_start * 1000
            ).toISOString(),
            current_period_end: new Date(
              subscription.current_period_end * 1000
            ).toISOString(),
            cancel_at_period_end: subscription.cancel_at_period_end,
            canceled_at: subscription.canceled_at
              ? new Date(subscription.canceled_at * 1000).toISOString()
              : null,
          },
          { onConflict: "stripe_subscription_id" }
        );

      if (subError) {
        throw subError;
      }

      // Update organization subscription status
      const isActive = subscription.status === "active";
      await supabase
        .from("organizations")
        .update({
          subscription_active: isActive,
          subscription_ends_at: subscription.cancel_at_period_end
            ? new Date(subscription.current_period_end * 1000).toISOString()
            : null,
        })
        .eq("id", stripeCustomer.org_id);
    }

    if (event.type === "customer.subscription.deleted") {
      const subscription = event.data.object as StripeSubscription;

      // Get organization
      const { data: stripeCustomer } = await supabase
        .from("stripe_customers")
        .select("org_id")
        .eq("stripe_customer_id", subscription.customer)
        .single();

      if (stripeCustomer) {
        // Mark subscription as cancelled
        await supabase
          .from("stripe_subscriptions")
          .update({ status: "canceled" })
          .eq("stripe_subscription_id", subscription.id);

        // Update organization
        await supabase
          .from("organizations")
          .update({ subscription_active: false })
          .eq("id", stripeCustomer.org_id);
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Internal server error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
