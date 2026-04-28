# 🏍️ RideAssist

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

**RideAssist** adalah aplikasi pelacak perawatan (maintenance tracker) sepeda motor offline-first yang dirancang dengan antarmuka elegan dan simpel. Aplikasi ini membantu pemilik kendaraan bermotor mencatat riwayat servis, jarak tempuh (odometer), memonitor "Kesehatan Kendaraan", dan mengelola garasi motor Anda langsung di dalam satu aplikasi.

---

## ✨ Fitur Utama

*   **📊 Dynamic Dashboard**: Pantau total odometer dan persentase "Kesehatan Kendaraan" secara presisi (Kalkulasi dinamis berbasis interval penggantian oli 2000 KM). Fitur ini akan otomatis memberi peringatan *"ATTENTION REQUIRED"* saat motor Anda sudah waktunya diservis.
*   **🛠️ Service History**: Catat pengeluaran, lokasi bengkel, odometer, jenis servis (Oli, Rem, Filter, dsb), hingga lampiran foto nota servis. History dilengkapi timeline visual yang mudah dibaca.
*   **🏍️ Garage Management**: Punya lebih dari satu kendaraan? Anda dapat menambah, melihat informasi spesifik, atau menghapus sepeda motor dengan mudah melalui menu "Manage" yang mengusung desain kartu modern berbasis *Glassmorphism*.
*   **📡 Offline First**: Semua data (termasuk penyimpanan gambar/nota) disimpan 100% secara lokal dan aman di perangkat menggunakan **SQLite**. Tidak butuh koneksi internet!

## 🛠️ Tech Stack(Real)

*   **Framework**: [Flutter](https://flutter.dev/)
*   **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
*   **Local Database**: [Sqflite](https://pub.dev/packages/sqflite)
*   **Styling**: Material 3, Custom Glassmorphism UI
*   **Plugin Penting**: `image_picker`, `path_provider`, `intl`

## 📚 Dokumentasi Teknis

*   [Autotrack Odometer Guide](notes/AUTOTRACK_ODOMETER_GUIDE.md) - alur implementasi GPS tracking, filter jarak, penyimpanan trip, dan cara porting ke project lain.

## 🚀 Memulai (Getting Started)

Ikuti langkah-langkah ini untuk menjalankan RideAssist di mesin lokal Anda:

### 1. Prasyarat
*   Flutter SDK terinstal (versi 3.0 ke atas direkomendasikan)
*   Dart SDK
*   Simulator/Emulator Android/iOS, atau Hubungkan Smartphone fisik Anda.

### 2. Instalasi

Clone repositori ini dan masuk ke dalam folder proyek:
```bash
git clone https://github.com/username/ride_assist.git
cd ride_assist
```

Unduh semua dependensi package:
```bash
flutter pub get
```

Jalankan aplikasi:
```bash
flutter run
```

## 📂 Struktur Proyek Terpenting

```text
lib/
├── database/        # Konfigurasi SQLite & skrip migrasi tabel
├── models/          # Model data (Motorcycle, ServiceRecord)
├── providers/       # Riverpod State Management (MotorcycleProvider, dsb.)
├── screens/         # Semua UI halaman aplikasi
│   ├── home_screen.dart       # Dashboard utama
│   ├── history_screen.dart    # Daftar riwayat servis / Timeline
│   ├── manage_screen.dart     # Pengaturan Garasi & Kendaraan
│   └── add_service_screen.dart# Formulir tambah servis baru
└── main.dart        # Entry point aplikasi & Bottom Navigation Bar
```

---
*Dibuat dengan ❤️ untuk memudahkan para pengendara.*
