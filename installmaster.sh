#!/bin/bash
# ============================================
# installmaster.sh
# Master Installer: Inject Protect Manager ke Pterodactyl Admin Panel
# Menambahkan sidebar menu + halaman untuk install/uninstall proteksi
# Hanya tampil untuk Admin ID 1
# ============================================

set -e

PANEL_DIR="/var/www/pterodactyl"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
SCRIPTS_DIR="$PANEL_DIR/storage/app/protect-scripts"
CONFIG_FILE="$PANEL_DIR/storage/app/protect-config.json"
CONTROLLER_PATH="$PANEL_DIR/app/Http/Controllers/Admin/ProtectManagerController.php"
VIEW_PATH="$PANEL_DIR/resources/views/admin/protect-manager.blade.php"

echo "==========================================="
echo "🛡️  MASTER INSTALLER: Protect Manager Panel"
echo "==========================================="
echo ""
echo "📦 Membuat halaman Protect Manager di Admin Panel"
echo "📦 Sidebar hanya tampil untuk Admin ID 1"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 1: Buat direktori dan config
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 BAGIAN 1: Setup direktori & konfigurasi"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$SCRIPTS_DIR"
chmod 755 "$SCRIPTS_DIR"

# Download semua script proteksi dari GitHub
GITHUB_URL="https://raw.githubusercontent.com/jhonaleyhost-oss/installprotect/refs/heads/main"
echo "📥 Mendownload script proteksi dari GitHub..."
for i in 2 3 4 5 6 7 8 9 10 11 12 13; do
    if curl -fsSL -o "$SCRIPTS_DIR/installprotect${i}.sh" "$GITHUB_URL/installprotect${i}.sh"; then
        chmod +x "$SCRIPTS_DIR/installprotect${i}.sh"
        echo "   ✅ installprotect${i}.sh"
    else
        rm -f "$SCRIPTS_DIR/installprotect${i}.sh"
        echo "   ⚠️ Gagal download installprotect${i}.sh"
    fi
done
echo "✅ Download script selesai ke $SCRIPTS_DIR"

# Buat config default jika belum ada
if [ ! -f "$CONFIG_FILE" ]; then
cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
    "brand_name": "Jhonaley Tech",
    "brand_text": "Protect By Jhonaley",
    "contact_telegram": "@danangvalentp",
    "bot_link": "@upgradeuser_bot",
    "protections": {
        "protect2": {
            "name": "Anti Hapus/Ubah User",
            "description": "Melindungi data user dari penghapusan dan modifikasi oleh admin lain",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Admin/UserController.php",
            "enabled": false
        },
        "protect3": {
            "name": "Anti Akses Location",
            "description": "Memblokir akses menu Location untuk admin selain ID 1",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Admin/LocationController.php",
            "enabled": false
        },
        "protect4": {
            "name": "Anti Akses Nodes",
            "description": "Memblokir akses menu Nodes untuk admin selain ID 1",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Admin/Nodes/NodeController.php",
            "enabled": false
        },
        "protect5": {
            "name": "Nests + Branding + Welcome Banner",
            "description": "Sembunyikan Nests, tambah branding footer & welcome banner",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Admin/Nests/NestController.php",
            "extra_files": [
                "app/Http/Controllers/Admin/Nests/EggController.php",
                "resources/views/layouts/admin.blade.php",
                "resources/views/layouts/master.blade.php",
                "resources/views/templates/wrapper.blade.php"
            ],
            "enabled": false
        },
        "protect6": {
            "name": "Anti Akses Settings",
            "description": "Memblokir akses Settings panel untuk admin selain ID 1",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Admin/Settings/IndexController.php",
            "enabled": false
        },
        "protect7": {
            "name": "Anti Akses Server File",
            "description": "Proteksi file controller server dari akses tidak sah",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Api/Client/Servers/FileController.php",
            "enabled": false
        },
        "protect8": {
            "name": "Anti Akses Server Controller",
            "description": "Proteksi server controller dari akses tidak sah",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Api/Client/Servers/ServerController.php",
            "enabled": false
        },
        "protect9": {
            "name": "Anti Modifikasi Server",
            "description": "Mencegah modifikasi detail server oleh admin lain",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Services/Servers/DetailsModificationService.php",
            "enabled": false
        },
        "protect10": {
            "name": "Anti Tautan Server (v1)",
            "description": "Mencegah perubahan tautan/link server di admin panel",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "resources/views/admin/servers/index.blade.php",
            "enabled": false
        },
        "protect11": {
            "name": "Anti Tautan Server (v2)",
            "description": "Versi lanjutan proteksi tautan server",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "resources/views/admin/servers/index.blade.php",
            "enabled": false
        },
        "protect12": {
            "name": "Konsolidasi Proteksi",
            "description": "Gabungan proteksi Nodes, Client API, App API User, API Key, Locations",
            "marker": "PROTEKSI_JHONALEY",
            "target_file": "app/Http/Controllers/Admin/Nodes/NodeController.php",
            "enabled": false
        },
        "protect13": {
            "name": "Proteksi Application API",
            "description": "Sembunyikan menu Application API dan blokir akses controller",
            "marker": "PROTEKSI_JHONALEY_APPAPI",
            "target_file": "app/Http/Controllers/Admin/ApiController.php",
            "enabled": false
        }
    }
}
CONFIGEOF
echo "✅ Config default dibuat: $CONFIG_FILE"
else
    echo "⚠️ Config sudah ada, skip..."
fi

chown www-data:www-data "$CONFIG_FILE" 2>/dev/null || true
chmod 664 "$CONFIG_FILE"

echo "✅ BAGIAN 1 SELESAI"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 2: Buat Controller
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎮 BAGIAN 2: Buat ProtectManagerController"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$CONTROLLER_PATH" ]; then
    cp "$CONTROLLER_PATH" "${CONTROLLER_PATH}.bak_${TIMESTAMP}"
    echo "💾 Backup controller lama"
fi

