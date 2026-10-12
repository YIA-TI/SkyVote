-- Survey Central — public (no login) "Hasil Input Bukti" page.
--
-- Anonymous visitors cannot SELECT submissions or read the private
-- survey-bukti bucket. This migration opens a deliberately narrow window for
-- ONE page, without loosening the tables themselves:
--   * public_bukti_surveys()  -> the external surveys that can be browsed
--   * public_bukti_list(...)  -> one page of rows (time, name, unit, jenis,
--                                 file paths) for one external survey
--   * a storage SELECT policy for anon limited to files that belong to a
--                                 listed submission of such a survey
-- Only EXTERNAL surveys with status Aktif / Selesai are exposed. Internal
-- survey answers, other tables and unreferenced storage files stay closed.
-- Run after 021_submission_extra_bukti.sql.

begin;

create or replace function public_bukti_surveys()
returns table (
  id bigint,
  nama text,
  tanggal_mulai date,
  tanggal_selesai date,
  status survey_status
)
language sql stable security definer set search_path = public as $$
  select sv.id, sv.nama, sv.tanggal_mulai, sv.tanggal_selesai, sv.status
  from surveys sv
  where sv.tipe = 'Eksternal' and sv.status in ('Aktif', 'Selesai')
  order by sv.id desc;
$$;

create or replace function public_bukti_list(
  p_survey_id bigint,
  p_search text default '',
  p_limit integer default 10,
  p_offset integer default 0
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
    and sv.status in ('Aktif', 'Selesai')
    and (coalesce(p_search, '') = '' or s.nama ilike '%' || p_search || '%')
  order by s.created_at desc, s.id desc
  limit least(greatest(coalesce(p_limit, 10), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

grant execute on function public_bukti_surveys() to anon, authenticated;
grant execute on function public_bukti_list(bigint, text, integer, integer) to anon, authenticated;

-- Storage: anon may read (and so create signed URLs for) only files that a
-- publicly listed submission points to. The check goes through a
-- security-definer helper because anon has no SELECT on submissions itself.
create or replace function is_public_bukti_file(p_name text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from submissions s
    join surveys sv on sv.id = s.survey_id
    where sv.tipe = 'Eksternal'
      and sv.status in ('Aktif', 'Selesai')
      and (s.file_bukti = p_name or s.file_bukti_2 = p_name)
  );
$$;

grant execute on function is_public_bukti_file(text) to anon, authenticated;

create policy "survey-bukti select public listed" on storage.objects
  for select to anon
  using (bucket_id = 'survey-bukti' and is_public_bukti_file(name));

commit;
