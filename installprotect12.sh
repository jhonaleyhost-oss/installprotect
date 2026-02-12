#!/bin/bash

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🚀 Memasang proteksi Nodes + Client Account API + Application API User..."
echo ""

# ===================================================================
# BAGIAN 1: PROTEKSI NODES (Sembunyikan + Block Akses)
# ===================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 BAGIAN 1: Proteksi Nodes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# === Restore & proteksi NodeViewController ===
CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeViewController.php"
LATEST_BACKUP=$(ls -t "${CONTROLLER}.bak_"* 2>/dev/null | tail -1)

if [ -n "$LATEST_BACKUP" ]; then
  cp "$LATEST_BACKUP" "$CONTROLLER"
  echo "📦 NodeViewController di-restore dari backup: $LATEST_BACKUP"
else
  echo "⚠️ Tidak ada backup NodeViewController, menggunakan file saat ini"
fi

cp "$CONTROLLER" "${CONTROLLER}.bak_${TIMESTAMP}"

python3 << 'PYEOF'
import re

controller = "/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeViewController.php"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY" in content:
    print("⚠️ Proteksi sudah ada di NodeViewController")
    exit(0)

if "use Illuminate\\Support\\Facades\\Auth;" not in content:
    content = content.replace(
        "use Pterodactyl\\Http\\Controllers\\Controller;",
        "use Pterodactyl\\Http\\Controllers\\Controller;\nuse Illuminate\\Support\\Facades\\Auth;"
    )

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

print("✅ Proteksi berhasil diinjeksi ke NodeViewController")
PYEOF

echo ""
grep -n "PROTEKSI_JHONALEY" "$CONTROLLER"

# === Sembunyikan menu Nodes di sidebar ===
echo ""
echo "🔧 Menyembunyikan menu Nodes dari sidebar..."

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
  SIDEBAR_FOUND=$(grep -rl "admin.nodes" /var/www/pterodactyl/resources/views/layouts/ 2>/dev/null | head -1)
  if [ -z "$SIDEBAR_FOUND" ]; then
    SIDEBAR_FOUND=$(grep -rl "admin.nodes" /var/www/pterodactyl/resources/views/partials/ 2>/dev/null | head -1)
  fi
fi

if [ -n "$SIDEBAR_FOUND" ]; then
  if [ ! -f "${SIDEBAR_FOUND}.bak_${TIMESTAMP}" ]; then
    cp "$SIDEBAR_FOUND" "${SIDEBAR_FOUND}.bak_${TIMESTAMP}"
  fi
  echo "📂 Sidebar ditemukan: $SIDEBAR_FOUND"

  python3 << PYEOF2
sidebar = "$SIDEBAR_FOUND"

with open(sidebar, "r") as f:
    content = f.read()

if "PROTEKSI_NODES_SIDEBAR" in content:
    print("⚠️ Sidebar Nodes sudah diproteksi")
    exit(0)

import re

lines = content.split("\n")
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]

    if ('admin.nodes' in line or "route('admin.nodes')" in line) and 'admin.nodes.view' not in line:
        li_start = len(new_lines) - 1
        while li_start >= 0 and '<li' not in new_lines[li_start]:
            li_start -= 1

        if li_start >= 0:
            new_lines.insert(li_start, "{{-- PROTEKSI_NODES_SIDEBAR --}}")
            new_lines.insert(li_start, "@if((int) Auth::user()->id === 1)")

            new_lines.append(line)
            i += 1

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

print("✅ Menu Nodes disembunyikan dari sidebar")
PYEOF2

else
  echo "⚠️ File sidebar tidak ditemukan."
fi

# === Proteksi NodeController (halaman list nodes) ===
NODE_LIST="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
if [ -f "$NODE_LIST" ]; then
  if ! grep -q "PROTEKSI_JHONALEY" "$NODE_LIST"; then
    cp "$NODE_LIST" "${NODE_LIST}.bak_${TIMESTAMP}"
    
    python3 << 'PYEOF3'
controller = "/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY" in content:
    print("⚠️ Sudah ada proteksi")
    exit(0)

if "use Illuminate\\Support\\Facades\\Auth;" not in content:
    content = content.replace(
        "use Pterodactyl\\Http\\Controllers\\Controller;",
        "use Pterodactyl\\Http\\Controllers\\Controller;\nuse Illuminate\\Support\\Facades\\Auth;"
    )

import re
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

print("✅ NodeController juga diproteksi")
PYEOF3
  else
    echo "⚠️ NodeController sudah diproteksi"
  fi
fi

echo ""
echo "✅ BAGIAN 1 SELESAI: Proteksi Nodes terpasang"
echo ""

# ===================================================================
# BAGIAN 2: PROTEKSI CLIENT ACCOUNT API (Block ubah password/email admin ID 1)
# ===================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 BAGIAN 2: Proteksi Client Account API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ACCT_CTRL="/var/www/pterodactyl/app/Http/Controllers/Api/Client/AccountController.php"