cat > "$CONTROLLER_PATH" << 'PHPEOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\File;
use Pterodactyl\Http\Controllers\Controller;

class ProtectManagerController extends Controller
{
    private $configPath;
    private $scriptsDir;
    private $panelDir;

    public function __construct()
    {
        $this->panelDir = base_path();
        $this->configPath = storage_path('app/protect-config.json');
        $this->scriptsDir = storage_path('app/protect-scripts');
    }

    /**
     * Cek apakah user adalah admin ID 1
     */
    private function authorizeAccess()
    {
        $user = Auth::user();
        if (!$user || (int) $user->id !== 1) {
            abort(403, '🚫 Akses ditolak! Hanya admin ID 1 yang dapat mengakses Protect Manager.');
        }
    }

    /**
     * Baca konfigurasi
     */
    private function getConfig()
    {
        if (!File::exists($this->configPath)) {
            return ['protections' => [], 'brand_name' => 'Jhonaley Tech', 'brand_text' => 'Protect By Jhonaley', 'contact_telegram' => '@danangvalentp', 'bot_link' => '@upgradeuser_bot'];
        }
        return json_decode(File::get($this->configPath), true);
    }

    /**
     * Simpan konfigurasi
     */
    private function saveConfig($config)
    {
        File::put($this->configPath, json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    }

    /**
     * Ambil URL raw script dari GitHub
     */
    private function getScriptUrl(string $filename): string
    {
        return 'https://raw.githubusercontent.com/jhonaleyhost-oss/installprotect/refs/heads/main/' . $filename;
    }

    /**
     * Pastikan script tersedia di server, jika belum maka download otomatis dari GitHub
     */
    private function ensureScriptExists(string $filename): bool
    {
        $scriptPath = $this->scriptsDir . '/' . $filename;

        if (File::exists($scriptPath)) {
            return true;
        }

        $content = @file_get_contents($this->getScriptUrl($filename));
        if ($content === false || trim($content) === '' || strpos($content, '404: Not Found') !== false) {
            return false;
        }

        File::ensureDirectoryExists($this->scriptsDir);
        File::put($scriptPath, $content);
        @chmod($scriptPath, 0755);

        return true;
    }

    /**
     * Cek apakah proteksi sudah terinstall dengan memeriksa marker di file target
     */
    private function checkInstalled($protectionKey, $protection)
    {
        $containsAny = function (string $relativePath, array $needles): bool {
            $fullPath = $this->panelDir . '/' . ltrim($relativePath, '/');
            if (!File::exists($fullPath)) {
                return false;
            }

            $content = File::get($fullPath);
            foreach ($needles as $needle) {
                if ($needle !== '' && strpos($content, $needle) !== false) {
                    return true;
                }
            }

            return false;
        };

        switch ($protectionKey) {
            case 'protect2':
                return $containsAny('app/Http/Controllers/Admin/UserController.php', [
                    '✖️ Akses ditolak - protect by',
                    'Hanya admin ID 1 yang bisa akses halaman view user',
                ]);

            case 'protect3':
                return $containsAny('app/Http/Controllers/Admin/LocationController.php', [
                    'Jhonaley Protect - Akses ditolak',
                ]);

            case 'protect4':
                return $containsAny('app/Http/Controllers/Admin/Nodes/NodeController.php', [
                    'membuka menu Nodes',
                    '©Protect By Jhonaley V2.3',
                ]);

            case 'protect5':
                return $containsAny('app/Http/Controllers/Admin/Nests/NestController.php', ['PROTEKSI_JHONALEY'])
                    || $containsAny('app/Http/Controllers/Admin/Nests/EggController.php', ['PROTEKSI_JHONALEY'])
                    || $containsAny('resources/views/layouts/admin.blade.php', ['PROTEKSI_NESTS_SIDEBAR', 'BRANDING_JHONALEY'])
                    || $containsAny('resources/views/layouts/master.blade.php', ['BRANDING_JHONALEY', 'WELCOME_JHONALEY'])
                    || $containsAny('resources/views/templates/wrapper.blade.php', ['WELCOME_JHONALEY']);

            case 'protect6':
                return $containsAny('app/Http/Controllers/Admin/Settings/IndexController.php', [
                    'Jhonaley Protect - Akses ditolak',
                    'Protect By Jhonaley',
                    'Akses ditolak',
                    '$user->id !== 1',
                ]);

            case 'protect7':
                return $containsAny('app/Http/Controllers/Api/Client/Servers/FileController.php', [
                    'private function checkServerAccess',
                    'Anda tidak memiliki akses ke server ini.',
                ]);

            case 'protect8':
                return $containsAny('app/Http/Controllers/Api/Client/Servers/ServerController.php', [
                    'Hanya Bisa Melihat Server Milik Sendiri.',
                    '𝗛𝗮𝗻𝘆𝗮 𝗕𝗶𝘀𝗮 𝗠𝗲𝗹𝗶𝗵𝗮𝘁 𝗦𝗲𝗿𝘃𝗲𝗿 𝗠𝗶𝗹𝗶𝗸 𝗦𝗲𝗻𝗱𝗶𝗿𝗶.',
                ]);

            case 'protect9':
                return $containsAny('app/Services/Servers/DetailsModificationService.php', [
                    'hanya admin utama yang bisa mengubah detail server',
                    'Protect By Jhonaley',
                    'Akses ditolak',
                    '$user->id !== 1',
                ]);

            case 'protect10':
                return $containsAny('resources/views/admin/servers/index.blade.php', [
                    'Security Protection Active',
                    'Protected by:',
                ]) || $containsAny('resources/views/admin/servers/view/index.blade.php', [
                    'SERVER MANAGEMENT RESTRICTED',
                    'Root Administrator Access Required',
                ]);

            case 'protect11':
                return $containsAny('resources/views/admin/servers/index.blade.php', [
                    'Protected by: ',
                    '@danangvalentpl',
                ]) || $containsAny('resources/views/admin/servers/view/index.blade.php', [
                    'BLUR PROTECTION FOR NON-ROOT ADMINS',
                    'backdrop-filter: blur(20px);',
                ]);

            case 'protect12':
                return $containsAny('resources/views/layouts/admin.blade.php', ['PROTEKSI_NODES_SIDEBAR'])
                    || $containsAny('app/Http/Controllers/Admin/Nodes/NodeController.php', ['PROTEKSI_JHONALEY'])
                    || $containsAny('app/Http/Controllers/Api/Client/AccountController.php', ['PROTEKSI_JHONALEY_ACCOUNT'])
                    || $containsAny('app/Http/Middleware/ProtectAdminOneApi.php', ['PROTEKSI_JHONALEY_MIDDLEWARE'])
                    || $containsAny('app/Http/Controllers/Api/Application/Users/UserController.php', ['PROTEKSI_JHONALEY_APPUSER']);

            case 'protect13':
                return $containsAny('resources/views/layouts/admin.blade.php', ['PROTEKSI_JHONALEY_APPAPI_MENU'])
                    || $containsAny('app/Http/Controllers/Admin/ApiController.php', ['PROTEKSI_JHONALEY_APPAPI_BLOCK']);
        }

        $targetFile = $this->panelDir . '/' . $protection['target_file'];
        if (!File::exists($targetFile)) {
            return false;
        }

        return strpos(File::get($targetFile), $protection['marker']) !== false;
    }

    /**
     * Halaman utama Protect Manager
     */
    public function index()
    {
        $this->authorizeAccess();
        $config = $this->getConfig();

        // Cek status install setiap proteksi
        foreach ($config['protections'] as $key => &$prot) {
            $prot['installed'] = $this->checkInstalled($key, $prot);
        }

        return view('admin.protect-manager', [
            'config' => $config,
            'protections' => $config['protections'],
        ]);
    }

    /**
     * Install proteksi
     */
    public function install(Request $request)
    {
        $this->authorizeAccess();
        $key = $request->input('protection_key');
        $config = $this->getConfig();

        if (!isset($config['protections'][$key])) {
            return redirect()->route('admin.protect-manager')->with('error', 'Proteksi tidak ditemukan: ' . $key);
        }

        $scriptFilename = 'install' . $key . '.sh';
        $scriptFile = $this->scriptsDir . '/' . $scriptFilename;

        if (!$this->ensureScriptExists($scriptFilename)) {
            return redirect()->route('admin.protect-manager')->with('error', 'Script tidak ditemukan di server maupun GitHub: ' . $scriptFilename);
        }

        // Set environment variables untuk script
        $envVars = sprintf(
            'BRAND_NAME=%s BRAND_TEXT=%s CONTACT_TELEGRAM=%s BOT_LINK=%s',
            escapeshellarg($config['brand_name'] ?? 'Jhonaley Tech'),
            escapeshellarg($config['brand_text'] ?? 'Protect By Jhonaley'),
            escapeshellarg($config['contact_telegram'] ?? '@danangvalentp'),
            escapeshellarg($config['bot_link'] ?? '@upgradeuser_bot')
        );

        // Jalankan script
        $output = [];
        $returnVar = 0;
        $command = sprintf(
            'cd %s && %s bash %s 2>&1',
            escapeshellarg($this->panelDir),
            $envVars,
            escapeshellarg($scriptFile)
        );
        exec($command, $output, $returnVar);

        $config['protections'][$key]['enabled'] = ($returnVar === 0);
        $this->saveConfig($config);

        $outputText = implode("\n", $output);

        if ($returnVar === 0) {
            return redirect()->route('admin.protect-manager')->with('success', "✅ {$config['protections'][$key]['name']} berhasil diinstall!")->with('output', $outputText);
        }

        return redirect()->route('admin.protect-manager')->with('error', "❌ Gagal install {$config['protections'][$key]['name']}")->with('output', $outputText);
    }

    /**
     * Uninstall proteksi (restore dari backup)
     */
    public function uninstall(Request $request)
    {
        $this->authorizeAccess();
        $key = $request->input('protection_key');
        $config = $this->getConfig();

        if (!isset($config['protections'][$key])) {
            return redirect()->route('admin.protect-manager')->with('error', 'Proteksi tidak ditemukan.');
        }

        $prot = $config['protections'][$key];
        
        // Kumpulkan semua file yang perlu di-restore
        $filesToRestore = [$prot['target_file']];
        if (!empty($prot['extra_files'])) {
            $filesToRestore = array_merge($filesToRestore, $prot['extra_files']);
        }

        $restoredCount = 0;
        $errors = [];

        foreach ($filesToRestore as $relPath) {
            $targetFile = $this->panelDir . '/' . $relPath;
            $dir = dirname($targetFile);
            $basename = basename($targetFile);
            $backups = glob($dir . '/' . $basename . '.bak_*');

            if (empty($backups)) {
                continue; // Skip file tanpa backup
            }

            sort($backups);
            $latestBackup = end($backups);

            if (File::exists($latestBackup)) {
                File::copy($latestBackup, $targetFile);
                $restoredCount++;
            } else {
                $errors[] = $relPath;
            }
        }

        if ($restoredCount === 0 && !empty($errors)) {
            return redirect()->route('admin.protect-manager')->with('error', '❌ Gagal restore backup untuk ' . $prot['name']);
        }

        $config['protections'][$key]['enabled'] = false;
        $this->saveConfig($config);

        // Clear cache
        exec("cd {$this->panelDir} && php artisan view:clear && php artisan route:clear && php artisan config:clear && php artisan cache:clear 2>&1");

        return redirect()->route('admin.protect-manager')->with('success', "✅ {$prot['name']} berhasil di-uninstall! ({$restoredCount} file di-restore)");
    }

    /**
     * Update konfigurasi (nama brand, teks, dll)
     */
    public function updateConfig(Request $request)
    {
        $this->authorizeAccess();
        $config = $this->getConfig();

        $config['brand_name'] = $request->input('brand_name', $config['brand_name']);
        $config['brand_text'] = $request->input('brand_text', $config['brand_text']);
        $config['contact_telegram'] = $request->input('contact_telegram', $config['contact_telegram']);
        $config['bot_link'] = $request->input('bot_link', $config['bot_link']);

        // Update nama dan deskripsi proteksi jika dikirim
        if ($request->has('protection_names')) {
            foreach ($request->input('protection_names') as $key => $name) {
                if (isset($config['protections'][$key])) {
                    $config['protections'][$key]['name'] = $name;
                }
            }
        }
        if ($request->has('protection_descriptions')) {
            foreach ($request->input('protection_descriptions') as $key => $desc) {
                if (isset($config['protections'][$key])) {
                    $config['protections'][$key]['description'] = $desc;
                }
            }
        }

        $this->saveConfig($config);

        $messages = ['✅ Konfigurasi berhasil diupdate!'];
        $outputBlocks = [];

        // Re-apply semua proteksi yang sudah terpasang agar teks brand diperbarui
        $envVars = sprintf(
            'BRAND_NAME=%s BRAND_TEXT=%s CONTACT_TELEGRAM=%s BOT_LINK=%s',
            escapeshellarg($config['brand_name'] ?? 'Jhonaley Tech'),
            escapeshellarg($config['brand_text'] ?? 'Protect By Jhonaley'),
            escapeshellarg($config['contact_telegram'] ?? '@danangvalentp'),
            escapeshellarg($config['bot_link'] ?? '@upgradeuser_bot')
        );

        $reapplied = 0;
        foreach ($config['protections'] as $key => $prot) {
            if (!$this->checkInstalled($key, $prot)) {
                continue;
            }

            $scriptFilename = 'install' . $key . '.sh';
            $scriptFile = $this->scriptsDir . '/' . $scriptFilename;

            if (!$this->ensureScriptExists($scriptFilename)) {
                continue;
            }

            $output = [];
            $returnVar = 0;
            $command = sprintf(
                'cd %s && %s bash %s 2>&1',
                escapeshellarg($this->panelDir),
                $envVars,
                escapeshellarg($scriptFile)
            );
            exec($command, $output, $returnVar);

            if ($returnVar === 0) {
                $config['protections'][$key]['enabled'] = true;
                $reapplied++;
            }

            $outputText = trim(implode("\n", $output));
            if ($outputText !== '') {
                $outputBlocks[] = '[' . $key . ']' . "\n" . $outputText;
            }
        }

        if ($reapplied > 0) {
            $this->saveConfig($config);
            $messages[] = "🔄 {$reapplied} proteksi otomatis diterapkan ulang dengan brand baru.";
        }

        $redirect = redirect()->route('admin.protect-manager')->with('success', implode("\n", $messages));

        if (!empty($outputBlocks)) {
            $redirect = $redirect->with('output', trim(implode("\n\n", $outputBlocks)));
        }

        return $redirect;
    }

    /**
     * Upload script proteksi
     */
    public function uploadScript(Request $request)
    {
        $this->authorizeAccess();

        if ($request->hasFile('script_file')) {
            $file = $request->file('script_file');
            $filename = $file->getClientOriginalName();
            $file->move($this->scriptsDir, $filename);
            chmod($this->scriptsDir . '/' . $filename, 0755);

            return redirect()->route('admin.protect-manager')->with('success', "✅ Script '{$filename}' berhasil diupload!");
        }

        return redirect()->route('admin.protect-manager')->with('error', '❌ Tidak ada file yang diupload.');
    }

    /**
     * Install semua proteksi yang dicentang
     */
    public function bulkInstall(Request $request)
    {
        $this->authorizeAccess();
        $selected = $request->input('selected_protections', []);
        $config = $this->getConfig();
        $results = [];
        $allOutput = [];

        if (empty($selected)) {
            return redirect()->route('admin.protect-manager')->with('error', '❌ Tidak ada proteksi yang dipilih.');
        }

        foreach ($selected as $key) {
            if (!isset($config['protections'][$key])) {
                continue;
            }

            $scriptFilename = 'install' . $key . '.sh';
            $scriptFile = $this->scriptsDir . '/' . $scriptFilename;

            if (!$this->ensureScriptExists($scriptFilename)) {
                $results[] = "⚠️ {$config['protections'][$key]['name']}: Script tidak ditemukan di server maupun GitHub";
                continue;
            }

            $envVars = sprintf(
                'BRAND_NAME=%s BRAND_TEXT=%s CONTACT_TELEGRAM=%s BOT_LINK=%s',
                escapeshellarg($config['brand_name'] ?? 'Jhonaley Tech'),
                escapeshellarg($config['brand_text'] ?? 'Protect By Jhonaley'),
                escapeshellarg($config['contact_telegram'] ?? '@danangvalentp'),
                escapeshellarg($config['bot_link'] ?? '@upgradeuser_bot')
            );

            $output = [];
            $returnVar = 0;
            $command = sprintf(
                'cd %s && %s bash %s 2>&1',
                escapeshellarg($this->panelDir),
                $envVars,
                escapeshellarg($scriptFile)
            );
            exec($command, $output, $returnVar);

            if ($returnVar === 0) {
                $config['protections'][$key]['enabled'] = true;
                $results[] = "✅ {$config['protections'][$key]['name']}: Berhasil diinstall";
            } else {
                $config['protections'][$key]['enabled'] = false;
                $results[] = "❌ {$config['protections'][$key]['name']}: Gagal install";
            }

            $allOutput[] = '[' . $key . ']';
            $allOutput[] = implode("\n", $output);
        }

        $this->saveConfig($config);

        return redirect()->route('admin.protect-manager')
            ->with('success', implode("\n", $results))
            ->with('output', trim(implode("\n\n", $allOutput)));
    }
}
PHPEOF

chmod 644 "$CONTROLLER_PATH"
echo "✅ Controller dibuat: $CONTROLLER_PATH"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 3: Buat View (Blade Template)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 BAGIAN 3: Buat Blade View"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$VIEW_PATH" ]; then
    cp "$VIEW_PATH" "${VIEW_PATH}.bak_${TIMESTAMP}"
