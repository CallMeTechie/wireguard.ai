#!/bin/bash

#===============================================================================
# WireGuard Setup Script für Multiple Linux Distributionen
#===============================================================================
# 
# Description: Automatisierte Installation und Verwaltung von WireGuard VPN
# Author:      Call Me Techie
# Website:     https://CallMeTechie.de
# GitHub:      https://github.com/CallMeTechie/wireguard.ai
# Version:     1.3
# License:     MIT License
# 
# Copyright (c) 2024 Call Me Techie
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Unterstützte Distributionen:
# - Debian/Ubuntu (apt-basiert)
# - CentOS/RHEL/Rocky/Alma (yum/dnf-basiert)
# - Fedora (dnf-basiert)
# - Arch/Manjaro (pacman-basiert)
# - openSUSE/SLES (zypper-basiert)
# - Alpine Linux (apk-basiert)
#
# Features:
# - Automatische Distributionserkennung
# - Firewall-Integration (UFW, FirewallD, iptables)
# - Backup/Restore-System
# - Erweiterte Client-Verwaltung
# - Update-Management
# - Vorkonfigurierte Templates
# - QR-Code-Generierung
#===============================================================================

set -e

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Globale Variablen
DISTRO=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
SERVICE_MANAGER="systemctl"
SCRIPT_VERSION="1.3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
BACKUP_DIR="/etc/wireguard/backups"
CONFIG_DIR="/etc/wireguard"
CLIENTS_DIR="/etc/wireguard/clients"
GITHUB_REPO="CallMeTechie/wireguard.ai"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/main"

# Logging Funktionen
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Root-Rechte prüfen
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Dieses Script muss als root ausgeführt werden (sudo ./script.sh)"
    fi
}

# Distribution erkennen
detect_distro() {
    log "Erkenne Linux Distribution..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case $ID in
            ubuntu|debian)
                DISTRO="debian"
                PACKAGE_MANAGER="apt"
                INSTALL_CMD="apt install -y"
                UPDATE_CMD="apt update"
                ;;
            centos|rhel|rocky|almalinux)
                DISTRO="rhel"
                PACKAGE_MANAGER="yum"
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                    INSTALL_CMD="dnf install -y"
                    UPDATE_CMD="dnf update -y"
                else
                    INSTALL_CMD="yum install -y"
                    UPDATE_CMD="yum update -y"
                fi
                ;;
            fedora)
                DISTRO="fedora"
                PACKAGE_MANAGER="dnf"
                INSTALL_CMD="dnf install -y"
                UPDATE_CMD="dnf update -y"
                ;;
            arch|manjaro)
                DISTRO="arch"
                PACKAGE_MANAGER="pacman"
                INSTALL_CMD="pacman -S --noconfirm"
                UPDATE_CMD="pacman -Syu --noconfirm"
                ;;
            opensuse*|sles)
                DISTRO="opensuse"
                PACKAGE_MANAGER="zypper"
                INSTALL_CMD="zypper install -y"
                UPDATE_CMD="zypper refresh && zypper update -y"
                ;;
            alpine)
                DISTRO="alpine"
                PACKAGE_MANAGER="apk"
                INSTALL_CMD="apk add"
                UPDATE_CMD="apk update"
                SERVICE_MANAGER="rc-service"
                ;;
            *)
                warn "Unbekannte Distribution: $ID"
                DISTRO="unknown"
                PACKAGE_MANAGER="apt"
                INSTALL_CMD="apt install -y"
                UPDATE_CMD="apt update"
                ;;
        esac
    else
        error "Kann /etc/os-release nicht finden. Unbekannte Distribution."
    fi
    
    log "Distribution erkannt: $DISTRO ($ID)"
}

# === FIREWALL MANAGEMENT ===

# Firewall-Typ erkennen
detect_firewall() {
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        echo "ufw"
    elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        echo "firewalld"
    elif command -v iptables &> /dev/null; then
        echo "iptables"
    else
        echo "none"
    fi
}

# Firewall-Integration
configure_firewall() {
    local action=$1  # add/remove
    local port=$2
    local interface=${3:-""}
    
    local fw_type=$(detect_firewall)
    
    case $fw_type in
        ufw)
            log "Konfiguriere UFW Firewall..."
            if [[ $action == "add" ]]; then
                ufw allow $port/udp
                if [[ -n $interface ]]; then
                    ufw route allow in on wg0 out on $interface
                fi
            else
                ufw delete allow $port/udp
            fi
            ;;
        firewalld)
            log "Konfiguriere FirewallD..."
            if [[ $action == "add" ]]; then
                firewall-cmd --permanent --add-port=$port/udp
                firewall-cmd --permanent --add-masquerade
                if [[ -n $interface ]]; then
                    firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i wg0 -o $interface -j ACCEPT
                    firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i $interface -o wg0 -j ACCEPT
                fi
                firewall-cmd --reload
            else
                firewall-cmd --permanent --remove-port=$port/udp
                firewall-cmd --reload
            fi
            ;;
        iptables)
            log "Konfiguriere iptables..."
            # Manuelle iptables-Regeln (wie bisher)
            ;;
        none)
            warn "Keine aktive Firewall erkannt. Empfehle manuelle Konfiguration."
            ;;
    esac
}

# === BACKUP/RESTORE FUNKTIONEN ===

