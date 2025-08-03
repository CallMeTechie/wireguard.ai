# WireGuard Setup Script - Vollständige Anleitung

**Author:** Call Me Techie  
**Website:** [https://CallMeTechie.de](https://CallMeTechie.de)  
**GitHub:** [https://github.com/CallMeTechie/wireguard.ai](https://github.com/CallMeTechie/wireguard.ai)  
**Version:** 1.3  
**License:** MIT License

---

## 📋 Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Installation und Systemanforderungen](#installation-und-systemanforderungen)
3. [Erste Schritte](#erste-schritte)
4. [Server-Einrichtung](#server-einrichtung)
5. [Client-Einrichtung](#client-einrichtung)
6. [Firewall-Management](#firewall-management)
7. [Client-Verwaltung](#client-verwaltung)
8. [Backup/Restore-System](#backuprestore-system)
9. [Update-Management](#update-management)
10. [Konfigurationstemplates](#konfigurationstemplates)
11. [Troubleshooting](#troubleshooting)
12. [Erweiterte Konfiguration](#erweiterte-konfiguration)
13. [Automatische Updates](#automatische-updates)
14. [Support und Community](#support-und-community)

---

## Übersicht

Das WireGuard Setup Script ist ein umfassendes Tool zur automatisierten Installation und Verwaltung von WireGuard VPN-Verbindungen. Es unterstützt mehrere Linux-Distributionen und bietet erweiterte Features wie automatische Firewall-Konfiguration, Backup/Restore-Funktionen und Template-basierte Setups.

**Entwickelt von:** [Call Me Techie](https://CallMeTechie.de) - Ihr Experte für Netzwerk- und Server-Technologien

### Unterstützte Distributionen
- **Debian/Ubuntu** (apt-basiert) - inklusive Debian 12 (Bookworm)
- **CentOS/RHEL/Rocky/Alma Linux** (yum/dnf-basiert)
- **Fedora** (dnf-basiert)
- **Arch Linux/Manjaro** (pacman-basiert)
- **openSUSE/SLES** (zypper-basiert)
- **Alpine Linux** (apk-basiert)

### Hauptfeatures
- ✅ Automatische Distributionserkennung
- ✅ Firewall-Integration (UFW, FirewallD, iptables)
- ✅ Backup/Restore-System mit Versionierung
- ✅ Erweiterte Client-Verwaltung
- ✅ **Automatisches Update-Management**
- ✅ Vorkonfigurierte Templates für verschiedene Szenarien
- ✅ QR-Code-Generierung für mobile Geräte
- ✅ Debian 12 Kompatibilität (UFW/iptables-persistent Fix)

---

## Installation und Systemanforderungen

### Systemanforderungen
- **Root-Rechte** erforderlich
- **Internetverbindung** für Paketinstallation und Updates
- **Mindestens 1 GB RAM**
- **Linux Kernel 3.10+** (für WireGuard-Support)

### Schnellinstallation

```bash
# Script herunterladen
wget https://raw.githubusercontent.com/CallMeTechie/wireguard.ai/main/wireguard_setup.sh

# Ausführbar machen
chmod +x wireguard_setup.sh

# Als root ausführen
sudo ./wireguard_setup.sh
```

### Alternative Download-Methoden

```bash
# Mit curl
curl -L https://raw.githubusercontent.com/CallMeTechie/wireguard.ai/main/wireguard_setup.sh -o wireguard_setup.sh

# Mit git (gesamtes Repository)
git clone https://github.com/CallMeTechie/wireguard.ai.git
cd wireguard.ai
chmod +x wireguard_setup.sh
```

### Erste Ausführung
Bei der ersten Ausführung wird automatisch:
1. Die Linux-Distribution erkannt
2. Der passende Package Manager ausgewählt
3. Die Systemkompatibilität geprüft
4. Verfügbare Updates geprüft

---

## Erste Schritte

### Script starten
```bash
sudo ./wireguard_setup.sh
```

### Kommandozeilenoptionen (Neu in v1.3)
```bash
./wireguard_setup.sh --version        # Versionsinformationen anzeigen
./wireguard_setup.sh --help          # Hilfe und Verwendungshinweise
./wireguard_setup.sh --check-updates # Auf Updates prüfen
./wireguard_setup.sh --auto-backup   # Automatisches Backup erstellen
```

### Hauptmenü-Navigation
```
=== WireGuard Setup Script v1.3 ===
Distribution: debian

        Author: Call Me Techie
      https://CallMeTechie.de

1) Server einrichten
2) Client einrichten
3) WireGuard verwalten
4) Abhängigkeiten installieren
5) Templates verwalten
6) System-Updates
7) Beenden
```

### Abhängigkeiten installieren (Option 4)
Führen Sie dies zuerst aus, um alle benötigten Pakete zu installieren:

**Installierte Pakete je Distribution:**
- **Debian/Ubuntu**: `wireguard`, `wireguard-tools`, `qrencode`, `netfilter-persistent`, `resolvconf`, `curl`
- **CentOS/RHEL/Fedora**: `wireguard-tools`, `qrencode`, `iptables-services`, `curl`, `firewalld`
- **Arch/Manjaro**: `wireguard-tools`, `qrencode`, `iptables`, `curl`, `ufw`
- **openSUSE**: `wireguard-tools`, `qrencode`, `iptables`, `curl`, `firewalld`
- **Alpine**: `wireguard-tools`, `qrencode`, `iptables`, `curl`

**Debian 12 Besonderheit:** Das Script erkennt automatisch Debian 12 (Bookworm) und umgeht den bekannten UFW/iptables-persistent Konflikt.

---

## Server-Einrichtung

### Schritt-für-Schritt Server-Setup

#### 1. Server einrichten (Hauptmenü Option 1)

Das Script führt automatisch folgende Schritte aus:
1. **Abhängigkeiten installieren**
2. **IP-Forwarding aktivieren**
3. **Template-Auswahl** (optional)
4. **Server-Konfiguration erstellen**

#### 2. Template-Auswahl

```
=== Konfigurationstemplates ===
1) Homelab (Einfache Home-VPN)
2) Unternehmen (Site-to-Site)
3) Road Warrior (Mobile Clients)
4) Gaming (Low Latency)
5) Privacy (Maximale Sicherheit)
6) Custom (Eigene Einstellungen)
```

**Template-Übersicht:**

| Template | VPN-Netzwerk | Port | DNS | Beschreibung |
|----------|--------------|------|-----|--------------|
| Homelab | 10.0.0.0/24 | 51820 | 10.0.0.1 | Einfache Heimnutzung |
| Enterprise | 172.16.0.0/16 | 51820 | 172.16.0.1 | Unternehmensumgebung |
| Road Warrior | 192.168.99.0/24 | 51820 | 1.1.1.1 | Mobile Clients |
| Gaming | 10.10.0.0/24 | 51820 | 8.8.8.8 | Niedrige Latenz |
| Privacy | 10.66.0.0/24 | 443 | 9.9.9.9 | Maximale Sicherheit |
| Custom | Benutzerdefiniert | Benutzerdefiniert | Benutzerdefiniert | Eigene Werte |

#### 3. Server-Konfiguration (Custom Template)

```bash
Server IP-Adresse im VPN (z.B. 10.0.0.1/24): 10.0.0.1/24
WireGuard Port (Standard: 51820): 51820
DNS Server (z.B. 8.8.8.8): 8.8.8.8
Externes Netzwerk-Interface (Standard: eth0): eth0
```

#### 4. Automatische Konfiguration

Das Script erstellt automatisch:

**Server-Konfiguration** (`/etc/wireguard/wg0.conf`):
```ini
[Interface]
PrivateKey = <generierter_private_key>
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true

# Firewall Regeln
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

**Erstellt automatisch:**
- 🔑 Server-Schlüsselpaar (`/etc/wireguard/keys/`)
- 🔥 Firewall-Regeln
- 📁 Verzeichnisstruktur
- 🔄 Systemd-Service
- 💾 Erstes Backup

#### 5. Firewall-Konfiguration

Das Script erkennt automatisch den Firewall-Typ:

**UFW (Ubuntu/Debian):**
```bash
ufw allow 51820/udp
ufw route allow in on wg0 out on eth0
```

**FirewallD (CentOS/RHEL/Fedora):**
```bash
firewall-cmd --permanent --add-port=51820/udp
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
```

**iptables (Fallback):**
```bash
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

#### 6. Server-Status überprüfen

Nach der Installation:
```bash
# Service-Status
systemctl status wg-quick@wg0

# WireGuard-Status
wg show

# Netzwerk-Interface
ip addr show wg0
```

---

## Client-Einrichtung

### Serverseitige Client-Konfiguration

#### 1. Client zum Server hinzufügen

**Automatisch nach Server-Setup:**
```
Möchten Sie jetzt einen Client hinzufügen? (j/n): j
```

**Oder über das Management-Menü:**
```
WireGuard Management → 2) Client hinzufügen
```

#### 2. Client-Informationen eingeben

```bash
Client Name: laptop-benutzer
Client IP im VPN (z.B. 10.0.0.2/32): 10.0.0.2/32
```

#### 3. Automatische Client-Konfiguration

Das Script:
1. **Generiert Client-Schlüsselpaar**
2. **Fügt Client zur Server-Konfiguration hinzu**
3. **Erstellt Client-Konfigurationsdatei**
4. **Erstellt automatisches Backup**
5. **Startet Server neu**

**Server-Konfiguration wird erweitert:**
```ini
[Peer]
# laptop-benutzer
PublicKey = <client_public_key>
AllowedIPs = 10.0.0.2/32
```

**Client-Konfiguration** (`/etc/wireguard/clients/laptop-benutzer.conf`):
```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.0.0.2/32
DNS = 10.0.0.1

[Peer]
PublicKey = <server_public_key>
Endpoint = <externe_server_ip>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

#### 4. QR-Code für mobile Geräte

```
QR-Code für mobile Geräte:
█▀▀▀▀▀█ ▀█▀ █▀▀▀▀▀█
█ ███ █ ▀▀▄ █ ███ █
█ ▀▀▀ █ █▄▀ █ ▀▀▀ █
▀▀▀▀▀▀▀ ▀ ▀ ▀▀▀▀▀▀▀
```

### Clientseitige Einrichtung

#### 1. Client einrichten (Hauptmenü Option 2)

Für eigenständige Clients ohne Serverzugriff:

```bash
Client Name: mein-laptop
Server Public Key: <server_public_key>
Server Endpoint (IP:Port): 203.0.113.1:51820
Client IP im VPN (z.B. 10.0.0.2/32): 10.0.0.2/32
Erlaubte IPs (Standard: 0.0.0.0/0): 0.0.0.0/0
DNS Server (Standard: 8.8.8.8): 8.8.8.8
```

#### 2. Client-Konfiguration aktivieren

```bash
WireGuard jetzt starten? (j/n): j
```

Das Script:
- Aktiviert den `wg-quick@wg0` Service
- Startet die VPN-Verbindung
- Erstellt automatisches Backup

#### 3. Client-Verbindung testen

```bash
# Verbindungsstatus prüfen
wg show

# Ping zum Server
ping 10.0.0.1

# Externe IP prüfen (sollte Server-IP sein)
curl ipinfo.io/ip
```

### Mobile Geräte (Android/iOS)

#### 1. WireGuard App installieren
- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
- **iOS**: [App Store](https://apps.apple.com/app/wireguard/id1441195209)

#### 2. Konfiguration hinzufügen
- **QR-Code scannen** (empfohlen)
- **Datei importieren**
- **Manuell eingeben**

#### 3. Verbindung aktivieren
- App öffnen
- Profil auswählen
- Toggle-Schalter aktivieren

---

## Firewall-Management

### Automatische Firewall-Erkennung

Das Script erkennt automatisch den verfügbaren Firewall-Typ:

```bash
# Erkennungslogik
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "ufw"
elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    echo "firewalld"
elif command -v iptables &> /dev/null; then
    echo "iptables"
else
    echo "none"
fi
```

### UFW (Ubuntu/Debian)

#### Automatische Konfiguration:
```bash
# Port freigeben
ufw allow 51820/udp

# Routing erlauben
ufw route allow in on wg0 out on eth0

# Status prüfen
ufw status verbose
```

#### Manuelle UFW-Verwaltung:
```bash
# WireGuard-Port schließen
ufw delete allow 51820/udp

# Spezifische IP erlauben
ufw allow from 10.0.0.0/24 to any port 51820

# Logging aktivieren
ufw logging on
```

### FirewallD (CentOS/RHEL/Fedora)

#### Automatische Konfiguration:
```bash
# Port permanent freigeben
firewall-cmd --permanent --add-port=51820/udp

# Masquerading aktivieren
firewall-cmd --permanent --add-masquerade

# Direkte Regeln hinzufügen
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i wg0 -o eth0 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i eth0 -o wg0 -j ACCEPT

# Konfiguration neu laden
firewall-cmd --reload
```

#### Manuelle FirewallD-Verwaltung:
```bash
# Aktuelle Konfiguration anzeigen
firewall-cmd --list-all

# Port entfernen
firewall-cmd --permanent --remove-port=51820/udp

# Zone erstellen für WireGuard
firewall-cmd --permanent --new-zone=wireguard
firewall-cmd --permanent --zone=wireguard --add-source=10.0.0.0/24
firewall-cmd --permanent --zone=wireguard --add-service=ssh

# Rich Rules für erweiterte Kontrolle
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" accept'
```

### iptables (Universell)

#### Manuelle iptables-Regeln:
```bash
# Grundregeln für WireGuard
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Regeln persistent speichern (Debian/Ubuntu)
iptables-save > /etc/iptables/rules.v4

# Regeln persistent speichern (CentOS/RHEL)
iptables-save > /etc/sysconfig/iptables
```

### Portfreigaben verwalten

#### Standard WireGuard-Port (51820)
```bash
# UFW
ufw allow 51820/udp

# FirewallD
firewall-cmd --permanent --add-port=51820/udp

# iptables
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
```

#### Alternativer Port (z.B. 443 für Privacy)
```bash
# UFW
ufw allow 443/udp

# FirewallD
firewall-cmd --permanent --add-port=443/udp

# iptables
iptables -A INPUT -p udp --dport 443 -j ACCEPT
```

#### Portbereich freigeben
```bash
# UFW (Bereich 51820-51830)
ufw allow 51820:51830/udp

# FirewallD
firewall-cmd --permanent --add-port=51820-51830/udp

# iptables
iptables -A INPUT -p udp --dport 51820:51830 -j ACCEPT
```

#### Source-basierte Beschränkungen
```bash
# Nur bestimmte IPs erlauben (UFW)
ufw allow from 203.0.113.0/24 to any port 51820

# Nur bestimmte IPs erlauben (FirewallD)
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="203.0.113.0/24" port protocol="udp" port="51820" accept'

# Nur bestimmte IPs erlauben (iptables)
iptables -A INPUT -s 203.0.113.0/24 -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -p udp --dport 51820 -j DROP
```

### Firewall-Troubleshooting

#### Verbindungsprobleme diagnostizieren:
```bash
# Aktive Verbindungen prüfen
ss -ulnp | grep 51820

# Firewall-Logs überprüfen (UFW)
tail -f /var/log/ufw.log

# Firewall-Logs überprüfen (FirewallD)
journalctl -f -u firewalld

# iptables-Regeln auflisten
iptables -L -n -v

# NAT-Regeln prüfen
iptables -t nat -L -n -v
```

#### Häufige Firewall-Fixes:
```bash
# Firewall temporär deaktivieren (Test)
ufw disable  # oder systemctl stop firewalld

# IP-Forwarding prüfen
sysctl net.ipv4.ip_forward

# Masquerading prüfen
iptables -t nat -L POSTROUTING -n -v

# Interface-Status prüfen
ip link show wg0
```

---

## Client-Verwaltung

### Erweiterte Client-Verwaltung (Option 3)

```
=== Erweiterte Client-Verwaltung ===
1) Alle Clients auflisten
2) Client hinzufügen
3) Client entfernen
4) Client bearbeiten
5) Client-Statistiken
6) Bulk-Client-Import (CSV)
7) Alle Client-Konfigurationen exportieren
8) Zurück
```

### Clients auflisten (Option 1)

**Beispielausgabe:**
```
Aktive WireGuard Clients:

Aktive Verbindungen:
interface: wg0
  public key: ABcd1234...
  private key: (hidden)
  listening port: 51820

peer: XYz9876...
  endpoint: 203.0.113.100:45231
  allowed ips: 10.0.0.2/32
  latest handshake: 2 minutes, 15 seconds ago
  transfer: 1.24 MiB received, 856.32 KiB sent
  persistent keepalive: every 25 seconds

Konfigurierte Clients:
1) laptop-benutzer
   Public Key: ABcd1234efgh5678...
   IP: 10.0.0.2/32

2) handy-android
   Public Key: XYz9876abcd1234...
   IP: 10.0.0.3/32
```

### Client entfernen (Option 3)

**Sicherheitsprozess:**
1. **Backup erstellen** vor Entfernung
2. **Client aus Server-Konfiguration entfernen**
3. **Client-Konfigurationsdatei löschen**
4. **Schlüssel löschen**
5. **Server-Service neu starten**

```bash
Client-Name zum Löschen: laptop-benutzer

[INFO] Erstelle Backup: before_remove_laptop-benutzer_20240803_143022
[INFO] Entferne Client: laptop-benutzer
[SUCCESS] Client 'laptop-benutzer' erfolgreich entfernt
```

### Client bearbeiten (Option 4)

**Bearbeitbare Eigenschaften:**

#### 1. AllowedIPs (Split-Tunneling)
```bash
Was möchten Sie ändern?
1) AllowedIPs (Split-Tunneling)

Auswahl: 1
Neue AllowedIPs (z.B. 10.0.0.0/24,192.168.1.0/24): 10.0.0.0/24,8.8.8.8/32
```

**Häufige Split-Tunneling-Konfigurationen:**
- `0.0.0.0/0` - Kompletter Traffic über VPN
- `10.0.0.0/24` - Nur lokales VPN-Netz
- `10.0.0.0/24,192.168.1.0/24` - Mehrere private Netze
- `8.8.8.8/32,1.1.1.1/32` - Nur DNS-Server

#### 2. DNS Server ändern
```bash
2) DNS Server

Auswahl: 2
Neuer DNS Server: 1.1.1.1
```

**Empfohlene DNS-Server:**
- `1.1.1.1` - Cloudflare (schnell)
- `8.8.8.8` - Google
- `9.9.9.9` - Quad9 (privatsphäreorientiert)
- `10.0.0.1` - VPN-Server (für interne Auflösung)

#### 3. Endpoint ändern
```bash
3) Endpoint

Auswahl: 3
Neuer Endpoint: 203.0.113.1:443
```

### Client-Statistiken (Option 5)

**Detaillierte Übersicht:**
```bash
interface: wg0
  public key: server_public_key
  private key: (hidden)
  listening port: 51820
  fwmark: 0xca6c

peer: client1_public_key
  preshared key: (hidden)
  endpoint: 203.0.113.100:45231
  allowed ips: 10.0.0.2/32
  latest handshake: 1 minute, 45 seconds ago
  transfer: 15.24 MiB received, 8.56 MiB sent
  persistent keepalive: every 25 seconds

peer: client2_public_key
  endpoint: 203.0.113.101:52341
  allowed ips: 10.0.0.3/32
  latest handshake: 5 minutes, 12 seconds ago
  transfer: 2.48 MiB received, 1.23 MiB sent
  persistent keepalive: every 25 seconds
```

### Bulk-Client-Import (Option 6)

**CSV-Format:**
```csv
name,ip,dns,allowed_ips
laptop-user,10.0.0.2/32,8.8.8.8,0.0.0.0/0
phone-android,10.0.0.3/32,1.1.1.1,10.0.0.0/24
tablet-ios,10.0.0.4/32,9.9.9.9,0.0.0.0/0
```

**Import-Prozess:**
1. CSV-Datei nach `/tmp/wireguard_clients.csv` kopieren
2. Script startet automatischen Import
3. Für jeden Client wird erstellt:
   - Schlüsselpaar
   - Server-Konfigurationseintrag
   - Client-Konfigurationsdatei
   - QR-Code

### Client-Export (Option 7)

**Export-Verzeichnis:** `/tmp/wireguard_export_YYYYMMDD_HHMMSS/`

**Exportierte Dateien:**
```
wireguard_export_20240803_143022/
├── laptop-benutzer.conf
├── handy-android.conf
├── tablet-ios.conf
└── export_info.txt
```

**Verwendung:**
```bash
# Alle Konfigurationen kopieren
cp /tmp/wireguard_export_*//*.conf /pfad/zum/backup/

# Einzelne Konfiguration an Client senden
scp laptop-benutzer.conf user@client:/etc/wireguard/wg0.conf
```

---

## Backup/Restore-System

### Automatische Backups

Das Script erstellt automatisch Backups bei:
- **Server-Einrichtung** (`initial_setup_YYYYMMDD_HHMMSS`)
- **Client hinzufügen** (`before_add_CLIENT_YYYYMMDD_HHMMSS`)
- **Client entfernen** (`before_remove_CLIENT_YYYYMMDD_HHMMSS`)
- **Konfigurationsänderungen**

### Backup-Verwaltung

```
=== Backup Management ===
1) Backup erstellen
2) Backup wiederherstellen
3) Backups auflisten
4) Backup löschen
5) Automatisches Backup konfigurieren
6) Zurück
```

### Manuelles Backup erstellen (Option 1)

```bash
Backup-Name (leer für automatisch): mein_backup

