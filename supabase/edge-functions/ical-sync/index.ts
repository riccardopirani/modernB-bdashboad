import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-id, content-type",
};

interface ICalEvent {
  uid: string;
  summary: string;
  description?: string;
  dtstart: string;
  dtend: string;
  status: "CONFIRMED" | "CANCELLED" | "TENTATIVE";
  attendees?: Array<{ email: string; name?: string }>;
}

// Simple iCal parser (handles basic events)
function parseICalData(data: string): ICalEvent[] {
  const events: ICalEvent[] = [];
  const eventBlocks = data.split("BEGIN:VEVENT");

  for (let i = 1; i < eventBlocks.length; i++) {
    const block = eventBlocks[i];
    const endIdx = block.indexOf("END:VEVENT");
    if (endIdx === -1) continue;

    const eventData = block.substring(0, endIdx);
    const lines = eventData.split("\r\n").filter((l) => l.trim());

    const event: ICalEvent = {
      uid: "",
      summary: "",
      dtstart: "",
      dtend: "",
      status: "CONFIRMED",
    };

    for (const line of lines) {
      const [key, ...valueParts] = line.split(":");
      const value = valueParts.join(":");

      if (key === "UID") event.uid = value;
      else if (key === "SUMMARY") event.summary = decodeURIComponent(value.replace(/\\,/g, ","));
      else if (key === "DESCRIPTION") event.description = value;
      else if (key === "DTSTART" || key.startsWith("DTSTART;")) event.dtstart = extractDate(value);
      else if (key === "DTEND" || key.startsWith("DTEND;")) event.dtend = extractDate(value);
      else if (key === "STATUS") event.status = value as "CONFIRMED" | "CANCELLED" | "TENTATIVE";
    }

    if (event.uid && event.dtstart && event.dtend) {
      events.push(event);
    }
  }

  return events;
}

function extractDate(dateStr: string): string {
  // Handle both DATE and DATETIME formats
  // YYYYMMDD or YYYYMMDDTHHMMSSZ
  if (dateStr.includes("T")) {
    return dateStr.substring(0, 15); // Return datetime
  }
  return dateStr.substring(0, 8); // Return date
}

function parseICalDate(dateStr: string): Date {
  if (dateStr.includes("T")) {
    // YYYYMMDDTHHMMSSZ format
    const year = parseInt(dateStr.substring(0, 4));
    const month = parseInt(dateStr.substring(4, 6)) - 1;
    const day = parseInt(dateStr.substring(6, 8));
    const hour = parseInt(dateStr.substring(9, 11)) || 0;
    const minute = parseInt(dateStr.substring(11, 13)) || 0;
    return new Date(year, month, day, hour, minute);
  }
  // YYYYMMDD format
  const year = parseInt(dateStr.substring(0, 4));
  const month = parseInt(dateStr.substring(4, 6)) - 1;
  const day = parseInt(dateStr.substring(6, 8));
  return new Date(year, month, day);
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

    const { property_id, org_id } = await req.json();

    if (!property_id || !org_id) {
      return new Response(
        JSON.stringify({ error: "Missing property_id or org_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseAdmin = createClient(
      supabaseUrl || "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || supabaseAnonKey || ""
    );

    // Get property with iCal URL
    const { data: property } = await supabaseAdmin
      .from("properties")
      .select("*")
      .eq("id", property_id)
      .eq("org_id", org_id)
      .single();

    if (!property || !property.ical_url) {
      return new Response(
        JSON.stringify({ error: "Property or iCal URL not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Fetch iCal data
    const icalRes = await fetch(property.ical_url);
    if (!icalRes.ok) {
      throw new Error(`Failed to fetch iCal: ${icalRes.statusText}`);
    }

    const icalData = await icalRes.text();

    // Parse iCal events
    const events = parseICalData(icalData);

    // Upsert bookings
    const bookings = events.map((event) => {
      const checkInDate = parseICalDate(event.dtstart);
      const checkOutDate = parseICalDate(event.dtend);
      const attendee = event.attendees?.[0];

      return {
        org_id,
        property_id,
        ical_uid: event.uid,
        guest_name: attendee?.name || event.summary || "Guest",
        guest_email: attendee?.email,
        check_in_date: checkInDate.toISOString().split("T")[0],
        check_out_date: checkOutDate.toISOString().split("T")[0],
        status: event.status === "CANCELLED" ? "cancelled" : "confirmed",
      };
    });

    const { data: upsertedBookings, error: upsertError } = await supabaseAdmin
      .from("bookings")
      .upsert(bookings, { onConflict: "org_id,ical_uid" });

    if (upsertError) {
      throw upsertError;
    }

    // Update property sync timestamp
    await supabaseAdmin
      .from("properties")
      .update({
        ical_last_synced_at: new Date().toISOString(),
        ical_sync_status: "idle",
      })
      .eq("id", property_id);

    return new Response(
      JSON.stringify({
        success: true,
        synced_count: upsertedBookings?.length || 0,
        message: "Bookings synchronized from iCal",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("iCal sync error:", error);
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
