<?php
$host = "localhost";
$db   = "inventaris_gudang";
$user = "root";
$pass = "1234";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Set zona waktu MySQL ke WIB (+07:00)
    $pdo->exec("SET time_zone = '+07:00'");
} catch (PDOException $e) {
    die("Koneksi gagal: " . $e->getMessage());
}

session_start();
?>