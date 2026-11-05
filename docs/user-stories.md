# 📖 User Story & Acceptance Criteria — Sistem Manajemen Peternakan

## 📌 Ringkasan Sistem
Sistem ini dirancang khusus untuk **Peternak** dalam mengelola dan memantau data hewan ternak, kandang, riwayat perkembangan, serta silsilah keturunan secara mandiri.
* **Autentikasi**: Google OAuth 2.0.
* **Penyimpanan Utama**: Google Drive API (Cloud Storage).
* **Penyimpanan Lokal**: Local Cache / Local Database (*Offline-First*).

---

## 🛠️ Definition of Done (DoD) Generik
Sebelum suatu *User Story* dianggap **Selesai (Done)**, fitur harus memenuhi kriteria umum berikut:
1. **Google OAuth 2.0**: Fungsi *Sign-In with Google* berjalan lancar dan aman.
2. **Offline Storage & Sync**: Data tersimpan di *Local Database* perangkat saat *offline*, dan disinkronkan otomatis ke Google Drive saat perangkat *online*.
3. **Data Integrity & Validation**: Input divalidasi di tingkat aplikasi (mencegah data terdistorsi/konflik).
4. **UI/UX**: Tampilan responsif, cepat, dan memiliki indikator status koneksi (*Online/Offline*) serta status sinkronisasi.
5. **Testing & Code Quality**: Lulus pengujian *Unit Test*, *Integration Test*, dan peninjauan kode (*Code Review*).

---

## 📋 Daftar User Story

### **US-01: Login Peternak via Google**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **login ke aplikasi menggunakan akun Google** agar dapat mengakses data peternakan saya secara praktis dan aman.
* **Detail:** 
  Otentikasi menggunakan Google OAuth 2.0. Jika perangkat dalam kondisi *offline*, Peternak yang sudah pernah login tetap bisa masuk menggunakan sesi lokal yang tersimpan.
* **Acceptance Criteria (AC):**
  * **AC 1 (Successful Login):** Peternak menekan tombol "Sign in with Google", memilih akun Google terdaftar, memberikan izin (*scopes*) Google Drive, dan diarahkan ke halaman utama.
  * **AC 2 (Offline Login):** Saat *offline*, Peternak dapat masuk ke aplikasi menggunakan token/sesi lokal yang masih valid.
  * **AC 3 (Permission Denied):** Jika Peternak menolak akses Google Drive, aplikasi menampilkan pesan peringatan bahwa izin Drive diperlukan untuk menyimpan data.

---

### **US-02: Manage Hewan Ternak (Google Drive & Offline Sync)**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **mengelola (tambah, lihat, ubah, hapus) data hewan ternak secara online maupun offline** agar informasi setiap ternak tersimpan rapi dan selalu terbarui.
* **Detail:** 
  Peternak dapat melakukan operasi CRUD data ternak. Perubahan data disimpan di database lokal dan disinkronkan ke Google Drive.
* **Acceptance Criteria (AC):**
  * **AC 1 (Tambah/Edit/Hapus):** Peternak dapat menambah, mengedit, dan menghapus data ternak (ID, Jenis, Tanggal Lahir, Jenis Kelamin, Status).
  * **AC 2 (Penyimpanan Offline):** Perubahan saat *offline* disimpan secara lokal dan diberi tanda `pending_sync`.
  * **AC 3 (Auto Sync):** Begitu perangkat terhubung ke internet, sistem otomatis mengunggah data `pending_sync` ke Google Drive di latar belakang.
  * **AC 4 (Soft Delete):** Aksi hapus data dilakukan secara *soft delete* agar mencegah kehilangan data permanen secara tidak sengaja.

---

### **US-03: View Hewan Ternak (Local Cache)**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **melihat daftar dan detail data hewan ternak secara cepat** agar dapat mengecek kondisi hewan ternak langsung di lapangan walau tanpa koneksi internet.
* **Detail:** 
  Aplikasi menampilkan data dari *cache* lokal untuk performa instan dan memperbarui data dari Google Drive saat *online*.
* **Acceptance Criteria (AC):**
  * **AC 1 (Fast Local Read):** Tampilan daftar dan detail ternak dimuat dari penyimpanan lokal tanpa perlu menunggu respon jaringan.
  * **AC 2 (Filter & Search):** Peternak dapat mencari ternak berdasarkan ID atau jenis hewan.
  * **AC 3 (Indikator Offline):** Terdapat label/banner *"Mode Offline"* saat menampilkan data tanpa jaringan internet.

---

### **US-04: Manage Kandang (Google Drive & Offline Sync)**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **mengelola data kandang secara online maupun offline** agar penempatan hewan ternak tercatat dengan terstruktur.
* **Detail:** 
  Peternak dapat membuat, melihat, mengubah, dan menghapus data kandang beserta kapasitasnya.
