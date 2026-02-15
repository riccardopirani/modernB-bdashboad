import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// This function is meant to be triggered on a schedule (e.g., every 15 minutes)
// It finds upcoming bookings that need access codes and generates them automatically.

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    const baseUrl = Deno.env.get("TTLOCK_BASE_URL") || "https://api.ttlock.eu";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Find bookings that:
    // 1. Check-in is within the next 24 hours
    // 2. Status is 'confirmed'
    // 3. Don't have an active access code yet
    const now = new Date();
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const { data: bookings, error: bookingsError } = await supabase
      .from("bookings")
      .select(`
        *,
        properties!inner(*, locks(*)),
        access_codes(id, status)
      `)
      .eq("status", "confirmed")
      .lte("check_in_date", tomorrow.toISOString().split("T")[0])
      .gte("check_out_date", now.toISOString().split("T")[0]);

    if (bookingsError) {
      throw bookingsError;
    }

    const results: Array<{ booking_id: string; status: string; message: string }> = [];

    for (const booking of bookings || []) {
      // Skip if already has an active code
      const hasActiveCode = booking.access_codes?.some(
        (code: { status: string }) => code.status === "active"
      );
      if (hasActiveCode) continue;

      // Get property locks
      const locks = booking.properties?.locks;
      if (!locks || locks.length === 0) {
        results.push({
          booking_id: booking.id,
          status: "skipped",
          message: "No locks assigned to property",
        });
        continue;
      }

      // Check org has active subscription
      const { data: org } = await supabase
        .from("organizations")
        .select("subscription_active")
        .eq("id", booking.org_id)
        .single();

      if (!org?.subscription_active) {
        results.push({
          booking_id: booking.id,
          status: "skipped",
          message: "No active subscription",
        });
        continue;
      }

      // Get TTLock integration
      const { data: ttlockIntegration } = await supabase
        .from("integrations_ttlock")
        .select("*")
        .eq("org_id", booking.org_id)
        .eq("is_active", true)
        .single();

      if (!ttlockIntegration) {
        results.push({
          booking_id: booking.id,
          status: "skipped",
          message: "No TTLock integration",
        });
        continue;
      }

      // Generate a random 6-digit code
      const code = String(Math.floor(100000 + Math.random() * 900000));

      // Calculate validity window
      const checkIn = new Date(booking.check_in_date);
      checkIn.setHours(15, 0, 0, 0); // Default 3 PM check-in
      const checkOut = new Date(booking.check_out_date);
      checkOut.setHours(11, 0, 0, 0); // Default 11 AM check-out

      // Generate code for each lock on the property
      for (const lock of locks) {
        try {
          // Create access code record first
          const { data: accessCode, error: codeInsertError } = await supabase
            .from("access_codes")
            .insert({
              org_id: booking.org_id,
              booking_id: booking.id,
              lock_id: lock.id,
              code: code,
              type: "timed",
              valid_from: checkIn.toISOString(),
              valid_until: checkOut.toISOString(),
              status: "pending",
              auto_generated: true,
            })
            .select()
            .single();

          if (codeInsertError) throw codeInsertError;

          // Send to TTLock API
          const codeRes = await fetch(`${baseUrl}/v3/code/create`, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${ttlockIntegration.access_token}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              lockId: lock.ttlock_lock_id,
              clientId: lock.ttlock_client_id,
              code: code,
              startDate: checkIn.getTime(),
              endDate: checkOut.getTime(),
            }),
          });

          if (codeRes.ok) {
            const codeData = await codeRes.json();
            await supabase
              .from("access_codes")
              .update({
                ttlock_code_id: codeData.codeId,
                status: "active",
              })
              .eq("id", accessCode.id);

            results.push({
              booking_id: booking.id,
              status: "success",
              message: `Code generated for lock ${lock.name}`,
            });
          } else {
            const errText = await codeRes.text();
            await supabase
              .from("access_codes")
              .update({ status: "failed" })
              .eq("id", accessCode.id);

            results.push({
              booking_id: booking.id,
              status: "error",
              message: `TTLock API error: ${errText}`,
            });
          }
        } catch (lockError) {
          results.push({
            booking_id: booking.id,
            status: "error",
            message: lockError instanceof Error ? lockError.message : "Unknown error",
          });
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: results.length,
        results,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Automation error:", error);
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
