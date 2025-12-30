# user_management Role

Diese Rolle verwaltet Benutzerkonten und SSH-Schlüssel auf den Ziel-Hosts.

## Aufgaben

- SSH-Schlüssel validieren
- Admin-Benutzer erstellen
- SSH-Verzeichnis einrichten
- Authorized Keys konfigurieren
- Sudo-Rechte gewähren
- SSH-Sicherheit härten (Passwort-Auth deaktivieren, Root-Login verbieten)

## Variablen

| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `default_user` | admin_novachris | Name des Admin-Benutzers |
| `ssh_key_path` | (erforderlich) | Pfad zum öffentlichen SSH-Schlüssel |
| `ssh_key_type` | ed25519 | SSH-Schlüsseltyp |
| `ssh_port` | 22 | SSH-Port |
| `enable_passwordless_sudo` | true | Passwortloses Sudo aktivieren |

## Abhängigkeiten

Diese Rolle benötigt:
- `setup_prod_env.sh` wurde ausgeführt, um SSH-Schlüssel zu generieren
- SSH-Zugriff mit Root-Rechten auf den Ziel-Host

## Tags

- `user_management`: Alle Tasks dieser Rolle
- `users`: Benutzerverwaltung
- `ssh`: SSH-Konfiguration
- `sudo`: Sudo-Konfiguration
- `hardening`: Sicherheits-Härtung
