# Quiz Rush

Aplikasi Flutter untuk **platform kuis kelas daring** lengkap dengan autentikasi NIM, manajemen kuis dan room, serta halaman **Peringkat Wilayah** dan **Profile** pengguna.

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
- **Ruang tunggu live** — setelah PIN terverifikasi, ruang tunggu menampilkan hero berisi judul kuis, jumlah soal, total poin, dan GAME PIN (ketuk untuk menyalin), kartu ringkasan room (jumlah peserta, status room, kondisi koneksi), grid peserta, serta sorakan real-time. Host mem-*publish* room lalu memulai kuis; seluruh peserta berpindah otomatis ke layar permainan saat soal pertama dikirim lewat WebSocket.
- **Tester kuis offline** — `QuizTestPage` menjalankan satu soal per layar dengan timer dial, penomoran waktu, dan penilaian skor tanpa menyentuh server.

### Peringkat Wilayah
Halaman peringkat user berdasarkan wilayah: podium tiga besar, daftar peringkat, dan baris posisi user sendiri — semuanya dari grup `kecamatan`/`kota`/`provinsi` respons `GET /api/location`. Koordinat diambil lewat `geolocator`, hasil terakhir di-cache di `SharedPreferences`, dan baris "Kamu" ditandai lewat perbandingan `username` dengan sesi berjalan. Menampilkan atribusi "© OpenStreetMap contributors".

### Profile
Halaman profil pengguna yang menampilkan nama, username, kelas, dan tanggal lahir, serta tombol **Logout** untuk mengakhiri sesi.

---

## Alur Pengguna

1. **Masuk** → `LoginPage` (atau langsung ke `MainShell` bila token tersimpan masih valid).
2. **Temukan kuis** → tab **Quiz** → cari judul atau ketik 6-digit PIN → lihat detail & kode room.
3. **Buat kuis** → FAB **Create Quiz** di Home → isi form → buat room → bagikan kode 6 digit.
4. **Jalankan** → detail room → `Publish` → `Mulai Game` → `Akhiri`.
5. **Akun** → tab **Peringkat** untuk peringkat wilayah (lokasi dari GPS), tab **Profile** untuk melihat profil dan logout.

