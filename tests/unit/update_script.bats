#!/usr/bin/env bats
# Tests fuer update_script — der sicherheitskritische Auto-Update-Pfad.
# Strategie:
#   - secure_fetch wird gemockt: gibt je nach URL fixe Lokal-Inhalte zurueck.
#   - Fake-Release-Asset und Fake-SHA256SUMS werden in einer Sandbox erzeugt.
#   - Bestaetigungs-Prompts via stdin (HEREDOC) gefuettert.

setup() {
    load '../test_helper'

    TEST_TMP="$(mktemp -d)"
    FAKE_REPO="$TEST_TMP/fake_repo"
    FAKE_INSTALL_DIR="$TEST_TMP/install"
    mkdir -p "$FAKE_REPO" "$FAKE_INSTALL_DIR"

    # "Altes" Skript, das aktualisiert werden soll
    cat > "$FAKE_INSTALL_DIR/wireguard_setup.sh" << 'OLD'
#!/usr/bin/env bash
SCRIPT_VERSION="1.0.0-old"
echo "alte version"
OLD
    chmod +x "$FAKE_INSTALL_DIR/wireguard_setup.sh"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Hilfs-Wrapper: ruft update_script in einer Subshell mit allen relevanten
# Mocks und Globals. $1 = neuer Versions-String, $2 = Confirm-Antworten
# (mehrzeilig, je Prompt eine Antwort).
run_update_script() {
    local version="$1"
    local stdin_input="$2"
    bash <<EOF
set +e
source "$SCRIPT_PATH"

# Globals umbiegen
SCRIPT_DIR="$FAKE_INSTALL_DIR"
SCRIPT_NAME="wireguard_setup.sh"
GITHUB_REPO="fake/repo"

# secure_fetch Mock — gibt je nach URL einen Fixture-Pfad zurueck
secure_fetch() {
    local url="\$1"
    local out="\$2"
    case "\$url" in
        */releases/download/*/SHA256SUMS)
            [[ -f "$FAKE_REPO/SHA256SUMS" ]] || return 22
            cp "$FAKE_REPO/SHA256SUMS" "\$out"
            ;;
        */releases/download/*/wireguard_setup.sh)
            [[ -f "$FAKE_REPO/wireguard_setup.sh" ]] || return 22
            cp "$FAKE_REPO/wireguard_setup.sh" "\$out"
            ;;
        *)
            return 22
            ;;
    esac
}

# Logging und error stumm bzw. nicht-fatal
log()     { :; }
warn()    { :; }
success() { :; }
error()   { echo "ERROR: \$*" >&2; exit 1; }

# Eingaben fuettern
echo -e '$stdin_input' | update_script "$version"
EOF
}

# Erzeugt ein gueltiges Fake-Asset + passende SHA256SUMS
make_valid_release() {
    cat > "$FAKE_REPO/wireguard_setup.sh" << 'NEW'
#!/usr/bin/env bash
SCRIPT_VERSION="1.4.4"
echo "neue version"
NEW
    sha256sum "$FAKE_REPO/wireguard_setup.sh" \
        | awk -v f="wireguard_setup.sh" '{print $1"  "f}' > "$FAKE_REPO/SHA256SUMS"
}

@test "update_script: gueltiger Hash → altes Skript wird ersetzt" {
    make_valid_release
    run run_update_script "1.4.4" "ja\nn"
    [ "$status" -eq 0 ]
    grep -q 'SCRIPT_VERSION="1.4.4"' "$FAKE_INSTALL_DIR/wireguard_setup.sh"
    # Backup wurde angelegt
    ls "$FAKE_INSTALL_DIR" | grep -q "^script_backup_v"
}

@test "update_script: falscher Hash → Update wird abgebrochen" {
    make_valid_release
    # SHA256SUMS manipulieren: andere Pruefsumme eintragen
    echo "deadbeef0000000000000000000000000000000000000000000000000000beef  wireguard_setup.sh" \
        > "$FAKE_REPO/SHA256SUMS"
    run run_update_script "1.4.4" "ja\nn"
    [ "$status" -ne 0 ]
    # Altes Skript MUSS unveraendert sein
    grep -q 'SCRIPT_VERSION="1.0.0-old"' "$FAKE_INSTALL_DIR/wireguard_setup.sh"
}

@test "update_script: SHA256SUMS fehlt → Update wird abgebrochen" {
    make_valid_release
    rm -f "$FAKE_REPO/SHA256SUMS"
    run run_update_script "1.4.4" "ja\nnein"
    [ "$status" -ne 0 ]
    grep -q 'SCRIPT_VERSION="1.0.0-old"' "$FAKE_INSTALL_DIR/wireguard_setup.sh"
}

@test "update_script: kein Eintrag fuer Skript in SHA256SUMS → Abbruch" {
    make_valid_release
    echo "00ff  irgendwas_anderes.sh" > "$FAKE_REPO/SHA256SUMS"
    run run_update_script "1.4.4" "ja\nn"
    [ "$status" -ne 0 ]
    grep -q 'SCRIPT_VERSION="1.0.0-old"' "$FAKE_INSTALL_DIR/wireguard_setup.sh"
}

@test "update_script: Bash-Syntaxfehler im Asset → Abbruch" {
    cat > "$FAKE_REPO/wireguard_setup.sh" << 'BROKEN'
#!/usr/bin/env bash
if [[ then echo broken
BROKEN
    sha256sum "$FAKE_REPO/wireguard_setup.sh" \
        | awk -v f="wireguard_setup.sh" '{print $1"  "f}' > "$FAKE_REPO/SHA256SUMS"
    run run_update_script "1.4.4" "ja\nn"
    [ "$status" -ne 0 ]
    grep -q 'SCRIPT_VERSION="1.0.0-old"' "$FAKE_INSTALL_DIR/wireguard_setup.sh"
}

@test "update_script: 'nein' am Confirm-Prompt → kein Update, kein Backup" {
    make_valid_release
    run run_update_script "1.4.4" "nein"
    [ "$status" -ne 0 ]
    grep -q 'SCRIPT_VERSION="1.0.0-old"' "$FAKE_INSTALL_DIR/wireguard_setup.sh"
    # Es darf KEIN Backup angelegt worden sein, weil wir vor dem Backup-Schritt abgebrochen haben
    ! ls "$FAKE_INSTALL_DIR" | grep -q "^script_backup_v"
}
