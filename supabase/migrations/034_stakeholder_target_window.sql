-- Survey Central — a stakeholder's target applies only inside a window of dates,
-- and deactivating the account no longer erases it from the past.
--
-- The reports used to count only ACTIVE people, for every day: switching a
-- stakeholder off removed their target (and headcount) from days they were
-- needed, e.g. 30 and 31 October. Now each stakeholder carries its own window:
--   target_mulai   first day the target counts (null = the day the record was created)
--   target_selesai last day the target counts  (null = no end yet)
-- and the report counts a stakeholder on a day inside that window whether or not
-- the account is active now. Organik and TAD employees are unchanged (current
-- active headcount).
--
-- Deactivating an account stops new submissions (it leaves the public name
-- search and the quota trigger no longer recognises it); it does not touch the
-- window, so the past stays intact.
--
-- The existing booster accounts were only needed on 30 and 31 October 2026, so
-- that is the window they get here.
-- Run after 033_stakeholder_target_100.sql.

begin;

alter table employees add column if not exists target_mulai date;
alter table employees add column if not exists target_selesai date;

alter table employees drop constraint if exists employees_target_window_check;
alter table employees
  add constraint employees_target_window_check
  check (target_mulai is null or target_selesai is null or target_selesai >= target_mulai);

update employees
set target_mulai = date '2026-10-30',
    target_selesai = date '2026-10-31'
where jenis_pegawai::text = 'Stakeholder'
  and target_mulai is null
  and target_selesai is null;

commit;
