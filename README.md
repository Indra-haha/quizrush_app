# Quiz Rush

Aplikasi Flutter yang menggabungkan **(1)** platform kuis kelas daring lengkap dengan autentikasi NIM serta manajemen kuis dan room, dan **(2)** konversi kalender (Hijriah, Umur, Weton, Saka Bali).

> Nama paket: `quizrush` · Root widget: `QuizApp` · Judul aplikasi: `Aplikasi Quiz` · Android label: `Quiz Rush`

![Screenshot](lib/assets/demo.jpeg)

---

## Daftar Isi

- [Fitur](#fitur)
- [Alur Pengguna](#alur-pengguna)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Arsitektur](#arsitektur)
- [Design System](#design-system)
- [Backend](#backend)
- [Pengujian](#pengujian)
- [Keterbatasan Saat Ini](#keterbatasan-saat-ini)

---

## Fitur

### Autentikasi
- **Login** dengan NIM + password, tanpa OTP.
- **Registrasi** (nama lengkap, NIM, kelas, tanggal lahir, konfirmasi password).
- **Restore sesi otomatis** — token yang tersimpan divalidasi lewat `GET /api/session`; jika masih valid pengguna langsung masuk ke aplikasi.

### Kuis
- **Berbrowse & mencari kuis** — dikelompokkan berdasarkan status (`open`, `in-Game`, `ended`), dengan pencarian judul.
- **Cari room via PIN** — kolom pencarian mendeteksi 6 digit angka dan langsung menuju room tersebut.
- **Buat kuis** — gambar kuis (jpg/png/webp, maks 5 MB), judul, deskripsi, minimal 5 pertanyaan × 4 pilihan jawaban, toggle jawaban benar, durasi per soal (1,5 / 2 / 3 / 5 detik), dan poin (1–50).
- **Buat room** — pilih kuis berstatus `quarantine`, isi judul & deskripsi room, dapatkan **kode room 6 digit** yang bisa disalin.
- **Alur status room** — `waiting → open → in-Game → ended`, diendorse lewat tombol aksi pada detail room.
- **Tester kuis offline** — `QuizTestPage` menjalankan satu soal per layar dengan timer dial, penomoran waktu, dan penilaian skor tanpa menyentuh server.

### Konversi Kalender
Empat tab konversi dari tanggal Mase:

| Tab | Hasil |
|---|---|
| Hijriah | Tanggal Hijriah |
| Umur | Tahun, bulan, hari, jam, menit, detik |
| Weton | Weton Jawa |
| Saka Bali | Angka Tahun Saka Bali |

Seluruh perhitungan berjalan **lokal** di `CalendarUtils` — tanpa jaringan.

### Bantuan
Halaman panduan statis yang menjelaskan login, home, kuis, pembuatan kuis, konversi, dan logout.

---

## Alur Pengguna

1. **Masuk** → `LoginPage` (atau langsung ke `MainShell` bila token tersimpan masih valid).
2. **Temukan kuis** → tab **Quiz** → cari judul atau ketik 6-digit PIN → lihat detail & kode room.
3. **Buat kuis** → FAB **Create Quiz** di Home → isi form → buat room → bagikan kode 6 digit.
4. **Jalankan** → detail room → `Publish` → `Mulai Game` → `Akhiri`.
5. **Alat** → tab **Konversi** untuk kalender, tab **Bantuan** untuk panduan, logout untuk mengakhiri sesi.

Navigasi memakai `MainShell` (`lib/pages/button.dart`) dengan 4 tab: **Home · Quiz · Konversi · Bantuan**.

---

## Menjalankan Aplikasi

```bash
# 1. Ambil dependensi
flutter pub get

# 2. Jalankan di perangkat / emulator
flutter run

# 3. Lcek kondisi kode
flutter analyze

# 4. Jalankan pengujian
flutter test
```

Kebutuhan: **Flutter 3.44+** · **Dart SDK ^3.12.2**

Base URL backend ditetapkan di `lib/services/api_client.dart`:

```dart
static const String baseUrl = 'https://deera-server.my.id';
```

Untuk.device/ emulator, ganti dengan host yang dapat dijangkau (mis. `10.0.2.2` untuk Android emulator atau IP LAN untuk perangkat fisik). Nilai ini **hardcoded** — belum memakai `.env` maupun `--dart-define`.

---

## Arsitektur

```
lib/
├── engine/      KalkulatorEngine — parser rekursif-desent (+ - × ÷) & hitungSkorWaktu
├── helpers/     QuizPlaySession — logika permainan murni Dart (timer, skor, callback)
├── models/      User, Quizes, Room, Result + serialisasi JSON
├── pages/       4 tab shell + auth
│   ├── MyQuizPage/   Sisi host: kuis saya, room, detail room, sheet buat room, buat kuis, tester
│   └── QuizPage/     Sisi peserta: jelajahi kuis, detail kuis
├── services/    Lapisan data: REST client, auth, kuis, room, hasil, sesi, cache
├── theme/       Design token + AppTheme.light, palet status, palet opsi jawaban
├── utils/       format.dart (durasi, kode, waktu relatif) + konversi_format.dart (CalendarUtils)
└── widgets/     31 widget presentational tanpa logika halaman
```

Pola yang dipakai:

- **Service singleton** — konstruktor privat + `static final … instance`.
- **Cache-first** — `QuizFeed` membaca `shared_preferences` dulu; jaringan hanya saat tombol refresh atau setelah mutasi.
- **In-memory index** — `QuizIndex` membangun peta `byId` / `byGroup` / `byKode` / `lowerTitles` agar pencarian & filter tidak menyentuh disk atau jaringan.
- **Sesi & cache per-NIM** — kunci `auth_token`, `auth_user`, `cache_all-<NIM>`, `cache_mine-<NIM>`. `clear()` menghapus seluruh awalan `cache_`.
- **Migrasi format** — cache versi lama (list datar) otomatis dimMigrasikan ke format terelompok saat dibaca.

---

## Design System

Semua token design berada di **`lib/theme/app_theme.dart`**. Aturan repo: **warna, font, spacing, radius, dan shadow tidak boleh di-hardcode di file lain.**

| Kelas | Cakupan |
|---|---|
| `AppColors` | Brand, surface, teks, status, divider + palet 4 warna jawaban |
| `AppSpacing` | Skala numerik `space1`…`space16`, clearances, alias semantik `xxs`…`xxl` |
| `AppPadding` | ~25 preset `EdgeInsets` siap pakai (page, card, badge, chip, screen, scroll) |
| `AppRadius` | `sm 8`, `md 12`, `lg 16`, `xl 24`, `pill 999` |
| `AppShadows` | 12 preset `List<BoxShadow>` (card, raised, hairline, layered, pillButton, brandGlow, …) |
| `AppElevation` | `none`, `subtle`, `medium`, `raised` |
| `AppTextStyles` | sekitar 45 style siap pakai |
| `AppFontSize` · `AppFontWeight` | Skala ukuran & bobot font untuk API widget |
| `AppIconSize` · `AppBorderWidth` | Ukuran glyph ikon & ketebalan border |
| `AppDecorations` | `BoxDecoration` siap pakai (card, statTile, pill, input, …) |
| `AppGradients` | `heroGradient`, `solidHero` |
| `AppButtons` | `ButtonStyle`: `primary`, `primaryLarge`, `primaryCompact`, `outline`, `text`, `destructive` |
| `AppStatus` | `danger`, `onLightAlpha` |
| `AppTheme` | Satu-satunya tempat `ThemeData` dibangun (`AppTheme.light`) |

**Font:** Montserrat (heading, display, angka statistik, display kalkulator) dan Plus Jakarta Sans (body, label, button, hint) lewat `google_fonts`; `monospace` untuk kode room.

**Mode:** **Light only.** `AppTheme` hanya mengekspos satu getter, `light`; `main.dart` tidak menyetel `darkTheme` maupun `themeMode`.

Dua berkas tema pendamping menjaga agar satu status/opsi tidak pernah punya dua warna:

- `lib/theme/quiz_status.dart` — daftar status + `labelOf()` + `palette()`.
- `lib/theme/quiz_option_theme.dart` — 4 tema opsi jawaban (merah/biru/kuning/hijau).

---

## Backend

REST (bukan Supabase/Firebase) memakai `package:http`, dengan JSON dua arah dan timeout 10 detik per request.

| Service | Endpoint |
|---|---|
| `AuthService` | `POST /api/login` · `POST /api/register` · `POST /api/logout` · `GET /api/session` |
| `QuizService` | `GET /api/quizzes` · `GET /api/my-quizzes` · `POST /api/create/quiz` |
| `RoomService` | `POST /api/create/room` · `PUT /api/room/{id}/status` |
| `ResultService` | `POST/GET/PUT /api/room/{kode}/result` · `GET /api/results` *(didefinisikan, belum dipakai UI)* |

Semua request selain login/register mengirim `Authorization: Bearer <token>`; token berlaku 24 jam. `ApiException` dengan `statusCode == 401` diubah menjadi `needsAuth: true` yang memicu `LoginRedirect.go` ke halaman login.

Rujukan endpoint lengkap tersedia di **`API.md`**.

---

## Dependensi

| Package | Versi | Kegunaan |
|---|---|---|
| `http` | `^1.2.0` | Panggilan REST ke Deera Server |
| `shared_preferences` | `^2.3.0` | Penyimpanan sesi auth + cache kuis per-NIM |
| `google_fonts` | `^8.2.1` | Memuat font Montserrat & Plus Jakarta Sans saat runtime |

Dev: `flutter_test`, `flutter_lints ^6.0.0`, `flutter_launcher_icons ^0.13.1`.

---

## Pengujian

```bash
flutter test
```

| Berkas | Cakupan |
|---|---|
| `test/widget_test.dart` | Smoke test aplikasi: halaman login tampil, validasi field kosong |
| `test/widgets_test.dart` | Widget bersama (`AppPill`, `StatusFilterRow`, `CacheInfoBar`, `AppPrimaryButton`, `EmptyStateView`, `AppStatTile`, `QuizCountdownDial`, `QuizAnswerBanner`, `QuizStatus.palette`) + 7 unit test `QuizPlaySession` |
| `test/quiz_cache_test.dart` | 8 test `QuizCacheService` (termasuk scoping per-NIM & migrasi format lama) + 8 test `QuizIndex` (grouping, cari PIN, pencarian judul) |
| `test/room_model_test.dart` | 3 test `Room.displayTitle` (urun judul: room → kuis → default) |
| `test/active_room_service_test.dart` | 4 test `ActiveRoomService` (set/clear + kontrak `ChangeNotifier`) |

---

## Keterbatasan Saat Ini

Hal-hal yang **belum** berfungsi dan perlu diketahui:

- **Join room belum diimplementasikan.** Tombol "Masuk" pada detail kuis hanya menampilkan snackbar `fitur join menyusul`.
- **`ResultService` belum dipakai.** Model `Result`/`ResultEntry` dan endpoint skor sudah ada, tetapi belum ada layar atau alur pengiriman skor.
- **Aturan minimal 5 pertanyaan sudah divalidasi di sisi klien.** `CreateQuizPage` memeriksa judul, deskripsi, gambar (wajib, maks 5 MB), minimal 5 pertanyaan, 4 opsi, jawaban benar terpilih, dan `skor` 1–50.
- **Belum ada mode gelap** dan belum ada halaman pengaturan/preferensi selain `HelpPage`.
- **Base URL backend hardcoded** di `lib/services/api_client.dart` — belum configurable via environment.

---

## Lisensi

Belum ditentukan.