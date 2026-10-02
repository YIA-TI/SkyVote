-- Survey Central -- Internal surveys (questions answered inside the app,
-- instead of an external link + uploaded proof photo).

begin;

create type survey_tipe as enum ('Eksternal', 'Internal');
alter table surveys add column tipe survey_tipe not null default 'Eksternal';

-- ── survey_questions / survey_question_options ───────────────────────────
create table survey_questions (
  id bigint generated always as identity primary key,
  survey_id bigint not null references surveys(id) on delete cascade,
  urutan integer not null default 0,
  pertanyaan text not null,
  created_at timestamptz not null default now()
);
create index idx_survey_questions_survey on survey_questions(survey_id);

create table survey_question_options (
  id bigint generated always as identity primary key,
  question_id bigint not null references survey_questions(id) on delete cascade,
  urutan integer not null default 0,
  opsi text not null
);
create index idx_survey_question_options_question on survey_question_options(question_id);

-- ── survey_answers ────────────────────────────────────────────────────────
-- pertanyaan/jawaban are stored as a text snapshot (like submissions.departemen
-- elsewhere in this schema) rather than relying solely on question_id, because
-- the admin builder re-saves a survey's questions via delete-then-reinsert —
-- question_id can go stale (on delete set null) after an edit, but the text
-- snapshot keeps old answers readable regardless.
create table survey_answers (
  id bigint generated always as identity primary key,
  submission_id bigint not null references submissions(id) on delete cascade,
  survey_id bigint not null references surveys(id) on delete cascade,
  question_id bigint references survey_questions(id) on delete set null,
  pertanyaan text not null,
  jawaban text not null,
  created_at timestamptz not null default now()
);
create index idx_survey_answers_submission on survey_answers(submission_id);
create index idx_survey_answers_survey on survey_answers(survey_id);
create index idx_survey_answers_question on survey_answers(question_id);

-- ── RLS ────────────────────────────────────────────────────────────────────
alter table survey_questions enable row level security;
alter table survey_question_options enable row level security;
alter table survey_answers enable row level security;

create policy survey_questions_select_public on survey_questions
  for select to anon using (
    exists (select 1 from surveys sv where sv.id = survey_id and sv.status = 'Aktif')
  );
create policy survey_questions_admin_all on survey_questions
  for all to authenticated using (is_admin()) with check (is_admin());

create policy survey_question_options_select_public on survey_question_options
  for select to anon using (
    exists (
      select 1 from survey_questions q join surveys sv on sv.id = q.survey_id
      where q.id = question_id and sv.status = 'Aktif'
    )
  );
create policy survey_question_options_admin_all on survey_question_options
  for all to authenticated using (is_admin()) with check (is_admin());

create policy survey_answers_insert_public on survey_answers
  for insert to anon, authenticated
  with check (
    exists (select 1 from surveys sv where sv.id = survey_id and sv.status = 'Aktif')
  );
create policy survey_answers_select_admin on survey_answers
  for select to authenticated using (is_admin());

grant select, insert, update, delete on
  survey_questions, survey_question_options, survey_answers
  to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

-- ── submit_internal_survey RPC ───────────────────────────────────────────
-- Inserts the submission + its answers in one round trip. Plain (invoker-
-- rights) function, not security definer: RLS still applies as anon for both
-- inserts, exactly like calling the REST API directly would. The only reason
-- this exists as an RPC is so we get the new submission's id back (needed to
-- link the answer rows) without opening an anon SELECT policy on
-- submissions -- RETURNING * from an INSERT this function itself just did is
-- not subject to a SELECT policy the way a follow-up PostgREST select would be.
create or replace function submit_internal_survey(
  p_survey_id bigint,
  p_nama text,
  p_tanggal date,
  p_jenis_pegawai jenis_pegawai_enum,
  p_departemen text,
  p_answers jsonb
) returns submissions
language plpgsql as $$
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

grant execute on function submit_internal_survey(
  bigint, text, date, jenis_pegawai_enum, text, jsonb
) to anon, authenticated;

commit;
