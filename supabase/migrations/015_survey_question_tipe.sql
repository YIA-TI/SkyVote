-- Survey Central -- per-question answer mode for Internal surveys: a
-- question can be "Pilihan" (multiple choice, radio -- what 014 already
-- supported) or "Lisan" (free-text answer, no options). Mode is chosen per
-- question, so one survey can mix both.

begin;

create type survey_question_tipe as enum ('Pilihan', 'Lisan');
alter table survey_questions add column tipe survey_question_tipe not null default 'Pilihan';

commit;
