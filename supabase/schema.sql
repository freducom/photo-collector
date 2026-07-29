-- Photo collector schema: one table, public bucket, anon can insert + read.
create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  uploader text not null check (char_length(uploader) between 1 and 80),
  storage_path text not null,
  thumb_path text,
  original_name text,
  content_type text,
  size_bytes bigint,
  taken_at timestamptz,
  uploaded_at timestamptz not null default now()
);

alter table public.photos enable row level security;

create policy "anon insert photos" on public.photos
  for insert to anon with check (true);

create policy "anon read photos" on public.photos
  for select to anon using (true);

-- Storage: public bucket for originals + thumbnails.
insert into storage.buckets (id, name, public)
  values ('photos', 'photos', true)
  on conflict (id) do nothing;

create policy "anon upload to photos bucket" on storage.objects
  for insert to anon with check (bucket_id = 'photos');

create policy "public read photos bucket" on storage.objects
  for select to anon using (bucket_id = 'photos');
