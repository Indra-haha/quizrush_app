# Dokumentasi API — Deera Server

## 1. Info Umum

| Item | Nilai |
|---|---|
| Base URL | `http://localhost:8080` (ganti lewat env `PORT`) |
| Format data | JSON (`Content-Type: application/json`) |
| Header autentikasi | `Authorization: Bearer <token>` |
| Token login | Diperoleh dari `POST /api/login`, berlaku 24 jam |
| Token room | Diperoleh dari `POST /api/rooms/verify` (§5.4), berlaku 1 jam, hanya untuk WebSocket `GET /api/rooms` |
| Koleksi DB | `users`, `quizzes`, `rooms`, `results`, `tokens`, `emojis` |
| Batas body | 1 MiB per request (`413` bila lebih) |
| Hashing password | SHA-256 (hex lowercase), dilakukan di sisi klien sebelum dikirim |
| Transport | HTTPS (produksi) melindungi password hash dan token |

Semua endpoint wajib menyertakan header `Authorization` **kecuali** `POST /api/register` dan `POST /api/login`. Endpoint WebSocket `GET /api/rooms?token=<JWT room>` (§8) mewajibkan header `Authorization` (token login) **dan** JWT ber-scope room pada query `token`.

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

---

## 2. Indeks Endpoint

| Metode | Endpoint | Auth | Fungsi |
|---|---|---|---|
| POST | `/api/register` | ✗ | Mendaftarkan akun baru |
| POST | `/api/login` | ✗ | Login dan mendapatkan token |
| POST | `/api/logout` | ✓ | Mengakhiri sesi token |
| GET | `/api/session` | ✓ | Mengecek sesi login masih aktif |
| GET | `/api/my-quizzes` | ✓ | List kuis milik user (dikelompokkan by status room) |
| POST | `/api/create/quiz` | ✓ | Membuat kuis baru |
| GET | `/api/quizzes` | ✓ | List semua kuis (grup: open, in-Game, ended; tanpa soal, berisi total soal/durasi/skor) |
| POST | `/api/create/room` | ✓ | Membuat room baru |
| POST | `/api/rooms/verify` | ✓ | Memverifikasi pin (kode) room |
| PUT | `/api/room/{id}/status` | ✓ | Mengubah status room |
| POST | `/api/room/{kode}/result` | ✓ | Membuat result untuk room |
| GET | `/api/room/{kode}/result` | ✓ | Melihat result berdasarkan kode room |
| PUT | `/api/room/{kode}/result` | ✓ | Update/upsert scoreboard result |
| GET | `/api/results` | ✓ | List semua result |
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
    "kelas": "Pemrograman Mobile SI-B"
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
> `device_id` tidak dikembalikan pada objek `user`.

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
    "kelas": "Pemrograman Mobile SI-B"
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

> `status` pada kuis = status room yang paling terakhir dibuat; field ini dihilangkan (`omitempty`) jika kuis belum punya room (masuk grup `quarantine`). `path` berisi URL gambar kuis hasil unggahan Cloudinary (lihat §4.2). `correct_idx` tidak dikembalikan pada response untuk menjaga jawaban benar tetap rahasia.

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

### 4.2 POST /api/create/quiz

| Metode | Path | Auth |
|---|---|---|
| POST | `/api/create/quiz` | ✓ |

**Request body:**

| No | Field | Tipe | Wajib | Deskripsi |
|---|---|---|---|---|
| 1 | `file` | file (binary) | ✅ | Gambar kuis: `jpg`/`jpeg`/`png`/`webp`, maksimal 5 MB |
| 2 | `data` | string (JSON) | ✅ | Data kuis dalam JSON (lihat field `data.*` di bawah) |
| 3 | `data.title` | string | ✅ | Judul kuis |
| 4 | `data.description` | string | ✗ | Deskripsi kuis |
| 5 | `data.questions` | array | ✅ | Minimal 5 soal |
| 6 | `data.questions[].question` | string | ✅ | Pertanyaan |
| 7 | `data.questions[].options` | array\[4\] | ✅ | Tepat 4 opsi jawaban |
| 8 | `data.questions[].correct_idx` | int | ✅ | Index jawaban benar (0–3) |
| 9 | `data.questions[].duration` | float | ✅ | Salah satu dari: `1.5`, `2`, `3`, `5` detik |
| 10 | `data.questions[].skor` | int | ✅ | Skor soal, antara 1–50 |

Dikirim sebagai `multipart/form-data`. Server mengunggah `file` lebih dulu ke Cloudinary (folder `galery-quiz/quiz-image`).
Bila berhasil, URL gambar hasil unggahan disimpan ke field `path` kuis di database,
lalu kuis ditulis. Jadi field `path` **tidak dikirim** klien; nilainya berasal dari Cloudinary.

