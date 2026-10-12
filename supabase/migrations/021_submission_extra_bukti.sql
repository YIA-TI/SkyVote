-- Survey Central — optional second evidence photo for external surveys.
-- `file_bukti` stays the required/main photo; `file_bukti_2` is an optional
-- extra one ('' when not provided, same convention as file_bukti).
-- Run after 020_employee_daily_submission_count.sql.

begin;

alter table submissions add column file_bukti_2 text not null default '';

commit;
