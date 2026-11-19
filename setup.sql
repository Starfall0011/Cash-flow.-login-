-- Jalankan sekali di Supabase: SQL Editor > New query > tempel semua > Run.
-- Tabel tertutup untuk akses langsung. Aplikasi hanya bisa memakai 3 fungsi di bawah,
-- dan setiap fungsi mengecek token auth (hasil turunan password, bukan password).

create table if not exists vaults(
  id text primary key,
  auth text not null,
  data text not null,
  t bigint not null default 0,
  updated_at timestamptz not null default now()
);
alter table vaults enable row level security;
revoke all on table vaults from anon, authenticated;

create or replace function vault_get(p_id text, p_auth text)
returns json language sql security definer set search_path = public as $$
  select json_build_object('data', data, 't', t) from vaults where id = p_id and auth = p_auth
$$;

create or replace function vault_create(p_id text, p_auth text, p_data text, p_t bigint)
returns json language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from vaults where id = p_id) then
    return json_build_object('ok', false, 'err', 'exists');
  end if;
  insert into vaults(id, auth, data, t) values (p_id, p_auth, p_data, p_t);
  return json_build_object('ok', true);
end $$;

create or replace function vault_put(p_id text, p_auth text, p_data text, p_t bigint)
returns json language plpgsql security definer set search_path = public as $$
begin
  update vaults set data = p_data, t = p_t, updated_at = now() where id = p_id and auth = p_auth;
  if not found then
    return json_build_object('ok', false, 'err', 'auth');
  end if;
  return json_build_object('ok', true);
end $$;

grant execute on function vault_get(text, text) to anon;
grant execute on function vault_create(text, text, text, bigint) to anon;
grant execute on function vault_put(text, text, text, bigint) to anon;