**Contoh request:**

```http
POST /api/create/quiz HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="data"
Content-Type: application/json

{
  "title": "Kuis Pemrograman Mobile",
  "description": "Dasar Flutter & Dart",
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
------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="kuis-mobile.png"
Content-Type: image/png

<isi biner gambar>
------WebKitFormBoundary--
```

> Untuk submit berhasil butuh minimal **5 soal**; contoh di atas hanya ilustrasi 1 soal.

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Kuis dibuat |
| 400 | Request bukan multipart / data tidak valid |
| 400 | `data` kosong |
| 400 | `file` tidak diunggah |
| 400 | Format gambar bukan jpg/jpeg/png/webp |
| 400 | Ukuran gambar > 5 MB |
| 400 | Judul kosong |
| 400 | Soal < 5 |
| 400 | Soal ke-n tidak valid |
| 400 | Opsi != 4 |
| 400 | correct_idx salah |
| 400 | Durasi salah |
| 400 | Skor tidak valid |
| 401 | Token tidak valid / sesi berakhir / bukan smartphone |
| 413 | Ukuran unggahan terlalu besar (maksimal 5 MB) |
| 500 | Gagal mengunggah gambar kuis / Gagal membuat kuis |

**Contoh response — `201 Created`**

```json
{
  "message": "Kuis berhasil dibuat",
  "quiz": {
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
    "created_at": "2026-09-17T10:00:00Z"
  }
}
```

Nilai `path` di atas adalah URL dari Cloudinary, bukan input klien.

**Contoh response — `400 Bad Request`**

```json
// Field data kosong
{ "message": "Field data wajib diisi" }

// Field data bukan JSON valid
{ "message": "Field data tidak valid" }

// File tidak diunggah
{ "message": "Gambar kuis wajib diunggah" }

// Format gambar salah
{ "message": "Format gambar kuis harus jpg, jpeg, png, atau webp" }

// Ukuran gambar terlalu besar
{ "message": "Ukuran gambar kuis maksimal 5 MB" }

// Judul kosong
{ "message": "Judul kuis wajib diisi" }

// Soal < 5
{ "message": "Kuis harus memiliki minimal 5 soal" }

// Soal ke-n tidak valid
{ "message": "Soal ke-1 wajib diisi" }

// Opsi != 4
{ "message": "Soal ke-1 harus memiliki tepat 4 opsi jawaban" }

// correct_idx salah
{ "message": "correct_idx soal ke-1 tidak valid" }

// Durasi salah
{ "message": "durasi soal ke-1 harus salah satu dari: 1.5, 2, 3, atau 5 detik" }

// Skor tidak valid
{ "message": "skor soal ke-1 harus antara 1 sampai 50" }
```

### 4.3 GET /api/quizzes

| Metode | Path | Auth |
|---|---|---|
| GET | `/api/quizzes` | ✓ |

Tidak ada request parameter.

