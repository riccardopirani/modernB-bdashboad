#!/bin/bash
# setup.sh - Complete setup script for LockFlow local development

set -e

echo "🚀 LockFlow Local Setup"
echo "======================"
echo ""

# Check prerequisites
echo "1️⃣  Checking prerequisites..."
command -v supabase &> /dev/null || { echo "❌ Supabase CLI not found. Install from: https://supabase.com/docs/guides/cli"; exit 1; }
command -v flutter &> /dev/null || { echo "❌ Flutter not found. Install from: https://flutter.dev"; exit 1; }
command -v pnpm &> /dev/null || { echo "❌ pnpm not found. Install from: https://pnpm.io"; exit 1; }
echo "✅ All prerequisites found"
echo ""

# Clone templates if needed
echo "2️⃣  Setting up monorepo..."
mkdir -p supabase/edge-functions
echo "✅ Monorepo structure ready"
echo ""

# Start Supabase
echo "3️⃣  Starting Supabase..."
if command -v docker &> /dev/null; then
    supabase start
    echo "✅ Supabase started"
else
    echo "⚠️  Docker not found - Supabase requires Docker"
    exit 1
fi
echo ""

# Wait for Supabase to be ready
echo "4️⃣  Waiting for Supabase to be ready..."
sleep 5

# Get Supabase credentials
SUPABASE_URL="http://localhost:54321"
echo "📝 Supabase URL: $SUPABASE_URL"

# Run migrations
echo "5️⃣  Running database migrations..."
supabase db push
echo "✅ Migrations complete"
echo ""

# Seed sample data
echo "6️⃣  Seeding sample data..."
supabase seed run
echo "✅ Sample data loaded"
echo ""

# Setup Flutter
echo "7️⃣  Setting up Flutter..."
cd flutter_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
cd ..
echo "✅ Flutter setup complete"
echo ""

# Create .env files from examples
echo "8️⃣  Setting up environment files..."
if [ ! -f supabase/.env.local ]; then
    cp supabase/.env.example supabase/.env.local
    echo "⚠️  Created supabase/.env.local - please update with real credentials"
fi

if [ ! -f flutter_app/.env ]; then
    cp flutter_app/.env.example flutter_app/.env
    echo "⚠️  Created flutter_app/.env - please update with real credentials"
fi
echo ""

echo "✅ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Open two terminals:"
echo "   Terminal 1: supabase functions serve"
echo "   Terminal 2: cd flutter_app && flutter run -d chrome"
echo ""
echo "2. Get your Supabase credentials from:"
echo "   supabase status"
echo ""
echo "3. Update .env files with real credentials (TTLock, Stripe, etc.)"
echo ""
echo "📚 See DEVELOPMENT.md for detailed guide"
