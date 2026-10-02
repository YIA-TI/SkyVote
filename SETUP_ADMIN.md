# Setup Admin User untuk Survey Central

Ada 2 cara untuk membuat akun admin:

## Opsi 1: Menggunakan Script Node.js (Recommended) ⚡

Paling mudah dan otomatis:

```bash
node scripts/setup-admin-user.js
```

Script akan meminta:
- **Supabase Project URL** — dari Settings → API Keys (copy Project URL)
- **Service Role Key** — dari Settings → API Keys (copy service_role key)
- **Email admin** — default: `admin@survey.local`
- **Password admin** — default: `AdminSurvey123!`
- **Nama display** — default: `Admin Demo`

Setelah selesai, gunakan email & password untuk login di `/admin/login`.

---

## Opsi 2: Manual via Supabase Dashboard

Jika script tidak bisa dijalankan:

### Step 1: Buat user di Authentication
1. Buka Supabase Dashboard → **Authentication** → **Users**
2. Klik **"Add user"**
3. Isi:
   - **Email**: `admin@survey.local` (atau pilihan sendiri)
   - **Password**: `AdminSurvey123!` (atau pilihan sendiri)
4. Klik **"Create user"**
5. **Copy UUID** user yang baru dibuat (lihat di kolom "ID")

### Step 2: Buat profile admin di Database
1. Buka **SQL Editor**
2. Jalankan query ini (ganti `<UUID>` dengan UUID dari step 1):

```sql
insert into profiles (id, role, display_name) values
  ('<UUID-dari-step-1>', 'admin', 'Admin Demo');
```

Contoh (jika UUID-nya `550e8400-e29b-41d4-a716-446655440000`):
```sql
insert into profiles (id, role, display_name) values
  ('550e8400-e29b-41d4-a716-446655440000', 'admin', 'Admin Demo');
```

3. Klik **"Run"**

### Step 3: Login
- Buka aplikasi di `/admin/login`
- Gunakan email & password dari step 1

---

## Troubleshooting

**❌ "Akun ini tidak memiliki akses admin"**
- Berarti row di tabel `profiles` belum ada atau `role` bukan `'admin'`
- Pastikan sudah jalankan step 2 (insert ke profiles) dengan benar

**❌ "Service Role Key tidak valid"**
- Pastikan menggunakan **service_role key**, bukan **anon key**
- Service Role Key lebih panjang dan dimulai dengan `eyJ...`

**❌ Email sudah terdaftar**
- Gunakan email yang berbeda, atau hapus user lama di Authentication → Users

---

## Dummy Credentials (untuk testing lokal)

| Field | Nilai |
|-------|-------|
| Email | `admin@survey.local` |
| Password | `AdminSurvey123!` |
| Role | `admin` |

⚠️ Ganti dengan kredensial yang lebih aman untuk production!
