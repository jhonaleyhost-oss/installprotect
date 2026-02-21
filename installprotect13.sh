#!/bin/bash

SIDEBAR_PATH="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
API_CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🚀 Memasang proteksi: Sembunyikan menu Application API..."

# ============================================
# STEP 1: Restore sidebar dari backup terbaru
# ============================================
if [ -f "$SIDEBAR_PATH" ]; then
    LATEST_BAK=$(ls -t "${SIDEBAR_PATH}".bak_* 2>/dev/null | head -1)
    if [ -n "$LATEST_BAK" ]; then
        echo "🔄 Restore sidebar dari backup: $LATEST_BAK"
        cp "$LATEST_BAK" "$SIDEBAR_PATH"
    fi
    # Backup bersih
    cp "$SIDEBAR_PATH" "${SIDEBAR_PATH}.bak_${TIMESTAMP}"
    echo "📦 Backup sidebar dibuat"
else
    echo "❌ File sidebar tidak ditemukan: $SIDEBAR_PATH"
    exit 1
fi

# Bersihkan proteksi lama yang mungkin merusak
sed -i '/PROTEKSI_JHONALEY_HIDE_APPAPI/d' "$SIDEBAR_PATH"
sed -i '/PROTEKSI_JHONALEY_BLOCK_APPAPI/d' "$SIDEBAR_PATH"

# ============================================
# STEP 2: Inject CSS hide (aman, tidak ubah struktur HTML)
# ============================================
INJECT_CSS='{{-- PROTEKSI_JHONALEY_HIDE_APPAPI_START --}}
@if(Auth::user()->id !== 1)
<style>a[href*="/admin/api"]{display:none !important;}</style>
@endif
{{-- PROTEKSI_JHONALEY_HIDE_APPAPI_END --}}'

# Cek apakah sudah ada
if grep -q "PROTEKSI_JHONALEY_HIDE_APPAPI_START" "$SIDEBAR_PATH"; then
    echo "⚠️ CSS proteksi sudah ada di sidebar, skip."
else
    # Inject sebelum </head>
    sed -i "/<\/head>/i\\${INJECT_CSS}" "$SIDEBAR_PATH"
    echo "✅ Menu Application API disembunyikan dari sidebar (CSS)"
fi

# ============================================
# STEP 3: Proteksi ApiController (block akses non-admin ID 1)
# ============================================
if [ -f "$API_CONTROLLER" ]; then
    # Restore dari backup terbaru
    LATEST_API_BAK=$(ls -t "${API_CONTROLLER}".bak_* 2>/dev/null | head -1)
    if [ -n "$LATEST_API_BAK" ]; then
        echo "🔄 Restore ApiController dari backup"
        cp "$LATEST_API_BAK" "$API_CONTROLLER"
    fi
    cp "$API_CONTROLLER" "${API_CONTROLLER}.bak_${TIMESTAMP}"

    if grep -q "PROTEKSI_JHONALEY_BLOCK_APPAPI_ACCESS" "$API_CONTROLLER"; then
        echo "⚠️ Proteksi ApiController sudah ada, skip."
    else
        # Inject middleware di constructor menggunakan sed (tanpa Python regex)
        # Cari baris "class ApiController" dan tambahkan constructor setelahnya
        sed -i '/class ApiController extends Controller/a\
\
    \/\/ PROTEKSI_JHONALEY_BLOCK_APPAPI_ACCESS\
    public function __construct()\
    {\
        $this->middleware(function ($request, $next) {\
            if (\\Illuminate\\Support\\Facades\\Auth::user() \\&\\& \\Illuminate\\Support\\Facades\\Auth::user()->id !== 1) {\
                abort(403, '"'"'Akses Application API hanya untuk Admin Utama.'"'"');\
            }\
            return $next($request);\
        });\
    }' "$API_CONTROLLER"

        echo "✅ Proteksi akses ApiController berhasil diterapkan"
    fi
else
    echo "⚠️ ApiController tidak ditemukan: $API_CONTROLLER"
fi

# ============================================
# STEP 4: Clear cache
# ============================================
cd /var/www/pterodactyl
php artisan view:clear 2>/dev/null
php artisan route:clear 2>/dev/null
php artisan config:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
echo "✅ Cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ PROTEKSI APPLICATION API BERHASIL!"
echo "==========================================="
echo "🔒 Menu Application API disembunyikan dari sidebar (selain ID 1)"
echo "🔒 Akses /admin/api diblock untuk non-admin ID 1"
echo "==========================================="
echo ""
echo "⚠️ Jika ada masalah, restore:"
echo "   cp ${SIDEBAR_PATH}.bak_${TIMESTAMP} $SIDEBAR_PATH"
echo "   cp ${API_CONTROLLER}.bak_${TIMESTAMP} $API_CONTROLLER"
echo "   cd /var/www/pterodactyl && php artisan view:clear && php artisan route:clear"
