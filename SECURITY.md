# SECURITY.md - Sicherheitsrichtlinien für novachris_home

## Schlüssel- und Secrets-Policy

Alle privaten Schlüssel und sensible Daten müssen streng geschützt werden:

- **Private SSH-Schlüssel** und andere sensible Dateien werden ausschließlich lokal im Verzeichnis `~/.wizzad/keys/` gespeichert
- Die Datei `.wizzad.local.yml` enthält lokale Pfade zu Schlüsseln und darf **niemals** ins Repository committed werden
- Dateien wie `*.pem`, `*.key`, `*.p12`, `*.kdbx` sowie `secrets*.yml` werden durch `.gitignore` ausgeschlossen
- Der SSH-Private-Key wird nur lokal verwendet und nie auf den Ziel-Hosts gespeichert

## Ansible Vault

Für sensible Variablen ist `ansible-vault` zu verwenden:

- Verschlüsseln Sie sensitive Variablen mit: `ansible-vault encrypt inventory/group_vars/proxmox_servers.yml`
- Unverschlüsselte Platzhaltervariablen in `group_vars` sollten ausschließlich auf verschlüsselte `vault_*` Variablen verweisen
- Das Vault-Passwort wird in einer lokalen Datei (z.B. `.vault_pass`) oder via Umgebungsvariable übergeben
- Diese Datei darf **niemals** ins Versionskontrollsystem

Beispiel für Vault-Verwendung:

```yaml
# Unverschlüsselt (in group_vars)
proxmox_api_token_secret: "{{ vault_proxmox_api_token_secret }}"

# Verschlüsselt (in vault file)
vault_proxmox_api_token_secret: "your-secret-token-here"
```

## SSH-Sicherheit

### Authentifizierung

- **Nur Key-basierte Authentifizierung** verwenden, keine Passwörter
- SSH-Schlüssel sollten vom Typ **ed25519** sein (modern und sicher)
- Passwort-Authentifizierung auf allen Ziel-Hosts deaktivieren: `PasswordAuthentication no`
- Root-Login per SSH verbieten: `PermitRootLogin no`

### SSH-Konfiguration

Empfohlene SSH-Server-Konfiguration (`/etc/ssh/sshd_config`):

```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
X11Forwarding no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
```

## Sudo-Sicherheit

- Nur benötigte Benutzer/Gruppen mit sudo-Rechten versehen
- **Passwortloses Sudo** nur für automatisierte Prozesse (Ansible) verwenden
- Für interaktive Benutzer Passwort-Bestätigung erzwingen
- Sudo-Logs regelmäßig überprüfen: `sudo journalctl -u sudo`

## Firewall-Konfiguration

Nur erforderliche Ports öffnen und eine Standard-Deny-Regel setzen:

```bash
# UFW Beispiel
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 8006/tcp  # Proxmox GUI
ufw enable
```

## Systemupdates

- Regelmäßige Aktualisierung von Betriebssystem und installierter Software sicherstellen
- Sicherheits-Updates sollten zeitnah eingespielt werden
- Automatische Updates für kritische Patches erwägen

```bash
# Automatische Updates aktivieren
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

## Logging und Monitoring

- Protokolle (logs/) außerhalb des Repositories speichern
- Logs auf sicherem System rotieren und archivieren
- Zentrale Log-Aggregation erwägen (ELK, Splunk, etc.)
- Regelmäßige Überprüfung von Sicherheitslogs

Wichtige Log-Dateien:

- `/var/log/auth.log` - Authentifizierung
- `/var/log/syslog` - Systemlogs
- `/var/log/novachris_home/` - Applikationslogs

## Proxmox-spezifische Sicherheit

### API-Token

- **Niemals** den Root-User mit Passwort verwenden
- Erstellen Sie einen dedizierten Benutzer: `ansible@pam`
- Generieren Sie einen API-Token mit minimalen Rechten
- Token-ID Format: `user@pam!tokenid`
- Speichern Sie Token-Secret **verschlüsselt** (Vault)

### Rollen und Berechtigungen

- Verwenden Sie die Rolle **PVEVMAdmin** für VM-Verwaltung
- Beschränken Sie Rechte auf notwendige Ressourcen
- Verwenden Sie **Realm** für Benutzer-Isolation

## Backup-Sicherheit

- Backups sollten **verschlüsselt** sein
- Backups sollten auf **separaten Systemen** gespeichert werden
- Regelmäßige **Restore-Tests** durchführen
- Backup-Zugangsrechte beschränken

## Checkliste für Produktionsdeployment

- [ ] SSH-Schlüssel generiert und sicher gespeichert
- [ ] `.wizzad.local.yml` in `.gitignore` eingetragen
- [ ] Vault-Passwort konfiguriert und sicher gespeichert
- [ ] Sensitive Variablen mit Vault verschlüsselt
- [ ] SSH-Konfiguration auf Ziel-Hosts gehärtet
- [ ] Firewall konfiguriert und getestet
- [ ] Sudo-Konfiguration überprüft
- [ ] Logging aktiviert und konfiguriert
- [ ] Backups konfiguriert und getestet
- [ ] Monitoring eingerichtet

## Incident Response

Im Falle eines Sicherheitsvorfalls:

1. **Sofort** den betroffenen SSH-Key deaktivieren
2. Einen neuen Key generieren: `bash setup_prod_env.sh`
3. Den neuen Public-Key auf allen Ziel-Hosts verteilen
4. Logs überprüfen und archivieren
5. Sicherheitsaudit durchführen
6. Betroffene Systeme neu deployen

## Weitere Ressourcen

- [OWASP Security Guidelines](https://owasp.org/)
- [CIS Benchmarks](https://www.cisecurity.org/)
- [Proxmox Security Documentation](https://pve.proxmox.com/wiki/Security)
- [Ansible Security Best Practices](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
