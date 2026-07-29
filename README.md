# Bilder av Birk — photo collector

Collect full-quality photos from a group of people — no login, they just enter
their name once. Static pages on GitHub Pages, backend on Supabase
(storage + Postgres + one edge function).

## How it works

- **`docs/index.html`** — the upload page (served at
  `https://birkbilder.com/`). Asks for a name (remembered
  in localStorage), then lets people multi-select photos from their phone.
  Originals are uploaded untouched; a ~1000px JPEG thumbnail is generated in
  the browser for the gallery. Date taken is read from EXIF
  (`DateTimeOriginal`), falling back to the file's modified time.
- **`docs/gallery.html`** — the owner's view. Sort by date taken / upload
  time, filter or group by uploader. Tiles link to the full-quality original.
- **`collect` edge function** (in Supabase, not this repo) — the upload
  gatekeeper, see below.
- **`download-all.sh <access-key>`** — pulls every original into
  `downloads/<uploader>/<date-taken>_<name>` on your machine.

## Access & bot protection

The share link carries a secret key (`?k=...`) which is **not** in this repo.
Without it the pages are inert and the API refuses everything.

- Anonymous clients cannot write to storage or the database at all. Uploads
  ask the `collect` edge function for signed upload URLs; it checks the key,
  a honeypot field, per-IP rate limits (120/hour, 400/day), a global cap
  (1500/day, 20 GB total), max 50 MB per file, and images-only. Metadata rows
  are inserted server-side only after the file verifiably exists.
- Reading the gallery requires the key too (RLS checks an `x-collect-key`
  header). Storage objects sit at unguessable UUID URLs and listing is
  disabled, so links people share of individual photos still work.

## Notes

- Supabase free tier includes 1 GB storage / 50 MB max file size. 20–30
  people × phone photos usually fits; the Pro plan ($25/mo, cancel after)
  lifts it to 100 GB if needed.
- iPhone HEIC originals are kept as-is (the `accept` attribute includes
  `.heic`, which stops iOS from converting). Thumbnails are JPEG, so the
  gallery works everywhere.
- If the key ever leaks: rotate it in the `collect` function source and the
  RLS policy, then share a new link.
