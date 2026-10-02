-- Survey Central -- adds a third per-question answer mode: "PilihanMulti"
-- (checkbox, pick multiple options) alongside the existing "Pilihan"
-- (radio, pick one) and "Lisan" (free text) from 015.

begin;

alter type survey_question_tipe add value 'PilihanMulti';

commit;
