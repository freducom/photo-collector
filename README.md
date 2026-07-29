# Photo Collector

Collect full-quality photos from a group of people — no login, they just enter
their name once. Backed by Supabase (storage + Postgres), frontend is three
static files.

## How it works

- **`web/index.html`** — the page you share. Asks for a name (remembered in
  localStorage), then lets people multi-select photos from their phone.
  Originals are uploaded untouched to the `photos` storage bucket; a ~1000px
  JPEG thumbnail is generated in the browser for the gallery. Date taken is
  read from EXIF (`DateTimeOriginal`), falling back to the file's modified time.
- **`web/gallery.html`** — your view. Sort by date taken / upload time, filter
  or group by uploader. Tiles link to the full-quality original.
- **`supabase/schema.sql`** — one `photos` table + public `photos` bucket.
  Anonymous visitors can insert and read, but not update or delete.
- **`download-all.sh`** — pulls every original into
  `downloads/<uploader>/<date-taken>_<name>` on your machine.

## Deploy

The static files live in the same Supabase project, in a public `web` storage
bucket, so there is nothing else to host. `web/config.js` must contain the
project URL and anon key before uploading.

## Notes

- The upload and gallery links are unlisted but not secret — anyone who has
  the link can upload and view. Fine for a trusted group; don't post it publicly.
- Supabase free tier includes 1 GB storage / 50 MB max file size. 20–30 people
  × phone photos usually fits; the Pro plan ($25/mo, cancel after) lifts it to
  100 GB if needed.
- iPhone HEIC originals are kept as-is (the `accept` attribute includes
  `.heic`, which stops iOS from converting). Thumbnails are JPEG, so the
  gallery works everywhere.
