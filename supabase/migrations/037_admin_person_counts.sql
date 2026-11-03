-- Survey Central — the Detail Survei page (status per employee) without downloading
-- the whole submissions table.
--
-- admin_person_counts(survey, tanggal): how many submissions each person made for
-- one survey, on one day (external surveys) or over the whole period (when
-- p_tanggal is null, for internal surveys). Returns nothing unless the caller is
-- an admin. Served by idx_submissions_survey_nama_tanggal / _survey_tanggal (036).
-- Run after 036_admin_report_aggregates.sql.

begin;

create or replace function admin_person_counts(p_survey_id bigint, p_tanggal date default null)
returns table (nama text, jumlah integer)
language sql stable security definer set search_path = public as $$
  select s.nama, count(*)::integer
  from submissions s
  where s.survey_id = p_survey_id
    and (p_tanggal is null or s.tanggal = p_tanggal)
    and is_admin()
  group by s.nama
  order by s.nama;
$$;

revoke execute on function admin_person_counts(bigint, date) from public, anon;
grant execute on function admin_person_counts(bigint, date) to authenticated;

commit;
