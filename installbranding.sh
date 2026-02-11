#!/bin/bash

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🎨 Memasang branding Jhonaley Tech ke Pterodactyl Panel..."
echo ""

# === LANGKAH 1: Cari file layout utama ===
LAYOUT_FILES=(
  "/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
  "/var/www/pterodactyl/resources/views/layouts/master.blade.php"
  "/var/www/pterodactyl/resources/views/layouts/auth.blade.php"
)

ADMIN_LAYOUT=""
MASTER_LAYOUT=""

for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    if [[ "$LF" == *"admin"* ]]; then
      ADMIN_LAYOUT="$LF"
    elif [[ "$LF" == *"master"* ]]; then
      MASTER_LAYOUT="$LF"
    fi
  fi
done

# Cari juga layout tambahan
if [ -z "$ADMIN_LAYOUT" ]; then
  ADMIN_LAYOUT=$(find /var/www/pterodactyl/resources/views/layouts/ -name "*.blade.php" -exec grep -l "admin" {} \; 2>/dev/null | head -1)
fi

if [ -z "$MASTER_LAYOUT" ]; then
  MASTER_LAYOUT=$(find /var/www/pterodactyl/resources/views/layouts/ -name "*.blade.php" 2>/dev/null | head -1)
fi

echo "📂 Admin layout: ${ADMIN_LAYOUT:-tidak ditemukan}"
echo "📂 Master layout: ${MASTER_LAYOUT:-tidak ditemukan}"
echo ""

