#!/usr/bin/env bats
# Tests für validate_client_name — Whitelist-Validierung gegen Pfad-Traversal
# und Shell-Sonderzeichen in Client-Namen.

setup() {
    load '../test_helper'
    load_script
}

@test "validate_client_name akzeptiert einfachen Buchstabennamen" {
    run validate_client_name "laptop"
    [ "$status" -eq 0 ]
}

@test "validate_client_name akzeptiert Bindestrich und Underscore" {
    run validate_client_name "laptop-user_01"
    [ "$status" -eq 0 ]
}

@test "validate_client_name akzeptiert 32-Zeichen-Maximum" {
    run validate_client_name "abcdefghijklmnopqrstuvwxyz123456"
    [ "$status" -eq 0 ]
}

@test "validate_client_name lehnt leeren Namen ab" {
    run validate_client_name ""
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt 33-Zeichen-Namen ab" {
    run validate_client_name "abcdefghijklmnopqrstuvwxyz1234567"
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt Pfad-Traversal ab" {
    run validate_client_name "../etc/passwd"
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt Slash ab" {
    run validate_client_name "foo/bar"
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt Leerzeichen ab" {
    run validate_client_name "foo bar"
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt Shell-Metas ab (Dollar)" {
    run validate_client_name 'foo$bar'
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt Shell-Metas ab (Semicolon)" {
    run validate_client_name "foo;bar"
    [ "$status" -ne 0 ]
}

@test "validate_client_name lehnt Backticks ab" {
    run validate_client_name 'foo`bar`'
    [ "$status" -ne 0 ]
}
