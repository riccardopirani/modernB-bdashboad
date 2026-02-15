# Edge Functions

TypeScript-based serverless functions for LockFlow backend operations.

## Functions Overview

### Authentication
- **ttlock-auth-start**: Initiates TTLock OAuth flow, returns authorization URL
- **ttlock-auth-callback**: Handles OAuth callback, exchanges code for tokens

### TTLock Integration
- **ttlock-sync-locks**: Fetches locks from TTLock API, syncs to database
- **ttlock-generate-code**: Generates time-bound passcodes via TTLock API
- **ttlock-revoke-code**: Revokes passcodes via TTLock API

### Booking & iCal
- **ical-sync**: Parses iCal URL, syncs bookings (scheduled function)
- **automation-generate-codes**: Auto-generates codes for upcoming check-ins (scheduled)

### Messaging
- **send-message**: Sends email/SMS via Resend/Twilio

### Billing
- **stripe-create-checkout-session**: Creates Stripe Checkout session
- **stripe-create-portal-session**: Creates Stripe Customer Portal session
- **stripe-webhook**: Handles Stripe webhook events

## Local Development

```bash
# Start functions server
supabase functions serve

# Deploy to production
supabase functions deploy <function-name>
```

## Environment Variables

See `../.env.example` for required env vars (TTLock, Stripe, Resend, Twilio).

## Security

- ✅ All functions validate JWT (Supabase Auth)
- ✅ TTLock tokens never exposed to client
- ✅ Service-to-service calls use Service Role key
- ✅ Stripe webhooks verified via HMAC
- ✅ RLS policies enforce multi-tenancy
