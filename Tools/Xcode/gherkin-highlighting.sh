#!/usr/bin/env bash
#
# Installs or removes Gherkin syntax highlighting for .feature files in Xcode.
#
#   Tools/Xcode/gherkin-highlighting.sh install
#   Tools/Xcode/gherkin-highlighting.sh uninstall
#   Tools/Xcode/gherkin-highlighting.sh status
#
# It copies two items into your home folder and changes nothing else:
#   ~/Library/Developer/Xcode/Plug-ins/Gherkin.ideplugin   (data only, no code)
#   ~/Library/Developer/Xcode/Specifications/Gherkin.xclangspec
#
# Quit and reopen Xcode afterwards. This relies on undocumented Xcode behaviour.

set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
xcode_dir="$HOME/Library/Developer/Xcode"
plugin="$xcode_dir/Plug-ins/Gherkin.ideplugin"
grammar="$xcode_dir/Specifications/Gherkin.xclangspec"

xcode_is_running() {
    pgrep -xq Xcode
}

remind_to_restart() {
    if xcode_is_running; then
        echo "Xcode is running: quit and reopen it to apply this."
    else
        echo "Open Xcode to apply this."
    fi
}

install() {
    mkdir -p "$xcode_dir/Plug-ins" "$xcode_dir/Specifications"
    # Remove the old copy first: copying a folder onto an existing one nests it.
    rm -rf "$plugin"
    cp -R "$source_dir/Gherkin.ideplugin" "$plugin"
    cp "$source_dir/Gherkin.xclangspec" "$grammar"
    echo "Installed:"
    echo "  $plugin"
    echo "  $grammar"
    remind_to_restart
    echo "When Xcode asks about an unexpected code bundle, choose Load Bundle."
}

uninstall() {
    local removed=0
    for item in "$plugin" "$grammar"; do
        if [ -e "$item" ]; then
            rm -rf "$item"
            echo "Removed $item"
            removed=1
        fi
    done
    if [ "$removed" -eq 0 ]; then
        echo "Gherkin highlighting is not installed."
        return
    fi
    remind_to_restart
}

status() {
    for item in "$plugin" "$grammar"; do
        if [ -e "$item" ]; then
            echo "Installed:     $item"
        else
            echo "Not installed: $item"
        fi
    done
}

case "${1:-}" in
    install) install ;;
    uninstall) uninstall ;;
    status) status ;;
    *)
        echo "Usage: $0 install|uninstall|status" >&2
        exit 64
        ;;
esac
