-- Survey Central — lock submissions.tanggal to the actual day of submission
-- (Asia/Jakarta). The public form's date field used to be a free picker
-- clamped only to the survey's own tanggal_mulai..tanggal_selesai window
-- (see publicPage.vue before this change), which let a submission be
-- backdated/forward-dated to any day within that period. The UI no longer
-- offers that picker, but the server must not trust the client's `tanggal`
-- value either — so it's overwritten here unconditionally, regardless of
-- what the client sends (devtools/API included).
-- Run after 013_employee_soft_delete.sql.

begin;

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

  -- Tanggal pengisian selalu dikunci ke hari ini — tidak bisa dimajukan
  -- atau dimundurkan, apapun nilai yang dikirim client.
  NEW.tanggal := v_today;

  select count(*) into v_count
  from submissions
  where survey_id = NEW.survey_id and nama = NEW.nama;

  if v_count >= v_max then
    raise exception 'Anda sudah mencapai batas maksimal pengisian survey ini (% kali)', v_max;
  end if;

  return NEW;
end;
$$;

commit;