[INFO] Erstelle Backup: mein_backup
[SUCCESS] Backup erstellt: /etc/wireguard/backups/mein_backup
```

**Backup-Inhalt:**
```
/etc/wireguard/backups/mein_backup/
├── wg0.conf                    # Server-Konfiguration
├── keys/                       # Alle Schlüssel
│   ├── server_private.key
│   ├── server_public.key
│   ├── client1_private.key
│   ├── client1_public.key
│   └── ...
├── clients/                    # Client-Konfigurationen
│   ├── laptop-benutzer.conf
│   ├── handy-android.conf
│   └── ...
└── backup_info.txt            # Metadaten
```

### Backup wiederherstellen (Option 2)

```bash
Verfügbare Backups:
1) initial_setup_20240803_120000
   Backup erstellt: So 03 Aug 2024 12:00:00 CEST
2) before_add_laptop_20240803_130000
   Backup erstellt: So 03 Aug 2024 13:00:00 CEST
3) mein_backup
   Backup erstellt: So 03 Aug 2024 14:30:22 CEST

Backup auswählen (Nummer): 3

ACHTUNG: Aktuelle Konfiguration wird überschrieben!
Fortfahren? (j/n): j

[INFO] Erstelle Backup: before_restore_20240803_143022
[SUCCESS] Backup wiederhergestellt: mein_backup

