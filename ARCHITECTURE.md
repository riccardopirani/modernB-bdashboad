# LockFlow Architecture & Implementation Guide

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLIENT APPLICATIONS                             │
│  ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────┐ │
│  │   Flutter Web        │ │   Flutter iOS        │ │  Flutter Android  │ │
│  │   (Responsive)       │ │   (Responsive)       │ │  (Responsive)     │ │
│  └──────────────────────┘ └──────────────────────┘ └──────────────────┘ │
│           │                          │                        │           │
└───────────┼──────────────────────────┼────────────────────────┼───────────┘
            │                          │                        │
            └──────────────────────────┼────────────────────────┘
                                       │ HTTPS + JWT
                                       │
         ┌─────────────────────────────┴─────────────────────────────┐
         │                    SUPABASE (Backend)                      │
         │                                                            │
         │  ┌──────────────────────────────────────────────────────┐ │
         │  │              PostgreSQL Database                      │ │
         │  │  ┌────────────────────────────────────────────────┐  │ │
         │  │  │  Organizations, Members, Profiles (Auth)       │  │ │
         │  │  │  Properties, Locks, Bookings, Access Codes     │  │ │
         │  │  │  Integrations (TTLock), Message Logs, Billing  │  │ │
         │  │  │  All protected by Row-Level Security (RLS)     │  │ │
         │  │  └────────────────────────────────────────────────┘  │ │
         │  └──────────────────────────────────────────────────────┘ │
         │                                                            │
         │  ┌──────────────────────────────────────────────────────┐ │
         │  │        Authentication (JWT + OAuth)                   │ │
         │  │  - Supabase Auth (Email/Password)                     │ │
         │  │  - TTLock OAuth Integration                           │ │
         │  └──────────────────────────────────────────────────────┘ │
         │                                                            │
         │  ┌──────────────────────────────────────────────────────┐ │
         │  │            Edge Functions (TypeScript)                │ │
         │  │  ┌─────────────────────────────────────────────────┐ │ │
         │  │  │ TTLock Integration                              │ │ │
         │  │  │ - ttlock-auth-start (OAuth URL)                 │ │ │
         │  │  │ - ttlock-auth-callback (Token Exchange)         │ │ │
         │  │  │ - ttlock-sync-locks (Fetch Locks)               │ │ │
         │  │  │ - ttlock-generate-code (Create Passcode)        │ │ │
         │  │  │ - ttlock-revoke-code (Revoke Passcode)          │ │ │
         │  │  └─────────────────────────────────────────────────┘ │ │
         │  │  ┌─────────────────────────────────────────────────┐ │ │
         │  │  │ iCal Sync                                       │ │ │
         │  │  │ - ical-sync (Parse & Sync Bookings)             │ │ │
         │  │  │ - automation-generate-codes (Schedule Codes)    │ │ │
         │  │  └─────────────────────────────────────────────────┘ │ │
         │  │  ┌─────────────────────────────────────────────────┐ │ │
         │  │  │ Messaging                                       │ │ │
         │  │  │ - send-message (Email/SMS via Resend/Twilio)    │ │ │
         │  │  └─────────────────────────────────────────────────┘ │ │
         │  │  ┌─────────────────────────────────────────────────┐ │ │
         │  │  │ Billing & Payments                              │ │ │
         │  │  │ - stripe-create-checkout-session                │ │ │
         │  │  │ - stripe-create-portal-session                  │ │ │
         │  │  │ - stripe-webhook (Event Handling)               │ │ │
         │  │  └─────────────────────────────────────────────────┘ │ │
         │  └──────────────────────────────────────────────────────┘ │
         │                                                            │
         └────────────────────────────────────────────────────────────┘
                          │              │              │
                    HTTPS │              │ HTTPS        │ HTTPS
                          │              │              │
         ┌────────────────┴──┐  ┌────────┴──────┐  ┌───┴──────────────┐
         │   TTLock API      │  │  Stripe API   │  │  iCal Providers  │
         │   OAuth + REST    │  │  Webhooks     │  │  Google Cal, etc │
         └───────────────────┘  └───────────────┘  └──────────────────┘
