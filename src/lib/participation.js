// Participation numbers (Jumlah / Target / Voting / Gap / Persentase) in one
// place, shared by the report, the dashboard and the per-employee views.
//
// Three kinds of participant:
//   - Organik and TAD (Non-Organik): bound by the survey's per-day limit, so
//     their target is `limit` votes per person per day.
//   - Stakeholder: no maximum, but a minimum of STAKEHOLDER_MIN_VOTES per day.
//     Their target is that minimum, and at most that many votes per person per
//     day are COUNTED (0 votes -> 0%, 1 -> 50%, 2 or more -> 100%). Because
//     counted votes are capped, votes / target gives that percentage directly,
//     and extra stakeholder votes cannot hide a shortfall elsewhere in the
//     totals. (The database applies the same cap in public_report_counts.)

export const STAKEHOLDER_JENIS = "Stakeholder";
export const STAKEHOLDER_MIN_VOTES = 2;

export const isStakeholder = (participant) => participant?.jenisPegawai === STAKEHOLDER_JENIS;

// Keeps at most STAKEHOLDER_MIN_VOTES submissions per stakeholder per day;
// everyone else's submissions pass through untouched. Needs `nama` on each
// submission, so it is for full submission rows (not already-capped aggregates).
export function capStakeholderVotes(submissions) {
  const perPersonDay = new Map();
  return submissions.filter((submission) => {
    if (!isStakeholder(submission)) return true;
    const key = `${submission.nama}|${submission.tanggal}`;
    const count = (perPersonDay.get(key) ?? 0) + 1;
    perPersonDay.set(key, count);
    return count <= STAKEHOLDER_MIN_VOTES;
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
    targetStakeholder: pegawai.stakeholder * STAKEHOLDER_MIN_VOTES,
    pengisianOrganik: pengisian.organik,
    pengisianNonOrganik: pengisian.nonOrganik,
    pengisianStakeholder: pengisian.stakeholder,
  });
}

// The total line of a table made of rows. `pegawaiMode` is "sum" when the rows
// are different groups of people (divisions), and "first" when every row covers
// the same people on a different day (the per-Tanggal table), so the headcount
// is taken once while targets and votes add up across the rows.
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
