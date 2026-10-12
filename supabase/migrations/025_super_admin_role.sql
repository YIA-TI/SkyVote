-- Survey Central — split admin accounts into two roles:
--   'super_admin' : everything an admin can do, PLUS managing employees
--                   (Kelola Pegawai) and deleting data (Hapus Data).
--   'admin'       : everything else; cannot change employees or delete
--                   submissions / evidence photos.
--
-- is_admin() keeps meaning "any admin account" (admin OR super_admin), so every
-- existing admin policy keeps working. The restricted operations get their own
-- is_super_admin() policies, so the limit is enforced by the database and not
-- only by hiding the pages in the UI.
--
-- After running this, promote the existing account(s) yourself in the SQL
-- Editor (kept out of this file on purpose — the repo is public):
--   update profiles set role = 'super_admin'
--   where id = (select id from auth.users where email = '<super admin email>');
-- Run after 024_public_bukti_date_range.sql.

begin;

alter table profiles drop constraint if exists profiles_role_check;
alter table profiles
  add constraint profiles_role_check check (role in ('admin', 'super_admin'));

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p
    where p.id = auth.uid() and p.role in ('admin', 'super_admin')
  );
$$;

create or replace function is_super_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p where p.id = auth.uid() and p.role = 'super_admin'
  );
$$;

-- Kelola Pegawai: only super admins may add / edit / (soft-)delete employees.
-- Reading stays public via employees_select_all (the survey form needs it).
drop policy if exists employees_admin_write on employees;
create policy employees_super_admin_write on employees
  for all to authenticated using (is_super_admin()) with check (is_super_admin());

-- Hapus Data: deleting submissions, clearing a submission's photo pointer and
-- removing the photo from storage are super-admin only. (Deleting a whole
-- survey from Kelola Survei still cascades to its submissions: foreign-key
-- cascades are not subject to these policies.)
drop policy if exists submissions_delete_admin on submissions;
create policy submissions_delete_super_admin on submissions
  for delete to authenticated using (is_super_admin());

drop policy if exists submissions_update_admin on submissions;
create policy submissions_update_super_admin on submissions
  for update to authenticated using (is_super_admin()) with check (is_super_admin());

drop policy if exists "survey-bukti delete admin" on storage.objects;
create policy "survey-bukti delete super admin" on storage.objects
  for delete to authenticated
  using (bucket_id = 'survey-bukti' and is_super_admin());

commit;
