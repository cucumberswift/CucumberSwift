#!/usr/bin/env bash
#
# Installs or removes Gherkin syntax highlighting and code snippets for .feature
# files in Xcode.
#
#   Tools/Xcode/gherkin-highlighting.sh install
#   Tools/Xcode/gherkin-highlighting.sh uninstall
#   Tools/Xcode/gherkin-highlighting.sh status
#
# It copies these into your home folder and changes nothing else:
#   ~/Library/Developer/Xcode/Plug-ins/Gherkin.ideplugin   (data only, no code)
#   ~/Library/Developer/Xcode/Specifications/Gherkin.xclangspec
#   ~/Library/Developer/Xcode/UserData/CodeSnippets/<id>.codesnippet, one per
#     snippet in Snippets/, named after its IDECodeSnippetIdentifier as Xcode does
#
# Quit and reopen Xcode afterwards. This relies on undocumented Xcode behaviour.

set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
xcode_dir="$HOME/Library/Developer/Xcode"
plugin="$xcode_dir/Plug-ins/Gherkin.ideplugin"
grammar="$xcode_dir/Specifications/Gherkin.xclangspec"
snippets_dir="$xcode_dir/UserData/CodeSnippets"
# Its tests set PLISTBUDDY to run it on Linux, which has no PlistBuddy.
plistbuddy="${PLISTBUDDY:-/usr/libexec/PlistBuddy}"

# Prints the installed path of each snippet in Snippets/, with its source.
snippets() {
    local snippet id
    for snippet in "$source_dir"/Snippets/*.codesnippet; do
        id="$("$plistbuddy" -c 'Print :IDECodeSnippetIdentifier' "$snippet")"
        printf '%s\t%s\n' "$snippets_dir/$id.codesnippet" "$snippet"
    done
}

installed_items() {
    echo "$plugin"
    echo "$grammar"
    snippets | cut -f1
}

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
    mkdir -p "$xcode_dir/Plug-ins" "$xcode_dir/Specifications" "$snippets_dir"
    # Remove each old copy first: copying a folder onto an existing one nests
    # it, and copying onto a symbolic link writes to the file it points to.
    rm -rf "$plugin" "$grammar"
    cp -R "$source_dir/Gherkin.ideplugin" "$plugin"
    cp "$source_dir/Gherkin.xclangspec" "$grammar"
    local target snippet
    while IFS=$'\t' read -r target snippet; do
        rm -f "$target"
        cp "$snippet" "$target"
    done < <(snippets)
    echo "Installed:"
    installed_items | sed 's/^/  /'
    remind_to_restart
    echo "If Xcode asks about an unexpected code bundle, choose Load Bundle."
}

uninstall() {
    local removed=0 item
    while read -r item; do
        if [[ -e "$item" || -L "$item" ]]; then
            rm -rf "$item"
            echo "Removed $item"
            removed=1
        fi
    done < <(installed_items)
    if [[ "$removed" -eq 0 ]]; then
        echo "Gherkin highlighting is not installed."
        return
    fi
    remind_to_restart
}

status() {
    local item
    while read -r item; do
        if [[ -e "$item" || -L "$item" ]]; then
            echo "Installed:     $item"
        else
            echo "Not installed: $item"
        fi
    done < <(installed_items)
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
