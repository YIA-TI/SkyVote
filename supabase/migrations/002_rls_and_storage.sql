-- Survey Central — Row Level Security + Storage policies (RBAC)
-- Run after 001_schema.sql.

begin;

alter table departments enable row level security;
alter table employees enable row level security;
alter table surveys enable row level security;
alter table submissions enable row level security;
alter table notifications enable row level security;
alter table profiles enable row level security;
alter table workforce_totals enable row level security;

-- departments: public read, admin write
create policy departments_select_all on departments
  for select using (true);
create policy departments_admin_write on departments
  for all to authenticated using (is_admin()) with check (is_admin());

-- employees: public read (needed for the public-page name autocomplete),
-- admin write
create policy employees_select_all on employees
  for select using (true);
create policy employees_admin_write on employees
  for all to authenticated using (is_admin()) with check (is_admin());

-- surveys: anon only sees Aktif surveys (matches the public "Pilih survey"
-- dropdown); admin sees/edits every status via full CRUD
create policy surveys_select_public_active on surveys
  for select to anon using (status = 'Aktif');
create policy surveys_admin_all on surveys
  for all to authenticated using (is_admin()) with check (is_admin());

-- submissions: anon/public can only INSERT (quota + active-status re-checked
-- here as defense-in-depth alongside the trg_enforce_submission_quota
-- trigger); admin can SELECT + DELETE (delete is needed so removing a
-- survey can cascade-delete its submissions); nobody gets UPDATE — the app
-- never edits a submission after it's created
create policy submissions_insert_public on submissions
  for insert to anon, authenticated
  with check (
    exists (select 1 from surveys sv where sv.id = survey_id and sv.status = 'Aktif')
  );
create policy submissions_select_admin on submissions
  for select to authenticated using (is_admin());
create policy submissions_delete_admin on submissions
  for delete to authenticated using (is_admin());

-- notifications: admin-only read + mark-read; rows are only ever inserted by
-- the security-definer trg_notify_new_submission trigger, which bypasses
-- these policies entirely, so there is no INSERT policy for any role
create policy notifications_select_admin on notifications
  for select to authenticated using (is_admin());
create policy notifications_update_admin on notifications
  for update to authenticated using (is_admin()) with check (is_admin());

-- workforce_totals: public read (used as the % denominator in reports),
-- admin write
create policy workforce_totals_select_all on workforce_totals
  for select using (true);
create policy workforce_totals_admin_write on workforce_totals
  for all to authenticated using (is_admin()) with check (is_admin());

-- profiles: a signed-in user may read only their own row (used client-side
-- to determine isAdmin after login) — no self-service insert/update/delete;
-- admin accounts are provisioned via the Supabase Dashboard / service_role
create policy profiles_select_own on profiles
  for select to authenticated using (id = auth.uid());

-- Fallback explicit grants. Supabase projects normally already grant these
-- to anon/authenticated by default for the public schema — RLS above is
-- what actually restricts access — but run this if you see a generic
-- "permission denied for table X" rather than an RLS-shaped empty result.
grant select, insert, update, delete on
  departments, employees, surveys, submissions, notifications, workforce_totals
  to anon, authenticated;
grant select on profiles to authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

-- ── Storage: bucket for uploaded survey evidence images ──────────────────
insert into storage.buckets (id, name, public)
values ('survey-bukti', 'survey-bukti', false)
on conflict (id) do nothing;

-- Public/anon may upload evidence (the public page never reads it back)
create policy "survey-bukti insert public" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'survey-bukti');

-- Only admins can view/download evidence
create policy "survey-bukti select admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'survey-bukti' and is_admin());

commit;