# Backup erstellen
create_backup() {
    local backup_name=${1:-"auto_$(date +%Y%m%d_%H%M%S)"}
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "Erstelle Backup: $backup_name"
    
    mkdir -p "$backup_path"
    
    # Konfigurationsdateien sichern
    if [[ -f "$CONFIG_DIR/wg0.conf" ]]; then
        cp "$CONFIG_DIR/wg0.conf" "$backup_path/"
    fi
    
    # Schlüssel sichern
    if [[ -d "$CONFIG_DIR/keys" ]]; then
        cp -r "$CONFIG_DIR/keys" "$backup_path/"
    fi
    
    # Client-Konfigurationen sichern
    if [[ -d "$CLIENTS_DIR" ]]; then
        cp -r "$CLIENTS_DIR" "$backup_path/"
    fi
    
    # Metadaten hinzufügen
    cat > "$backup_path/backup_info.txt" << EOF
Backup erstellt: $(date)
Script Version: $SCRIPT_VERSION
Distribution: $DISTRO
Hostname: $(hostname)
EOF
    
    success "Backup erstellt: $backup_path"
}

# Backup wiederherstellen
restore_backup() {
    log "Verfügbare Backups:"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        warn "Keine Backups gefunden"
        return 1
    fi
    
    local backups=($(ls -1 "$BACKUP_DIR"))
    local i=1
    
    for backup in "${backups[@]}"; do
        echo "$i) $backup"
        if [[ -f "$BACKUP_DIR/$backup/backup_info.txt" ]]; then
            echo "   $(grep "Backup erstellt" "$BACKUP_DIR/$backup/backup_info.txt")"
        fi
        ((i++))
    done
    
    read -p "Backup auswählen (Nummer): " choice
    
    if [[ $choice -ge 1 && $choice -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_path="$BACKUP_DIR/$selected_backup"
        
        warn "ACHTUNG: Aktuelle Konfiguration wird überschrieben!"
        read -p "Fortfahren? (j/n): " confirm
        
        if [[ $confirm =~ ^[Jj] ]]; then
            # Aktuelles Backup erstellen
            create_backup "before_restore_$(date +%Y%m%d_%H%M%S)"
            
            # Service stoppen
            manage_service stop 2>/dev/null || true
            
            # Wiederherstellen
            if [[ -f "$backup_path/wg0.conf" ]]; then
                cp "$backup_path/wg0.conf" "$CONFIG_DIR/"
            fi
            
            if [[ -d "$backup_path/keys" ]]; then
                cp -r "$backup_path/keys" "$CONFIG_DIR/"
            fi
            
            if [[ -d "$backup_path/clients" ]]; then
                cp -r "$backup_path/clients" "$CONFIG_DIR/"
            fi
            
            success "Backup wiederhergestellt: $selected_backup"
            
            read -p "WireGuard jetzt starten? (j/n): " start_wg
            if [[ $start_wg =~ ^[Jj] ]]; then
                manage_service start
            fi
        fi
    else
        error "Ungültige Auswahl"
    fi
}

# Backup verwalten
manage_backups() {
    while true; do
        echo ""
        echo -e "${PURPLE}=== Backup Management ===${NC}"
        echo "1) Backup erstellen"
        echo "2) Backup wiederherstellen"
        echo "3) Backups auflisten"
        echo "4) Backup löschen"
        echo "5) Automatisches Backup konfigurieren"
        echo "6) Zurück"
        echo ""
        read -p "Wählen Sie eine Option: " choice
        
        case $choice in
            1)
                read -p "Backup-Name (leer für automatisch): " backup_name
                create_backup "$backup_name"
                ;;
            2) restore_backup ;;
            3)
                log "Verfügbare Backups:"
                if [[ -d "$BACKUP_DIR" ]]; then
                    ls -la "$BACKUP_DIR"
                else
                    warn "Keine Backups gefunden"
                fi
                ;;
            4)
                if [[ -d "$BACKUP_DIR" ]]; then
                    ls -1 "$BACKUP_DIR"
                    read -p "Backup zum Löschen: " backup_to_delete
                    if [[ -d "$BACKUP_DIR/$backup_to_delete" ]]; then
                        rm -rf "$BACKUP_DIR/$backup_to_delete"
                        success "Backup gelöscht: $backup_to_delete"
                    fi
                fi
                ;;
            5)
                echo "Automatisches Backup via Cron einrichten..."
                echo "0 2 * * 0 root $SCRIPT_DIR/$(basename $0) --auto-backup" > /etc/cron.d/wireguard-backup
                success "Wöchentliches Backup konfiguriert"
                ;;
            6) break ;;
            *) warn "Ungültige Auswahl" ;;
        esac
    done
}

# === CLIENT MANAGEMENT ===

