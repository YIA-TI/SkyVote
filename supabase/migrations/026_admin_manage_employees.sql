-- Survey Central — regular admins may manage employees (Kelola Pegawai) again.
-- 025 limited employee writes to super admins; only "Hapus Data" (deleting
-- submissions / evidence photos) stays super-admin only.
-- Run after 025_super_admin_role.sql.

begin;

drop policy if exists employees_super_admin_write on employees;
drop policy if exists employees_admin_write on employees;
create policy employees_admin_write on employees
  for all to authenticated using (is_admin()) with check (is_admin());

commit;
