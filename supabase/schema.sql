-- Reference copy of the live schema (applied via Supabase migrations:
-- photo_collector_init + bot_protection). The '<ACCESS_KEY>' placeholder is
-- the secret carried in the shared link — not stored in this public repo.

create table public.photos (
  id uuid primary key default gen_random_uuid(),
  uploader text not null check (char_length(uploader) between 1 and 80),
  uploader_id uuid, -- per-device identity from the browser's localStorage
  storage_path text not null,
  thumb_path text,
  original_name text,
  content_type text,
  size_bytes bigint,
  taken_at timestamptz,
  uploaded_at timestamptz not null default now()
);
alter table public.photos enable row level security;

-- Reads require the link key; all writes go through the `collect` edge
-- function using the service role, so there are no insert policies at all.
create policy "key holders read photos" on public.photos
  for select to anon
  using ((current_setting('request.headers', true)::json ->> 'x-collect-key') = '<ACCESS_KEY>');

-- Rate-limit log for the collect function (service role only: RLS, no policies).
create table public.upload_events (
  id bigint generated always as identity primary key,
  ip text not null,
  bytes bigint not null default 0,
  created_at timestamptz not null default now()
);
create index upload_events_ip_idx on public.upload_events (ip, created_at);
create index upload_events_created_idx on public.upload_events (created_at);
alter table public.upload_events enable row level security;

-- Public bucket: files served only by exact (UUID) URL, no listing, 50 MB cap.
insert into storage.buckets (id, name, public, file_size_limit)
  values ('photos', 'photos', true, 52428800);
