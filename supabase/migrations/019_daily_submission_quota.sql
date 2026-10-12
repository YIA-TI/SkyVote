-- Survey Central — max_pengisian is now a PER-DAY limit: one employee may
-- submit to one survey at most `max_pengisian` times for each `tanggal` (the
-- date the employee picks in the form), instead of that many times in total.
-- Only the quota count changes; the status / period checks are kept exactly
-- as in 010.
-- Run after 010_submission_date_within_period.sql.

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

  if (v_tanggal_mulai is not null and NEW.tanggal < v_tanggal_mulai)
     or (v_tanggal_selesai is not null and NEW.tanggal > v_tanggal_selesai) then
    raise exception 'Tanggal yang dipilih di luar periode survey';
  end if;

  select count(*) into v_count
  from submissions
  where survey_id = NEW.survey_id and nama = NEW.nama and tanggal = NEW.tanggal;

  if v_count >= v_max then
    raise exception 'Anda sudah mencapai batas maksimal pengisian survey ini pada tanggal tersebut (% kali per hari)', v_max;
  end if;

  return NEW;
end;
$$;

commit;