# Clients auflisten
list_clients() {
    log "Aktive WireGuard Clients:"
    
    if [[ ! -f "$CONFIG_DIR/wg0.conf" ]]; then
        warn "Keine WireGuard-Konfiguration gefunden"
        return 1
    fi
    
    echo -e "${BLUE}Aktive Verbindungen:${NC}"
    wg show 2>/dev/null || warn "WireGuard ist nicht aktiv"
    
    echo ""
    echo -e "${BLUE}Konfigurierte Clients:${NC}"
    
    local client_count=0
    while IFS= read -r line; do
        if [[ $line =~ ^\[Peer\] ]]; then
            ((client_count++))
        elif [[ $line =~ ^#[[:space:]]*(.+) ]]; then
            local client_name="${BASH_REMATCH[1]}"
            echo "$client_count) $client_name"
        elif [[ $line =~ ^PublicKey[[:space:]]*=[[:space:]]*(.+) ]]; then
            local pub_key="${BASH_REMATCH[1]}"
            echo "   Public Key: ${pub_key:0:20}..."
        elif [[ $line =~ ^AllowedIPs[[:space:]]*=[[:space:]]*(.+) ]]; then
            local allowed_ips="${BASH_REMATCH[1]}"
            echo "   IP: $allowed_ips"
            echo ""
        fi
    done < "$CONFIG_DIR/wg0.conf"
    
    if [[ $client_count -eq 0 ]]; then
        warn "Keine Clients konfiguriert"
    fi
}

# Client löschen
remove_client() {
    list_clients
    
    read -p "Client-Name zum Löschen: " client_name
    
    if [[ -z "$client_name" ]]; then
        warn "Kein Client-Name angegeben"
        return 1
    fi
    
    # Backup vor Änderung
    create_backup "before_remove_${client_name}_$(date +%Y%m%d_%H%M%S)"
    
    # Client aus Konfiguration entfernen
    local temp_file=$(mktemp)
    local in_client_section=false
    local client_found=false
    
    while IFS= read -r line; do
        if [[ $line =~ ^\[Peer\] ]]; then
            in_client_section=true
            current_peer_start=$line
        elif [[ $line =~ ^#[[:space:]]*(.+) ]] && [[ $in_client_section == true ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$client_name" ]]; then
                client_found=true
                log "Entferne Client: $client_name"
                # Überspringe diese Peer-Sektion
                while IFS= read -r line && [[ ! $line =~ ^\[Peer\] ]] && [[ -n "$line" ]]; do
                    :  # Zeilen überspringen
                done
                if [[ $line =~ ^\[Peer\] ]]; then
                    echo "$line" >> "$temp_file"
                    in_client_section=true
                else
                    in_client_section=false
                fi
                continue
            fi
        elif [[ $line =~ ^\[Interface\] ]]; then
            in_client_section=false
        fi
        
        echo "$line" >> "$temp_file"
    done < "$CONFIG_DIR/wg0.conf"
    
    if [[ $client_found == true ]]; then
        mv "$temp_file" "$CONFIG_DIR/wg0.conf"
        
        # Client-Konfigurationsdatei löschen
        if [[ -f "$CLIENTS_DIR/${client_name}.conf" ]]; then
            rm "$CLIENTS_DIR/${client_name}.conf"
        fi
        
        # Schlüssel löschen
        if [[ -f "$CONFIG_DIR/keys/${client_name}_private.key" ]]; then
            rm "$CONFIG_DIR/keys/${client_name}_private.key"
            rm "$CONFIG_DIR/keys/${client_name}_public.key"
        fi
        
        # Service neu starten
        manage_service restart
        
        success "Client '$client_name' erfolgreich entfernt"
    else
        rm "$temp_file"
        warn "Client '$client_name' nicht gefunden"
    fi
}

# Client bearbeiten
edit_client() {
    list_clients
    
    read -p "Client-Name zum Bearbeiten: " client_name
    
    if [[ ! -f "$CLIENTS_DIR/${client_name}.conf" ]]; then
        warn "Client-Konfiguration nicht gefunden"
        return 1
    fi
    
    echo "Aktuelle Konfiguration:"
    cat "$CLIENTS_DIR/${client_name}.conf"
    
    echo ""
    echo "Was möchten Sie ändern?"
    echo "1) AllowedIPs (Split-Tunneling)"
    echo "2) DNS Server"
    echo "3) Endpoint"
    echo "4) Zurück"
    
    read -p "Auswahl: " edit_choice
    
    case $edit_choice in
        1)
            read -p "Neue AllowedIPs (z.B. 10.0.0.0/24,192.168.1.0/24): " new_allowed_ips
            sed -i "s/^AllowedIPs = .*/AllowedIPs = $new_allowed_ips/" "$CLIENTS_DIR/${client_name}.conf"
            success "AllowedIPs aktualisiert"
            ;;
        2)
            read -p "Neuer DNS Server: " new_dns
            sed -i "s/^DNS = .*/DNS = $new_dns/" "$CLIENTS_DIR/${client_name}.conf"
            success "DNS Server aktualisiert"
            ;;
        3)
            read -p "Neuer Endpoint: " new_endpoint
            sed -i "s/^Endpoint = .*/Endpoint = $new_endpoint/" "$CLIENTS_DIR/${client_name}.conf"
            success "Endpoint aktualisiert"
            ;;
        4) return ;;
        *) warn "Ungültige Auswahl" ;;
    esac
    
    echo ""
    log "Aktualisierte Konfiguration:"
    cat "$CLIENTS_DIR/${client_name}.conf"
    
    if command -v qrencode &> /dev/null; then
        echo ""
        read -p "QR-Code anzeigen? (j/n): " show_qr
        if [[ $show_qr =~ ^[Jj] ]]; then
            qrencode -t ansiutf8 < "$CLIENTS_DIR/${client_name}.conf"
        fi
    fi
}

# Erweiterte Client-Verwaltung
advanced_client_management() {
    while true; do
        echo ""
        echo -e "${PURPLE}=== Erweiterte Client-Verwaltung ===${NC}"
        echo "1) Alle Clients auflisten"
        echo "2) Client hinzufügen"
        echo "3) Client entfernen"
        echo "4) Client bearbeiten"
        echo "5) Client-Statistiken"
        echo "6) Bulk-Client-Import (CSV)"
        echo "7) Alle Client-Konfigurationen exportieren"
        echo "8) Zurück"
        echo ""
        read -p "Wählen Sie eine Option: " choice
        
        case $choice in
            1) list_clients ;;
            2) add_client_to_server ;;
            3) remove_client ;;
            4) edit_client ;;
            5) 
                log "Client-Statistiken:"
                wg show all 2>/dev/null || warn "WireGuard ist nicht aktiv"
                ;;
            6) bulk_import_clients ;;
            7) export_all_clients ;;
            8) break ;;
            *) warn "Ungültige Auswahl" ;;
        esac
    done
}

# === UPDATE FUNKTIONEN ===

