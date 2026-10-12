-- Survey Central — the admin chooses, per external survey, whether its
-- evidence results appear on the public "Hasil Input Bukti" page (/hasil-bukti).
-- Default is NOT shown: existing surveys become hidden until an admin ticks
-- the checkbox in the survey form, so nothing is exposed by accident.
-- The public RPCs and the storage helper from 022 now also require the flag.
-- Run after 022_public_bukti_page.sql.

begin;

alter table surveys add column tampil_publik boolean not null default false;

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
  where sv.tipe = 'Eksternal'
    and sv.tampil_publik
    and sv.status in ('Aktif', 'Selesai')
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
    and sv.tampil_publik
    and sv.status in ('Aktif', 'Selesai')
    and (coalesce(p_search, '') = '' or s.nama ilike '%' || p_search || '%')
  order by s.created_at desc, s.id desc
  limit least(greatest(coalesce(p_limit, 10), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

create or replace function is_public_bukti_file(p_name text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from submissions s
    join surveys sv on sv.id = s.survey_id
    where sv.tipe = 'Eksternal'
      and sv.tampil_publik
      and sv.status in ('Aktif', 'Selesai')
      and (s.file_bukti = p_name or s.file_bukti_2 = p_name)
  );
$$;

commit;
