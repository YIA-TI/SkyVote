// Page buttons for a pager, kept short however many pages there are:
//   1 … 4 5 [6] 7 8 … 636
// Returns numbers for pages and the strings "gap-left" / "gap-right" for the
// "…" separators (distinct, so each can be used as a v-for key). Rendering one
// button per page overflowed the card once a table had hundreds of pages.
const range = (from, to) => Array.from({ length: to - from + 1 }, (_, i) => from + i);

export function pageItems(current, total, siblings = 1) {
  // first + last + current±siblings + two gaps
  const maxSlots = siblings * 2 + 5;
  if (total <= maxSlots) return range(1, total);

  const left = Math.max(current - siblings, 1);
  const right = Math.min(current + siblings, total);
  // A gap that would hide just one page is not worth showing: treat it as
  // "near the edge" and list the pages instead.
  const gapLeft = left > 3;
  const gapRight = right < total - 2;

  // Near the start: show a longer run so the pager keeps a constant width.
  if (!gapLeft && gapRight) {
    return [...range(1, 3 + siblings * 2), "gap-right", total];
  }
  // Near the end.
  if (gapLeft && !gapRight) {
    return [1, "gap-left", ...range(total - (2 + siblings * 2), total)];
  }
  return [1, "gap-left", ...range(left, right), "gap-right", total];
}
