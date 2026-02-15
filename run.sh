#!/bin/bash
# ─────────────────────────────────────────────
# LockFlow — Build & Serve Flutter Web App
# ─────────────────────────────────────────────

set -e

PORT=${1:-8080}
APP_DIR="$(cd "$(dirname "$0")/flutter_app" && pwd)"
BUILD_DIR="$APP_DIR/build/web"

echo "╔══════════════════════════════════════╗"
echo "║        LockFlow — Run Script         ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Step 1: Kill anything on the target port
echo "→ Freeing port $PORT..."
lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
sleep 0.5

# Step 2: Get dependencies
echo "→ Getting Flutter dependencies..."
cd "$APP_DIR"
flutter pub get --no-example

# Step 3: Build for web
echo "→ Building Flutter web (release)..."
flutter build web --no-tree-shake-icons --release

# Step 4: Serve
echo ""
echo "✓ Build complete!"
echo "→ Serving on http://localhost:$PORT"
echo "  Press Ctrl+C to stop."
echo ""

cd "$BUILD_DIR"
python3 -m http.server $PORT
