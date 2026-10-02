-- Survey Central — enforce survey date-period for public submissions and
-- auto-close surveys ("Selesai") once tanggal_selesai has passed.
-- Run after 008_real_employee_data.sql.
--
-- All "today" comparisons use Asia/Jakarta (WIB) so a survey's last day
-- stays open through the full local calendar day, regardless of the
-- database server's default timezone (usually UTC).

begin;

-- ── enforce_submission_quota: also reject submissions outside the survey's
--    tanggal_mulai..tanggal_selesai window (in addition to the existing
--    status = 'Aktif' check) ─────────────────────────────────────────────
create or replace function enforce_submission_quota() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_max integer;
  v_status survey_status;
  v_tanggal_mulai date;
  v_tanggal_selesai date;
  v_count integer;
  v_today date;
begin
  perform pg_advisory_xact_lock(hashtextextended(NEW.survey_id::text || ':' || NEW.nama, 0));

  select max_pengisian, status, tanggal_mulai, tanggal_selesai
    into v_max, v_status, v_tanggal_mulai, v_tanggal_selesai
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

  select count(*) into v_count
  from submissions
  where survey_id = NEW.survey_id and nama = NEW.nama;

  if v_count >= v_max then
    raise exception 'Anda sudah mencapai batas maksimal pengisian survey ini (% kali)', v_max;
  end if;

  return NEW;
end;
$$;

-- ── RLS: anon may only see/insert-into surveys that are Aktif AND within
--    their date period (mirrors the trigger above; this is what actually
--    keeps a lapsed-but-still-"Aktif" survey out of the public dropdown) ──
drop policy if exists surveys_select_public_active on surveys;
create policy surveys_select_public_active on surveys
  for select to anon using (
    status = 'Aktif'
    and (tanggal_mulai is null or tanggal_mulai <= (now() at time zone 'Asia/Jakarta')::date)
    and (tanggal_selesai is null or tanggal_selesai >= (now() at time zone 'Asia/Jakarta')::date)
  );

drop policy if exists submissions_insert_public on submissions;
create policy submissions_insert_public on submissions
  for insert to anon, authenticated
  with check (
    exists (
      select 1 from surveys sv where sv.id = survey_id
        and sv.status = 'Aktif'
        and (sv.tanggal_mulai is null or sv.tanggal_mulai <= (now() at time zone 'Asia/Jakarta')::date)
        and (sv.tanggal_selesai is null or sv.tanggal_selesai >= (now() at time zone 'Asia/Jakarta')::date)
    )
  );

-- ── sync_survey_statuses: flips Terjadwal -> Aktif once tanggal_mulai has
--    arrived, and Terjadwal/Aktif -> Selesai once tanggal_selesai has
--    passed. Surveys with no dates set are left untouched (still fully
--    manual). Callable by anon/authenticated so the app can call it
--    opportunistically on load, and scheduled via pg_cron below so it also
--    runs with nobody visiting the app. ───────────────────────────────────
create or replace function sync_survey_statuses() returns void
language plpgsql security definer set search_path = public as $$
begin
  update surveys
  set status = 'Aktif'
  where status = 'Terjadwal'
    and tanggal_mulai is not null
    and tanggal_mulai <= (now() at time zone 'Asia/Jakarta')::date
    and (tanggal_selesai is null or tanggal_selesai >= (now() at time zone 'Asia/Jakarta')::date);

  update surveys
  set status = 'Selesai'
  where status in ('Aktif', 'Terjadwal')
    and tanggal_selesai is not null
    and tanggal_selesai < (now() at time zone 'Asia/Jakarta')::date;
end;
$$;

grant execute on function sync_survey_statuses() to anon, authenticated;

-- ── pg_cron: run the sync every 15 minutes regardless of app traffic ─────
create extension if not exists pg_cron;

grant usage on schema cron to postgres;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'sync-survey-statuses') then
    perform cron.unschedule('sync-survey-statuses');
  end if;
end $$;

select cron.schedule('sync-survey-statuses', '*/15 * * * *', $$select public.sync_survey_statuses()$$);

commit;
