-- Survey Central — new 'readonly' role: can sign in to the admin area and READ
-- survey data (Dashboard, Hasil Survei Internal, Laporan) but can't change
-- anything.
--
-- is_admin() is deliberately NOT widened: every write policy in the schema is
-- guarded by is_admin() / is_super_admin(), so a readonly account is rejected
-- by the database on any insert / update / delete. It only gets extra
-- SELECT-only policies on the tables those three pages read.
-- Run after 027_public_report_aggregates.sql.

begin;

alter table profiles drop constraint if exists profiles_role_check;
alter table profiles
  add constraint profiles_role_check check (role in ('admin', 'super_admin', 'readonly'));

create or replace function is_readonly() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p where p.id = auth.uid() and p.role = 'readonly'
  );
$$;

-- Dashboard / Laporan: surveys (every status) and submissions.
drop policy if exists surveys_select_readonly on surveys;
create policy surveys_select_readonly on surveys
  for select to authenticated using (is_readonly());

drop policy if exists submissions_select_readonly on submissions;
create policy submissions_select_readonly on submissions
  for select to authenticated using (is_readonly());

-- Hasil Survei Internal: questions, options and answers.
drop policy if exists survey_questions_select_readonly on survey_questions;
create policy survey_questions_select_readonly on survey_questions
  for select to authenticated using (is_readonly());

drop policy if exists survey_question_options_select_readonly on survey_question_options;
create policy survey_question_options_select_readonly on survey_question_options
  for select to authenticated using (is_readonly());

drop policy if exists survey_answers_select_readonly on survey_answers;
create policy survey_answers_select_readonly on survey_answers
  for select to authenticated using (is_readonly());

-- Laporan -> detail per departemen opens the evidence photos.
drop policy if exists "survey-bukti select readonly" on storage.objects;
create policy "survey-bukti select readonly" on storage.objects
  for select to authenticated
  using (bucket_id = 'survey-bukti' and is_readonly());

commit;
