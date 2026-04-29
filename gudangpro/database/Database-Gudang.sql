-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: inventaris_gudang
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `barang`
--

DROP TABLE IF EXISTS `barang`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barang` (
  `id_barang` int NOT NULL AUTO_INCREMENT,
  `nama_barang` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kategori` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stok` int DEFAULT '0',
  `harga` decimal(10,2) DEFAULT '0.00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_barang`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `barang`
--

LOCK TABLES `barang` WRITE;
/*!40000 ALTER TABLE `barang` DISABLE KEYS */;
INSERT INTO `barang` VALUES (1,'Laptop ASUS','Elektronik',8,8500000.00,'2026-04-28 21:23:51'),(2,'Printer Canon','Elektronik',2,1500000.00,'2026-04-28 21:23:51'),(3,'Meja Kantor','Furnitur',2,1200000.00,'2026-04-28 21:23:51'),(4,'Kursi Ergonomis','Furnitur',4,900000.00,'2026-04-28 21:23:51'),(5,'Kertas A4 (Rim)','ATK',25,55000.00,'2026-04-28 21:23:51'),(6,'Tinta Printer','ATK',5,85000.00,'2026-04-28 21:23:51'),(7,'Lemari Arsip','Furnitur',2,2500000.00,'2026-04-28 21:23:51'),(8,'Monitor LG 24\"','Elektronik',3,2200000.00,'2026-04-28 21:23:51');
/*!40000 ALTER TABLE `barang` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `barang_keluar`
--

DROP TABLE IF EXISTS `barang_keluar`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barang_keluar` (
  `id_keluar` int NOT NULL AUTO_INCREMENT,
  `id_barang` int NOT NULL,
  `tanggal` date NOT NULL DEFAULT (curdate()),
  `jumlah` int NOT NULL,
  `tujuan` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_keluar`),
  KEY `id_barang` (`id_barang`),
  CONSTRAINT `barang_keluar_ibfk_1` FOREIGN KEY (`id_barang`) REFERENCES `barang` (`id_barang`) ON DELETE RESTRICT,
  CONSTRAINT `barang_keluar_chk_1` CHECK ((`jumlah` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `barang_keluar`
--

LOCK TABLES `barang_keluar` WRITE;
/*!40000 ALTER TABLE `barang_keluar` DISABLE KEYS */;
INSERT INTO `barang_keluar` VALUES (1,1,'2026-04-14',2,'Divisi IT'),(2,2,'2026-04-29',1,'Divisi HRD'),(3,3,'2026-04-15',2,'Ruang Rapat'),(4,5,'2026-04-19',15,'Divisi Keuangan'),(5,6,'2026-04-20',5,'Divisi Marketing'),(6,4,'2026-04-14',1,'Divisi IT'),(7,8,'2026-04-11',2,'Divisi Operasional'),(8,5,'2026-04-11',10,'Divisi HRD');
/*!40000 ALTER TABLE `barang_keluar` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_cek_stok_sebelum_keluar` BEFORE INSERT ON `barang_keluar` FOR EACH ROW BEGIN
    DECLARE stok_sekarang INT;
    SELECT stok INTO stok_sekarang FROM barang WHERE id_barang = NEW.id_barang;
    IF stok_sekarang IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR: Barang tidak ditemukan.';
    END IF;
    IF stok_sekarang < NEW.jumlah THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: Stok tidak mencukupi untuk transaksi keluar!';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_kurangi_stok` AFTER INSERT ON `barang_keluar` FOR EACH ROW BEGIN
    UPDATE barang SET stok = stok - NEW.jumlah WHERE id_barang = NEW.id_barang;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `barang_masuk`
--

DROP TABLE IF EXISTS `barang_masuk`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barang_masuk` (
  `id_masuk` int NOT NULL AUTO_INCREMENT,
  `id_barang` int NOT NULL,
  `id_supplier` int NOT NULL,
  `tanggal` date NOT NULL DEFAULT (curdate()),
  `jumlah` int NOT NULL,
  PRIMARY KEY (`id_masuk`),
  KEY `id_barang` (`id_barang`),
  KEY `id_supplier` (`id_supplier`),
  CONSTRAINT `barang_masuk_ibfk_1` FOREIGN KEY (`id_barang`) REFERENCES `barang` (`id_barang`) ON DELETE RESTRICT,
  CONSTRAINT `barang_masuk_ibfk_2` FOREIGN KEY (`id_supplier`) REFERENCES `supplier` (`id_supplier`) ON DELETE RESTRICT,
  CONSTRAINT `barang_masuk_chk_1` CHECK ((`jumlah` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `barang_masuk`
--

LOCK TABLES `barang_masuk` WRITE;
/*!40000 ALTER TABLE `barang_masuk` DISABLE KEYS */;
INSERT INTO `barang_masuk` VALUES (1,1,1,'2026-04-09',5),(2,2,2,'2026-04-23',3),(3,3,3,'2026-04-29',4),(4,4,1,'2026-04-16',2),(5,5,2,'2026-04-22',30),(6,6,2,'2026-04-02',10),(7,7,3,'2026-04-08',2),(8,8,1,'2026-04-01',5),(9,1,1,'2026-04-12',5),(10,5,2,'2026-04-28',20),(11,4,2,'2026-04-13',3);
/*!40000 ALTER TABLE `barang_masuk` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_tambah_stok` AFTER INSERT ON `barang_masuk` FOR EACH ROW BEGIN
    UPDATE barang SET stok = stok + NEW.jumlah WHERE id_barang = NEW.id_barang;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `supplier`
--

DROP TABLE IF EXISTS `supplier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `supplier` (
  `id_supplier` int NOT NULL AUTO_INCREMENT,
  `nama_supplier` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alamat` text COLLATE utf8mb4_unicode_ci,
  `no_telp` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_supplier`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `supplier`
--

LOCK TABLES `supplier` WRITE;
/*!40000 ALTER TABLE `supplier` DISABLE KEYS */;
INSERT INTO `supplier` VALUES (1,'PT Maju Bersama','Jl. Industri No.1, Jakarta','021-11111111','2026-04-28 21:23:51'),(2,'CV Sejahtera','Jl. Raya Bekasi No.5, Bekasi','021-22222222','2026-04-28 21:23:51'),(3,'UD Karya Mandiri','Jl. Mawar No.9, Bandung','022-33333333','2026-04-28 21:23:51');
/*!40000 ALTER TABLE `supplier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id_user` int NOT NULL AUTO_INCREMENT,
  `nama_user` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','staff') COLLATE utf8mb4_unicode_ci DEFAULT 'staff',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user`),
  UNIQUE KEY `nama_user` (`nama_user`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','admin','2026-04-28 21:23:51'),(2,'budi_staff','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','staff','2026-04-28 21:23:51'),(3,'sari_gudang','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','staff','2026-04-28 21:23:51'),(4,'darkzone','$2y$10$gTmy/CnbkPN9WcuM8PrvpuTE4GyA0aNJR.ahZPHHd04MwbU3Wy.Bm','admin','2026-04-28 21:25:08');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_laporan_keluar`
--

DROP TABLE IF EXISTS `v_laporan_keluar`;
/*!50001 DROP VIEW IF EXISTS `v_laporan_keluar`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_laporan_keluar` AS SELECT 
 1 AS `id_keluar`,
 1 AS `nama_barang`,
 1 AS `kategori`,
 1 AS `jumlah`,
 1 AS `tujuan`,
 1 AS `tanggal`,
 1 AS `total_nilai_keluar`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_rekap_masuk_bulanan`
--

DROP TABLE IF EXISTS `v_rekap_masuk_bulanan`;
/*!50001 DROP VIEW IF EXISTS `v_rekap_masuk_bulanan`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_rekap_masuk_bulanan` AS SELECT 
 1 AS `tahun`,
 1 AS `bulan`,
 1 AS `nama_barang`,
 1 AS `nama_supplier`,
 1 AS `total_masuk`,
 1 AS `total_nilai`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_ringkasan_kategori`
--

DROP TABLE IF EXISTS `v_ringkasan_kategori`;
/*!50001 DROP VIEW IF EXISTS `v_ringkasan_kategori`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ringkasan_kategori` AS SELECT 
 1 AS `kategori`,
 1 AS `jumlah_item`,
 1 AS `total_stok`,
 1 AS `rata_harga`,
 1 AS `total_nilai_inventaris`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_stok_kritis`
--

DROP TABLE IF EXISTS `v_stok_kritis`;
/*!50001 DROP VIEW IF EXISTS `v_stok_kritis`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_stok_kritis` AS SELECT 
 1 AS `nama_barang`,
 1 AS `kategori`,
 1 AS `stok`,
 1 AS `harga`,
 1 AS `nilai_tersisa`,
 1 AS `status`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'inventaris_gudang'
--

--
-- Dumping routines for database 'inventaris_gudang'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_catat_masuk` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_catat_masuk`(
    IN p_id_barang   INT,
    IN p_id_supplier INT,
    IN p_tanggal     DATE,
    IN p_jumlah      INT
)
BEGIN
    INSERT INTO barang_masuk (id_barang, id_supplier, tanggal, jumlah)
    VALUES (p_id_barang, p_id_supplier, p_tanggal, p_jumlah);
    SELECT CONCAT('Berhasil mencatat ', p_jumlah, ' unit masuk.') AS pesan;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_laporan_stok` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_laporan_stok`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_tambah_barang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tambah_barang`(
    IN p_nama  VARCHAR(100),
    IN p_kat   VARCHAR(50),
    IN p_harga DECIMAL(10,2)
)
BEGIN
    INSERT INTO barang (nama_barang, kategori, harga, stok)
    VALUES (p_nama, p_kat, p_harga, 0);
    SELECT LAST_INSERT_ID() AS id_barang_baru;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_laporan_keluar`
--

/*!50001 DROP VIEW IF EXISTS `v_laporan_keluar`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_laporan_keluar` AS select `bk`.`id_keluar` AS `id_keluar`,`b`.`nama_barang` AS `nama_barang`,`b`.`kategori` AS `kategori`,`bk`.`jumlah` AS `jumlah`,`bk`.`tujuan` AS `tujuan`,`bk`.`tanggal` AS `tanggal`,(`bk`.`jumlah` * `b`.`harga`) AS `total_nilai_keluar` from (`barang_keluar` `bk` join `barang` `b` on((`bk`.`id_barang` = `b`.`id_barang`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_rekap_masuk_bulanan`
--

/*!50001 DROP VIEW IF EXISTS `v_rekap_masuk_bulanan`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_rekap_masuk_bulanan` AS select year(`bm`.`tanggal`) AS `tahun`,month(`bm`.`tanggal`) AS `bulan`,`b`.`nama_barang` AS `nama_barang`,`s`.`nama_supplier` AS `nama_supplier`,sum(`bm`.`jumlah`) AS `total_masuk`,sum((`bm`.`jumlah` * `b`.`harga`)) AS `total_nilai` from ((`barang_masuk` `bm` join `barang` `b` on((`bm`.`id_barang` = `b`.`id_barang`))) join `supplier` `s` on((`bm`.`id_supplier` = `s`.`id_supplier`))) group by year(`bm`.`tanggal`),month(`bm`.`tanggal`),`b`.`nama_barang`,`s`.`nama_supplier` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_ringkasan_kategori`
--

/*!50001 DROP VIEW IF EXISTS `v_ringkasan_kategori`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_ringkasan_kategori` AS select `barang`.`kategori` AS `kategori`,count(0) AS `jumlah_item`,sum(`barang`.`stok`) AS `total_stok`,avg(`barang`.`harga`) AS `rata_harga`,sum((`barang`.`stok` * `barang`.`harga`)) AS `total_nilai_inventaris` from `barang` group by `barang`.`kategori` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_stok_kritis`
--

/*!50001 DROP VIEW IF EXISTS `v_stok_kritis`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_stok_kritis` AS select `barang`.`nama_barang` AS `nama_barang`,`barang`.`kategori` AS `kategori`,`barang`.`stok` AS `stok`,`barang`.`harga` AS `harga`,(`barang`.`stok` * `barang`.`harga`) AS `nilai_tersisa`,(case when (`barang`.`stok` < 5) then 'KRITIS' else 'MENIPIS' end) AS `status` from `barang` where (`barang`.`stok` < 10) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-29  4:54:23