if [ ! -f "$ACCT_CTRL" ]; then
  ACCT_CTRL=$(find /var/www/pterodactyl/app/Http/Controllers/Api/Client -maxdepth 1 -iname "AccountController.php" 2>/dev/null | head -1)
fi

if [ -n "$ACCT_CTRL" ] && [ -f "$ACCT_CTRL" ]; then
  echo "📂 Client AccountController ditemukan: $ACCT_CTRL"

  ACCT_BACKUP=$(ls -t "${ACCT_CTRL}.bak_"* 2>/dev/null | tail -1)
  if [ -n "$ACCT_BACKUP" ]; then
    cp "$ACCT_BACKUP" "$ACCT_CTRL"
    echo "📦 Restore dari backup: $ACCT_BACKUP"
  fi

  cp "$ACCT_CTRL" "${ACCT_CTRL}.bak_${TIMESTAMP}"

  python3 << PYEOF4
import re

controller = "$ACCT_CTRL"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY_ACCOUNT" in content:
    print("⚠️ Proteksi sudah ada di AccountController")
    exit(0)

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
    
    if re.search(r'public function (updatePassword|updateEmail|update)\b', line) and '__construct' not in line:
        j = i
        while j < len(lines) and '{' not in lines[j]:
            j += 1
            if j > i:
                new_lines.append(lines[j])
        
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
PYEOF4

  echo ""
  grep -n "PROTEKSI_JHONALEY_ACCOUNT" "$ACCT_CTRL"
else
  echo "⚠️ Client AccountController tidak ditemukan, skip."
fi

echo ""
echo "✅ BAGIAN 2 SELESAI: Proteksi Client Account API terpasang"
echo ""

# ===================================================================
# BAGIAN 3: PROTEKSI APPLICATION API USER via MIDDLEWARE
# (Block akses data admin ID 1 SEBELUM validasi Form Request)
# ===================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 BAGIAN 3: Proteksi Application API User (Middleware)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# === LANGKAH 3a: Buat Middleware file ===
MIDDLEWARE_DIR="/var/www/pterodactyl/app/Http/Middleware"
MIDDLEWARE_FILE="${MIDDLEWARE_DIR}/ProtectAdminUser.php"

cat > "$MIDDLEWARE_FILE" << 'MWEOF'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ProtectAdminUser
{
    /**
     * PROTEKSI_JHONALEY_MIDDLEWARE: Block semua akses API ke User ID 1
     * Middleware ini jalan SEBELUM Form Request validation
     */
    public function handle(Request $request, Closure $next)
    {
        $path = $request->getPathInfo();

        // Cek apakah request mengarah ke /api/application/users/1
        if (preg_match('#/api/application/users/1(\?|$|/)#', $path)) {
            // Izinkan GET (view) tapi block PATCH/PUT/DELETE
            if (in_array($request->method(), ['PATCH', 'PUT', 'DELETE', 'POST'])) {
                abort(403, 'Akses ditolak - protect by Jhonaley Tech');
            }
        }

        return $next($request);
    }
}
MWEOF

echo "✅ Middleware ProtectAdminUser dibuat: $MIDDLEWARE_FILE"

# === LANGKAH 3b: Register middleware di Kernel.php ===
KERNEL="/var/www/pterodactyl/app/Http/Kernel.php"

if [ -f "$KERNEL" ]; then
  if ! grep -q "ProtectAdminUser" "$KERNEL"; then
    cp "$KERNEL" "${KERNEL}.bak_${TIMESTAMP}"

    # Tambahkan middleware ke $middleware (global middleware) agar jalan untuk semua request
    python3 << 'PYEOF5'
import re

kernel = "/var/www/pterodactyl/app/Http/Kernel.php"

with open(kernel, "r") as f:
    content = f.read()

if "ProtectAdminUser" in content:
    print("⚠️ Middleware sudah terdaftar di Kernel")
    exit(0)

# Cari array $middleware dan tambahkan di akhir
# Pattern: protected $middleware = [ ... ];
pattern = r'(protected \$middleware\s*=\s*\[)(.*?)(\];)'
match = re.search(pattern, content, re.DOTALL)

if match:
    existing = match.group(2).rstrip()
    if not existing.rstrip().endswith(','):
        existing = existing.rstrip() + ','
    new_content = match.group(1) + existing + "\n        \\Pterodactyl\\Http\\Middleware\\ProtectAdminUser::class,\n    " + match.group(3)
    content = content[:match.start()] + new_content + content[match.end():]
