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

-- Membuat akun untuk semua santri yang sudah ada.
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

-- Memeriksa nama + password tanpa membutuhkan email.
create or replace function public.student_login(p_student_id bigint, p_password text)
returns table (student_id bigint, name text, class_id text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  select s.id, s.name, s.class_id
  from public.students s
  join public.student_accounts a on a.student_id = s.id
  where s.id = p_student_id
    and extensions.crypt(p_password, a.password_hash) = a.password_hash;
end;
$$;

grant execute on function public.student_login(bigint, text) to anon, authenticated;

-- Rekapan hanya untuk student_id yang diminta.
-- Fungsi ini tidak membuka tabel attendance langsung kepada santri.
create or replace function public.get_student_attendance(
  p_student_id bigint,
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
  where a.student_id = p_student_id
    and a.attendance_date between p_start_date and p_end_date
  order by a.attendance_date desc, a.session;
$$;

grant execute on function public.get_student_attendance(bigint, date, date) to anon, authenticated;