WireGuard jetzt starten? (j/n): j
```

**Wiederherstellungsprozess:**
1. **Sicherheitsbackup** der aktuellen Konfiguration
2. **Service stoppen**
3. **Dateien wiederherstellen**
4. **Berechtigungen setzen**
5. **Optional: Service starten**

### Automatisches Backup konfigurieren (Option 5)

**Cron-Job-Erstellung:**
```bash
# Wöchentliches Backup (Sonntag 2:00 Uhr)
echo "0 2 * * 0 root /pfad/zum/script/wireguard_setup.sh --auto-backup" > /etc/cron.d/wireguard-backup
```

**Automatisches Backup ausführen:**
```bash
# Manueller Test
./wireguard_setup.sh --auto-backup
```

### Backup-Aufbewahrung

**Automatische Bereinigung** (manuell hinzufügbar):
```bash
# Backups älter als 30 Tage löschen
find /etc/wireguard/backups/ -type d -mtime +30 -exec rm -rf {} \;

# Nur die neuesten 10 Backups behalten
ls -1t /etc/wireguard/backups/ | tail -n +11 | xargs -r rm -rf
```

---

## Update-Management

### Automatisches Update-System (Neu in v1.3)

Das Script verfügt über ein vollständiges automatisches Update-System, das direkt mit dem GitHub-Repository verbunden ist.

### Update-Verwaltung

```
=== Update Management ===
1) WireGuard Updates prüfen
2) Script Updates prüfen  ← Neu: Automatische GitHub-Integration
3) System komplett aktualisieren
4) Automatische Updates konfigurieren
5) Automatische Script-Updates aktivieren  ← Neu
6) Zurück
```

### Script-Updates prüfen (Option 2)

**Automatische GitHub-Integration:**
```bash
[INFO] Prüfe Script-Updates...
Aktuelle Version: 1.3
Neueste Version:  1.4

