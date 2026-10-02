-- Survey Central — mock/demo data
-- Run after 001_schema.sql and 002_rls_and_storage.sql.
-- Note: run this as the Postgres/service_role owner (e.g. via the Supabase
-- SQL Editor), since it needs to bypass the RLS policies from 002 to seed
-- rows that plain anon/authenticated roles aren't allowed to insert
-- directly (surveys, employees, departments, non-Aktif-adjacent data).

begin;

insert into departments (nama) values
  ('Operasional Bandara / Security'),
  ('Layanan Pelanggan / Front Desk'),
  ('Teknik / Maintenance Fasilitas'),
  ('Keuangan / Akuntansi'),
  ('Komersial / Retail'),
  ('Human Resources / SDM'),
  ('IT & Digital Services'),
  ('Marketing & Komunikasi'),
  ('Legal & Compliance'),
  ('Cargo & Logistik')
on conflict (nama) do nothing;

insert into workforce_totals (jenis_pegawai, total) values
  ('Organik', 150),
  ('Non-Organik', 50)
on conflict (jenis_pegawai) do update set total = excluded.total;

insert into employees (nama, unit_kerja, jenis_pegawai) values
  ('Budi Santoso',      'Operasional Bandara / Security', 'Organik'),
  ('Siti Aminah',       'Layanan Pelanggan / Front Desk', 'Non-Organik'),
  ('Ahmad Ridwan',      'Teknik / Maintenance Fasilitas', 'Organik'),
  ('Dewi Lestari',      'Keuangan / Akuntansi',           'Organik'),
  ('Joko Anwar',        'Komersial / Retail',             'Non-Organik'),
  ('Siti Nurhaliza',    'Layanan Pelanggan / Front Desk', 'Organik'),
  ('Bambang Wijaya',    'Operasional Bandara / Security', 'Organik'),
  ('Rina Kartika',      'Keuangan / Akuntansi',           'Non-Organik'),
  ('Fajar Nugroho',     'Teknik / Maintenance Fasilitas', 'Organik'),
  ('Maya Puspita',      'Komersial / Retail',             'Organik'),
  ('Hendra Gunawan',    'Operasional Bandara / Security', 'Non-Organik'),
  ('Yuni Astuti',       'Layanan Pelanggan / Front Desk', 'Organik'),
  ('Dedi Kurniawan',    'Teknik / Maintenance Fasilitas', 'Non-Organik'),
  ('Lestari Wulandari', 'Keuangan / Akuntansi',           'Organik'),
  ('Agus Salim',        'Komersial / Retail',             'Organik'),
  ('Nurul Hidayah',     'Operasional Bandara / Security', 'Organik'),
  ('Wahyu Saputra',     'Layanan Pelanggan / Front Desk', 'Non-Organik'),
  ('Indah Permata',     'Teknik / Maintenance Fasilitas', 'Organik'),
  ('Rudi Hartono',      'Keuangan / Akuntansi',           'Organik'),
  ('Sari Dewi',         'Komersial / Retail',             'Non-Organik'),
  ('Eko Prasetyo',      'Operasional Bandara / Security', 'Organik'),
  ('Fitriani',          'Layanan Pelanggan / Front Desk', 'Organik'),
  ('Anton Wibowo',      'Teknik / Maintenance Fasilitas', 'Non-Organik'),
  ('Melati Sari',       'Keuangan / Akuntansi',           'Organik')
on conflict (nama) do nothing;

