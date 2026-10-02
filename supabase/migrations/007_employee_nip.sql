-- Survey Central -- add employee identifier (NIP/NIK) column.
-- Run this AFTER 001-006, BEFORE 008_real_employee_data.sql.

begin;

alter table employees add column if not exists nip text unique;

commit;
