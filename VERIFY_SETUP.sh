#!/bin/bash
# Quick verification script for LockFlow setup

echo "🔍 Verifying LockFlow Setup..."
echo ""

# Check Supabase URL
if grep -q "https://hdjtmmwtgiinkmqaekcn.supabase.co" flutter_app/.env 2>/dev/null; then
    echo "✅ Flutter .env configured with Supabase URL"
else
    echo "❌ Flutter .env missing Supabase URL"
fi

# Check Flutter environment config
if grep -q "https://hdjtmmwtgiinkmqaekcn.supabase.co" flutter_app/lib/core/config/environment.dart; then
    echo "✅ Flutter environment.dart configured"
else
    echo "❌ Flutter environment.dart not configured"
fi

# Check ANON_KEY
if grep -q "sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5" flutter_app/.env 2>/dev/null; then
    echo "✅ Supabase ANON_KEY configured in Flutter"
else
    echo "❌ Supabase ANON_KEY not configured"
fi

# Check documentation
echo ""
echo "📚 Documentation Files:"
for doc in PRODUCTION_SETUP.md SUPABASE_CONFIG.md ARCHITECTURE.md API_REFERENCE.md PROJECT_STATUS.md; do
    if [ -f "$doc" ]; then
        echo "✅ $doc"
    else
        echo "❌ $doc missing"
    fi
done

# Check Flutter files
echo ""
echo "🎨 Flutter Project Structure:"
for dir in flutter_app/lib/core/config flutter_app/lib/core/providers flutter_app/lib/features flutter_app/lib/ui/components; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "*.dart" 2>/dev/null | wc -l)
        echo "✅ $dir ($count files)"
    else
        echo "❌ $dir missing"
    fi
done

# Check backend
echo ""
echo "🔧 Backend Structure:"
if [ -f "supabase/migrations/001_init_schema.sql" ]; then
    lines=$(wc -l < supabase/migrations/001_init_schema.sql)
    echo "✅ Database migrations ($lines lines)"
else
    echo "❌ Database migrations missing"
fi

if [ -d "supabase/edge-functions" ]; then
    count=$(find supabase/edge-functions -name "index.ts" 2>/dev/null | wc -l)
    echo "✅ Edge Functions ($count deployed)"
else
    echo "❌ Edge Functions missing"
fi

# Check git status
echo ""
echo "📝 Git Status:"
commits=$(git log --oneline | wc -l)
echo "✅ $commits commits in history"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎯 NEXT STEPS:"
echo ""
echo "1. Get SERVICE_ROLE_KEY from Supabase Dashboard"
echo "   → https://app.supabase.com/projects/hdjtmmwtgiinkmqaekcn"
echo ""
echo "2. Add to supabase/.env.local:"
echo "   SUPABASE_SERVICE_ROLE_KEY=<your_key>"
echo ""
echo "3. Link project:"
echo "   $ supabase link --project-ref hdjtmmwtgiinkmqaekcn"
echo ""
echo "4. Push schema:"
echo "   $ supabase db push"
echo ""
echo "5. Deploy functions:"
echo "   $ supabase functions deploy ttlock-auth-start"
echo ""
echo "Full guide: See PRODUCTION_SETUP.md"
echo "════════════════════════════════════════════════════════════════"

