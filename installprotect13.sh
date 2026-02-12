#!/bin/bash

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🚀 Memasang proteksi Application API (Sembunyikan + Block Akses)..."
echo ""

# === LANGKAH 1: Restore ApplicationApiController dari backup asli ===
CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"

# Cari file controller yang tepat
if [ ! -f "$CONTROLLER" ]; then
  CONTROLLER=$(find /var/www/pterodactyl/app/Http/Controllers/Admin -maxdepth 1 -iname "*api*" -name "*.php" 2>/dev/null | head -1)
fi

if [ -z "$CONTROLLER" ] || [ ! -f "$CONTROLLER" ]; then
  echo "❌ Controller Application API tidak ditemukan!"
  echo "   Mencari di direktori Admin..."
  find /var/www/pterodactyl/app/Http/Controllers/Admin -maxdepth 2 -name "*.php" | grep -i api
  exit 1
fi

echo "📂 Controller ditemukan: $CONTROLLER"

LATEST_BACKUP=$(ls -t "${CONTROLLER}.bak_"* 2>/dev/null | tail -1)

if [ -n "$LATEST_BACKUP" ]; then
  cp "$LATEST_BACKUP" "$CONTROLLER"
  echo "📦 Controller di-restore dari backup paling awal: $LATEST_BACKUP"
else
  echo "⚠️ Tidak ada backup, menggunakan file saat ini"
fi

cp "$CONTROLLER" "${CONTROLLER}.bak_${TIMESTAMP}"

# === LANGKAH 2: Inject proteksi ke ApiController ===
python3 << PYEOF
import re

controller = "$CONTROLLER"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY" in content:
    print("⚠️ Proteksi sudah ada di ApiController")
    exit(0)

if "use Illuminate\\Support\\Facades\\Auth;" not in content:
    # Cari use statement yang ada untuk inject setelahnya
    use_pattern = r'(use Pterodactyl\\Http\\Controllers\\Controller;)'
    if re.search(use_pattern, content):
        content = re.sub(use_pattern, r'\1\nuse Illuminate\\Support\\Facades\\Auth;', content)
    else:
        # Fallback: cari use statement terakhir
        content = re.sub(r'(use [^;]+;)(\s*class )', r'\1\nuse Illuminate\\Support\\Facades\\Auth;\2', content)

lines = content.split("\n")
new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    
    if re.search(r'public function (?!__construct)', line):
        j = i
        while j < len(lines) and '{' not in lines[j]:
            j += 1
            if j > i:
                new_lines.append(lines[j])
        
        new_lines.append("        // PROTEKSI_JHONALEY: Hanya admin ID 1")
        new_lines.append("        if (!Auth::user() || (int) Auth::user()->id !== 1) {")
        new_lines.append("            abort(403, 'Akses ditolak - protect by Jhonaley Tech');")
        new_lines.append("        }")
        
        if j > i:
            i = j
    i += 1

with open(controller, "w") as f:
    f.write("\n".join(new_lines))

print("✅ Proteksi berhasil diinjeksi ke ApiController")
PYEOF

echo ""
echo "📋 Verifikasi ApiController (cari PROTEKSI):"
grep -n "PROTEKSI_JHONALEY" "$CONTROLLER"
echo ""

# === LANGKAH 3: Sembunyikan menu Application API di sidebar ===
echo "🔧 Menyembunyikan menu Application API dari sidebar..."

SIDEBAR_FILES=(
  "/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
  "/var/www/pterodactyl/resources/views/partials/admin/sidebar.blade.php"
)

SIDEBAR_FOUND=""
for SF in "${SIDEBAR_FILES[@]}"; do
  if [ -f "$SF" ]; then
    SIDEBAR_FOUND="$SF"
    break
  fi
done

if [ -z "$SIDEBAR_FOUND" ]; then
  SIDEBAR_FOUND=$(grep -rl "admin.api" /var/www/pterodactyl/resources/views/layouts/ 2>/dev/null | head -1)
  if [ -z "$SIDEBAR_FOUND" ]; then
    SIDEBAR_FOUND=$(grep -rl "admin.api" /var/www/pterodactyl/resources/views/partials/ 2>/dev/null | head -1)
  fi
fi

if [ -n "$SIDEBAR_FOUND" ]; then
  if [ ! -f "${SIDEBAR_FOUND}.bak_${TIMESTAMP}" ]; then
    cp "$SIDEBAR_FOUND" "${SIDEBAR_FOUND}.bak_${TIMESTAMP}"
  fi
  echo "📂 Sidebar ditemukan: $SIDEBAR_FOUND"

  echo "📋 Baris terkait API di sidebar:"
  grep -n -i "api" "$SIDEBAR_FOUND" | grep -i "application\|admin.api" | head -10
  echo ""

  python3 << PYEOF2
sidebar = "$SIDEBAR_FOUND"

with open(sidebar, "r") as f:
    content = f.read()

if "PROTEKSI_API_SIDEBAR" in content:
    print("⚠️ Sidebar Application API sudah diproteksi")
    exit(0)

import re

lines = content.split("\n")
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]

    # Cari baris yang mengandung referensi ke application api menu
    if ('admin.api' in line or "route('admin.api')" in line or 'Application API' in line) and 'PROTEKSI' not in line:
        # Mundur ke baris <li> terdekat
        li_start = len(new_lines) - 1
        while li_start >= 0 and '<li' not in new_lines[li_start]:
            li_start -= 1

        if li_start >= 0:
            new_lines.insert(li_start, "{{-- PROTEKSI_API_SIDEBAR --}}")
            new_lines.insert(li_start, "@if((int) Auth::user()->id === 1)")

            new_lines.append(line)
            i += 1

            # Cari </li> penutup
            li_depth = 1
            while i < len(lines) and li_depth > 0:
                curr = lines[i]
                li_depth += curr.count('<li') - curr.count('</li')
                new_lines.append(curr)
                i += 1

            new_lines.append("@endif")
            continue

    new_lines.append(line)
    i += 1

with open(sidebar, "w") as f:
    f.write("\n".join(new_lines))

print("✅ Menu Application API disembunyikan dari sidebar")
PYEOF2

else
  echo "⚠️ File sidebar tidak ditemukan."
fi

# === LANGKAH 4: Clear semua cache ===
cd /var/www/pterodactyl
php artisan route:clear 2>/dev/null
php artisan config:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
php artisan view:clear 2>/dev/null
echo "✅ Semua cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ Proteksi Application API LENGKAP selesai!"
echo "==========================================="
echo "🔒 Menu Application API disembunyikan dari sidebar (selain ID 1)"
echo "🔒 Akses /admin/api diblock (selain ID 1)"
echo "🚀 Panel tetap normal, server tetap jalan"
echo "==========================================="
echo ""
echo "⚠️ Jika ada masalah, restore:"
echo "   cp ${CONTROLLER}.bak_${TIMESTAMP} $CONTROLLER"
if [ -n "$SIDEBAR_FOUND" ]; then
echo "   cp ${SIDEBAR_FOUND}.bak_${TIMESTAMP} $SIDEBAR_FOUND"
fi
echo "   cd /var/www/pterodactyl && php artisan view:clear && php artisan route:clear"
