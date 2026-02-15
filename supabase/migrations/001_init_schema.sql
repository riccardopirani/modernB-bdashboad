-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable RLS by default
ALTER DATABASE postgres SET "app.settings.enforce_rls" TO 'on';

-- ============================================================================
-- AUTH & MULTI-TENANCY
-- ============================================================================

-- organizations table
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  plan TEXT NOT NULL DEFAULT 'basic' CHECK (plan IN ('basic', 'pro', 'enterprise')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled')),
  stripe_customer_id TEXT,
  subscription_active BOOLEAN DEFAULT FALSE,
  subscription_ends_at TIMESTAMP,
  max_properties INT DEFAULT 5,
  max_team_members INT DEFAULT 3,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- org_members table (users in organization)
CREATE TABLE org_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  email TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(org_id, user_id)
);

ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

-- profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  timezone TEXT DEFAULT 'UTC',
  dark_mode BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INTEGRATIONS
-- ============================================================================

CREATE TABLE integrations_ttlock (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  access_token TEXT NOT NULL, -- encrypted
  refresh_token TEXT, -- encrypted
  token_expires_at TIMESTAMP,
  ttlock_user_id TEXT NOT NULL,
  ttlock_client_id TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  last_synced_at TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE integrations_ttlock ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROPERTY MANAGEMENT
-- ============================================================================

CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'US',
  ical_url TEXT,
  ical_last_synced_at TIMESTAMP,
  ical_sync_status TEXT DEFAULT 'idle' CHECK (ical_sync_status IN ('idle', 'syncing', 'error')),
  ical_sync_error TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_properties_org_id ON properties(org_id);

CREATE TABLE locks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  ttlock_lock_id BIGINT NOT NULL,
  ttlock_client_id TEXT NOT NULL,
  name TEXT NOT NULL,
  model TEXT,
  feature_value INT,
  status INT DEFAULT 0, -- 0=locked, 1=unlocked
  electric_quantity INT DEFAULT -1, -- battery %
  longitude NUMERIC,
  latitude NUMERIC,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(org_id, ttlock_lock_id, ttlock_client_id)
);

ALTER TABLE locks ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_locks_org_id ON locks(org_id);
CREATE INDEX idx_locks_property_id ON locks(property_id);

-- ============================================================================
-- BOOKINGS & ACCESS
-- ============================================================================

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  ical_uid TEXT NOT NULL, -- Unique ID from iCal, used for idempotency
  guest_name TEXT NOT NULL,
  guest_email TEXT,
  guest_phone TEXT,
  check_in_date DATE NOT NULL,
  check_out_date DATE NOT NULL,
  check_in_time TIME DEFAULT '15:00',
  check_out_time TIME DEFAULT '11:00',
  status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(org_id, ical_uid)
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_bookings_org_id ON bookings(org_id);
CREATE INDEX idx_bookings_property_id ON bookings(property_id);
CREATE INDEX idx_bookings_check_in_date ON bookings(check_in_date);

CREATE TABLE access_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  lock_id UUID NOT NULL REFERENCES locks(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  guest_name TEXT,
  guest_email TEXT,
  guest_phone TEXT,
  code TEXT NOT NULL,
  ttlock_code_id BIGINT, -- TTLock response ID
  valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  times_used INT DEFAULT 0,
  max_uses INT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'used', 'revoked', 'expired')),
  sent_via TEXT, -- 'email', 'sms', 'none'
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE access_codes ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_access_codes_org_id ON access_codes(org_id);
CREATE INDEX idx_access_codes_property_id ON access_codes(property_id);
CREATE INDEX idx_access_codes_booking_id ON access_codes(booking_id);

-- ============================================================================
-- MESSAGING
-- ============================================================================

CREATE TABLE message_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('email', 'sms')),
  subject TEXT, -- for email
  body TEXT NOT NULL,
  variables TEXT[] DEFAULT ARRAY[]::TEXT[], -- {guest_name, code, check_in, check_out}
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE message_templates ENABLE ROW LEVEL SECURITY;

