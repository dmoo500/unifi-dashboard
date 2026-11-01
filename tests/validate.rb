require "yaml"

ROOT = File.expand_path("..", __dir__)

def check(condition, message)
  raise message unless condition
end

def walk(value, &block)
  yield value if value.is_a?(Hash)
  case value
  when Hash
    value.each_value { |child| walk(child, &block) }
  when Array
    value.each { |child| walk(child, &block) }
  end
end

def check_keys(node, path)
  if node.is_a?(Psych::Nodes::Mapping)
    keys = node.children.each_slice(2).map(&:first).map(&:value)
    check(keys.uniq == keys, "#{path}: duplicate YAML keys")
  end
  node.children&.each { |child| check_keys(child, path) }
end

def load_yaml(path)
  text = File.read(File.join(ROOT, path))
  check_keys(Psych.parse_stream(text), path)
  YAML.safe_load(text, permitted_classes: [], aliases: false)
end

dashboard = load_yaml("dashboard.yaml")
check(dashboard.fetch("views").length == 1, "Expected one dashboard view")
view = dashboard["views"].first
check(view["type"] == "sections", "Expected a native sections view")
check(view["max_columns"] == 3, "Expected three desktop columns")
check(view.fetch("sections").length == 1, "Expected one full-width overview section")
section = view["sections"].first
check(section["column_span"] == 3, "Overview must span all desktop columns")
rows = section.fetch("cards")
check(rows.length == 4, "Expected header, traffic, devices and status rows")
check(rows.map { |row| row["columns"] } == [2, 6, 3, 3], "Incorrect desktop row layout")
rows.each do |row|
  check(row["type"] == "grid" && row["square"] == false, "Expected non-square native grids")
  check(row["grid_options"] == { "columns" => "full", "rows" => "auto" },
        "Rows must use full width and content-driven height")
  style = row.fetch("card_mod").fetch("style")
  check(style.include?("container-type: inline-size;") && style.include?("@container"),
        "Each row needs width-aware responsive styling")
end
check(rows[1]["card_mod"]["style"].include?("max-width: 450px") &&
      rows[1]["card_mod"]["style"].include?("grid-column: auto;"),
      "Traffic cards must become single-column on narrow screens")
check(rows[3]["card_mod"]["style"].include?("grid-column: auto;"),
      "Offline card must reset its span on narrow screens")

native_types = %w[sections grid markdown vertical-stack tile sensor history-graph entities entity-filter]
nodes = []
walk(dashboard) do |node|
  nodes << node
  if node.key?("type")
    check(native_types.include?(node["type"]), "Non-native type: #{node['type']}")
  end
  if node.key?("card_mod")
    style = node["card_mod"]["style"]
    check(node["card_mod"].keys == ["style"] &&
          (style.is_a?(String) || (style.is_a?(Hash) && style.values.all? { |css| css.is_a?(String) })),
          "Use explicit card-mod CSS or shadow-root style mappings")
  end
end

router_stack = rows[0]["cards"][1]
check(router_stack["type"] == "vertical-stack", "Router history must be vertically stacked")
router_graphs = router_stack["cards"].drop(1)
check(router_graphs.map { |card| card["name"] } == ["CPU", "Memory", "Temperature"],
      "Expected three stacked router histories")
router_graphs.each do |graph|
  check(graph["type"] == "sensor" && graph["graph"] == "line" &&
        graph["hours_to_show"] == 24 && graph["detail"] == 2,
        "Router charts must show detailed 24-hour native line history")
  styles = graph.fetch("card_mod").fetch("style")
  css = styles.fetch(".")
  check(css.include?("states(config.entity)") && css.include?("not is_number(value)") &&
        css.include?("var(--disabled-text-color)"), "Missing entity-aware unavailable-state guard")
  check(css.include?("value | float >= 61") && css.include?("value | float >= 31") &&
        css.include?("var(--error-color)") && css.include?("var(--warning-color)") &&
        css.include?("var(--success-color)"), "Incorrect current-value color thresholds")
  check(styles.fetch("hui-graph-header-footer $").include?("padding-bottom: 40px"),
        "Router sparklines must use compact 40px graph height")
end