Update verfügbar!

Möchten Sie das Update jetzt installieren? (j/n): j

[INFO] Lade Script-Update herunter...
[INFO] Backup erstellt: script_backup_v1.3_20240803_143022
[SUCCESS] Script erfolgreich auf Version 1.4 aktualisiert!

Changelog verfügbar unter:
https://github.com/CallMeTechie/wireguard.ai/releases/tag/v1.4

Script neu starten mit neuer Version? (j/n): j
```

**Update-Funktionen:**
- **Automatische Versionserkennung** über GitHub API
- **Sicherer Download** mit Validierung
- **Automatisches Backup** des aktuellen Scripts
- **Syntaxprüfung** vor Installation
- **Rollback-Möglichkeit** bei Problemen

### Automatische Script-Updates aktivieren (Option 5)

**Cron-Job für wöchentliche Prüfung:**
```bash
[INFO] Konfiguriere automatische Update-Prüfung...
[SUCCESS] Automatische Update-Prüfung konfiguriert (Sonntags 3:00 Uhr)
Logs: /var/log/wireguard-updates.log
```

**Cron-Job Details:**
```bash
# Wird automatisch erstellt: /etc/cron.d/wireguard-updates
0 3 * * 0 root /pfad/zum/script/wireguard_setup.sh --check-updates > /var/log/wireguard-updates.log 2>&1
```

### WireGuard Updates prüfen (Option 1)

**Distributionsabhängige Prüfung:**

#### Debian/Ubuntu:
```bash
apt list --upgradable 2>/dev/null | grep wireguard