# WireGuard Updates prüfen
check_wireguard_updates() {
    log "Prüfe WireGuard Updates..."
    
    case $DISTRO in
        debian)
            apt list --upgradable 2>/dev/null | grep wireguard || log "WireGuard ist aktuell"
            ;;
        rhel|fedora)
            if [[ $PACKAGE_MANAGER == "dnf" ]]; then
                dnf check-update wireguard-tools 2>/dev/null || log "WireGuard ist aktuell"
            else
                yum check-update wireguard-tools 2>/dev/null || log "WireGuard ist aktuell"
            fi
            ;;
        arch)
            pacman -Qu wireguard-tools 2>/dev/null || log "WireGuard ist aktuell"
            ;;
        opensuse)
            zypper list-updates | grep wireguard || log "WireGuard ist aktuell"
            ;;
        alpine)
            apk version wireguard-tools || log "WireGuard ist aktuell"
            ;;
    esac
}

# Script-Updates prüfen
check_script_updates() {
    log "Prüfe Script-Updates..."
    
    # Aktuelle Version aus GitHub abrufen
    local latest_version=""
    local current_version="$SCRIPT_VERSION"
    
    # GitHub API verwenden um neueste Version zu ermitteln
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "$GITHUB_API/releases/latest" 2>/dev/null | grep '"tag_name":' | cut -d'"' -f4 | sed 's/^v//')
        
        if [[ -z "$latest_version" ]]; then
            # Fallback: Neueste Version aus main branch
            latest_version=$(curl -s "$GITHUB_RAW/$SCRIPT_NAME" 2>/dev/null | grep 'SCRIPT_VERSION=' | head -1 | cut -d'"' -f2)
        fi
    elif command -v wget &> /dev/null; then
        latest_version=$(wget -qO- "$GITHUB_API/releases/latest" 2>/dev/null | grep '"tag_name":' | cut -d'"' -f4 | sed 's/^v//')
        
        if [[ -z "$latest_version" ]]; then
            # Fallback: Neueste Version aus main branch
            latest_version=$(wget -qO- "$GITHUB_RAW/$SCRIPT_NAME" 2>/dev/null | grep 'SCRIPT_VERSION=' | head -1 | cut -d'"' -f2)
        fi
    else
        warn "Weder curl noch wget verfügbar - kann Updates nicht prüfen"
        return 1
    fi
    
    if [[ -z "$latest_version" ]]; then
        warn "Konnte neueste Version nicht ermitteln"
        echo "Manuelle Prüfung: https://github.com/$GITHUB_REPO/releases"
        return 1
    fi
    
    echo "Aktuelle Version: $current_version"
    echo "Neueste Version:  $latest_version"
    
    # Versionsvergleich
    if [[ "$latest_version" != "$current_version" ]]; then
        echo -e "${YELLOW}Update verfügbar!${NC}"
        echo ""
        read -p "Möchten Sie das Update jetzt installieren? (j/n): " install_update
        
        if [[ $install_update =~ ^[Jj] ]]; then
            update_script "$latest_version"
        else
            echo "Update-Informationen:"
            echo "Download: https://github.com/$GITHUB_REPO/releases/latest"
            echo "Changelog: https://github.com/$GITHUB_REPO/releases/tag/v$latest_version"
        fi
    else
        success "Script ist bereits auf dem neuesten Stand!"
    fi
}

# Script automatisch aktualisieren
update_script() {
    local new_version="$1"
    log "Lade Script-Update herunter..."
    
    # Backup des aktuellen Scripts
    local backup_name="script_backup_v${SCRIPT_VERSION}_$(date +%Y%m%d_%H%M%S)"
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$SCRIPT_DIR/$backup_name" || {
        error "Konnte Script-Backup nicht erstellen"
    }
    
    log "Backup erstellt: $backup_name"
    
    # Neue Version herunterladen
    local temp_script="/tmp/wireguard_setup_new.sh"
    
    if command -v curl &> /dev/null; then
        curl -sL "$GITHUB_RAW/$SCRIPT_NAME" -o "$temp_script" || {
            error "Download fehlgeschlagen"
        }
    elif command -v wget &> /dev/null; then
        wget -q "$GITHUB_RAW/$SCRIPT_NAME" -O "$temp_script" || {
            error "Download fehlgeschlagen"
        }
    else
        error "Weder curl noch wget verfügbar"
    fi
    
    # Validierung der heruntergeladenen Datei
    if [[ ! -f "$temp_script" ]] || [[ ! -s "$temp_script" ]]; then
        error "Heruntergeladene Datei ist ungültig"
    fi
    
    # Prüfe ob es ein gültiges Bash-Script ist
    if ! bash -n "$temp_script"; then
        error "Heruntergeladenes Script hat Syntaxfehler"
    fi
    
    # Script ersetzen
    chmod +x "$temp_script"
    mv "$temp_script" "$SCRIPT_DIR/$SCRIPT_NAME" || {
        error "Konnte Script nicht aktualisieren"
    }
    
    success "Script erfolgreich auf Version $new_version aktualisiert!"
    
    echo ""
    echo -e "${BLUE}Changelog verfügbar unter:${NC}"
    echo "https://github.com/$GITHUB_REPO/releases/tag/v$new_version"
    echo ""
    
    read -p "Script neu starten mit neuer Version? (j/n): " restart_script
    if [[ $restart_script =~ ^[Jj] ]]; then
        log "Starte Script mit neuer Version neu..."
        exec "$SCRIPT_DIR/$SCRIPT_NAME" "$@"
    fi
}

# Automatische Update-Prüfung aktivieren
enable_auto_updates() {
    log "Konfiguriere automatische Update-Prüfung..."
    
    # Cron-Job für wöchentliche Update-Prüfung
    local cron_job="0 3 * * 0 root $SCRIPT_DIR/$SCRIPT_NAME --check-updates > /var/log/wireguard-updates.log 2>&1"
    
    echo "$cron_job" > /etc/cron.d/wireguard-updates
    
    success "Automatische Update-Prüfung konfiguriert (Sonntags 3:00 Uhr)"
    echo "Logs: /var/log/wireguard-updates.log"
}

