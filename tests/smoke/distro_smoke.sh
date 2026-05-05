#!/usr/bin/env bash
# Distro-Smoke-Test: läuft im CI-Container pro Distribution.
# Strategie: das Skript wirklich gegen den Paketmanager laufen lassen — wenn ein
# distroabhängiger Paketname falsch ist (wie das Alpine-`qrencode`-Issue),
# schlägt `install_dependencies` fehl und der Test bricht ab.
#
# Aufruf: distro_smoke.sh <expected_distro>
#   z. B. distro_smoke.sh alpine

set -uo pipefail

EXPECTED_DISTRO="${1:-}"
if [[ -z "$EXPECTED_DISTRO" ]]; then
    echo "Usage: $0 <expected_distro>" >&2
    exit 2
fi

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/wireguard_setup.sh"
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "FAIL: Skript nicht gefunden: $SCRIPT_PATH" >&2
    exit 2
fi

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

# Skript via source einbinden — Source-Guard verhindert main()
# shellcheck disable=SC1090
source "$SCRIPT_PATH"

# 1. Distro-Detection
detect_distro
if [[ "$DISTRO" != "$EXPECTED_DISTRO" ]]; then
    fail "detect_distro lieferte '$DISTRO', erwartet '$EXPECTED_DISTRO'"
fi
pass "detect_distro = $DISTRO"

# 2. Dependency-Install (real — schlägt bei falschem Paketnamen fehl)
echo "--- install_dependencies start ---"
if ! install_dependencies; then
    fail "install_dependencies fehlgeschlagen auf $DISTRO"
fi
echo "--- install_dependencies done ---"
pass "install_dependencies erfolgreich"

# 3. Critical Tools verfügbar?
for tool in wg qrencode; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        fail "$tool nicht im PATH nach install_dependencies"
    fi
    pass "$tool verfügbar: $(command -v "$tool")"
done

echo "===> ALL CHECKS PASSED on $DISTRO"
