# UniFi Dashboard für Home Assistant

Ein übersichtliches UniFi-Dashboard mit **ausschließlich eingebauten Karten** in
der Basis. Kein HACS, kein `card-mod`, keine Theme-Abhängigkeit. Die native
Sections-Ansicht ordnet die Karten auf Desktop und Smartphone an.

Wer mehr braucht, kann **zwei unabhängige optionale Erweiterungen** hinzufügen:
eine automatisch zusammengestellte Offline-Client-Liste und eine Netzwerktopologie.

## Was enthalten ist

- CPU, RAM und CPU-Temperatur mit nativen Gauge-Karten.
- Laufzeit und Firmware-Status; Firmware-Details öffnen sich per Antippen.
- Aktuelle LAN-/WLAN-Clientzahlen und sieben Tage Verlauf.
- TX-/RX-Datenrate des WAN-Ports und Clientzahlen je WLAN.
- Einzelne Schalter für den Netzwerkzugriff von Clients, ohne Sammelschalter.
- Native Offline-Liste für explizit ausgewählte Client-Tracker.

Dies ist eine **Dashboard-Vorlage**, keine Integration und kein HACS-Paket.
Die Beispiel-Entitäten müssen an die eigene Installation angepasst werden.

## Voraussetzungen

- Eine aktuelle stabile Home-Assistant-Version mit Sections-, Heading-, Tile-
  und Entity-Filter-Karten samt `conditions`-Unterstützung.
