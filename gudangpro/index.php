<?php
require_once 'config.php';
date_default_timezone_set('Asia/Jakarta');

// ===============================
// 1. LOGIKA AUTH
// ===============================
$msg = "";
if (isset($_POST['register'])) {
    $username = trim($_POST['username']);
    $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
    try {
        $stmt = $pdo->prepare("INSERT INTO users (nama_user, password, role) VALUES (?, ?, 'staff')");
        $stmt->execute([$username, $password]);
        $msg = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Registrasi Berhasil! Silakan login.</div>";
    } catch (PDOException $e) {
        $msg = "<div class='alert alert-danger'><i class='bi bi-x-circle me-2'></i>Username sudah digunakan.</div>";
    }
}

if (isset($_POST['login'])) {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE nama_user = ?");
    $stmt->execute([trim($_POST['username'])]);
    $user = $stmt->fetch();
    if ($user && password_verify($_POST['password'], $user['password'])) {
        $_SESSION['login'] = true;
        $_SESSION['user']  = $user['nama_user'];
        $_SESSION['role']  = $user['role'];
        header("Location: index.php?page=dashboard");
        exit;
    } else {
        $msg = "<div class='alert alert-danger'><i class='bi bi-x-circle me-2'></i>Username atau password salah.</div>";
    }
}

if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: index.php");
    exit;
}

// ===============================
// 2. LOGIKA CRUD
// ===============================
$alert = "";
if (isset($_SESSION['login'])) {
    $page = $_GET['page'] ?? 'dashboard';

    // Tambah Barang
    if (isset($_POST['tambah_brg'])) {
        try {
            $pdo->prepare("INSERT INTO barang(nama_barang, kategori, harga, stok) VALUES(?,?,?,0)")
                ->execute([trim($_POST['nama']), trim($_POST['kategori']), $_POST['harga']]);
            $alert = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Barang berhasil ditambahkan.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Gagal menambah barang: " . $e->getMessage() . "</div>";
        }
    }

    // Edit Barang
    if (isset($_POST['edit_brg'])) {
        try {
            $pdo->prepare("UPDATE barang SET nama_barang=?, kategori=?, harga=? WHERE id_barang=?")
                ->execute([trim($_POST['nama']), trim($_POST['kategori']), $_POST['harga'], $_POST['id_barang']]);
            $alert = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Barang berhasil diperbarui.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Gagal edit barang.</div>";
        }
    }

    // Hapus Barang
    if (isset($_GET['hapus_brg'])) {
        try {
            $pdo->prepare("DELETE FROM barang WHERE id_barang=?")->execute([$_GET['hapus_brg']]);
            $alert = "<div class='alert alert-warning'><i class='bi bi-trash me-2'></i>Barang berhasil dihapus.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Tidak bisa hapus barang yang sudah memiliki transaksi.</div>";
        }
    }

    // Tambah Supplier
    if (isset($_POST['tambah_supp'])) {
        try {
            $pdo->prepare("INSERT INTO supplier(nama_supplier, alamat, no_telp) VALUES(?,?,?)")
                ->execute([trim($_POST['nama_s']), trim($_POST['alamat_s']), trim($_POST['telp_s'])]);
            $alert = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Supplier berhasil ditambahkan.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Gagal menambah supplier.</div>";
        }
    }

    // Edit Supplier
    if (isset($_POST['edit_supp'])) {
        try {
            $pdo->prepare("UPDATE supplier SET nama_supplier=?, alamat=?, no_telp=? WHERE id_supplier=?")
                ->execute([trim($_POST['nama_s']), trim($_POST['alamat_s']), trim($_POST['telp_s']), $_POST['id_supplier']]);
            $alert = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Supplier berhasil diperbarui.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Gagal edit supplier.</div>";
        }
    }

    // Hapus Supplier
    if (isset($_GET['hapus_supp'])) {
        try {
            $pdo->prepare("DELETE FROM supplier WHERE id_supplier=?")->execute([$_GET['hapus_supp']]);
            $alert = "<div class='alert alert-warning'><i class='bi bi-trash me-2'></i>Supplier berhasil dihapus.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Tidak bisa hapus supplier yang masih memiliki transaksi.</div>";
        }
    }

    // Barang Masuk — FIX: gunakan CURDATE() agar cocok dengan kolom DATE
    if (isset($_POST['trx_masuk'])) {
        try {
            $pdo->prepare("INSERT INTO barang_masuk (id_barang, id_supplier, tanggal, jumlah) VALUES (?, ?, CURDATE(), ?)")
                ->execute([$_POST['id_barang'], $_POST['id_supplier'], $_POST['jumlah']]);
            $alert = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Barang masuk berhasil dicatat. Stok otomatis diperbarui oleh trigger.</div>";
        } catch (PDOException $e) {
            $alert = "<div class='alert alert-danger'>Gagal catat barang masuk: " . $e->getMessage() . "</div>";
        }
    }

    // Barang Keluar — FIX: gunakan CURDATE() + tangkap error stok tidak cukup dari trigger
    if (isset($_POST['trx_keluar'])) {
        try {
            $pdo->prepare("INSERT INTO barang_keluar (id_barang, tanggal, jumlah, tujuan) VALUES (?, CURDATE(), ?, ?)")
                ->execute([$_POST['id_barang'], $_POST['jumlah'], trim($_POST['tujuan'])]);
            $alert = "<div class='alert alert-success'><i class='bi bi-check-circle me-2'></i>Barang keluar berhasil dicatat. Stok otomatis dikurangi oleh trigger.</div>";
        } catch (PDOException $e) {
            // Tangkap pesan dari trigger tr_cek_stok_sebelum_keluar
            $alert = "<div class='alert alert-danger'><i class='bi bi-exclamation-triangle me-2'></i>" . $e->getMessage() . "</div>";
        }
    }
}
?>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GudangPro | Sistem Inventaris</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link rel="stylesheet" href="style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>

