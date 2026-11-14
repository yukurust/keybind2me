#!/bin/bash
set -e

REPO_URL="https://github.com/yukurust/keybind2me.git"
TARGET_DIR="${HOME}/repos/github/keybind2me"

echo "==> Setting up keybind2me..."

# 1. Clone or update repository
if [ -d "$TARGET_DIR/.git" ]; then
    echo "==> Updating keybind2me repository in $TARGET_DIR..."
    git -C "$TARGET_DIR" pull --ff-only
else
    echo "==> Cloning keybind2me to $TARGET_DIR..."
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# 2. Setup AeroSpace config
echo "==> Configuring AeroSpace..."
mkdir -p "${HOME}/.config/aerospace"
ln -sf "${TARGET_DIR}/aerospace/aerospace.toml" "${HOME}/.aerospace.toml"
ln -sf "${TARGET_DIR}/aerospace/hud.swift" "${HOME}/.config/aerospace/hud.swift"

# 3. Compile Notch HUD
echo "==> Compiling Notch HUD (Swift)..."
swiftc -O "${HOME}/.config/aerospace/hud.swift" -o "${HOME}/.config/aerospace/hud_bin"

cat << 'HUD_WRAPPER' > "${HOME}/.config/aerospace/hud"
#!/bin/bash
killall hud_bin 2>/dev/null
exec "${HOME}/.config/aerospace/hud_bin" "$@"
HUD_WRAPPER
chmod +x "${HOME}/.config/aerospace/hud"

# 4. Compile CheatSheet (Dock Companion)
echo "==> Compiling CheatSheet..."
mkdir -p "${TARGET_DIR}/cheatsheet"
clang -O0 -c "${TARGET_DIR}/cheatsheet/dock_glass.c" -o /tmp/saithe-dock_glass.o
swiftc -O "${TARGET_DIR}/cheatsheet/cheatsheet.swift" /tmp/saithe-dock_glass.o -o "${HOME}/.config/aerospace/cheatsheet"

# 5. Install JankyBorders (active window border)
if ! command -v borders >/dev/null 2>&1; then
    echo "==> Installing JankyBorders..."
    INSTALLED_BORDERS=false
    if command -v brew >/dev/null 2>&1; then
        brew tap FelixKratz/formulae || true
        brew trust felixkratz/formulae || true
        if brew install borders; then
            INSTALLED_BORDERS=true
        fi
    fi

    if [ "$INSTALLED_BORDERS" = false ]; then
        echo "==> Homebrew install failed or unavailable, building JankyBorders from source..."
        TMP_BORDERS_DIR=$(mktemp -d)
        git clone --depth 1 --branch v1.9.0 https://github.com/FelixKratz/JankyBorders.git "$TMP_BORDERS_DIR"
        make -C "$TMP_BORDERS_DIR"
        BIN_DIR="/opt/homebrew/bin"
        [ ! -d "$BIN_DIR" ] && BIN_DIR="/usr/local/bin"
        mkdir -p "$BIN_DIR"
        cp "${TMP_BORDERS_DIR}/bin/borders" "${BIN_DIR}/borders"
        chmod +x "${BIN_DIR}/borders"
        rm -rf "$TMP_BORDERS_DIR"
    fi
fi

# 6. Setup WezTerm config
echo "==> Configuring WezTerm..."
mkdir -p "${HOME}/.config/wezterm"
ln -sf "${TARGET_DIR}/wezterm/wezterm.lua" "${HOME}/.config/wezterm/wezterm.lua"
ln -sf "${TARGET_DIR}/wezterm/keybinds.lua" "${HOME}/.config/wezterm/keybinds.lua"

# 7. Reload AeroSpace and start JankyBorders if running
if command -v aerospace >/dev/null 2>&1; then
    echo "==> Reloading AeroSpace configuration..."
    aerospace reload-config || true
fi

if command -v borders >/dev/null 2>&1 && ! pgrep -x borders >/dev/null 2>&1; then
    echo "==> Starting JankyBorders..."
    nohup borders active_color=0xff59c7fa inactive_color=0x00000000 width=4.0 hidpi=on >/dev/null 2>&1 &
fi

echo ""
echo "✨ keybind2me installation complete!"
echo "Run '${HOME}/.config/aerospace/cheatsheet &' to show the cheat sheet widget."
