#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeViewController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Akses Node View..."

if [ ! -f "$REMOTE_PATH" ]; then
  echo "❌ File $REMOTE_PATH tidak ditemukan! Pastikan Pterodactyl sudah terinstall."
  exit 1
fi

# Backup file asli
cp "$REMOTE_PATH" "$BACKUP_PATH"
echo "📦 Backup file lama dibuat di $BACKUP_PATH"

# Cek apakah proteksi sudah terpasang
if grep -q "PROTEKSI_JHONALEY_NODE_VIEW" "$REMOTE_PATH"; then
  echo "⚠️ Proteksi sudah terpasang sebelumnya, skip."
  exit 0
fi

# Tambahkan use Auth jika belum ada
if ! grep -q "use Illuminate\\\\Support\\\\Facades\\\\Auth;" "$REMOTE_PATH"; then
  sed -i '/^use Pterodactyl\\\\Http\\\\Controllers\\\\Controller;/a use Illuminate\\Support\\Facades\\Auth;' "$REMOTE_PATH"
  echo "✅ Ditambahkan: use Auth"
fi

# Tambahkan method checkNodeAccess setelah constructor
# Cari baris constructor closing brace yang diikuti method lain
INJECT_METHOD='
    // === PROTEKSI_JHONALEY_NODE_VIEW ===
    private function checkNodeAccess()
    {
        $user = Auth::user();
        if (!$user || (int) $user->id !== 1) {
            abort(403, '\''Akses ditolak - protect by Jhonaley Tech'\'');
        }
    }
    // === END PROTEKSI ==='

# Inject method setelah class declaration (setelah baris pertama yang ada "class ... Controller")
# Kita inject setelah opening brace class
sed -i "/class NodeViewController extends Controller/,/^    {/ {
    /^    {/a\\
\\
    // === PROTEKSI_JHONALEY_NODE_VIEW ===\\
    private function checkNodeAccess()\\
    {\\
        \\\$user = Auth::user();\\
        if (!\\\$user || (int) \\\$user->id !== 1) {\\
            abort(403, 'Akses ditolak - protect by Jhonaley Tech');\\
        }\\
    }\\
    // === END PROTEKSI ===
}" "$REMOTE_PATH"

echo "✅ Method checkNodeAccess berhasil diinjeksi"

# Inject $this->checkNodeAccess() di awal setiap public function (kecuali __construct)
# Cari semua public function dan tambahkan pengecekan setelah baris opening brace
FUNCTIONS=("index" "settings" "configuration" "allocations" "servers" "updateSettings" "updateConfiguration" "createAllocation" "deleteAllocation" "delete")

for FUNC in "${FUNCTIONS[@]}"; do
  if grep -q "public function $FUNC" "$REMOTE_PATH"; then
    # Tambahkan checkNodeAccess setelah opening brace fungsi tersebut
    sed -i "/public function $FUNC/,/^    {/ {
        /^    {/a\\
        \\\$this->checkNodeAccess();
    }" "$REMOTE_PATH"
    echo "  🔒 Proteksi ditambahkan ke: $FUNC()"
  fi
done

chmod 644 "$REMOTE_PATH"

echo ""
echo "✅ Proteksi Anti Akses Node View berhasil dipasang!"
echo "📂 Lokasi file: $REMOTE_PATH"
echo "🗂️ Backup file lama: $BACKUP_PATH"
echo "🔒 Hanya Admin ID 1 yang bisa akses Node View."
echo ""
echo "⚠️ Jika ada error, restore dengan:"
echo "   cp $BACKUP_PATH $REMOTE_PATH"
