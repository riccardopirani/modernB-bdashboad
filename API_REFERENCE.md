#!/usr/bin/env -S note

# LockFlow Edge Functions API Reference

All Edge Functions require:
- **Authorization**: `Authorization: Bearer <JWT_TOKEN>`
- **Content-Type**: `application/json`
- **Base URL**: `http://localhost:54321/functions/v1/`

## Authentication Functions

### POST /ttlock-auth-start

Initiates TTLock OAuth flow. Returns authorization URL to redirect user to.

**Request:**
```json
{
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "authorization_url": "https://api.ttlock.eu/oauth/authorize?...",
    "state": "a1b2c3d4e5f6..."
  }
}
```

**Error (400/500):**
```json
{
  "success": false,
  "error": "Missing org_id"
}
```

---

### POST /ttlock-auth-callback

Handles OAuth callback. Exchanges authorization code for access token and stores in database.

**Request:**
```json
{
  "code": "authorization_code_from_ttlock",
  "state": "a1b2c3d4e5f6...",
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "TTLock integration connected"
  }
}
```

**Notes:**
- Stores encrypted tokens in `integrations_ttlock` table
- Only one active integration per organization
- Tokens auto-refresh when needed

---

## TTLock Integration Functions

### POST /ttlock-sync-locks

Fetches all locks from TTLock API and syncs to database.

**Request:**
```json
{
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "synced_count": 5,
    "message": "Locks synchronized"
  }
}
```

**Error Scenarios:**
- `401`: TTLock integration not found
- `500`: Failed to fetch locks from TTLock API

**Notes:**
- Idempotent: can be called multiple times
- Uses unique constraint: `(org_id, ttlock_lock_id, ttlock_client_id)`
- Updates battery level and lock status

---

### POST /ttlock-generate-code

Generates a time-bound passcode via TTLock API and stores locally.

**Request:**
```json
{
  "lock_id": "20000000-0000-0000-0000-000000000001",
  "access_code_id": "40000000-0000-0000-0000-000000000001",
  "code": "123456",
  "valid_from": 1676400000,
  "valid_until": 1676486400,
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "ttlock_code_id": 987654321,
    "code": "123456",
    "message": "Access code generated"
  }
}
```

**Error Scenarios:**
- `404`: Lock or TTLock integration not found
- `500`: TTLock API error

**Notes:**
- Unix timestamps in seconds
- Updates `access_codes` row with TTLock response
- Code becomes active immediately on TTLock

---

### POST /ttlock-revoke-code

Revokes a previously generated passcode.

**Request:**
```json
{
  "access_code_id": "40000000-0000-0000-0000-000000000001",
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Access code revoked"
  }
}
```

**Notes:**
- Sets status to "revoked" in database
- Calls TTLock API to revoke immediately
- Cannot be undone

---

## Booking Synchronization

### POST /ical-sync

Fetches iCal data from URL, parses events, and syncs bookings to database.

**Request:**
```json
{
  "property_id": "10000000-0000-0000-0000-000000000001",
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "synced_count": 5,
    "message": "Bookings synchronized from iCal"
  }
}
```

**Error Scenarios:**
- `404`: Property not found or missing iCal URL
- `500`: Failed to fetch iCal data

**Booking Fields Extracted:**
- `UID` → `ical_uid` (unique identifier)
- `SUMMARY` → `guest_name`
- `DTSTART` → `check_in_date`
- `DTEND` → `check_out_date`
- `ATTENDEE` → `guest_email`, `guest_phone`
- `STATUS` → booking status (CONFIRMED/CANCELLED)

**Notes:**
- Idempotent: uses UID as unique key
- Handles cancellations (sets status to "cancelled")
- Supports Google Calendar, Airbnb iCal exports, etc.
- Updates `ical_last_synced_at` on property

---

## Messaging

### POST /send-message

Sends email or SMS to guest with access code or booking information.

**Request:**
```json
{
  "access_code_id": "40000000-0000-0000-0000-000000000001",
  "type": "email",
  "recipient_email": "guest@example.com",
  "template_id": "50000000-0000-0000-0000-000000000001",
  "variables": {
    "guest_name": "John Doe",
    "code": "123456",
    "check_in_time": "15:00"
  },
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message_id": "60000000-0000-0000-0000-000000000001",
    "external_id": "re_28729473274",
    "status": "sent"
  }
}
```

**Error Scenarios:**
- `400`: Missing required fields
- `500`: Resend/Twilio API error

**Supported Types:**
- `email` – via Resend API
- `sms` – via Twilio API

**Notes:**
- Templates stored in `message_templates` table
- Variables are interpolated into template body
- Logs all messages in `message_logs` for audit
- Retries up to 3 times on failure

