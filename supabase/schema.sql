-- =============================================================================
-- Nafas Bakery — Supabase schema
-- Run this once in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run: every statement uses "if not exists" / "on conflict".
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TABLES
-- -----------------------------------------------------------------------------

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  price numeric not null default 0,
  category text not null default '',
  emoji text not null default '',
  image_url text,
  tags text[] not null default '{}',
  story text not null default '',
  highlights text[] not null default '{}',
  ingredients text[] not null default '{}',
  allergens text[] not null default '{}',
  calories int not null default 0,
  prep_minutes int not null default 0,
  rating numeric not null default 4.8,
  review_count int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text not null,
  address text not null,
  payment_method text not null default 'cod',
  is_completed boolean not null default false,
  total numeric not null default 0,
  items jsonb not null default '[]',
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- Storefront (anonymous visitors) can read products/banners and place
-- orders. Only a logged-in admin (any authenticated user) can write to
-- products/banners, and can read/update/delete orders.
-- -----------------------------------------------------------------------------

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.banners  enable row level security;
alter table public.orders   enable row level security;

drop policy if exists "public read categories" on public.categories;
create policy "public read categories" on public.categories
  for select using (true);

drop policy if exists "admin write categories" on public.categories;
create policy "admin write categories" on public.categories
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "public read products" on public.products;
create policy "public read products" on public.products
  for select using (true);

drop policy if exists "admin write products" on public.products;
create policy "admin write products" on public.products
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "public read banners" on public.banners;
create policy "public read banners" on public.banners
  for select using (true);

drop policy if exists "admin write banners" on public.banners;
create policy "admin write banners" on public.banners
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "public insert orders" on public.orders;
create policy "public insert orders" on public.orders
  for insert with check (true); -- anyone can place an order at checkout

drop policy if exists "admin read orders" on public.orders;
create policy "admin read orders" on public.orders
  for select using (auth.role() = 'authenticated');

drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders
  for update using (auth.role() = 'authenticated');

drop policy if exists "admin delete orders" on public.orders;
create policy "admin delete orders" on public.orders
  for delete using (auth.role() = 'authenticated');

-- -----------------------------------------------------------------------------
-- STORAGE — product & banner photo buckets, both public-read
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('banner-images', 'banner-images', true)
on conflict (id) do nothing;

drop policy if exists "public read product images" on storage.objects;
create policy "public read product images" on storage.objects
  for select using (bucket_id = 'product-images');

drop policy if exists "admin write product images" on storage.objects;
create policy "admin write product images" on storage.objects
  for insert with check (bucket_id = 'product-images' and auth.role() = 'authenticated');

drop policy if exists "admin update product images" on storage.objects;
create policy "admin update product images" on storage.objects
  for update using (bucket_id = 'product-images' and auth.role() = 'authenticated');

drop policy if exists "admin delete product images" on storage.objects;
create policy "admin delete product images" on storage.objects
  for delete using (bucket_id = 'product-images' and auth.role() = 'authenticated');

drop policy if exists "public read banner images" on storage.objects;
create policy "public read banner images" on storage.objects
  for select using (bucket_id = 'banner-images');

drop policy if exists "admin write banner images" on storage.objects;
create policy "admin write banner images" on storage.objects
  for insert with check (bucket_id = 'banner-images' and auth.role() = 'authenticated');

drop policy if exists "admin update banner images" on storage.objects;
create policy "admin update banner images" on storage.objects
  for update using (bucket_id = 'banner-images' and auth.role() = 'authenticated');

drop policy if exists "admin delete banner images" on storage.objects;
create policy "admin delete banner images" on storage.objects
  for delete using (bucket_id = 'banner-images' and auth.role() = 'authenticated');

-- -----------------------------------------------------------------------------
-- No seed data — the owner adds every category and product from the
-- dashboard. If you're re-running this on a database that already has the
-- old hardcoded categories (pastry/cake/bread/coffee) baked into existing
-- product rows, that's fine — those rows just keep their text value until
-- you edit them from the dashboard and pick one of your new categories.
-- -----------------------------------------------------------------------------

-- =============================================================================
-- ADMIN USER
-- Don't create the admin account with SQL — use the dashboard instead:
-- Authentication → Users → Add user (enter an email + password).
-- That's the account you'll sign in with on the app's /admin screen.
-- =============================================================================
