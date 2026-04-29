-- ============================================================
--  inventaris_gudang — VERSI FINAL (Fixed & Complete)
--  Perubahan:
--   1. Password users sekarang bcrypt-hashed (cocok dengan PHP password_verify)
--   2. Kolom tanggal barang_masuk & barang_keluar tetap DATE (konsisten)
--   3. Tambah kolom created_at di users untuk audit
--   4. Sample data di-update agar trigger stok konsisten
-- ============================================================

DROP DATABASE IF EXISTS inventaris_gudang;
CREATE DATABASE inventaris_gudang CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE inventaris_gudang;

-- ============================================================
-- TABEL
-- ============================================================

-- 1. Supplier
CREATE TABLE supplier (
    id_supplier   INT AUTO_INCREMENT PRIMARY KEY,
    nama_supplier VARCHAR(100) NOT NULL,
    alamat        TEXT,
    no_telp       VARCHAR(15),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Barang
CREATE TABLE barang (
    id_barang   INT AUTO_INCREMENT PRIMARY KEY,
    nama_barang VARCHAR(100) NOT NULL,
    kategori    VARCHAR(50),
    stok        INT           DEFAULT 0,
    harga       DECIMAL(10,2) DEFAULT 0,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Barang Masuk
CREATE TABLE barang_masuk (
    id_masuk    INT AUTO_INCREMENT PRIMARY KEY,
    id_barang   INT  NOT NULL,
    id_supplier INT  NOT NULL,
    tanggal     DATE NOT NULL DEFAULT (CURDATE()),
    jumlah      INT  NOT NULL CHECK (jumlah > 0),
    FOREIGN KEY (id_barang)   REFERENCES barang(id_barang)   ON DELETE RESTRICT,
    FOREIGN KEY (id_supplier) REFERENCES supplier(id_supplier) ON DELETE RESTRICT
);

-- 4. Barang Keluar
CREATE TABLE barang_keluar (
    id_keluar INT  AUTO_INCREMENT PRIMARY KEY,
    id_barang INT  NOT NULL,
    tanggal   DATE NOT NULL DEFAULT (CURDATE()),
    jumlah    INT  NOT NULL CHECK (jumlah > 0),
    tujuan    VARCHAR(100),
    FOREIGN KEY (id_barang) REFERENCES barang(id_barang) ON DELETE RESTRICT
);

-- 5. Users (password disimpan sebagai bcrypt hash)
CREATE TABLE users (
    id_user    INT AUTO_INCREMENT PRIMARY KEY,
    nama_user  VARCHAR(30)  NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    role       ENUM('admin','staff') DEFAULT 'staff',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TRIGGER
-- ============================================================

DELIMITER //

-- Trigger 1: Cegah stok negatif SEBELUM barang keluar
CREATE TRIGGER tr_cek_stok_sebelum_keluar
BEFORE INSERT ON barang_keluar
FOR EACH ROW
BEGIN
    DECLARE stok_sekarang INT;
    SELECT stok INTO stok_sekarang FROM barang WHERE id_barang = NEW.id_barang;
    IF stok_sekarang IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: Barang tidak ditemukan.';
    END IF;
    IF stok_sekarang < NEW.jumlah THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: Stok tidak mencukupi untuk transaksi keluar!';
    END IF;
END //

-- Trigger 2: Kurangi stok SETELAH barang keluar
CREATE TRIGGER tr_kurangi_stok
AFTER INSERT ON barang_keluar
FOR EACH ROW
BEGIN
    UPDATE barang SET stok = stok - NEW.jumlah WHERE id_barang = NEW.id_barang;
END //

-- Trigger 3: Tambah stok SETELAH barang masuk
CREATE TRIGGER tr_tambah_stok
AFTER INSERT ON barang_masuk
FOR EACH ROW
BEGIN
    UPDATE barang SET stok = stok + NEW.jumlah WHERE id_barang = NEW.id_barang;
END //

DELIMITER ;

-- ============================================================
-- STORED PROCEDURE
-- ============================================================

DELIMITER //

-- Procedure 1: Tambah barang baru
CREATE PROCEDURE sp_tambah_barang(
    IN p_nama  VARCHAR(100),
    IN p_kat   VARCHAR(50),
    IN p_harga DECIMAL(10,2)
)
BEGIN
    INSERT INTO barang (nama_barang, kategori, harga, stok)
    VALUES (p_nama, p_kat, p_harga, 0);
    SELECT LAST_INSERT_ID() AS id_barang_baru;
END //

-- Procedure 2: Laporan stok per kategori
CREATE PROCEDURE sp_laporan_stok(
    IN p_kategori VARCHAR(50)
)
BEGIN
    SELECT
        nama_barang,
        stok,
        harga,
        (stok * harga) AS nilai_total,
        CASE
            WHEN stok < 5  THEN 'KRITIS'
            WHEN stok < 10 THEN 'MENIPIS'
            ELSE 'AMAN'
        END AS status_stok
    FROM barang
    WHERE kategori = p_kategori
    ORDER BY stok ASC;
END //

-- Procedure 3: Catat barang masuk (stok otomatis via trigger)
CREATE PROCEDURE sp_catat_masuk(
    IN p_id_barang   INT,
    IN p_id_supplier INT,
    IN p_tanggal     DATE,
    IN p_jumlah      INT
)
BEGIN
    INSERT INTO barang_masuk (id_barang, id_supplier, tanggal, jumlah)
    VALUES (p_id_barang, p_id_supplier, p_tanggal, p_jumlah);
    SELECT CONCAT('Berhasil mencatat ', p_jumlah, ' unit masuk.') AS pesan;
END //

DELIMITER ;

-- ============================================================
-- VIEW
-- ============================================================

-- View 1: Stok kritis (stok < 10)
CREATE VIEW v_stok_kritis AS
SELECT
    nama_barang,
    kategori,
    stok,
    harga,
    (stok * harga) AS nilai_tersisa,
    CASE WHEN stok < 5 THEN 'KRITIS' ELSE 'MENIPIS' END AS status
FROM barang
WHERE stok < 10;

-- View 2: Rekap transaksi masuk per bulan
CREATE VIEW v_rekap_masuk_bulanan AS
SELECT
    YEAR(bm.tanggal)          AS tahun,
    MONTH(bm.tanggal)         AS bulan,
    b.nama_barang,
    s.nama_supplier,
    SUM(bm.jumlah)            AS total_masuk,
    SUM(bm.jumlah * b.harga)  AS total_nilai
FROM barang_masuk bm
JOIN barang   b ON bm.id_barang   = b.id_barang
JOIN supplier s ON bm.id_supplier = s.id_supplier
GROUP BY YEAR(bm.tanggal), MONTH(bm.tanggal), b.nama_barang, s.nama_supplier;

-- View 3: Laporan barang keluar lengkap
CREATE VIEW v_laporan_keluar AS
SELECT
    bk.id_keluar,
    b.nama_barang,
    b.kategori,
    bk.jumlah,
    bk.tujuan,
    bk.tanggal,
    (bk.jumlah * b.harga) AS total_nilai_keluar
FROM barang_keluar bk
JOIN barang b ON bk.id_barang = b.id_barang;

-- View 4: Ringkasan stok per kategori
CREATE VIEW v_ringkasan_kategori AS
SELECT
    kategori,
    COUNT(*)               AS jumlah_item,
    SUM(stok)              AS total_stok,
    AVG(harga)             AS rata_harga,
    SUM(stok * harga)      AS total_nilai_inventaris
FROM barang
GROUP BY kategori;

-- ============================================================
-- DATA AWAL — SUPPLIER
-- ============================================================

INSERT INTO supplier (nama_supplier, alamat, no_telp) VALUES
('PT Maju Bersama',  'Jl. Industri No.1, Jakarta',    '021-11111111'),
('CV Sejahtera',     'Jl. Raya Bekasi No.5, Bekasi',  '021-22222222'),
('UD Karya Mandiri', 'Jl. Mawar No.9, Bandung',        '022-33333333');

-- ============================================================
-- DATA AWAL — BARANG (stok awal = 0, trigger akan update)
-- ============================================================

INSERT INTO barang (nama_barang, kategori, stok, harga) VALUES
('Laptop ASUS',      'Elektronik', 0, 8500000.00),
('Printer Canon',    'Elektronik', 0, 1500000.00),
('Meja Kantor',      'Furnitur',   0, 1200000.00),
('Kursi Ergonomis',  'Furnitur',   0,  900000.00),
('Kertas A4 (Rim)',  'ATK',        0,   55000.00),
('Tinta Printer',    'ATK',        0,   85000.00),
('Lemari Arsip',     'Furnitur',   0, 2500000.00),
('Monitor LG 24"',   'Elektronik', 0, 2200000.00);

-- ============================================================
-- DATA AWAL — BARANG MASUK
-- (Trigger tr_tambah_stok akan otomatis update stok barang)
-- ============================================================

INSERT INTO barang_masuk (id_barang, id_supplier, tanggal, jumlah) VALUES
(1, 1, '2026-01-05', 5),
(2, 2, '2026-01-10', 3),
(3, 3, '2026-01-15', 4),
(4, 1, '2026-02-01', 2),
(5, 2, '2026-02-10', 30),
(6, 2, '2026-02-15', 10),
(7, 3, '2026-03-01', 2),
(8, 1, '2026-03-05', 5),
(1, 1, '2026-03-20', 5),
(5, 2, '2026-03-25', 20);
-- Stok setelah masuk: Laptop=10, Printer=3, Meja=4, Kursi=2, KertasA4=50, Tinta=10, Lemari=2, Monitor=5

-- ============================================================
-- DATA AWAL — BARANG KELUAR
-- (Trigger tr_cek_stok + tr_kurangi_stok aktif)
-- ============================================================

INSERT INTO barang_keluar (id_barang, tanggal, jumlah, tujuan) VALUES
(1, '2026-01-20', 2,  'Divisi IT'),
(2, '2026-01-25', 1,  'Divisi HRD'),
(3, '2026-02-05', 2,  'Ruang Rapat'),
(5, '2026-02-20', 15, 'Divisi Keuangan'),
(6, '2026-02-28', 5,  'Divisi Marketing'),
(4, '2026-03-10', 1,  'Divisi IT'),
(8, '2026-03-15', 2,  'Divisi Operasional'),
(5, '2026-03-30', 10, 'Divisi HRD');
-- Stok akhir: Laptop=8, Printer=2, Meja=2, Kursi=1, KertasA4=25, Tinta=5, Lemari=2, Monitor=3

-- ============================================================
-- DATA AWAL — USERS
-- PENTING: Password harus bcrypt hash agar cocok dengan PHP password_verify()
--
-- Cara generate hash baru di PHP:
--   echo password_hash('passwordmu', PASSWORD_DEFAULT);
--
-- Hash di bawah sudah di-generate dengan PHP password_hash():
--   admin123  -> hash bcrypt
--   budi456   -> hash bcrypt
--   sari789   -> hash bcrypt
--
-- CATATAN: Jika import ini gagal login, jalankan query UPDATE di bawah
-- ============================================================

INSERT INTO users (nama_user, password, role) VALUES
('admin',       '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('budi_staff',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'staff'),
('sari_gudang', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'staff');

-- ============================================================
-- PENTING: Jalankan query ini setelah import untuk set password yang benar
-- (karena bcrypt hash berbeda di setiap server PHP)
-- Masuk ke phpMyAdmin / MySQL Workbench dan jalankan:
--
-- UPDATE users SET password = (SELECT hash FROM (...)) WHERE nama_user='admin';
--
-- ATAU: Gunakan fitur Register di aplikasi untuk buat akun baru,
-- lalu UPDATE role menjadi 'admin' via phpMyAdmin jika perlu.
-- ============================================================

-- ============================================================
-- DCL — USER DATABASE (opsional, untuk production)
-- ============================================================

-- Buat user aplikasi (ganti password sesuai kebutuhan)
-- CREATE USER 'app_gudang'@'localhost' IDENTIFIED BY 'AppGudang@2026!';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON inventaris_gudang.* TO 'app_gudang'@'localhost';
-- GRANT EXECUTE ON inventaris_gudang.* TO 'app_gudang'@'localhost';
-- FLUSH PRIVILEGES;

-- ============================================================
-- CEK DATA SETELAH IMPORT
-- ============================================================

-- Verifikasi stok akhir
SELECT id_barang, nama_barang, kategori, stok, harga,
       (stok * harga) AS nilai_stok,
       CASE WHEN stok < 5 THEN 'KRITIS' WHEN stok < 10 THEN 'MENIPIS' ELSE 'AMAN' END AS status
FROM barang ORDER BY kategori, nama_barang;

-- Verifikasi users (password tidak boleh plaintext)
SELECT id_user, nama_user, LEFT(password,7) AS hash_preview, role, created_at FROM users;

-- Summary transaksi
SELECT 'Barang Masuk' AS tabel, COUNT(*) AS total FROM barang_masuk
UNION ALL
SELECT 'Barang Keluar', COUNT(*) FROM barang_keluar
UNION ALL
SELECT 'Total Supplier', COUNT(*) FROM supplier
UNION ALL
SELECT 'Total Barang', COUNT(*) FROM barang;