CREATE TABLE message_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  access_code_id UUID REFERENCES access_codes(id) ON DELETE SET NULL,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  recipient_email TEXT,
  recipient_phone TEXT,
  type TEXT NOT NULL CHECK (type IN ('email', 'sms')),
  subject TEXT,
  body TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'bounced')),
  error_message TEXT,
  external_id TEXT, -- Resend/Twilio message ID
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE message_logs ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_message_logs_org_id ON message_logs(org_id);

-- ============================================================================
-- BILLING / STRIPE
-- ============================================================================

CREATE TABLE stripe_customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE CASCADE,
  stripe_customer_id TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE stripe_customers ENABLE ROW LEVEL SECURITY;

CREATE TABLE stripe_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  stripe_subscription_id TEXT NOT NULL UNIQUE,
  stripe_customer_id TEXT NOT NULL,
  status TEXT NOT NULL, -- active, past_due, canceled, unpaid
  plan_name TEXT NOT NULL, -- basic, pro, enterprise
  current_period_start TIMESTAMP,
  current_period_end TIMESTAMP,
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  canceled_at TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE stripe_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_stripe_subscriptions_org_id ON stripe_subscriptions(org_id);

-- ============================================================================
-- AUDIT & LEADS
-- ============================================================================

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id TEXT,
  changes JSONB,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  company TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'lost', 'converted')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Organizations: Users can see orgs they're a member of
CREATE POLICY "org_select_policy" ON organizations
  FOR SELECT
  USING (
    id IN (
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT org_id FROM integrations_ttlock WHERE org_id IS NOT NULL
      AND org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    )
  );

-- Organization members: only org members can see/manage their org's members
CREATE POLICY "org_members_select" ON org_members
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "org_members_insert" ON org_members
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "org_members_delete" ON org_members
  FOR DELETE
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Profiles: Users can see their own profile, admins can see all
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT
  USING (id = auth.uid() OR auth.jwt()->>'role' = 'authenticated');

CREATE POLICY "profiles_update" ON profiles
  FOR UPDATE
  USING (id = auth.uid());

-- TTLock integrations: org members only
CREATE POLICY "ttlock_integrations_select" ON integrations_ttlock
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "ttlock_integrations_insert" ON integrations_ttlock
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "ttlock_integrations_update" ON integrations_ttlock
  FOR UPDATE
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Properties: org members only
CREATE POLICY "properties_select" ON properties
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "properties_insert" ON properties
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "properties_update" ON properties
  FOR UPDATE
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "properties_delete" ON properties
  FOR DELETE
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Locks: org members only
CREATE POLICY "locks_select" ON locks
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "locks_update" ON locks
  FOR UPDATE
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Bookings: org members only
CREATE POLICY "bookings_select" ON bookings
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Access codes: org members only
CREATE POLICY "access_codes_select" ON access_codes
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "access_codes_insert" ON access_codes
  FOR INSERT
  WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Message templates: org members only
CREATE POLICY "message_templates_select" ON message_templates
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "message_templates_insert" ON message_templates
  FOR INSERT
  WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "message_templates_update" ON message_templates
  FOR UPDATE
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Message logs: org members only (read-only)
CREATE POLICY "message_logs_select" ON message_logs
  FOR SELECT
  USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Stripe customers: org admins only
CREATE POLICY "stripe_customers_select" ON stripe_customers
  FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Stripe subscriptions: org admins only
CREATE POLICY "stripe_subscriptions_select" ON stripe_subscriptions
  FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Audit logs: org admins only
CREATE POLICY "audit_logs_select" ON audit_logs
  FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM org_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to create a profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER properties_updated_at BEFORE UPDATE ON properties
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER locks_updated_at BEFORE UPDATE ON locks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER integrations_ttlock_updated_at BEFORE UPDATE ON integrations_ttlock
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER bookings_updated_at BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER access_codes_updated_at BEFORE UPDATE ON access_codes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER message_templates_updated_at BEFORE UPDATE ON message_templates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER stripe_subscriptions_updated_at BEFORE UPDATE ON stripe_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