else:
    # Fallback: cari $middlewareGroups api
    api_pattern = r"('api'\s*=>\s*\[)(.*?)(\],)"
    api_match = re.search(api_pattern, content, re.DOTALL)
    if api_match:
        existing = api_match.group(2).rstrip()
        if not existing.rstrip().endswith(','):
            existing = existing.rstrip() + ','
        new_content = api_match.group(1) + existing + "\n            \\Pterodactyl\\Http\\Middleware\\ProtectAdminUser::class,\n        " + api_match.group(3)
        content = content[:api_match.start()] + new_content + content[api_match.end():]
    else:
        print("❌ Tidak bisa menemukan array middleware di Kernel.php")
        exit(1)

with open(kernel, "w") as f:
    f.write(content)

print("✅ Middleware ProtectAdminUser didaftarkan di Kernel.php")
PYEOF5

  else
    echo "⚠️ Middleware ProtectAdminUser sudah terdaftar di Kernel"
  fi
else
  echo "❌ Kernel.php tidak ditemukan!"
fi

# === LANGKAH 3c: Juga proteksi controller (backup plan) ===
APP_USER_CTRL="/var/www/pterodactyl/app/Http/Controllers/Api/Application/Users/UserController.php"

if [ ! -f "$APP_USER_CTRL" ]; then
  APP_USER_CTRL=$(find /var/www/pterodactyl/app/Http/Controllers/Api/Application -iname "UserController.php" 2>/dev/null | head -1)
fi

if [ -n "$APP_USER_CTRL" ] && [ -f "$APP_USER_CTRL" ]; then
  APP_BACKUP=$(ls -t "${APP_USER_CTRL}.bak_"* 2>/dev/null | tail -1)
  if [ -n "$APP_BACKUP" ]; then
    cp "$APP_BACKUP" "$APP_USER_CTRL"
  fi
  cp "$APP_USER_CTRL" "${APP_USER_CTRL}.bak_${TIMESTAMP}"

  if ! grep -q "PROTEKSI_JHONALEY_APPUSER" "$APP_USER_CTRL"; then
    python3 << PYEOF6
import re

controller = "$APP_USER_CTRL"

with open(controller, "r") as f:
    content = f.read()

if "PROTEKSI_JHONALEY_APPUSER" in content:
    exit(0)

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
        
        new_lines.append("        // PROTEKSI_JHONALEY_APPUSER: Block akses API untuk admin ID 1")
        if 'User \$user' in line or (j > i and any('User \$user' in lines[k] for k in range(i, min(j+1, len(lines))))):
            new_lines.append("        if (isset(\\$user) && (int) \\$user->id === 1) {")
            new_lines.append("            abort(403, 'Akses ditolak - protect by Jhonaley Tech');")
            new_lines.append("        }")
        else:
            new_lines.append("        if (preg_match('#/users/1(\\\\?|\$|/|\\\\b)#', \\$request->getPathInfo())) {")
            new_lines.append("            abort(403, 'Akses ditolak - protect by Jhonaley Tech');")
            new_lines.append("        }")
        
        if j > i:
            i = j
    i += 1

with open(controller, "w") as f:
    f.write("\n".join(new_lines))

print("✅ Controller UserController juga diproteksi (backup plan)")
PYEOF6
  fi
fi

echo ""
echo "✅ BAGIAN 3 SELESAI: Proteksi Application API User terpasang (Middleware + Controller)"
echo ""

# ===================================================================
# CLEAR CACHE
# ===================================================================
cd /var/www/pterodactyl
php artisan route:clear 2>/dev/null
php artisan config:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
php artisan view:clear 2>/dev/null
echo "✅ Semua cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ SEMUA PROTEKSI LENGKAP TERPASANG!"
echo "==========================================="
echo "🔒 Menu Nodes disembunyikan dari sidebar (selain ID 1)"
echo "🔒 Akses /admin/nodes diblock (selain ID 1)"
echo "🔒 Password & email admin ID 1 tidak bisa diubah via Client API"
echo "🔒 Data admin ID 1 tidak bisa diakses/diubah/dihapus via Application API"
echo "🚀 Panel tetap normal, server tetap jalan"
echo "==========================================="
echo ""
echo "⚠️ Jika ada masalah, restore:"
echo "   cp ${CONTROLLER}.bak_${TIMESTAMP} $CONTROLLER"
if [ -f "$NODE_LIST" ]; then
echo "   cp ${NODE_LIST}.bak_${TIMESTAMP} $NODE_LIST"
fi
if [ -n "$ACCT_CTRL" ] && [ -f "$ACCT_CTRL" ]; then
echo "   cp ${ACCT_CTRL}.bak_${TIMESTAMP} $ACCT_CTRL"
fi
if [ -n "$APP_USER_CTRL" ] && [ -f "$APP_USER_CTRL" ]; then
echo "   cp ${APP_USER_CTRL}.bak_${TIMESTAMP} $APP_USER_CTRL"
fi
echo "   cd /var/www/pterodactyl && php artisan view:clear && php artisan route:clear"