# === LANGKAH 2: Inject CSS + Footer branding ===
inject_branding() {
  local FILE="$1"
  local LABEL="$2"

  if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "⚠️ File $LABEL tidak ditemukan, skip."
    return
  fi

  if grep -q "BRANDING_JHONALEY" "$FILE"; then
    echo "⚠️ Branding sudah ada di $LABEL, skip."
    return
  fi

  cp "$FILE" "${FILE}.bak_${TIMESTAMP}"
  echo "📦 Backup: ${FILE}.bak_${TIMESTAMP}"

  python3 << PYEOF
layout = "$FILE"

with open(layout, "r") as f:
    content = f.read()

if "BRANDING_JHONALEY" in content:
    print("Sudah ada branding")
    exit(0)

# CSS branding
branding_css = """
<!-- BRANDING_JHONALEY: Custom Branding -->
<style>
  /* ===== Jhonaley Tech Branding ===== */
  .jhonaley-footer {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 9999;
    background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
    padding: 10px 20px;
    text-align: center;
    border-top: 2px solid rgba(99, 102, 241, 0.5);
    box-shadow: 0 -4px 20px rgba(99, 102, 241, 0.15);
    font-family: 'Segoe UI', system-ui, sans-serif;
  }
  .jhonaley-footer .jt-inner {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    flex-wrap: wrap;
  }
  .jhonaley-footer .jt-badge {
    background: linear-gradient(135deg, #6366f1, #8b5cf6);
    color: #fff;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
    box-shadow: 0 2px 10px rgba(99, 102, 241, 0.4);
  }
  .jhonaley-footer .jt-text {
    color: #c4b5fd;
    font-size: 13px;
    font-weight: 500;
  }
  .jhonaley-footer .jt-text a {
    color: #818cf8;
    text-decoration: none;
    font-weight: 600;
    transition: all 0.3s ease;
  }
  .jhonaley-footer .jt-text a:hover {
    color: #a78bfa;
    text-shadow: 0 0 10px rgba(139, 92, 246, 0.5);
  }
  .jhonaley-footer .jt-separator {
    color: #4338ca;
    font-size: 10px;
  }
  .jhonaley-footer .jt-tg {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: rgba(99, 102, 241, 0.15);
    border: 1px solid rgba(99, 102, 241, 0.3);
    padding: 3px 10px;
    border-radius: 15px;
    color: #a5b4fc;
    font-size: 12px;
    text-decoration: none;
    transition: all 0.3s ease;
  }
  .jhonaley-footer .jt-tg:hover {
    background: rgba(99, 102, 241, 0.3);
    border-color: rgba(129, 140, 248, 0.5);
    color: #c7d2fe;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(99, 102, 241, 0.2);
  }
  .jhonaley-footer .jt-tg svg {
    width: 14px;
    height: 14px;
    fill: currentColor;
  }
  .jhonaley-footer .jt-promo {
    color: #fbbf24;
    font-size: 12px;
    font-weight: 600;
    text-shadow: 0 0 8px rgba(251, 191, 36, 0.3);
  }
  .jhonaley-footer .jt-promo a {
    color: #facc15;
    text-decoration: none;
    font-weight: 700;
    transition: all 0.3s ease;
  }
  .jhonaley-footer .jt-promo a:hover {
    color: #fde68a;
    text-shadow: 0 0 12px rgba(253, 224, 71, 0.5);
  }

  /* Beri ruang bawah agar footer tidak menutupi konten */
  body {
    padding-bottom: 50px !important;
  }

  /* Panel title tweak */
  .jhonaley-panel-tag {
    position: fixed;
    top: 10px;
    right: 15px;
    z-index: 9998;
    background: linear-gradient(135deg, #6366f1, #8b5cf6);
    color: #fff;
    padding: 5px 14px;
    border-radius: 20px;
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    box-shadow: 0 3px 15px rgba(99, 102, 241, 0.3);
    font-family: 'Segoe UI', system-ui, sans-serif;
    opacity: 0.9;
    transition: opacity 0.3s;
  }
  .jhonaley-panel-tag:hover {
    opacity: 1;
  }
</style>
"""

# HTML footer
branding_html = """
<!-- BRANDING_JHONALEY: Footer -->
<div class="jhonaley-footer">
  <div class="jt-inner">
    <span class="jt-badge">⚡ Protected</span>
    <span class="jt-text">Panel by <a href="https://t.me/danangvalentp" target="_blank">Jhonaley Tech</a></span>
    <span class="jt-separator">●</span>
    <a class="jt-tg" href="https://t.me/danangvalentp" target="_blank">
      <svg viewBox="0 0 24 24"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/></svg>
      @danangvalentp
    </a>
    <span class="jt-separator">●</span>
    <span class="jt-promo">Butuh panel yang anti mokad? Langsung aja ke <a href="https://t.me/upgradeuser_bot" target="_blank">@upgradeuser_bot</a></span>
  </div>
</div>
<div class="jhonaley-panel-tag">🛡️ Jhonaley Tech</div>
"""

# Inject sebelum </body>
if "</body>" in content:
    content = content.replace("</body>", branding_css + branding_html + "\n</body>")
    print("✅ Branding diinjeksi sebelum </body>")
elif "</html>" in content:
    content = content.replace("</html>", branding_css + branding_html + "\n</html>")
    print("✅ Branding diinjeksi sebelum </html>")
else:
    content += branding_css + branding_html
    print("✅ Branding ditambahkan di akhir file")

with open(layout, "w") as f:
    f.write(content)

PYEOF

  echo "✅ Branding dipasang di $LABEL"
}

# Inject ke semua layout yang ditemukan
for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    inject_branding "$LF" "$(basename $LF)"
  fi
done

# === LANGKAH 3: Ubah title panel ===
echo ""
echo "🔧 Mengubah judul panel..."

for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    if grep -q "<title>" "$LF" && ! grep -q "Jhonaley Tech" "$LF"; then
      sed -i 's/<title>.*<\/title>/<title>Pterodactyl - Jhonaley Tech<\/title>/g' "$LF" 2>/dev/null
      echo "✅ Title diubah di $(basename $LF)"
    fi
  fi
done

# === LANGKAH 4: Clear cache ===
cd /var/www/pterodactyl
php artisan view:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
echo "✅ Cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ Branding Jhonaley Tech terpasang!"
echo "==========================================="
echo "🎨 Footer keren dengan gradient ungu"
echo "🛡️ Badge 'Protected' + 'Jhonaley Tech'"
echo "📱 Link Telegram @danangvalentp"
echo "🏷️ Tag panel di pojok kanan atas"
echo "📝 Title panel diubah"
echo "==========================================="
echo ""
echo "⚠️ Untuk hapus branding, restore backup:"
for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "${LF}.bak_${TIMESTAMP}" ]; then
    echo "   cp ${LF}.bak_${TIMESTAMP} $LF"
  fi
done
echo "   cd /var/www/pterodactyl && php artisan view:clear"
