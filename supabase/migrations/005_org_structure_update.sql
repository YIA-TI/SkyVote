-- Survey Central — remap departments/employees to the InJourney Airports
-- org-chart structure (General Manager + 4 Divisions, each with several
-- Department Heads as leaf units).
--
-- Run this AFTER 001-003. Safe to run once; re-running is harmless (uses
-- ON CONFLICT DO NOTHING / idempotent UPDATEs) as long as employee names
-- below still match what's in your `employees` table.

begin;

-- 1. Insert the 18 new leaf departments (Department Head level) —
--    these are what employees.unit_kerja / submissions.departemen will
--    point to going forward. The report's "per Departemen" table groups
--    these under their parent (General Manager / Division) in the app.
insert into departments (nama) values
  ('Airport Operation Center Head'),
  ('Branch Communication & CSR Department Head'),
  ('Legal & Compliance Department Head'),
  ('Asset Management & General Services Department Head'),
  ('Safety Management System & OHS Department Head'),
  ('Airport Quality Control Department Head'),
  ('Airport Operation Airside Department Head'),
  ('Airport Operation Landside & Terminal Department Head'),
  ('Airport Services Improvement Department Head'),
  ('Airport Rescue & Fire Fighting Department Head'),
  ('Airport Security Protection Department Head'),
  ('Airport Security Screening Department Head'),
  ('Airport Facilities Department Head'),
  ('Airport Equipment Department Head'),
  ('Airport Technology Department Head'),
  ('Airport Environment Department Head'),
  ('Aero Commercial Department Head'),
  ('Non-Aero Commercial Department Head')
on conflict (nama) do nothing;

-- 2. Reassign each existing employee to a new leaf department.
update employees set unit_kerja = 'Airport Operation Center Head' where nama in ('Budi Santoso', 'Siti Aminah');
update employees set unit_kerja = 'Branch Communication & CSR Department Head' where nama in ('Ahmad Ridwan');
update employees set unit_kerja = 'Legal & Compliance Department Head' where nama in ('Dewi Lestari');
update employees set unit_kerja = 'Asset Management & General Services Department Head' where nama in ('Joko Anwar', 'Siti Nurhaliza');
update employees set unit_kerja = 'Safety Management System & OHS Department Head' where nama in ('Bambang Wijaya');
update employees set unit_kerja = 'Airport Quality Control Department Head' where nama in ('Rina Kartika');
update employees set unit_kerja = 'Airport Operation Airside Department Head' where nama in ('Fajar Nugroho', 'Maya Puspita', 'Hendra Gunawan');
update employees set unit_kerja = 'Airport Operation Landside & Terminal Department Head' where nama in ('Yuni Astuti', 'Dedi Kurniawan');
update employees set unit_kerja = 'Airport Services Improvement Department Head' where nama in ('Lestari Wulandari');
update employees set unit_kerja = 'Airport Rescue & Fire Fighting Department Head' where nama in ('Agus Salim');
update employees set unit_kerja = 'Airport Security Protection Department Head' where nama in ('Nurul Hidayah', 'Wahyu Saputra');
update employees set unit_kerja = 'Airport Security Screening Department Head' where nama in ('Indah Permata');
update employees set unit_kerja = 'Airport Facilities Department Head' where nama in ('Rudi Hartono');
update employees set unit_kerja = 'Airport Equipment Department Head' where nama in ('Sari Dewi');
update employees set unit_kerja = 'Airport Technology Department Head' where nama in ('Eko Prasetyo');
update employees set unit_kerja = 'Airport Environment Department Head' where nama in ('Fitriani');
update employees set unit_kerja = 'Aero Commercial Department Head' where nama in ('Anton Wibowo');
update employees set unit_kerja = 'Non-Aero Commercial Department Head' where nama in ('Melati Sari');

-- 3. Keep historical submissions consistent — each submission's stored
--    `departemen` was denormalized from the employee's unit_kerja at
--    submission time, so re-sync it to the employee's new department.
update submissions s
set departemen = e.unit_kerja
from employees e
where e.nama = s.nama
  and s.departemen is distinct from e.unit_kerja;

-- 4. Drop the old flat department list — nothing should reference these
--    anymore after steps 2-3, so this is safe.
delete from departments
where nama in (
  'Cargo & Logistik',
  'Layanan Pelanggan / Front Desk',
  'Teknik / Maintenance Fasilitas',
  'Keuangan / Akuntansi',
  'Komersial / Retail',
  'Human Resources / SDM',
  'IT & Digital Services',
  'Marketing & Komunikasi',
  'Legal & Compliance',
  'Operasional Bandara / Security'
);

commit;