-- Surveys — dates use the current year dynamically (mirrors the old JS
-- seed's `new Date().getFullYear()`); the Draft row keeps NULL dates just
-- like the original empty-string values meant "not scheduled yet".
insert into surveys (nama, link, tanggal_mulai, tanggal_selesai, status, max_pengisian) values
  ('Survei Budaya Kerja 2026', 'https://forms.office.com/budaya-kerja',
     make_date(extract(year from current_date)::int, 10, 1),
     make_date(extract(year from current_date)::int, 10, 15), 'Aktif', 20),
  ('Feedback Fasilitas Bandara', 'https://forms.google.com/fasilitas-bandara',
     make_date(extract(year from current_date)::int, 9, 10),
     make_date(extract(year from current_date)::int, 9, 30), 'Selesai', 15),
  ('Kesiapan Operasional Akhir Tahun', '',
     make_date(extract(year from current_date)::int, 11, 1),
     make_date(extract(year from current_date)::int, 11, 15), 'Terjadwal', 20),
  ('Kepuasan Layanan Terminal 1', 'https://forms.familia.id/cx100',
     make_date(extract(year from current_date)::int, 7, 1),
     make_date(extract(year from current_date)::int, 7, 31), 'Aktif', 20),
  ('Kepuasan Layanan Terminal 2', 'https://forms.familia.id/cx101',
     make_date(extract(year from current_date)::int, 7, 1),
     make_date(extract(year from current_date)::int, 7, 31), 'Aktif', 10),
  ('Evaluasi Kantin Karyawan', 'https://forms.google.com/kantin-karyawan',
     make_date(extract(year from current_date)::int, 8, 5),
     make_date(extract(year from current_date)::int, 8, 20), 'Selesai', 25),
  ('Survei Keselamatan Kerja Q3', 'https://forms.office.com/keselamatan-q3',
     make_date(extract(year from current_date)::int, 8, 1),
     make_date(extract(year from current_date)::int, 8, 14), 'Selesai', 30),
  ('Persiapan Mudik Lebaran', '',
     make_date(extract(year from current_date)::int, 12, 1),
     make_date(extract(year from current_date)::int, 12, 10), 'Terjadwal', 20),
  ('Evaluasi Sistem Shift Kerja', 'https://forms.google.com/shift-kerja',
     make_date(extract(year from current_date)::int, 6, 1),
     make_date(extract(year from current_date)::int, 6, 15), 'Selesai', 20),
  ('Survei Kepuasan Digitalisasi HR', 'https://forms.office.com/digitalisasi-hr',
     make_date(extract(year from current_date)::int, 7, 10),
     make_date(extract(year from current_date)::int, 7, 25), 'Aktif', 20),
  ('Feedback Program Pelatihan', 'https://forms.google.com/program-pelatihan',
     make_date(extract(year from current_date)::int, 5, 1),
     make_date(extract(year from current_date)::int, 5, 20), 'Selesai', 25),
  ('Survei Kesiapan Peak Season', '', null, null, 'Draft', 20);

-- Mock submissions — real employees (not synthetic names), spread across the
-- 4 "Aktif" surveys and the last 10 days. jenis_pegawai/departemen copy the
-- employee's own values, same denormalization the app already does at
-- submission time. Inserting into `submissions` fires both
-- trg_enforce_submission_quota (harmless here — well under every
-- max_pengisian) and trg_notify_new_submission, so ~16 rows automatically
-- appear in `notifications` too without a separate insert.
insert into submissions (nama, tanggal, survey_id, jenis_pegawai, departemen, file_bukti) values
  ('Budi Santoso', current_date,
     (select id from surveys where nama = 'Survei Budaya Kerja 2026'),
     'Organik', 'Operasional Bandara / Security', 'seed/placeholder.jpg'),
  ('Siti Aminah', current_date,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 1'),
     'Non-Organik', 'Layanan Pelanggan / Front Desk', 'seed/placeholder.jpg'),
  ('Ahmad Ridwan', current_date - 1,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 2'),
     'Organik', 'Teknik / Maintenance Fasilitas', 'seed/placeholder.jpg'),
  ('Dewi Lestari', current_date - 1,
     (select id from surveys where nama = 'Survei Kepuasan Digitalisasi HR'),
     'Organik', 'Keuangan / Akuntansi', 'seed/placeholder.jpg'),
  ('Joko Anwar', current_date - 2,
     (select id from surveys where nama = 'Survei Budaya Kerja 2026'),
     'Non-Organik', 'Komersial / Retail', 'seed/placeholder.jpg'),
  ('Siti Nurhaliza', current_date - 2,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 1'),
     'Organik', 'Layanan Pelanggan / Front Desk', 'seed/placeholder.jpg'),
  ('Bambang Wijaya', current_date - 3,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 2'),
     'Organik', 'Operasional Bandara / Security', 'seed/placeholder.jpg'),
  ('Rina Kartika', current_date - 3,
     (select id from surveys where nama = 'Survei Kepuasan Digitalisasi HR'),
     'Non-Organik', 'Keuangan / Akuntansi', 'seed/placeholder.jpg'),
  ('Fajar Nugroho', current_date - 4,
     (select id from surveys where nama = 'Survei Budaya Kerja 2026'),
     'Organik', 'Teknik / Maintenance Fasilitas', 'seed/placeholder.jpg'),
  ('Maya Puspita', current_date - 4,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 1'),
     'Organik', 'Komersial / Retail', 'seed/placeholder.jpg'),
  ('Hendra Gunawan', current_date - 5,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 2'),
     'Non-Organik', 'Operasional Bandara / Security', 'seed/placeholder.jpg'),
  ('Yuni Astuti', current_date - 5,
     (select id from surveys where nama = 'Survei Kepuasan Digitalisasi HR'),
     'Organik', 'Layanan Pelanggan / Front Desk', 'seed/placeholder.jpg'),
  ('Dedi Kurniawan', current_date - 6,
     (select id from surveys where nama = 'Survei Budaya Kerja 2026'),
     'Non-Organik', 'Teknik / Maintenance Fasilitas', 'seed/placeholder.jpg'),
  ('Lestari Wulandari', current_date - 7,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 1'),
     'Organik', 'Keuangan / Akuntansi', 'seed/placeholder.jpg'),
  ('Agus Salim', current_date - 8,
     (select id from surveys where nama = 'Kepuasan Layanan Terminal 2'),
     'Organik', 'Komersial / Retail', 'seed/placeholder.jpg'),
  ('Nurul Hidayah', current_date - 9,
     (select id from surveys where nama = 'Survei Kepuasan Digitalisasi HR'),
     'Organik', 'Operasional Bandara / Security', 'seed/placeholder.jpg');

commit;

-- ── Bootstrapping the first admin user ────────────────────────────────────
-- Can't be done via plain SQL INSERT — password hashing requires Supabase's
-- Auth service. Steps:
--   1. Supabase Dashboard → Authentication → Users → Add user (set email +
--      password).
--   2. Copy that user's UUID, then run:
--        insert into profiles (id, role, display_name)
--        values ('<uuid-from-auth.users>', 'admin', 'Nama Admin');
