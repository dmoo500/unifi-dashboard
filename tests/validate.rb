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
check(view.fetch("sections").length == 5, "Expected all five dashboard sections")

native_types = %w[sections grid heading gauge tile history-graph entities entity-filter]
nodes = []
walk(dashboard) do |node|
  nodes << node
  if node.key?("type")
    check(native_types.include?(node["type"]), "Non-native type: #{node['type']}")
  end
  check(!node.key?("card_mod") && !node.key?("style"), "Unexpected custom styling")
end

gauges = nodes.select { |node| node["type"] == "gauge" }
check(gauges.length == 3, "Expected CPU, RAM and temperature gauges")
gauges.each do |gauge|
  check(gauge["min"] == 0 && gauge["max"] == 100, "Incorrect gauge range")
  check(gauge["needle"] == true, "Expected needle gauges")
  check(gauge["severity"] == { "green" => 0, "yellow" => 31, "red" => 61 },
        "Incorrect gauge color thresholds")
end

graphs = nodes.select { |node| node["type"] == "history-graph" }
check(graphs.length == 3, "Expected WAN, LAN/WLAN and per-WLAN history")
graphs.each do |graph|
  check(graph["hours_to_show"] == 168, "History must cover exactly seven days")
  check(graph["entities"].length.between?(1, 8), "Invalid history entity count")
end

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

readme = File.read(File.join(ROOT, "README.md"))
entities = nodes.filter_map { |node| node["entity"] }.uniq
check(entities.length == 18, "Expected all 18 example entities")
entities.each do |entity|
  check(entity.match?(/\A(?:sensor|switch|update|device_tracker)\.[a-z0-9_]+\z/),
        "Invalid entity ID: #{entity}")
  check(readme.include?("`#{entity}`"), "Undocumented entity: #{entity}")
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

puts "PASS: YAML, native cards, 18 documented entities, gauges, history and optional cards"