Response dikelompokkan ke **3 grup** berdasarkan status room paling terakhir dibuat:
`open`, `in-Game`, dan `ended`. Kuis berstatus `waiting` maupun yang belum punya room sama
sekali **tidak ditampilkan** pada feed ini. Setiap kuis muncul hanya di satu grup; room di
dalam kuis diurutkan ascending by `created_at`, dan urutan kuis di tiap grup berdasarkan
`created_at` kuis (terbaru di atas).

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
          "status": "open",
          "created_at": "2026-09-17T10:30:00Z"
        }
      ]
    }
  ],
  "in-Game": [],
  "ended": []
}
```

> `path` berisi URL gambar kuis hasil unggahan Cloudinary (lihat §4.2). `host` berisi nama pemilik kuis (field `nama` pada koleksi `users`, diambil dari `user_id` kuis); `user_id` tidak dikembalikan pada feed ini. Feed publik **tidak** mengembalikan daftar soal; sebagai gantinya dikirim ringkasan `total_questions` (jumlah soal), `total_duration` (jumlah durasi semua soal dalam detik), dan `total_skor` (jumlah skor semua soal). `status` di level kuis tidak dikembalikan pada endpoint ini (status room terbaru sudah direpresentasikan oleh nama grup). Kuis berstatus `waiting` maupun yang belum punya room tidak ditampilkan. Pin room (`kode`) **tidak** dikembalikan pada feed publik ini; klien harus memverifikasi pin lewat `POST /api/rooms/verify` (§5.3) untuk mendapat data room.

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

**Contoh request:**

```http
POST /api/create/room HTTP/1.1
Host: localhost:8080
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "quiz_id": "6651a0ab0000000000000000",
  "judul": "Room Ujian MongoDB",
  "isi": "Evaluasi konsep dasar NoSQL dan MongoDB."
}
```

**Response:**

| Status | Deskripsi |
|---|---|
| 201 | Room dibuat |
| 400 | quiz_id kosong |
| 400 | quiz_id tidak valid |
| 400 | status tidak valid |
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

Memverifikasi pin room. Pin adalah **kode room enam digit** yang dibuat saat room dibuat (§5.1). Bila kode cocok, server menerbitkan **JWT ber-scope room** (masa berlaku 1 jam) beserta data room. Token itu lalu dipakai klien untuk handshake WebSocket `GET /api/rooms?token=<JWT>` (§8).

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

Token yang dikembalikan `POST /api/rooms/verify` (§5.3) adalah JWT yang **berbeda** dari token login dan hanya berlaku untuk handshake WebSocket `GET /api/rooms?token=<JWT room>` (§8.1).

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

## 7. Emoji

Koleksi `emojis` menyimpan referensi emoji yang asetnya berupa berkas `.gif` di Cloudinary.
Setiap dokumen memiliki `nama` (boleh berisi karakter emoji) dan `path` (URL/path aset yang
berakhiran `.gif`). Kredensial Cloudinary diatur lewat env `CLOUDINARY_URL` (atau
`CLOUDINARY_CLOUD_NAME` + `CLOUDINARY_API_KEY` + `CLOUDINARY_API_SECRET`); endpoint di bawah
hanya membaca/menulis metadata di MongoDB.

### 7.1 GET /api/emojis

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

### 7.2 GET /api/emojis/{id}

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

### 7.3 POST /api/emojis

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

## 8. WebSocket

Endpoint WebSocket melakukan *handshake* HTTP Upgrade lalu berpindah ke frame WebSocket.
Autentikasi memakai JWT lewat header `Authorization: Bearer <token>`,
dan asal (Origin) handshake dibatasi oleh env `ALLOWED_ORIGINS` bila diset.

### 8.1 GET /api/rooms?token=<JWT room>

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
| `connected` | Saat koneksi upgraded, sebelum apa pun. `users` sudah termasuk dirinya sendiri |
| `join` | Saat klien lain masuk ke room yang sama |
| `leave` | Saat klien lain keluar dari room |

#### Contoh respons

```json
{"type":"connected","room":"482913","from":"klien-a","time":"2026-10-04T18:53:12+07:00","users":1}
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

---

## 9. Kode Error Umum

| Kode | Arti | Contoh pesan |
|---|---|---|
| 400 | Request/atribut tidak valid | `Request tidak valid` / `Status room harus salah satu dari: waiting, open, in-Game, ended` |
| 401 | Autentikasi gagal atau sesi berakhir | `Token tidak valid` / `Sesi telah berakhir, silakan login kembali` / `Token tidak ditemukan` / `Token room tidak ditemukan` / `Token room tidak valid` |
| 401 | Bukan dari perangkat smartphone (allowlist device) | `Akses hanya diizinkan dari perangkat smartphone` |
| 403 | Otorisasi gagal (resource bukan milik Anda / perangkat lain) | `Anda tidak punya akses ke kuis ini` / `Token room bukan milik pengguna ini` / `Akun sudah terikat pada perangkat lain` |
| 404 | Data tidak ditemukan | `Kuis tidak ditemukan` / `Room tidak ditemukan` / `Result tidak ditemukan` / `Emoji tidak ditemukan` |
| 409 | Konflik data (duplikat) | `Username sudah terdaftar` / `Room sudah memiliki result` / `Emoji dengan path ini sudah ada` |
| 413 | Body request terlalu besar (> 1 MiB; multipart unggahan > 5 MB) | `Body request terlalu besar (maksimal 1 MiB)` / `Ukuran unggahan terlalu besar (maksimal 5 MB)` |
| 415 | Content-Type bukan JSON | `Content-Type harus application/json` |
| 429 | Rate limit terlampaui | `Terlalu banyak percobaan login, coba lagi nanti` |
| 500 | Error server | `Gagal membuat akun` / `Gagal membuat room` / `Gagal membuat token room` |

> Selain endpoint multipart `POST /api/create/quiz`, semua endpoint yang menerima body JSON memakai validator yang sama sehingga dapat mengembalikan `413` dan `415` di luar daftar contoh per-endpoint di atas. Endpoint dengan `middleware.Auth` juga dapat mengembalikan `401` allowlist device.