<?php if (!isset($_SESSION['login'])): ?>
<!-- ====== HALAMAN LOGIN ====== -->
<div class="container d-flex align-items-center justify-content-center" style="min-height: 100vh;">
    <div class="col-md-8 shadow-lg bg-white rounded-4 overflow-hidden d-flex">
        <div class="col-md-6 bg-primary p-5 text-white d-none d-md-flex flex-column justify-content-center">
            <div class="mb-3"><i class="bi bi-building-fill-gear" style="font-size:3rem;"></i></div>
            <h3 class="fw-bold">GudangPro</h3>
            <p class="opacity-75">Sistem Informasi Inventaris Gudang Perusahaan</p>
            <hr class="opacity-25">
            <small class="opacity-50">Kelola stok barang, supplier, dan transaksi dengan mudah</small>
        </div>
        <div class="col-md-6 p-4">
            <h5 class="fw-bold mb-1">Selamat Datang</h5>
            <p class="text-muted small mb-3">Masuk ke akun Anda untuk melanjutkan</p>
            <?= $msg ?>
            <ul class="nav nav-tabs mb-3">
                <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#tab-login"><i class="bi bi-box-arrow-in-right me-1"></i>Login</a></li>
                <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#tab-reg"><i class="bi bi-person-plus me-1"></i>Register</a></li>
            </ul>
            <div class="tab-content">
                <div id="tab-login" class="tab-pane fade show active">
                    <form method="POST">
                        <div class="mb-2">
                            <label class="form-label small fw-semibold">Username</label>
                            <input class="form-control" name="username" placeholder="Masukkan username" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Password</label>
                            <input class="form-control" type="password" name="password" placeholder="Masukkan password" required>
                        </div>
                        <button class="btn btn-primary w-100" name="login"><i class="bi bi-box-arrow-in-right me-2"></i>Masuk</button>
                    </form>
                </div>
                <div id="tab-reg" class="tab-pane fade">
                    <form method="POST">
                        <div class="mb-2">
                            <label class="form-label small fw-semibold">Username Baru</label>
                            <input class="form-control" name="username" placeholder="Buat username" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Password</label>
                            <input class="form-control" type="password" name="password" placeholder="Buat password" required>
                        </div>
                        <button class="btn btn-success w-100" name="register"><i class="bi bi-person-check me-2"></i>Daftar Akun</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<?php else: ?>