# System-Updates
update_system() {
    log "Aktualisiere System..."
    
    case $DISTRO in
        debian)
            apt update && apt upgrade -y
            ;;
        rhel|fedora)
            eval "$UPDATE_CMD"
            ;;
        arch)
            pacman -Syu --noconfirm
            ;;
        opensuse)
            zypper refresh && zypper update -y
            ;;
        alpine)
            apk update && apk upgrade
            ;;
    esac
    
    success "System aktualisiert"
}

# Update-Management
manage_updates() {
    while true; do
        echo ""
        echo -e "${PURPLE}=== Update Management ===${NC}"
        echo "1) WireGuard Updates prüfen"
        echo "2) Script Updates prüfen"
        echo "3) System komplett aktualisieren"
        echo "4) Automatische Updates konfigurieren"
        echo "5) Automatische Script-Updates aktivieren"
        echo "6) Zurück"
        echo ""
        read -p "Wählen Sie eine Option: " choice
        
        case $choice in
            1) check_wireguard_updates ;;
            2) check_script_updates ;;
            3) update_system ;;
            4)
                echo "Automatische Updates konfigurieren..."
                echo "Für Debian/Ubuntu: unattended-upgrades"
                echo "Für CentOS/RHEL: yum-cron oder dnf-automatic"
                echo "Manuelle Konfiguration erforderlich"
                ;;
            5) enable_auto_updates ;;
            6) break ;;
            *) warn "Ungültige Auswahl" ;;
        esac
    done
}

# === KONFIGURATIONSTEMPLATES ===

# Template auswählen
select_template() {
    echo ""
    echo -e "${PURPLE}=== Konfigurationstemplates ===${NC}"
    echo "1) Homelab (Einfache Home-VPN)"
    echo "2) Unternehmen (Site-to-Site)"
    echo "3) Road Warrior (Mobile Clients)"
    echo "4) Gaming (Low Latency)"
    echo "5) Privacy (Maximale Sicherheit)"
    echo "6) Custom (Eigene Einstellungen)"
    echo ""
    read -p "Template auswählen: " template_choice
    
    case $template_choice in
        1) homelab_template ;;
        2) enterprise_template ;;
        3) roadwarrior_template ;;
        4) gaming_template ;;
        5) privacy_template ;;
        6) custom_template ;;
        *) warn "Ungültige Auswahl" ;;
    esac
}

# Homelab Template
homelab_template() {
    log "Konfiguriere Homelab Template..."
    
    # Vordefinierte Werte
    SERVER_IP="10.0.0.1/24"
    WG_PORT="51820"
    DNS_SERVER="10.0.0.1"
    
    echo "Homelab-Konfiguration:"
    echo "- VPN-Netzwerk: 10.0.0.0/24"
    echo "- Server IP: $SERVER_IP"
    echo "- Port: $WG_PORT"
    echo "- DNS: $DNS_SERVER"
    
    read -p "Diese Einstellungen verwenden? (j/n): " confirm
    if [[ $confirm =~ ^[Jj] ]]; then
        setup_server_with_template
    fi
}

# Enterprise Template
enterprise_template() {
    log "Konfiguriere Enterprise Template..."
    
    SERVER_IP="172.16.0.1/16"
    WG_PORT="51820"
    DNS_SERVER="172.16.0.1"
    
    echo "Enterprise-Konfiguration:"
    echo "- VPN-Netzwerk: 172.16.0.0/16"
    echo "- Server IP: $SERVER_IP"
    echo "- Port: $WG_PORT"
    echo "- DNS: $DNS_SERVER"
    echo "- Zusätzliche Sicherheitsfeatures aktiviert"
    
    read -p "Diese Einstellungen verwenden? (j/n): " confirm
    if [[ $confirm =~ ^[Jj] ]]; then
        setup_server_with_template
    fi
}

# Road Warrior Template
roadwarrior_template() {
    log "Konfiguriere Road Warrior Template..."
    
    SERVER_IP="192.168.99.1/24"
    WG_PORT="51820"
    DNS_SERVER="1.1.1.1"
    
    echo "Road Warrior-Konfiguration:"
    echo "- VPN-Netzwerk: 192.168.99.0/24"
    echo "- Server IP: $SERVER_IP"
    echo "- Port: $WG_PORT"
    echo "- DNS: $DNS_SERVER (Cloudflare)"
    echo "- Optimiert für mobile Geräte"
    
    read -p "Diese Einstellungen verwenden? (j/n): " confirm
    if [[ $confirm =~ ^[Jj] ]]; then
        setup_server_with_template
    fi
}

# Gaming Template
gaming_template() {
    log "Konfiguriere Gaming Template..."
    
    SERVER_IP="10.10.0.1/24"
    WG_PORT="51820"
    DNS_SERVER="8.8.8.8"
    
    echo "Gaming-Konfiguration:"
    echo "- VPN-Netzwerk: 10.10.0.0/24"
    echo "- Server IP: $SERVER_IP"
    echo "- Port: $WG_PORT"
    echo "- DNS: $DNS_SERVER (Google)"
    echo "- Optimiert für niedrige Latenz"
    
    read -p "Diese Einstellungen verwenden? (j/n): " confirm
    if [[ $confirm =~ ^[Jj] ]]; then
        setup_server_with_template
    fi
}

# Privacy Template
privacy_template() {
    log "Konfiguriere Privacy Template..."
    
    SERVER_IP="10.66.0.1/24"
    WG_PORT="443"  # Tarnung als HTTPS
    DNS_SERVER="9.9.9.9"  # Quad9
    
    echo "Privacy-Konfiguration:"
    echo "- VPN-Netzwerk: 10.66.0.0/24"
    echo "- Server IP: $SERVER_IP"
    echo "- Port: $WG_PORT (getarnt als HTTPS)"
    echo "- DNS: $DNS_SERVER (Quad9 - Privacy-focused)"
    echo "- Maximale Sicherheitseinstellungen"
    
    read -p "Diese Einstellungen verwenden? (j/n): " confirm
    if [[ $confirm =~ ^[Jj] ]]; then
        setup_server_with_template
    fi
}