graphs = rows[1]["cards"]
check(graphs.length == 5, "Expected WAN plus four compact client graphs")
graphs.each do |graph|
  check(graph["hours_to_show"] == 168, "History must cover exactly seven days")
  if graph["type"] == "history-graph"
    check(graph["entities"].length.between?(1, 8), "Invalid history entity count")
  else
    check(graph["graph"] == "line" && graph["detail"] == 1,
          "Native client graphs need hourly line history")
  end
end
check(rows[1]["cards"] == graphs, "All graphs must appear together in the traffic row")
check(graphs.drop(1).map { |graph| graph["name"] } ==
      ["LAN clients", "Wi-Fi clients", "Main Wi-Fi", "Guest Wi-Fi"],
      "Expected English traffic labels in the original overview order")
check(view["title"] == "Network", "Expected an English view title")
check(rows[2]["cards"].map { |card| card["title"] } == ["Client access", "LAN", "Wi-Fi"],
      "Expected English device panels in the original overview order")

offline = nodes.find { |node| node["type"] == "entity-filter" }
check(!offline.nil?, "Missing native offline list")
check(offline["conditions"] == [{ "condition" => "state", "state" => "not_home" }],
      "Native offline list must only match not_home")
check(offline["entities"].length == 3, "Expected three example client trackers")
offline["entities"].each do |entity|
  check(entity["entity"].start_with?("device_tracker."), "Offline list needs trackers")
end
check(offline["show_empty"] == true, "Keep the empty offline list visible")

nodes.select { |node| node["type"] == "entities" }.each do |card|
  check(card["show_header_toggle"] == false, "Do not expose bulk switching")
end

firmware = nodes.find { |node| node["entity"] == "update.dream_router" }
%w[tap_action icon_tap_action].each do |action|
  check(firmware.fetch(action) == { "action" => "more-info" },
        "Firmware interaction must open details, not install an update")
end

readme = File.read(File.join(ROOT, "README.md"), encoding: "UTF-8")
entities = nodes.filter_map { |node| node["entity"] }.uniq
check(entities.length == 18, "Expected all 18 example entities")
entities.each do |entity|
  check(entity.match?(/\A(?:sensor|switch|update|device_tracker)\.[a-z0-9_]+\z/),
        "Invalid entity ID: #{entity}")
  check(readme.include?("`#{entity}`"), "Undocumented entity: #{entity}")
end
mapping = readme.split("#### Finding the right entity", 2).first
entities.each do |entity|
  row = mapping.lines.find { |line| line.start_with?("| ") && line.include?("`#{entity}`") }
  check(!row.nil?, "Missing entity selection table row: #{entity}")
  domain = entity.split(".").first
  check(row.include?("`#{domain}`:"), "Missing expected domain/state: #{entity}")
  occurrences = nodes.count { |node| node["entity"] == entity }
  suffix = occurrences == 1 ? "occurrence" : "occurrences"
  check(row.include?("#{occurrences} #{suffix}"), "Incorrect replacement count: #{entity}")
end

automatic = load_yaml("optional/auto-offline-clients.yaml")
check(automatic["type"] == "custom:auto-entities", "Incorrect optional list type")
rules = automatic.fetch("filter").fetch("include")
check(rules.length == 1, "Expected one bounded inclusion rule")
rule = rules.first
check(rule["integration"] == "unifi" && rule["domain"] == "device_tracker" &&
      rule["state"] == "not_home" && rule["attributes"] == { "source_type" => "router" },
      "Automatic list must match only offline UniFi router trackers")
check(automatic["show_empty"] == true && automatic["unique"] == true,
      "Expected visible, deduplicated automatic list")
check(automatic.fetch("card")["show_header_toggle"] == false, "No bulk toggle")

map = load_yaml("optional/network-map.yaml")
check(map["type"] == "custom:unifi-network-map", "Incorrect optional map type")
check(map["entry_id"] == "REPLACE_WITH_NETWORK_MAP_ENTRY_ID",
      "Publish a placeholder, not a personal integration ID")
check(map["card_height"] == 600, "Expected a valid numeric map height")
load_yaml(".github/workflows/validate.yml")

puts "PASS: YAML, native cards, 18 documented entities, stacked router history and optional cards"
