-- Survey Central — a stakeholder may now submit more than their daily target.
--
--   * Target (what the report compares against): 100 votes per person per day,
--     and at most 100 per person per day are COUNTED (public_report_counts from
--     033 and capStakeholderVotes in the app both cap at 100). Votes above that
--     are stored and shown as "X vote masuk, 100 dihitung", but do not raise the
--     percentage or the totals.
--   * Daily MAXIMUM (what the database accepts): raised from 100 to 1000 per
--     person per survey per day, a loose safety ceiling against scripts and
--     mistakes flooding storage and the log quota.
--
-- Only enforce_submission_quota changes, and only that one constant. Keep the
-- 1000 equal to STAKEHOLDER_DAILY_CEILING in src/lib/participation.js.
-- Run after 034_stakeholder_target_window.sql.

begin;

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
  c_stakeholder_daily_ceiling constant integer := 1000;
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
    -- Above the daily target is allowed; only the loose safety ceiling applies.
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

commit;
