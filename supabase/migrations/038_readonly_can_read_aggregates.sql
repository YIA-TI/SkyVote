-- Survey Central — the aggregate functions from 036 and 037 checked is_admin(), which
-- is false for the 'readonly' role (028), so a readonly account saw empty reports,
-- dashboard and survey lists. Readonly may READ everything the admin screens show
-- (see the select policies in 028), so these read-only functions now accept it too.
--
-- Same bodies as 036 / 037; only the guard changes to (is_admin() or is_readonly()).
-- Run after 037_admin_person_counts.sql.

begin;

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
      and (is_admin() or is_readonly())
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
    and (is_admin() or is_readonly())
  group by s.nama
  order by s.nama;
$$;

create or replace function submission_counts_by_survey()
returns table (survey_id bigint, jumlah integer)
language sql stable security definer set search_path = public as $$
  select s.survey_id, count(*)::integer
  from submissions s
  where (is_admin() or is_readonly())
  group by s.survey_id;
$$;

create or replace function admin_person_counts(p_survey_id bigint, p_tanggal date default null)
returns table (nama text, jumlah integer)
language sql stable security definer set search_path = public as $$
  select s.nama, count(*)::integer
  from submissions s
  where s.survey_id = p_survey_id
    and (p_tanggal is null or s.tanggal = p_tanggal)
    and (is_admin() or is_readonly())
  group by s.nama
  order by s.nama;
$$;

commit;
