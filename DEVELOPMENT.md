# LockFlow Development Guide

## Architecture Overview

LockFlow is a multi-tenant SaaS built with:
- **Frontend**: Flutter (web/iOS/Android) with Material 3 + Riverpod
- **Backend**: Supabase (PostgreSQL + Auth + Edge Functions)
- **Payments**: Stripe (Subscriptions, Checkout, Portal)
- **Integrations**: TTLock API, iCal sync, Resend/Twilio

### Multi-Tenancy

All data is scoped to `organizations`:
- Row-Level Security (RLS) enforces org isolation
- Users belong to org via `org_members`
- All tables have `org_id` foreign key
- Service-to-service calls use `SUPABASE_SERVICE_ROLE_KEY`

## Project Structure

```
ttlockadmin/
├── flutter_app/                    # Flutter frontend
│   ├── lib/
│   │   ├── main.dart               # App entry, themes, router
│   │   ├── config/
│   │   │   └── router.dart         # GoRouter setup
│   │   ├── core/
│   │   │   ├── config/
│   │   │   │   ├── environment.dart    # Env vars
│   │   │   │   └── theme.dart         # Design tokens
│   │   │   └── providers/
│   │   │       ├── auth_provider.dart       # Auth state
│   │   │       ├── properties_provider.dart  # Properties CRUD
│   │   │       ├── locks_provider.dart      # Locks sync
│   │   │       ├── bookings_provider.dart   # Bookings
│   │   │       └── access_codes_provider.dart
│   │   ├── features/
│   │   │   └── dashboard/
│   │   │       └── dashboard_page.dart      # Home page
│   │   └── ui/
│   │       ├── components/
│   │       │   ├── buttons/
│   │       │   ├── cards/
│   │       │   ├── inputs/
│   │       │   └── loaders/
│   │       └── shell/
│   │           ├── app_shell.dart
│   │           ├── sidebar_nav.dart
│   │           └── top_bar.dart
│   ├── web/
│   │   └── index.html
│   ├── pubspec.yaml
│   └── .env.example
├── supabase/
│   ├── config.toml                 # Local dev config
│   ├── migrations/
│   │   └── 001_init_schema.sql     # Schema + RLS
│   ├── seed/
│   │   └── seed.sql                # Sample data
│   └── edge-functions/
│       ├── ttlock-auth-start/
│       ├── ttlock-auth-callback/
│       ├── ttlock-sync-locks/
│       ├── ttlock-generate-code/
│       ├── ttlock-revoke-code/
│       ├── ical-sync/
│       ├── automation-generate-codes/
│       ├── send-message/
│       ├── stripe-create-checkout-session/
│       ├── stripe-create-portal-session/
│       └── stripe-webhook/
├── .gitignore
├── README.md
└── package.json
```

## Local Setup

### 1. Clone & Install

```bash
git clone <repo>
cd ttlockadmin
pnpm install
```

### 2. Supabase Local Development

```bash
# Install Supabase CLI
# https://supabase.com/docs/guides/cli

# Start local Supabase (requires Docker)
supabase start

# Output will show:
# - API URL: http://localhost:54321
# - Anon Key: eyJ...
# - Service Role: eyJ...
```

Copy the keys to your environment files.

### 3. Run Migrations

```bash
# Auto-detect and run migrations
supabase db push

# Verify schema
supabase db list
```

### 4. Seed Sample Data

```bash
supabase seed run
```

### 5. Start Edge Functions

```bash
# In a new terminal
supabase functions serve
# Functions will auto-reload on file changes
```

### 6. Setup Flutter

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Generate code (Riverpod, JSON serialization)
flutter pub run build_runner build

# Start web dev server
flutter run -d chrome

# Or iOS (requires Xcode)
flutter run -d ios

# Or Android (requires emulator/device)
flutter run
```

### 7. Environment Files

**`supabase/.env.local`**
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
TTLOCK_CLIENT_ID=your_id
TTLOCK_CLIENT_SECRET=your_secret
STRIPE_SECRET_KEY=sk_test_...
```

**`flutter_app/.env`**
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

## API Routes

### Authentication
- `POST /auth/v1/signup` – Sign up
- `POST /auth/v1/signin` – Sign in
- `POST /auth/v1/logout` – Sign out
- `POST /auth/v1/refresh` – Refresh token

### Edge Functions (with Bearer token)
- `POST /functions/v1/ttlock-auth-start` – Get TTLock OAuth URL
- `POST /functions/v1/ttlock-auth-callback` – Exchange OAuth code
- `POST /functions/v1/ttlock-sync-locks` – Sync locks from TTLock
- `POST /functions/v1/ttlock-generate-code` – Generate access code
- `POST /functions/v1/ical-sync` – Sync bookings from iCal URL
- `POST /functions/v1/send-message` – Send email/SMS
- `POST /functions/v1/stripe-webhook` – Stripe webhook (no auth)

## Database Schema

### Core Tables
- **organizations** – Org profile, plan, subscription status
- **org_members** – Team members, roles (owner/admin/member)
- **profiles** – User profiles, extended from auth.users

### Integration
- **integrations_ttlock** – Encrypted TTLock tokens

### Properties & Locks
- **properties** – Property records, iCal URLs
- **locks** – TTLock locks, assigned to properties

### Bookings & Access
- **bookings** – iCal-synced reservations (idempotent UID-based)
- **access_codes** – Generated passcodes for guests

### Messaging
- **message_templates** – Email/SMS templates
- **message_logs** – Sent messages with status

