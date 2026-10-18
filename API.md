# Dokumentasi API — Deera Server

## 1. Info Umum

| Item | Nilai |
|---|---|
| Base URL | `http://localhost:8080` (ganti lewat env `PORT`) |
| Format data | JSON (`Content-Type: application/json`) |
| Header autentikasi | `Authorization: Bearer <token>` |
| Token login | Diperoleh dari `POST /api/login`, berlaku 24 jam |
| Token room | Diperoleh dari `POST /api/rooms/verify` (§5.4), berlaku 1 jam, hanya untuk WebSocket `GET /api/rooms` |
| Koleksi DB | `users`, `quizzes`, `rooms`, `results`, `tokens`, `emojis`, `coins` |
| Batas body | 1 MiB per request (`413` bila lebih) |
| Hashing password | SHA-256 (hex lowercase), dilakukan di sisi klien sebelum dikirim |
| Transport | HTTPS (produksi) melindungi password hash dan token |

Semua endpoint wajib menyertakan header `Authorization` **kecuali** `POST /api/register` dan `POST /api/login`. Endpoint WebSocket `GET /api/rooms?token=<JWT room>` (§9) mewajibkan header `Authorization` (token login) **dan** JWT ber-scope room pada query `token`.

Semua endpoint yang dilindungi `middleware.Auth` (dan `POST /api/login`) menerapkan **allowlist perangkat**: request wajib berasal dari smartphone, dicek dari header `User-Agent`. Request dari selain smartphone ditolak `401 { "message": "Akses hanya diizinkan dari perangkat smartphone" }`.

**Environment variables:**

| Env | Wajib | Default | Fungsi |
|---|---|---|---|
| `JWT_SECRET` | ✅ | — (tanpa fallback) | Secret penanda tangan JWT, minimal 32 karakter |
| `MONGO_URI` | ✗* | — | URI MongoDB; *atau isi `DB_HOST/DB_PORT/DB_USER/DB_PASS/DB_NAME/DB_AUTH_SOURCE` |
| `DB_NAME` | ✗ | `quizrush_app_db` | Nama database (hanya dipakai bila `MONGO_URI` tidak menentukan path) |
| `PORT` | ✗ | `8080` | Port HTTP saat `cert.pem` tidak ada |
| `SEED_ENABLED` | ✗ | `true` | `false` menonaktifkan semua seed data contoh |
| `ALLOWED_ORIGINS` | ✗ | origin se-host | Daftar origin yang diizinkan untuk handshake WebSocket (pisahkan koma) |
| `CLEANUP_ORPHAN_COLLECTIONS` | ✗ | `false` | `true` mengizinkan penghapusan koleksi orphan `anggota`/`anggotas` saat startup |
| `CLOUDINARY_URL` | ✗ | — | Kredensial Cloudinary (`cloudinary://<api_key>:<api_secret>@<cloud_name>`); alternatif: `CLOUDINARY_CLOUD_NAME` + `CLOUDINARY_API_KEY` + `CLOUDINARY_API_SECRET`. Kosong = client media tidak aktif (server tetap berjalan) |
| `AI_API_KEY` | ✗ | — | API key penyedia model AI (API gaya OpenAI-compatible). Kosong = `POST /api/ai/suggest` merespons 502 (server tetap berjalan) |
| `AI_BASE_URL` | ✗ | `https://api.openai.com/v1` | Base URL API AI yang mendukung endpoint `/chat/completions` |
| `AI_MODEL` | ✗ | `gpt-4o-mini` | Nama model AI yang dipakai untuk saran soal |

---

## 2. Indeks Endpoint

| Metode | Endpoint | Auth | Fungsi |
|---|---|---|---|
| POST | `/api/register` | ✗ | Mendaftarkan akun baru |
| POST | `/api/login` | ✗ | Login dan mendapatkan token |
| POST | `/api/logout` | ✓ | Mengakhiri sesi token |
| GET | `/api/session` | ✓ | Mengecek sesi login masih aktif |
| GET | `/api/my-quizzes` | ✓ | List kuis milik user (dikelompokkan by status room) |
| POST | `/api/create/signature` | ✓ | Membuat signature Cloudinary untuk upload gambar kuis langsung dari klien |
| POST | `/api/create/quiz` | ✓ | Membuat kuis baru (setelah gambar diunggah ke Cloudinary) |
| GET | `/api/quizzes` | ✓ | List kuis publik (grup: open, in-Game, ended; hanya room `public`, pin ikut; tanpa soal, berisi total soal/durasi/skor) |
| POST | `/api/create/room` | ✓ | Membuat room baru (`type`: `public`/`private`) |
| POST | `/api/rooms/verify` | ✓ | Memverifikasi pin (kode) room |
| PUT | `/api/room/{id}/status` | ✓ | Mengubah status room (memulai/menghentikan permainan) |
| POST | `/api/room/{kode}/answer` | ✓ | Mengirim jawaban satu soal pada permainan yang berjalan |
| POST | `/api/room/{kode}/result` | ✓ | Membuat result untuk room |
| GET | `/api/room/{kode}/result` | ✓ | Melihat result berdasarkan kode room |
| PUT | `/api/room/{kode}/result` | ✓ | Update/upsert scoreboard result |
| GET | `/api/results` | ✓ | List semua result |
| POST | `/api/ai/suggest` | ✓ | Membuat saran soal (AI) dari topik teks |
| GET | `/api/me/points` | ✓ | Saldo poin user yang login |
| GET | `/api/me/coins` | ✓ | Riwayat perolehan koin user yang login |
| GET | `/api/emojis` | ✓ | List semua emoji |
| GET | `/api/emojis/{id}` | ✓ | Melihat satu emoji berdasarkan ID |
| POST | `/api/emojis` | ✓ | Membuat emoji baru |
| GET | `/api/rooms?token=<JWT room>` | ✓ | Koneksi WebSocket room (header login + JWT room) |

---

## 3. Auth

