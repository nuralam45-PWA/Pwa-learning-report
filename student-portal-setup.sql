-- PWA Learning Report — Tahap 1 Portal Santri
-- Jalankan SEKALI di Supabase > SQL Editor > New query.
-- Login santri: pilih kelas + nama + password.
-- Password awal semua santri: pwa12345

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.student_accounts (
  student_id bigint primary key references public.students(id) on delete cascade,
  password_hash text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.student_sessions (
  token_hash text primary key,
  student_id bigint not null references public.students(id) on delete cascade,
  expires_at timestamptz not null
);

insert into public.student_accounts (student_id, password_hash)
select s.id, extensions.crypt('pwa12345', extensions.gen_salt('bf'))
from public.students s
on conflict (student_id) do nothing;

-- Daftar nama untuk pilihan login. Password tidak dikirim ke aplikasi.
create or replace function public.get_student_login_list()
returns table (student_id bigint, name text, class_id text)
language sql
security definer
set search_path = ''
as $$
  select s.id, s.name, s.class_id
  from public.students s
  order by s.class_id, s.name;
$$;

grant execute on function public.get_student_login_list() to anon, authenticated;

-- Login menghasilkan token sementara. Token ini yang dipakai untuk mengambil rekapan,
-- sehingga santri tidak dapat meminta data santri lain hanya dengan mengganti ID.
create or replace function public.student_login(p_student_id bigint, p_password text)
returns table (student_id bigint, name text, class_id text, session_token text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_token text;
  v_hash text;
begin
  if exists (
    select 1
    from public.students s
    join public.student_accounts a on a.student_id = s.id
    where s.id = p_student_id
      and extensions.crypt(p_password, a.password_hash) = a.password_hash
  ) then
    v_token := encode(extensions.gen_random_bytes(32), 'hex');
    v_hash := encode(extensions.digest(v_token, 'sha256'), 'hex');

    delete from public.student_sessions where expires_at < now();
    insert into public.student_sessions(token_hash, student_id, expires_at)
    values(v_hash, p_student_id, now() + interval '12 hours');

    return query
    select s.id, s.name, s.class_id, v_token
    from public.students s
    where s.id = p_student_id;
  end if;
end;
$$;

grant execute on function public.student_login(bigint, text) to anon, authenticated;

-- Rekapan hanya berdasarkan token login yang valid.
create or replace function public.get_student_attendance(
  p_session_token text,
  p_start_date date,
  p_end_date date
)
returns table (
  attendance_date date,
  session text,
  present boolean,
  subject_name text
)
language sql
security definer
set search_path = ''
as $$
  select a.attendance_date, a.session, a.present, s.name
  from public.attendance a
  left join public.subjects s on s.id = a.subject_id
  join public.student_sessions ss
    on ss.student_id = a.student_id
   and ss.token_hash = encode(extensions.digest(p_session_token, 'sha256'), 'hex')
   and ss.expires_at > now()
  where a.attendance_date between p_start_date and p_end_date
  order by a.attendance_date desc, a.session;
$$;

grant execute on function public.get_student_attendance(text, date, date) to anon, authenticated;
