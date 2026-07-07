#!/usr/bin/env bash
# Installs the swap-displays Hammerspoon function and Karabiner binding.
# Safe to re-run: idempotent for both configs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUA_SNIPPET="$SCRIPT_DIR/swap_displays.lua"
KARABINER_RULE="$SCRIPT_DIR/karabiner_rule.json"

HAMMERSPOON_CONFIG="$HOME/.hammerspoon/init.lua"
KARABINER_CONFIG="$HOME/.config/karabiner/karabiner.json"

log()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*" >&2; }
die()  { printf "\033[1;31m==>\033[0m %s\n" "$*" >&2; exit 1; }

# --- 1. Prerequisites ------------------------------------------------------

if ! command -v brew >/dev/null 2>&1; then
	die "Homebrew is required. Install it from https://brew.sh first."
fi

if ! command -v jq >/dev/null 2>&1; then
	log "Installing jq (needed to merge Karabiner config)..."
	brew install jq
fi

# --- 2. Install apps -------------------------------------------------------

for cask in hammerspoon karabiner-elements; do
	if brew list --cask "$cask" >/dev/null 2>&1; then
		log "$cask already installed."
	else
		log "Installing $cask..."
		brew install --cask "$cask"
	fi
done

# --- 3. Hammerspoon config -------------------------------------------------

mkdir -p "$(dirname "$HAMMERSPOON_CONFIG")"
touch "$HAMMERSPOON_CONFIG"

if grep -q "BEGIN swap-displays" "$HAMMERSPOON_CONFIG"; then
	log "Hammerspoon snippet already present, skipping."
else
	log "Appending swap-displays snippet to $HAMMERSPOON_CONFIG"
	printf "\n" >> "$HAMMERSPOON_CONFIG"
	cat "$LUA_SNIPPET" >> "$HAMMERSPOON_CONFIG"
fi

# --- 4. Karabiner config ---------------------------------------------------

mkdir -p "$(dirname "$KARABINER_CONFIG")"

if [[ ! -f "$KARABINER_CONFIG" ]]; then
	warn "No Karabiner config found at $KARABINER_CONFIG."
	warn "Open Karabiner-Elements once to let it create the default config, then re-run this script."
	exit 1
fi

RULE_DESC=$(jq -r '.description' "$KARABINER_RULE")
ALREADY_PRESENT=$(jq --arg desc "$RULE_DESC" \
	'[.profiles[].complex_modifications.rules[]?.description] | index($desc) != null' \
	"$KARABINER_CONFIG")

if [[ "$ALREADY_PRESENT" == "true" ]]; then
	log "Karabiner rule already present, skipping."
else
	BACKUP="$KARABINER_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
	cp "$KARABINER_CONFIG" "$BACKUP"
	log "Backed up existing Karabiner config to $BACKUP"

	TMP=$(mktemp)
	jq --slurpfile rule "$KARABINER_RULE" '
		.profiles |= map(
			.complex_modifications.rules = ((.complex_modifications.rules // []) + $rule)
		)
	' "$KARABINER_CONFIG" > "$TMP"
	mv "$TMP" "$KARABINER_CONFIG"
	log "Added swap-displays rule to Karabiner config."
fi

# --- 5. Wrap up ------------------------------------------------------------

log "Done!"
echo
echo "Next steps:"
echo "  1. Open Hammerspoon (first launch prompts for Accessibility permission)."
echo "  2. If it was already running, click its menu-bar icon → Reload Config."
echo "  3. Open Karabiner-Elements once to grant its permissions."
echo "  4. Test with:  Right Cmd + \\"