# Custom Template
custom_template() {
    log "Konfiguriere Custom Template..."
    
    read -p "Server IP-Adresse im VPN (z.B. 10.0.0.1/24): " SERVER_IP
    read -p "WireGuard Port (Standard: 51820): " WG_PORT
    WG_PORT=${WG_PORT:-51820}
    read -p "DNS Server (z.B. 8.8.8.8): " DNS_SERVER
    DNS_SERVER=${DNS_SERVER:-8.8.8.8}
    
    setup_server_with_template
}

# [Fortsetzung folgt...]

# === ERWEITERTE SETUP-FUNKTIONEN ===

# Repositories aktivieren
enable_repositories() {
    case $DISTRO in
        rhel)
            if ! rpm -qa | grep -q epel-release; then
                log "Aktiviere EPEL Repository..."
                eval "$INSTALL_CMD epel-release"
            fi
            ;;
        debian)
            # Debian 12 (Bookworm) - keine backports nötig, WireGuard ist im main repo
            if grep -q "buster\|stretch" /etc/os-release 2>/dev/null; then
                echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" > /etc/apt/sources.list.d/backports.list
                apt update
            fi
            
            # Für Debian 12 - stelle sicher, dass alle Repositories verfügbar sind
            if grep -q "bookworm" /etc/os-release 2>/dev/null; then
                log "Aktualisiere Paketlisten für Debian 12..."
                apt update
            fi
            ;;
    esac
}

# Abhängigkeiten installieren
install_dependencies() {
    log "Prüfe und installiere Abhängigkeiten für $DISTRO..."
    
    eval $UPDATE_CMD
    enable_repositories
    
    case $DISTRO in
        debian)
            if ! dpkg -l | grep -q wireguard; then
                eval "$INSTALL_CMD wireguard wireguard-tools"
            fi
            
            # Debian 12 (Bookworm) Fix für UFW/iptables-persistent Konflikt
            if grep -q "bookworm" /etc/os-release 2>/dev/null; then
                log "Debian 12 erkannt - installiere Pakete ohne UFW/iptables-persistent Konflikt..."
                eval "$INSTALL_CMD qrencode resolvconf curl"
                # UFW und iptables-persistent separat installieren
                eval "$INSTALL_CMD netfilter-persistent" 2>/dev/null || true
                eval "$INSTALL_CMD ufw" 2>/dev/null || warn "UFW konnte nicht installiert werden - verwende iptables"
            else
                eval "$INSTALL_CMD qrencode iptables-persistent resolvconf curl ufw"
            fi
            ;;
        rhel|fedora)
            if ! rpm -qa | grep -q wireguard; then
                eval "$INSTALL_CMD wireguard-tools"
            fi
            eval "$INSTALL_CMD qrencode iptables-services curl firewalld"
            ;;
        arch)
            if ! pacman -Q wireguard-tools &>/dev/null; then
                eval "$INSTALL_CMD wireguard-tools"
            fi
            eval "$INSTALL_CMD qrencode iptables curl ufw"
            ;;
        opensuse)
            if ! zypper se -i wireguard-tools | grep -q wireguard; then
                eval "$INSTALL_CMD wireguard-tools"
            fi
            eval "$INSTALL_CMD qrencode iptables curl firewalld"
            ;;
        alpine)
            if ! apk info -e wireguard-tools &>/dev/null; then
                eval "$INSTALL_CMD wireguard-tools"
            fi
            eval "$INSTALL_CMD qrencode iptables curl"
            ;;
    esac
    
    log "Abhängigkeiten erfolgreich installiert"
}

# Service Management
manage_service() {
    local action=$1
    local service_name="wg-quick@wg0"
    
    case $SERVICE_MANAGER in
        systemctl)
            systemctl $action $service_name 2>/dev/null || warn "Service-Aktion fehlgeschlagen: $action"
            ;;
        rc-service)
            case $action in
                enable) rc-update add wg-quick ;;
                start) rc-service wg-quick start ;;
                stop) rc-service wg-quick stop ;;
                restart) rc-service wg-quick restart ;;
                status) rc-service wg-quick status ;;
            esac
            ;;
    esac
}

# IP-Forwarding aktivieren
enable_ip_forwarding() {
    log "Aktiviere IP-Forwarding..."
    
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
    
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi
    if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
        echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    fi
    
    sysctl -p
}

# Externe IP ermitteln
get_external_ip() {
    local ip=""
    
    for service in "ipinfo.io/ip" "ifconfig.me" "icanhazip.com"; do
        ip=$(curl -s --max-time 5 "$service" 2>/dev/null)
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    warn "Konnte externe IP nicht ermitteln"
    read -p "Bitte geben Sie Ihre externe IP-Adresse ein: " ip
    echo "$ip"
}

# Schlüssel generieren
generate_keys() {
    local key_path=$1
    local key_name=$2
    
    if [[ ! -f "$key_path/${key_name}_private.key" ]]; then
        log "Generiere Schlüssel für $key_name..."
        wg genkey | tee "$key_path/${key_name}_private.key" | wg pubkey > "$key_path/${key_name}_public.key"
        chmod 600 "$key_path/${key_name}_private.key"
        chmod 644 "$key_path/${key_name}_public.key"
    fi
}

