#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./deploy_supabase.sh <PROJECT_REF>
#
# Example:
#   ./deploy_supabase.sh abcdefghijklmnopqrst
#
# Notes:
# - Run from repo root where /supabase exists.
# - Requires Supabase CLI: https://supabase.com/docs/guides/cli
# - You must be logged in: supabase login

PROJECT_REF="${1:-}"

if [[ -z "$PROJECT_REF" ]]; then
  echo "❌ Missing PROJECT_REF."
  echo "Usage: ./deploy_supabase.sh <PROJECT_REF>"
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "❌ Supabase CLI not found. Install it first."
  exit 1
fi

if [[ ! -d "supabase" ]]; then
  echo "❌ ./supabase folder not found. Run this from repo root."
  exit 1
fi

echo "✅ Linking to Supabase project: $PROJECT_REF"
supabase link --project-ref "$PROJECT_REF"

echo "✅ Applying DB migrations (remote)"
# Applies all migrations in supabase/migrations to the linked remote project
supabase db push

echo "✅ Deploying Edge Functions"
# Deploy all functions found under supabase/functions/*
# If y specific ones, pass names: supabase functions deploy my-fn
supabase functions deploy --no-verify-jwt

echo "✅ Done."
echo "Tip: If you use secrets, run: supabase secrets set --env-file supabase/.env.supabase"