Navigasi memakai `MainShell` (`lib/pages/button.dart`) dengan 4 tab: **Home · Quiz · Peringkat · Profile**.

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
├── engine/      KalkulatorEngine — pohon Expr + hitung() & hitungSkorWaktu
├── helpers/     Logika murni Dart: json, format, validators, pin, room_status_flow, quiz_play_session, quiz_image, room_launcher, room_roster, region_label
├── models/      User, Quizes, Room, RoomMessage, RoomVerify + serialisasi JSON
├── pages/       4 tab shell + auth
│   ├── MyQuizPage/   Sisi host: kuis saya, room, detail room, sheet buat room, buat kuis, tester
│   └── QuizPage/     Sisi peserta: jelajahi kuis, detail kuis
├── services/    Lapisan data: REST client, auth, kuis, room, sesi, cache
├── theme/       Design token (modul terpisah) + barrel app_theme.dart, palet status, palet opsi jawaban
└── widgets/     55 widget presentational tanpa logika halaman
```

Pola yang dipakai:

- **Service singleton** — konstruktor privat + `static final … instance`.
- **Cache-first** — `QuizFeed` membaca `shared_preferences` dulu; jaringan hanya saat tombol refresh atau setelah mutasi. Cache feed publik menyimpan ringkasan (`host`, `total_questions`, `total_duration`, `total_skor`, tanpa soal mentah/PIN), sedangkan `my-quizzes` tetap menyimpan `questions[]` mentah.
- **In-memory index** — `QuizIndex` membangun peta `byId` / `byGroup` / `byKode` / `lowerTitles` agar pencarian & filter tidak menyentuh disk atau jaringan.
- **Sesi & cache per-NIM** — kunci `auth_token`, `auth_user`, `cache_all-<NIM>`, `cache_mine-<NIM>`. `clear()` menghapus seluruh awalan `cache_`.
- **Migrasi format** — cache versi lama (list datar) otomatis dimMigrasikan ke format terelompok saat dibaca.

---

## Design System

Token design terbagi ke modul-modul di **`lib/theme/`** (`app_colors.dart`, `app_spacing.dart`, `app_metrics.dart`, `app_typography.dart`, `app_shadows.dart`, `app_gradients.dart`, `app_decorations.dart`, `app_buttons.dart`, `app_theme_data.dart`) dan dire-export oleh barrel **`lib/theme/app_theme.dart`**. Aturan repo: **warna, font, spacing, radius, dan shadow tidak boleh di-hardcode di file lain.**

| Kelas | Cakupan |
|---|---|
| `AppColors` | Brand, surface, teks, status, divider + palet 4 warna jawaban + palet halaman menunggu |
| `AppSpacing` | Skala numerik `space1`…`space16`, clearances, alias semantik `xxs`…`xxl` |
| `AppRadius` | `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`, `pill 999` |
| `AppShadows` | 14 preset `List<BoxShadow>` (card, raised, hairline, layered, pillButton, brandGlow, softCard, …) |
| `AppElevation` | `none`, `subtle`, `medium`, `raised` |
| `AppSizes` | Ukuran komponen tetap (tombol kembali, avatar, slot kosong, titik status) |
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
| `QuizService` | `GET /api/quizzes` · `GET /api/my-quizzes` · `POST /api/create/signature` · unggah langsung ke Cloudinary · `POST /api/create/quiz` |
| `RoomService` | `POST /api/create/room` · `PUT /api/room/{id}/status` |
| `LocationService` | `GET /api/location` (grouped leaderboard wilayah dari koordinat GPS, API.md §12) |

Semua request selain login/register mengirim `Authorization: Bearer <token>`; token berlaku 24 jam. `ApiException` dengan `statusCode == 401` diubah menjadi `needsAuth: true` yang memicu `LoginRedirect.go` ke halaman login.

Gambar kuis **diunggah otomatis begitu dipilih**: aplikasi meminta signature ke `POST /api/create/signature`, mengunggah langsung ke Cloudinary sebagai aset `authenticated` (overlay progres 2 tahap tampil di atas gambar), lalu `POST /api/create/quiz` mengirim `image_id` (`public_id`) dan `image_format` hasilnya. Server menyimpan aset dan mengembalikan **signed URL** (field `path`) saat kuis dibaca, sehingga gambar hanya dapat diakses user yang login. Unggahan berjalan di latar belakang — tombol Simpan nonaktif sampai selesai, dan gagal unggah menampilkan tombol "Coba lagi" di atas gambar.

Rujukan endpoint lengkap tersedia di **`API.md`**. Penjelasan alur token (asal, validasi, dan efek tiap token per endpoint) ada di **`docs/token_flow.md`**.

---

## Dependensi

| Package | Versi | Kegunaan |
|---|---|---|
| `http` | `^1.2.0` | Panggilan REST ke Deera Server |
| `shared_preferences` | `^2.3.0` | Penyimpanan sesi auth + cache kuis per-NIM |
| `google_fonts` | `^8.2.1` | Memuat font Montserrat & Plus Jakarta Sans saat runtime |
| `geolocator` | `^14.0.2` | Mengambil koordinat GPS untuk kartu lokasi wilayah |

Dev: `flutter_test`, `flutter_lints ^6.0.0`, `flutter_launcher_icons ^0.13.1`.

---

## Pengujian

```bash
flutter test
```

| Berkas | Cakupan |
|---|---|
| `test/widget_test.dart` | Smoke test aplikasi: halaman login tampil, validasi field kosong |
| `test/widgets_test.dart` | Widget bersama presentational (tombol, badge, kartu kuis/room, dsb.) + unit `QuizPlaySession` |
| `test/pages_test.dart` | Halaman `RankingRegionPage` (kartu lokasi + daftar peringkat) dan `ProfilePage` (data user + tombol logout) |
| `test/quiz_cache_test.dart` | `QuizCacheService` (scoping per-NIM & migrasi format lama) + `QuizIndex` (grouping, cari PIN, pencarian judul) |
| `test/room_model_test.dart` | `Room.displayTitle` (urutan judul: room → kuis → default) |
| `test/active_room_service_test.dart` | `ActiveRoomService` (set/clear + kontrak `ChangeNotifier`) |
| `test/helpers_test.dart` | Helper murni: `json`, `pin`, `auth_validator`, `room_status_flow`, `quiz_image`, `quiz_form_validator`, `room_roster` |
| `test/format_test.dart` | `format` (durasi, kode, waktu relatif, tanggal lahir, `totalDuration`) |
| `test/region_label_test.dart` | `formatRegionLabel` (slug wilayah `GET /api/location` → label terbaca) |
| `test/quiz_waiting_test.dart` | Widget halaman menunggu (`QuizWaitingHero`, `QuizWaitingStats`, `QuizWaitingParticipant`, `QuizWaitingSlot`) |
| `test/engine_score_test.dart` | `KalkulatorEngine.hitungSkorWaktu` |
| `test/model_json_test.dart` | Serialisasi/deserialisasi model (`Quizes`, `Room`, `RoomMessage`, `User`, dll) |
| `test/service_test.dart` | Lapisan service lewat `MockClient` (`ApiClient`, auth, quiz, room) |

Total **201** test, semuanya lulus.

---

## Keterbatasan Saat Ini

Hal-hal yang **belum** berfungsi dan perlu diketahui:

- **Peringkat Wilayah bergantung pada izin lokasi.** Podium dan daftar berasal dari `GET /api/location` (lihat `API.md` §12). Tanpa izin lokasi atau bila grup wilayah kosong, halaman menampilkan pesan kosong; kartu lokasi memakai cache terakhir bila ada. Slug wilayah dari server (`kecamatan-pasteur`) dinormalisasi jadi label yang terbaca (`Pasteur`) oleh `lib/helpers/region_label.dart`.
- **Aturan minimal 5 pertanyaan sudah divalidasi di sisi klien.** `CreateQuizPage` memeriksa judul, deskripsi, gambar (wajib, maks 5 MB), minimal 5 pertanyaan, 4 opsi, jawaban benar terpilih, dan `skor` 1–50.
- **Belum ada mode gelap** dan belum ada halaman pengaturan/preferensi selain `ProfilePage`.
- **Base URL backend hardcoded** di `lib/services/api_client.dart` — belum configurable via environment.

---

## Lisensi

Belum ditentukan.