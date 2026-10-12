-- Survey Central — date-range filter for the public "Hasil Input Bukti" page.
-- Adds p_tanggal_dari / p_tanggal_sampai (inclusive, both optional) to
-- public_bukti_list, filtering on the submission's `tanggal` (the date picked
-- in the form). The old 4-argument version is dropped so only one overload of
-- the function exists. Visibility rules are unchanged from 023.
-- Run after 023_survey_tampil_publik.sql.

begin;

drop function if exists public_bukti_list(bigint, text, integer, integer);

create or replace function public_bukti_list(
  p_survey_id bigint,
  p_search text default '',
  p_limit integer default 10,
  p_offset integer default 0,
  p_tanggal_dari date default null,
  p_tanggal_sampai date default null
)
returns table (
  id bigint,
  created_at timestamptz,
  tanggal date,
  nama text,
  departemen text,
  jenis_pegawai jenis_pegawai_enum,
  file_bukti text,
  file_bukti_2 text,
  total_count bigint
)
language sql stable security definer set search_path = public as $$
  select
    s.id, s.created_at, s.tanggal, s.nama, s.departemen, s.jenis_pegawai,
    s.file_bukti, s.file_bukti_2,
    count(*) over () as total_count
  from submissions s
  join surveys sv on sv.id = s.survey_id
  where s.survey_id = p_survey_id
    and sv.tipe = 'Eksternal'
    and sv.tampil_publik
    and sv.status in ('Aktif', 'Selesai')
    and (coalesce(p_search, '') = '' or s.nama ilike '%' || p_search || '%')
    and (p_tanggal_dari is null or s.tanggal >= p_tanggal_dari)
    and (p_tanggal_sampai is null or s.tanggal <= p_tanggal_sampai)
  order by s.created_at desc, s.id desc
  limit least(greatest(coalesce(p_limit, 10), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

grant execute on function public_bukti_list(bigint, text, integer, integer, date, date)
  to anon, authenticated;

commit;
