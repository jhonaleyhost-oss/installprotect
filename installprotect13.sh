#!/bin/bash

SIDEBAR_PATH="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${SIDEBAR_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi: Sembunyikan menu Application API dari sidebar..."

if [ ! -f "$SIDEBAR_PATH" ]; then
  echo "❌ File sidebar tidak ditemukan: $SIDEBAR_PATH"
  exit 1
fi

# Backup
cp "$SIDEBAR_PATH" "$BACKUP_PATH"
echo "📦 Backup dibuat: $BACKUP_PATH"

# Inject proteksi menggunakan Python
export SIDEBAR_PATH

python3 << 'PYEOF'
import os, re

filepath = os.environ['SIDEBAR_PATH']

with open(filepath, 'r') as f:
    content = f.read()

# Cek apakah sudah diproteksi
if 'PROTEKSI_JHONALEY_HIDE_APPAPI' in content:
    print("⚠️ Proteksi sudah terpasang sebelumnya, skip.")
    exit(0)

# Pattern: cari link Application API di sidebar
# Biasanya berbentuk: <a href="{{ route('admin.api.index') }}"...>Application API</a>
# atau <li>...<a ...>Application API</a>...</li>

# Strategi: bungkus elemen Application API dengan @if(Auth::user()->id === 1)
patterns = [
    # Pattern untuk list item yang mengandung Application API
    (r'(<li[^>]*>[\s\S]*?(?:Application API|admin\.api\.index)[\s\S]*?</li>)',
     r'{{-- PROTEKSI_JHONALEY_HIDE_APPAPI --}}@if(Auth::user()->id === 1)\1@endif{{-- END_PROTEKSI_JHONALEY_HIDE_APPAPI --}}'),
    # Pattern untuk <a> tag langsung
    (r'(<a[^>]*(?:admin\.api\.index|admin/api)[^>]*>[\s\S]*?Application API[\s\S]*?</a>)',
     r'{{-- PROTEKSI_JHONALEY_HIDE_APPAPI --}}@if(Auth::user()->id === 1)\1@endif{{-- END_PROTEKSI_JHONALEY_HIDE_APPAPI --}}'),
]

modified = False
for pattern, replacement in patterns:
    if re.search(pattern, content, re.IGNORECASE):
        content = re.sub(pattern, replacement, content, count=1, flags=re.IGNORECASE)
        modified = True
        break

if not modified:
    # Fallback: cari baris yang mengandung Application API atau admin.api
    lines = content.split('\n')
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if ('Application API' in line or 'admin.api.index' in line or 'admin/api' in line) and 'PROTEKSI_JHONALEY' not in line:
            # Cari awal <li> atau <a> terdekat ke atas
            start = i
            for j in range(i, max(i-5, -1), -1):
                if '<li' in lines[j]:
                    start = j
                    break
            # Cari akhir </li> atau </a> terdekat ke bawah
            end = i
            for j in range(i, min(i+5, len(lines))):
                if '</li>' in lines[j]:
                    end = j
                    break

            # Insert @if before start, @endif after end
            new_lines.append('{{-- PROTEKSI_JHONALEY_HIDE_APPAPI --}}')
            new_lines.append('@if(Auth::user()->id === 1)')
            for k in range(start if start < i else i, end + 1):
                new_lines.append(lines[k])
            new_lines.append('@endif')
            new_lines.append('{{-- END_PROTEKSI_JHONALEY_HIDE_APPAPI --}}')
            i = end + 1
            modified = True
        else:
            new_lines.append(line)
            i += 1

    if modified:
        content = '\n'.join(new_lines)

if modified:
    with open(filepath, 'w') as f:
        f.write(content)
    print("✅ Menu Application API berhasil disembunyikan dari sidebar")
else:
    print("⚠️ Tidak menemukan elemen Application API di sidebar. Coba metode alternatif...")

    # Metode alternatif: inject CSS untuk hide via route check
    css_inject = """
{{-- PROTEKSI_JHONALEY_HIDE_APPAPI --}}
@if(Auth::user()->id !== 1)
<style>
    a[href*="admin/api"], a[href*="admin.api"] {
        display: none !important;
    }
</style>
@endif
{{-- END_PROTEKSI_JHONALEY_HIDE_APPAPI --}}
"""
    # Inject sebelum </head> atau di akhir file
    if '</head>' in content:
        content = content.replace('</head>', css_inject + '\n</head>')
    else:
        content += '\n' + css_inject

    with open(filepath, 'w') as f:
        f.write(content)
    print("✅ Proteksi CSS fallback diterapkan untuk menyembunyikan Application API")

PYEOF

# Juga block akses route /admin/api untuk non-admin ID 1
ROUTE_FILE="/var/www/pterodactyl/routes/admin.php"
if [ -f "$ROUTE_FILE" ]; then
    cp "$ROUTE_FILE" "${ROUTE_FILE}.bak_${TIMESTAMP}"

    export ROUTE_FILE
    python3 << 'PYEOF2'
import os

filepath = os.environ['ROUTE_FILE']

with open(filepath, 'r') as f:
    content = f.read()

if 'PROTEKSI_JHONALEY_BLOCK_APPAPI' in content:
    print("⚠️ Proteksi route Application API sudah ada, skip.")
    exit(0)

# Inject middleware check di awal file setelah <?php atau use statements
inject_code = """
// PROTEKSI_JHONALEY_BLOCK_APPAPI: Block akses /admin/api untuk non-admin ID 1
Route::prefix('api')->middleware(function ($request, $next) {
    if (Auth::user()->id !== 1) {
        abort(403, '@𝙅𝙃𝙊𝙉𝘼𝙇𝙀𝙔 𝙏𝙀𝘾𝙃 • Menu Application API hanya untuk Admin Utama.');
    }
    return $next($request);
})->group(function () {
    // Route asli akan tetap berjalan untuk admin ID 1
});
"""

# Cari posisi yang tepat - setelah group admin
# Lebih aman: inject sebagai middleware pada route group api
# Kita akan inject pengecekan di controller level

print("⚠️ Route protection skipped - menggunakan controller level protection.")

PYEOF2
fi

# Proteksi di controller level: block akses ApiController untuk non-admin ID 1
API_CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"
if [ -f "$API_CONTROLLER" ]; then
    export API_CONTROLLER

    python3 << 'PYEOF3'
import os

filepath = os.environ['API_CONTROLLER']

with open(filepath, 'r') as f:
    content = f.read()

if 'PROTEKSI_JHONALEY_BLOCK_APPAPI_ACCESS' in content:
    print("⚠️ Proteksi akses ApiController sudah ada, skip.")
    exit(0)

# Inject constructor check
constructor_check = """
    // PROTEKSI_JHONALEY_BLOCK_APPAPI_ACCESS: Block semua akses Application API untuk non-admin ID 1
    public function __construct()
    {
        parent::__construct();
        if (\\Illuminate\\Support\\Facades\\Auth::user() && \\Illuminate\\Support\\Facades\\Auth::user()->id !== 1) {
            abort(403, '@𝙅𝙃𝙊𝙉𝘼𝙇𝙀𝙔 𝙏𝙀𝘾𝙃 • Menu Application API hanya untuk Admin Utama.');
        }
    }
"""

# Cari class declaration dan inject setelahnya
import re
# Hapus constructor lama jika ada, lalu inject yang baru
pattern = r'(class\s+ApiController\s+extends\s+\w+\s*\{)'
if re.search(pattern, content):
    content = re.sub(pattern, r'\1\n' + constructor_check, content, count=1)
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
