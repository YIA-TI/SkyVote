// Participation numbers (Jumlah / Target / Voting / Gap / Persentase) in one
// place, shared by the report, the dashboard and the per-employee views.
//
// Three kinds of participant:
//   - Organik and TAD (Non-Organik): bound by the survey's per-day limit, so
//     their target is `limit` votes per person per day.
//   - Stakeholder ("buzzer"): a fixed target of STAKEHOLDER_DAILY_TARGET votes
//     per person per day, which is also their daily maximum (the database
//     refuses a 101st submission in a day). The percentage is plain
//     votes / target. A stakeholder only counts inside its own date window
//     (see employeesOn), so neither adding one nor switching one off changes
//     the figures of days outside that window.

export const STAKEHOLDER_JENIS = "Stakeholder";

// Votes expected from one stakeholder per day. Keep it equal to the safety
// ceiling c_stakeholder_daily_ceiling in the database (migration 032), and to
// the cap in public_report_counts (migration 033).
export const STAKEHOLDER_DAILY_TARGET = 100;

export const isStakeholder = (participant) => participant?.jenisPegawai === STAKEHOLDER_JENIS;

// Keeps at most STAKEHOLDER_DAILY_TARGET submissions per stakeholder per day;
// everyone else's submissions pass through untouched. The database already
// refuses more than that, so this only matters if the ceiling is ever raised.
// Needs `nama` on each submission, so it is for full submission rows (not
// already-capped aggregates).
export function capStakeholderVotes(submissions) {
  const perPersonDay = new Map();
  return submissions.filter((submission) => {
    if (!isStakeholder(submission)) return true;
    const key = `${submission.nama}|${submission.tanggal}`;
    const count = (perPersonDay.get(key) ?? 0) + 1;
    perPersonDay.set(key, count);
    return count <= STAKEHOLDER_DAILY_TARGET;
  });
}

// Who the reports draw their headcount from: active Organik / TAD, and EVERY
// stakeholder, active or not. A stakeholder's own date window (employeesOn)
// decides on which days they count, so switching an account off afterwards does
// not erase the days it was needed.
export const isCountedEmployee = (employee) => isStakeholder(employee) || !!employee.isActive;

// The participants who count on a given day (YYYY-MM-DD). Organik and TAD always
// do (the caller has already kept only the active ones); a stakeholder counts
// only inside its window: from `targetMulai` (the day it was registered, unless
// set otherwise) to `targetSelesai` (empty = no end yet).
// Without a day (internal surveys have none) stakeholders are left out: they
// take part in external surveys only.
export function employeesOn(employees, tanggal) {
  if (!tanggal) return employees.filter((employee) => !isStakeholder(employee));
  return employees.filter((employee) => {
    if (!isStakeholder(employee)) return true;
    if (employee.targetMulai && tanggal < employee.targetMulai) return false;
    if (employee.targetSelesai && tanggal > employee.targetSelesai) return false;
    return true;
  });
}

// { organik, nonOrganik, stakeholder } counts of a list of employees or
// submissions (anything with `jenisPegawai`). Unknown values count as TAD,
// which is what the code did before stakeholders existed.
export function countByJenis(list) {
  const counts = { organik: 0, nonOrganik: 0, stakeholder: 0 };
  for (const item of list) {
    if (item.jenisPegawai === "Organik") counts.organik++;
    else if (item.jenisPegawai === STAKEHOLDER_JENIS) counts.stakeholder++;
    else counts.nonOrganik++;
  }
  return counts;
}

const percent = (value, total) => (total > 0 ? Math.round((value / total) * 1000) / 10 : 0);

// Fills in the totals, gaps (voting - target) and percentages from the six base
// numbers. Totals include every participant, stakeholders too.
function finalize(key, base) {
  const pegawaiTotal = base.pegawaiOrganik + base.pegawaiNonOrganik + base.pegawaiStakeholder;
  const targetTotal = base.targetOrganik + base.targetNonOrganik + base.targetStakeholder;
  const pengisianTotal =
    base.pengisianOrganik + base.pengisianNonOrganik + base.pengisianStakeholder;

  return {
    key,
    ...base,
    pegawaiTotal,
    targetTotal,
    pengisianTotal,
    gapOrganik: base.pengisianOrganik - base.targetOrganik,
    gapNonOrganik: base.pengisianNonOrganik - base.targetNonOrganik,
    gapStakeholder: base.pengisianStakeholder - base.targetStakeholder,
    gapTotal: pengisianTotal - targetTotal,
    persenOrganik: percent(base.pengisianOrganik, base.targetOrganik),
    persenNonOrganik: percent(base.pengisianNonOrganik, base.targetNonOrganik),
    persenStakeholder: percent(base.pengisianStakeholder, base.targetStakeholder),
    persenTotal: percent(pengisianTotal, targetTotal),
  };
}

// One report row. `pegawai` / `pengisian` are countByJenis results; `limit` is the
// survey's per-day limit per person (1 for internal surveys).
export function buildRow(key, pegawai, pengisian, limit) {
  return finalize(key, {
    pegawaiOrganik: pegawai.organik,
    pegawaiNonOrganik: pegawai.nonOrganik,
    pegawaiStakeholder: pegawai.stakeholder,
    targetOrganik: pegawai.organik * limit,
    targetNonOrganik: pegawai.nonOrganik * limit,
    targetStakeholder: pegawai.stakeholder * STAKEHOLDER_DAILY_TARGET,
    pengisianOrganik: pengisian.organik,
    pengisianNonOrganik: pengisian.nonOrganik,
    pengisianStakeholder: pengisian.stakeholder,
  });
}

// The total line of a table made of rows. `pegawaiMode` is "sum" when the rows
// are different groups of people (divisions), and "first" when every row covers
// the same people on a different day (the per-Tanggal table), so the headcount
// is taken once (from the first row, the most recent day) while targets and
// votes add up across the rows.
export function sumRows(rows, pegawaiMode = "sum") {
  const sum = (field) => rows.reduce((total, row) => total + row[field], 0);
  const headcount = (field) => (pegawaiMode === "first" ? rows[0]?.[field] ?? 0 : sum(field));

  return finalize("total", {
    pegawaiOrganik: headcount("pegawaiOrganik"),
    pegawaiNonOrganik: headcount("pegawaiNonOrganik"),
    pegawaiStakeholder: headcount("pegawaiStakeholder"),
    targetOrganik: sum("targetOrganik"),
    targetNonOrganik: sum("targetNonOrganik"),
    targetStakeholder: sum("targetStakeholder"),
    pengisianOrganik: sum("pengisianOrganik"),
    pengisianNonOrganik: sum("pengisianNonOrganik"),
    pengisianStakeholder: sum("pengisianStakeholder"),
  });
}
