-- Survey Central — let the public page show an employee's real per-day quota.
--
-- Anonymous visitors have no SELECT policy on `submissions` (admin-only), so
-- the public page could never see how many times an employee already filled a
-- survey: the "X / N" counter was always 0 and the quota was only enforced when
-- the submit failed. This RPC returns just that one number — the count of
-- submissions for (survey, employee name, date) — without opening up the table.
-- It is limited to active surveys, and the employee list it is keyed by is
-- already publicly readable (employees_select_all).
-- Run after 019_daily_submission_quota.sql.

begin;

create or replace function employee_submission_count(
  p_survey_id bigint,
  p_nama text,
  p_tanggal date
) returns integer
language sql stable security definer set search_path = public as $$
  select count(*)::integer
  from submissions s
  join surveys sv on sv.id = s.survey_id
  where sv.status = 'Aktif'
    and s.survey_id = p_survey_id
    and s.nama = p_nama
    and s.tanggal = p_tanggal;
$$;

grant execute on function employee_submission_count(bigint, text, date) to anon, authenticated;

commit;
