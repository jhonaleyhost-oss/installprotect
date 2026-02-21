#!/bin/bash
# ============================================
# installprotect13.sh
# Menyembunyikan menu "Application API" dari sidebar
# dan memblokir akses controller Application API
# untuk semua admin KECUALI User ID 1
# ============================================

set -e

PANEL_DIR="/var/www/pterodactyl"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)

echo "==========================================="
echo "🔒 INSTALLPROTECT13: Proteksi Application API"
echo "==========================================="

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 1: Sembunyikan menu Application API dari sidebar
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 BAGIAN 1: Sembunyikan menu Application API di sidebar"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SIDEBAR_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"

if [ ! -f "$SIDEBAR_FILE" ]; then
    echo "❌ File sidebar tidak ditemukan: $SIDEBAR_FILE"
    echo "🔍 Mencari file layout alternatif..."
    SIDEBAR_FILE=$(find "$PANEL_DIR/resources/views" -name "*.blade.php" -exec grep -l "Application API\|application/api\|admin\.api" {} \; 2>/dev/null | head -1)
    if [ -z "$SIDEBAR_FILE" ]; then
        echo "❌ Tidak bisa menemukan file sidebar yang mengandung menu Application API"
        echo "⏭️ Skip bagian 1, lanjut ke bagian 2..."
    else
        echo "📂 Ditemukan file alternatif: $SIDEBAR_FILE"
    fi
fi

if [ -n "$SIDEBAR_FILE" ] && [ -f "$SIDEBAR_FILE" ]; then
    # Backup
    cp "$SIDEBAR_FILE" "${SIDEBAR_FILE}.bak_${TIMESTAMP}"
    echo "💾 Backup: ${SIDEBAR_FILE}.bak_${TIMESTAMP}"

    # Cek apakah sudah diproteksi
    if grep -q "PROTEKSI_JHONALEY_APPAPI_MENU" "$SIDEBAR_FILE"; then
        echo "⚠️ Proteksi menu Application API sudah ada, skip..."
    else
        # Gunakan Python untuk inject proteksi
        python3 << 'PYEOF1'
import re
import os

sidebar_file = os.environ.get("SIDEBAR_FILE_PATH", "")
if not sidebar_file:
    print("ERROR: SIDEBAR_FILE_PATH not set")
    exit(1)

with open(sidebar_file, "r") as f:
    content = f.read()

# Pattern: cari link/menu yang mengandung "Application API" atau route admin.api
# Biasanya dalam format <li> atau <a> dengan href ke application api
patterns = [
    # Pattern 1: <li> block yang mengandung Application API
    r'(<li[^>]*>[\s\S]*?(?:Application\s*API|application/api|admin\.api)[\s\S]*?</li>)',
    # Pattern 2: <a> tag dengan Application API
    r'(<a[^>]*(?:Application\s*API|application/api|admin\.api)[^>]*>[\s\S]*?</a>)',
]

found = False
for pattern in patterns:
    matches = list(re.finditer(pattern, content, re.IGNORECASE))
    if matches:
        for match in reversed(matches):
            original = match.group(0)
            # Wrap dengan @if(Auth::user()->id === 1)
            replacement = (
                "{{-- PROTEKSI_JHONALEY_APPAPI_MENU: Sembunyikan Application API untuk non-ID 1 --}}\n"
                "@if(Auth::user()->id === 1)\n"
                + original + "\n"
                "@endif\n"
                "{{-- END PROTEKSI_JHONALEY_APPAPI_MENU --}}"
            )
            content = content[:match.start()] + replacement + content[match.end():]
            found = True
        break

if not found:
    # Fallback: cari teks "Application API" dan wrap parent element
    # Gunakan pendekatan line-by-line
    lines = content.split("\n")
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.search(r'Application\s*API', line, re.IGNORECASE) and 'PROTEKSI_JHONALEY' not in line:
            # Cari awal <li> atau <div> sebelumnya
            start = i
            for j in range(i-1, max(i-5, -1), -1):
                if re.search(r'<li|<div', lines[j]):
                    start = j
                    break
            # Cari akhir </li> atau </div> sesudahnya
            end = i
            for j in range(i+1, min(i+5, len(lines))):
                if re.search(r'</li>|</div>', lines[j]):
                    end = j
                    break

            # Insert proteksi
            if start < i:
                # Re-add lines sebelum start (sudah di new_lines)
                pass
            new_lines.append("{{-- PROTEKSI_JHONALEY_APPAPI_MENU: Sembunyikan Application API --}}")
            new_lines.append("@if(Auth::user()->id === 1)")
            for k in range(start if start == i else i, end + 1):
                new_lines.append(lines[k])
            new_lines.append("@endif")
            new_lines.append("{{-- END PROTEKSI_JHONALEY_APPAPI_MENU --}}")
            i = end + 1
            found = True
        else:
            new_lines.append(line)
            i += 1

    if found:
        content = "\n".join(new_lines)

