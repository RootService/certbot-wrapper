# certbot-wrapper

Auf Grund der aktuellen Probleme bei den CAs StartSSL und WoSign musste auch ich für meine Projekte nach Alternativen suchen. Derzeit gibt es allerdings nur eine einzige weitere CA bei der man kostenlose Certifikate bekommt, LetsEncrypt.

Da mir persönlich jedoch die durch den offiziellen ACME-Client certbot vorgegebene Ablagestruktur sowie die stark eingeschränkte Funktionalität bezüglich selbsterstellter CSR nicht zusagen und ich darüberinaus mit FreeBSD auch ein OS verwende, welches derzeit nur rudimentär unterstützt wird, habe ich mir einen eigenen Wrapper für das Tool geschrieben.

**Der Wrapper kann aktuell folgende Dinge automatisch erledigen:**
* Registrieren eines LetsEncrypt Accounts
* Erzeugen von ECC (secp384r1) und RSA (2048Bit) Keys pro Domain
* Erzeugen von ECC (secp384r1) und RSA (2048Bit) Backup-Keys pro Domain
* Erzeugen von ECC (SHA384) und RSA (SHA384) CSRs pro Subdomain
* Erzeugen der ECC und RSA Zertifikate mittels certbot pro Subdomain
* Einbinden der ECC und RSA Zertifikate in Apache24 pro Subdomain
* Einbinden der ECC und RSA Zertifikate in Postfix pro Subdomain
* Einbinden der RSA Zertifikate in Dovecot pro Subdomain
* Erneuern der Zertifikate wenn weniger als 10 Tage gültig
* Erzeugen und aktivieren von HSTS und HPKP

**TODO**
* Kompatibilität zu anderen OS/Distros herstellen
* Sourcecode optimieren und aufräumen
* Dokumentation erstellen
* Funktionalität erweitern

**Notwendige manuelle Konfiguration vor der ersten Nutzung des Script:**
* Es muss für jede Subdomain ein eigener VirtualHost existieren.
* Es muss für jede Subdomain ein eigener SSL-VirtualHost existieren.
* In der Apache Konfiguration vor dem ersten VirtualHost einfügen (wenn ein anderes WWWDIR gewünscht ist, bitte auch hier ändern):
```
	<DirectoryMatch "^\.well-known">
	    Require all granted
	</DirectoryMatch>
	<FilesMatch "^\.well-known">
	    Require all granted
	</FilesMatch>
	AliasMatch "^/?\.well-known/acme-challenge(.*)" "/data/www/acme/.well-known/acme-challenge$1"
	<Directory "/data/www/acme">
	    Options None +FollowSymlinks
	    AllowOverride None
	    Require all granted
	</Directory>
```

**Ablagestruktur:**
* Basis-Verzeichnisse
```
  SSLDIR = /data/ssl # Konfigurierbar im Script
  WWWDIR = /data/www # Konfigurierbar im Script
```
* Account-Verzeichnis
```
  ${SSLDIR}/acme/accounts
```
* Domain-Verzeichnis
```
  ${SSLDIR}/${DOMAIN}
```
* Subomain-Verzeichnis
```
  ${SSLDIR}/${DOMAIN}/${SUBDOMAIN}
```
* ACME-Challenge-Verzeichnis
```
  ${WWWDIR}/acme/.well-known/acme-challenge
```

**Copyright © 2016 Markus Kohlmeyer**