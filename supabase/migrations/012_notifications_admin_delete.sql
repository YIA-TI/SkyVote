-- Survey Central — allow admins to delete notifications (single or bulk
-- "clear all"). Only select + update policies existed before this; there
-- was no way to remove a notification row at all.
-- Run this after 011_merge_airport_aeronautical_into_aero_commercial.sql.

begin;

create policy notifications_delete_admin on notifications
  for delete to authenticated using (is_admin());

commit;
