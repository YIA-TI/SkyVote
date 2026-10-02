#!/usr/bin/env node
// Empties the `submissions` and `surveys` tables on the target Supabase
// project, plus every file in the survey-bukti storage bucket. Destructive
// — irreversible. `notifications` and every other table (departments,
// employees, workforce_totals, profiles) are left untouched.
//
// Needs the service_role key (RLS blocks anon/authenticated non-admin from
// deleting surveys/submissions, and this also needs to bypass storage RLS
// to remove every object regardless of admin session).

import { createClient } from "@supabase/supabase-js";
import * as readline from "readline/promises";

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

async function ask(question) {
  const answer = await rl.question(question);
  if (!answer) {
    console.error("❌ Wajib diisi");
    process.exit(1);
  }
  return answer;
}

async function listAllFiles(supabase, bucket, prefix = "") {
  const { data, error } = await supabase.storage.from(bucket).list(prefix, { limit: 1000 });
  if (error) throw error;

  const files = [];
  for (const entry of data) {
    const fullPath = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.id === null) {
      // folder — recurse
      files.push(...(await listAllFiles(supabase, bucket, fullPath)));
    } else {
      files.push(fullPath);
    }
  }
  return files;
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function main() {
  console.log("Kosongkan tabel surveys + submissions (dan file bukti terkait)\n");

  const url = await ask("Supabase Project URL: ");
  const serviceKey = await ask("Service Role Key: ");
  const confirm = await ask(
    '\n⚠️  Ini akan menghapus SEMUA baris di tabel "submissions" & "surveys", dan SEMUA file di bucket ' +
      '"survey-bukti", secara permanen. Ketik "HAPUS" untuk lanjut: '
  );
  rl.close();

  if (confirm !== "HAPUS") {
    console.log("Dibatalkan.");
    process.exit(0);
  }

  const supabase = createClient(url, serviceKey, { auth: { persistSession: false } });

  console.log("\n→ Menghapus file di bucket survey-bukti...");
  const files = await listAllFiles(supabase, "survey-bukti");
  let removed = 0;
  for (const batch of chunk(files, 100)) {
    const { error } = await supabase.storage.from("survey-bukti").remove(batch);
    if (error) throw error;
    removed += batch.length;
  }
  console.log(`  ✅ ${removed} file dihapus`);

  console.log("→ Mengosongkan tabel submissions...");
  const { error: subErr, count: subCount } = await supabase
    .from("submissions")
    .delete({ count: "exact" })
    .gte("id", 0);
  if (subErr) throw subErr;
  console.log(`  ✅ ${subCount ?? 0} baris dihapus`);

  console.log("→ Mengosongkan tabel surveys...");
  const { error: survErr, count: survCount } = await supabase
    .from("surveys")
    .delete({ count: "exact" })
    .gte("id", 0);
  if (survErr) throw survErr;
  console.log(`  ✅ ${survCount ?? 0} baris dihapus`);

  console.log("\n✅ Selesai. Tabel departments/employees/workforce_totals/notifications/profiles tidak diubah.");
}

main().catch((err) => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