### 3.1 POST /api/register

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/register` | ✗ |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `username` | string | ✅ | Username unik (min 3 karakter: huruf, angka, underscore, atau dash) |
| 2 | `nama` | string | ✅ | Nama lengkap |
| 3 | `kelas` | string | ✅ | Nama kelas |
| 4 | `password` | string | ✅ | Password dalam bentuk hash **SHA-256** (hex lowercase 64 karakter), bukan plaintext |
| 5 | `tanggal_lahir` | string | ✅ | Format `YYYY-MM-DD`, tidak boleh di masa depan |

**Contoh request:**

```http
POST /api/register HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "username": "124240200",
  "nama": "Budi Santoso",
  "kelas": "Pemrograman Mobile SI-B",
  "password": "bee5688aea66a47460b19c76f8f199c6b9585eb726f8322b1429793863609ca2",
  "tanggal_lahir": "2004-03-10"
}
```

> **Catatan hashing:** klien meng-hash password dengan SHA-256 sebelum dikirim
> (`password` = `SHA256(plaintext)` di atas). Server menyimpan/membandingkan nilai
> hash tersebut. Pengiriman tetap melalui HTTPS.

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Berhasil |
| 400 | Wajib diisi / format salah |
| 400 | Username tidak valid (min 3 karakter, hanya huruf, angka, underscore, atau dash) |
| 400 | Tanggal lahir masa depan |
| 400 | Format tanggal salah |
| 409 | Username sudah terdaftar |
| 500 | Error server |

**Contoh response — `201 Created`**

```json
{
  "message": "Akun berhasil dibuat",
  "user": {
    "username": "124240200",
    "nama": "Budi Santoso",
    "kelas": "Pemrograman Mobile SI-B",
    "tanggal_lahir": "2004-03-10"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// Wajib diisi / format salah
{ "message": "Username, nama, kelas, password, dan tanggal lahir wajib diisi" }

// Username tidak valid
{ "message": "Username minimal 3 karakter, hanya huruf, angka, underscore, atau dash" }

// Tanggal lahir masa depan
{ "message": "Tanggal lahir tidak boleh di masa depan" }

// Format tanggal salah
{ "message": "Format tanggal lahir harus YYYY-MM-DD" }
```

**Contoh response — `409 Conflict`**

```json
{ "message": "Username sudah terdaftar" }
```

**Contoh response — `500 Internal Server Error`**

```json
{ "message": "Gagal membuat akun" }
```

### 3.2 POST /api/login

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/login` | ✗ |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `username` | string | ✅ | Username user |
| 2 | `password` | string | ✅ | Password dalam bentuk hash **SHA-256** (hex lowercase 64 karakter), bukan plaintext |
| 3 | `device_id` | string | ✅ | ID perangkat; mengikat username ke perangkat ini (lihat catatan di bawah) |

**Contoh request:**

```http
POST /api/login HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "username": "124240200",
  "password": "bee5688aea66a47460b19c76f8f199c6b9585eb726f8322b1429793863609ca2",
  "device_id": "android-3f9c1d7b"
}
```

> **Catatan hashing:** klien meng-hash password dengan SHA-256 sebelum dikirim
> (`password` = `SHA256(plaintext)`, contoh di atas untuk `rahasia123`). Server
> membandingkan nilai hash tersebut. Pengiriman tetap melalui HTTPS.

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Berhasil, dapat token |
| 400 | Wajib diisi (username, password, device_id) |
| 401 | Bukan dari perangkat smartphone (allowlist device) |
| 401 | Username/password salah |
| 403 | Akun sudah terikat pada perangkat lain |
| 413 | Body terlalu besar (> 1 MiB) |
| 415 | Content-Type bukan JSON |
| 429 | Terlalu banyak percobaan login gagal (5 per IP+username per 5 menit; lihat header `Retry-After`) |
| 500 | Error server |

**Contoh response — `200 OK`**

```json
{
  "token": "<JWT>",
  "user": {
    "username": "124240200",
    "nama": "Budi Santoso",
    "kelas": "Pemrograman Mobile SI-B",
    "points": 120
  }
}
```

**Contoh response — `400 Bad Request`**

```json
{ "message": "Username, password, dan device_id wajib diisi" }
```

**Contoh response — `401 Unauthorized`**

```json
// Bukan dari smartphone
{ "message": "Akses hanya diizinkan dari perangkat smartphone" }

// Username/password salah
{ "message": "Username atau password salah" }
```

**Contoh response — `403 Forbidden`**

```json
{ "message": "Akun sudah terikat pada perangkat lain" }
```

**Contoh response — `500 Internal Server Error`**

```json
{ "message": "Gagal membuat token" }
```

> **Device binding:** saat login sukses, `device_id` disimpan pada user. Jika
> user yang sama login kembali, `device_id` harus sama; bila berbeda, ditolak `403`.
> `device_id` tidak dikembalikan pada objek `user`. Objek `user` pada `POST /api/login`, `GET /api/session`, dan `POST /api/register` menyertakan `points` (saldo poin akrual dari permainan kuis; lihat §11).

### 3.3 POST /api/logout

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/logout` | ✓ |

Tidak ada request body.

**Contoh request:**

```http
POST /api/logout HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Berhasil logout |
| 401 | Token tidak ditemukan |
| 401 | Token tidak valid |
| 401 | Sesi sudah berakhir |
| 500 | Error server |

**Contoh response — `200 OK`**

```json
{ "message": "Logout berhasil, sesi berakhir" }
```

**Contoh response — `401 Unauthorized`**

```json
// Token tidak ditemukan
{ "message": "Token tidak ditemukan" }

// Token tidak valid
{ "message": "Token tidak valid" }

// Sesi sudah berakhir
{ "message": "Sesi telah berakhir, silakan login kembali" }
```

**Contoh response — `500 Internal Server Error`**

```json
{ "message": "Gagal menghapus sesi" }
```

### 3.4 GET /api/session

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/session` | ✓ |

Tidak ada request parameter maupun body.

**Contoh request:**

```http
GET /api/session HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Sesi valid |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone / user tidak ditemukan |

**Contoh response — `200 OK`**

```json
{
  "valid": true,
  "user": {
    "username": "124240200",
    "nama": "Budi Santoso",
    "kelas": "Pemrograman Mobile SI-B",
    "points": 120
  }
}
```

**Contoh response — `401 Unauthorized`**

```json
// Token tidak valid
{ "message": "Token tidak valid" }

// Sesi berakhir
{ "message": "Sesi telah berakhir, silakan login kembali" }

// User tidak ditemukan
{ "message": "User tidak ditemukan" }
```

---

## 4. Quiz

### 4.1 GET /api/my-quizzes

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/my-quizzes` | ✓ |

Tidak ada request parameter. Response hanya kuis milik user yang login (identitas diambil otomatis dari token, sehingga tidak bisa dilihat oleh user lain).

Response dikelompokkan ke **5 grup** berdasarkan status room paling terakhir dibuat:
`waiting`, `open`, `in-Game`, `ended`, dan `quarantine` (kuis yang belum punya room sama sekali).
Setiap kuis muncul hanya di **satu** grup; room di dalam kuis diurutkan ascending (kecil → besar) by `created_at`, dan urutan kuis di tiap grup berdasarkan `created_at` kuis (terbaru di atas).

**Contoh request:**

```http
GET /api/my-quizzes HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | List kuis milik sendiri (dikelompokkan by status room) |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 401 | User tidak ditemukan |

**Contoh response — `200 OK`**

```json
{
  "waiting": [
    {
      "id": "<id>",
      "user_id": "<user_id>",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "questions": [
        {
          "question": "Bahasa pemrograman utama Flutter?",
          "options": ["Kotlin", "Dart", "Swift", "Java"],
          "duration": 1.5,
          "skor": 20
        }
      ],
      "created_at": "2026-09-17T10:00:00Z",
      "status": "waiting",
      "rooms": [
        {
          "id": "<room_id>",
          "judul": "Room Soal Flutter",
          "isi": "Kumpulan soal dasar Flutter & Dart untuk persiapan ujian.",
          "kode": "482913",
          "status": "waiting",
          "type": "public",
          "created_at": "2026-09-17T10:00:00Z"
        }
      ]
    }
  ],
  "open": [],
  "in-Game": [],
  "ended": [],
  "quarantine": [
    {
      "id": "<id>",
      "user_id": "<user_id>",
      "title": "Kuis Basis Data MongoDB",
      "description": "Konsep dasar MongoDB",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mongodb.png",
      "questions": [
        {
          "question": "MongoDB termasuk database jenis apa?",
          "options": ["SQL", "Redis", "NoSQL", "GraphQL"],
          "duration": 2,
          "skor": 20
        }
      ],
      "created_at": "2026-09-16T08:00:00Z",
      "rooms": []
    }
  ]
}
```

> `status` pada kuis = status room yang paling terakhir dibuat; field ini dihilangkan (`omitempty`) jika kuis belum punya room (masuk grup `quarantine`). `path` berisi URL gambar kuis hasil unggahan Cloudinary (lihat §4.2–§4.4). `correct_idx` tidak dikembalikan pada response untuk menjaga jawaban benar tetap rahasia. Tiap room memuat `type` (`public` atau `private`); room lama tanpa field `type` ditampilkan sebagai `public`.

**Contoh response — `401 Unauthorized`**

```json
// Token tidak valid
{ "message": "Token tidak valid" }

// Sesi berakhir
{ "message": "Sesi telah berakhir, silakan login kembali" }

// Bukan dari smartphone
{ "message": "Akses hanya diizinkan dari perangkat smartphone" }

// User tidak ditemukan
{ "message": "User tidak ditemukan" }
```

---

### 4.2 POST /api/create/signature

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/create/signature` | ✓ |

Endpoint ini digunakan klien untuk meminta tanda tangan digital (*signature*) resmi dari server
sebelum mengunggah gambar langsung ke Cloudinary. Signature ditandatangani dari parameter
`folder` dan `timestamp` (waktu server saat ini) memakai API secret Cloudinary; API secret itu
sendiri **tidak pernah** dikembalikan.

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `folder` | string | ✅ | Folder tujuan aset di Cloudinary; harus `galery-quiz/quiz-image` |

**Contoh request:**

```http
POST /api/create/signature HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "folder": "galery-quiz/quiz-image"
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Sukses menghasilkan signature |
| 400 | `folder` kosong atau bukan folder yang diizinkan |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 413 | Body terlalu besar (> 1 MiB) |
| 415 | Content-Type bukan JSON |
| 500 | Gagal membuat signature (konfigurasi Cloudinary belum lengkap) |

**Contoh response — `200 OK`**

```json
{
  "success": true,
  "signature": "81f14371fa77c3852cd1d6ebbe382cf8476aa081",
  "timestamp": 1792154580,
  "apiKey": "123456789012345",
  "cloudName": "dlxxyz123"
}
```

> `apiKey` dan `cloudName` adalah kredensial publik; `signature` dihitung dari `folder` +
> `timestamp` (SHA-1). Klien mengirim ulang `api_key`, `timestamp`, `signature`, dan `folder`
> yang sama saat upload ke Cloudinary (§4.3). Karena `timestamp` diambil saat permintaan,
> signature hanya berlaku dalam jendela waktu singkat yang diterima Cloudinary.

**Contoh response — `400 Bad Request`**

```json
// folder kosong
{ "message": "folder wajib diisi" }

// folder bukan folder yang diizinkan
{ "message": "folder tidak diizinkan" }
```

---

### 4.3 POST /image/upload (Direct to Cloudinary)

| Metode | Path | Auth |
|---|---|---|
| POST | `https://api.cloudinary.com/v1_1/<cloudName>/image/upload` | ✗ |

Endpoint ini disediakan langsung oleh Cloudinary. Klien mengirimkan file asli (*binary*) ke URL
ini menggunakan data otorisasi yang didapatkan dari endpoint `POST /api/create/signature` (§4.2).

**Request body (multipart/form-data):**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `file` | file (binary) | ✅ | File fisik gambar kuis (`jpg`/`jpeg`/`png`/`webp`), maksimal 5 MB |
| 2 | `api_key` | string | ✅ | Diambil dari field `apiKey` hasil respons endpoint `/api/create/signature` |
| 3 | `timestamp` | int | ✅ | Diambil dari field `timestamp` hasil respons endpoint `/api/create/signature` |
| 4 | `signature` | string | ✅ | Diambil dari field `signature` hasil respons endpoint `/api/create/signature` |
| 5 | `folder` | string | ✅ | **Wajib sama** dengan folder yang dikirim pada endpoint `/api/create/signature` |

**Contoh request:**

```http
POST /v1_1/dlxxyz123/image/upload HTTP/1.1
Host: api.cloudinary.com
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="api_key"

123456789012345
------WebKitFormBoundary
Content-Disposition: form-data; name="timestamp"

1792154580
------WebKitFormBoundary
Content-Disposition: form-data; name="signature"

81f14371fa77c3852cd1d6ebbe382cf8476aa081
------WebKitFormBoundary
Content-Disposition: form-data; name="folder"

galery-quiz/quiz-image
------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="kuis-mobile.png"
Content-Type: image/png

<isi biner gambar>
------WebKitFormBoundary--
```

**Response (JSON — `200 OK`):**
Klien wajib menangkap nilai `secure_url` pada respons ini untuk dikirimkan ke backend sebagai `path` kuis (§4.4).

```json
{
  "asset_id": "8347f3b8918c5e7b23c56d78a912e34d",
  "public_id": "galery-quiz/quiz-image/kuis-mobile",
  "format": "png",
  "resource_type": "image",
  "secure_url": "https://res.cloudinary.com/dlxxyz123/image/upload/v1792154580/galery-quiz/quiz-image/kuis-mobile.png"
}
```

---

### 4.4 POST /api/create/quiz

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/create/quiz` | ✓ |

Endpoint ini dipanggil setelah klien berhasil mendapatkan `secure_url` dari Cloudinary (§4.3). URL
gambar tersebut dikirim klien pada field **`path`** untuk disimpan ke database.

Untuk submit kuis yang berhasil, klien wajib mengirimkan **minimal 5 soal** dan format data berupa **`application/json`**.

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `title` | string | ✅ | Judul kuis |
| 2 | `description` | string | ✗ | Deskripsi kuis |
| 3 | `path` | string | ✅ | URL gambar kuis (`secure_url`) hasil balikan dari Cloudinary |
| 4 | `questions` | array | ✅ | Array berisi objek pertanyaan, minimal 5 soal |
| 5 | `questions[].question` | string | ✅ | Teks pertanyaan soal |
| 6 | `questions[].options` | array\[4\] | ✅ | Tepat 4 opsi pilihan jawaban |
| 7 | `questions[].correct_idx` | int | ✅ | Index jawaban yang benar (rentang 0–3) |
| 8 | `questions[].duration` | float | ✅ | Durasi pengerjaan soal. Harus salah satu dari: `1.5`, `2`, `3`, `5` detik |
| 9 | `questions[].skor` | int | ✅ | Skor bobot soal, wajib berada di antara rentang 1–50 |

**Contoh request:**

```http
POST /api/create/quiz HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "title": "Kuis Pemrograman Mobile",
  "description": "Dasar Flutter & Dart",
  "path": "https://res.cloudinary.com/dlxxyz123/image/upload/v1792154580/galery-quiz/quiz-image/kuis-mobile.png",
  "questions": [
    {
      "question": "Bahasa pemrograman utama Flutter?",
      "options": ["Kotlin", "Dart", "Swift", "Java"],
      "correct_idx": 1,
      "duration": 1.5,
      "skor": 20
    }
  ]
}
```

> **Catatan Singkat:** Contoh request di atas hanya mengilustrasikan 1 soal demi ringkasnya dokumen. Validasi sistem tetap mewajibkan minimal **5 soal**.

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Kuis berhasil dibuat |
| 400 | `title` / `path` kosong atau tidak valid |
| 400 | Jumlah soal di dalam `questions` kurang dari 5 |
| 400 | Properti `question` pada soal ke-n kosong |
| 400 | Jumlah item `options` pada soal ke-n tidak tepat 4 |
| 400 | Nilai `correct_idx` pada soal ke-n berada di luar rentang 0-3 |
| 400 | Nilai `duration` pada soal ke-n tidak sesuai pilihan yang diizinkan |
| 400 | Nilai `skor` pada soal ke-n berada di luar rentang 1-50 |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 415 | Content-Type bukan JSON |
| 500 | Gagal menyimpan data kuis ke database |

**Contoh response — `201 Created`**

```json
{
  "message": "Kuis berhasil dibuat",
  "quiz": {
    "id": "qz_8812x",
    "user_id": "usr_9921a",
    "title": "Kuis Pemrograman Mobile",
    "description": "Dasar Flutter & Dart",
    "path": "https://res.cloudinary.com/dlxxyz123/image/upload/v1792154580/galery-quiz/quiz-image/kuis-mobile.png",
    "questions": [
      {
        "question": "Bahasa pemrograman utama Flutter?",
        "options": ["Kotlin", "Dart", "Swift", "Java"],
        "duration": 1.5,
        "skor": 20
      }
    ],
    "created_at": "2026-10-16T15:15:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// Judul kosong
{ "message": "Judul kuis wajib diisi" }

// Public ID (URL Cloudinary) kosong
{ "message": "public_id gambar kuis wajib diisi" }

// Total item array pada questions < 5
{ "message": "Kuis harus memiliki minimal 5 soal" }

// Teks pertanyaan kosong pada indeks tertentu
{ "message": "Soal ke-1 wajib diisi" }

// Jumlah opsi pilihan jawaban salah
{ "message": "Soal ke-1 harus memiliki tepat 4 opsi jawaban" }

// Index kunci jawaban berada di luar rentang 0-3
{ "message": "correct_idx soal ke-1 tidak valid" }

// Durasi tidak sesuai dengan aturan float (1.5, 2, 3, 5)
{ "message": "durasi soal ke-1 harus salah satu dari: 1.5, 2, 3, atau 5 detik" }

// Skor berada di luar batas angka 1 - 50
{ "message": "skor soal ke-1 harus antara 1 sampai 50" }
```


### 4.5 GET /api/quizzes

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/quizzes` | ✓ |

Tidak ada request parameter.

Response dikelompokkan ke **3 grup** berdasarkan status room paling terakhir dibuat:
`open`, `in-Game`, dan `ended`. Kuis berstatus `waiting` maupun yang belum punya room sama
sekali **tidak ditampilkan** pada feed ini. Setiap kuis muncul hanya di satu grup; room di
dalam kuis diurutkan ascending by `created_at`, dan urutan kuis di tiap grup berdasarkan
`created_at` kuis (terbaru di atas).

Feed ini bersifat publik: **hanya room bertipe `public`** yang dikembalikan pada array
`rooms`. Status kuis (penentu grup) dihitung dari room **public** paling terakhir dibuat,
sehingga kuis yang tidak punya room public (mis. semua room-nya `private`) tidak muncul di
feed. Karena room yang tampil bersifat public, **pin (`kode`) ikut dikembalikan** pada tiap
room di feed ini. Room lama yang belum punya field `type` dianggap `public`.

**Contoh request:**

```http
GET /api/quizzes HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Semua kuis (dikelompokkan by status room) |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 500 | Gagal memuat data kuis / data room / data host kuis |

**Contoh response — `200 OK`**

```json
{
  "open": [
    {
      "id": "<id>",
      "host": "Budi Santoso",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "total_questions": 10,
      "total_duration": 20,
      "total_skor": 200,
      "created_at": "2026-09-17T10:00:00Z",
      "rooms": [
        {
          "id": "<room_id>",
          "judul": "Room Latihan Mobile",
          "isi": "Sesi latihan pemrograman mobile bersama teman sekelas.",
          "kode": "482913",
          "status": "open",
          "type": "public",
          "created_at": "2026-09-17T10:30:00Z"
        }
      ]
    }
  ],
  "in-Game": [],
  "ended": []
}
```

> `path` berisi URL gambar kuis hasil unggahan Cloudinary (lihat §4.2–§4.4). `host` berisi nama pemilik kuis (field `nama` pada koleksi `users`, diambil dari `user_id` kuis); `user_id` tidak dikembalikan pada feed ini. Feed publik **tidak** mengembalikan daftar soal; sebagai gantinya dikirim ringkasan `total_questions` (jumlah soal), `total_duration` (jumlah durasi semua soal dalam detik), dan `total_skor` (jumlah skor semua soal). `status` di level kuis tidak dikembalikan pada endpoint ini (status room terbaru sudah direpresentasikan oleh nama grup). Kuis berstatus `waiting` maupun yang belum punya room tidak ditampilkan. Room yang dikembalikan **hanya bertipe `public`**; karena itu pin (`kode`) ikut dikembalikan untuk room tersebut, sedangkan room `private` tidak ditampilkan. Room lama tanpa field `type` dianggap `public`.

**Contoh response — `401 Unauthorized`**

```json
{ "message": "Token tidak valid" }
```

---

## 5. Room

### 5.1 POST /api/create/room

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/create/room` | ✓ |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `quiz_id` | string (ObjectId) | ✅ | ID kuis yang dimainkan di room |
| 2 | `judul` | string | ✗ | Judul/header room |
| 3 | `isi` | string | ✗ | Deskripsi/isi room |
| 4 | `status` | string | ✗ | `waiting` (default), `open`, `in-Game`, `ended` |
| 5 | `type` | string | ✗ | `public` (default) atau `private`; menentukan apakah room tampil di feed publik |

**Contoh request:**

```http
POST /api/create/room HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "quiz_id": "6651a0ab0000000000000000",
  "judul": "Room Ujian MongoDB",
  "isi": "Evaluasi konsep dasar NoSQL dan MongoDB.",
  "type": "public"
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Room dibuat |
| 400 | quiz_id kosong |
| 400 | quiz_id tidak valid |
| 400 | status tidak valid |
| 400 | tipe room tidak valid |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 403 | Kuis bukan milik Anda (`Anda tidak punya akses ke kuis ini`) |
| 404 | Kuis tidak ada |
| 500 | Gagal membuat kode room / Gagal membuat room |

**Contoh response — `201 Created`**

```json
{
  "message": "Room berhasil dibuat",
  "room": {
    "id": "<id>",
    "quiz_id": "6651a0ab...",
    "quiz": {
      "id": "6651a0ab...",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "total_questions": 10
    },
    "kode": "482913",
    "judul": "Room Soal Flutter",
    "isi": "Kumpulan soal dasar Flutter & Dart untuk persiapan ujian.",
    "status": "waiting",
    "type": "public",
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// quiz_id kosong
{ "message": "quiz_id wajib diisi" }

// quiz_id tidak valid
{ "message": "quiz_id tidak valid" }

// status tidak valid
{ "message": "Status room harus salah satu dari: waiting, open, in-Game, ended" }

// tipe room tidak valid
{ "message": "Tipe room harus salah satu dari: public, private" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Kuis tidak ditemukan" }
```

### 5.2 PUT /api/room/{id}/status

| Metode | Path | Auth |
|---|---|---|
| PUT | `/api/room/{id}/status` | ✓ |

**Path parameter:**

| No | Parameter | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `id` | string (ObjectId) | ✅ | ID room (sumber kebenaran; selalu dipakai) |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `room_id` | string (ObjectId) | ✗ | Opsional; jika diisi wajib sama dengan `id` di path (bila beda → `400`) |
| 2 | `status` | string | ✅ | `waiting`, `open`, `in-Game`, `ended` |

**Contoh request:**

```http
PUT /api/room/6651a0ab0000000000000001/status HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "room_id": "6651a0ab0000000000000001",
  "status": "in-Game"
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Status berubah |
| 400 | ID tidak valid |
| 400 | Status tidak valid |
| 400 | `room_id` di body tidak cocok dengan path |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 403 | Room bukan milik Anda (`Anda tidak punya akses ke kuis ini`) |
| 404 | Room tidak ada |
| 500 | Gagal mengubah status room |

> Path `{id}` selalu menjadi sumber kebenaran; `room_id` di body hanya boleh sama dengan path.

**Contoh response — `200 OK`**

```json
{
  "message": "Status room berhasil diubah",
  "room": {
    "id": "<id>",
    "quiz_id": "6651a0ab...",
    "quiz": {
      "id": "6651a0ab...",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "total_questions": 10
    },
    "kode": "482913",
    "judul": "Room Soal Flutter",
    "isi": "Kumpulan soal dasar Flutter & Dart untuk persiapan ujian.",
    "status": "in-Game",
    "type": "public",
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// ID tidak valid
{ "message": "ID room tidak valid" }

// Status tidak valid
{ "message": "Status room harus salah satu dari: waiting, open, in-Game, ended" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Room tidak ditemukan" }
```

### 5.3 POST /api/rooms/verify

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/rooms/verify` | ✓ |

Memverifikasi pin room. Pin adalah **kode room enam digit** yang dibuat saat room dibuat (§5.1). Bila kode cocok, server menerbitkan **JWT ber-scope room** (masa berlaku 1 jam) beserta data room. Token itu lalu dipakai klien untuk handshake WebSocket `GET /api/rooms?token=<JWT>` (§9).

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `pin` | string | ✅ | Kode room enam digit, contoh `482913` |

**Contoh request:**

```http
POST /api/rooms/verify HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "pin": "482913"
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Pin valid; token room + data room dikembalikan |
| 400 | `pin` kosong |
| 401 | Token login tidak valid / sesi berakhir / bukan smartphone |
| 404 | Tidak ada room dengan pin tersebut (`Room tidak ditemukan`) |
| 404 | Kuis room sudah tidak ada (`Kuis tidak ditemukan`) |
| 500 | Gagal memuat data room / kuis / Gagal membuat token room |

**Contoh response — `200 OK`**

```json
{
  "message": "Pin valid",
  "token": "<JWT room>",
  "room": {
    "id": "<id>",
    "quiz_id": "6651a0ab...",
    "quiz": {
      "id": "6651a0ab...",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "total_questions": 10
    },
    "kode": "482913",
    "judul": "Room Soal Flutter",
    "isi": "Kumpulan soal dasar Flutter & Dart untuk persiapan ujian.",
    "status": "waiting",
    "type": "public",
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

> `token` adalah JWT ber-scope room (klaim `sub`=username, `room`=kode room, `typ`="room") dan **bukan** token login; token ini hanya berlaku untuk WebSocket `GET /api/rooms`.

**Contoh response — `400 Bad Request`**

```json
{ "message": "pin wajib diisi" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Room tidak ditemukan" }
```

### 5.4 JWT Room (Token Ber-scope Room)

Token yang dikembalikan `POST /api/rooms/verify` (§5.3) adalah JWT yang **berbeda** dari token login dan hanya berlaku untuk handshake WebSocket `GET /api/rooms?token=<JWT room>` (§9.1).

**Klaim (claims):**

| Klaim | Tipe | Deskripsi |
|---|---|---|
| `sub` | string | Username pemilik token (diambil dari user yang login saat verifikasi) |
| `room` | string | Kode room enam digit; klaim inilah yang menentukan room tujuan WebSocket |
| `typ` | string | Selalu `"room"`, menandai token ber-scope room (bukan token login) |
| `iat` | number | Waktu terbit (Unix) |
| `exp` | number | Waktu kedaluwarsa (Unix); 1 jam setelah diterbitkan |

**Karakteristik:**

- Ditandatangani dengan `JWT_SECRET` yang sama seperti token login, tetapi klaim `typ="room"` membuatnya **tidak dapat dipakai** sebagai Bearer di endpoint `middleware.Auth` (token login tidak memakai klaim `typ`).
- Tidak disimpan di koleksi `tokens`, sehingga tidak ikut mekanisme logout/revocation; keamanannya bertumpu pada masa berlaku pendek (1 jam).
- Saat handshake WebSocket, klaim `sub` token room **wajib sama** dengan user pada token login; bila berbeda, handshake ditolak `403`.

**Contoh payload (decoded):**

```json
{
  "sub": "budi",
  "room": "482913",
  "typ": "room",
  "iat": 1760000000,
  "exp": 1760003600
}
```

### 5.5 POST /api/room/{kode}/answer

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/room/{kode}/answer` | ✓ |

Dipakai klien untuk mengirim jawaban satu soal **selama permainan berjalan**. Permainan dibuka
saat host mengubah status room menjadi `in-Game` (§5.2) dan soal disiarkan server lewat WebSocket
(§9.1, pesan `question`). Klien menghitung sendiri **skor** soal (kecepatan menjawab × bobot ×
ketepatan) lalu mengirimkannya; server hanya mengakumulasi dengan penjagaan ringan. Sesi
permainan hidup **di memori** — server menjadi otoritas atas urutan soal, jeda papan peringkat,
dan akumulasi skor.

**Path parameter:**

| No | Parameter | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `kode` | string (6 digit) | ✅ | Kode room yang sedang bermain |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `question_index` | int | ✅ | Indeks soal yang dijawab (0-based); wajib sama dengan soal yang sedang berjalan |
| 2 | `selected_idx` | int | ✅ | Indeks opsi yang dipilih peserta (0–3) |
| 3 | `is_correct` | bool | ✅ | Benar/tidaknya jawaban (dihitung klien) |
| 4 | `elapsed_ms` | int | ✅ | Waktu menjawab dalam milidetik (dihitung klien) |
| 5 | `score` | int | ✅ | Skor soal hasil hitung klien (lihat penjagaan di bawah) |

**Contoh request:**

```http
POST /api/room/482913/answer HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "question_index": 0,
  "selected_idx": 1,
  "is_correct": true,
  "elapsed_ms": 840,
  "score": 17
}
```

**Penjagaan skor (server),** karena skor dihitung klien:

- `score` dijepit ke rentang `0 .. skor soal` (`skor` pada soal, 1–50).
- Bila `elapsed_ms > duration×1000 + 2000` (toleransi latensi 2 detik), `score` dipaksa `0`.
- Satu peserta hanya boleh menjawab **sekali** per soal.

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Jawaban tersimpan |
| 400 | Kode room kosong |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 404 | Permainan tidak sedang berjalan |
| 409 | Soal sedang tidak berjalan / soal sudah berganti / jawaban sudah dikirim |
| 415 | Content-Type bukan JSON |

**Contoh response — `200 OK`** (akumulasi skor peserta setelah jawaban ini)

```json
{
  "message": "Jawaban tersimpan",
  "score": 51,
  "correct": 3,
  "answered": 4
}
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Permainan tidak sedang berjalan" }
```

**Contoh response — `409 Conflict`**

```json
// Soal sedang tidak berjalan (fase jeda)
{ "message": "Soal sedang tidak berjalan" }

// Mengirim indeks soal yang bukan soal berjalan
{ "message": "Soal sudah berganti" }

// Peserta sudah menjawab soal ini
{ "message": "Jawaban sudah dikirim" }
```

---

## 6. Result

> Aturan: **1 kode room unik = maksimal 1 result** (dijamin unique index `results.kode`).

### 6.1 POST /api/room/{kode}/result

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/room/{kode}/result` | ✓ |

**Path parameter:**

| No | Parameter | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `kode` | string (6 digit) | ✅ | Kode unik room, contoh `482913` |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `entries` | array | ✗ | Daftar skor peserta (boleh kosong saat dibuat) |
| 2 | `entries[].nama` | string | ✅ | Nama peserta |
| 3 | `entries[].skor` | int | ✗ | Skor peserta (0–100) |

**Contoh request:**

```http
POST /api/room/482913/result HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "entries": [
    { "nama": "Budi", "skor": 80 },
    { "nama": "Ani", "skor": 70 }
  ]
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Result dibuat |
| 400 | Kode kosong |
| 400 | Nama peserta kosong / skor di luar 0–100 |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 403 | Room bukan milik Anda (`Anda tidak punya akses ke kuis ini`) |
| 404 | Room tidak ditemukan |
| 409 | Room sudah punya result |
| 500 | Gagal memeriksa result / Gagal membuat result |

**Contoh response — `201 Created`**

```json
{
  "message": "Result berhasil dibuat",
  "result": {
    "id": "<id>",
    "room_id": "<room_id>",
    "kode": "482913",
    "quiz_id": "6651a0ab...",
    "entries": [
      { "nama": "Budi", "skor": 80 },
      { "nama": "Ani", "skor": 70 }
    ],
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// Kode kosong
{ "message": "Kode room wajib diisi" }

// Nama peserta kosong
{ "message": "nama peserta ke-1 wajib diisi" }

// Skor di luar 0-100
{ "message": "skor peserta ke-1 harus antara 0 sampai 100" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Room tidak ditemukan" }
```

**Contoh response — `409 Conflict`**

```json
{ "message": "Room sudah memiliki result" }
```

### 6.2 GET /api/room/{kode}/result

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/room/{kode}/result` | ✓ |

**Path parameter:**

| No | Parameter | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `kode` | string (6 digit) | ✅ | Kode unik room |

**Contoh request:**

```http
GET /api/room/482913/result HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Result ditemukan |
| 400 | Kode kosong |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 404 | Result tidak ada |
| 500 | Gagal memuat data result / Gagal memuat data kuis |

**Contoh response — `200 OK`**

```json
{
  "result": {
    "id": "<id>",
    "room_id": "<room_id>",
    "kode": "482913",
    "quiz_id": "6651a0ab...",
    "quiz": {
      "id": "6651a0ab...",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "total_questions": 10
    },
    "entries": [
      { "nama": "Budi", "skor": 80 },
      { "nama": "Ani", "skor": 70 }
    ],
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
{ "message": "Kode room wajib diisi" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Result tidak ditemukan" }
```

### 6.3 PUT /api/room/{kode}/result

| Metode | Path | Auth |
|---|---|---|
| PUT | `/api/room/{kode}/result` | ✓ |

Upsert: jika result belum ada akan dibuat, jika sudah ada maka `entries` diganti.

**Path parameter:**

| No | Parameter | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `kode` | string (6 digit) | ✅ | Kode unik room |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `entries` | array | ✅ (setidaknya 1 valid) | Daftar skor peserta |
| 2 | `entries[].nama` | string | ✅ | Nama peserta |
| 3 | `entries[].skor` | int | ✗ | Skor peserta (0–100) |

**Contoh request:**

```http
PUT /api/room/482913/result HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "entries": [
    { "nama": "Budi", "skor": 90 },
    { "nama": "Ani", "skor": 75 },
    { "nama": "Cici", "skor": 60 }
  ]
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Result diperbarui/baru |
| 400 | Kode kosong / nama kosong / skor di luar 0–100 |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 403 | Room bukan milik Anda (`Anda tidak punya akses ke kuis ini`) |
| 404 | Room tidak ditemukan |
| 500 | Gagal memperbarui result / Gagal memuat data result |

**Contoh response — `200 OK`**

```json
{
  "result": {
    "id": "<id>",
    "room_id": "<room_id>",
    "kode": "482913",
    "quiz_id": "6651a0ab...",
    "quiz": {
      "id": "6651a0ab...",
      "title": "Kuis Pemrograman Mobile",
      "description": "Dasar Flutter & Dart",
      "path": "https://res.cloudinary.com/quiz/image/upload/v123/galery-quiz/quiz-image/kuis-mobile.png",
      "total_questions": 10
    },
    "entries": [
      { "nama": "Budi", "skor": 90 },
      { "nama": "Ani", "skor": 75 },
      { "nama": "Cici", "skor": 60 }
    ],
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
{ "message": "Kode room wajib diisi" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Room tidak ditemukan" }
```

### 6.4 GET /api/results

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/results` | ✓ |

**Query parameter (opsional):**

| No | Parameter | Tipe | Default | Deskripsi |
|---|---|---|---|---|
| 1 | `limit` | int ≥ 0 | tanpa batas | Batas jumlah result yang dikembalikan |
| 2 | `skip` | int ≥ 0 | 0 | Jumlah result yang dilewati |

**Contoh request:**

```http
GET /api/results?limit=20&skip=0 HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Semua result |
| 400 | `limit` atau `skip` bukan bilangan bulat / di bawah 0 |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 500 | Gagal memuat data result |

**Contoh response — `200 OK`**

```json
{
  "results": [
    {
      "id": "<id>",
      "room_id": "<room_id>",
      "kode": "482913",
      "quiz_id": "6651a0ab...",
      "entries": [
        { "nama": "Budi", "skor": 90 },
        { "nama": "Ani", "skor": 75 },
        { "nama": "Cici", "skor": 60 }
      ],
      "created_at": "2026-09-17T10:00:00Z"
    }
  ]
}
```

**Contoh response — `400 Bad Request`**

```json
// Limit tidak valid
{ "message": "limit tidak valid" }

// Skip tidak valid
{ "message": "skip tidak valid" }
```

**Contoh response — `401 Unauthorized`**

```json
{ "message": "Token tidak valid" }
```

---

## 7. AI

### 7.1 POST /api/ai/suggest

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/ai/suggest` | ✓ |

Endpoint ini dipanggil halaman **Create Quiz** dari aplikasi ketika pengguna
menekan tombol "Buat Soal dengan AI" lalu mengirim topik lewat bottom sheet.
Klien hanya mengirim **topik/ide teks bebas** (mis. `"Sejarah Majapahit"` atau
`"10 soal tentang Flutter"`). Server mengambil jumlah soal dari teks topik
lewat pola `N soal` (mis. `"10 soal tentang Flutter"` → 10 soal); bila topik
tidak memuat angka tersebut, dipakai **jumlah default 5** (maksimal 30; bila
lebih dari 30 permintaan ditolak). Server lalu meneruskan topik ke model AI dan
membalikkan daftar soal yang **sudah memenuhi aturan kuis (§4.4)**: tepat 4
opsi, `correct_idx` 0–3, `duration` ∈ {`1.5`, `2`, `3`, `5`}, dan `skor`
1–50.

Klien memakai hasil balikan ini untuk **mengganti seluruh isian pertanyaan**
pada form create quiz (auto-fill). Karena bergantung pada model AI, endpoint
ini dapat merespons lebih lama dari endpoint biasa — klien disarankan memakai
timeout ≥ 60 detik.

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `topic` | string | ✅ | Topik/ide soal dalam bentuk teks bebas; jumlah soal diambil dari pola `N soal` (default 5, maksimal 30) |

**Contoh request:**

```http
POST /api/ai/suggest HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "topic": "2 soal tentang Sejarah Majapahit"
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Berhasil; berisi daftar soal hasil AI |
| 400 | `topic` kosong / jumlah soal pada topik di luar rentang 1–30 |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 415 | Content-Type bukan JSON |
| 502 | Model AI gagal merespons |
| 500 | Terjadi kesalahan server |

**Contoh response — `200 OK`**

```json
{
  "message": "Saran soal berhasil dibuat",
  "questions": [
    {
      "question": "Kerajaan Majapahit didirikan oleh siapa?",
      "options": ["Raden Wijaya", "Hayam Wuruk", "Gajah Mada", "Sri Kertanegara"],
      "correct_idx": 0,
      "duration": 3,
      "skor": 20
    },
    {
      "question": "Pada tahun berapa Kerajaan Majapahit didirikan?",
      "options": ["1293", "1350", "1400", "1478"],
      "correct_idx": 0,
      "duration": 2,
      "skor": 15
    }
  ]
}
```

**Contoh response — `400 Bad Request`**

```json
// topic kosong
{ "message": "Topik soal wajib diisi" }

// jumlah soal pada topik di luar rentang yang diizinkan (mis. "50 soal tentang Flutter")
{ "message": "Jumlah soal tidak valid" }
```

**Catatan klien:** soal yang tidak memenuhi bentuk dasar (question kosong
atau `options` tidak berjumlah 4) dibuang klien (`AiService`), bukan dijadikan
isian form. Field dengan nilai di luar aturan (`duration`, `skor`,
`correct_idx`) dinormalisasi ke nilai default yang aman sebelum ditampilkan.

---

## 8. Emoji

Koleksi `emojis` menyimpan referensi emoji yang asetnya berupa berkas `.gif` di Cloudinary.
Setiap dokumen memiliki `nama` (boleh berisi karakter emoji) dan `path` (URL/path aset yang
berakhiran `.gif`). Kredensial Cloudinary diatur lewat env `CLOUDINARY_URL` (atau
`CLOUDINARY_CLOUD_NAME` + `CLOUDINARY_API_KEY` + `CLOUDINARY_API_SECRET`); endpoint di bawah
hanya membaca/menulis metadata di MongoDB.

### 8.1 GET /api/emojis

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/emojis` | ✓ |

Tidak ada request parameter. Daftar diurutkan dari yang terbaru (`created_at` desc).

**Contoh request:**

```http
GET /api/emojis HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Semua emoji |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |

**Contoh response — `200 OK`**

```json
{
  "emojis": [
    {
      "id": "<id>",
      "nama": "😀",
      "path": "https://res.cloudinary.com/demo/image/upload/v123/muka-senyum.gif",
      "created_at": "2026-09-17T10:00:00Z"
    }
  ]
}
```

### 8.2 GET /api/emojis/{id}

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/emojis/{id}` | ✓ |

**Path parameter:**

| No | Parameter | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `id` | string (ObjectId) | ✅ | ID dokumen emoji |

**Contoh request:**

```http
GET /api/emojis/6651a0ab0000000000000002 HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Emoji ditemukan |
| 400 | ID kosong / tidak valid |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 404 | Emoji tidak ada |

**Contoh response — `200 OK`**

```json
{
  "emoji": {
    "id": "6651a0ab0000000000000002",
    "nama": "😀",
    "path": "https://res.cloudinary.com/demo/image/upload/v123/muka-senyum.gif",
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// ID kosong
{ "message": "ID emoji wajib diisi" }

// ID tidak valid
{ "message": "ID emoji tidak valid" }
```

**Contoh response — `404 Not Found`**

```json
{ "message": "Emoji tidak ditemukan" }
```

### 8.3 POST /api/emojis

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/emojis` | ✓ |

Tanpa upload file: `path` diisi URL/path aset Cloudinary yang sudah ada dan wajib berakhiran `.gif`.
Aturan unik `emojis.path` membuat path yang sama tidak bisa didaftarkan dua kali.

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `nama` | string | ✅ | Nama/label emoji (boleh berisi karakter emoji) |
| 2 | `path` | string | ✅ | URL/path aset Cloudinary, wajib berakhiran `.gif` |

**Contoh request:**

```http
POST /api/emojis HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "nama": "😀",
  "path": "https://res.cloudinary.com/demo/image/upload/v123/muka-senyum.gif"
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Emoji dibuat |
| 400 | `nama` kosong / `path` kosong / `path` tidak berakhiran `.gif` |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 409 | Path sudah terdaftar |
| 413 | Body terlalu besar (> 1 MiB) |
| 415 | Content-Type bukan JSON |
| 500 | Gagal membuat emoji |

**Contoh response — `201 Created`**

```json
{
  "message": "Emoji berhasil dibuat",
  "emoji": {
    "id": "<id>",
    "nama": "😀",
    "path": "https://res.cloudinary.com/demo/image/upload/v123/muka-senyum.gif",
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

**Contoh response — `400 Bad Request`**

```json
// Nama kosong
{ "message": "nama emoji wajib diisi" }

// Path kosong
{ "message": "path emoji wajib diisi" }

// Path bukan .gif
{ "message": "path emoji wajib diakhiri .gif" }
```

**Contoh response — `409 Conflict`**

```json
{ "message": "Emoji dengan path ini sudah ada" }
```

---

## 9. WebSocket

Endpoint WebSocket melakukan *handshake* HTTP Upgrade lalu berpindah ke frame WebSocket.
Autentikasi memakai JWT lewat header `Authorization: Bearer <token>`,
dan asal (Origin) handshake dibatasi oleh env `ALLOWED_ORIGINS` bila diset.

### 9.1 GET /api/rooms?token=<JWT room>

| Item | Nilai |
|---|---|
| Protokol | `ws://` (HTTP) atau `wss://` (HTTPS, saat `cert.pem` tersedia) |
| Auth | ✅ Header `Authorization: Bearer <token>` (JWT login) **dan** query `token=<JWT room>` |
| Query param | `token` (wajib, JWT ber-scope room dari `POST /api/rooms/verify` §5.3 — lihat §5.4), `name` (opsional, default username pemilik token) |

Room ditentukan oleh klaim `room` pada JWT room di query `token`. Klaim `sub` JWT room wajib
sama dengan user yang sedang login (header `Authorization`). Kode room divalidasi harus ada di
database; jika tidak, handshake ditolak `404 { "message": "Room tidak ditemukan" }` sebelum upgrade.
Karena `middleware.Auth` juga menerapkan allowlist device, handshake ditolak `401`
`{ "message": "Akses hanya diizinkan dari perangkat smartphone" }` bila bukan dari smartphone.

Tanpa/`token` room tidak valid handshake ditolak `401` (`Token room tidak ditemukan` / `Token room tidak valid`);
bila `sub` JWT room berbeda dengan user login, ditolak `403` (`Token room bukan milik pengguna ini`).

Contoh: `ws://localhost:8080/api/rooms?token=<JWT room>&name=klien-a` (sertakan header `Authorization: Bearer <JWT login>`).

#### Format pesan

Semua pesan berupa JSON dengan bentuk yang sama:

| Field | Tipe | Keterangan |
|---|---|---|
| `type` | string | Jenis pesan |
| `room` | string | Kode room (dikirim server) |
| `from` | string | Nickname pengirim (dikirim server) |
| `time` | string | Waktu server format RFC3339 (dikirim server) |
| `data` | any | Payload bebas (dikirim klien) |
| `users` | number | Jumlah koneksi aktif di room (dikirim server) |
| `names` | string[] | Daftar nickname klien yang sudah terhubung di room, dikirim server **hanya pada pesan `connected`** agar klien baru langsung mengenal penghuni room sebelumnya (klien menambahkan dirinya sendiri ke daftar) |

#### Pesan dari klien

| `type` | Contoh | Balasan server |
|---|---|---|
| `ping` | `{"type":"ping","data":1}` | `pong` ke pengirim |
| `echo` | `{"type":"echo","data":"hai"}` | `echo` ke pengirim |
| `count` | `{"type":"count"}` | `count` ke pengirim |
| `broadcast` | `{"type":"broadcast","data":"halo"}` | `broadcast` ke klien **lain** di room yang sama |

Tipe lain diperlakukan sebagai `broadcast`. Payload yang bukan JSON dibalas dengan `error`.

#### Pesan dari server

| `type` | Kapan dikirim |
|---|---|
| `connected` | Saat koneksi upgraded, sebelum apa pun. `users` sudah termasuk dirinya sendiri; `names` berisi nickname klien yang sudah terhubung sebelumnya |
| `join` | Saat klien lain masuk ke room yang sama |
| `leave` | Saat klien lain keluar dari room |
| `question` | Soal baru dibuka saat permainan berjalan (lihat §9.2) |
| `round_result` | Satu ronde selesai; berisi kunci jawaban + papan peringkat sementara dan jeda sebelum soal berikutnya (lihat §9.2) |
| `game_end` | Permainan selesai; berisi papan peringkat akhir (lihat §9.2) |

#### Contoh respons

```json
{"type":"connected","room":"482913","from":"klien-a","time":"2026-10-04T18:53:12+07:00","users":1}
{"type":"connected","room":"482913","from":"klien-b","time":"2026-10-04T18:53:13+07:00","users":2,"names":["klien-a"]}
{"type":"broadcast","room":"482913","from":"klien-b","time":"2026-10-04T18:53:14+07:00","data":"halo"}
```

Server mengirim frame `Ping` otomatis tiap 54 detik; klien harus menjawab `Pong`. Koneksi yang tidak
menjawab dalam 60 detik akan ditutup. Ukuran pesan maksimal 8192 byte.

Tes cepat (perlu header Authorization login, JWT room di query, dan User-Agent smartphone):

```bash
wscat -c "ws://localhost:8080/api/rooms?token=<JWT room>&name=klien-a" \
  -H "Authorization: Bearer <JWT login>" \
  -H "User-Agent: Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Mobile Safari/537.36"
```

### 9.2 Alur Permainan (Game)

Permainan dimulai ketika host mengubah status room menjadi `in-Game` lewat `PUT /api/room/{id}/status`
(§5.2). Server lalu menjalankan permainan secara **otoritatif** dan menyiarkannya ke semua klien di
room lewat WebSocket:

1. Server menyiarkan `question` (soal ke-`index`), lalu menunggu selama `duration` detik.
2. Selama soal terbuka, tiap peserta mengirim jawaban lewat `POST /api/room/{kode}/answer` (§5.5).
3. Saat waktu soal habis, server menyiarkan `round_result` (kunci jawaban + papan peringkat
   sementara) dan berhenti selama `next_in_ms` (5000 ms) sebelum soal berikutnya.
4. Langkah 1–3 diulang sampai soal habis; server menyiarkan `game_end`, menandai room `ended`,
   lalu mengkreditkan **poin** (dan mencatat koin) ke tiap peserta sesuai skor (§11).

Peserta yang baru terhubung saat permainan berjalan otomatis didaftarkan ke papan peringkat
(ikut dari ronde berikutnya). **Host (pemilik kuis) tidak didaftarkan ke papan peringkat**:
host hanya memandu sesi, tidak menjawab soal, tidak muncul di leaderboard, dan tidak menerima
kredit poin; jawaban dari username host ditolak `409 Host tidak ikut bermain`. Bila host
mengubah status room ke `ended` sebelum permainan tamat,
sesi dihentikan tanpa kredit poin.

> `correct_idx` **sengaja ikut dikirim** pada `question` dan `round_result` karena skor soal
> dihitung klien (§5.5). Papan peringkat diurutkan skor desc, lalu jumlah benar desc, lalu nama asc;
> `rank` dimulai dari 1.

**`question`**

```json
{
  "type": "question",
  "room": "482913",
  "time": "2026-10-05T20:00:00+07:00",
  "data": {
    "index": 0,
    "total": 10,
    "question": "Bahasa pemrograman utama Flutter?",
    "options": ["Kotlin", "Dart", "Swift", "Java"],
    "correct_idx": 1,
    "duration": 1.5,
    "max_score": 20,
    "expires_at": 1760000001500
  }
}
```

`expires_at` adalah epoch **milidetik** kapan soal ditutup. `max_score` = bobot (`skor`) soal.

**`round_result`**

```json
{
  "type": "round_result",
  "room": "482913",
  "time": "2026-10-05T20:00:02+07:00",
  "data": {
    "round": 0,
    "total": 10,
    "correct_idx": 1,
    "next_in_ms": 5000,
    "leaderboard": [
      { "rank": 1, "username": "124240200", "nama": "Budi", "score": 20, "correct": 1, "answered": 1 }
    ]
  }
}
```

**`game_end`**

```json
{
  "type": "game_end",
  "room": "482913",
  "time": "2026-10-05T20:03:00+07:00",
  "data": {
    "total": 10,
    "finished_at": "2026-10-05T20:03:00+07:00",
    "leaderboard": [
      { "rank": 1, "username": "124240200", "nama": "Budi", "score": 150, "correct": 8, "answered": 10 }
    ]
  }
}
```

---

## 10. Kode Error Umum

| Kode | Arti | Contoh pesan |
|---|---|---|
| 400 | Request/atribut tidak valid | `Request tidak valid` / `Status room harus salah satu dari: waiting, open, in-Game, ended` / `Tipe room harus salah satu dari: public, private` |
| 401 | Autentikasi gagal atau sesi berakhir | `Token tidak valid` / `Sesi telah berakhir, silakan login kembali` / `Token tidak ditemukan` / `Token room tidak ditemukan` / `Token room tidak valid` |
| 401 | Bukan dari perangkat smartphone (allowlist device) | `Akses hanya diizinkan dari perangkat smartphone` |
| 403 | Otorisasi gagal (resource bukan milik Anda / perangkat lain) | `Anda tidak punya akses ke kuis ini` / `Token room bukan milik pengguna ini` / `Akun sudah terikat pada perangkat lain` |
| 404 | Data tidak ditemukan | `Kuis tidak ditemukan` / `Room tidak ditemukan` / `Result tidak ditemukan` / `Emoji tidak ditemukan` / `Permainan tidak sedang berjalan` |
| 409 | Konflik data (duplikat / state permainan) | `Username sudah terdaftar` / `Room sudah memiliki result` / `Emoji dengan path ini sudah ada` / `Soal sedang tidak berjalan` / `Soal sudah berganti` / `Jawaban sudah dikirim` |
| 413 | Body request terlalu besar (> 1 MiB) | `Body request terlalu besar (maksimal 1 MiB)` |
| 415 | Content-Type bukan JSON | `Content-Type harus application/json` |
| 429 | Rate limit terlampaui | `Terlalu banyak percobaan login, coba lagi nanti` |
| 500 | Error server | `Gagal membuat akun` / `Gagal membuat room` / `Gagal membuat token room` |

> Semua endpoint yang menerima body JSON memakai validator yang sama sehingga dapat mengembalikan `413` dan `415` di luar daftar contoh per-endpoint di atas. Endpoint dengan `middleware.Auth` juga dapat mengembalikan `401` allowlist device. Endpoint `POST /image/upload` (§4.3) disediakan Cloudinary, bukan oleh server ini.

---

## 11. Poin & Koin

Poin adalah saldo akrual milik user (field `points` pada objek `user`, lihat §3.2–§3.4). Saldo ini
bertambah otomatis saat sebuah permainan selesai (§9.2): tiap peserta menerima poin sebesar **total
skor** yang dikumpulkannya. Setiap penambahan juga dicatat sebagai satu baris koin di koleksi `coins`
dengan **rantai hash SHA-256** (`hash = SHA256(prev_hash + payload)`, terhubung per user) sehingga
riwayat menjadi ledger yang tidak bisa diubah diam-diam tanpa memutus rantai.

### 11.1 GET /api/me/points

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/me/points` | ✓ |

Tidak ada request parameter. Mengembalikan saldo poin user yang login.

**Contoh request:**

```http
GET /api/me/points HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Saldo poin |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |

**Contoh response — `200 OK`**

```json
{
  "message": "Saldo poin",
  "points": 120
}
```

### 11.2 GET /api/me/coins

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/me/coins` | ✓ |

Tidak ada request parameter. Mengembalikan riwayat perolehan koin user yang login, diurutkan dari
yang **terbaru** (`created_at` desc, lalu `_id` desc).

**Contoh request:**

```http
GET /api/me/coins HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
```

**Response:**

| Status | Deskripsi |
|---|---|
| 200 | Riwayat koin |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 500 | Gagal membaca riwayat koin |

**Contoh response — `200 OK`**

```json
{
  "message": "Riwayat koin",
  "coins": [
    {
      "id": "6700aa11bb22cc33dd44ee55",
      "amount": 150,
      "reason": "quiz_reward",
      "room_kode": "482913",
      "quiz_id": "6651a0ab0000000000000000",
      "created_at": "2026-10-05T20:03:00Z",
      "prev_hash": "9f2c...e1",
      "hash": "3ab4...7d"
    }
  ]
}
```

> `reason` bernilai `quiz_reward` untuk hadiah permainan kuis. `prev_hash` dan `hash` adalah rantai
> SHA-256 untuk verifikasi integritas; baris pertama milik user memakai `prev_hash` string kosong.

**Contoh response — `401 Unauthorized`**

```json
// Token tidak valid
{ "message": "Token tidak valid" }

// Sesi berakhir
{ "message": "Sesi telah berakhir, silakan login kembali" }
```

**Contoh response — `500 Internal Server Error`**

```json
{ "message": "Gagal membaca riwayat koin" }
```
