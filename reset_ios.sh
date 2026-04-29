#!/bin/bash
# ============================================================
# News App iOS Reset Script
# Jalankan script ini setiap kali build iOS bermasalah:
#   - Pod install gagal
#   - DerivedData korup
#   - Xcode tidak detect plugin baru
#   - Error "module not found" atau "framework not found"
#
# Usage:
#   chmod +x reset_ios.sh   (jalankan sekali untuk izinkan eksekusi)
#   ./reset_ios.sh
# ============================================================

set -e  # Berhenti otomatis jika ada command yang gagal
export LANG=en_US.UTF-8

PROJECT_NAME="news_app"

echo ""
echo "============================================================"
echo "  🔄 iOS Build Reset — $PROJECT_NAME"
echo "============================================================"
echo ""

# [1/6] Flutter Clean
echo "🧹 [1/6] Flutter clean (hapus build cache Dart & Flutter)..."
fvm flutter clean
echo "✅ Done."
echo ""

# [2/6] Flutter Pub Get
echo "📦 [2/6] Flutter pub get (restore semua dependencies)..."
fvm flutter pub get
echo "✅ Done."
echo ""

# [3/6] Hapus Artifacts CocoaPods lama
echo "🗑️  [3/6] Hapus artifacts CocoaPods lama..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/Runner.xcworkspace
echo "✅ Pods, Podfile.lock, dan xcworkspace dihapus."
echo ""

# [4/6] Hapus DerivedData Xcode yang korup
# PENTING: File DerivedData dikunci oleh beberapa proses background, bukan hanya Xcode:
#   - Xcode itu sendiri
#   - XCBBuildService (Xcode background build worker, tetap jalan meski Xcode ditutup)
#   - sourcekit-lsp (Apple Language Server untuk Swift)
#   - Dart Analysis Server (dijalankan VS Code/Cursor/IDE saat project terbuka)
# Semua harus dimatikan dulu sebelum DerivedData bisa dihapus dengan bersih.
echo "🗄️  [4/6] Mematikan proses yang mengunci DerivedData..."

# Tutup Xcode
if pgrep -x "Xcode" > /dev/null; then
  echo "   → Menutup Xcode..."
  killall Xcode 2>/dev/null || true
fi

# Matikan Xcode background build services
echo "   → Mematikan Xcode background services (XCBBuildService, sourcekit-lsp)..."
pkill -f "XCBBuildService" 2>/dev/null || true
pkill -f "sourcekit-lsp" 2>/dev/null || true
pkill -f "swift-frontend" 2>/dev/null || true
pkill -f "com.apple.dt.SKAgent" 2>/dev/null || true

# Matikan Dart Analysis Server (yang dijalankan VS Code/Cursor/IDE)
echo "   → Mematikan Dart Analysis Server (IDE background process)..."
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
pkill -f "DartAnalysisServer" 2>/dev/null || true

sleep 2  # Tunggu semua proses benar-benar berhenti

echo "   → Menghapus DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
rm -rf ~/Library/Developer/Xcode/DerivedData/Pods-*
echo "✅ Semua proses dimatikan & DerivedData bersih."
echo ""

# [5/6] Pod Install Ulang
echo "🔧 [5/6] Pod install ulang..."
cd ios
pod install --repo-update
cd ..
echo "✅ Pod install selesai."
echo ""

# [6/6] Selesai — Buka Xcode otomatis
echo "============================================================"
echo "🚀 [6/6] Reset selesai!"
echo ""
echo "   Membuka Runner.xcworkspace di Xcode..."
open ios/Runner.xcworkspace
echo ""
echo "   Setelah Xcode terbuka, pilih device dan tekan ▶ Run."
echo "   Atau jalankan: fvm flutter run"
echo "============================================================"
echo ""