if found:
    with open(sidebar_file, "w") as f:
        f.write(content)
    print("Menu Application API berhasil disembunyikan")
else:
    print("WARN: Tidak menemukan menu Application API di sidebar")

PYEOF1
        export SIDEBAR_FILE_PATH="$SIDEBAR_FILE"
        echo "✅ Bagian 1 selesai"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 2: Block akses ke Application API Controller
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 BAGIAN 2: Block akses Application API Controller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_CONTROLLER="$PANEL_DIR/app/Http/Controllers/Admin/ApiController.php"

if [ ! -f "$API_CONTROLLER" ]; then
    echo "❌ ApiController tidak ditemukan: $API_CONTROLLER"
else
    # Backup
    cp "$API_CONTROLLER" "${API_CONTROLLER}.bak_${TIMESTAMP}"
    echo "💾 Backup: ${API_CONTROLLER}.bak_${TIMESTAMP}"

    if grep -q "PROTEKSI_JHONALEY_APPAPI_BLOCK" "$API_CONTROLLER"; then
        echo "⚠️ Proteksi block sudah ada, skip..."
    else
        # Inject proteksi di constructor atau awal method index
        python3 << 'PYEOF2'
import re
import os

controller_file = os.environ.get("API_CONTROLLER_PATH", "")
if not controller_file:
    print("ERROR: API_CONTROLLER_PATH not set")
    exit(1)

with open(controller_file, "r") as f:
    content = f.read()

# Cari apakah ada constructor
constructor_match = re.search(r'(public\s+function\s+__construct\s*\([^)]*\)\s*\{)', content)

if constructor_match:
    # Tambah proteksi di dalam constructor
    inject_code = (
        "\n        // PROTEKSI_JHONALEY_APPAPI_BLOCK: Block akses Application API untuk non-ID 1\n"
        "        $this->middleware(function ($request, $next) {\n"
        "            if ($request->user()->id !== 1) {\n"
        "                abort(403, 'Akses Application API tidak diizinkan.');\n"
        "            }\n"
        "            return $next($request);\n"
        "        });\n"
    )
    pos = constructor_match.end()
    content = content[:pos] + inject_code + content[pos:]
else:
    # Tidak ada constructor, buat constructor baru
    # Cari class declaration
    class_match = re.search(r'(class\s+\w+[^{]*\{)', content)
    if class_match:
        inject_code = (
            "\n    // PROTEKSI_JHONALEY_APPAPI_BLOCK: Block akses Application API untuk non-ID 1\n"
            "    public function __construct()\n"
            "    {\n"
            "        $this->middleware(function ($request, $next) {\n"
            "            if ($request->user()->id !== 1) {\n"
            "                abort(403, 'Akses Application API tidak diizinkan.');\n"
            "            }\n"
            "            return $next($request);\n"
            "        });\n"
            "    }\n"
        )
        pos = class_match.end()
        content = content[:pos] + inject_code + content[pos:]
    else:
        print("ERROR: Tidak bisa menemukan class declaration")
        exit(1)

with open(controller_file, "w") as f:
    f.write(content)
print("Proteksi akses Application API Controller berhasil diinjeksi")

PYEOF2
        export API_CONTROLLER_PATH="$API_CONTROLLER"
        echo "✅ Bagian 2 selesai"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 3: Block route Application API di admin
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 BAGIAN 3: Middleware route Application API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MIDDLEWARE_DIR="$PANEL_DIR/app/Http/Middleware"
MIDDLEWARE_FILE="$MIDDLEWARE_DIR/ProtectApplicationApi.php"

if [ -f "$MIDDLEWARE_FILE" ]; then
    echo "⚠️ Middleware ProtectApplicationApi sudah ada, overwrite..."
fi

cat > "$MIDDLEWARE_FILE" << 'PHPEOF'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ProtectApplicationApi
{
    /**
     * PROTEKSI_JHONALEY_APPAPI_MIDDLEWARE
     * Block akses ke halaman Application API untuk semua admin kecuali ID 1
     */
    public function handle(Request $request, Closure $next)
    {
        if ($request->user() && $request->user()->id !== 1) {
            abort(403, 'Akses Application API tidak diizinkan.');
        }

        return $next($request);
    }
}
PHPEOF

echo "✅ Middleware ProtectApplicationApi dibuat"

# Daftarkan middleware di Kernel jika belum
KERNEL_FILE="$PANEL_DIR/app/Http/Kernel.php"
if [ -f "$KERNEL_FILE" ]; then
    if grep -q "ProtectApplicationApi" "$KERNEL_FILE"; then
        echo "⚠️ Middleware sudah terdaftar di Kernel"
    else
        cp "$KERNEL_FILE" "${KERNEL_FILE}.bak_${TIMESTAMP}"
        # Tambahkan ke routeMiddleware
        sed -i "/'auth'/a\\        'protect.appapi' => \\\\Pterodactyl\\\\Http\\\\Middleware\\\\ProtectApplicationApi::class," "$KERNEL_FILE"
        echo "✅ Middleware didaftarkan di Kernel.php"
    fi