---

## Billing & Payments

### POST /stripe-create-checkout-session

Creates a Stripe Checkout session for subscription purchase.

**Request:**
```json
{
  "org_id": "00000000-0000-0000-0000-000000000001",
  "plan": "pro",
  "success_url": "https://lockflow.local/billing?session_id={CHECKOUT_SESSION_ID}",
  "cancel_url": "https://lockflow.local/billing"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "session_id": "cs_live_...",
    "url": "https://checkout.stripe.com/pay/cs_live_..."
  }
}
```

**Error Scenarios:**
- `400`: Invalid plan
- `500`: Stripe API error

**Plans:**
- `basic` – $9/month
- `pro` – $29/month
- `enterprise` – Custom pricing

**Notes:**
- Creates or retrieves Stripe customer
- Links to organization in `stripe_customers` table
- Redirect user to returned URL to complete payment

---

### POST /stripe-create-portal-session

Creates a Stripe Customer Portal link for subscription management.

**Request:**
```json
{
  "org_id": "00000000-0000-0000-0000-000000000001",
  "return_url": "https://lockflow.local/billing"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://billing.stripe.com/session/..."
  }
}
```

**Error Scenarios:**
- `404`: Stripe customer not found
- `500`: Stripe API error

**Notes:**
- User can manage payment methods, cancel subscription, view invoices
- Return URL sends user back after management

---

### POST /stripe-webhook

Webhook endpoint for Stripe events. No authentication required.

**Stripe Events Handled:**
- `customer.subscription.updated` – Update subscription status
- `customer.subscription.deleted` – Mark subscription as cancelled

**Request (from Stripe):**
```json
{
  "id": "evt_...",
  "type": "customer.subscription.updated",
  "data": {
    "object": {
      "id": "sub_...",
      "customer": "cus_...",
      "status": "active",
      "current_period_start": 1676400000,
      "current_period_end": 1679078400
    }
  }
}
```

**Response (200):**
```json
{
  "received": true
}
```

**Error Scenarios:**
- `401`: Invalid webhook signature
- `404`: Organization not found
- `500`: Database error

**Notes:**
- All updates are idempotent
- Updates both `stripe_subscriptions` and `organizations` tables
- Syncs plan, status, and billing period

**Setup in Production:**
```bash
# Point this webhook to your production URL:
# https://your-domain.com/functions/v1/stripe-webhook

# Stripe CLI for local testing:
stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
```

---

## Automation Functions

### POST /automation-generate-codes

Scheduled function that runs daily to auto-generate access codes for upcoming check-ins.

**Trigger:** Scheduled via Supabase Cron / external scheduler

**Behavior:**
- Finds bookings with check-in date = today + 1
- For each booking with no active code:
  - Generates random passcode
  - Calls TTLock API to create code
  - Optionally sends email/SMS (if enabled)

**Configuration (in organizations):**
- `auto_generate_codes` – Enable/disable
- `auto_send_codes` – Enable/disable
- `code_send_method` – "email" | "sms" | "both"

**Notes:**
- Respects feature gates (plan-based)
- Only for "confirmed" bookings
- Codes valid from check-in time until check-out + buffer

---

## Error Handling

All functions return consistent error format:

```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

### HTTP Status Codes
- `200` – Success
- `400` – Bad request (missing/invalid parameters)
- `401` – Unauthorized (invalid JWT or missing auth)
- `404` – Resource not found
- `500` – Server error

### Common Errors
- `"Unauthorized"` – Invalid JWT token
- `"TTLock integration not found"` – User hasn't connected TTLock
- `"Stripe customer not found"` – User has no Stripe customer record
- `"Failed to fetch locks from TTLock"` – TTLock API error
- `"Missing environment variable: X"` – Server misconfiguration

---

## Testing Edge Functions Locally

Using `curl`:

```bash
# Get JWT token from Supabase auth
JWT=$(supabase auth users list --json | jq -r '.[0].id')

# Test ttlock-sync-locks
curl -X POST http://localhost:54321/functions/v1/ttlock-sync-locks \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"org_id":"..."}'

# Test ical-sync
curl -X POST http://localhost:54321/functions/v1/ical-sync \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"property_id":"...","org_id":"..."}'

# Test send-message
curl -X POST http://localhost:54321/functions/v1/send-message \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "type":"email",
    "recipient_email":"test@example.com",
    "template_id":"...",
    "variables":{"guest_name":"John","code":"123456"},
    "org_id":"..."
  }'
```

Using Flutter (in code):

```dart
final response = await supabase.functions.invoke(
  'ttlock-sync-locks',
  body: {'org_id': orgId},
);
```

---

**API Version**: 1.0
**Last Updated**: Feb 15, 2026
