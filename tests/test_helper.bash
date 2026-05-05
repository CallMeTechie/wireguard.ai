#!/usr/bin/env bash
# Gemeinsamer Helper für alle bats-Tests.
# Quellt das Setup-Skript per source — der Source-Guard verhindert, dass
# main() startet. So sind alle Funktionen isoliert testbar.

SCRIPT_PATH="${BATS_TEST_DIRNAME}/../../wireguard_setup.sh"

# Lädt das Skript in die aktuelle Shell. Vorher Logging stummschalten,
# damit Tests nicht von Skript-Output verunreinigt werden.
load_script() {
    silence_logging
    # shellcheck disable=SC1090
    source "$SCRIPT_PATH"
    # error() im Skript ruft exit 1 auf — für Tests durch nicht-fatales
    # Verhalten ersetzen, damit der Test-Runner weiterläuft.
    silence_logging
}

# Stille Stubs für Logging.
silence_logging() {
    log() { :; }
    warn() { :; }
    success() { :; }
    error() { echo "ERROR: $*" >&2; return 1; }
}