fi

cat > "$VIEW_PATH" << 'VIEWEOF'
@extends('layouts.admin')

@section('title')
    Protect Manager
@endsection

@section('content-header')
    <h1>🛡️ Protect Manager<small>Kelola proteksi panel Anda</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Protect Manager</li>
    </ol>
@endsection

@section('content')
<style>
    .protect-card {
        background: linear-gradient(135deg, #0c1929 0%, #132f4c 50%, #0a2744 100%);
        border: 1px solid #1e3a5f;
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 15px;
        transition: all 0.3s ease;
    }
    .protect-card:hover {
        border-color: #3b82f6;
        box-shadow: 0 4px 20px rgba(59, 130, 246, 0.15);
    }
    .protect-card.installed {
        border-left: 4px solid #22c55e;
    }
    .protect-card.not-installed {
        border-left: 4px solid #64748b;
    }
    .protect-header {
        background: linear-gradient(135deg, #0c1929 0%, #1a365d 100%);
        border: 1px solid #1e3a5f;
        border-radius: 12px;
        padding: 25px;
        margin-bottom: 25px;
    }
    .protect-header h2 {
        color: #93c5fd;
        margin: 0 0 5px 0;
        font-size: 24px;
    }
    .protect-header p {
        color: #94a3b8;
        margin: 0;
    }
    .badge-installed {
        background: #166534;
        color: #4ade80;
        padding: 3px 10px;
        border-radius: 20px;
        font-size: 11px;
        font-weight: 600;
    }
    .badge-not-installed {
        background: #1e293b;
        color: #94a3b8;
        padding: 3px 10px;
        border-radius: 20px;
        font-size: 11px;
        font-weight: 600;
    }
    .protect-title {
        color: #e2e8f0;
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 5px;
    }
    .protect-desc {
        color: #94a3b8;
        font-size: 13px;
        margin-bottom: 10px;
    }
    .btn-install {
        background: linear-gradient(135deg, #2563eb, #3b82f6);
        color: white;
        border: none;
        padding: 6px 16px;
        border-radius: 8px;
        font-size: 13px;
        cursor: pointer;
        transition: all 0.2s;
    }
    .btn-install:hover {
        background: linear-gradient(135deg, #1d4ed8, #2563eb);
        color: white;
        transform: translateY(-1px);
    }
    .btn-uninstall {
        background: linear-gradient(135deg, #dc2626, #ef4444);
        color: white;
        border: none;
        padding: 6px 16px;
        border-radius: 8px;
        font-size: 13px;
        cursor: pointer;
        transition: all 0.2s;
    }
    .btn-uninstall:hover {
        background: linear-gradient(135deg, #b91c1c, #dc2626);
        color: white;
        transform: translateY(-1px);
    }
    .btn-save-config {
        background: linear-gradient(135deg, #7c3aed, #8b5cf6);
        color: white;
        border: none;
        padding: 8px 24px;
        border-radius: 8px;
        font-size: 14px;
        cursor: pointer;
        transition: all 0.2s;
    }
    .btn-save-config:hover {
        background: linear-gradient(135deg, #6d28d9, #7c3aed);
        color: white;
        transform: translateY(-1px);
    }
    .btn-bulk {
        background: linear-gradient(135deg, #059669, #10b981);
        color: white;
        border: none;
        padding: 10px 28px;
        border-radius: 8px;
        font-size: 14px;
        cursor: pointer;
        font-weight: 600;
        transition: all 0.2s;
    }
    .btn-bulk:hover {
        background: linear-gradient(135deg, #047857, #059669);
        color: white;
        transform: translateY(-1px);
    }
    .config-section {
        background: linear-gradient(135deg, #0c1929 0%, #132f4c 100%);
        border: 1px solid #1e3a5f;
        border-radius: 12px;
        padding: 25px;
        margin-bottom: 25px;
    }
    .config-section h3 {
        color: #93c5fd;
        margin: 0 0 20px 0;
        font-size: 18px;
    }
    .config-input {
        background: #0f172a;
        border: 1px solid #334155;
        color: #e2e8f0;
        border-radius: 8px;
        padding: 8px 12px;
        width: 100%;
        font-size: 14px;
        transition: border-color 0.2s;
    }
    .config-input:focus {
        border-color: #3b82f6;
        outline: none;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    }
    .config-label {
        color: #94a3b8;
        font-size: 13px;
        margin-bottom: 5px;
        display: block;
    }
    .alert-custom {
        border-radius: 10px;
        padding: 15px 20px;
        margin-bottom: 20px;
        font-size: 14px;
    }
    .output-box {
        background: #0f172a;
        border: 1px solid #334155;
        border-radius: 8px;
        padding: 12px;
        color: #94a3b8;
        font-family: monospace;
        font-size: 12px;
        max-height: 200px;
        overflow-y: auto;
        white-space: pre-wrap;
        margin-top: 10px;
    }
    .select-all-box {
        background: #0f172a;
        border: 1px solid #334155;
        border-radius: 10px;
        padding: 15px 20px;
        margin-bottom: 20px;
        display: flex;
        align-items: center;
        justify-content: space-between;
    }
    .select-all-box label {
        color: #e2e8f0;
        font-size: 14px;
        font-weight: 500;
        cursor: pointer;
    }
    .custom-check {
        width: 20px;
        height: 20px;
        accent-color: #3b82f6;
        cursor: pointer;
    }
    .tab-btn {
        background: transparent;
        border: 1px solid #334155;
        color: #94a3b8;
        padding: 8px 20px;
        border-radius: 8px;
        cursor: pointer;
        font-size: 14px;
        transition: all 0.2s;
        margin-right: 8px;
        margin-bottom: 8px;
    }
    .tab-btn.active, .tab-btn:hover {
        background: #1e3a5f;
        border-color: #3b82f6;
        color: #93c5fd;
    }
    .editable-name {
        background: transparent;
        border: 1px solid transparent;
        color: #e2e8f0;
        font-size: 16px;
        font-weight: 600;
        padding: 2px 6px;
        border-radius: 4px;
        width: 100%;
        transition: all 0.2s;
    }
    .editable-name:hover, .editable-name:focus {
        background: #0f172a;
        border-color: #334155;
        outline: none;
    }
    .editable-desc {
        background: transparent;
        border: 1px solid transparent;
        color: #94a3b8;
        font-size: 13px;
        padding: 2px 6px;
        border-radius: 4px;
        width: 100%;
        transition: all 0.2s;
    }
    .editable-desc:hover, .editable-desc:focus {
        background: #0f172a;
        border-color: #334155;
        outline: none;
    }
</style>

{{-- Notifikasi --}}
@if(session('success'))
    <div class="alert alert-success alert-custom">
        {!! nl2br(e(session('success'))) !!}
    </div>
@endif
@if(session('error'))
    <div class="alert alert-danger alert-custom">
        {!! nl2br(e(session('error'))) !!}
    </div>
@endif
@if(session('output'))
    <div class="output-box">{{ session('output') }}</div>
@endif

{{-- Header --}}
<div class="protect-header">
    <h2>🛡️ Protect Manager</h2>
    <p>Kelola semua proteksi panel dari sini. Centang proteksi yang ingin diinstall, lalu klik "Terapkan".</p>
</div>

{{-- Tab Navigation --}}
<div style="margin-bottom: 20px;">
    <button class="tab-btn active" onclick="showTab('protections', this)">🔒 Proteksi</button>
    <button class="tab-btn" onclick="showTab('config', this)">⚙️ Konfigurasi</button>
    <button class="tab-btn" onclick="showTab('upload', this)">📤 Upload Script</button>
</div>

{{-- TAB: Proteksi --}}
<div id="tab-protections">
    <form id="bulkInstallForm" action="{{ route('admin.protect-manager.bulk-install') }}" method="POST">
        @csrf
    </form>

    {{-- Select All --}}
    <div class="select-all-box">
        <label>
            <input type="checkbox" class="custom-check" id="selectAll" onclick="toggleAll(this)" style="margin-right: 10px;">
            Pilih Semua (yang belum terinstall)
        </label>
        <button type="submit" form="bulkInstallForm" class="btn-bulk">🚀 Terapkan yang Dicentang</button>
    </div>

    {{-- Protection Cards --}}
    <div class="row">
        @foreach($protections as $key => $prot)
        <div class="col-md-6">
            <div class="protect-card {{ $prot['installed'] ? 'installed' : 'not-installed' }}">
                <div style="display: flex; align-items: flex-start; justify-content: space-between;">
                    <div style="display: flex; align-items: flex-start; flex: 1;">
                        @if(!$prot['installed'])
                        <input type="checkbox" name="selected_protections[]" value="{{ $key }}" form="bulkInstallForm" class="custom-check protect-check" style="margin-right: 12px; margin-top: 3px;">
                        @else
                        <span style="margin-right: 12px; font-size: 18px;">✅</span>
                        @endif
                        <div style="flex: 1;">
                            <div class="protect-title">{{ $prot['name'] }}</div>
                            <div class="protect-desc">{{ $prot['description'] }}</div>
                            <div style="margin-top: 8px;">
                                @if($prot['installed'])
                                    <span class="badge-installed">● Terinstall</span>
                                @else
                                    <span class="badge-not-installed">○ Belum Install</span>
                                @endif
                                <span style="color: #475569; font-size: 11px; margin-left: 10px;">{{ $key }}</span>
                            </div>
                        </div>
                    </div>
                    <div style="display: flex; gap: 6px; flex-shrink: 0;">
                        @if(!$prot['installed'])
                        <form action="{{ route('admin.protect-manager.install') }}" method="POST" style="display:inline;">
                            @csrf
                            <input type="hidden" name="protection_key" value="{{ $key }}">
                            <button type="submit" class="btn-install" onclick="return confirm('Install {{ $prot['name'] }}?')">Install</button>
                        </form>
                        @else
                        <form action="{{ route('admin.protect-manager.uninstall') }}" method="POST" style="display:inline;">
                            @csrf
                            <input type="hidden" name="protection_key" value="{{ $key }}">
                            <button type="submit" class="btn-uninstall" onclick="return confirm('Uninstall {{ $prot['name'] }}? Ini akan restore dari backup.')">Uninstall</button>
                        </form>
                        @endif
                    </div>
                </div>
            </div>
        </div>
        @endforeach
    </div>
</div>

{{-- TAB: Konfigurasi --}}
<div id="tab-config" style="display: none;">
    <form action="{{ route('admin.protect-manager.update-config') }}" method="POST">
        @csrf
        
        {{-- Brand Settings --}}
        <div class="config-section">
            <h3>🏷️ Pengaturan Brand</h3>
            <div class="row">
                <div class="col-md-6">
                    <div class="form-group">
                        <label class="config-label">Nama Brand</label>
                        <input type="text" name="brand_name" value="{{ $config['brand_name'] ?? 'Jhonaley Tech' }}" class="config-input">
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label class="config-label">Teks Proteksi</label>
                        <input type="text" name="brand_text" value="{{ $config['brand_text'] ?? 'Protect By Jhonaley' }}" class="config-input">
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label class="config-label">Kontak Telegram</label>
                        <input type="text" name="contact_telegram" value="{{ $config['contact_telegram'] ?? '@danangvalentp' }}" class="config-input">
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label class="config-label">Link Bot</label>
                        <input type="text" name="bot_link" value="{{ $config['bot_link'] ?? '@upgradeuser_bot' }}" class="config-input">
                    </div>
                </div>
            </div>
        </div>

        {{-- Protection Names Edit --}}
        <div class="config-section">
            <h3>✏️ Edit Nama & Deskripsi Proteksi</h3>
            @foreach($protections as $key => $prot)
            <div style="padding: 12px 0; border-bottom: 1px solid #1e3a5f;">
                <div class="row">
                    <div class="col-md-1" style="display: flex; align-items: center; justify-content: center;">
                        <span style="color: #475569; font-size: 12px;">{{ $key }}</span>
                    </div>
                    <div class="col-md-4">
                        <input type="text" name="protection_names[{{ $key }}]" value="{{ $prot['name'] }}" class="editable-name" placeholder="Nama proteksi">
                    </div>
                    <div class="col-md-7">
                        <input type="text" name="protection_descriptions[{{ $key }}]" value="{{ $prot['description'] }}" class="editable-desc" placeholder="Deskripsi">
                    </div>
                </div>
            </div>
            @endforeach
        </div>

        <div style="text-align: right; margin-top: 15px;">
            <button type="submit" class="btn-save-config">💾 Simpan Konfigurasi</button>
        </div>
    </form>
</div>

{{-- TAB: Upload Script --}}
<div id="tab-upload" style="display: none;">
    <div class="config-section">
        <h3>📤 Upload Script Proteksi</h3>
        <p style="color: #94a3b8; font-size: 13px; margin-bottom: 20px;">
            Upload file .sh script proteksi ke server. Nama file harus sesuai format: <code style="color: #93c5fd;">installprotectX.sh</code>
        </p>
        <form action="{{ route('admin.protect-manager.upload-script') }}" method="POST" enctype="multipart/form-data">
            @csrf
            <div class="form-group">
                <input type="file" name="script_file" accept=".sh" class="config-input" style="padding: 10px;">
            </div>
            <button type="submit" class="btn-install" style="margin-top: 10px;">📤 Upload Script</button>
        </form>

        <div style="margin-top: 25px;">
            <h4 style="color: #93c5fd; font-size: 15px;">📂 Script yang Tersedia</h4>
            <div style="margin-top: 10px;">
                @php
                    $scriptFiles = glob(storage_path('app/protect-scripts/*.sh'));
                @endphp
                @if(count($scriptFiles) > 0)
                    @foreach($scriptFiles as $sf)
                    <div style="padding: 8px 12px; background: #0f172a; border-radius: 6px; margin-bottom: 6px; color: #94a3b8; font-family: monospace; font-size: 13px;">
                        📄 {{ basename($sf) }}
                        <span style="float: right; color: #475569;">{{ number_format(filesize($sf) / 1024, 1) }} KB</span>
                    </div>
                    @endforeach
                @else
                    <p style="color: #64748b; font-style: italic;">Belum ada script yang diupload. Upload script atau jalankan perintah download di bawah.</p>
                @endif
            </div>
        </div>

        <div style="margin-top: 25px; padding: 15px; background: #0f172a; border: 1px solid #334155; border-radius: 8px;">
            <h4 style="color: #fbbf24; font-size: 14px; margin-bottom: 10px;">💡 Download Script dari GitHub</h4>
            <p style="color: #94a3b8; font-size: 12px; margin-bottom: 10px;">Jalankan perintah ini via SSH untuk download semua script sekaligus:</p>
            <code style="color: #93c5fd; font-size: 11px; display: block; padding: 10px; background: #020617; border-radius: 6px; word-break: break-all;">
SCRIPTS_DIR="{{ storage_path('app/protect-scripts') }}" && mkdir -p "$SCRIPTS_DIR" && for i in 2 3 4 5 6 7 8 9 10 11 12 13; do curl -fsSL -o "$SCRIPTS_DIR/installprotect${i}.sh" "https://raw.githubusercontent.com/jhonaleyhost-oss/installprotect/refs/heads/main/installprotect${i}.sh" && chmod +x "$SCRIPTS_DIR/installprotect${i}.sh"; done && echo "✅ Download script selesai!"
            </code>
        </div>
    </div>
</div>

<script>
function showTab(tab, btn) {
    document.getElementById('tab-protections').style.display = 'none';
    document.getElementById('tab-config').style.display = 'none';
    document.getElementById('tab-upload').style.display = 'none';
    document.getElementById('tab-' + tab).style.display = 'block';
    
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
}

function toggleAll(checkbox) {
    document.querySelectorAll('.protect-check').forEach(cb => {
        cb.checked = checkbox.checked;
    });
}
</script>
@endsection
VIEWEOF

chmod 644 "$VIEW_PATH"
echo "✅ View dibuat: $VIEW_PATH"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 4: Tambah Route
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛣️  BAGIAN 4: Tambah Route"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ROUTES_FILE="$PANEL_DIR/routes/admin.php"

if [ ! -f "$ROUTES_FILE" ]; then
    echo "❌ File routes tidak ditemukan: $ROUTES_FILE"
else
    cp "$ROUTES_FILE" "${ROUTES_FILE}.bak_${TIMESTAMP}"
    echo "💾 Backup: ${ROUTES_FILE}.bak_${TIMESTAMP}"

    if grep -q "protect-manager" "$ROUTES_FILE"; then
        echo "⚠️ Route protect-manager sudah ada, skip..."
    else
        # Tambahkan route di akhir file (sebelum closing bracket terakhir jika ada)
        cat >> "$ROUTES_FILE" << 'ROUTEEOF'

/*
|--------------------------------------------------------------------------
| Protect Manager Routes (PROTEKSI_JHONALEY_MASTER)
|--------------------------------------------------------------------------
*/
Route::group(['prefix' => 'protect-manager'], function () {
    Route::get('/', [\Pterodactyl\Http\Controllers\Admin\ProtectManagerController::class, 'index'])->name('admin.protect-manager');
    Route::post('/install', [\Pterodactyl\Http\Controllers\Admin\ProtectManagerController::class, 'install'])->name('admin.protect-manager.install');
    Route::post('/uninstall', [\Pterodactyl\Http\Controllers\Admin\ProtectManagerController::class, 'uninstall'])->name('admin.protect-manager.uninstall');
    Route::post('/update-config', [\Pterodactyl\Http\Controllers\Admin\ProtectManagerController::class, 'updateConfig'])->name('admin.protect-manager.update-config');
    Route::post('/upload-script', [\Pterodactyl\Http\Controllers\Admin\ProtectManagerController::class, 'uploadScript'])->name('admin.protect-manager.upload-script');
    Route::post('/bulk-install', [\Pterodactyl\Http\Controllers\Admin\ProtectManagerController::class, 'bulkInstall'])->name('admin.protect-manager.bulk-install');
});
ROUTEEOF
        echo "✅ Route ditambahkan"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 5: Tambah Sidebar Menu (hanya ID 1)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 BAGIAN 5: Tambah Sidebar Menu"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ensure_protect_manager_sidebar() {
    local target_file="$1"

    if [ -z "$target_file" ] || [ ! -f "$target_file" ]; then
        echo "⚠️ Layout sidebar tidak ditemukan, skip pemulihan sidebar"
        return 0
    fi

    if grep -q "PROTEKSI_JHONALEY_MASTER_SIDEBAR\|admin.protect-manager" "$target_file" 2>/dev/null; then
        echo "ℹ️ Sidebar Protect Manager sudah ada di $target_file"
        return 0
    fi

    cp "$target_file" "${target_file}.bak_pm_${TIMESTAMP}" 2>/dev/null || true

    local settings_line=""
    settings_line=$(grep -n "Settings\|settings\|Configuration" "$target_file" | grep -i "href\|route\|url" | tail -1 | cut -d: -f1)
    if [ -z "$settings_line" ]; then
        settings_line=$(grep -n "</ul>" "$target_file" | tail -1 | cut -d: -f1)
    fi

    if [ -z "$settings_line" ]; then
        echo "⚠️ Tidak bisa menemukan posisi sidebar yang tepat"
        echo "📝 Tambahkan manual di layout file:"
        echo '   @if(Auth::user() && Auth::user()->id === 1)'
        echo '   <li><a href="{{ route('\''admin.protect-manager'\'') }}"><i class="fa fa-shield"></i> <span>Protect Manager</span></a></li>'
        echo '   @endif'
        return 0
    fi

    local total_lines
    local insert_line
    local temp_file

    total_lines=$(wc -l < "$target_file")
    insert_line=$settings_line
    for i in $(seq "$settings_line" $((settings_line + 15))); do
        if [ "$i" -gt "$total_lines" ]; then break; fi
        if sed -n "${i}p" "$target_file" | grep -q "</li>"; then
            insert_line=$i
            break
        fi
    done

    temp_file=$(mktemp)
    head -n "$insert_line" "$target_file" > "$temp_file"
    cat >> "$temp_file" << 'SIDEBAREOF'
                {{-- PROTEKSI_JHONALEY_MASTER_SIDEBAR: Protect Manager Menu --}}
                @if(Auth::user() && Auth::user()->id === 1)
                <li class="{{ Route::currentRouteName() === 'admin.protect-manager' ? 'active' : '' }}">
                    <a href="{{ route('admin.protect-manager') }}">
                        <i class="fa fa-shield"></i> <span>Protect Manager</span>
                    </a>
                </li>
                @endif
                {{-- END PROTEKSI_JHONALEY_MASTER_SIDEBAR --}}
SIDEBAREOF
    tail -n +"$((insert_line + 1))" "$target_file" >> "$temp_file"
    mv "$temp_file" "$target_file"
    chmod 644 "$target_file"

    echo "✅ Sidebar menu ditambahkan di baris $insert_line"
}

# Cari file layout admin
LAYOUT_FILE=""
LAYOUT_CANDIDATES=(
    "$PANEL_DIR/resources/views/layouts/admin.blade.php"
    "$PANEL_DIR/resources/views/layouts/app.blade.php"
    "$PANEL_DIR/resources/views/layouts/master.blade.php"
)

for candidate in "${LAYOUT_CANDIDATES[@]}"; do
    if [ -f "$candidate" ]; then
        LAYOUT_FILE="$candidate"
        break
    fi
done

if [ -z "$LAYOUT_FILE" ]; then
    echo "❌ Layout file tidak ditemukan!"
    echo "⏭️ Skip penambahan sidebar. Tambahkan manual."
else
    echo "📂 Layout ditemukan: $LAYOUT_FILE"
    ensure_protect_manager_sidebar "$LAYOUT_FILE"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BAGIAN 6: Clear Cache
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
# SELESAI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "==========================================="
echo "✅ MASTER INSTALLER SELESAI!"
echo "==========================================="
echo ""
echo "🛡️  Protect Manager berhasil diinstall!"
echo ""
echo "📌 Fitur:"
echo "   • Sidebar menu 'Protect Manager' (hanya untuk Admin ID 1)"
echo "   • Install/Uninstall proteksi via centang & klik"
echo "   • Edit nama brand, teks proteksi, kontak"
echo "   • Edit nama & deskripsi setiap proteksi"
echo "   • Upload script proteksi baru"
echo "   • Bulk install (centang beberapa, terapkan sekaligus)"
echo ""
echo "✅ Semua script proteksi sudah otomatis didownload ke server."
echo ""
echo "🌐 Akses: Admin Panel → Sidebar → Protect Manager"
echo ""
echo "⚠️ Jika ada masalah, restore:"
[ -f "${CONTROLLER_PATH}.bak_${TIMESTAMP}" ] && echo "   cp ${CONTROLLER_PATH}.bak_${TIMESTAMP} ${CONTROLLER_PATH}"
echo "   rm ${VIEW_PATH}"
[ -f "${ROUTES_FILE}.bak_${TIMESTAMP}" ] && echo "   cp ${ROUTES_FILE}.bak_${TIMESTAMP} ${ROUTES_FILE}"
[ -f "${LAYOUT_FILE}.bak_pm_${TIMESTAMP}" ] && echo "   cp ${LAYOUT_FILE}.bak_pm_${TIMESTAMP} ${LAYOUT_FILE}"
echo "   cd $PANEL_DIR && php artisan view:clear && php artisan route:clear"
