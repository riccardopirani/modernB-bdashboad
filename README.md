# LockFlow: Multi-Tenant TTLock SaaS

Production-ready property management platform for TTLock integration with Flutter (web/iOS/Android), Supabase, and Stripe.

## Quick Start

### Prerequisites
- Flutter 3.24+
- Node.js 18+ / pnpm
- Supabase CLI
- Stripe CLI

### Local Setup

1. **Clone and install**
   ```bash
   git clone <repo>
   cd ttlockadmin
   pnpm install
   ```

2. **Backend (Supabase)**
   ```bash
   # Copy environment template
   cp supabase/.env.example supabase/.env.local
   
   # Start local Supabase
   supabase start
   
   # Run migrations
   supabase db push
   
   # Seed sample data
   pnpm run seed
   ```

3. **Edge Functions**
   ```bash
   cd supabase/edge-functions
   # Functions auto-reload on save
   ```

4. **Frontend (Flutter)**
   ```bash
   cd flutter_app
   flutter pub get
   
   # Web
   flutter run -d chrome
   
   # iOS/Android (adjust to your device/emulator)
   flutter run -d ios
   ```

5. **Stripe (optional for local development)**
   ```bash
   stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
   ```

## Project Structure

```
.
├── flutter_app/                  # Flutter frontend (web/iOS/Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                 # DI, constants, utils
│   │   ├── features/             # Feature modules (auth, properties, etc.)
│   │   └── ui/                   # Reusable component kit
│   ├── pubspec.yaml
│   └── web/
├── supabase/                      # Backend infrastructure
│   ├── config.toml                # Supabase config
│   ├── migrations/                # SQL migrations + RLS
│   ├── seed/                      # Seed scripts
│   └── edge-functions/            # TypeScript functions
│       ├── ttlock-auth-start/
│       ├── ttlock-sync-locks/
│       ├── ical-sync/
│       ├── automation-generate-codes/
│       ├── stripe-webhook/
│       └── ...
├── README.md (this file)
├── .gitignore
├── package.json                   # Monorepo tools (if using pnpm workspaces)
└── pnpm-workspace.yaml            # Workspace config
```

## Tech Stack

- **Frontend**: Flutter + Material 3 + go_router + Riverpod
- **Backend**: Supabase (Auth, PostgreSQL, RLS, Edge Functions TypeScript)
- **Payments**: Stripe (Subscriptions, Checkout, Portal, Webhooks)
- **Integrations**: TTLock, iCal (Airbnb/Booking sync), Resend/Twilio
- **Monitoring**: (Optional) Sentry, PostHog

## Key Features

### Core Product
- ✅ Multi-tenant SaaS with org-based isolation
- ✅ TTLock integration (OAuth + token refresh)
- ✅ Property + lock management (CRUD)
- ✅ iCal sync (Airbnb/Booking) with cancellation handling
- ✅ Booking-driven code generation + auto-send
- ✅ Manual code generation + revocation
- ✅ Guest management

### Billing
- ✅ Stripe subscriptions (Basic/Pro tiers)
- ✅ Feature gating (TTLock, code generation)
- ✅ Checkout + Portal sessions
- ✅ Webhook sync (subscription updates)

### Admin / Team
- ✅ Organization settings
- ✅ Team invites + member management
- ✅ Message templates (email/SMS)
- ✅ Audit logs (planned)

### UI/UX
- ✅ Premium glassmorphism design + dark mode
- ✅ Command palette (Cmd/Ctrl+K)
- ✅ Skeleton loaders + optimistic updates
- ✅ Micro-animations + page transitions
- ✅ Responsive (mobile/tablet/desktop)

## Database Schema

### Core Tables
- `organizations` – org profile, plan, usage
- `org_members` – team members + roles
- `profiles` – user profiles (auth extension)
- `integrations_ttlock` – encrypted TTLock tokens + metadata
- `properties` – property records + iCal URL
- `locks` – TTLock locks + property association
- `bookings` – iCal-synced bookings
- `access_codes` – generated codes (TTLock API)
- `message_templates` – email/SMS templates
- `message_logs` – sent messages + status
- `stripe_customers` – Stripe customer mapping
- `stripe_subscriptions` – subscription records
- `leads` – (optional) sales leads

All tables have **Row Level Security (RLS)** policies to enforce multi-tenancy.

## Environment Variables

### Supabase `.env.local`
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...

# TTLock
TTLOCK_CLIENT_ID=your_client_id
TTLOCK_CLIENT_SECRET=your_secret
TTLOCK_REDIRECT_URI=http://localhost:3000/integrations/ttlock/callback

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email / SMS
RESEND_API_KEY=re_...
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...
```

### Flutter `flutter_app/.env`
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

## Development Commands

```bash
# Backend
pnpm run db:push          # Run migrations
pnpm run seed             # Seed sample data
pnpm run functions:serve  # Start Edge Functions locally

# Frontend
cd flutter_app && flutter run -d chrome  # Web
flutter run -d ios                       # iOS
flutter run -d android                   # Android

# Testing
pnpm run test             # Run all tests
flutter test              # Flutter unit/widget tests

# Deployment (CI/CD)
# See .github/workflows/ for automated pipelines
```

## Deployment

### Supabase (Backend)
```bash
supabase link --project-ref <project-id>
supabase db push --dry-run
supabase db push
supabase functions deploy
```

### Flutter (Frontend)
- **Web**: Deploy to Vercel/Netlify using `flutter build web`
- **iOS**: Build via Xcode, submit to App Store
- **Android**: Build AAB, submit to Play Store

## Security

- ✅ Row Level Security (RLS) on all tables
- ✅ TTLock tokens encrypted at rest (Supabase Secrets)
- ✅ OAuth 2.0 for TTLock (server-side token exchange only)
- ✅ Stripe webhooks verified (HMAC)
- ✅ JWT auth (Supabase Auth)
- ✅ CORS configured per environment

## API Documentation

See `supabase/edge-functions/README.md` for Edge Functions API specs.

## Contributing

1. Create a feature branch: `git checkout -b feat/my-feature`
2. Commit with conventional commits: `git commit -m "feat: add X"`
3. Push and open PR
4. Ensure all tests pass + lints clean

## Roadmap

- [ ] Webhook retry logic + dead letter queue
- [ ] In-app notifications (real-time)
- [ ] Advanced analytics + usage reports
- [ ] Multi-property booking templates
- [ ] Guest communication hub
- [ ] Third-party integrations (Zapier, etc.)
- [ ] Mobile app refinements (push notifications)

## Support & Issues

File issues at [GitHub Issues](https://github.com/your-org/ttlockadmin/issues).

## License

TBD (Proprietary / Commercial)

---

**Last Updated**: Feb 15, 2026