### Billing
- **stripe_customers** – Stripe customer mapping
- **stripe_subscriptions** – Subscription records

### Audit
- **audit_logs** – Org activity logs

## State Management (Riverpod)

### Providers
- **`authNotifierProvider`** – Auth state (login/signup/logout)
- **`currentUserProvider`** – Current authenticated user (stream)
- **`currentOrgProvider`** – Selected organization context
- **`propertiesProvider`** – Properties CRUD operations
- **`locksProvider`** – Locks sync & assignment
- **`bookingsProvider`** – Bookings list & filtering
- **`accessCodesProvider`** – Code generation & revocation

### Usage
```dart
final properties = ref.watch(propertiesProvider);
final isDone = await ref.read(locksProvider.notifier).syncLocks();
```

## UI Design System

### Colors
- **Light**: Neutral palette (blacks/grays/whites)
- **Dark**: Dark theme-first (Material 3)
- **Accents**: Blue (#3B82F6)

### Spacing Scale
```
xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 24px, xxl: 32px
```

### Components
- **AppButton** – Variants: primary, secondary, ghost
- **AppCard** – Elevation + glassmorphism option
- **AppTextField** – Validation, icons, error states
- **AppSkeletonLoader** – Shimmer animation
- **AppShell** – Responsive sidebar + top bar

### Responsive Breakpoints
- Mobile: <600px
- Tablet: 600-1024px
- Desktop: >1024px

## Deployment

### Supabase
```bash
supabase link --project-ref <project-id>
supabase db push
supabase functions deploy ttlock-auth-start
# ... deploy all functions
```

### Flutter Web
```bash
flutter build web --release
# Deploy to Vercel/Netlify
vercel deploy --prod
```

### Flutter iOS/Android
```bash
flutter build ipa  # iOS
flutter build appbundle  # Android
# Submit to App Store / Play Store
```

## Key Features Implementation

### TTLock Integration
1. User clicks "Connect TTLock"
2. Frontend calls `ttlock-auth-start` → get OAuth URL
3. User authorizes on TTLock
4. TTLock redirects to callback → calls `ttlock-auth-callback`
5. Edge Function exchanges code, stores encrypted tokens
6. Frontend can now call `ttlock-sync-locks` to fetch locks

### iCal Sync
1. User provides iCal URL in property settings
2. Manual sync: `Sync Locks` button calls `ical-sync`
3. Edge Function fetches iCal, parses events, upserts bookings (UID-based)
4. Handles cancellations (sets status to cancelled)

### Code Generation
1. Booking created from iCal
2. On check-in day, auto-generate code:
   - Create `access_codes` record
   - Call `ttlock-generate-code` Edge Function
   - Edge Function calls TTLock API → creates passcode
   - Optional: auto-send via `send-message` function
3. User can manually revoke codes

### Billing
1. User selects plan → Stripe Checkout session created
2. Stripe redirects to success page
3. Webhook updates subscription in DB (RLS enforced)
4. Features gated by `organizations.plan` + RLS

## Testing

### Unit Tests (Flutter)
```bash
flutter test
```

### Edge Function Tests
```bash
# Local: invoke functions during supabase functions serve
# Integration: test full flow with curl
curl -X POST http://localhost:54321/functions/v1/ical-sync \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"property_id":"...", "org_id":"..."}'
```

## Security Checklist

- ✅ TTLock tokens encrypted at rest (Supabase vaults)
- ✅ All Edge Functions verify JWT + org_id
- ✅ RLS policies enforce multi-tenancy
- ✅ Stripe webhooks verified (HMAC)
- ✅ CORS configured per environment
- ✅ Service-to-service calls use SERVICE_ROLE_KEY

## Common Tasks

### Add a New Feature
1. Add database table in migration
2. Add RLS policy
3. Create Riverpod provider for state
4. Create UI page/widget
5. Wire into router
6. Test locally

### Add a New Edge Function
1. Create folder: `supabase/edge-functions/my-function/`
2. Add `index.ts` with request/response handling
3. Add to deployment workflow
4. Test with `supabase functions serve`

### Customize Theme
Edit `lib/core/config/theme.dart`:
- `AppColors` – Color palette
- `AppSpacing` – Spacing scale
- `AppRadius` – Border radius
- `AppElevation` – Shadows

## Troubleshooting

### Supabase not starting
```bash
# Make sure Docker is running
docker ps

# Rebuild containers
supabase stop
supabase start
```

### Flutter build failing
```bash
# Clean build artifacts
flutter clean
flutter pub get

# Regenerate code
flutter pub run build_runner clean
flutter pub run build_runner build
```

### Edge Functions not deploying
```bash
# Check syntax
deno check supabase/edge-functions/my-function/index.ts

# Check environment variables
cat supabase/.env.local
```

### RLS permission errors
- Verify user is in `org_members` for that org
- Check RLS policies: `SELECT * FROM pg_policies`
- Test with service role (no RLS) to verify data exists

## Next Steps

1. ✅ Schema + migrations + RLS
2. ✅ Edge Functions scaffolding
3. ✅ Flutter UI kit + AppShell
4. ✅ Dashboard with KPIs
5. 🔲 Properties CRUD page
6. 🔲 Locks assignment UI
7. 🔲 Bookings & codes management
8. 🔲 TTLock integration UI
9. 🔲 Stripe checkout integration
10. 🔲 Email/SMS automation
11. 🔲 Polish + micro-animations
12. 🔲 Unit tests + docs

---

**Last Updated**: Feb 15, 2026
