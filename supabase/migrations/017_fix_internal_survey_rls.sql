-- Survey Central -- fix submit_internal_survey: the exact same INSERT into
-- submissions that succeeds when run directly via PostgREST was observed to
-- fail RLS ("new row violates row-level security policy for table
-- submissions") when run from inside this PL/pgSQL function, for an anon
-- caller, even though the function is plain SECURITY INVOKER (the default)
-- and current_user/is_admin() correctly report 'anon'/false inside it.
-- Reproduced with a minimal hardcoded-values test function -- the RLS check
-- genuinely evaluates differently once the INSERT is issued from inside a
-- function body versus a top-level statement. Rather than chase that further,
-- make this trusted, narrowly-scoped function SECURITY DEFINER instead: it
-- only ever performs the two controlled inserts below (no dynamic SQL, no
-- arbitrary table access), and the real gatekeeping -- survey must exist, be
-- "Aktif", be within its date period, and respect each employee's quota --
-- is already enforced independently by the trg_enforce_submission_quota
-- BEFORE INSERT trigger on submissions (security definer since 001/010),
-- which fires regardless of this function's own security context.

begin;

drop function if exists debug_whoami();
drop function if exists debug_insert_test();

create or replace function submit_internal_survey(
  p_survey_id bigint,
  p_nama text,
  p_tanggal date,
  p_jenis_pegawai jenis_pegawai_enum,
  p_departemen text,
  p_answers jsonb
) returns submissions
language plpgsql security definer set search_path = public as $$
declare
  v_submission submissions;
  v_answer jsonb;
begin
  insert into submissions (nama, tanggal, survey_id, jenis_pegawai, departemen, file_bukti)
  values (p_nama, p_tanggal, p_survey_id, p_jenis_pegawai, p_departemen, '')
  returning * into v_submission;

  for v_answer in select * from jsonb_array_elements(p_answers)
  loop
    insert into survey_answers (submission_id, survey_id, question_id, pertanyaan, jawaban)
    values (
      v_submission.id,
      p_survey_id,
      (v_answer->>'question_id')::bigint,
      v_answer->>'pertanyaan',
      v_answer->>'jawaban'
    );
  end loop;

  return v_submission;
end;
$$;

revoke execute on function submit_internal_survey(
  bigint, text, date, jenis_pegawai_enum, text, jsonb
) from public;
grant execute on function submit_internal_survey(
  bigint, text, date, jenis_pegawai_enum, text, jsonb
) to anon, authenticated;

commit;