* **Acceptance Criteria (AC):**
  * **AC 1 (Kelola Kandang):** Peternak dapat mengisi Nama Kandang, Lokasi/Blok, dan Kapasitas Maksimal.
  * **AC 2 (Validasi Hapus):** Peternak tidak dapat menghapus kandang yang masih terisi ternak sebelum ternak dipindahkan.
  * **AC 3 (Sinkronisasi):** Data kandang tersimpan di database lokal dan otomatis tersinkron ke Google Drive saat terhubung internet.

---

### **US-05: View Kandang (Local Cache)**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **melihat daftar kandang beserta ternak di dalamnya secara offline** agar mengetahui keterisian setiap kandang.
* **Detail:** 
  Menampilkan informasi kapasitas kandang dan daftar ternak yang menempatinya menggunakan *cache* lokal.
* **Acceptance Criteria (AC):**
  * **AC 1 (Status Keterisian):** Menampilkan rasio jumlah ternak dibanding kapasitas kandang (contoh: 8/10 ekor).
  * **AC 2 (Detail Anggota):** Memilih kandang akan menampilkan daftar ternak yang ada di dalam kandang tersebut secara *offline*.

---

### **US-06: Pencatatan Pemantauan Harian (Offline-First)**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **mencatat kondisi harian hewan ternak kapan saja** agar riwayat kesehatan dan perkembangan ternak tetap terdokumentasi walau sedang di area tanpa sinyal.
* **Detail:** 
  Peternak memasukkan log harian (berat badan, suhu, kondisi kesehatan, pakan, obat) yang akan masuk ke antrean sinkronisasi (*sync queue*).
* **Acceptance Criteria (AC):**
  * **AC 1 (Input Pemantauan):** Peternak dapat menginput catatan perkembangan ternak kapan saja tanpa ketergantungan internet.
  * **AC 2 (Validasi Input):** Angka berat badan dan suhu harus berupa nilai positif.
  * **AC 3 (Sync Queue):** Catatan disimpan lokal dengan timestamp, dan otomatis diunggah ke Google Drive saat jaringan *online*.

---

### **US-07: Manage & View History Hewan Ternak**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **melihat dan mengelola riwayat pemantauan hewan ternak** agar rekam jejak perkembangan ternak terpantau secara kronologis.
* **Detail:** 
  Peternak dapat melihat *timeline* perkembangan ternak, memperbarui catatan yang salah diinput, atau menghapus entri yang tidak valid.
* **Acceptance Criteria (AC):**
  * **AC 1 (Timeline View):** Menampilkan riwayat pemantauan yang diurutkan dari yang terbaru ke terlama.
  * **AC 2 (Filter Tanggal):** Peternak dapat menyaring riwayat berdasarkan rentang tanggal tertentu di mode *offline*.
  * **AC 3 (Koreksi Data):** Peternak dapat mengubah/menghapus log pemantauan yang salah.

---

### **US-08: Manage & View Silsilah Hewan Ternak**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **mengatur dan melihat hubungan silsilah (induk & keturunan) hewan ternak** agar garis keturunan dapat dilacak dengan mudah.
* **Detail:** 
  Peternak menentukan hubungan Induk Jantan (*Sire*) dan Induk Betina (*Dam*) serta dapat melihat visualisasi pohon silsilah secara *offline*.
* **Acceptance Criteria (AC):**
  * **AC 1 (Relasi Induk-Anak):** Peternak dapat memilih ID Induk Jantan dan Betina untuk suatu hewan ternak.
  * **AC 2 (Validasi Logis):** Ternak tidak bisa menjadi induk bagi dirinya sendiri, dan umur induk harus lebih tua dari keturunannya.
  * **AC 3 (Visualisasi Pohon Silsilah):** Menampilkan bagan silsilah keluarga ternak dari data lokal dan disinkronkan ke Google Drive.

---

### **US-09: Quick View / Dashboard Peternak**
* **User Story:** 
  > Sebagai **Peternak**, saya ingin **melihat ringkasan data peternakan dan status sinkronisasi Google Drive pada dashboard** agar dapat memantau kondisi peternakan secara cepat.
* **Detail:** 
  Dashboard menampilkan ringkasan metrik utama yang dikalkulasi dari database lokal, beserta indikator koneksi dan waktu terakhir sinkronisasi.
* **Acceptance Criteria (AC):**
  * **AC 1 (Kartu Statistik):** Menampilkan total populasi ternak, jumlah kandang, dan jumlah ternak yang sedang sakit.
  * **AC 2 (Status Sinkronisasi):** Menampilkan status koneksi (*Online/Offline*) dan informasi *"Terakhir disinkronkan: [Waktu]"*.