```

## Flutter State Management (Riverpod)

```
┌─────────────────────────────────────────────┐
│         Riverpod State Providers             │
├─────────────────────────────────────────────┤
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ authNotifierProvider                   │ │
│  │ - Sign up, Sign in, Sign out           │ │
│  │ - JWT token management                 │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ currentUserProvider (Stream)           │ │
│  │ - Current authenticated user           │ │
│  │ - Listens to auth.onAuthStateChange    │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ currentOrgProvider (State)              │ │
│  │ - Selected organization context        │ │
│  │ - Used for multi-tenancy isolation     │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ propertiesProvider (StateNotifier)     │ │
│  │ - Load properties (org-scoped)         │ │
│  │ - Create, update, delete properties    │ │
│  │ - Sync iCal bookings                   │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ locksProvider (StateNotifier)          │ │
│  │ - Load locks (org-scoped)              │ │
│  │ - Sync locks from TTLock               │ │
│  │ - Assign/unassign to properties        │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ bookingsProvider (StateNotifier)       │ │
│  │ - Load bookings (org-scoped)           │ │
│  │ - Create, update, cancel bookings      │ │
│  │ - Track check-in times                 │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ accessCodesProvider (StateNotifier)    │ │
│  │ - Load access codes (org-scoped)       │ │
│  │ - Generate codes (local + TTLock)      │ │
│  │ - Revoke codes, send via email/SMS     │ │
│  └────────────────────────────────────────┘ │
│                                              │
└─────────────────────────────────────────────┘
```

## Database Schema (RLS-Enforced)

```
organizations
├── id (PK)
├── name
├── plan: "basic"|"pro"|"enterprise"
├── subscription_active: bool
├── max_properties, max_team_members

org_members ─────── profiles
├── id (PK)        ├── id (FK: auth.users)
├── org_id (FK)    ├── email
├── user_id (FK)   ├── full_name
├── role            ├── dark_mode
                    └── timezone

properties
├── id (PK)
├── org_id (FK) ─── RLS Policy: only members of org can see
├── name
├── ical_url
├── ical_last_synced_at
└── ical_sync_status

locks
├── id (PK)
├── org_id (FK) ─── RLS Policy
├── property_id (FK, nullable)
├── ttlock_lock_id (unique per org)
├── ttlock_client_id
├── name, model, status, battery_level

integrations_ttlock
├── id (PK)
├── org_id (FK, unique) ─── Only one per org
├── access_token (encrypted)
├── refresh_token (encrypted)
├── ttlock_user_id

bookings
├── id (PK)
├── org_id (FK) ─── RLS Policy
├── property_id (FK)
├── ical_uid (unique per org) ─── Idempotency key
├── guest_name, guest_email, guest_phone
├── check_in_date, check_out_date, check_in_time
├── status: "confirmed"|"cancelled"|"completed"

access_codes
├── id (PK)
├── org_id (FK) ─── RLS Policy
├── property_id (FK)
├── lock_id (FK)
├── booking_id (FK, nullable)
├── code (passcode)
├── ttlock_code_id (response from TTLock)
├── valid_from, valid_until
├── status: "active"|"used"|"revoked"|"expired"
├── sent_via: "email"|"sms"|"none"

stripe_customers
├── id (PK)
├── org_id (FK, unique) ─── One stripe customer per org
├── stripe_customer_id

stripe_subscriptions
├── id (PK)
├── org_id (FK)
├── stripe_subscription_id
├── status: "active"|"past_due"|"canceled"
├── current_period_start, current_period_end
└── plan_name: "basic"|"pro"|"enterprise"

audit_logs
├── id (PK)
├── org_id (FK) ─── RLS Policy: only admins
├── user_id (FK)
├── action, resource_type, resource_id
├── changes (JSONB)
└── created_at

message_logs
├── id (PK)
├── org_id (FK) ─── RLS Policy
├── access_code_id (FK)
├── recipient_email, recipient_phone
├── type: "email"|"sms"
├── status: "pending"|"sent"|"failed"|"bounced"
└── external_id (Resend/Twilio message ID)
```

## Data Flow Examples

### Example 1: Generate Access Code for Guest

```
1. User selects booking on Bookings page
   │
2. Click "Generate Code" button
   │
3. Frontend: Calculate valid_from & valid_until based on check-in
   │
4. Create access_codes row locally (optimistic UI)
   │
5. Call Edge Function: ttlock-generate-code
   ├─ Function: Verify JWT & org_id
   ├─ Function: Fetch TTLock credentials from DB
   ├─ Function: Call TTLock API /v3/code/create
   ├─ Function: TTLock returns: { codeId, code, createTime }
   ├─ Function: Update access_codes row with ttlock_code_id
   └─ Function: Return success
   │
6. Frontend: Update local state with TTLock response
   │
7. Show code in UI + option to send via email/SMS
   │
8. User clicks "Send Email"
   │
9. Call Edge Function: send-message
   ├─ Function: Render email template with code
   ├─ Function: Call Resend API to send email
   ├─ Function: Log message in message_logs
   └─ Function: Update access_codes.sent_via = "email"
   │
10. Done! Guest receives email with code
```

### Example 2: Sync Bookings from iCal

```
1. User adds iCal URL to property settings
   │
2. Click "Sync iCal" button
   │
3. Frontend: Call Edge Function: ical-sync
   │