<!-- ====== HALAMAN UTAMA ====== -->
<div class="container-fluid">
    <div class="row">
        <!-- SIDEBAR -->
        <div class="col-md-2 p-0 sidebar">
            <div class="px-4 py-3 border-bottom border-secondary mb-3">
                <h5 class="text-white m-0"><i class="bi bi-building-fill-gear me-2"></i>GudangPro</h5>
                <small class="text-white-50"><?= htmlspecialchars($_SESSION['user']) ?> · <?= htmlspecialchars($_SESSION['role']) ?></small>
            </div>
            <a href="?page=dashboard"  class="<?= $page=='dashboard' ?'active':'' ?>"><i class="bi bi-speedometer2 me-2"></i> Dashboard</a>
            <a href="?page=barang"     class="<?= $page=='barang'    ?'active':'' ?>"><i class="bi bi-box me-2"></i> Stok Barang</a>
            <a href="?page=supplier"   class="<?= $page=='supplier'  ?'active':'' ?>"><i class="bi bi-people me-2"></i> Supplier</a>
            <a href="?page=masuk"      class="<?= $page=='masuk'     ?'active':'' ?>"><i class="bi bi-plus-circle me-2"></i> Barang Masuk</a>
            <a href="?page=keluar"     class="<?= $page=='keluar'    ?'active':'' ?>"><i class="bi bi-dash-circle me-2"></i> Barang Keluar</a>
            <a href="?page=riwayat"    class="<?= $page=='riwayat'   ?'active':'' ?>"><i class="bi bi-clock-history me-2"></i> Riwayat</a>
            <hr class="mx-3 border-secondary">
            <a href="?logout=true" class="text-danger"><i class="bi bi-box-arrow-right me-2"></i> Keluar</a>
        </div>

        <!-- KONTEN UTAMA -->
        <div class="col-md-10 p-4">
            <?= $alert ?>

            <?php
            // ============================
            // DASHBOARD
            // ============================
            if ($page == 'dashboard'):
                // Data kartu ringkasan
                $totalBarang   = $pdo->query("SELECT COUNT(*) FROM barang")->fetchColumn();
                $totalSupplier = $pdo->query("SELECT COUNT(*) FROM supplier")->fetchColumn();
                $totalStok     = $pdo->query("SELECT SUM(stok) FROM barang")->fetchColumn() ?? 0;
                $nilaiInventaris = $pdo->query("SELECT SUM(stok * harga) FROM barang")->fetchColumn() ?? 0;
                $stokKritis    = $pdo->query("SELECT COUNT(*) FROM barang WHERE stok < 5")->fetchColumn();
                $transaksiHariIni = $pdo->query("SELECT (SELECT COUNT(*) FROM barang_masuk WHERE tanggal = CURDATE()) + (SELECT COUNT(*) FROM barang_keluar WHERE tanggal = CURDATE())")->fetchColumn();

                // Data grafik 30 hari terakhir (diambil per hari yang ada datanya)
                // FIX: query langsung ke DB agar akurat
                $grafikData = $pdo->query("
                    SELECT tgl, SUM(masuk) AS masuk, SUM(keluar) AS keluar FROM (
                        SELECT DATE(tanggal) AS tgl, SUM(jumlah) AS masuk, 0 AS keluar FROM barang_masuk
                            WHERE tanggal >= DATE_SUB(CURDATE(), INTERVAL 29 DAY) GROUP BY DATE(tanggal)
                        UNION ALL
                        SELECT DATE(tanggal) AS tgl, 0 AS masuk, SUM(jumlah) AS keluar FROM barang_keluar
                            WHERE tanggal >= DATE_SUB(CURDATE(), INTERVAL 29 DAY) GROUP BY DATE(tanggal)
                    ) AS combined GROUP BY tgl ORDER BY tgl ASC
                ")->fetchAll(PDO::FETCH_ASSOC);

                // Bangun array 30 hari penuh (isi 0 jika tidak ada transaksi)
                $labelGrafik = []; $dataMasuk = []; $dataKeluar = [];
                $mapGrafik = [];
                foreach ($grafikData as $row) $mapGrafik[$row['tgl']] = $row;
                for ($i = 29; $i >= 0; $i--) {
                    $tgl = date('Y-m-d', strtotime("-$i days"));
                    $labelGrafik[] = date('d/m', strtotime($tgl));
                    $dataMasuk[]   = isset($mapGrafik[$tgl]) ? (int)$mapGrafik[$tgl]['masuk']  : 0;
                    $dataKeluar[]  = isset($mapGrafik[$tgl]) ? (int)$mapGrafik[$tgl]['keluar'] : 0;
                }

                // Data grafik pie kategori
                $pieData = $pdo->query("SELECT kategori, COUNT(*) AS jml FROM barang GROUP BY kategori")->fetchAll(PDO::FETCH_ASSOC);

                // Stok kritis list
                $listKritis = $pdo->query("SELECT nama_barang, stok, kategori FROM barang WHERE stok < 5 ORDER BY stok ASC LIMIT 5")->fetchAll();
                // Transaksi terbaru
                $transaksiTerbaru = $pdo->query("
                    SELECT 'Masuk' AS jenis, b.nama_barang, bm.jumlah, bm.tanggal, s.nama_supplier AS keterangan
                    FROM barang_masuk bm JOIN barang b ON bm.id_barang=b.id_barang JOIN supplier s ON bm.id_supplier=s.id_supplier
                    UNION ALL
                    SELECT 'Keluar' AS jenis, b.nama_barang, bk.jumlah, bk.tanggal, bk.tujuan AS keterangan
                    FROM barang_keluar bk JOIN barang b ON bk.id_barang=b.id_barang
                    ORDER BY tanggal DESC LIMIT 8
                ")->fetchAll();
            ?>
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="mb-0">Dashboard</h2>
                        <small class="text-muted">Update terakhir: <?= date('d M Y, H:i') ?> WIB</small>
                    </div>
                </div>

                <!-- Kartu Ringkasan -->
                <div class="row g-3 mb-4">
                    <div class="col-md-2">
                        <div class="card p-3 bg-primary border-0 text-white h-100">
                            <div class="d-flex justify-content-between">
                                <div><div class="small opacity-75">Total Barang</div><h3 class="mb-0 fw-bold"><?= $totalBarang ?></h3></div>
                                <i class="bi bi-box-fill fs-2 opacity-50"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="card p-3 bg-success border-0 text-white h-100">
                            <div class="d-flex justify-content-between">
                                <div><div class="small opacity-75">Total Supplier</div><h3 class="mb-0 fw-bold"><?= $totalSupplier ?></h3></div>
                                <i class="bi bi-people-fill fs-2 opacity-50"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="card p-3 border-0 text-white h-100" style="background:linear-gradient(135deg,#0ea5e9,#0284c7)">
                            <div class="d-flex justify-content-between">
                                <div><div class="small opacity-75">Total Stok</div><h3 class="mb-0 fw-bold"><?= number_format($totalStok) ?></h3></div>
                                <i class="bi bi-layers-fill fs-2 opacity-50"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card p-3 bg-warning border-0 text-white h-100">
                            <div class="d-flex justify-content-between">
                                <div><div class="small opacity-75">Nilai Inventaris</div><h5 class="mb-0 fw-bold">Rp <?= number_format($nilaiInventaris,0,',','.') ?></h5></div>
                                <i class="bi bi-currency-dollar fs-2 opacity-50"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-1-5 col-md">
                        <div class="card p-3 border-0 text-white h-100" style="background:linear-gradient(135deg,#ef4444,#dc2626)">
                            <div class="d-flex justify-content-between">
                                <div><div class="small opacity-75">Stok Kritis</div><h3 class="mb-0 fw-bold"><?= $stokKritis ?></h3></div>
                                <i class="bi bi-exclamation-triangle-fill fs-2 opacity-50"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md">
                        <div class="card p-3 border-0 text-white h-100" style="background:linear-gradient(135deg,#8b5cf6,#7c3aed)">
                            <div class="d-flex justify-content-between">
                                <div><div class="small opacity-75">Transaksi Hari Ini</div><h3 class="mb-0 fw-bold"><?= $transaksiHariIni ?></h3></div>
                                <i class="bi bi-arrow-left-right fs-2 opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Grafik Tren 30 Hari -->
                <div class="card p-4 shadow-sm border-0 mb-4">
                    <h6 class="text-secondary mb-3"><i class="bi bi-graph-up me-2"></i>Tren Masuk & Keluar (30 Hari Terakhir)</h6>
                    <canvas id="inventoryChart" style="max-height: 280px;"></canvas>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Pie Kategori -->
                    <div class="col-md-4">
                        <div class="card p-4 shadow-sm border-0 h-100">
                            <h6 class="text-secondary mb-3"><i class="bi bi-pie-chart me-2"></i>Komposisi Barang</h6>
                            <canvas id="pieChart" style="max-height: 220px;"></canvas>
                        </div>
                    </div>
                    <!-- Stok Kritis -->
                    <div class="col-md-4">
                        <div class="card p-4 shadow-sm border-0 h-100">
                            <h6 class="text-secondary mb-3"><i class="bi bi-exclamation-triangle text-danger me-2"></i>Stok Kritis (< 5)</h6>
                            <?php if (empty($listKritis)): ?>
                                <p class="text-success small"><i class="bi bi-check-circle me-1"></i>Semua stok aman.</p>
                            <?php else: foreach ($listKritis as $k): ?>
                                <div class="d-flex justify-content-between align-items-center mb-2 p-2 rounded" style="background:rgba(239,68,68,0.08)">
                                    <div>
                                        <div class="fw-semibold small"><?= htmlspecialchars($k['nama_barang']) ?></div>
                                        <div class="text-muted" style="font-size:0.75rem"><?= $k['kategori'] ?></div>
                                    </div>
                                    <span class="badge bg-danger"><?= $k['stok'] ?> unit</span>
                                </div>
                            <?php endforeach; endif; ?>
                        </div>
                    </div>
                    <!-- Transaksi Terbaru -->
                    <div class="col-md-4">
                        <div class="card p-4 shadow-sm border-0 h-100">
                            <h6 class="text-secondary mb-3"><i class="bi bi-clock-history me-2"></i>Transaksi Terbaru</h6>
                            <?php foreach ($transaksiTerbaru as $t): ?>
                                <div class="d-flex justify-content-between align-items-center mb-2">
                                    <div style="font-size:0.82rem">
                                        <span class="badge <?= $t['jenis']=='Masuk'?'bg-success':'bg-danger' ?> me-1"><?= $t['jenis'] ?></span>
                                        <strong><?= htmlspecialchars($t['nama_barang']) ?></strong>
                                        <div class="text-muted"><?= $t['keterangan'] ?> · <?= date('d M', strtotime($t['tanggal'])) ?></div>
                                    </div>
                                    <span class="fw-bold"><?= $t['jumlah'] ?></span>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    </div>
                </div>

                <script>
                    // Grafik Line
                    new Chart(document.getElementById('inventoryChart').getContext('2d'), {
                        type: 'line',
                        data: {
                            labels: <?= json_encode($labelGrafik) ?>,
                            datasets: [
                                { label: 'Masuk',  data: <?= json_encode($dataMasuk) ?>,  borderColor:'#2ecc71', backgroundColor:'rgba(46,204,113,0.08)', fill:true, tension:0.4, pointRadius:3 },
                                { label: 'Keluar', data: <?= json_encode($dataKeluar) ?>, borderColor:'#e74c3c', backgroundColor:'rgba(231,76,60,0.08)',  fill:true, tension:0.4, pointRadius:3 }
                            ]
                        },
                        options: { plugins:{legend:{position:'top'}}, scales:{y:{beginAtZero:true, ticks:{stepSize:1}}} }
                    });

                    // Grafik Pie
                    new Chart(document.getElementById('pieChart').getContext('2d'), {
                        type: 'doughnut',
                        data: {
                            labels: <?= json_encode(array_column($pieData,'kategori')) ?>,
                            datasets: [{ data: <?= json_encode(array_column($pieData,'jml')) ?>,
                                backgroundColor: ['#6366f1','#06b6d4','#f59e0b','#10b981','#ef4444'] }]
                        },
                        options: { plugins:{legend:{position:'bottom'}} }
                    });
                </script>

            <?php
            // ============================
            // BARANG
            // ============================
            elseif ($page == 'barang'):
                $editBarang = null;
                if (isset($_GET['edit_brg'])) {
                    $stmt = $pdo->prepare("SELECT * FROM barang WHERE id_barang=?");
                    $stmt->execute([$_GET['edit_brg']]);
                    $editBarang = $stmt->fetch();
                }
            ?>
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h3 class="mb-0"><i class="bi bi-box me-2"></i>Manajemen Barang</h3>
                </div>

                <!-- Form Tambah / Edit -->
                <div class="card p-4 mb-4 border-0 shadow-sm">
                    <h6 class="mb-3"><?= $editBarang ? '<i class="bi bi-pencil me-2"></i>Edit Barang' : '<i class="bi bi-plus-circle me-2"></i>Tambah Barang Baru' ?></h6>
                    <form method="POST" class="row g-2">
                        <?php if ($editBarang): ?>
                            <input type="hidden" name="id_barang" value="<?= $editBarang['id_barang'] ?>">
                        <?php endif; ?>
                        <div class="col-md-4"><input name="nama" class="form-control" placeholder="Nama Barang" value="<?= $editBarang ? htmlspecialchars($editBarang['nama_barang']) : '' ?>" required></div>
                        <div class="col-md-3"><input name="kategori" class="form-control" placeholder="Kategori" value="<?= $editBarang ? htmlspecialchars($editBarang['kategori']) : '' ?>"></div>
                        <div class="col-md-3"><input name="harga" type="number" class="form-control" placeholder="Harga" value="<?= $editBarang ? $editBarang['harga'] : '' ?>" required></div>
                        <div class="col-md-2">
                            <button name="<?= $editBarang ? 'edit_brg' : 'tambah_brg' ?>" class="btn <?= $editBarang ? 'btn-warning' : 'btn-success' ?> w-100">
                                <?= $editBarang ? 'Update' : 'Tambah' ?>
                            </button>
                        </div>
                        <?php if ($editBarang): ?><div class="col-md-2"><a href="?page=barang" class="btn btn-secondary w-100">Batal</a></div><?php endif; ?>
                    </form>
                </div>

                <!-- Tabel Barang -->
                <div class="card p-4 shadow-sm border-0">
                    <div class="d-flex justify-content-between mb-3">
                        <h6 class="mb-0">Daftar Barang</h6>
                        <span class="badge bg-primary"><?= $pdo->query("SELECT COUNT(*) FROM barang")->fetchColumn() ?> item</span>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead><tr><th>#</th><th>Nama Barang</th><th>Kategori</th><th>Harga</th><th>Stok</th><th>Nilai Stok</th><th>Status</th><th>Aksi</th></tr></thead>
                            <tbody>
                                <?php foreach ($pdo->query("SELECT * FROM barang ORDER BY kategori, nama_barang")->fetchAll() as $r): ?>
                                <tr>
                                    <td><?= $r['id_barang'] ?></td>
                                    <td><strong><?= htmlspecialchars($r['nama_barang']) ?></strong></td>
                                    <td><span class="badge" style="background:rgba(99,102,241,0.15);color:#4338ca"><?= $r['kategori'] ?></span></td>
                                    <td>Rp <?= number_format($r['harga'],0,',','.') ?></td>
                                    <td><span class="badge <?= $r['stok'] < 5 ? 'bg-danger' : ($r['stok'] < 10 ? 'bg-warning' : 'bg-info') ?>"><?= $r['stok'] ?></span></td>
                                    <td>Rp <?= number_format($r['stok'] * $r['harga'],0,',','.') ?></td>
                                    <td>
                                        <?php if ($r['stok'] < 5) echo "<span class='badge bg-danger'>KRITIS</span>";
                                              elseif ($r['stok'] < 10) echo "<span class='badge bg-warning text-dark'>MENIPIS</span>";
                                              else echo "<span class='badge bg-success'>AMAN</span>"; ?>
                                    </td>
                                    <td>
                                        <a href="?page=barang&edit_brg=<?= $r['id_barang'] ?>" class="btn btn-sm btn-outline-warning me-1"><i class="bi bi-pencil"></i></a>
                                        <a href="?page=barang&hapus_brg=<?= $r['id_barang'] ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Yakin hapus barang ini?')"><i class="bi bi-trash"></i></a>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>

            <?php
            // ============================
            // SUPPLIER
            // ============================
            elseif ($page == 'supplier'):
                $editSupp = null;
                if (isset($_GET['edit_supp'])) {
                    $stmt = $pdo->prepare("SELECT * FROM supplier WHERE id_supplier=?");
                    $stmt->execute([$_GET['edit_supp']]);
                    $editSupp = $stmt->fetch();
                }
            ?>
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h3 class="mb-0"><i class="bi bi-people me-2"></i>Data Supplier</h3>
                </div>
                <div class="card p-4 mb-4 border-0 shadow-sm">
                    <h6 class="mb-3"><?= $editSupp ? '<i class="bi bi-pencil me-2"></i>Edit Supplier' : '<i class="bi bi-plus-circle me-2"></i>Tambah Supplier' ?></h6>
                    <form method="POST" class="row g-2">
                        <?php if ($editSupp): ?><input type="hidden" name="id_supplier" value="<?= $editSupp['id_supplier'] ?>"><?php endif; ?>
                        <div class="col-md-3"><input name="nama_s" class="form-control" placeholder="Nama Supplier" value="<?= $editSupp ? htmlspecialchars($editSupp['nama_supplier']) : '' ?>" required></div>
                        <div class="col-md-4"><input name="alamat_s" class="form-control" placeholder="Alamat" value="<?= $editSupp ? htmlspecialchars($editSupp['alamat']) : '' ?>"></div>
                        <div class="col-md-3"><input name="telp_s" class="form-control" placeholder="No Telp" value="<?= $editSupp ? htmlspecialchars($editSupp['no_telp']) : '' ?>"></div>
                        <div class="col-md-2"><button name="<?= $editSupp ? 'edit_supp' : 'tambah_supp' ?>" class="btn <?= $editSupp ? 'btn-warning' : 'btn-primary' ?> w-100"><?= $editSupp ? 'Update' : 'Simpan' ?></button></div>
                        <?php if ($editSupp): ?><div class="col-md-2"><a href="?page=supplier" class="btn btn-secondary w-100">Batal</a></div><?php endif; ?>
                    </form>
                </div>
                <div class="card p-4 shadow-sm border-0">
                    <table class="table table-hover">
                        <thead><tr><th>#</th><th>Nama Supplier</th><th>Alamat</th><th>No Telp</th><th>Total Pasok</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <?php
                            $suppList = $pdo->query("
                                SELECT s.*, COUNT(bm.id_masuk) AS total_pasok
                                FROM supplier s LEFT JOIN barang_masuk bm ON s.id_supplier=bm.id_supplier
                                GROUP BY s.id_supplier ORDER BY s.nama_supplier
                            ")->fetchAll();
                            foreach ($suppList as $s): ?>
                            <tr>
                                <td><?= $s['id_supplier'] ?></td>
                                <td><strong><?= htmlspecialchars($s['nama_supplier']) ?></strong></td>
                                <td><?= htmlspecialchars($s['alamat']) ?></td>
                                <td><?= htmlspecialchars($s['no_telp']) ?></td>
                                <td><span class="badge bg-info"><?= $s['total_pasok'] ?>x</span></td>
                                <td>
                                    <a href="?page=supplier&edit_supp=<?= $s['id_supplier'] ?>" class="btn btn-sm btn-outline-warning me-1"><i class="bi bi-pencil"></i></a>
                                    <a href="?page=supplier&hapus_supp=<?= $s['id_supplier'] ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Yakin hapus supplier ini?')"><i class="bi bi-trash"></i></a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>

            <?php
            // ============================
            // BARANG MASUK
            // ============================
            elseif ($page == 'masuk'):
                $daftarBarang   = $pdo->query("SELECT * FROM barang ORDER BY nama_barang")->fetchAll();
                $daftarSupplier = $pdo->query("SELECT * FROM supplier ORDER BY nama_supplier")->fetchAll();
            ?>
                <h3 class="mb-4"><i class="bi bi-plus-circle me-2"></i>Input Barang Masuk</h3>
                <div class="row g-4">
                    <div class="col-md-5">
                        <div class="card p-4 border-0 shadow-sm">
                            <h6 class="mb-3">Form Penerimaan Barang</h6>
                            <form method="POST">
                                <label class="form-label small fw-semibold">Pilih Barang</label>
                                <select name="id_barang" class="form-select mb-3">
                                    <?php foreach ($daftarBarang as $b): ?>
                                        <option value="<?= $b['id_barang'] ?>"><?= htmlspecialchars($b['nama_barang']) ?> (Stok: <?= $b['stok'] ?>)</option>
                                    <?php endforeach; ?>
                                </select>
                                <label class="form-label small fw-semibold">Pilih Supplier</label>
                                <select name="id_supplier" class="form-select mb-3">
                                    <?php foreach ($daftarSupplier as $s): ?>
                                        <option value="<?= $s['id_supplier'] ?>"><?= htmlspecialchars($s['nama_supplier']) ?></option>
                                    <?php endforeach; ?>
                                </select>
                                <label class="form-label small fw-semibold">Jumlah Diterima</label>
                                <input name="jumlah" type="number" min="1" class="form-control mb-3" placeholder="Masukkan jumlah" required>
                                <button name="trx_masuk" class="btn btn-success w-100"><i class="bi bi-check-circle me-2"></i>Catat Masuk</button>
                            </form>
                        </div>
                    </div>
                    <div class="col-md-7">
                        <div class="card p-4 border-0 shadow-sm">
                            <h6 class="mb-3">10 Transaksi Masuk Terakhir</h6>
                            <div class="table-responsive">
                                <table class="table table-hover table-sm">
                                    <thead><tr><th>Tanggal</th><th>Barang</th><th>Supplier</th><th>Jml</th></tr></thead>
                                    <tbody>
                                        <?php
                                        $riwayatMasuk = $pdo->query("
                                            SELECT bm.tanggal, b.nama_barang, s.nama_supplier, bm.jumlah
                                            FROM barang_masuk bm
                                            JOIN barang b   ON bm.id_barang=b.id_barang
                                            JOIN supplier s ON bm.id_supplier=s.id_supplier
                                            ORDER BY bm.id_masuk DESC LIMIT 10
                                        ")->fetchAll();
                                        foreach ($riwayatMasuk as $r): ?>
                                            <tr>
                                                <td><?= date('d M Y', strtotime($r['tanggal'])) ?></td>
                                                <td><?= htmlspecialchars($r['nama_barang']) ?></td>
                                                <td><?= htmlspecialchars($r['nama_supplier']) ?></td>
                                                <td><span class="badge bg-success">+<?= $r['jumlah'] ?></span></td>
                                            </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

            <?php
            // ============================
            // BARANG KELUAR
            // ============================
            elseif ($page == 'keluar'):
                $daftarBarang = $pdo->query("SELECT * FROM barang WHERE stok > 0 ORDER BY nama_barang")->fetchAll();
            ?>
                <h3 class="mb-4"><i class="bi bi-dash-circle me-2"></i>Input Barang Keluar</h3>
                <div class="row g-4">
                    <div class="col-md-5">
                        <div class="card p-4 border-0 shadow-sm">
                            <h6 class="mb-3">Form Pengeluaran Barang</h6>
                            <?php if (empty($daftarBarang)): ?>
                                <div class="alert alert-warning"><i class="bi bi-exclamation-triangle me-2"></i>Semua stok habis. Silakan tambah barang masuk terlebih dahulu.</div>
                            <?php else: ?>
                            <form method="POST">
                                <label class="form-label small fw-semibold">Pilih Barang</label>
                                <select name="id_barang" class="form-select mb-3">
                                    <?php foreach ($daftarBarang as $b): ?>
                                        <option value="<?= $b['id_barang'] ?>"><?= htmlspecialchars($b['nama_barang']) ?> — Stok: <?= $b['stok'] ?></option>
                                    <?php endforeach; ?>
                                </select>
                                <label class="form-label small fw-semibold">Jumlah Dikeluarkan</label>
                                <input name="jumlah" type="number" min="1" class="form-control mb-3" placeholder="Masukkan jumlah" required>
                                <label class="form-label small fw-semibold">Tujuan / Divisi</label>
                                <input name="tujuan" class="form-control mb-3" placeholder="Contoh: Divisi IT, Ruang Rapat" required>
                                <button name="trx_keluar" class="btn btn-danger w-100"><i class="bi bi-arrow-right-circle me-2"></i>Catat Keluar</button>
                            </form>
                            <?php endif; ?>
                        </div>
                    </div>
                    <div class="col-md-7">
                        <div class="card p-4 border-0 shadow-sm">
                            <h6 class="mb-3">10 Transaksi Keluar Terakhir</h6>
                            <div class="table-responsive">
                                <table class="table table-hover table-sm">
                                    <thead><tr><th>Tanggal</th><th>Barang</th><th>Tujuan</th><th>Jml</th></tr></thead>
                                    <tbody>
                                        <?php
                                        $riwayatKeluar = $pdo->query("
                                            SELECT bk.tanggal, b.nama_barang, bk.tujuan, bk.jumlah
                                            FROM barang_keluar bk JOIN barang b ON bk.id_barang=b.id_barang
                                            ORDER BY bk.id_keluar DESC LIMIT 10
                                        ")->fetchAll();
                                        foreach ($riwayatKeluar as $r): ?>
                                            <tr>
                                                <td><?= date('d M Y', strtotime($r['tanggal'])) ?></td>
                                                <td><?= htmlspecialchars($r['nama_barang']) ?></td>
                                                <td><?= htmlspecialchars($r['tujuan']) ?></td>
                                                <td><span class="badge bg-danger">-<?= $r['jumlah'] ?></span></td>
                                            </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

            <?php
            // ============================
            // RIWAYAT TRANSAKSI
            // ============================
            elseif ($page == 'riwayat'):
                $filter = $_GET['filter'] ?? 'semua';
                $bulan  = $_GET['bulan']  ?? date('Y-m');

                if ($filter == 'masuk') {
                    $riwayat = $pdo->query("
                        SELECT 'Masuk' AS jenis, bm.id_masuk AS id_trx, b.nama_barang, b.kategori,
                               bm.jumlah, bm.tanggal, s.nama_supplier AS keterangan,
                               (bm.jumlah * b.harga) AS total_nilai
                        FROM barang_masuk bm
                        JOIN barang b ON bm.id_barang=b.id_barang
                        JOIN supplier s ON bm.id_supplier=s.id_supplier
                        WHERE DATE_FORMAT(bm.tanggal,'%Y-%m') = '$bulan'
                        ORDER BY bm.tanggal DESC
                    ")->fetchAll();
                } elseif ($filter == 'keluar') {
                    $riwayat = $pdo->query("
                        SELECT 'Keluar' AS jenis, bk.id_keluar AS id_trx, b.nama_barang, b.kategori,
                               bk.jumlah, bk.tanggal, bk.tujuan AS keterangan,
                               (bk.jumlah * b.harga) AS total_nilai
                        FROM barang_keluar bk
                        JOIN barang b ON bk.id_barang=b.id_barang
                        WHERE DATE_FORMAT(bk.tanggal,'%Y-%m') = '$bulan'
                        ORDER BY bk.tanggal DESC
                    ")->fetchAll();
                } else {
                    $riwayat = $pdo->query("
                        SELECT 'Masuk' AS jenis, bm.id_masuk AS id_trx, b.nama_barang, b.kategori,
                               bm.jumlah, bm.tanggal, s.nama_supplier AS keterangan,
                               (bm.jumlah * b.harga) AS total_nilai
                        FROM barang_masuk bm
                        JOIN barang b ON bm.id_barang=b.id_barang
                        JOIN supplier s ON bm.id_supplier=s.id_supplier
                        WHERE DATE_FORMAT(bm.tanggal,'%Y-%m') = '$bulan'
                        UNION ALL
                        SELECT 'Keluar' AS jenis, bk.id_keluar AS id_trx, b.nama_barang, b.kategori,
                               bk.jumlah, bk.tanggal, bk.tujuan AS keterangan,
                               (bk.jumlah * b.harga) AS total_nilai
                        FROM barang_keluar bk
                        JOIN barang b ON bk.id_barang=b.id_barang
                        WHERE DATE_FORMAT(bk.tanggal,'%Y-%m') = '$bulan'
                        ORDER BY tanggal DESC
                    ")->fetchAll();
                }
            ?>
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h3 class="mb-0"><i class="bi bi-clock-history me-2"></i>Riwayat Transaksi</h3>
                </div>
                <!-- Filter -->
                <div class="card p-3 border-0 shadow-sm mb-4">
                    <form method="GET" class="row g-2 align-items-end">
                        <input type="hidden" name="page" value="riwayat">
                        <div class="col-md-3">
                            <label class="form-label small fw-semibold">Bulan</label>
                            <input type="month" name="bulan" class="form-control" value="<?= $bulan ?>">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label small fw-semibold">Jenis Transaksi</label>
                            <select name="filter" class="form-select">
                                <option value="semua" <?= $filter=='semua'?'selected':'' ?>>Semua</option>
                                <option value="masuk" <?= $filter=='masuk'?'selected':'' ?>>Barang Masuk</option>
                                <option value="keluar" <?= $filter=='keluar'?'selected':'' ?>>Barang Keluar</option>
                            </select>
                        </div>
                        <div class="col-md-2"><button class="btn btn-primary w-100"><i class="bi bi-funnel me-2"></i>Filter</button></div>
                    </form>
                </div>
                <div class="card p-4 shadow-sm border-0">
                    <div class="d-flex justify-content-between mb-3">
                        <h6 class="mb-0">Hasil: <?= count($riwayat) ?> transaksi</h6>
                        <?php
                        $totalNilai = array_sum(array_column($riwayat, 'total_nilai'));
                        ?>
                        <span class="text-muted small">Total Nilai: <strong>Rp <?= number_format($totalNilai,0,',','.') ?></strong></span>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead><tr><th>#</th><th>Jenis</th><th>Barang</th><th>Kategori</th><th>Jumlah</th><th>Keterangan</th><th>Tanggal</th><th>Total Nilai</th></tr></thead>
                            <tbody>
                                <?php if (empty($riwayat)): ?>
                                    <tr><td colspan="8" class="text-center text-muted py-4">Tidak ada transaksi pada periode ini.</td></tr>
                                <?php else: foreach ($riwayat as $r): ?>
                                <tr>
                                    <td><?= $r['id_trx'] ?></td>
                                    <td><span class="badge <?= $r['jenis']=='Masuk'?'bg-success':'bg-danger' ?>"><?= $r['jenis'] ?></span></td>
                                    <td><strong><?= htmlspecialchars($r['nama_barang']) ?></strong></td>
                                    <td><?= $r['kategori'] ?></td>
                                    <td><?= $r['jenis']=='Masuk' ? '+' : '-' ?><?= $r['jumlah'] ?></td>
                                    <td><?= htmlspecialchars($r['keterangan']) ?></td>
                                    <td><?= date('d M Y', strtotime($r['tanggal'])) ?></td>
                                    <td>Rp <?= number_format($r['total_nilai'],0,',','.') ?></td>
                                </tr>
                                <?php endforeach; endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>

            <?php endif; ?>
        </div><!-- /col konten -->
    </div><!-- /row -->
</div><!-- /container-fluid -->
<?php endif; ?>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