# Beispielausgabe:
wireguard/bookworm-updates 1.0.20210219-2ubuntu0.20.04.1 all [upgradable from: 1.0.20210124-1ubuntu1]
```

#### CentOS/RHEL/Fedora:
```bash
dnf check-update wireguard-tools

# Oder für ältere Systeme:
yum check-update wireguard-tools
```

#### Arch/Manjaro:
```bash
pacman -Qu wireguard-tools
```

### System Updates (Option 3)

**Vollständige Systemaktualisierung:**

```bash
[INFO] Aktualisiere System...

# Debian/Ubuntu
apt update && apt upgrade -y

# CentOS/RHEL/Fedora
dnf update -y

# Arch/Manjaro
pacman -Syu --noconfirm

[SUCCESS] System aktualisiert
```

### Kommandozeilen-Updates

**Neue Kommandozeilenoptionen:**
```bash
# Nur auf Updates prüfen (ohne Installation)
./wireguard_setup.sh --check-updates

# Versionsinformationen anzeigen
./wireguard_setup.sh --version
# Ausgabe:
# WireGuard Setup Script v1.3
# Author: Call Me Techie
# Website: https://CallMeTechie.de
# GitHub: https://github.com/CallMeTechie/wireguard.ai

# Hilfe anzeigen
./wireguard_setup.sh --help
```

### Update-Sicherheit

**Vor großen Updates:**
1. **Automatisches Backup erstellen**
2. **Konfiguration testen**
3. **Rollback-Plan bereithalten**

**Nach Updates prüfen:**
```bash
# WireGuard-Status
systemctl status wg-quick@wg0
wg show

# Netzwerk-Konnektivität
ping 10.0.0.1

# Client-Verbindungen
wg show all
```

### Update-Logs überwachen

**Log-Dateien:**
```bash
# Automatische Update-Logs
tail -f /var/log/wireguard-updates.log

# System-Update-Logs
journalctl -u apt-daily-upgrade.service  # Debian/Ubuntu
journalctl -u dnf-automatic.service      # Fedora
```

### Rollback bei Problemen

**Script-Rollback:**
```bash
# Backup-Scripts werden automatisch erstellt als:
# script_backup_v[VERSION]_[TIMESTAMP]

# Manueller Rollback:
cp script_backup_v1.3_20240803_143022 wireguard_setup.sh
chmod +x wireguard_setup.sh
```

**Konfiguration-Rollback:**
```bash
# WireGuard verwalten → Backup/Restore → Backup wiederherstellen
# Automatische Backups verfügbar vor jeder größeren Änderung
```

---

## Konfigurationstemplates

### Template-Übersicht

| Template | Anwendungsfall | Netzwerk | Port | DNS | Besonderheiten |
|----------|----------------|----------|------|-----|----------------|
| **Homelab** | Heimnetzwerk | 10.0.0.0/24 | 51820 | 10.0.0.1 | Einfach, lokal |
| **Enterprise** | Unternehmen | 172.16.0.0/16 | 51820 | 172.16.0.1 | Große Netze |
| **Road Warrior** | Mobile Clients | 192.168.99.0/24 | 51820 | 1.1.1.1 | Extern optimiert |
| **Gaming** | Gaming/Latenz | 10.10.0.0/24 | 51820 | 8.8.8.8 | Niedrige Latenz |
| **Privacy** | Anonymität | 10.66.0.0/24 | 443 | 9.9.9.9 | Getarnt als HTTPS |
| **Custom** | Benutzerdefiniert | Variable | Variable | Variable | Individuelle Werte |

### Homelab Template

**Ideal für:**
- Heimnetzwerke
- Kleine Büros
- Persönliche VPNs
- Einfache Setups

**Konfiguration:**
```ini
# Server
Address = 10.0.0.1/24
ListenPort = 51820
DNS = 10.0.0.1

# Clients erhalten IPs: 10.0.0.2, 10.0.0.3, etc.
```

**Verwendung:**
```bash
# Template auswählen
Templates verwalten → 1) Homelab

# Bestätigung
Diese Einstellungen verwenden? (j/n): j
```

### Enterprise Template

**Ideal für:**
- Unternehmensumgebungen
- Site-to-Site VPNs
- Große Netzwerke
- Mehrere Standorte

**Konfiguration:**
```ini
# Server
Address = 172.16.0.1/16
ListenPort = 51820
DNS = 172.16.0.1

