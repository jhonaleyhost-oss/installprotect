#!/bin/bash

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🚀 Memasang proteksi Anti Akses Node View..."

# === LANGKAH 1: Buat Middleware ===
MIDDLEWARE_PATH="/var/www/pterodactyl/app/Http/Middleware/AdminOnlyMiddleware.php"

if [ -f "$MIDDLEWARE_PATH" ]; then
  cp "$MIDDLEWARE_PATH" "${MIDDLEWARE_PATH}.bak_${TIMESTAMP}"
fi

cat > "$MIDDLEWARE_PATH" << 'MEOF'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminOnlyMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = Auth::user();

        if (!$user || (int) $user->id !== 1) {
            abort(403, 'Akses ditolak - protect by Jhonaley Tech');
        }

        return $next($request);
    }
}
MEOF

chmod 644 "$MIDDLEWARE_PATH"
echo "✅ Middleware AdminOnlyMiddleware berhasil dibuat"

# === LANGKAH 2: Daftarkan middleware di Kernel.php ===
KERNEL_PATH="/var/www/pterodactyl/app/Http/Kernel.php"

if [ -f "$KERNEL_PATH" ]; then
  cp "$KERNEL_PATH" "${KERNEL_PATH}.bak_${TIMESTAMP}"

  # Cek apakah sudah terdaftar
  if ! grep -q "admin.only" "$KERNEL_PATH"; then
    # Tambahkan ke $routeMiddleware array
    sed -i "/'auth' =>/a\\        'admin.only' => \\\\Pterodactyl\\\\Http\\\\Middleware\\\\AdminOnlyMiddleware::class," "$KERNEL_PATH"
    echo "✅ Middleware didaftarkan di Kernel.php"
  else
    echo "⚠️ Middleware sudah terdaftar di Kernel.php"
  fi
else
  echo "❌ Kernel.php tidak ditemukan!"
  exit 1
fi

# === LANGKAH 3: Tambahkan middleware ke route node view ===
ROUTES_PATH="/var/www/pterodactyl/routes/admin.php"

if [ -f "$ROUTES_PATH" ]; then
  cp "$ROUTES_PATH" "${ROUTES_PATH}.bak_${TIMESTAMP}"

  # Cek apakah sudah ada middleware admin.only di route nodes view
  if ! grep -q "admin.only" "$ROUTES_PATH"; then
    # Cari route group untuk nodes view dan tambahkan middleware
    # Pendekatan: wrap semua route nodes/view dengan middleware tambahan
    sed -i "/Route.*admin\.nodes\.view/,/);/{
      s/->group(function/->middleware('admin.only')->group(function/
    }" "$ROUTES_PATH"

    # Jika sed tidak berhasil (pattern tidak cocok), coba cara lain
    if ! grep -q "admin.only" "$ROUTES_PATH"; then
      echo "⚠️ Tidak bisa inject otomatis ke routes. Menggunakan cara alternatif..."

      # Restore dan gunakan pendekatan controller langsung
      cp "${ROUTES_PATH}.bak_${TIMESTAMP}" "$ROUTES_PATH"

      # === CARA ALTERNATIF: Patch controller langsung ===
      CONTROLLER_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeViewController.php"

      if [ -f "$CONTROLLER_PATH" ]; then
        cp "$CONTROLLER_PATH" "${CONTROLLER_PATH}.bak_${TIMESTAMP}"

        # Tambahkan use Auth jika belum ada
        if ! grep -q "use Illuminate\\\\Support\\\\Facades\\\\Auth;" "$CONTROLLER_PATH"; then
          sed -i '/^namespace /a use Illuminate\\Support\\Facades\\Auth;' "$CONTROLLER_PATH"
        fi

        # Tambahkan middleware di constructor
        if ! grep -q "PROTEKSI_JHONALEY" "$CONTROLLER_PATH"; then
          # Cari __construct dan tambahkan middleware di dalamnya
          sed -i '/__construct/,/{/{
            /{/a\        // PROTEKSI_JHONALEY\n        $this->middleware(function ($request, $next) {\n            if ((int) $request->user()->id !== 1) {\n                abort(403, '"'"'Akses ditolak - protect by Jhonaley Tech'"'"');\n            }\n            return $next($request);\n        });
          }' "$CONTROLLER_PATH"
        fi

        chmod 644 "$CONTROLLER_PATH"
        echo "✅ Proteksi diinjeksi langsung ke constructor NodeViewController"
      else
        echo "❌ NodeViewController.php tidak ditemukan!"
        exit 1
      fi
    else
      echo "✅ Middleware berhasil ditambahkan ke routes"
    fi
  else
    echo "⚠️ Middleware sudah ada di routes"
  fi
else
  echo "❌ File routes/admin.php tidak ditemukan!"
  exit 1
fi

# === LANGKAH 4: Clear cache ===
cd /var/www/pterodactyl
php artisan route:clear 2>/dev/null
php artisan config:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
echo "✅ Cache dibersihkan"

echo ""
echo "✅ Proteksi Anti Akses Node View berhasil dipasang!"
echo "🔒 Hanya Admin ID 1 yang bisa akses Node View"
echo ""
echo "⚠️ Jika ada error, restore dengan:"
echo "   cp ${KERNEL_PATH}.bak_${TIMESTAMP} $KERNEL_PATH"
echo "   php artisan route:clear && php artisan config:clear"
