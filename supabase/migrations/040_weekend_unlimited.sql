-- Survey Central — "weekend unlimited" access for chosen employees.
--
-- employees.weekend_unlimited: an Organik / TAD employee with this switched on may
-- submit as many times as they like on a Saturday or Sunday, up to a safety
-- ceiling of 1000 a day (same as Stakeholders). Weekdays stay normal, and so does
-- the weekend catch-up rule for everyone else (039).
--
-- Reports: like a Stakeholder's votes above the target, such an employee's weekend
-- votes above the survey's normal daily limit are SHOWN as Voting (jumlah_asli) but
-- COUNTED only up to that limit (jumlah), so percentage and Gap are not inflated.
-- That is the same `jumlah` / `jumlah_asli` pair public_report_counts (033) and
-- admin_report_counts (038) already return; only the cap rule gains a branch.
--
-- Keep the 1000 equal to WEEKEND_UNLIMITED_CEILING in src/lib/participation.js.
-- Run after 039_weekend_catch_up.sql.

begin;

alter table employees add column if not exists weekend_unlimited boolean not null default false;

-- The day's limit for one person: unchanged from 039, plus the weekend-unlimited case.
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
  v_unlimited boolean;
  v_before integer;
  v_debt integer;
  c_weekend_ceiling constant integer := 1000;
begin
  select max_pengisian, tipe, tanggal_mulai into v_max, v_tipe, v_mulai
  from surveys where id = p_survey_id;

  if not found then
    return null;
  end if;
  if v_tipe = 'Internal' then
    return 1;
  end if;

  select
    exists (select 1 from employees e
            where e.nama = p_nama and e.is_active and e.jenis_pegawai::text = 'Stakeholder'),
    exists (select 1 from employees e
            where e.nama = p_nama and e.is_active and e.weekend_unlimited
              and e.jenis_pegawai::text <> 'Stakeholder')
  into v_stakeholder, v_unlimited;

  if v_stakeholder or extract(isodow from p_tanggal) not in (6, 7) then
    return v_max;
  end if;

  -- Saturday / Sunday from here on.
  if v_unlimited then
    return greatest(v_max, c_weekend_ceiling);
  end if;

  -- Weekend catch-up (039): normal limit plus what the person still owes.
  if v_mulai is null or p_tanggal <= v_mulai then
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

-- Same trigger as 039 with a clearer message when the weekend ceiling is hit.
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

  select exists (
    select 1 from employees e
    where e.nama = NEW.nama and e.is_active and e.jenis_pegawai::text = 'Stakeholder'
  ) into v_stakeholder;

  if NEW.jenis_pegawai::text = 'Stakeholder' and not v_stakeholder then
    raise exception 'Peserta ini bukan Stakeholder';
  end if;

  if v_stakeholder and NEW.jenis_pegawai::text <> 'Stakeholder' then
    NEW.jenis_pegawai := 'Stakeholder'::jenis_pegawai_enum;
    NEW.departemen := 'Stakeholders';
  end if;

  if v_tipe = 'Internal' then
    select count(*) into v_count
    from submissions
    where survey_id = NEW.survey_id and nama = NEW.nama;

    if v_count >= 1 then
      raise exception 'Anda sudah mengisi survey internal ini. Survey internal hanya bisa diisi 1 kali selama periode survey.';
    end if;
  elsif v_stakeholder then
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

    -- The normal limit, plus the weekend rules (employee_day_limit).
    v_limit := employee_day_limit(NEW.survey_id, NEW.nama, NEW.tanggal);

    if v_count >= v_limit then
      if v_limit >= 1000 then
        raise exception 'Batas pengaman % isian per hari sudah tercapai', v_limit;
      elsif v_limit > v_max then
        raise exception 'Anda sudah mengisi seluruh kuota hari ini beserta hutang pengisian (% kali pada tanggal ini)', v_limit;
      end if;
      raise exception 'Anda sudah mencapai batas maksimal pengisian survey ini pada tanggal tersebut (% kali per hari)', v_max;
    end if;
  end if;

  return NEW;
end;
$$;

-- Report counts: a stakeholder's votes are capped at 100 per person per day (033);
-- now a weekend-unlimited employee's weekend votes are capped at the survey's normal
-- daily limit. `jumlah` = counted, `jumlah_asli` = everything that came in.
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
    sum(least(t.c, coalesce(t.cap, t.c)))::integer,
    sum(t.c)::integer
  from (
    select
      s.tanggal, s.departemen, s.jenis_pegawai, s.nama, count(*)::integer as c,
      case
        when s.jenis_pegawai::text = 'Stakeholder' then 100
        when extract(isodow from s.tanggal) in (6, 7)
             and exists (select 1 from employees e
                         where e.nama = s.nama and e.weekend_unlimited
                           and e.jenis_pegawai::text <> 'Stakeholder')
          then max(sv.max_pengisian)
        else null
      end as cap
    from submissions s
    join surveys sv on sv.id = s.survey_id
    where s.survey_id = p_survey_id
      and (is_admin() or is_readonly())
    group by s.tanggal, s.departemen, s.jenis_pegawai, s.nama
  ) t
  group by t.tanggal, t.departemen, t.jenis_pegawai
  order by t.tanggal, t.departemen, t.jenis_pegawai;
$$;

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
    sum(least(t.c, coalesce(t.cap, t.c)))::integer,
    sum(t.c)::integer
  from (
    select
      s.tanggal, s.departemen, s.jenis_pegawai, s.nama, count(*)::integer as c,
      case
        when s.jenis_pegawai::text = 'Stakeholder' then 100
        when extract(isodow from s.tanggal) in (6, 7)
             and exists (select 1 from employees e
                         where e.nama = s.nama and e.weekend_unlimited
                           and e.jenis_pegawai::text <> 'Stakeholder')
          then max(sv.max_pengisian)
        else null
      end as cap
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
