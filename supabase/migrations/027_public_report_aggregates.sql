-- Survey Central — the public /hasil-bukti page becomes a read-only copy of
-- the admin report (participation recap per tanggal / per divisi). It needs
-- only AGGREGATE numbers, never names or photos, so:
--   * public_bukti_surveys() now also returns max_pengisian (the report's
--     per-day target needs it) — dropped and recreated for the new shape;
--   * public_report_counts(survey) returns submission COUNTS grouped by
--     tanggal / departemen / jenis_pegawai;
--   * the names + evidence-photo endpoints from 022-024 are removed, so those
--     can no longer be fetched through the API either.
-- Visibility rules are unchanged: external surveys with tampil_publik = true
-- and status Aktif / Selesai only.
-- Run after 026_admin_manage_employees.sql.

begin;

-- Names + photos are no longer shown publicly: close those endpoints.
drop policy if exists "survey-bukti select public listed" on storage.objects;
drop function if exists is_public_bukti_file(text);
drop function if exists public_bukti_list(bigint, text, integer, integer, date, date);
drop function if exists public_bukti_list(bigint, text, integer, integer);

drop function if exists public_bukti_surveys();

create function public_bukti_surveys()
returns table (
  id bigint,
  nama text,
  tanggal_mulai date,
  tanggal_selesai date,
  status survey_status,
  max_pengisian integer
)
language sql stable security definer set search_path = public as $$
  select sv.id, sv.nama, sv.tanggal_mulai, sv.tanggal_selesai, sv.status, sv.max_pengisian
  from surveys sv
  where sv.tipe = 'Eksternal'
    and sv.tampil_publik
    and sv.status in ('Aktif', 'Selesai')
  order by sv.id desc;
$$;

create function public_report_counts(p_survey_id bigint)
returns table (
  tanggal date,
  departemen text,
  jenis_pegawai jenis_pegawai_enum,
  jumlah integer
)
language sql stable security definer set search_path = public as $$
  select s.tanggal, s.departemen, s.jenis_pegawai, count(*)::integer
  from submissions s
  join surveys sv on sv.id = s.survey_id
  where s.survey_id = p_survey_id
    and sv.tipe = 'Eksternal'
    and sv.tampil_publik
    and sv.status in ('Aktif', 'Selesai')
  group by s.tanggal, s.departemen, s.jenis_pegawai;
$$;

grant execute on function public_bukti_surveys() to anon, authenticated;
grant execute on function public_report_counts(bigint) to anon, authenticated;

commit;
