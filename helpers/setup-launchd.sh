#!/usr/bin/env bash
# helpers/setup-launchd.sh
#
# Sets up launchd agents for automated Neuron jobs on macOS.
# Creates plist files in ~/Library/LaunchAgents/ and loads them.
#
# Jobs:
#   - com.neuron.ingest        → daily at 08:00
#   - com.neuron.lint          → every Monday at 09:00
#   - com.neuron.filter-evolve → every Monday at 09:05
#
# Usage:
#   ./helpers/setup-launchd.sh
#   ./helpers/setup-launchd.sh --uninstall
set -euo pipefail

LAUNCHD_DIR="${HOME}/Library/LaunchAgents"
LOG_DIR="${HOME}/.agents-neuron"

# Resolve claude binary path
CLAUDE_BIN=$(command -v claude 2>/dev/null || true)
if [ -z "$CLAUDE_BIN" ]; then
    echo "ERROR: 'claude' not found in PATH. Is Claude Code installed?" >&2
    echo "       Run 'which claude' after opening a new shell to verify." >&2
    exit 1
fi

UNINSTALL=false
if [[ "${1:-}" == "--uninstall" ]]; then
    UNINSTALL=true
fi

# ── Helpers ─────────────────────────────────────────────────────

write_plist() {
    local label="$1"
    local cmd="$2"
    local hour="$3"
    local min="$4"
    local weekday="${5:-}"   # empty = every day
    local plist="${LAUNCHD_DIR}/${label}.plist"

    local weekday_block=""
    if [ -n "$weekday" ]; then
        weekday_block="
        <key>Weekday</key>
        <integer>${weekday}</integer>"
    fi

    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${CLAUDE_BIN}</string>
        <string>-p</string>
        <string>${cmd}</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${hour}</integer>
        <key>Minute</key>
        <integer>${min}</integer>${weekday_block}
    </dict>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/launchd.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST
    echo "  wrote: ${plist}"
}

load_plist() {
    local label="$1"
    local plist="${LAUNCHD_DIR}/${label}.plist"
    launchctl unload "$plist" 2>/dev/null || true
    launchctl load "$plist"
    echo "  loaded: ${label}"
}

unload_plist() {
    local label="$1"
    local plist="${LAUNCHD_DIR}/${label}.plist"
    if [ -f "$plist" ]; then
        launchctl unload "$plist" 2>/dev/null || true
        rm "$plist"
        echo "  removed: ${plist}"
    else
        echo "  not found: ${plist}"
    fi
}

# ── Main ─────────────────────────────────────────────────────────

mkdir -p "$LAUNCHD_DIR" "$LOG_DIR"

if $UNINSTALL; then
    echo "Removing Neuron launchd agents..."
    unload_plist "com.neuron.ingest"
    unload_plist "com.neuron.lint"
    unload_plist "com.neuron.filter-evolve"
    echo "Done."
    exit 0
fi

echo "Installing Neuron launchd agents..."
echo "  claude: ${CLAUDE_BIN}"
echo ""

#            label                       command                hour  min  weekday
write_plist  "com.neuron.ingest"         "neuron ingest"         8    0    ""
write_plist  "com.neuron.lint"           "neuron lint"           9    0    "1"
write_plist  "com.neuron.filter-evolve"  "neuron filter evolve"  9    5    "1"

echo ""
echo "Loading agents..."
load_plist "com.neuron.ingest"
load_plist "com.neuron.lint"
load_plist "com.neuron.filter-evolve"

echo ""
echo "Done. Agents installed:"
echo "  com.neuron.ingest        → daily at 08:00"
echo "  com.neuron.lint          → Monday at 09:00"
echo "  com.neuron.filter-evolve → Monday at 09:05"
echo ""
echo "Logs: ${LOG_DIR}/launchd.log"
echo "To remove: ./helpers/setup-launchd.sh --uninstall"
