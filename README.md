# UniFi Dashboard for Home Assistant

A UniFi-inspired network overview using **native Home Assistant cards** and
**card-mod for styling**. A wide controller header, a compact traffic row, and
aligned device panels bring back the structure of the original dashboard without
Bubble Card, Mini Graph Card, Button Card, Stack in Card, or Multiple Entity Row.

All dashboard labels and documentation are in English. Home Assistant still
localizes built-in states and dialogs according to your profile language.

## Design

On a wide screen:

```text
┌────────────────────────────────────────────────────────────────────┐
│ UniFi Network                  Dream Router: CPU / Memory / Temp    │
├──────────────────────┬──────────┬──────────┬──────────┬─────────────┤
│ WAN traffic (TX/RX)  │ LAN      │ Wi-Fi    │ Main     │ Guest       │
├──────────────────────┼──────────┴──────────┼──────────┴─────────────┤
│ Client access        │ LAN details        │ Wi-Fi details          │
├──────────────────────┼────────────────────┴────────────────────────┤
│ Firmware             │ Offline clients                             │
└──────────────────────┴─────────────────────────────────────────────┘
```

This is a layout guide, **not a screenshot of a tested live installation**.
The header spans the dashboard, with CPU, memory, and temperature histories
stacked vertically on the right. WAN traffic gets twice the width of a client
graph, and the offline list occupies two device columns. CSS container queries
adapt to the available card width, including when the Home Assistant sidebar is
open: the traffic row becomes two columns below 900px and one below 450px;
the header and device rows stack below 700px.

Cards use theme-provided backgrounds/text, subtle borders, 8px corners, blue
and orange graph accents, and no forced dark theme. There are no external images.

**Native design limits:** router values use three stacked 24-hour line graphs
with current values, not the original Bubble progress bars. Each entire line
uses green/yellow/red according to the **current** value, not the historical
value of each segment. Missing/non-numeric current states use a neutral color.
Native sensor graphs show a current value and history;
the WAN graph retains native axes and legend. These are not pixel-identical to
Mini Graph Card. Styling does not replace the charts or hide missing data.

## Features

- CPU, memory, and CPU temperature as stacked 24-hour native line graphs,
  with current-value warning colors and compact 40px sparklines.
- Current LAN/Wi-Fi/main/guest client counts with seven-day native sensor graphs.
- Seven-day TX/RX history for the WAN port.
- Router uptime, Wi-Fi details, and individual client-access switches.
- Firmware status; tapping opens details rather than installing immediately.
- A native offline list for explicitly selected client trackers.
- Two independent optional additions: automatic offline discovery and topology.

This is a **dashboard template**, not an integration or a HACS package.
Replace the example entity IDs before using it.

## Requirements

- A current stable Home Assistant release with Sections views, native sensor,
  tile, and entity-filter cards supporting `conditions`.
