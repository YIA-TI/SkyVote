#!/usr/bin/env bash
# Load-test the public survey page with 100 concurrent requests.
# Safe to Ctrl+C at any time — autocannon aborts in-flight requests and
# exits immediately, it never keeps running unattended.

npx autocannon \
  --connections 100 \
  --amount 100 \
  --timeout 20 \
  https://sky-vote-phi.vercel.app/
