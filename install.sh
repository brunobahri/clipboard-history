#!/bin/bash
set -e

HISTORY_DIR="$HOME/.clipboard-history"
MONITOR_PLIST="$HOME/Library/LaunchAgents/com.clipboard-history.plist"
HOTKEY_PLIST="$HOME/Library/LaunchAgents/com.clipboard-hotkey.plist"

echo "=== Clipboard History - Instalacao ==="
echo ""

chmod +x "$HISTORY_DIR/monitor.sh"
chmod +x "$HISTORY_DIR/picker.sh"
echo "[OK] Scripts com permissao de execucao"

if launchctl list 2>/dev/null | grep -q "com.clipboard-history"; then
    launchctl unload "$MONITOR_PLIST" 2>/dev/null || true
fi
if launchctl list 2>/dev/null | grep -q "com.clipboard-hotkey"; then
    launchctl unload "$HOTKEY_PLIST" 2>/dev/null || true
fi
echo "[OK] Servicos anteriores parados"

echo "Compilando hotkey binary..."
swiftc -O -o "$HISTORY_DIR/clipboard-hotkey" "$HISTORY_DIR/ClipboardHistoryHotkey.swift" -framework Cocoa -framework Carbon
echo "[OK] Hotkey compilado ($HISTORY_DIR/clipboard-hotkey)"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$MONITOR_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.clipboard-history</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${HISTORY_DIR}/monitor.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST

cat > "$HOTKEY_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.clipboard-hotkey</string>
    <key>ProgramArguments</key>
    <array>
        <string>${HISTORY_DIR}/clipboard-hotkey</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST
echo "[OK] LaunchAgents criados"

launchctl load "$MONITOR_PLIST"
launchctl load "$HOTKEY_PLIST"
echo "[OK] Servicos iniciados"

echo ""
echo "=== Instalacao concluida! ==="
echo ""
echo "IMPORTANTE: Adicione o binario na lista de Acessibilidade:"
echo "  1. System Settings > Privacy & Security > Accessibility"
echo '  2. Clique "+" > Cmd+Shift+G > ~/.clipboard-history/clipboard-hotkey'
echo "  3. Ative o toggle"
echo ""
echo "Sem essa permissao o picker abre, mas nao cola automaticamente."
echo "Voce ainda pode colar manualmente com Cmd+V apos selecionar."
echo ""
echo "Uso: Cmd+Shift+V para abrir o historico de clipboard."
echo ""
echo "Comandos uteis:"
echo "  Parar:       launchctl unload $MONITOR_PLIST $HOTKEY_PLIST"
echo "  Iniciar:     launchctl load $MONITOR_PLIST $HOTKEY_PLIST"
echo "  Limpar:      > $HISTORY_DIR/history.txt"
echo ""
echo "Desinstalar:"
echo "  launchctl unload $MONITOR_PLIST $HOTKEY_PLIST"
echo "  rm -rf $HISTORY_DIR $MONITOR_PLIST $HOTKEY_PLIST"
