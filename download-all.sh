#!/usr/bin/env bash
# Download every original into ./downloads/<uploader>/<date-taken>_<original-name>
# Reads Supabase URL + anon key from docs/config.js.
set -euo pipefail
cd "$(dirname "$0")"

SUPABASE_URL=$(grep -o "supabaseUrl: '[^']*'" docs/config.js | cut -d"'" -f2)
ANON_KEY=$(grep -o "anonKey: '[^']*'" docs/config.js | cut -d"'" -f2)
COLLECT_KEY="${COLLECT_KEY:-${1:-}}"
if [ -z "$COLLECT_KEY" ]; then
  echo "Usage: ./download-all.sh <access-key>   (the k=... value from the shared link)" >&2
  exit 1
fi
OUT=downloads

curl -sf "$SUPABASE_URL/rest/v1/photos?select=uploader,storage_path,original_name,taken_at&limit=5000" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY" -H "x-collect-key: $COLLECT_KEY" |
SUPABASE_URL="$SUPABASE_URL" OUT="$OUT" python3 -c '
import json, sys, os, re, urllib.request

rows = json.load(sys.stdin)
base = os.environ["SUPABASE_URL"]
out = os.environ["OUT"]
safe = lambda s: re.sub(r"[^\w. -]", "_", s or "unknown").strip() or "unknown"

for i, r in enumerate(rows, 1):
    folder = os.path.join(out, safe(r["uploader"]))
    os.makedirs(folder, exist_ok=True)
    stamp = (r.get("taken_at") or "")[:19].replace(":", "-").replace("T", "_") or "no-date"
    name = f"{stamp}_{safe(r.get('original_name') or os.path.basename(r['storage_path']))}"
    dest = os.path.join(folder, name)
    if os.path.exists(dest):
        print(f"[{i}/{len(rows)}] skip (exists): {dest}")
        continue
    url = f"{base}/storage/v1/object/public/photos/{r['storage_path']}"
    print(f"[{i}/{len(rows)}] {dest}")
    urllib.request.urlretrieve(url, dest)

print(f"Done: {len(rows)} photos in ./{out}/")
' 2>&1
