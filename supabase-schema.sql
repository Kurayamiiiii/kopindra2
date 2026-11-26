-- After creating the admin user in Supabase Auth, authorize it with:
-- insert into public.admin_users (user_id) values ('<AUTH_USER_UUID>');
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.anggota (
  id uuid primary key default gen_random_uuid(),
  nomor_anggota text not null unique,
  nama text not null,
  fakultas text not null,
  bergabung date not null,
  status text not null default 'Aktif' check (status in ('Aktif', 'Nonaktif')),
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.anggota enable row level security;

drop policy if exists "Admin can read own access" on public.admin_users;
create policy "Admin can read own access"
  on public.admin_users for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Admins can read members" on public.anggota;
create policy "Admins can read members"
  on public.anggota for select to authenticated
  using (
    exists (
      select 1 from public.admin_users
      where admin_users.user_id = auth.uid()
    )
  );

drop policy if exists "Admins can add members" on public.anggota;
create policy "Admins can add members"
  on public.anggota for insert to authenticated
  with check (
    exists (
      select 1 from public.admin_users
      where admin_users.user_id = auth.uid()
    )
  );

grant select on public.admin_users to authenticated;
grant select, insert on public.anggota to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'anggota'
  ) then
    alter publication supabase_realtime add table public.anggota;
  end if;
end;
$$;
