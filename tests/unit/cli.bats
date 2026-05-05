#!/usr/bin/env bats
# Tests für die CLI-Argument-Verarbeitung (--version, --help).
# Diese Tests führen das Skript direkt aus (nicht sourced), damit der
# Top-Level-case-Dispatcher angesprochen wird.

setup() {
    SCRIPT_PATH="${BATS_TEST_DIRNAME}/../../wireguard_setup.sh"
}

@test "--version gibt Versionsstring aus" {
    run "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"WireGuard Setup Script"* ]]
    [[ "$output" == *"v1."* ]]
}

@test "--version enthält GitHub-Repo-URL" {
    run "$SCRIPT_PATH" --version
    [[ "$output" == *"github.com/CallMeTechie/wireguard.ai"* ]]
}

@test "--help gibt Verwendung aus" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Verwendung"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "-h ist Kurzform von --help" {
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Verwendung"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "--help erwähnt --auto-backup, --check-updates, --version" {
    run "$SCRIPT_PATH" --help
    [[ "$output" == *"--auto-backup"* ]]
    [[ "$output" == *"--check-updates"* ]]
    [[ "$output" == *"--version"* ]]
}