- The official [UniFi Network integration](https://www.home-assistant.io/integrations/unifi/).
- [card-mod 4](https://github.com/thomasloven/lovelace-card-mod), installed through
  HACS or manually according to its instructions. Its support for styling native
  grid cards without `ha-card` is needed here. Choose a compatible Home Assistant/
  card-mod version pair from the project's compatibility table.
- A modern browser or Companion App WebView supporting CSS container queries.
- The required sensors, trackers, switches, and update entity. Some are disabled
  by default or only available on certain hardware.
- Recorder/History with at least seven days retained for these sensors. Do not
  exclude them from Recorder. Native sensor graphs require recorded history;
  the WAN history graph may backfill older data from suitable long-term statistics.

Only **one frontend dependency** is needed for the base design: card-mod.
Without it the native cards still work, but the responsive styling, wide WAN/
offline cards, and combined header are lost. Remove all `card_mod` blocks if you
want an entirely dependency-free version; adjust native grid columns for your
screen yourself.

Credentials belong in the integration, **never in dashboard YAML**. Client access
and firmware actions require suitable UniFi permissions; monitoring can use
more restricted access.

## Installation

1. Back up your existing dashboard using its **Raw configuration editor**.
2. Install card-mod. Under **Settings > Dashboards > Resources**, verify that
   its JavaScript module is registered, following the project's instructions.
   HACS normally manages this resource. Reload the browser after installation.
   If using `frontend.extra_module_url`, follow card-mod's guidance and keep its
   URL/version consistent with the dashboard resource to avoid duplicate loading.
3. Create and open a new empty dashboard under **Settings > Dashboards**.
   Take control first if the dashboard is automatically managed.
4. Copy [dashboard.yaml](./dashboard.yaml) and replace the entities listed below.
   Find your IDs under **Developer tools > States** or
   **Settings > Devices & services > Entities**. Also change the header's
   `UniFi Dream Router` text if you use a different router.
5. Paste the **whole file** into the new dashboard's **Raw configuration editor**
   and save. Do not paste it into a single-card editor or `configuration.yaml`.
6. Check readings, units, layout, and actions. Remove unavailable cards/rows rather
   than supplying artificial zero values.
7. Replace the old dashboard only after checking the new one. Uninstall old custom
   cards only if no other dashboards still use them.

Keep personal versions in ignored `local/` or `dashboard.local.yaml`.
Review every Git upload for private data even when using ignored local files.

### Entity mapping

Router IDs follow the original Dream Router example, but your IDs may differ
even with the same hardware. Wi-Fi networks and clients use neutral placeholders.
Replace each ID **at every occurrence**.

The prefix before the dot is the **entity domain**, not the device model.
`name:` only changes the displayed label; `entity:` selects the actual data or
control. Device names, MAC addresses, integration entry IDs, and friendly names
cannot replace an entity ID.

| Example entity | Domain / expected state and unit | Select from / avoid | Replace |
| --- | --- | --- | --- |
| `sensor.dream_router_cpu_utilization` | `sensor`: numeric 0–100, `%` | Router CPU utilization; not CPU load average | 1 occurrence |
| `sensor.dream_router_memory_utilization` | `sensor`: numeric 0–100, `%` | Router memory utilization; not free/used memory in bytes | 1 occurrence |
| `sensor.dream_router_dream_router_cpu_temperature` | `sensor`: numeric temperature, `°C` | Router CPU temperature; not another device's temperature | 1 occurrence |
| `sensor.dream_router_uptime` | `sensor`: duration with time unit, or timestamp with `device_class: timestamp` | Router uptime/startup; not a client's last-seen time | 1 occurrence |
| `update.dream_router` | `update`: `on` = update available, `off` = no update offered | Router firmware; not HA Core update or a restart `button` | 1 occurrence |
| `sensor.dream_router_connected_lan_clients` | `sensor`: nonnegative numeric count, no physical unit | Connected wired clients at the intended router/site scope; not port count | 2 occurrences |
| `sensor.dream_router_wlan_users` | `sensor`: nonnegative numeric count, no physical unit | Connected Wi-Fi clients at the intended router/site scope; not AP count | 2 occurrences |
| `sensor.dream_router_port_5_tx` | `sensor`: numeric data **rate**, e.g. `Mbit/s` | Actual WAN port TX; not cumulative bytes or negotiated link speed | 1 occurrence |
| `sensor.dream_router_port_5_rx` | `sensor`: numeric data **rate**, same unit as TX | Same WAN port RX; not cumulative bytes or negotiated link speed | 1 occurrence |
| `sensor.wlan_main_clients` | `sensor`: nonnegative numeric count | Clients of the main SSID; not a Wi-Fi enable/disable switch | 2 occurrences |
| `sensor.wlan_guest_clients` | `sensor`: nonnegative numeric count | Clients of the guest SSID; not an unrelated network | 2 occurrences |
| `sensor.wlan_main_disconnected_clients` | `sensor`: nonnegative numeric count | Disconnected clients of the main SSID, if provided; not a connectivity `binary_sensor` | 1 occurrence |
| `switch.client_1`, `switch.client_2`, `switch.client_3` | `switch`: `on` / `off`, verified access semantics | Individual UniFi client access; not PoE, port power, SSID, or firewall switches | 1 occurrence each |
| `device_tracker.client_1`, `device_tracker.client_2`, `device_tracker.client_3` | `device_tracker`: `home` / `not_home`; `source_type: router` for automatic discovery | Router-backed client presence; not `person`, GPS tracker, or connectivity `binary_sensor` | 1 occurrence each |

Counts refer to the supplied base dashboard, not optional cards. SSID-wide and
router-wide client counts are not interchangeable; pick the scope you intend
and rename the card if it differs. Availability and entity names vary by UniFi
hardware, firmware, integration version, and account permissions.

#### Finding the right entity

1. Open **Settings > Devices & services > UniFi Network** and open your router,
   Wi-Fi network, or client device. Look for the metric/control described above;
   the entity's exact label may vary.
2. If it is missing, use the **Entities** list with the UniFi integration filter
   and include disabled entities. Enable the relevant entity if it is provided
   and you need it. A disabled entity may not appear under Developer tools.
3. In **Developer tools > States**, select the entity and inspect its **raw state**,
   `unit_of_measurement`, and relevant attributes. A graph needs a numeric
   state such as `42`, not text such as `42%`. The `%` belongs in the unit attribute.
   `unknown` or `unavailable` cannot establish that a replacement is working.
4. Confirm it belongs to the intended device/network, copy its full entity ID,
   and compare a live value with the UniFi controller. For switches, verify
   behavior using a noncritical client only.

Do not use **Set state** to create missing sensors or convert units. That only
changes HA's current in-memory state, does not create a persistent integration
entity, and does not operate the device.

#### Replacing entities safely

For example, if your router exposes `sensor.gateway_cpu_usage` in percent, change:

```yaml
type: sensor
entity: sensor.gateway_cpu_usage
name: CPU
graph: line
detail: 2
hours_to_show: 24
```

This is a **partial illustration**, not a complete replacement dashboard.
Keep the existing chart's `card_mod` styling and color template: it reads
`config.entity`, so it automatically follows the replacement entity. The new ID is
illustrative; it is not guaranteed to exist in your installation.

In VS Code, use Find/Replace within your local dashboard copy to replace the
**full old ID**, not just `dream_router`. For example, replace
`sensor.dream_router_connected_lan_clients` in both the graph and LAN details.
Do not rename actual HA entities just to match this template.

Client switches and trackers are separate entities even for the same physical
device. Map each independently. Add/remove complete list items to support more
or fewer clients; matching the example's three clients is not required.

#### Missing or incompatible entities

| Situation | Safe adaptation |
| --- | --- |
| No CPU temperature sensor | Remove that sensor card from the router's vertical stack. Do not substitute a fake zero. |
| No guest Wi-Fi | Remove its sensor card **and** its Wi-Fi details row. In the traffic grid change `columns: 6` to `5` to keep the remaining four cards on one desktop row with WAN spanning two columns. |
| No disconnected-count sensor | Remove only that details row. Do not substitute a tracker or estimate a count from its state. |
| No client-access switches / insufficient permissions | Remove the Client access card; a tracker is read-only and cannot replace a switch. |
| No firmware `update` entity | Remove the tile. A restart button is not a firmware update replacement. |
| Only a connectivity `binary_sensor` is available | Not a drop-in tracker replacement: identify its raw connected/disconnected states and adjust the native filter conditions and entity domain deliberately. The optional Auto Entities snippet only discovers UniFi `device_tracker` entities. |
| CPU/memory reported as a 0–1 fraction or bytes | Not compatible with the percentage warning thresholds as supplied. Use a real percentage metric or explicitly create and document a persistent conversion sensor outside this template. |
| WAN RX/TX use different units | Use matching-rate entities or an explicit persistent unit conversion. Renaming a unit does not convert values. |
| No numeric client-count sensors | Remove the corresponding graphs/rows or supply separately configured numeric count sensors. Presence trackers cannot replace count sensors directly. |

Compatible sensors from another integration can drive the native numeric cards
if meaning, scope, state, and units match. The **automatic** offline snippet is
intentionally restricted to the official `unifi` integration; the topology
snippet requires its separate Network Map integration entry.

### Important semantics

- Port 5 is an example. TX/RX are from the router port's perspective; do not
  assume download/upload direction without checking. These are data rates,
  **not an internet speed test**. Use sensors with matching units.
- The temperature chart assumes °C without overriding the entity's unit.
  Convert its warning thresholds if your entity uses °F.
- Router line colors use the current numeric value: green below 31, yellow from
  31 up to (but not including) 61, red from 61. Edit the `>= 31` / `>= 61` checks
  in each chart's `card_mod` template to customize the thresholds, especially
  temperature. These are example thresholds, not hardware safety guarantees.
  The entire history is recolored when the current value changes; historical
  threshold crossings are not individually colored. Unknown, unavailable,
  and other non-numeric states remain neutral, never a fabricated zero.
- Router charts retain 24 hours of history; traffic/client charts retain the
  seven-day display period. Both require actual Recorder data. Changing a
  router chart's `hours_to_show` does not change its current-value color rules.
- Wi-Fi counters count **clients**, not access points.
- Official UniFi client-access switches normally mean **on = access allowed**,
  **off = blocked**. Verify before switching; do not substitute PoE, Wi-Fi, or
  firewall switches. The dashboard deliberately has no bulk toggle.
- A UniFi tracker in `not_home` is not detected as connected; this does not prove
  device failure or a person's absence. Detection can be delayed. Randomized
  MAC addresses and sleeping clients can affect tracking.
- `unknown` and `unavailable` are **not** classified as offline. “Last changed”
  is the HA state change, not necessarily the exact disconnection time.
- The offline card stays visible when empty. An empty list **does not prove**
  every device is reachable: check missing or unavailable trackers separately.

## Optional additions

Each file below contains **one card**, not a whole dashboard.
Both additions are independent of each other and are not required by the base.

### Automatic offline clients

1. Install [Auto Entities](https://github.com/thomasloven/lovelace-auto-entities)
   through HACS and load its resource according to its instructions.
2. In the raw dashboard YAML, replace the `entity-filter` card inside the last
   grid's `cards` list with [optional/auto-offline-clients.yaml](./optional/auto-offline-clients.yaml),
   keeping the same indentation. This preserves its wide offline-list position.
   Alternatively add the snippet as a standalone manual card.

The filter selects `device_tracker` entities from the official `unifi` integration
with `source_type: router` and state `not_home`. It does not pick up unrelated
router integrations. With multiple UniFi integration entries it includes all of
them; narrow it using your own attributes if needed. If nothing appears, check
states, attributes, and integration membership. Unknown/unavailable devices are
not included here either.

Private Wi-Fi/IP exclusions are not bundled. Add your own under `filter.exclude`
if needed, for example:

```yaml
  exclude:
    - attributes:
        essid: YOUR_GUEST_WIFI
    - attributes:
        ip: "192.0.2.*"
```

The IP pattern is a documentation example, not a real local subnet.
Trackers without those attributes are not excluded by those rules.

### Network topology

1. Install and configure the separate
   [UniFi Network Map integration](https://github.com/merlijntishauser/unifi-network-maps-ha).
   The official UniFi integration and Auto Entities alone cannot render topology.
2. Add [optional/network-map.yaml](./optional/network-map.yaml) as a manual card
   in a new section beneath the overview. Expand that section/card if desired.
3. Replace `REPLACE_WITH_NETWORK_MAP_ENTRY_ID` with the **Network Map integration's
   entry ID**, not the official UniFi integration's ID. The provider documents
   the `entry_id` attribute on `sensor.unifi_network_map_status`; alternatively
   select the integration through its visual card editor.
4. Adjust the 600px card height if needed.

There is no equivalent native topology card. The optional map uses its default
appearance rather than forcing a theme. These third-party projects handle their
own updates and compatibility; their code is not bundled here.

## Changes from the original

The screenshot's broad header, traffic row, three-column device panels, and wide
offline list guide this layout. Native grids and one native vertical stack replace
the repeated custom stacks. Native stacked sensor/history graphs replace
Bubble Card and Mini Graph Card; card-mod supplies presentation only.

Duplicate uptime rows and the misleading “Access Points” counter label are gone.
The original “disconnected devices” filter did not test for an offline state;
the new lists explicitly require `not_home`. Private IDs, external logos, and
theme-specific dependencies are not published. No template sensors, helpers,
or automations are required.

## Validation

From the repository directory:

```sh
ruby tests/validate.rb
```

This uses Ruby's standard library to check YAML syntax, duplicate keys, native
card types, the full-width layout and responsive-style rules, entity documentation,
router warning templates and 24-hour histories, seven-day traffic graphs, safe
firmware actions, and optional filters.
GitHub Actions runs the same checks.

These are **static configuration checks, not live Home Assistant or visual tests**.
Without access to a real installation, entity availability, units, permissions,
chart rendering, and card-mod application cannot be verified.

### Home Assistant checklist

- Desktop/sidebar open and phone: header, graph row, and device panels wrap
  without horizontal scrolling or clipped content.
- If panels look unstyled or stay in six narrow columns, check card-mod loading
  and browser container-query support; refresh the frontend cache if needed.
- CPU/memory/temperature: real values, correct units, suitable warning thresholds.
- History: enough retained data, correct WAN port, correct TX/RX mapping.
- Access switches: check direction with a noncritical test device; never block
  your own management access.
- Offline list: disconnect/reconnect a selected test client and wait for tracking
  updates; it should only appear when `not_home`.
- Firmware: tapping opens details and does not immediately start an update.
- Optional cards: resources loaded and correct integration/entry ID selected.

## License

[MIT](./LICENSE). Independent community project, not affiliated with Ubiquiti
or the Home Assistant project.