4. Edge Function: ical-sync
   ├─ Verify JWT & org_id
   ├─ Fetch property from DB (RLS scoped to org)
   ├─ Fetch iCal data from URL (HTTP GET)
   ├─ Parse iCal: extract events (UID, SUMMARY, DTSTART, DTEND, STATUS)
   ├─ Handle cancellations: set status = "cancelled"
   ├─ For each event:
   │  └─ UPSERT into bookings (org_id, ical_uid)
   │     → Idempotent: re-running sync won't create duplicates
   ├─ Update property: ical_last_synced_at = now()
   └─ Return: { success: true, synced_count: 5 }
   │
5. Frontend: Update properties provider
   │
6. Dashboard now shows upcoming bookings
   │
7. Optional: Trigger automation
   └─ For each upcoming booking (check-in within 24h):
      ├─ If no access code exists:
      └─ Auto-generate code + send email
```

### Example 3: Stripe Subscription Webhook

```
1. Customer purchases Pro plan on Checkout
   │
2. Stripe captures payment
   │
3. Stripe sends webhook: POST /functions/v1/stripe-webhook
   ├─ Event type: "customer.subscription.updated"
   ├─ Payload: { subscription: { id, customer, status, ...} }
   │
4. Edge Function: stripe-webhook
   ├─ Verify signature (HMAC-SHA256)
   ├─ Fetch org from stripe_customers (org_id)
   ├─ UPDATE stripe_subscriptions row
   ├─ UPDATE organizations:
   │  ├─ subscription_active = true
   │  ├─ plan = "pro" (from metadata)
   │  └─ subscription_ends_at = null
   └─ Return: { received: true }
   │
5. Frontend: Next auth refresh picks up new plan
   │
6. RLS policies now allow:
   └─ ttlock-generate-code, ttlock-sync-locks, etc.
```

## Environment Variables

### Supabase (`supabase/.env.local`)
```bash
# Supabase URLs & Keys (from: supabase status)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ... (for client auth)
SUPABASE_SERVICE_ROLE_KEY=eyJ... (for server/functions)

# TTLock OAuth
TTLOCK_CLIENT_ID=your_client_id
TTLOCK_CLIENT_SECRET=your_secret
TTLOCK_REDIRECT_URI=http://localhost:3000/integrations/ttlock/callback
TTLOCK_BASE_URL=https://api.ttlock.eu

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email (Resend)
RESEND_API_KEY=re_...
RESEND_FROM_EMAIL=noreply@lockflow.local

# SMS (Twilio)
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1234567890
```

### Flutter (`flutter_app/.env`)
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ... (same as above)
STRIPE_PUBLISHABLE_KEY=pk_test_... (same as above)
```

## Deployment Checklist

- [ ] Production Supabase project created
- [ ] Database migrations applied
- [ ] RLS policies verified
- [ ] All Edge Functions deployed
- [ ] Environment variables configured
- [ ] TTLock OAuth credentials set
- [ ] Stripe API keys configured + webhooks pointed to production
- [ ] Resend/Twilio credentials set
- [ ] Flutter app built for web/iOS/Android
- [ ] Web app deployed (Vercel/Netlify)
- [ ] iOS app submitted to App Store
- [ ] Android app submitted to Play Store
- [ ] Custom domain configured
- [ ] SSL/TLS certificate installed
- [ ] Monitoring & error tracking (Sentry) setup

## Security Best Practices

✅ **Implemented:**
- Row-Level Security (RLS) on all tables
- TTLock tokens encrypted at rest (Supabase vaults)
- OAuth 2.0 for third-party integrations
- JWT authentication for all API calls
- Stripe webhook verification (HMAC)
- Service-to-service calls use SERVICE_ROLE_KEY
- CORS configured per environment

🔲 **Recommended for Production:**
- API rate limiting
- DDoS protection (Cloudflare)
- Audit logging (all data changes)
- Intrusion detection
- Regular security audits
- Encryption for sensitive data fields
- Secrets rotation policy

## Next Steps (Post-MVP)

1. **Testing**
   - Unit tests for providers
   - Widget tests for UI
   - Integration tests for Edge Functions
   - E2E tests with Playwright

2. **Performance**
   - Implement pagination for large lists
   - Add local caching (Hive/SQLite)
   - Optimize images
   - Code splitting for Flutter web

3. **Features**
   - Real-time notifications (WebSocket)
   - Bulk code generation
   - Guest communication hub
   - Advanced analytics
   - Multi-language support
   - White-label options

4. **Analytics**
   - Post-hog event tracking
   - Usage analytics
   - Performance monitoring
   - Error tracking (Sentry)

---

**Created**: Feb 15, 2026
**Last Updated**: Feb 15, 2026