# Unterstützt bis zu 65.534 Clients
# Clients: 172.16.0.2 - 172.16.255.254
```

**Erweiterte Konfiguration:**
```bash
# Subnet-Routing für verschiedene Abteilungen
AllowedIPs = 172.16.1.0/24  # IT-Abteilung
AllowedIPs = 172.16.2.0/24  # Buchhaltung
AllowedIPs = 172.16.3.0/24  # Vertrieb
```

### Road Warrior Template

**Ideal für:**
- Mobile Mitarbeiter
- Laptops/Smartphones
- Externe Verbindungen
- Reisende

**Konfiguration:**
```ini
# Server
Address = 192.168.99.1/24
ListenPort = 51820
DNS = 1.1.1.1  # Cloudflare für schnelle externe Auflösung

# Optimiert für externe Verbindungen
PersistentKeepalive = 25
```

**Client-Optimierungen:**
```ini
# Aggressive Keepalive für mobile Verbindungen
PersistentKeepalive = 25

# Split-Tunneling für lokale Zugriffe
AllowedIPs = 192.168.99.0/24, 10.0.0.0/8
```

### Gaming Template

**Ideal für:**
- Gaming-VPNs
- Niedrige Latenz
- Streaming
- Echtzeit-Anwendungen

**Konfiguration:**
```ini
# Server
Address = 10.10.0.1/24
ListenPort = 51820
DNS = 8.8.8.8  # Google DNS für Geschwindigkeit

# Latenz-Optimierungen
MTU = 1420
```

**Latenz-Optimierungen:**
```bash
# Kernel-Parameter für Gaming
echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf

# Anwenden
sysctl -p
```

### Privacy Template

**Ideal für:**
- Maximale Anonymität
- Umgehung von Zensur
- Getarnte Verbindungen
- Privatsphäre-fokussiert

**Konfiguration:**
```ini
# Server
Address = 10.66.0.1/24
ListenPort = 443  # Getarnt als HTTPS-Traffic
DNS = 9.9.9.9     # Quad9 - privatsphäreorientiert

# Zusätzliche Sicherheitsfeatures
PreSharedKey = <generiert>
```

**Erweiterte Privacy-Features:**
```bash
# Obfuscation durch Port 443
ListenPort = 443

# DNS-over-HTTPS
DNS = 9.9.9.9, 149.112.112.112

# Traffic-Verschleierung
# (Zusätzliche Tools wie obfs4 können integriert werden)
```

### Custom Template

**Vollständig anpassbar:**
```bash
Server IP-Adresse im VPN (z.B. 10.0.0.1/24): 172.20.0.1/16
WireGuard Port (Standard: 51820): 8080
DNS Server (z.B. 8.8.8.8): 1.1.1.1
```

**Erweiterte Custom-Optionen:**
```bash
# MTU-Größe
MTU = 1420

# Keepalive-Intervall
PersistentKeepalive = 25

# Pre-Shared Key aktivieren
PreSharedKey = yes

