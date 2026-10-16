// Letter label for an answer option by position: 0 -> A, 1 -> B, ... 25 -> Z,
// then 26 -> AA, 27 -> AB (spreadsheet-column style) for the rare long list.
// Display-only: the saved answer is still the option's own text.
export function optionLabel(index) {
  let n = index;
  let label = "";
  do {
    label = String.fromCharCode(65 + (n % 26)) + label;
    n = Math.floor(n / 26) - 1;
  } while (n >= 0);
  return label;
}
