-- Survey Central — weekend catch-up: on a Saturday or Sunday, a participant who still
-- owes votes may submit more than the normal daily limit, up to what they owe.
--
-- Rules (external surveys only; Organik and TAD, not Stakeholders, whose limit is
-- their own safety ceiling):
--   * Debt before a day D = (days from the survey's start up to the day before D)
--     x max_pengisian  -  the person's submissions on those days. Every day of the
--     period counts, weekends too. Never below 0.
--   * On a Saturday or Sunday the day's limit is max_pengisian + that debt, so the
--     normal quota stays and the extra is exactly what is owed. On any other day
--     the limit is max_pengisian, as before.
--   * A catch-up submission is recorded on the day it is made (the Saturday or
--     Sunday), not on the day it makes up for.
--   * A survey without a start date has no debt.
--
-- employee_day_limit() gives the limit for one person and day; the public form
-- reads it, and enforce_submission_quota (below) applies it, so it cannot be
-- bypassed. Everything else in the trigger is unchanged from 035.
-- Run after 038_readonly_can_read_aggregates.sql.

begin;

create or replace function employee_day_limit(
  p_survey_id bigint,
  p_nama text,
  p_tanggal date
) returns integer
language plpgsql stable security definer set search_path = public as $$
declare
  v_max integer;
  v_tipe survey_tipe;
  v_mulai date;
  v_stakeholder boolean;
  v_before integer;
  v_debt integer;
begin
  select max_pengisian, tipe, tanggal_mulai into v_max, v_tipe, v_mulai
  from surveys where id = p_survey_id;

  if not found then
    return null;
  end if;
  if v_tipe = 'Internal' then
    return 1;
  end if;

  select exists (
    select 1 from employees e
    where e.nama = p_nama and e.is_active and e.jenis_pegawai::text = 'Stakeholder'
  ) into v_stakeholder;

  -- Weekdays, stakeholders and surveys without a start date: the normal limit.
  if v_stakeholder
     or v_mulai is null
     or p_tanggal <= v_mulai
     or extract(isodow from p_tanggal) not in (6, 7) then
    return v_max;
  end if;

  select count(*)::integer into v_before
  from submissions
  where survey_id = p_survey_id and nama = p_nama and tanggal < p_tanggal;

  v_debt := greatest(0, (p_tanggal - v_mulai) * v_max - v_before);
  return v_max + v_debt;
end;
$$;

grant execute on function employee_day_limit(bigint, text, date) to anon, authenticated;

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
  v_limit integer;
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

    -- The normal limit, plus the debt on a Saturday or Sunday (employee_day_limit).
    v_limit := employee_day_limit(NEW.survey_id, NEW.nama, NEW.tanggal);

    if v_count >= v_limit then
      if v_limit > v_max then
        raise exception 'Anda sudah mengisi seluruh kuota hari ini beserta hutang pengisian (% kali pada tanggal ini)', v_limit;
      end if;
      raise exception 'Anda sudah mencapai batas maksimal pengisian survey ini pada tanggal tersebut (% kali per hari)', v_max;
    end if;
  end if;

  return NEW;
end;
$$;

commit;
