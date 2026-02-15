# 🚀 LockFlow Production Setup - Quick Start

Your Supabase credentials are now configured! Here's what to do next:

## Step 1: Setup Supabase Remote Database

```bash
# Link your Supabase project
supabase link --project-ref hdjtmmwtgiinkmqaekcn

# Run migrations to create schema & RLS policies
supabase db push

# Deploy Edge Functions
supabase functions deploy ttlock-auth-start
supabase functions deploy ttlock-auth-callback
supabase functions deploy ttlock-sync-locks
supabase functions deploy ttlock-generate-code
supabase functions deploy ical-sync
supabase functions deploy stripe-webhook
# ... deploy remaining functions
```

## Step 2: Configure Environment Variables

Update `supabase/.env.local` with:
- **TTLOCK_CLIENT_ID** & **TTLOCK_CLIENT_SECRET** (from TTLock Developer Console)
- **STRIPE_SECRET_KEY** & **STRIPE_WEBHOOK_SECRET** (from Stripe Dashboard)
- **RESEND_API_KEY** (from Resend)
- **TWILIO_ACCOUNT_SID**, **TWILIO_AUTH_TOKEN**, **TWILIO_PHONE_NUMBER** (from Twilio)

## Step 3: Configure Flutter

Your Flutter app is already configured to use:
```
SUPABASE_URL=https://hdjtmmwtgiinkmqaekcn.supabase.co
SUPABASE_ANON_KEY=sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5
```

**Already in**: `flutter_app/.env`

## Step 4: Run Flutter App

```bash
cd flutter_app

# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Or iOS/Android
flutter run -d ios
```

## Step 5: Important - Configure Supabase Auth

In your Supabase Dashboard:

1. **Authentication Settings**:
   - Go to: Settings → Authentication
   - Add your frontend URL to "Redirect URLs"
   - Example: `http://localhost:5173`, `https://your-domain.com`

2. **Enable Providers** (if using):
   - Google OAuth
   - GitHub OAuth
   - etc.

3. **Setup Email Provider**:
   - Configure SMTP for email confirmations
   - Or use Supabase's built-in email provider

## Step 6: Configure TTLock Integration

1. Go to [TTLock Developer Portal](https://developer.ttlock.eu)
2. Create OAuth Application:
   - **Client ID**: `TTLOCK_CLIENT_ID`
   - **Client Secret**: `TTLOCK_CLIENT_SECRET`
   - **Redirect URI**: `https://your-domain.com/functions/v1/ttlock-auth-callback`

3. Update `supabase/.env.local`:
   ```bash
   TTLOCK_CLIENT_ID=your_id
   TTLOCK_CLIENT_SECRET=your_secret
   TTLOCK_REDIRECT_URI=https://your-domain.com/functions/v1/ttlock-auth-callback
   ```

## Step 7: Configure Stripe

1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Get your API keys:
   - **Secret Key**: `STRIPE_SECRET_KEY`
   - **Publishable Key**: `STRIPE_PUBLISHABLE_KEY`
   - **Webhook Secret**: Create a webhook endpoint for: `https://your-domain.com/functions/v1/stripe-webhook`

3. Update files:
   - `supabase/.env.local`: Add keys
   - `flutter_app/.env`: Add `STRIPE_PUBLISHABLE_KEY`

4. Create Stripe Products/Prices:
   - Basic: $9/month
   - Pro: $29/month
   - Enterprise: Custom

## Step 8: Configure Email/SMS

### Resend (Email)
```bash
# Get API key from https://resend.com
RESEND_API_KEY=re_your_key
RESEND_FROM_EMAIL=noreply@your-domain.com
```

### Twilio (SMS)
```bash
# Get from https://www.twilio.com
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=+1234567890
```

## Step 9: Verify Edge Functions

Test that Edge Functions are working:

```bash
# Get a JWT token from your Supabase app
# Then test an endpoint:

curl -X POST https://hdjtmmwtgiinkmqaekcn.supabase.co/functions/v1/ttlock-sync-locks \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"org_id":"YOUR_ORG_ID"}'
```

## Step 10: Deploy Frontend

### Vercel (Recommended for Flutter Web)
```bash
cd flutter_app

# Build for production
flutter build web --release

# Deploy to Vercel
vercel deploy --prod
```

### Netlify
```bash
# Build
flutter build web --release

# Deploy
netlify deploy --prod --dir=build/web
```

## Checklist

- [ ] Supabase project linked locally
- [ ] Migrations applied to production DB
- [ ] Edge Functions deployed
- [ ] TTLock OAuth configured
- [ ] Stripe keys configured
- [ ] Resend/Twilio configured
- [ ] Flutter app runs locally
- [ ] Frontend deployed
- [ ] Auth redirects configured
- [ ] Webhook endpoints verified

## Useful Links

- Supabase Dashboard: https://app.supabase.com/projects
- Supabase API Docs: https://supabase.com/docs
- TTLock Developer: https://developer.ttlock.eu
- Stripe Dashboard: https://dashboard.stripe.com
- Resend: https://resend.com
- Twilio: https://www.twilio.com

## Troubleshooting

### "RLS policy violation"
- Check that user is in `org_members` table
- Verify RLS policies are enabled
- Use Service Role key for admin operations

### "TTLock API error"
- Verify `TTLOCK_CLIENT_ID` and `TTLOCK_CLIENT_SECRET`
- Check token isn't expired (tokens refresh automatically)
- Ensure redirect URI matches exactly

### "Stripe webhook not received"
- Verify webhook endpoint is accessible
- Check webhook signature verification
- Look at Stripe dashboard for failed deliveries

### "Flutter app can't connect"
- Verify SUPABASE_URL in `.env` file
- Check internet connection
- Verify ANON_KEY is correct
- Try: `flutter clean && flutter pub get`

---

**Your app is ready to launch! 🎉**

Questions? Check:
1. `DEVELOPMENT.md` – Local dev guide
2. `ARCHITECTURE.md` – System design
3. `API_REFERENCE.md` – API endpoints
4. `PROJECT_STATUS.md` – What's implemented

---

**Last Updated**: Feb 15, 2026
