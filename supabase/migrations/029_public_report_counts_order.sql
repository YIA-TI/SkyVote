-- Survey Central — make public_report_counts() safe to page through.
-- It returns one row per tanggal / departemen / jenis_pegawai (up to ~50 rows
-- per day), so a long survey passes the API's 1000-rows-per-request cap. The
-- client now fetches it page by page, which needs a deterministic order: with
-- none, pages could repeat or skip rows. Same columns and visibility rules as
-- 027; only the ORDER BY is new.
-- Run after 028_readonly_role.sql.

begin;

create or replace function public_report_counts(p_survey_id bigint)
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
  group by s.tanggal, s.departemen, s.jenis_pegawai
  order by s.tanggal, s.departemen, s.jenis_pegawai;
$$;

commit;
