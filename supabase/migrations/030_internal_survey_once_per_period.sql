-- Survey Central — INTERNAL surveys can be filled only ONCE per employee for the
-- whole survey period. External surveys keep the per-day limit from 019
-- (max_pengisian per employee per tanggal).
--
--   * enforce_submission_quota(): for an Internal survey, any earlier submission
--     by the same employee name on that survey (any date) blocks a new one.
--     Everything else (status, period, external per-day quota) is as in 019.
--   * employee_submission_count(): for an Internal survey it counts across all
--     dates, so the public form shows the real "1 / 1" and locks the form.
--   * Existing Internal surveys get max_pengisian = 1, so the stored limit
--     matches the rule (anything that reads it, e.g. the report target, sees 1).
--     Submissions made before this migration are left untouched; they only
--     prevent a further one.
-- Run after 029_public_report_counts_order.sql.

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

  if v_tipe = 'Internal' then
    -- Once per employee for the whole period, whatever the date.
    select count(*) into v_count
    from submissions
    where survey_id = NEW.survey_id and nama = NEW.nama;

    if v_count >= 1 then
      raise exception 'Anda sudah mengisi survey internal ini. Survey internal hanya bisa diisi 1 kali selama periode survey.';
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

create or replace function employee_submission_count(
  p_survey_id bigint,
  p_nama text,
  p_tanggal date
) returns integer
language sql stable security definer set search_path = public as $$
  select count(*)::integer
  from submissions s
  join surveys sv on sv.id = s.survey_id
  where sv.status = 'Aktif'
    and s.survey_id = p_survey_id
    and s.nama = p_nama
    -- Internal surveys are limited per period, so every date counts.
    and (sv.tipe = 'Internal' or s.tanggal = p_tanggal);
$$;

update surveys set max_pengisian = 1 where tipe = 'Internal' and max_pengisian <> 1;

commit;
