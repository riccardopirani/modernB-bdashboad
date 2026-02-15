# 🔑 Supabase Configuration Reference Card

## Your Project Details

```
Project Reference ID: hdjtmmwtgiinkmqaekcn
Project URL:         https://hdjtmmwtgiinkmqaekcn.supabase.co
Anon Key:            sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5
Region:              (check Supabase dashboard)
```

## Where Credentials Are Used

### Flutter App (`flutter_app/.env`)
```bash
SUPABASE_URL=https://hdjtmmwtgiinkmqaekcn.supabase.co
SUPABASE_ANON_KEY=sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5
```
✅ Used by: `flutter_app/lib/core/providers/auth_provider.dart`

### Backend (`supabase/.env.local`) - NOT in git
```bash
SUPABASE_URL=https://hdjtmmwtgiinkmqaekcn.supabase.co
SUPABASE_ANON_KEY=sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5
SUPABASE_SERVICE_ROLE_KEY=<GET THIS FROM DASHBOARD>
```
✅ Used by: Edge Functions, CLI deployment

## Quick Commands

### Link Supabase Project
```bash
supabase link --project-ref hdjtmmwtgiinkmqaekcn
```

### View Supabase Status
```bash
supabase status
```

### Push Database Schema
```bash
supabase db push
```

### Deploy Edge Functions
```bash
supabase functions deploy <function-name>
```

### View Logs
```bash
supabase functions logs <function-name>
```

## Critical: Get Service Role Key

1. Go to: https://app.supabase.com/projects
2. Select your project
3. Settings → API
4. Under "Project API keys" find "service_role" (marked as secret)
5. Copy it
6. Add to `supabase/.env.local`:
   ```bash
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
   ```

## Environment Files

| File | Purpose | In Git? | When Used |
|------|---------|---------|-----------|
| `flutter_app/.env` | Runtime (Flutter) | ❌ NO | App startup |
| `flutter_app/.env.example` | Template | ✅ YES | Documentation |
| `supabase/.env.local` | Backend secrets | ❌ NO | Deployment |
| `supabase/.env.example` | Template | ✅ YES | Documentation |

## Flutter Code

These constants are set in: `flutter_app/lib/core/config/environment.dart`

```dart
class Environment {
  static const String supabaseUrl = 
    'https://hdjtmmwtgiinkmqaekcn.supabase.co';
  
  static const String supabaseAnonKey = 
    'sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5';
}
```

Used everywhere in the app:
- Auth provider: `Supabase.initialize(url: Environment.supabaseUrl, ...)`
- API calls: `supabase.from('table').select()`
- Real-time: `supabase.from('bookings').on(...).subscribe()`

## Security Checklist

- [ ] ANON_KEY is public (safe to expose)
- [ ] SERVICE_ROLE_KEY is secret (NEVER expose)
- [ ] .env files are in .gitignore
- [ ] Verified Edge Functions can connect
- [ ] RLS policies are enabled
- [ ] Auth providers are configured
- [ ] Webhook endpoints are set up

## Testing Connection

From Flutter:
```dart
final response = await supabase.auth.getSession();
if (response != null) {
  print('✅ Connected to Supabase!');
}
```

From Edge Function:
```typescript
const { data: { user }, error } = await supabase.auth.getUser();
if (error) console.error('❌ Auth error:', error);
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Check ANON_KEY format |
| Connection timeout | Check Project URL is correct |
| RLS policy error | Verify user is in org_members table |
| Function not found | Run `supabase functions deploy` |

## Useful Links

- Dashboard: https://app.supabase.com
- Your Project: https://app.supabase.com/projects/hdjtmmwtgiinkmqaekcn
- API Docs: https://supabase.com/docs/guides/api
- Reference: https://supabase.com/docs/reference/javascript

---

**⚡ All configured and ready to go!**
