-- Survey Central — keep the admin screens fast as submissions pile up.
--
-- Until now every admin page downloaded the whole submissions table (1000 rows per
-- request) and counted in the browser. With ~1000 new rows a day that grows
-- without bound. These functions let the database do the counting:
--
--   * admin_report_counts(survey)   — counts per tanggal / departemen / jenis for
--     one survey, like public_report_counts (033) but for admins: any survey type
--     and status, nothing hidden. jumlah = counted (a stakeholder's votes capped at
--     100 per person per day), jumlah_asli = everything that came in.
--   * admin_votes_per_person(survey) — votes per person (for the "lowest voters"
--     ranking).
--   * submission_counts_by_survey()  — total submissions per survey (Kelola Survei).
--
-- All three return nothing unless the caller is an admin (is_admin()). The extra
-- indexes serve the same queries and the quota trigger that runs on every insert.
-- Keep the 100 here equal to STAKEHOLDER_DAILY_TARGET in src/lib/participation.js.
-- Run after 035_stakeholder_ceiling_1000.sql.

begin;

create index if not exists idx_submissions_survey_tanggal on submissions(survey_id, tanggal);
create index if not exists idx_submissions_survey_nama_tanggal on submissions(survey_id, nama, tanggal);

create or replace function admin_report_counts(p_survey_id bigint)
returns table (
  tanggal date,
  departemen text,
  jenis_pegawai jenis_pegawai_enum,
  jumlah integer,
  jumlah_asli integer
)
language sql stable security definer set search_path = public as $$
  select
    t.tanggal,
    t.departemen,
    t.jenis_pegawai,
    sum(case when t.jenis_pegawai::text = 'Stakeholder' then least(t.c, 100) else t.c end)::integer,
    sum(t.c)::integer
  from (
    select s.tanggal, s.departemen, s.jenis_pegawai, s.nama, count(*)::integer as c
    from submissions s
    where s.survey_id = p_survey_id
      and is_admin()
    group by s.tanggal, s.departemen, s.jenis_pegawai, s.nama
  ) t
  group by t.tanggal, t.departemen, t.jenis_pegawai
  order by t.tanggal, t.departemen, t.jenis_pegawai;
$$;

create or replace function admin_votes_per_person(p_survey_id bigint)
returns table (nama text, jumlah integer)
language sql stable security definer set search_path = public as $$
  select s.nama, count(*)::integer
  from submissions s
  where s.survey_id = p_survey_id
    and is_admin()
  group by s.nama
  order by s.nama;
$$;

create or replace function submission_counts_by_survey()
returns table (survey_id bigint, jumlah integer)
language sql stable security definer set search_path = public as $$
  select s.survey_id, count(*)::integer
  from submissions s
  where is_admin()
  group by s.survey_id;
$$;

revoke execute on function admin_report_counts(bigint) from public, anon;
revoke execute on function admin_votes_per_person(bigint) from public, anon;
revoke execute on function submission_counts_by_survey() from public, anon;
grant execute on function admin_report_counts(bigint) to authenticated;
grant execute on function admin_votes_per_person(bigint) to authenticated;
grant execute on function submission_counts_by_survey() to authenticated;

commit;
