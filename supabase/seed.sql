-- Jalankan sekali di Supabase SQL Editor setelah schema.sql.
insert into public.classes (id,name) values
('VII','Kelas VII'),('VIII','Kelas VIII'),('IX','Kelas IX')
on conflict (id) do nothing;

insert into public.subjects (name) values
('Aqidah'),('Fiqih'),('Hadist'),('Shiroh'),('Baqu (Bahasa Quran)'),('Leveling Quran'),('Halaqah Tahfizh')
on conflict (name) do nothing;

-- Akun pengajar dibuat dari Supabase Dashboard > Authentication > Users.
-- Setelah akun dibuat, isi email masing-masing pada tabel teachers.
-- Contoh:
-- insert into public.teachers (name,email,role) values ('Abah Alam','EMAIL_ABAH_ALAM','teacher');
-- lalu hubungkan subject dengan teacher_subjects menggunakan id hasil insert.

-- Jadwal V1:
-- Kepesantrenan: bada Isya, Senin-Jumat.
-- Leveling Quran: bada Magrib, Selasa-Kamis, Abah Alam.
-- Halaqah Tahfizh: bada Shubuh, Selasa-Sabtu, Abah Dendi.