# IPv6 Support
Address = 172.20.0.1/16, fd42:42:42::1/64
```

### Template-Wechsel

**Bestehendes Setup auf anderes Template migrieren:**

1. **Backup erstellen**
```bash
WireGuard verwalten → Backup/Restore → Backup erstellen
```

2. **Neues Template konfigurieren**
```bash
Templates verwalten → [Template auswählen]
```

3. **Clients migrieren**
```bash
# Alte Client-Konfigurationen sichern
cp /etc/wireguard/clients/* /tmp/old_clients/

# Neue Client-Konfigurationen mit angepassten IPs erstellen
# Clients müssen neue Konfiguration erhalten
```

4. **Testing und Rollback**
```bash
# Bei Problemen: Backup wiederherstellen
WireGuard verwalten → Backup/Restore → Backup wiederherstellen
```

---

## Troubleshooting

### Häufige Probleme und Lösungen

#### 1. Verbindungsprobleme

**Problem:** Client kann sich nicht verbinden
```bash
# Diagnose
wg show              # WireGuard-Status prüfen
systemctl status wg-quick@wg0  # Service-Status
journalctl -u wg-quick@wg0     # Service-Logs

# Netzwerk-Tests
ping <server_ip>     # Server erreichbar?
nc -u <server_ip> <port>  # Port offen?
```

**Lösungen:**
```bash
# 1. Service neu starten
systemctl restart wg-quick@wg0

# 2. Firewall prüfen
ufw status
firewall-cmd --list-all
iptables -L -n

# 3. Port-Freigabe
ufw allow 51820/udp
firewall-cmd --add-port=51820/udp --permanent
```

#### 2. DNS-Probleme

**Problem:** Websites nicht erreichbar, DNS-Auflösung fehlgeschlagen
```bash
# DNS-Test
nslookup google.com
dig google.com

# WireGuard DNS prüfen
cat /etc/wireguard/wg0.conf | grep DNS
```

**Lösungen:**
```bash
# 1. DNS in Client-Konfiguration ändern
DNS = 8.8.8.8, 1.1.1.1

# 2. resolvconf installieren (Debian/Ubuntu)
apt install resolvconf

# 3. DNS manuell setzen
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### 3. IP-Forwarding nicht aktiv

**Problem:** Clients können nicht ins Internet
```bash
# IP-Forwarding prüfen
cat /proc/sys/net/ipv4/ip_forward  # Sollte "1" sein
```

**Lösung:**
```bash
# Temporär aktivieren
echo 1 > /proc/sys/net/ipv4/ip_forward

# Permanent aktivieren
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
```

#### 4. MTU-Probleme

**Problem:** Webseiten laden nicht vollständig, Downloads abgebrochen
```bash
# MTU-Test
ping -M do -s 1472 google.com  # Sollte funktionieren
ping -M do -s 1500 google.com  # Könnte fehlschlagen
```

**Lösung:**
```bash
# MTU in WireGuard-Konfiguration setzen
[Interface]
MTU = 1420

# Oder dynamisch ermitteln
ip route get 8.8.8.8 | grep mtu
```

#### 5. Performance-Probleme

**Problem:** Langsame VPN-Verbindung
```bash
# Bandbreiten-Test
iperf3 -c <server_ip>

# WireGuard-Statistiken
wg show all dump
```

**Optimierungen:**
```bash
# 1. Kernel-Parameter optimieren
echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf

# 2. MTU optimieren
MTU = 1420

# 3. Keepalive reduzieren
PersistentKeepalive = 0  # Nur wenn nötig
```

### Debug-Modus aktivieren

**Erweiterte Logging:**
```bash
# WireGuard Debug-Logs
echo 'module wireguard +p' > /sys/kernel/debug/dynamic_debug/control

# Syslog überwachen
tail -f /var/log/syslog | grep wireguard

# Kernel-Messages
dmesg | grep wireguard
```

### Konfiguration validieren

**Syntax-Check:**
```bash
# Konfigurationssyntax prüfen
wg-quick parse /etc/wireguard/wg0.conf

# Schlüssel validieren
wg pubkey < /etc/wireguard/keys/server_private.key
```

**Netzwerk-Validierung:**
```bash
# IP-Konflikte prüfen
ip addr show | grep -E "(10\.|172\.|192\.)"

# Routing-Tabelle prüfen
ip route show table all | grep wg0
```

### Recovery-Verfahren

**Bei kompletten Ausfall:**
```bash
# 1. Backup wiederherstellen
./wireguard_setup.sh
# → WireGuard verwalten → Backup/Restore → Backup wiederherstellen

# 2. Dienst zurücksetzen
systemctl stop wg-quick@wg0
rm /etc/wireguard/wg0.conf
systemctl daemon-reload

# 3. Neuinstallation
./wireguard_setup.sh
# → Abhängigkeiten installieren
# → Server/Client neu einrichten
```

**Notfall-Zugriff ohne VPN:**
```bash
# SSH-Zugriff sicherstellen
ufw allow ssh
firewall-cmd --add-service=ssh --permanent

# Alternative Fernwartung
# TeamViewer, anydesk, oder andere Tools installieren
```

---

## Erweiterte Konfiguration

### Multi-Server Setup

**Mehrere WireGuard-Instanzen:**
```bash
# Zusätzliche Konfigurationen
/etc/wireguard/wg1.conf  # Port 51821
/etc/wireguard/wg2.conf  # Port 51822

# Services starten
systemctl enable wg-quick@wg1
systemctl enable wg-quick@wg2
systemctl start wg-quick@wg1
systemctl start wg-quick@wg2
```

**Load Balancing:**
```bash
# Clients auf verschiedene Server verteilen
# Server 1: wg0 (10.0.0.0/24)
# Server 2: wg1 (10.0.1.0/24)
# Server 3: wg2 (10.0.2.0/24)
```

### Site-to-Site VPN

**Standort A (Hauptsitz):**
```ini
[Interface]
PrivateKey = <standort_a_private>
Address = 172.16.1.1/24
ListenPort = 51820

[Peer]
# Standort B
PublicKey = <standort_b_public>
Endpoint = standort-b.example.com:51820
AllowedIPs = 172.16.2.0/24
PersistentKeepalive = 25
```

**Standort B (Filiale):**
```ini
[Interface]
PrivateKey = <standort_b_private>
Address = 172.16.2.1/24
ListenPort = 51820

[Peer]
# Standort A
PublicKey = <standort_a_public>
Endpoint = hauptsitz.example.com:51820
AllowedIPs = 172.16.1.0/24
PersistentKeepalive = 25
```

### IPv6-Support

**Dual-Stack Konfiguration:**
```ini
[Interface]
PrivateKey = <private_key>
Address = 10.0.0.1/24, fd42:42:42::1/64
ListenPort = 51820

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 10.0.0.2/32, fd42:42:42::2/128
```

**IPv6-Routing:**
```bash
# IPv6-Forwarding aktivieren
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf

# IPv6-Firewall-Regeln
ip6tables -A FORWARD -i wg0 -j ACCEPT
ip6tables -A FORWARD -o wg0 -j ACCEPT
```

### Pre-Shared Keys (PSK)

**PSK generieren und verwenden:**
```bash
# PSK generieren
wg genpsk > /etc/wireguard/keys/client1.psk

# Server-Konfiguration
[Peer]
PublicKey = <client_public_key>
PreSharedKey = <psk_content>
AllowedIPs = 10.0.0.2/32

# Client-Konfiguration
[Peer]
PublicKey = <server_public_key>
PreSharedKey = <psk_content>
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0
```

### Traffic-Shaping

**Bandbreitenlimitierung mit tc:**
```bash
# Download-Limit für Client (10 Mbit/s)
tc qdisc add dev wg0 root handle 1: htb default 30
tc class add dev wg0 parent 1: classid 1:1 htb rate 10mbit
tc filter add dev wg0 protocol ip parent 1:0 prio 1 u32 match ip dst 10.0.0.2/32 flowid 1:1

# Upload-Limit
tc qdisc add dev eth0 root handle 1: htb default 30
tc class add dev eth0 parent 1: classid 1:1 htb rate 5mbit
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip src 10.0.0.2/32 flowid 1:1
```

### Monitoring und Alerting

**Prometheus-Exporter:**
```bash
# WireGuard-Prometheus-Exporter installieren
wget https://github.com/MindFlavor/prometheus_wireguard_exporter/releases/download/3.6.6/prometheus_wireguard_exporter_3.6.6_linux_amd64.tar.gz
tar xzf prometheus_wireguard_exporter_3.6.6_linux_amd64.tar.gz
mv prometheus_wireguard_exporter /usr/local/bin/

# Systemd-Service
cat > /etc/systemd/system/wireguard-exporter.service << 'EOF'
[Unit]
Description=WireGuard Prometheus Exporter
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/prometheus_wireguard_exporter -n /etc/wireguard/wg0.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now wireguard-exporter
```

**Grafana Dashboard:**
- Import Dashboard ID: 21522
- Überwacht: Verbindungen, Traffic, Handshakes, Uptime

### Security Hardening

**Zusätzliche Sicherheitsmaßnahmen:**
```bash
# 1. Fail2Ban für WireGuard
cat > /etc/fail2ban/jail.d/wireguard.conf << 'EOF'
[wireguard]
enabled = true
port = 51820
protocol = udp
filter = wireguard
logpath = /var/log/syslog
maxretry = 3
bantime = 86400
EOF

# 2. Port Knocking
# Verstecke WireGuard-Port hinter Port-Klopf-Sequenz

# 3. Geo-IP Blocking
# Erlaube nur Verbindungen aus bestimmten Ländern

# 4. Rate Limiting
iptables -A INPUT -p udp --dport 51820 -m limit --limit 10/min -j ACCEPT
iptables -A INPUT -p udp --dport 51820 -j DROP
```

### Hochverfügbarkeit

**Keepalived für Server-Redundanz:**
```bash
# Installation
apt install keepalived

# Konfiguration (/etc/keepalived/keepalived.conf)
vrrp_script chk_wireguard {
    script "/bin/systemctl is-active wg-quick@wg0"
    interval 2
    weight 2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass WireGuardHA
    }
    virtual_ipaddress {
        203.0.113.100
    }
    track_script {
        chk_wireguard
    }
}
```

---

## Automatische Updates

### GitHub-Integration (Neu in v1.3)

Das WireGuard Setup Script verfügt über eine vollständige GitHub-Integration für automatische Updates:

**Repository:** [https://github.com/CallMeTechie/wireguard.ai](https://github.com/CallMeTechie/wireguard.ai)

### Update-Mechanismus

**Automatische Erkennung:**
- Prüft GitHub Releases über API
- Vergleicht lokale mit aktueller Version
- Lädt Updates sicher herunter
- Validiert Integrität vor Installation

**Update-Quellen:**
1. **GitHub Releases** (primär) - offizielle Versionen
2. **Main Branch** (fallback) - neueste Entwicklungsversion

### Sicherheitsfeatures

**Vor jedem Update:**
- Automatisches Backup des aktuellen Scripts
- Syntaxprüfung der neuen Version
- Integritätsprüfung der Download-Datei

**Rollback-Schutz:**
```bash
# Automatische Backups bei Updates:
script_backup_v1.3_20240803_143022
script_backup_v1.2_20240802_120000
script_backup_v1.1_20240801_100000
```

### Update-Benachrichtigungen

**Automatische Checks:**
- Wöchentliche Prüfung via Cron-Job
- Log-Dateien in `/var/log/wireguard-updates.log`
- E-Mail-Benachrichtigungen (optional konfigurierbar)

**Manuelle Checks:**
```bash
# Schnelle Versionsprüfung
./wireguard_setup.sh --version

# Vollständige Update-Prüfung
./wireguard_setup.sh --check-updates
```

---

## Support und Community

### Offizielle Kanäle

**Website:** [https://CallMeTechie.de](https://CallMeTechie.de)  
- Tutorials und Anleitungen
- Blog-Posts zu Netzwerk-Technologien
- Weiterführende Dokumentation

**GitHub Repository:** [https://github.com/CallMeTechie/wireguard.ai](https://github.com/CallMeTechie/wireguard.ai)  
- Source Code
- Issue Tracking
- Feature Requests
- Community Discussions

### Bug Reports und Feature Requests

**Bug Report erstellen:**
1. [GitHub Issues](https://github.com/CallMeTechie/wireguard.ai/issues) öffnen
2. Template "Bug Report" auswählen
3. Systeminformationen angeben:
   ```bash
   # Diese Informationen helfen bei der Diagnose:
   ./wireguard_setup.sh --version
   cat /etc/os-release
   uname -a
   ```

**Feature Request:**
1. [GitHub Issues](https://github.com/CallMeTechie/wireguard.ai/issues) öffnen
2. Template "Feature Request" auswählen
3. Detaillierte Beschreibung der gewünschten Funktion

### Community Guidelines

**Bevor Sie Fragen stellen:**
1. **Dokumentation lesen** - Diese umfassende Anleitung durchgehen
2. **Troubleshooting-Sektion prüfen** - Häufige Probleme und Lösungen
3. **GitHub Issues durchsuchen** - Möglicherweise wurde das Problem bereits gelöst

**Bei Problemen:**
1. **Logs sammeln:**
   ```bash
   # WireGuard Logs
   journalctl -u wg-quick@wg0 --no-pager
   
   # System Logs
   tail -n 50 /var/log/syslog
   
   # Script-spezifische Logs
   cat /var/log/wireguard-updates.log
   ```

2. **Systeminfos bereitstellen:**
   ```bash
   # Distribution und Version
   cat /etc/os-release
   
   # WireGuard Version
   wg --version
   
   # Script Version
   ./wireguard_setup.sh --version
   ```

### Beitragen zum Projekt

**Pull Requests willkommen für:**
- Bug Fixes
- Neue Features
- Dokumentationsverbesserungen
- Übersetzungen
- Neue Distributionsunterstützung

**Entwicklungsumgebung:**
```bash
# Repository forken und klonen
git clone https://github.com/IhrBenutzername/wireguard.ai.git
cd wireguard.ai

# Feature Branch erstellen
git checkout -b feature/neue-funktion

# Änderungen testen
bash -n wireguard_setup.sh  # Syntax-Check
shellcheck wireguard_setup.sh  # Code-Qualität

# Pull Request erstellen auf GitHub
```

### Lizenz und Copyright

**Copyright © 2025 Call Me Techie**  
Freie Nutzung, Modifikation und Weitergabe unter MIT-Lizenz

### Haftungsausschluss

Das Script wird "wie gesehen" bereitgestellt. Obwohl es sorgfältig entwickelt und getestet wurde, übernimmt der Autor keine Haftung für Schäden oder Probleme, die durch die Verwendung entstehen könnten.

**Empfehlungen:**
- Immer in Testumgebung erst testen
- Backups vor Produktiveinsatz erstellen
- Bei kritischen Systemen professionelle Beratung einholen


**Projektgeschichte:**
- **v1.0** - Grundfunktionalität und Multi-Distribution-Support
- **v1.1** - Template-System und erweiterte Client-Verwaltung
- **v1.2** - Backup/Restore-System und Firewall-Integration
- **v1.3** - Automatische Updates und Debian 12 Kompatibilität

---

**Entwickelt mit ❤️ von [Call Me Techie](https://CallMeTechie.de)**
