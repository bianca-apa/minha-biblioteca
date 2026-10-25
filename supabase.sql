-- Rode este arquivo inteiro uma vez em: Supabase → SQL Editor → New query → Run

-- 1) Lombadas da estante (título e autor de cada espaço na estante)
create table if not exists public.shelf_slots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  slot int not null,
  title text not null default '',
  author text not null default '',
  updated_at timestamptz not null default now(),
  unique (user_id, slot)
);

-- 2) Abas da biblioteca (cada aba comporta até 100 livros no app)
create table if not exists public.library_pages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- 3) Livros lidos
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  page_id uuid not null references public.library_pages(id) on delete cascade,
  title text not null default '',
  author text not null default '',
  genre text not null default '',
  date_read date,
  read_time text not null default '',
  rating int not null default 0 check (rating between 0 and 5),
  summary text not null default '',
  cover_path text,
  created_at timestamptz not null default now()
);

create index if not exists books_page_idx on public.books (page_id);

-- 4) Segurança: cada pessoa só enxerga e altera os próprios dados
alter table public.shelf_slots   enable row level security;
alter table public.library_pages enable row level security;
alter table public.books         enable row level security;

drop policy if exists "own shelf_slots" on public.shelf_slots;
create policy "own shelf_slots" on public.shelf_slots
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own library_pages" on public.library_pages;
create policy "own library_pages" on public.library_pages
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own books" on public.books;
create policy "own books" on public.books
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 5) Armazenamento das fotos de capa (pasta com o id de cada usuário)
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

drop policy if exists "covers read" on storage.objects;
create policy "covers read" on storage.objects
  for select using (bucket_id = 'covers');

drop policy if exists "covers insert own" on storage.objects;
create policy "covers insert own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "covers update own" on storage.objects;
create policy "covers update own" on storage.objects
  for update to authenticated
  using (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "covers delete own" on storage.objects;
create policy "covers delete own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);
