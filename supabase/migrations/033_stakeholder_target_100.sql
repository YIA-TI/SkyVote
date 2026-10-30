-- Survey Central — Stakeholders now have a target of 100 votes per person per
-- day (also their daily maximum: the safety ceiling in enforce_submission_quota
-- from 032 is 100 a day, so the two match). The earlier rule "2 a day, 0/50/100%"
-- is replaced by plain votes / target.
--
-- Only the public report counts change: for a stakeholder, at most 100 votes per
-- person per day are counted (it was 2). Same columns and visibility rules as 032.
-- Keep the 100 here equal to STAKEHOLDER_DAILY_TARGET in src/lib/participation.js
-- and to c_stakeholder_daily_ceiling in 032.
-- Run after 032_stakeholders.sql.

begin;

create or replace function public_report_counts(p_survey_id bigint)
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
    join surveys sv on sv.id = s.survey_id
    where s.survey_id = p_survey_id
      and sv.tipe = 'Eksternal'
      and sv.tampil_publik
      and sv.status in ('Aktif', 'Selesai')
    group by s.tanggal, s.departemen, s.jenis_pegawai, s.nama
  ) t
  group by t.tanggal, t.departemen, t.jenis_pegawai
  order by t.tanggal, t.departemen, t.jenis_pegawai;
$$;

commit;