fi

# Inject middleware ke route file
ADMIN_ROUTE="$PANEL_DIR/routes/admin.php"
if [ -f "$ADMIN_ROUTE" ]; then
    if grep -q "PROTEKSI_JHONALEY_APPAPI_ROUTE" "$ADMIN_ROUTE"; then
        echo "⚠️ Proteksi route sudah ada"
    else
        cp "$ADMIN_ROUTE" "${ADMIN_ROUTE}.bak_${TIMESTAMP}"
        # Cari route group untuk api dan tambahkan middleware
        python3 << 'PYEOF3'
import re
import os

route_file = os.environ.get("ADMIN_ROUTE_PATH", "")
if not route_file:
    print("ERROR: ADMIN_ROUTE_PATH not set")
    exit(1)

with open(route_file, "r") as f:
    content = f.read()

# Cari route yang mengarah ke ApiController
# Pattern: Route::resource('api', ...) atau Route::get('api', ...)
patterns = [
    r"(Route::\w+\s*\(\s*['\"]api['\"])",
    r"(Route::\w+\s*\(\s*['\"]api/\w*['\"])",
]

found = False
for pattern in patterns:
    matches = list(re.finditer(pattern, content))
    if matches:
        # Tambah middleware di awal file sebelum route api
        first_match = matches[0]
        # Cari baris yang mengandung route api, wrap dengan middleware group
        lines = content.split("\n")
        new_lines = []
        api_routes = []
        in_api_section = False

        for i, line in enumerate(lines):
            if re.search(r"Route::\w+\s*\(\s*['\"]api", line) and "PROTEKSI_JHONALEY" not in line:
                if not in_api_section:
                    new_lines.append("// PROTEKSI_JHONALEY_APPAPI_ROUTE: Middleware protect Application API")
                    new_lines.append("Route::middleware(['protect.appapi'])->group(function () {")
                    in_api_section = True
                new_lines.append("    " + line)
                # Cek apakah baris berikutnya masih api route
                if i + 1 < len(lines) and not re.search(r"Route::\w+\s*\(\s*['\"]api", lines[i + 1]):
                    new_lines.append("});")
                    new_lines.append("// END PROTEKSI_JHONALEY_APPAPI_ROUTE")
                    in_api_section = False
            else:
                new_lines.append(line)

        if in_api_section:
            new_lines.append("});")
            new_lines.append("// END PROTEKSI_JHONALEY_APPAPI_ROUTE")

        content = "\n".join(new_lines)
        found = True
        break

if found:
    with open(route_file, "w") as f:
        f.write(content)
    print("Route Application API diproteksi dengan middleware")
else:
    print("WARN: Tidak menemukan route api di admin routes")

PYEOF3
        export ADMIN_ROUTE_PATH="$ADMIN_ROUTE"
        echo "✅ Bagian 3 selesai"
    fi
else
    echo "⚠️ File routes/admin.php tidak ditemukan"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BERSIHKAN CACHE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🧹 Membersihkan cache..."
cd "$PANEL_DIR"
php artisan route:clear 2>/dev/null || true
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
echo "✅ Semua cache dibersihkan"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "==========================================="
echo "✅ INSTALLPROTECT13 SELESAI!"
echo "==========================================="
echo "🔒 Menu Application API disembunyikan dari sidebar (selain ID 1)"
echo "🔒 Akses controller Application API diblock (selain ID 1)"
echo "🔒 Route Application API dilindungi middleware (selain ID 1)"
echo "==========================================="
echo ""
echo "⚠️ Jika ada masalah, restore:"
if [ -n "$SIDEBAR_FILE" ] && [ -f "${SIDEBAR_FILE}.bak_${TIMESTAMP}" ]; then
    echo "   cp ${SIDEBAR_FILE}.bak_${TIMESTAMP} ${SIDEBAR_FILE}"
fi
echo "   cp ${API_CONTROLLER}.bak_${TIMESTAMP} ${API_CONTROLLER}"
if [ -f "${KERNEL_FILE}.bak_${TIMESTAMP}" ]; then
    echo "   cp ${KERNEL_FILE}.bak_${TIMESTAMP} ${KERNEL_FILE}"
fi
if [ -f "${ADMIN_ROUTE}.bak_${TIMESTAMP}" ]; then
    echo "   cp ${ADMIN_ROUTE}.bak_${TIMESTAMP} ${ADMIN_ROUTE}"
fi
echo "   rm -f $MIDDLEWARE_FILE"
echo "   cd $PANEL_DIR && php artisan view:clear && php artisan route:clear"
