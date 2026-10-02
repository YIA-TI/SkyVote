#!/usr/bin/env node
// Read-only sanity check: confirms the schema/RLS/RPC/storage markers left
// behind by supabase/migrations/001..010 are present on whatever project
// VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY (in .env) currently points to.
// Uses only the anon key, so a few checks that need an authenticated admin
// session are reported as "tidak bisa dicek" rather than pass/fail.

import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";

function loadEnv(path = ".env") {
  const out = {};
  for (const line of readFileSync(path, "utf8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    out[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
  }
  return out;
}

const env = loadEnv();
const url = env.VITE_SUPABASE_URL;
const anonKey = env.VITE_SUPABASE_ANON_KEY;

if (!url || !anonKey) {
  console.error("❌ VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY tidak ditemukan di .env");
  process.exit(1);
}

console.log(`Mengecek project: ${url}\n`);

const supabase = createClient(url, anonKey, { auth: { persistSession: false } });

const results = [];

async function check(label, migration, fn) {
  try {
    const detail = await fn();
    results.push({ label, migration, ok: true, detail });
  } catch (err) {
    results.push({ label, migration, ok: false, detail: err.message });
  }
}

async function main() {
  await check("Tabel departments + RLS read", "001 + 002", async () => {
    const { count, error } = await supabase.from("departments").select("*", { count: "exact", head: true });
    if (error) throw error;
    return `${count} baris`;
  });

  await check("Tabel employees + RLS read", "001 + 002", async () => {
    const { count, error } = await supabase.from("employees").select("*", { count: "exact", head: true });
    if (error) throw error;
    return `${count} baris`;
  });

  await check("Kolom employees.nip", "007", async () => {
    const { error } = await supabase.from("employees").select("nip").limit(1);
    if (error) throw error;
    return "kolom ada";
  });

  await check("Tabel workforce_totals + RLS read", "001 + 002", async () => {
    const { data, error } = await supabase.from("workforce_totals").select("*");
    if (error) throw error;
    return `${data.length} baris`;
  });

  await check("Tabel surveys + RLS anon (hanya status Aktif)", "001 + 002 + 009", async () => {
    const { count, error } = await supabase
      .from("surveys")
      .select("*", { count: "exact", head: true })
      .eq("status", "Aktif");
    if (error) throw error;
    return `${count} survey aktif terlihat oleh anon`;
  });

  await check("RPC employees_belum_survey()", "001", async () => {
    const { data, error } = await supabase.rpc("employees_belum_survey");
    if (error) throw error;
    return `callable, ${data.length} pegawai belum submit hari ini`;
  });

  await check("RPC is_admin()", "001", async () => {
    const { data, error } = await supabase.rpc("is_admin");
    if (error) throw error;
    return `callable (anon → ${data})`;
  });

  await check("RPC sync_survey_statuses()", "009", async () => {
    const { error } = await supabase.rpc("sync_survey_statuses");
    if (error) throw error;
    return "callable";
  });

  await check("Storage bucket survey-bukti ada", "002", async () => {
    const { error } = await supabase.storage.from("survey-bukti").list("", { limit: 1 });
    if (error) throw error;
    return "bucket ditemukan";
  });

  console.log("Hasil:\n");
  for (const r of results) {
    const icon = r.ok ? "✅" : "❌";
    console.log(`${icon} [migrasi ${r.migration}] ${r.label} — ${r.detail}`);
  }

  const failed = results.filter((r) => !r.ok);
  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  if (failed.length === 0) {
    console.log("✅ Semua pengecekan (anon-accessible) lolos.");
  } else {
    console.log(`❌ ${failed.length} pengecekan gagal — lihat detail di atas.`);
  }
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(
    "\nCatatan: script ini pakai anon key, jadi tidak bisa memverifikasi hal yang butuh login admin\n" +
      "(policy submissions_update_admin & storage delete admin dari migrasi 006), dan tidak bisa\n" +
      "membedakan persis migrasi 009 vs 010 (keduanya sama-sama meng-update fungsi yang sama) tanpa\n" +
      "insert data uji. Kalau semua di atas ✅, hampir pasti 001-009 sudah jalan; untuk 010 cek manual\n" +
      "di SQL Editor: `select prosrc from pg_proc where proname = 'enforce_submission_quota';` lalu cari\n" +
      "baris 'Tanggal yang dipilih di luar periode survey' di outputnya."
  );
}

main();
