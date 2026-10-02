-- Survey Central — schema (tables, enums, triggers, RPC)
-- Run this first in the Supabase SQL Editor.

begin;

-- ── Enum types ────────────────────────────────────────────────────────────
create type survey_status as enum ('Draft', 'Terjadwal', 'Aktif', 'Selesai');
create type jenis_pegawai_enum as enum ('Organik', 'Non-Organik');

-- ── departments ──────────────────────────────────────────────────────────
create table departments (
  id bigint generated always as identity primary key,
  nama text not null unique,
  created_at timestamptz not null default now()
);

-- ── employees ────────────────────────────────────────────────────────────
create table employees (
  id bigint generated always as identity primary key,
  nama text not null unique,
  unit_kerja text not null references departments(nama) on update cascade,
  jenis_pegawai jenis_pegawai_enum not null,
  created_at timestamptz not null default now()
);
create index idx_employees_unit_kerja on employees(unit_kerja);
create index idx_employees_nama on employees(lower(nama));

-- ── surveys ──────────────────────────────────────────────────────────────
create table surveys (
  id bigint generated always as identity primary key,
  nama text not null,
  link text not null default '',
  tanggal_mulai date,
  tanggal_selesai date,
  status survey_status not null default 'Draft',
  max_pengisian integer not null default 20 check (max_pengisian > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_tanggal_order check (
    tanggal_mulai is null or tanggal_selesai is null or tanggal_mulai <= tanggal_selesai
  )
);
create index idx_surveys_status on surveys(status);

create or replace function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_surveys_updated_at
  before update on surveys
  for each row execute function set_updated_at();

-- ── submissions ──────────────────────────────────────────────────────────
create table submissions (
  id bigint generated always as identity primary key,
  nama text not null,
  tanggal date not null,
  survey_id bigint not null references surveys(id) on delete cascade,
  jenis_pegawai jenis_pegawai_enum not null,
  departemen text not null references departments(nama) on update cascade,
  file_bukti text not null default '',
  created_at timestamptz not null default now()
);
create index idx_submissions_survey on submissions(survey_id);
create index idx_submissions_nama on submissions(nama);
create index idx_submissions_tanggal on submissions(tanggal);
create index idx_submissions_survey_nama on submissions(survey_id, nama);
create index idx_submissions_departemen on submissions(departemen);

-- ── notifications ────────────────────────────────────────────────────────
create table notifications (
  id bigint generated always as identity primary key,
  message text not null,
  created_at timestamptz not null default now(),
  read boolean not null default false
);
create index idx_notifications_created_at on notifications(created_at desc);
create index idx_notifications_unread on notifications(read) where read = false;

-- ── workforce_totals (denominator constant for report percentages) ──────
create table workforce_totals (
  jenis_pegawai jenis_pegawai_enum primary key,
  total integer not null check (total >= 0)
);

-- ── profiles (RBAC: one row per admin auth user) ─────────────────────────
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin')),
  display_name text,
  created_at timestamptz not null default now()
);

-- ── RBAC helper used by every RLS policy ─────────────────────────────────
create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'
  );
$$;

-- ── Server-authoritative quota + active-survey enforcement ───────────────
-- Mirrors the app's "maxPengisian = max times ONE employee may submit to
-- THIS survey" rule, plus a survey-must-be-Aktif check, done at the DB
-- level so it can't be bypassed by calling the REST API directly.
create or replace function enforce_submission_quota() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_max integer;
  v_status survey_status;
  v_count integer;
begin
  -- Serialize concurrent submits for the same (survey, employee) pair so a
  -- race between two simultaneous inserts can't both slip past the count
  -- check before either commits.
  perform pg_advisory_xact_lock(hashtextextended(NEW.survey_id::text || ':' || NEW.nama, 0));

  select max_pengisian, status into v_max, v_status
  from surveys where id = NEW.survey_id;

  if v_status is null then
    raise exception 'Survey tidak ditemukan';
  end if;

  if v_status <> 'Aktif' then
    raise exception 'Survey tidak aktif untuk pengisian';
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

create trigger trg_enforce_submission_quota
  before insert on submissions
  for each row execute function enforce_submission_quota();

-- ── Auto-notification on new submission ──────────────────────────────────
create or replace function notify_new_submission() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_survey_nama text;
begin
  select nama into v_survey_nama from surveys where id = NEW.survey_id;
  insert into notifications (message)
  values (format('Bukti survei baru dari %s untuk "%s"', NEW.nama, coalesce(v_survey_nama, 'survey')));
  return NEW;
end;
$$;

create trigger trg_notify_new_submission
  after insert on submissions
  for each row execute function notify_new_submission();

-- ── employeesBelumSurvey / employeesBelumSurveyOnDate as one RPC ────────
create or replace function employees_belum_survey(p_tanggal date default null)
returns setof employees
language sql stable as $$
  select e.*
  from employees e
  where not exists (
    select 1 from submissions s
    where s.nama = e.nama
      and (p_tanggal is null or s.tanggal = p_tanggal)
  )
  order by e.nama;
$$;

commit;
