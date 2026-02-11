#!/bin/bash

CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeViewController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🚀 Memasang proteksi Anti Akses Node View..."

# === LANGKAH 1: Restore dari backup terakhir ===
LATEST_BACKUP=$(ls -t "${CONTROLLER}.bak_"* 2>/dev/null | head -1)

if [ -n "$LATEST_BACKUP" ]; then
  cp "$LATEST_BACKUP" "$CONTROLLER"
  echo "📦 File di-restore dari backup: $LATEST_BACKUP"
else
  echo "⚠️ Tidak ada backup ditemukan, menggunakan file saat ini"
fi

# Backup lagi sebelum modifikasi
cp "$CONTROLLER" "${CONTROLLER}.bak_${TIMESTAMP}"

# === LANGKAH 2: Cek isi file saat ini ===
echo ""
echo "📋 Isi 5 baris pertama file:"
head -5 "$CONTROLLER"
echo "..."
echo ""

# === LANGKAH 3: Buat file middleware terpisah ===
MIDDLEWARE="/var/www/pterodactyl/app/Http/Middleware/NodeProtect.php"

cat > "$MIDDLEWARE" << 'EOF'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class NodeProtect
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user || (int) $user->id !== 1) {
            abort(403, 'Akses ditolak - protect by Jhonaley Tech');
        }
        return $next($request);
    }
}
EOF

chmod 644 "$MIDDLEWARE"
echo "✅ Middleware NodeProtect dibuat"

# === LANGKAH 4: Daftarkan di Kernel.php ===
KERNEL="/var/www/pterodactyl/app/Http/Kernel.php"
cp "$KERNEL" "${KERNEL}.bak_${TIMESTAMP}"

if ! grep -q "'node.protect'" "$KERNEL"; then
  # Cari baris yang mengandung 'admin' => di routeMiddleware dan tambahkan setelahnya
  sed -i "/'admin' =>/a\\        'node.protect' => \\\\Pterodactyl\\\\Http\\\\Middleware\\\\NodeProtect::class," "$KERNEL"
  
  if grep -q "'node.protect'" "$KERNEL"; then
    echo "✅ Middleware didaftarkan di Kernel.php"
  else
    echo "❌ Gagal daftarkan middleware di Kernel. Coba manual."
    echo "   Tambahkan baris ini di \$routeMiddleware di app/Http/Kernel.php:"
    echo "   'node.protect' => \\Pterodactyl\\Http\\Middleware\\NodeProtect::class,"
  fi
else
  echo "⚠️ Middleware sudah terdaftar"
fi

# === LANGKAH 5: Tambahkan middleware ke route ===
ROUTES="/var/www/pterodactyl/routes/admin.php"
cp "$ROUTES" "${ROUTES}.bak_${TIMESTAMP}"

echo ""
echo "📋 Mencari route nodes view di routes/admin.php..."
grep -n "nodes" "$ROUTES" | head -20
echo ""

# Cari pattern route group untuk node view
# Biasanya: Route::group(['prefix' => '/nodes/view/{node}'], function () {
# Kita tambahkan middleware ke group tersebut

if ! grep -q "node.protect" "$ROUTES"; then
  # Coba beberapa pattern yang umum di Pterodactyl
  
  # Pattern 1: nodes/view group
  sed -i "s|'prefix' => '/nodes/view/{node}'|'prefix' => '/nodes/view/{node}', 'middleware' => 'node.protect'|g" "$ROUTES"
  
  # Pattern 2: nodes/view/{node} tanpa prefix
  sed -i "s|'prefix' => 'nodes/view/{node}'|'prefix' => 'nodes/view/{node}', 'middleware' => 'node.protect'|g" "$ROUTES"
  
  # Pattern 3: cek apakah berhasil
  if grep -q "node.protect" "$ROUTES"; then
    echo "✅ Middleware ditambahkan ke route nodes view"
  else
    echo "⚠️ Pattern route tidak cocok. Menampilkan route terkait nodes:"
    grep -n -A2 -B2 "node" "$ROUTES" | head -40
    echo ""
    echo "❗ Tambahkan middleware MANUAL di routes/admin.php:"
    echo "   Cari group route untuk nodes view, tambahkan: 'middleware' => 'node.protect'"
    echo ""
    echo "   Atau tambahkan di controller constructor:"
    echo "   \$this->middleware(\\Pterodactyl\\Http\\Middleware\\NodeProtect::class);"
  fi
else
  echo "⚠️ Middleware sudah ada di routes"
fi

# === LANGKAH 6: Clear cache ===
cd /var/www/pterodactyl
php artisan route:clear 2>/dev/null
php artisan config:clear 2>/dev/null  
php artisan cache:clear 2>/dev/null
php artisan view:clear 2>/dev/null
echo "✅ Cache dibersihkan"

echo ""
echo "========================================="
echo "✅ Proteksi Node View selesai!"
echo "🔒 Hanya Admin ID 1 yang bisa akses"
echo "========================================="
echo ""
echo "⚠️ Jika masih 500 error, restore SEMUA file:"
echo "   cp ${CONTROLLER}.bak_${TIMESTAMP} $CONTROLLER"
echo "   cp ${KERNEL}.bak_${TIMESTAMP} $KERNEL"  
echo "   cp ${ROUTES}.bak_${TIMESTAMP} $ROUTES"
echo "   cd /var/www/pterodactyl && php artisan route:clear && php artisan config:clear"
