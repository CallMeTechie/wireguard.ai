#!/usr/bin/env bats
# Tests fuer bulk_import_clients — CSV-Parser, Header-Check, Validierung,
# Duplikat-Erkennung, Default-Werte, CRLF-Handling.

setup() {
    load '../test_helper'

    TEST_TMP="$(mktemp -d)"
    mkdir -p "$TEST_TMP/keys" "$TEST_TMP/clients" "$TEST_TMP/backups"

    # Server-Fixture mit minimaler Config + bestehender Peer "alice"
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
EOF

    # Dummy-Server-Keys, damit bulk_import_clients keine wg-Calls braucht
    echo "SERVERPRIV" > "$TEST_TMP/keys/server_private.key"
    echo "SERVERPUB"  > "$TEST_TMP/keys/server_public.key"
    chmod 600 "$TEST_TMP/keys/server_private.key"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Wrapper: ruft bulk_import_clients in Subshell mit allen Mocks und Globals.
# $1 = Pfad zur CSV-Datei (wird auf stdin gepiped als Antwort auf den Pfad-Prompt)
run_bulk_import() {
    local csv_path="$1"
    bash <<EOF
set +e
source "$SCRIPT_PATH"

CONFIG_DIR='$TEST_TMP'
CLIENTS_DIR='$TEST_TMP/clients'
BACKUP_DIR='$TEST_TMP/backups'

# Mocks fuer Side-Effects, die wg/Netzwerk brauchen
get_external_ip()   { echo "203.0.113.1"; }
generate_keys() {
    local key_path=\$1
    local key_name=\$2
    echo "PRIV_\${key_name}" > "\$key_path/\${key_name}_private.key"
    echo "PUB_\${key_name}" > "\$key_path/\${key_name}_public.key"
    chmod 600 "\$key_path/\${key_name}_private.key"
}
reload_wg_config() { :; }
create_backup()    { :; }

log()     { echo "LOG: \$*"; }
warn()    { echo "WARN: \$*"; }
success() { echo "OK: \$*"; }

# Pfad-Prompt mit der Test-CSV beantworten
echo '$csv_path' | bulk_import_clients
EOF
}

# ---------- Tests ----------

@test "bulk_import: gueltiger CSV mit zwei Clients → beide importiert" {
    cat > "$TEST_TMP/in.csv" << 'EOF'
name,ip,dns,allowed_ips
bob,10.0.0.3/32,8.8.8.8,0.0.0.0/0
carol,10.0.0.4/32,1.1.1.1,10.0.0.0/24
EOF
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -eq 0 ]
    grep -q "# bob"   "$TEST_TMP/wg0.conf"
    grep -q "# carol" "$TEST_TMP/wg0.conf"
    [ -f "$TEST_TMP/clients/bob.conf" ]
    [ -f "$TEST_TMP/clients/carol.conf" ]
    grep -q "DNS = 1.1.1.1"      "$TEST_TMP/clients/carol.conf"
    grep -q "AllowedIPs = 10.0.0.0/24" "$TEST_TMP/clients/carol.conf"
}

@test "bulk_import: falscher Header → Abbruch ohne Aenderung" {
    cat > "$TEST_TMP/in.csv" << 'EOF'
foo,bar,baz
bob,10.0.0.3/32,8.8.8.8
EOF
    local before
    before=$(sha256sum "$TEST_TMP/wg0.conf" | awk '{print $1}')
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -ne 0 ]
    local after
    after=$(sha256sum "$TEST_TMP/wg0.conf" | awk '{print $1}')
    [ "$before" = "$after" ]
}

@test "bulk_import: nicht-existente Datei → Abbruch" {
    run run_bulk_import "$TEST_TMP/does_not_exist.csv"
    [ "$status" -ne 0 ]
}

@test "bulk_import: Duplikat (alice ist schon im Server) → wird uebersprungen" {
    cat > "$TEST_TMP/in.csv" << 'EOF'
name,ip,dns,allowed_ips
alice,10.0.0.2/32,8.8.8.8,0.0.0.0/0
bob,10.0.0.3/32,8.8.8.8,0.0.0.0/0
EOF
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -eq 0 ]
    [[ "$output" == *"existiert bereits"* ]]
    grep -q "# bob" "$TEST_TMP/wg0.conf"
    # alice darf nicht doppelt vorhanden sein
    [ "$(grep -c "^# alice$" "$TEST_TMP/wg0.conf")" -eq 1 ]
}

@test "bulk_import: ungueltiger Client-Name → wird uebersprungen" {
    cat > "$TEST_TMP/in.csv" << 'EOF'
name,ip,dns,allowed_ips
../evil,10.0.0.3/32,8.8.8.8,0.0.0.0/0
bob,10.0.0.3/32,8.8.8.8,0.0.0.0/0
EOF
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -eq 0 ]
    grep -q "# bob" "$TEST_TMP/wg0.conf"
    ! grep -q "evil" "$TEST_TMP/wg0.conf"
}

@test "bulk_import: ungueltige IP → wird uebersprungen" {
    cat > "$TEST_TMP/in.csv" << 'EOF'
name,ip,dns,allowed_ips
mallory,not-an-ip,8.8.8.8,0.0.0.0/0
bob,10.0.0.3/32,8.8.8.8,0.0.0.0/0
EOF
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -eq 0 ]
    grep -q "# bob" "$TEST_TMP/wg0.conf"
    ! grep -q "# mallory" "$TEST_TMP/wg0.conf"
}

@test "bulk_import: leere DNS/AllowedIPs → Defaults werden gesetzt" {
    cat > "$TEST_TMP/in.csv" << 'EOF'
name,ip,dns,allowed_ips
bob,10.0.0.3/32,,
EOF
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -eq 0 ]
    grep -q "DNS = 8.8.8.8"             "$TEST_TMP/clients/bob.conf"
    grep -q "AllowedIPs = 0.0.0.0/0"    "$TEST_TMP/clients/bob.conf"
}

@test "bulk_import: Windows-CRLF-Zeilenenden werden akzeptiert" {
    printf 'name,ip,dns,allowed_ips\r\nbob,10.0.0.3/32,8.8.8.8,0.0.0.0/0\r\n' \
        > "$TEST_TMP/in.csv"
    run run_bulk_import "$TEST_TMP/in.csv"
    [ "$status" -eq 0 ]
    grep -q "# bob" "$TEST_TMP/wg0.conf"
    ! grep -q $'\r' "$TEST_TMP/wg0.conf"
}
