#!/bin/bash

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🚀 Memasang proteksi Client Account API (Block ubah password/email admin ID 1)..."
echo ""

# === LANGKAH 1: Cari AccountController untuk Client API ===
CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Api/Client/AccountController.php"

if [ ! -f "$CONTROLLER" ]; then
  CONTROLLER=$(find /var/www/pterodactyl/app/Http/Controllers/Api/Client -maxdepth 1 -iname "AccountController.php" 2>/dev/null | head -1)
fi

if [ -z "$CONTROLLER" ] || [ ! -f "$CONTROLLER" ]; then
  echo "❌ AccountController untuk Client API tidak ditemukan!"
  echo "   Mencari di direktori..."
  find /var/www/pterodactyl/app/Http/Controllers/Api/Client -maxdepth 2 -name "*.php" 2>/dev/null
  exit 1
fi

echo "📂 Controller ditemukan: $CONTROLLER"

# === Restore dari backup paling awal ===
LATEST_BACKUP=$(ls -t "${CONTROLLER}.bak_"* 2>/dev/null | tail -1)

if [ -n "$LATEST_BACKUP" ]; then
  cp "$LATEST_BACKUP" "$CONTROLLER"
  echo "📦 Controller di-restore dari backup paling awal: $LATEST_BACKUP"
else
  echo "⚠️ Tidak ada backup, menggunakan file saat ini"
fi

cp "$CONTROLLER" "${CONTROLLER}.bak_${TIMESTAMP}"

# === LANGKAH 2: Inject proteksi ke method update password & email ===
python3 << PYEOF
import re

controller = "$CONTROLLER"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY_ACCOUNT" in content:
    print("⚠️ Proteksi sudah ada di AccountController")
    exit(0)

# Tambah use Auth jika belum ada
if "use Illuminate\\Support\\Facades\\Auth;" not in content:
    use_pattern = r'(use Pterodactyl\\[^;]+;)'
    match = re.search(use_pattern, content)
    if match:
        content = content.replace(match.group(0), match.group(0) + "\nuse Illuminate\\Support\\Facades\\Auth;", 1)

lines = content.split("\n")
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    
    # Cari method updatePassword, updateEmail, atau update
    if re.search(r'public function (updatePassword|updateEmail|update)\b', line) and '__construct' not in line:
        method_name = re.search(r'public function (\w+)', line).group(1)
        j = i
        while j < len(lines) and '{' not in lines[j]:
            j += 1
            if j > i:
                new_lines.append(lines[j])
        
        # Inject proteksi: block perubahan untuk user ID 1 oleh orang lain
        new_lines.append("        // PROTEKSI_JHONALEY_ACCOUNT: Block ubah data admin ID 1")
        new_lines.append("        \$targetUser = \$request->user();")
        new_lines.append("        if ((int) \$targetUser->id === 1 && (!Auth::user() || (int) Auth::user()->id !== 1)) {")
        new_lines.append("            abort(403, 'Akses ditolak - protect by Jhonaley Tech');")
        new_lines.append("        }")
        
        if j > i:
            i = j
    i += 1

with open(controller, "w") as f:
    f.write("\n".join(new_lines))

print("✅ Proteksi berhasil diinjeksi ke Client AccountController")
PYEOF

echo ""
echo "📋 Verifikasi AccountController (cari PROTEKSI):"
grep -n "PROTEKSI_JHONALEY_ACCOUNT" "$CONTROLLER"
echo ""

# === LANGKAH 3: Proteksi juga di Application API (update user) ===
echo "🔧 Menambahkan proteksi di Application API UserController..."

APP_USER_CTRL="/var/www/pterodactyl/app/Http/Controllers/Api/Application/Users/UserController.php"

if [ ! -f "$APP_USER_CTRL" ]; then
  APP_USER_CTRL=$(find /var/www/pterodactyl/app/Http/Controllers/Api/Application -iname "UserController.php" 2>/dev/null | head -1)
fi

if [ -n "$APP_USER_CTRL" ] && [ -f "$APP_USER_CTRL" ]; then
  echo "📂 Application UserController ditemukan: $APP_USER_CTRL"
  
  APP_BACKUP=$(ls -t "${APP_USER_CTRL}.bak_"* 2>/dev/null | tail -1)
  if [ -n "$APP_BACKUP" ]; then
    cp "$APP_BACKUP" "$APP_USER_CTRL"
    echo "📦 Restore dari backup paling awal: $APP_BACKUP"
  fi
  
  cp "$APP_USER_CTRL" "${APP_USER_CTRL}.bak_${TIMESTAMP}"

  python3 << PYEOF3
import re

controller = "$APP_USER_CTRL"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY_APPUSER" in content:
    print("⚠️ Proteksi sudah ada di Application UserController")
    exit(0)

lines = content.split("\n")
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    
    # Proteksi SEMUA method (index, view, update, delete, store) untuk user ID 1
    if re.search(r'public function (?!__construct)', line):
        method_name = re.search(r'public function (\w+)', line).group(1)
        j = i
        while j < len(lines) and '{' not in lines[j]:
            j += 1
            if j > i:
                new_lines.append(lines[j])
        
        new_lines.append("        // PROTEKSI_JHONALEY_APPUSER: Block semua akses API untuk admin ID 1")
        new_lines.append("        \$reqUser = \$request->route()->parameter('user');")
        new_lines.append("        if (\$reqUser && (int) (is_object(\$reqUser) ? \$reqUser->id : \$reqUser) === 1) {")
        new_lines.append("            abort(403, 'Akses ditolak - protect by Jhonaley Tech');")
        new_lines.append("        }")
        
        if j > i:
            i = j
    i += 1

with open(controller, "w") as f:
    f.write("\n".join(new_lines))

print("✅ Proteksi berhasil diinjeksi ke Application UserController")
PYEOF3

  echo ""
  echo "📋 Verifikasi Application UserController:"
  grep -n "PROTEKSI_JHONALEY_APPUSER" "$APP_USER_CTRL"
else
  echo "⚠️ Application UserController tidak ditemukan, skip."
fi

# === LANGKAH 4: Clear semua cache ===
echo ""
cd /var/www/pterodactyl
php artisan route:clear 2>/dev/null
php artisan config:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
php artisan view:clear 2>/dev/null
echo "✅ Semua cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ Proteksi Client Account API LENGKAP!"
echo "==========================================="
echo "🔒 Password & email admin ID 1 tidak bisa diubah via Client API"
echo "🔒 Admin ID 1 tidak bisa di-update/delete via Application API"
echo "🚀 Panel tetap normal, server tetap jalan"
echo "==========================================="
echo ""
echo "⚠️ Jika ada masalah, restore:"
echo "   cp ${CONTROLLER}.bak_${TIMESTAMP} $CONTROLLER"
if [ -n "$APP_USER_CTRL" ] && [ -f "$APP_USER_CTRL" ]; then
echo "   cp ${APP_USER_CTRL}.bak_${TIMESTAMP} $APP_USER_CTRL"
fi
echo "   cd /var/www/pterodactyl && php artisan route:clear && php artisan cache:clear"
