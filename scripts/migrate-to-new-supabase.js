#!/usr/bin/env node
// Migrates data + storage files from the current Supabase project to a new
// one. Run the SQL files in supabase/migrations/ (001 through 010, in
// order) on the NEW project's SQL Editor FIRST — this script only moves
// rows and files, it does not create tables/policies/buckets.
//
// Requires the service_role key for both projects (bypasses RLS so the
// full dataset is read/written, not just what the anon role can see).

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

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function main() {
  console.log("Migrasi data Survey Central ke project Supabase baru\n");

  const oldUrl = await ask("Supabase URL project LAMA: ");
  const oldKey = await ask("Service Role Key project LAMA: ");
  const newUrl = await ask("Supabase URL project BARU: ");
  const newKey = await ask("Service Role Key project BARU: ");
  rl.close();

  const oldDb = createClient(oldUrl, oldKey, { auth: { persistSession: false } });
  const newDb = createClient(newUrl, newKey, { auth: { persistSession: false } });

  // Sanity check: the new project must already have the schema (run
  // supabase/migrations/001..010 first) or every insert below will fail.
  const { error: schemaCheck } = await newDb.from("departments").select("id").limit(1);
  if (schemaCheck) {
    console.error(
      "❌ Tabel 'departments' tidak ditemukan di project baru. Jalankan dulu semua file di " +
        "supabase/migrations/ (001 s/d 010, berurutan) lewat SQL Editor project baru, lalu ulangi script ini."
    );
    process.exit(1);
  }

  // ── departments ──────────────────────────────────────────────────────
  console.log("\n→ departments");
  const { data: departments, error: depErr } = await oldDb.from("departments").select("*");
  if (depErr) throw depErr;
  for (const batch of chunk(departments, 500)) {
    const { error } = await newDb.from("departments").insert(batch);
    if (error) throw error;
  }
  console.log(`  ✅ ${departments.length} baris`);

  // ── employees ────────────────────────────────────────────────────────
  console.log("→ employees");
  const { data: employees, error: empErr } = await oldDb.from("employees").select("*");
  if (empErr) throw empErr;
  for (const batch of chunk(employees, 500)) {
    const { error } = await newDb.from("employees").insert(batch);
    if (error) throw error;
  }
  console.log(`  ✅ ${employees.length} baris`);

  // ── workforce_totals ─────────────────────────────────────────────────
  console.log("→ workforce_totals");
  const { data: totals, error: totalsErr } = await oldDb.from("workforce_totals").select("*");
  if (totalsErr) throw totalsErr;
  if (totals.length) {
    const { error } = await newDb.from("workforce_totals").insert(totals);
    if (error) throw error;
  }
  console.log(`  ✅ ${totals.length} baris`);

  // ── surveys (capture old id → new id map; id is an identity column so
  //    the new project assigns fresh ids) ────────────────────────────────
  console.log("→ surveys");
  const { data: surveys, error: survErr } = await oldDb
    .from("surveys")
    .select("*")
    .order("id", { ascending: true });
  if (survErr) throw survErr;

  const surveyIdMap = new Map();
  for (const survey of surveys) {
    const { id: oldId, ...rest } = survey;
    const { data: inserted, error } = await newDb.from("surveys").insert(rest).select("id").single();
    if (error) throw error;
    surveyIdMap.set(oldId, inserted.id);
  }
  console.log(`  ✅ ${surveys.length} baris`);

  // ── submissions (remap survey_id via the map above) ─────────────────
  console.log("→ submissions");
  const { data: submissions, error: subErr } = await oldDb.from("submissions").select("*");
  if (subErr) throw subErr;
  const remappedSubmissions = submissions.map(({ id, survey_id, ...rest }) => ({
    ...rest,
    survey_id: surveyIdMap.get(survey_id),
  }));
  for (const batch of chunk(remappedSubmissions, 500)) {
    const { error } = await newDb.from("submissions").insert(batch);
    if (error) throw error;
  }
  console.log(`  ✅ ${submissions.length} baris`);

  // ── notifications ────────────────────────────────────────────────────
  console.log("→ notifications");
  const { data: notifications, error: notifErr } = await oldDb.from("notifications").select("*");
  if (notifErr) throw notifErr;
  for (const batch of chunk(notifications, 500)) {
    const { error } = await newDb.from("notifications").insert(batch);
    if (error) throw error;
  }
  console.log(`  ✅ ${notifications.length} baris`);

  // ── storage: copy every uploaded bukti file, path-for-path ───────────
  console.log("→ storage (survey-bukti)");
  const filePaths = submissions.map((s) => s.file_bukti).filter(Boolean);
  let copied = 0;
  for (const path of filePaths) {
    const { data: file, error: downloadErr } = await oldDb.storage.from("survey-bukti").download(path);
    if (downloadErr) {
      console.warn(`  ⚠️  gagal download ${path}: ${downloadErr.message}`);
      continue;
    }
    const { error: uploadErr } = await newDb.storage
      .from("survey-bukti")
      .upload(path, file, { upsert: true, contentType: file.type });
    if (uploadErr) {
      console.warn(`  ⚠️  gagal upload ${path}: ${uploadErr.message}`);
      continue;
    }
    copied += 1;
  }
  console.log(`  ✅ ${copied}/${filePaths.length} file`);

  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("✅ Migrasi data selesai.");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Langkah selanjutnya:");
  console.log("1. Jalankan `node scripts/setup-admin-user.js` untuk project BARU (akun admin/profiles tidak ikut termigrasi).");
  console.log("2. Update VITE_SUPABASE_URL & VITE_SUPABASE_ANON_KEY di .env ke project baru.");
}

main().catch((err) => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
