-- Run this once in your Supabase project's SQL editor.
-- Creates the single-row settings table the new admin dashboard
-- "Settings" tab reads from and writes to.

create table if not exists public.store_settings (
  id integer primary key,
  whatsapp_number text not null default '',
  instapay_link text not null default '',
  vodafone_cash_number text not null default ''
);

-- Public can read (needed so the storefront checkout can build the
-- WhatsApp / InstaPay / Vodafone Cash links). Only logged-in admins can write.
alter table public.store_settings enable row level security;

create policy "Public can read store settings"
  on public.store_settings for select
  using (true);

create policy "Authenticated users can upsert store settings"
  on public.store_settings for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Seed the single settings row (id = 1) with empty values so the first
-- save from the dashboard works via upsert.
insert into public.store_settings (id, whatsapp_number, instapay_link, vodafone_cash_number)
values (1, '', '', '')
on conflict (id) do nothing;
