-- Survey Central -- Description for internal surveys (details of the survey activity).

begin;

alter table surveys add column deskripsi text not null default '';

commit;
