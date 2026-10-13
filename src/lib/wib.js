// Every date and time the app shows or sends is in WIB (Asia/Jakarta), the
// timezone the database uses for its period and quota checks — independent of
// the visitor's device timezone. (new Date().toISOString() would be UTC, and
// getHours() would be the device's own zone; neither is WIB.)

const WIB = "Asia/Jakarta";

// "h23" avoids the "24:00:00" some engines print at midnight with hour12:false.
const dateFormatter = new Intl.DateTimeFormat("en-CA", { timeZone: WIB });
const timeFormatter = new Intl.DateTimeFormat("en-GB", {
  timeZone: WIB,
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});
const dateTimeFormatter = new Intl.DateTimeFormat("id-ID", {
  timeZone: WIB,
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

// Today's date as YYYY-MM-DD in WIB. Also used for file-name date stamps.
export function wibToday() {
  return dateFormatter.format(new Date());
}

// "14:04:58" in WIB; empty string when there is no value.
export function formatWibTime(value) {
  return value ? timeFormatter.format(new Date(value)) : "";
}

// "13/10/2026 14.04.58 WIB" — for "Diekspor pada" lines.
export function formatWibDateTime(value = new Date()) {
  return `${dateTimeFormatter.format(new Date(value))} WIB`;
}
