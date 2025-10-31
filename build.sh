#!/bin/bash
set -e

# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

# Build Flutter web app
cd app
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_SITE_URL=$SUPABASE_SITE_URL \
  --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
