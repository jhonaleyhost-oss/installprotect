#!/bin/bash
###############################################
# INSTALLPROTECT13.SH
# Menghilangkan kolom "ptla" di Application API
###############################################

set -e

echo "==========================================="
echo "🔒 INSTALLPROTECT13: Hilangkan kolom ptla"
echo "    di halaman Application API"
echo "==========================================="

# Cari blade view Application API
API_BLADE="/var/www/pterodactyl/resources/views/admin/api/index.blade.php"

if [ ! -f "$API_BLADE" ]; then
    echo "❌ File tidak ditemukan: $API_BLADE"
    exit 1
fi

# Backup
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
cp "$API_BLADE" "${API_BLADE}.bak_${TIMESTAMP}"
echo "✅ Backup dibuat: ${API_BLADE}.bak_${TIMESTAMP}"

# Inject CSS untuk menyembunyikan kolom ptla via Python
export TARGET_FILE="$API_BLADE"

python3 << 'PYEOF'
import os

target = os.environ["TARGET_FILE"]

with open(target, "r") as f:
    content = f.read()

# Hapus proteksi lama jika ada
import re
content = re.sub(
    r'<!-- PROTEKSI_JHONALEY_HIDE_PTLA_START -->.*?<!-- PROTEKSI_JHONALEY_HIDE_PTLA_END -->',
    '',
    content,
    flags=re.DOTALL
)

# Cara 1: Sembunyikan via CSS - inject style di awal file
# Ini menyembunyikan sel tabel yang berisi "ptla"
hide_css = """<!-- PROTEKSI_JHONALEY_HIDE_PTLA_START -->
<style>
    /* Sembunyikan kolom ptla di tabel Application API */
    .ptla-hidden { display: none !important; }
</style>
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Cari semua sel tabel yang berisi teks "ptla"
    var tables = document.querySelectorAll('table');
    tables.forEach(function(table) {
        var headers = table.querySelectorAll('th');
        var ptlaIndex = -1;

        // Cari index kolom ptla
        headers.forEach(function(th, index) {
            if (th.textContent.trim().toLowerCase() === 'ptla' ||
                th.textContent.trim().toLowerCase().indexOf('ptla') !== -1) {
                ptlaIndex = index;
                th.style.display = 'none';
            }
        });

        // Sembunyikan semua sel di kolom tersebut
        if (ptlaIndex !== -1) {
            var rows = table.querySelectorAll('tr');
            rows.forEach(function(row) {
                var cells = row.querySelectorAll('td, th');
                if (cells[ptlaIndex]) {
                    cells[ptlaIndex].style.display = 'none';
                }
            });
        }
    });

    // Juga sembunyikan elemen apapun dengan teks/kelas ptla
    var allElements = document.querySelectorAll('td, span, div, code');
    allElements.forEach(function(el) {
        var text = el.textContent.trim();
        if (text === 'ptla' && el.tagName === 'TD') {
            el.style.display = 'none';
            // Sembunyikan juga header kolom yang sejajar
            var cellIndex = el.cellIndex;
            if (cellIndex !== undefined) {
                var table = el.closest('table');
                if (table) {
                    var headerRow = table.querySelector('thead tr, tr:first-child');
                    if (headerRow) {
                        var headerCells = headerRow.querySelectorAll('th, td');
                        if (headerCells[cellIndex]) {
                            headerCells[cellIndex].style.display = 'none';
                        }
                    }
                }
            }
        }
    });
});
</script>
<!-- PROTEKSI_JHONALEY_HIDE_PTLA_END -->
"""

# Cara 2: Juga coba hapus langsung kolom ptla dari HTML jika ada pattern yang jelas
# Hapus <td> atau <th> yang berisi "ptla" secara eksplisit
content = re.sub(
    r'<th[^>]*>[^<]*ptla[^<]*</th>',
    '<!-- ptla column hidden -->',
    content,
    flags=re.IGNORECASE
)
content = re.sub(
    r"<td[^>]*>\s*\{\{\s*\\\$key->identifier\s*\}\}\s*</td>",
    "<!-- ptla identifier hidden -->",
    content,
    flags=re.IGNORECASE
)

# Tambahkan CSS/JS di akhir file (sebelum @endsection jika ada)
if '@endsection' in content:
    content = content.replace('@endsection', hide_css + '\n@endsection')
elif '@stop' in content:
    content = content.replace('@stop', hide_css + '\n@stop')
else:
    content += '\n' + hide_css

with open(target, "w") as f:
    f.write(content)

print("✅ Kolom ptla berhasil disembunyikan dari Application API")
PYEOF

# Verifikasi
echo ""
echo "🔍 Verifikasi proteksi:"
grep -n "PROTEKSI_JHONALEY_HIDE_PTLA" "$API_BLADE" || echo "⚠️ Marker tidak ditemukan"
grep -n "ptla column hidden\|ptla identifier hidden" "$API_BLADE" || echo "(Tidak ada kolom ptla eksplisit di HTML)"

# Bersihkan cache
echo ""
cd /var/www/pterodactyl
php artisan view:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
echo "✅ Cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ PROTEKSI 13 SELESAI!"
echo "==========================================="
echo "🔒 Kolom ptla disembunyikan di Application API"
echo ""
echo "⚠️ Restore jika ada masalah:"
echo "   cp ${API_BLADE}.bak_${TIMESTAMP} ${API_BLADE}"
echo "   cd /var/www/pterodactyl && php artisan view:clear"