- Eingerichtete [UniFi-Network-Integration](https://www.home-assistant.io/integrations/unifi/).
- Die benötigten Sensoren, Tracker, Switches und Update-Entitäten. Manche sind
  standardmäßig deaktiviert oder nur für bestimmte Hardware verfügbar.
- Recorder/History für die Verlaufskarten. Die Sensoren dürfen nicht vom
  Recorder ausgeschlossen sein. Sieben Tage Historie müssen vorhanden sein;
  ältere Daten können bei geeigneten Sensoren aus Langzeitstatistiken stammen.

Zugangsdaten gehören ausschließlich in die Integration, **nicht** ins Dashboard.
Schreibaktionen wie Client-Zugriff und Firmware-Updates benötigen passende
UniFi-Berechtigungen; reine Anzeige kann mit weniger Rechten auskommen.

## Installation

1. Bestehendes Dashboard sichern: im Menü den **Rohkonfigurationseditor** öffnen
   und die aktuelle YAML-Konfiguration lokal speichern.
2. Unter **Einstellungen → Dashboards** ein neues leeres Dashboard anlegen und
   öffnen. Bei automatisch verwalteten Dashboards gegebenenfalls erst die
   Kontrolle übernehmen.
3. [dashboard.yaml](./dashboard.yaml) kopieren und die unten genannten Entitäten
   ersetzen. Deine tatsächlichen IDs findest du unter **Entwicklerwerkzeuge →
   Zustände** bzw. **Einstellungen → Geräte & Dienste → Entitäten**.
4. Die gesamte angepasste Datei in den **Rohkonfigurationseditor des neuen
   Dashboards** einfügen und speichern. Nicht in den Editor einer einzelnen Karte
   und nicht direkt in `configuration.yaml` einfügen.
5. Prüfen, ob alle Messwerte und Einheiten stimmen. Nicht vorhandene Karten oder
   Zeilen entfernen statt künstliche Nullwerte einzutragen.
6. Erst nach erfolgreicher Prüfung das alte Dashboard ablösen. Installierte
   Custom Cards nur entfernen, wenn kein anderes Dashboard sie mehr verwendet.

Persönliche Varianten kannst du im ignorierten Verzeichnis `local/` oder als
`dashboard.local.yaml` ablegen. Diese Dateien werden nicht mit Git veröffentlicht.
Vor jedem Upload trotzdem die Änderungen auf private Daten prüfen.

### Entitäten anpassen

Die Router-IDs folgen dem ursprünglichen Dream-Router-Beispiel; auch bei einem
Dream Router können sie anders heißen. WLANs und Clients sind neutrale Platzhalter.
Jede ID **an allen Fundstellen** ersetzen.

| Beispiel-Entität | Benötigter Wert |
| --- | --- |
| `sensor.dream_router_cpu_utilization` | CPU-Auslastung in Prozent |
| `sensor.dream_router_memory_utilization` | RAM-Auslastung in Prozent |
| `sensor.dream_router_dream_router_cpu_temperature` | CPU-Temperatur in °C |
| `sensor.dream_router_uptime` | Laufzeit oder Startzeitpunkt, je nach Integration |
| `update.dream_router` | Firmware-Update-Entität |
| `sensor.dream_router_connected_lan_clients` | Anzahl verbundener LAN-Clients |
| `sensor.dream_router_wlan_users` | Anzahl verbundener WLAN-Clients |
| `sensor.dream_router_port_5_tx` | TX-Datenrate des tatsächlichen WAN-Ports |
| `sensor.dream_router_port_5_rx` | RX-Datenrate des tatsächlichen WAN-Ports |
| `sensor.wlan_main_clients` | Clientzahl des Haupt-WLANs |
| `sensor.wlan_guest_clients` | Clientzahl des Gast-WLANs |
| `sensor.wlan_main_disconnected_clients` | Getrennte Clients des Haupt-WLANs |
| `switch.client_1`, `switch.client_2`, `switch.client_3` | UniFi-Client-Zugriffsschalter |
| `device_tracker.client_1`, `device_tracker.client_2`, `device_tracker.client_3` | UniFi-Client-Tracker |

**Wichtige Bedeutungen:**

- Port 5 ist nur ein Beispiel. TX/RX beziehen sich auf den Port des Routers;
  Download/Upload nicht ungeprüft aus diesen Namen ableiten. Es sind Datenraten,
  kein Internet-Speedtest. Beide Sensoren sollten dieselbe Einheit haben.
- Die Temperatur-Gauge geht von °C aus und überschreibt die Sensor-Einheit nicht.
  Bei °F den Bereich und die Schwellen entsprechend umrechnen.
- Die Gauge-Farben sind Beispielwerte aus dem bisherigen Dashboard: grün ab 0,
  gelb ab 31, rot ab 61. Die native Gauge verwendet inklusive Untergrenzen;
  die bisherige strikte Bedingung `above: 60` ist damit für ganzzahlige Werte
  abgebildet. Schwellen insbesondere für Temperaturen an die Hardware anpassen.
- Der WLAN-Sensor zählt **Clients**, nicht Access Points. Die irreführende
  Bezeichnung „Access Points“ des alten Dashboards entfällt.
- Die offiziellen UniFi-Client-Zugriffsschalter bedeuten üblicherweise **an =
  Zugriff erlaubt**, **aus = blockiert**. Vor dem ersten Schalten kontrollieren;
  nicht mit PoE-, WLAN- oder Firewall-Schaltern verwechseln.
- `not_home` bedeutet beim UniFi-Tracker „nicht als verbunden erkannt“; nicht
  zwingend, dass ein Gerät defekt oder eine Person abwesend ist. Die Erkennung
  kann verzögert sein. `unknown` und `unavailable` werden nicht als offline
  ausgegeben. „Zuletzt geändert“ ist der HA-Zustandswechsel, nicht unbedingt
  der exakte Trennungszeitpunkt.
- Die native Offline-Liste bleibt bei null Treffern als leere Karte sichtbar.
  Das ist **keine** Bestätigung, dass alle Geräte erreichbar sind: fehlende oder
  nicht verfügbare Tracker unter Entwicklerwerkzeuge prüfen.

## Optionale Erweiterungen

Die Basis funktioniert ohne diese Erweiterungen. Jede Datei unten enthält
**genau eine Karte**, kein vollständiges Dashboard. Im Bearbeitungsmodus eine
manuelle Karte anlegen und deren YAML einfügen.

### Automatische Offline-Client-Liste

1. [Auto Entities](https://github.com/thomasloven/lovelace-auto-entities) über HACS
   installieren und die Dashboard-Ressource gemäß dessen Anleitung laden.
2. Die native Entity-Filter-Karte im Abschnitt „Offline-Clients“ durch
   [optional/auto-offline-clients.yaml](./optional/auto-offline-clients.yaml)
   ersetzen. Die Heading-Karte kann bleiben.

Der Filter findet `device_tracker` der offiziellen `unifi`-Integration mit
`source_type: router` und Zustand `not_home`. Er nimmt nicht versehentlich
Tracker anderer Router-Integrationen auf. Bei mehreren UniFi-Integrationen
umfasst er alle; bei Bedarf anhand eigener Attribute weiter eingrenzen.
Falls nichts erscheint, Tracker-Zustände, Attribute und Integrationszuordnung
prüfen. Auch diese Liste meldet unbekannte oder nicht verfügbare Geräte nicht
als offline.

Die alten privaten WLAN-/IP-Ausschlüsse werden nicht mitgeliefert. Bei Bedarf
unter `filter.exclude` eigene Regeln ergänzen, beispielsweise:

```yaml
  exclude:
    - attributes:
        essid: DEIN_GAST_WLAN
    - attributes:
        ip: "192.0.2.*"
```

Das IP-Muster ist ein Dokumentationsbeispiel, kein realer lokaler Netzbereich.
Tracker ohne entsprechendes Attribut werden dadurch nicht ausgeschlossen.

### Netzwerktopologie

1. Die separate Integration
   [UniFi Network Map](https://github.com/merlijntishauser/unifi-network-maps-ha)
   nach deren Anleitung installieren und konfigurieren. Nur die offizielle
   UniFi-Integration oder Auto Entities reichen hierfür nicht aus.
2. [optional/network-map.yaml](./optional/network-map.yaml) als manuelle Karte
   hinzufügen, am besten in einen eigenen Abschnitt.
3. `REPLACE_WITH_NETWORK_MAP_ENTRY_ID` durch die **Entry-ID der
   Network-Map-Integration** ersetzen, nicht durch die der offiziellen
   UniFi-Integration. Laut Anbieter findest du sie im Attribut `entry_id`
   von `sensor.unifi_network_map_status`; alternativ den visuellen Karteneditor
   der Erweiterung verwenden.
4. Die Kartenhöhe von 600 Pixeln bei Bedarf anpassen.

Es gibt keinen gleichwertigen nativen Ersatz für diese Netzwerktopologie.
Die optionale Karte verwendet ihre Standarddarstellung statt erzwungener
Themes. Updates und Kompatibilität dieser Erweiterungen liegen bei deren
jeweiligen Projekten; sie sind nicht Bestandteil dieses Repositories.

## Unterschiede zum bisherigen Dashboard

Die mehrfach verschachtelten Stacks, Bubble-/Button-/Mini-Graph-Karten,
Multiple Entity Row, externes Logo und CSS-Anpassungen entfallen.
Native Verlaufskarten behalten den Zeitraum von 168 Stunden bei, sehen aber
anders aus als Mini Graph Card. Doppelte Laufzeitzeilen entfallen.

Die alte „disconnected devices“-Karte hatte keinen Offline-Zustandsfilter.
Die neue Liste zeigt tatsächlich nur `not_home`. Die automatische Auswahl
und Topologie bleiben bewusst getrennte, optionale Custom Cards.
Es werden keine Template-Sensoren, Automationen oder zusätzlichen Helfer benötigt.

## Prüfung

Lokal aus dem Repository-Verzeichnis:

```sh
ruby tests/validate.rb
```

Die Prüfung verwendet nur Rubys Standardbibliothek. Sie prüft YAML-Syntax,
doppelte Schlüssel, native Kartentypen der Basis, die dokumentierten Entitäten,
Gauge-Schwellen, sieben Tage Verlauf und die optionalen Filter. GitHub Actions
führt dieselbe Prüfung aus.

Das ist **kein Home-Assistant-Laufzeit- oder visueller Test**. Ohne Verbindung
zu einer echten Installation sind Entitätsverfügbarkeit, tatsächliche Einheiten,
Berechtigungen und Darstellung nicht überprüfbar.

### Checkliste in Home Assistant

- Desktop und Smartphone: keine fehlerhaften oder abgeschnittenen Karten.
- CPU/RAM/Temperatur: tatsächliche Werte und Einheiten, passende Warnschwellen.
- Historie: Daten vorhanden, WAN-Port und TX/RX korrekt zugeordnet.
- Client-Zugriff: nur an einem unkritischen Testgerät die Schaltrichtung prüfen;
  nicht den eigenen Verwaltungszugang sperren.
- Offline-Liste: ein ausgewähltes Testgerät trennen und nach der
  Erkennungsverzögerung wieder verbinden; nur offline soll es gelistet sein.
- Firmware: Antippen öffnet Details, startet aber kein sofortiges Update.
- Optionale Karten: Ressourcen geladen, richtige Integration/Entry-ID verwendet.

## Lizenz

[MIT](./LICENSE). Unabhängiges Community-Projekt; keine Verbindung zu Ubiquiti
oder dem Home-Assistant-Projekt.
