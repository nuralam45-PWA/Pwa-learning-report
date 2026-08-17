-- PWA Learning Report — Tahap 1 Portal Santri
-- Jalankan sekali di Supabase > SQL Editor.
-- Setelah itu, buat akun login santri di Authentication > Users
-- dan isi email yang sama pada public.students.email.

alter table public.students add column if not exists email text;
create unique index if not exists students_email_unique_idx on public.students (lower(email)) where email is not null;

alter table public.students enable row level security;
alter table public.attendance enable row level security;

-- Santri hanya boleh membaca profil miliknya sendiri.
drop policy if exists "students_can_read_own_profile" on public.students;
create policy "students_can_read_own_profile"
on public.students for select to authenticated
using (lower(email) = lower((select auth.jwt()->>'email')));

-- Santri hanya boleh melihat absensinya sendiri.
drop policy if exists "students_can_read_own_attendance" on public.attendance;
create policy "students_can_read_own_attendance"
on public.attendance for select to authenticated
using (
  student_id = (
    select s.id
    from public.students s
    where lower(s.email) = lower((select auth.jwt()->>'email'))
    limit 1
  )
);

-- Agar nama mata pelajaran dan kelas dapat ditampilkan pada dashboard.
alter table public.subjects enable row level security;
drop policy if exists "authenticated_can_read_subjects" on public.subjects;
create policy "authenticated_can_read_subjects"
on public.subjects for select to authenticated
using (true);

alter table public.classes enable row level security;
drop policy if exists "authenticated_can_read_classes" on public.classes;
create policy "authenticated_can_read_classes"
on public.classes for select to authenticated
using (true);
