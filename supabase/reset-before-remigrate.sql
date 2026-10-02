-- Survey Central — full reset of everything the app's migrations created.
-- Run this ONCE in the SQL Editor of the project you want to wipe, right
-- before re-running supabase/migrations/001..010 from scratch.
--
-- Safe/idempotent: every drop uses IF EXISTS, and the pg_cron cleanup is
-- guarded so it's a no-op if pg_cron was never enabled.
--
-- Does NOT touch auth.users — any admin accounts created via
-- scripts/setup-admin-user.js stay in Authentication → Users, just without
-- a matching `profiles` row until you re-run that script (or re-insert the
-- profile row for the existing UUID).

begin;

-- Unschedule the pg_cron job (if migration 009 ever got that far) before
-- dropping the function it calls.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    if exists (select 1 from cron.job where jobname = 'sync-survey-statuses') then
      perform cron.unschedule('sync-survey-statuses');
    end if;
  end if;
end $$;

drop table if exists submissions cascade;
drop table if exists notifications cascade;
drop table if exists surveys cascade;
drop table if exists employees cascade;
drop table if exists departments cascade;
drop table if exists workforce_totals cascade;
drop table if exists profiles cascade;

drop function if exists enforce_submission_quota() cascade;
drop function if exists notify_new_submission() cascade;
drop function if exists set_updated_at() cascade;
drop function if exists is_admin() cascade;
drop function if exists employees_belum_survey(date) cascade;
drop function if exists sync_survey_statuses() cascade;

drop type if exists survey_status;
drop type if exists jenis_pegawai_enum;

commit;

-- Storage cleanup runs outside the transaction above (storage.objects is a
-- big table on some plans; keeping it separate avoids one huge lock).
delete from storage.objects where bucket_id = 'survey-bukti';
delete from storage.buckets where id = 'survey-bukti';
