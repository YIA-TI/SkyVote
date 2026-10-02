-- Survey Central — merge "Airport Aeronautical" into "Aero Commercial
-- Department Head". Every employee/submission that pointed at "Airport
-- Aeronautical" is repointed at "Aero Commercial Department Head", then the
-- now-unused "Airport Aeronautical" department row is dropped.
-- Run this after 010_submission_date_within_period.sql.

begin;

update employees
set unit_kerja = 'Aero Commercial Department Head'
where unit_kerja = 'Airport Aeronautical';

-- Keep historical submissions consistent — same denormalization fix-up
-- pattern as 005_org_structure_update.sql.
update submissions s
set departemen = e.unit_kerja
from employees e
where e.nama = s.nama
  and s.departemen = 'Airport Aeronautical';

delete from departments where nama = 'Airport Aeronautical';

commit;