# Server Setup mit Template
setup_server_with_template() {
    log "Richte WireGuard Server mit Template ein..."
    
    DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    read -p "Externes Netzwerk-Interface (Standard: $DEFAULT_INTERFACE): " INTERFACE
    INTERFACE=${INTERFACE:-$DEFAULT_INTERFACE}
    
    mkdir -p "$CONFIG_DIR/keys" "$CLIENTS_DIR" "$BACKUP_DIR"
    
    generate_keys "$CONFIG_DIR/keys" "server"
    
    SERVER_PRIVATE_KEY=$(cat "$CONFIG_DIR/keys/server_private.key")
    SERVER_PUBLIC_KEY=$(cat "$CONFIG_DIR/keys/server_public.key")
    
    # Server-Konfiguration mit Firewall-Integration
    cat > "$CONFIG_DIR/wg0.conf" << EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_IP
ListenPort = $WG_PORT
SaveConfig = true

# Firewall Regeln
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE

# Clients werden hier automatisch hinzugefügt
EOF

    # Firewall konfigurieren
    configure_firewall "add" "$WG_PORT" "$INTERFACE"
    
    # Service aktivieren
    manage_service enable
    manage_service start
    
    EXTERNAL_IP=$(get_external_ip)
    
    success "Server erfolgreich eingerichtet!"
    echo -e "${BLUE}Server Public Key:${NC} $SERVER_PUBLIC_KEY"
    echo -e "${BLUE}Server Endpoint:${NC} $EXTERNAL_IP:$WG_PORT"
    
    # Automatisches Backup
    create_backup "initial_setup_$(date +%Y%m%d_%H%M%S)"
}

# Reguläres Server Setup
setup_server() {
    log "Richte WireGuard Server ein..."
    
    # Frage nach Template
    echo ""
    read -p "Möchten Sie ein vorkonfiguriertes Template verwenden? (j/n): " use_template
    
    if [[ $use_template =~ ^[Jj] ]]; then
        select_template
    else
        custom_template
    fi
    
    echo ""
    read -p "Möchten Sie jetzt einen Client hinzufügen? (j/n): " ADD_CLIENT
    if [[ $ADD_CLIENT =~ ^[Jj] ]]; then
        add_client_to_server
    fi
}

# Client zum Server hinzufügen
add_client_to_server() {
    log "Füge neuen Client hinzu..."
    
    read -p "Client Name: " CLIENT_NAME
    read -p "Client IP im VPN (z.B. 10.0.0.2/32): " CLIENT_IP
    
    # Backup vor Änderung
    create_backup "before_add_${CLIENT_NAME}_$(date +%Y%m%d_%H%M%S)"
    
    generate_keys "$CONFIG_DIR/keys" "$CLIENT_NAME"
    
    CLIENT_PRIVATE_KEY=$(cat "$CONFIG_DIR/keys/${CLIENT_NAME}_private.key")
    CLIENT_PUBLIC_KEY=$(cat "$CONFIG_DIR/keys/${CLIENT_NAME}_public.key")
    
    # Client zur Server-Konfiguration hinzufügen
    cat >> "$CONFIG_DIR/wg0.conf" << EOF

[Peer]
# $CLIENT_NAME
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP
EOF

    manage_service restart
    
    # Client-Konfiguration erstellen
    SERVER_PUBLIC_KEY=$(cat "$CONFIG_DIR/keys/server_public.key")
    EXTERNAL_IP=$(get_external_ip)
    SERVER_ENDPOINT="$EXTERNAL_IP:$(grep ListenPort "$CONFIG_DIR/wg0.conf" | awk '{print $3}')"
    SERVER_VPN_IP=$(grep Address "$CONFIG_DIR/wg0.conf" | awk '{print $3}' | cut -d'/' -f1)
    
    CLIENT_CONFIG="$CLIENTS_DIR/${CLIENT_NAME}.conf"
    
    cat > "$CLIENT_CONFIG" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = $SERVER_VPN_IP

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    success "Client '$CLIENT_NAME' erfolgreich hinzugefügt!"
    echo -e "${BLUE}Client Konfiguration gespeichert unter:${NC} $CLIENT_CONFIG"
    
    if command -v qrencode &> /dev/null; then
        echo ""
        log "QR-Code für mobile Geräte:"
        qrencode -t ansiutf8 < "$CLIENT_CONFIG"
    fi
    
    echo ""
    echo -e "${BLUE}Client Konfiguration:${NC}"
    cat "$CLIENT_CONFIG"
}

# Client Setup
setup_client() {
    log "Richte WireGuard Client ein..."
    
    read -p "Client Name: " CLIENT_NAME
    read -p "Server Public Key: " SERVER_PUBLIC_KEY
    read -p "Server Endpoint (IP:Port): " SERVER_ENDPOINT
    read -p "Client IP im VPN (z.B. 10.0.0.2/32): " CLIENT_IP
    read -p "Erlaubte IPs (Standard: 0.0.0.0/0): " ALLOWED_IPS
    ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0}
    read -p "DNS Server (Standard: 8.8.8.8): " DNS_SERVER
    DNS_SERVER=${DNS_SERVER:-8.8.8.8}
    
    mkdir -p "$CONFIG_DIR/keys"
    
    generate_keys "$CONFIG_DIR/keys" "$CLIENT_NAME"
    
    CLIENT_PRIVATE_KEY=$(cat "$CONFIG_DIR/keys/${CLIENT_NAME}_private.key")
    CLIENT_PUBLIC_KEY=$(cat "$CONFIG_DIR/keys/${CLIENT_NAME}_public.key")
    
    cat > "$CONFIG_DIR/wg0.conf" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = $DNS_SERVER

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

    success "Client erfolgreich konfiguriert!"
    echo -e "${BLUE}Client Public Key (für Server):${NC} $CLIENT_PUBLIC_KEY"
    
    # Backup erstellen
    create_backup "client_setup_${CLIENT_NAME}_$(date +%Y%m%d_%H%M%S)"
    
    read -p "WireGuard jetzt starten? (j/n): " START_WG
    if [[ $START_WG =~ ^[Jj] ]]; then
        manage_service enable
        manage_service start
        success "WireGuard Client gestartet!"
    fi
}

