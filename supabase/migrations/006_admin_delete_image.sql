-- Survey Central — allow admins to delete an evidence photo (storage
-- object) and clear the submission's file_bukti pointer, without deleting
-- the submission row itself (so participation counts/quota stay intact).
-- Run this in the Supabase SQL Editor after 001-005.

begin;

-- Admin needs UPDATE on submissions to null out file_bukti after deleting
-- the underlying storage object (no UPDATE policy existed before this).
create policy submissions_update_admin on submissions
  for update to authenticated using (is_admin()) with check (is_admin());

-- Admin needs DELETE on the survey-bukti storage objects to actually
-- remove the file (only INSERT + SELECT policies existed before this).
create policy "survey-bukti delete admin" on storage.objects
  for delete to authenticated using (bucket_id = 'survey-bukti' and is_admin());

commit;
