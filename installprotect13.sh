#!/bin/bash

SIDEBAR_PATH="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${SIDEBAR_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi: Sembunyikan menu Application API..."

# Step 1: Restore sidebar dari backup terakhir jika rusak
LATEST_BAK=$(ls -t "${SIDEBAR_PATH}".bak_* 2>/dev/null | head -1)
if [ -n "$LATEST_BAK" ]; then
  echo "🔄 Restore sidebar dari backup: $LATEST_BAK"
  cp "$LATEST_BAK" "$SIDEBAR_PATH"
fi

if [ ! -f "$SIDEBAR_PATH" ]; then
  echo "❌ File sidebar tidak ditemukan: $SIDEBAR_PATH"
  exit 1
fi

# Backup bersih
cp "$SIDEBAR_PATH" "$BACKUP_PATH"
echo "📦 Backup dibuat: $BACKUP_PATH"

# Hapus proteksi lama jika ada (bersihkan dulu)
export SIDEBAR_PATH
python3 << 'PYEOF'
import os, re
filepath = os.environ['SIDEBAR_PATH']
with open(filepath, 'r') as f:
    content = f.read()
# Hapus blok proteksi lama
content = re.sub(r'\{\{-- PROTEKSI_JHONALEY_HIDE_APPAPI --\}\}.*?\{\{-- END_PROTEKSI_JHONALEY_HIDE_APPAPI --\}\}\s*', '', content, flags=re.DOTALL)
with open(filepath, 'w') as f:
    f.write(content)
print("✅ Proteksi lama dibersihkan")
PYEOF

# Step 2: Inject CSS + JS untuk hide menu Application API (metode aman, tidak ubah struktur HTML)
python3 << 'PYEOF2'
import os
filepath = os.environ['SIDEBAR_PATH']
with open(filepath, 'r') as f:
    content = f.read()

if 'PROTEKSI_JHONALEY_HIDE_APPAPI' in content:
    print("⚠️ Proteksi sudah ada, skip.")
    exit(0)

# Inject sebelum </head> - hanya CSS/JS, tidak mengubah struktur sidebar
inject = """
{{-- PROTEKSI_JHONALEY_HIDE_APPAPI --}}
@if(Auth::user()->id !== 1)
<style>
    /* Sembunyikan menu Application API dari sidebar */
    a[href*="/admin/api"] { display: none !important; }
</style>
@endif
{{-- END_PROTEKSI_JHONALEY_HIDE_APPAPI --}}
"""

if '</head>' in content:
    content = content.replace('</head>', inject + '\n</head>')
elif '</body>' in content:
    content = content.replace('</body>', inject + '\n</body>')
else:
    content += '\n' + inject

with open(filepath, 'w') as f:
    f.write(content)
print("✅ Proteksi CSS berhasil diterapkan (sidebar tidak diubah strukturnya)")
PYEOF2

# Step 3: Proteksi di ApiController - block akses untuk non-admin ID 1
API_CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"
if [ -f "$API_CONTROLLER" ]; then
    # Restore dari backup terbaru dulu
    LATEST_API_BAK=$(ls -t "${API_CONTROLLER}".bak_* 2>/dev/null | head -1)
    if [ -n "$LATEST_API_BAK" ]; then
        cp "$LATEST_API_BAK" "$API_CONTROLLER"
        echo "🔄 Restore ApiController dari backup"
    fi

    cp "$API_CONTROLLER" "${API_CONTROLLER}.bak_${TIMESTAMP}"
    export API_CONTROLLER

    python3 << 'PYEOF3'
import os, re
filepath = os.environ['API_CONTROLLER']
with open(filepath, 'r') as f:
    content = f.read()

if 'PROTEKSI_JHONALEY_BLOCK_APPAPI_ACCESS' in content:
    print("⚠️ Proteksi ApiController sudah ada, skip.")
    exit(0)

# Tambahkan use Auth jika belum ada
if 'use Illuminate\\Support\\Facades\\Auth;' not in content:
    content = content.replace(
        'use Illuminate\\Http\\RedirectResponse;',
        'use Illuminate\\Http\\RedirectResponse;\nuse Illuminate\\Support\\Facades\\Auth;'
    )
    if 'use Illuminate\\Support\\Facades\\Auth;' not in content:
        # fallback: tambah setelah namespace
        content = re.sub(
            r'(namespace [^;]+;)',
            r'\1\n\nuse Illuminate\\Support\\Facades\\Auth;',
            content, count=1
        )

# Inject pengecekan di awal setiap method public
# Cara paling aman: tambah method __construct dengan middleware check
check_code = """
    // PROTEKSI_JHONALEY_BLOCK_APPAPI_ACCESS
    public function __construct()
    {
        parent::__construct();
        $this->middleware(function ($request, $next) {
            if (Auth::user() && Auth::user()->id !== 1) {
                abort(403, 'Akses Application API hanya untuk Admin Utama.');
            }
            return $next($request);
        });
    }
"""

# Cari class body dan inject constructor
match = re.search(r'(class\s+ApiController\s+extends\s+\w+\s*\{)', content)
if match:
    pos = match.end()
    content = content[:pos] + '\n' + check_code + content[pos:]
    with open(filepath, 'w') as f:
        f.write(content)
    print("✅ Proteksi akses ApiController berhasil diterapkan")
else:
    print("❌ Tidak menemukan class ApiController")
PYEOF3
fi

# Clear cache
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
echo "📂 Backup sidebar: $BACKUP_PATH"
echo "==========================================="
echo ""
echo "⚠️ Jika ada masalah, restore:"
echo "   cp $BACKUP_PATH $SIDEBAR_PATH"
echo "   cd /var/www/pterodactyl && php artisan view:clear && php artisan route:clear"
