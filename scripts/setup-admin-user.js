#!/usr/bin/env node

import { createClient } from "@supabase/supabase-js";
import * as readline from "readline/promises";

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

async function main() {
  console.log("Setup Admin User untuk Survey Central\n");

  const supabaseUrl = await rl.question(
    "Masukkan Supabase Project URL (https://...supabase.co): "
  );
  const supabaseServiceKey = await rl.question(
    "Masukkan Service Role Key (dari Settings → API Keys → service_role): "
  );

  if (!supabaseUrl || !supabaseServiceKey) {
    console.error("❌ URL dan Service Role Key wajib diisi");
    process.exit(1);
  }

  const adminEmail = await rl.question("Email admin (default: admin@survey.local): ") || "admin@survey.local";
  const adminPassword = await rl.question("Password admin (default: AdminSurvey123!): ") || "AdminSurvey123!";
  const displayName = await rl.question("Nama display admin (default: Admin Demo): ") || "Admin Demo";

  rl.close();

  console.log("\n🔄 Membuat akun admin...\n");

  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const { data: user, error: createError } = await supabase.auth.admin.createUser({
      email: adminEmail,
      password: adminPassword,
      email_confirm: true,
    });

    if (createError) {
      console.error("❌ Gagal membuat user auth:", createError.message);
      process.exit(1);
    }

    console.log(`✅ User auth berhasil dibuat (ID: ${user.user.id})`);

    const { error: insertError } = await supabase
      .from("profiles")
      .insert({
        id: user.user.id,
        role: "admin",
        display_name: displayName,
      });

    if (insertError) {
      console.error("❌ Gagal membuat profile admin:", insertError.message);
      process.exit(1);
    }

    console.log(`✅ Profile admin berhasil dibuat\n`);
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("✅ Admin user berhasil dibuat!");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log(`Email:    ${adminEmail}`);
    console.log(`Password: ${adminPassword}`);
    console.log(`Nama:     ${displayName}`);
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    console.log("Silakan login ke /admin/login dengan kredensial di atas.");
  } catch (err) {
    console.error("❌ Error:", err.message);
    process.exit(1);
  }
}

main();
