-- Survey Central — "Stakeholders": a participant category that is NOT bound by
-- the usual fill limit.
--
--   * Stakeholders are rows in `employees` with jenis_pegawai = 'Stakeholder'
--     and unit_kerja = 'Stakeholders' (their own division in the reports).
--   * They have no maximum number of votes. The expected minimum is 2 votes per
--     day; in the reports a stakeholder's day counts as 0 votes -> 0%,
--     1 vote -> 50%, 2 or more -> 100% (at most 2 votes per person per day are
--     COUNTED; the real number is still stored and can be shown separately).
--   * "No maximum" still has a very loose safety ceiling per person per day
--     (100) so a script or a mistake cannot flood storage and the log quota.
--   * Everything else is unchanged: the survey must be Aktif and the date must be
--     inside its period. Internal surveys keep their once-per-period rule for
--     everyone, stakeholders included.
--
-- Note: the new enum value is only compared as text (jenis_pegawai::text) inside
-- the functions below, because a value added with ALTER TYPE cannot be used as a
-- literal until that statement's transaction has been committed.
-- Run after 031_default_survey.sql.

begin;

alter type jenis_pegawai_enum add value if not exists 'Stakeholder';

insert into departments (nama) values ('Stakeholders') on conflict (nama) do nothing;

-- ── Quota: stakeholders skip the per-day limit ──────────────────────────────
create or replace function enforce_submission_quota() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_max integer;
  v_tipe survey_tipe;
  v_status survey_status;
  v_tanggal_mulai date;
  v_tanggal_selesai date;
  v_count integer;
  v_today date;
  v_stakeholder boolean;
  c_stakeholder_daily_ceiling constant integer := 100;
begin
  perform pg_advisory_xact_lock(hashtextextended(NEW.survey_id::text || ':' || NEW.nama, 0));

  select max_pengisian, tipe, status, tanggal_mulai, tanggal_selesai
    into v_max, v_tipe, v_status, v_tanggal_mulai, v_tanggal_selesai
  from surveys where id = NEW.survey_id;

  if v_status is null then
    raise exception 'Survey tidak ditemukan';
  end if;

  if v_status <> 'Aktif' then
    raise exception 'Survey tidak aktif untuk pengisian';
  end if;

  v_today := (now() at time zone 'Asia/Jakarta')::date;
  if (v_tanggal_mulai is not null and v_today < v_tanggal_mulai)
     or (v_tanggal_selesai is not null and v_today > v_tanggal_selesai) then
    raise exception 'Survey sudah di luar periode pengisian';
  end if;

  if (v_tanggal_mulai is not null and NEW.tanggal < v_tanggal_mulai)
     or (v_tanggal_selesai is not null and NEW.tanggal > v_tanggal_selesai) then
    raise exception 'Tanggal yang dipilih di luar periode survey';
  end if;

  -- Whether this name is an active stakeholder is decided by the employees
  -- table, never by what the client says about itself.
  select exists (
    select 1 from employees e
    where e.nama = NEW.nama and e.is_active and e.jenis_pegawai::text = 'Stakeholder'
  ) into v_stakeholder;

  if NEW.jenis_pegawai::text = 'Stakeholder' and not v_stakeholder then
    raise exception 'Peserta ini bukan Stakeholder';
  end if;

  if v_stakeholder and NEW.jenis_pegawai::text <> 'Stakeholder' then
    -- keep the recorded category consistent with the employee record
    NEW.jenis_pegawai := 'Stakeholder'::jenis_pegawai_enum;
    NEW.departemen := 'Stakeholders';
  end if;

  if v_tipe = 'Internal' then
    -- Once per employee for the whole period (stakeholders too).
    select count(*) into v_count
    from submissions
    where survey_id = NEW.survey_id and nama = NEW.nama;

    if v_count >= 1 then
      raise exception 'Anda sudah mengisi survey internal ini. Survey internal hanya bisa diisi 1 kali selama periode survey.';
    end if;
  elsif v_stakeholder then
    -- No maximum, only the loose safety ceiling.
    select count(*) into v_count
    from submissions
    where survey_id = NEW.survey_id and nama = NEW.nama and tanggal = NEW.tanggal;

    if v_count >= c_stakeholder_daily_ceiling then
      raise exception 'Batas pengaman % isian per hari sudah tercapai', c_stakeholder_daily_ceiling;
    end if;
  else
    select count(*) into v_count
    from submissions
    where survey_id = NEW.survey_id and nama = NEW.nama and tanggal = NEW.tanggal;

    if v_count >= v_max then
      raise exception 'Anda sudah mencapai batas maksimal pengisian survey ini pada tanggal tersebut (% kali per hari)', v_max;
    end if;
  end if;

  return NEW;
end;
$$;

-- ── Public report counts: stakeholders' votes are capped at 2 per person/day ─
-- `jumlah` is what the report COUNTS (capped for stakeholders, so the percentage
-- rule 0 / 50 / 100% falls out of votes / target); `jumlah_asli` is the real
-- number of submissions. The return shape changes, so the function is replaced.
drop function if exists public_report_counts(bigint);

create function public_report_counts(p_survey_id bigint)
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
    sum(case when t.jenis_pegawai::text = 'Stakeholder' then least(t.c, 2) else t.c end)::integer,
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

grant execute on function public_report_counts(bigint) to anon, authenticated;

commit;
