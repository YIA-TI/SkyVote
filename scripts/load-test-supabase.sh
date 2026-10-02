#!/usr/bin/env bash
# Load-test the Supabase REST endpoint the public page polls every 3s
# (GET /rest/v1/surveys) directly, bypassing Vercel entirely. Read-only,
# does not write/mutate any data. Uses the anon key from .env (public by
# design — same key that ships in the built frontend bundle).

set -euo pipefail
cd "$(dirname "$0")/.."

SUPABASE_URL=$(grep '^VITE_SUPABASE_URL=' .env | cut -d= -f2-)
ANON_KEY=$(grep '^VITE_SUPABASE_ANON_KEY=' .env | cut -d= -f2-)

npx autocannon \
  --connections 200 \
  --duration 15 \
  --timeout 20 \
  --renderStatusCodes \
  -H "apikey: ${ANON_KEY}" \
  -H "authorization: Bearer ${ANON_KEY}" \
  "${SUPABASE_URL}/rest/v1/surveys?select=*&order=id"
