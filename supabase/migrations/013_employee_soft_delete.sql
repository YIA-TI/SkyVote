-- Survey Central -- soft-delete for employees.
-- "Deleting" an employee from the admin UI must not remove their row —
-- past submissions reference employees only by a snapshot of nama/
-- departemen/jenis_pegawai (no FK), but reports and audits still need the
-- employee record itself to exist. Instead, deleting flips is_active to
-- false: the employee disappears from the public survey form's name search
-- and from "belum mengisi survei" lists, without losing any history.

begin;

alter table employees add column if not exists is_active boolean not null default true;
create index if not exists idx_employees_is_active on employees(is_active);

-- Only employees still active should show up as "hasn't submitted yet".
create or replace function employees_belum_survey(p_tanggal date default null)
returns setof employees
language sql stable as $$
  select e.*
  from employees e
  where e.is_active
    and not exists (
      select 1 from submissions s
      where s.nama = e.nama
        and (p_tanggal is null or s.tanggal = p_tanggal)
    )
  order by e.nama;
$$;

commit;
