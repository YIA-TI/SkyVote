-- Survey Central — let the admin choose which survey is pre-selected on the
-- public form when more than one survey is active. At most ONE survey is the
-- default (enforced by a partial unique index). The public page picks the
-- default if it is currently available (Aktif and within its period) and falls
-- back to the first available survey otherwise, so the flag never hides or
-- blocks anything.
--
-- set_default_survey() clears the old default and sets the new one in a single
-- transaction (pass NULL to clear it). Admin-only, checked inside the function.
-- Run after 030_internal_survey_once_per_period.sql.

begin;

alter table surveys add column is_default boolean not null default false;

create unique index surveys_single_default on surveys ((true)) where is_default;

create or replace function set_default_survey(p_survey_id bigint) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then
    raise exception 'Hanya admin yang boleh mengatur survei default';
  end if;

  -- Two statements: with the unique index, the old default must be cleared
  -- before the new one is set.
  update surveys set is_default = false where is_default;

  if p_survey_id is not null then
    update surveys set is_default = true where id = p_survey_id;
    if not found then
      raise exception 'Survei tidak ditemukan';
    end if;
  end if;
end;
$$;

revoke execute on function set_default_survey(bigint) from public, anon;
grant execute on function set_default_survey(bigint) to authenticated;

commit;
