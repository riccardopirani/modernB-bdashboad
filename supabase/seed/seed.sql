-- Seed data for local development
-- This file is run by: supabase seed run

-- Note: In production, use Auth dashboard to create users
-- For local dev, we'll insert test data directly

-- Insert test organization
INSERT INTO organizations (id, name, slug, plan, status, subscription_active, max_properties, max_team_members)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'Acme Properties', 'acme-properties', 'pro', 'active', true, 10, 5),
  ('00000000-0000-0000-0000-000000000002', 'Vacation Homes Co', 'vacation-homes', 'basic', 'active', false, 3, 2)
ON CONFLICT (id) DO NOTHING;

-- Insert test users (via Auth, but we seed profiles)
-- Note: Run these through Supabase Auth in production
-- For local testing, manually create users via Auth UI then reference them here

-- Insert test properties
INSERT INTO properties (id, org_id, name, address, city, state, postal_code, country, ical_url, description)
VALUES 
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Beachfront Villa', '123 Ocean Ave', 'Miami', 'FL', '33139', 'US', 
   'https://calendar.google.com/calendar/ical/example%40gmail.com/public/basic.ics', 'Beautiful beachfront property'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Mountain Lodge', '456 Pine Road', 'Aspen', 'CO', '81611', 'US',
   NULL, 'Mountain retreat with scenic views')
ON CONFLICT (id) DO NOTHING;

-- Insert test locks
INSERT INTO locks (id, org_id, property_id, ttlock_lock_id, ttlock_client_id, name, model, status, electric_quantity)
VALUES 
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 
   123456789, 'test_client_1', 'Front Door', 'TTLock Pro', 0, 85),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   987654321, 'test_client_1', 'Back Gate', 'TTLock Standard', 1, 60)
ON CONFLICT (id) DO NOTHING;

-- Insert test bookings
INSERT INTO bookings (id, org_id, property_id, ical_uid, guest_name, guest_email, guest_phone, 
                     check_in_date, check_out_date, check_in_time, check_out_time, status)
VALUES 
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   'airbnb-booking-001@example.com', 'John Smith', 'john@example.com', '+1234567890', 
   CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE + INTERVAL '5 days', '15:00', '11:00', 'confirmed'),
  ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   'airbnb-booking-002@example.com', 'Jane Doe', 'jane@example.com', '+0987654321',
   CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE + INTERVAL '10 days', '15:00', '11:00', 'confirmed')
ON CONFLICT (id) DO NOTHING;

-- Insert test access codes
INSERT INTO access_codes (id, org_id, property_id, lock_id, booking_id, guest_name, guest_email, guest_phone,
                          code, valid_from, valid_until, status, sent_via, sent_at)
VALUES 
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'John Smith', 'john@example.com', '+1234567890',
   '123456', CURRENT_TIMESTAMP + INTERVAL '2 days', CURRENT_TIMESTAMP + INTERVAL '5 days', 'active', 'email', CURRENT_TIMESTAMP),
  ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 'Jane Doe', 'jane@example.com', '+0987654321',
   '654321', CURRENT_TIMESTAMP + INTERVAL '7 days', CURRENT_TIMESTAMP + INTERVAL '10 days', 'active', 'sms', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- Insert test message templates
INSERT INTO message_templates (id, org_id, name, type, subject, body, variables, is_default)
VALUES 
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Check-in Code', 'email',
   'Your Check-in Code for {property_name}',
   'Hello {guest_name},\n\nYour check-in code is: {code}\n\nValid from: {check_in_time}\n\nPlease keep this code safe.',
   ARRAY['guest_name', 'property_name', 'code', 'check_in_time'], true),
  ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Check-in Code SMS', 'sms',
   NULL,
   'Hi {guest_name}, your code for {property_name} is {code}. Valid from {check_in_time}.',
   ARRAY['guest_name', 'property_name', 'code', 'check_in_time'], false)
ON CONFLICT (id) DO NOTHING;

-- Insert test message logs
INSERT INTO message_logs (id, org_id, access_code_id, recipient_email, type, subject, body, status, sent_at)
VALUES 
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001',
   'john@example.com', 'email', 'Your Check-in Code', 'Your code is 123456', 'sent', CURRENT_TIMESTAMP),
  ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002',
   NULL, 'sms', NULL, 'Your code is 654321', 'sent', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;
