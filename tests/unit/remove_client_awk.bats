#!/usr/bin/env bats
# Tests für die awk-State-Machine in remove_client.
# End-to-End-Test gegen eine Fixture-wg0.conf in einer tmp-Sandbox.
# Side-Effects (Backup, Reload, Service) werden gemockt.

setup() {
    load '../test_helper'

    TEST_TMP="$(mktemp -d)"
    mkdir -p "$TEST_TMP/keys" "$TEST_TMP/clients" "$TEST_TMP/backups"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Hilfsfunktion: Fixture mit drei Peers anlegen
write_fixture_three_peers() {
    cat > "$TEST_TMP/wg0.conf" << 'EOF'
[Interface]
PrivateKey = AAAA
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = false

[Peer]
# alice
PublicKey = KEY_ALICE
AllowedIPs = 10.0.0.2/32

[Peer]
# bob
PublicKey = KEY_BOB
AllowedIPs = 10.0.0.3/32

[Peer]
# carol
PublicKey = KEY_CAROL
AllowedIPs = 10.0.0.4/32
EOF
}

# Wrapper: führt remove_client in einer Subshell aus mit gemockten Side-Effects.
run_remove_client() {
    local input="$1"
    bash <<EOF
set +e
source "$SCRIPT_PATH"
CONFIG_DIR='$TEST_TMP'
CLIENTS_DIR='$TEST_TMP/clients'
BACKUP_DIR='$TEST_TMP/backups'
create_backup() { :; }
reload_wg_config() { :; }
list_clients() { :; }
manage_service() { :; }
log() { :; }
warn() { :; }
success() { :; }
echo '$input' | remove_client
EOF
}

@test "remove_client entfernt mittleren Peer und behält andere" {
    write_fixture_three_peers
    run_remove_client "bob"
    grep -q "# alice"  "$TEST_TMP/wg0.conf"
    grep -q "# carol"  "$TEST_TMP/wg0.conf"
    ! grep -q "# bob"  "$TEST_TMP/wg0.conf"
    ! grep -q "KEY_BOB" "$TEST_TMP/wg0.conf"
}

@test "remove_client entfernt ersten Peer und behält [Interface]" {
    write_fixture_three_peers
    run_remove_client "alice"
    grep -q "^\[Interface\]" "$TEST_TMP/wg0.conf"
    grep -q "ListenPort = 51820" "$TEST_TMP/wg0.conf"
    ! grep -q "# alice" "$TEST_TMP/wg0.conf"
    grep -q "# bob"   "$TEST_TMP/wg0.conf"
    grep -q "# carol" "$TEST_TMP/wg0.conf"
}

@test "remove_client entfernt letzten Peer korrekt" {
    write_fixture_three_peers
    run_remove_client "carol"
    grep -q "# alice" "$TEST_TMP/wg0.conf"
    grep -q "# bob"   "$TEST_TMP/wg0.conf"
    ! grep -q "# carol"  "$TEST_TMP/wg0.conf"
    ! grep -q "KEY_CAROL" "$TEST_TMP/wg0.conf"
}

@test "remove_client lässt Datei unverändert, wenn Client nicht existiert" {
    write_fixture_three_peers
    local before
    before=$(sha256sum "$TEST_TMP/wg0.conf" | awk '{print $1}')
    run_remove_client "eve" || true
    local after
    after=$(sha256sum "$TEST_TMP/wg0.conf" | awk '{print $1}')
    [ "$before" = "$after" ]
}

@test "remove_client lehnt ungültigen Client-Namen ab (Pfad-Traversal)" {
    write_fixture_three_peers
    local before
    before=$(sha256sum "$TEST_TMP/wg0.conf" | awk '{print $1}')
    run_remove_client "../passwd" || true
    local after
    after=$(sha256sum "$TEST_TMP/wg0.conf" | awk '{print $1}')
    [ "$before" = "$after" ]
}