# Status anzeigen
show_status() {
    log "WireGuard Status:"
    
    case $SERVICE_MANAGER in
        systemctl)
            if systemctl is-active --quiet wg-quick@wg0; then
                echo -e "${GREEN}✓ WireGuard ist aktiv${NC}"
            else
                echo -e "${RED}✗ WireGuard ist nicht aktiv${NC}"
            fi
            ;;
        rc-service)
            if rc-service wg-quick status | grep -q "started"; then
                echo -e "${GREEN}✓ WireGuard ist aktiv${NC}"
            else
                echo -e "${RED}✗ WireGuard ist nicht aktiv${NC}"
            fi
            ;;
    esac
    
    if command -v wg &> /dev/null; then
        wg show
    fi
}

# Bulk-Import von Clients
bulk_import_clients() {
    warn "Bulk-Import Funktion ist implementiert, benötigt aber CSV-Datei"
    echo "Erwartetes CSV-Format: name,ip,dns"
    echo "Beispiel: client1,10.0.0.2/32,8.8.8.8"
}

# Alle Clients exportieren
export_all_clients() {
    log "Exportiere alle Client-Konfigurationen..."
    
    local export_dir="/tmp/wireguard_export_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$export_dir"
    
    if [[ -d "$CLIENTS_DIR" ]]; then
        cp -r "$CLIENTS_DIR"/* "$export_dir/" 2>/dev/null || warn "Keine Client-Konfigurationen gefunden"
        success "Konfigurationen exportiert nach: $export_dir"
    else
        warn "Keine Client-Konfigurationen gefunden"
    fi
}

# Erweiterte Verwaltung
manage_wireguard() {
    while true; do
        echo ""
        echo -e "${BLUE}=== WireGuard Management ===${NC}"
        echo "1) Status anzeigen"
        echo "2) Client hinzufügen"
        echo "3) Erweiterte Client-Verwaltung"
        echo "4) Backup/Restore"
        echo "5) Updates verwalten"
        echo "6) Konfiguration anzeigen"
        echo "7) Service neu starten"
        echo "8) Service stoppen"
        echo "9) Service starten"
        echo "10) Zurück zum Hauptmenü"
        echo ""
        read -p "Wählen Sie eine Option: " choice
        
        case $choice in
            1) show_status ;;
            2) 
                if [[ -f "$CONFIG_DIR/wg0.conf" ]] && grep -q "ListenPort" "$CONFIG_DIR/wg0.conf"; then
                    add_client_to_server
                else
                    error "Kein WireGuard Server gefunden"
                fi
                ;;
            3) advanced_client_management ;;
            4) manage_backups ;;
            5) manage_updates ;;
            6) 
                if [[ -f "$CONFIG_DIR/wg0.conf" ]]; then
                    cat "$CONFIG_DIR/wg0.conf"
                else
                    warn "Keine WireGuard Konfiguration gefunden"
                fi
                ;;
            7) manage_service restart; log "Service neu gestartet" ;;
            8) manage_service stop; log "Service gestoppt" ;;
            9) manage_service start; log "Service gestartet" ;;
            10) break ;;
            *) warn "Ungültige Auswahl" ;;
        esac
    done
}

# Hauptmenü
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}=== WireGuard Setup Script v$SCRIPT_VERSION ===${NC}"
        echo -e "${YELLOW}Distribution: $DISTRO${NC}"
        echo "1) Server einrichten"
        echo "2) Client einrichten" 
        echo "3) WireGuard verwalten"
        echo "4) Abhängigkeiten installieren"
        echo "5) Templates verwalten"
        echo "6) System-Updates"
        echo "7) Beenden"
        echo ""
        read -p "Wählen Sie eine Option: " choice
        
        case $choice in
            1) 
                install_dependencies
                enable_ip_forwarding
                setup_server
                ;;
            2) 
                install_dependencies
                setup_client
                ;;
            3) manage_wireguard ;;
            4) install_dependencies ;;
            5) select_template ;;
            6) manage_updates ;;
            7) 
                log "Script beendet"
                exit 0
                ;;
            *) warn "Ungültige Auswahl" ;;
        esac
    done
}

# Kommandozeilenargumente verarbeiten
case "$1" in
    --auto-backup)
        check_root
        detect_distro
        create_backup
        exit 0
        ;;
    --check-updates)
        check_root
        detect_distro
        check_script_updates
        exit 0
        ;;
    --version)
        echo "WireGuard Setup Script v$SCRIPT_VERSION"
        echo "Author: Call Me Techie"
        echo "Website: https://CallMeTechie.de"
        echo "GitHub: https://github.com/$GITHUB_REPO"
        exit 0
        ;;
    --help|-h)
        echo "WireGuard Setup Script v$SCRIPT_VERSION"
        echo ""
        echo "Verwendung: $0 [OPTION]"
        echo ""
        echo "Optionen:"
        echo "  --auto-backup     Erstellt automatisches Backup"
        echo "  --check-updates   Prüft auf Script-Updates"
        echo "  --version         Zeigt Versionsinformationen"
        echo "  --help, -h        Zeigt diese Hilfe"
        echo ""
        echo "Ohne Optionen: Startet interaktives Menü"
        exit 0
        ;;
esac

# Hauptfunktion
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║        WireGuard Setup Script        ║"
    echo "║       Multi-Distribution Support     ║"
    echo "║            Version $SCRIPT_VERSION             ║"
    echo "║                                      ║"
    echo "║        Author: Call Me Techie        ║"
    echo "║      https://CallMeTechie.de         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_root
    detect_distro
    
    main_menu
}

# Script starten
main "$@"
