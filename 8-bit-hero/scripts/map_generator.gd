extends RefCounted
class_name MapGenerator

const NODE_TYPES := ["enemy", "elite", "chest", "trap", "fountain", "shop", "event"]

static func generate_floor(floor: int, rng: RandomNumberGenerator) -> Dictionary:
	var nodes: Array[Dictionary] = []
	var rows := 5
	var id_counter := 0
	var row_ids: Array[Array] = []

	for row in rows:
		var count := 1 if row == 0 or row == rows - 1 else rng.randi_range(2, 3)
		var current_row: Array = []
		for col in count:
			var node_type := "start" if row == 0 else _roll_type(floor, row, rows, rng)
			if row == rows - 1:
				node_type = "boss" if floor >= 5 else "stairs"
			var node := {
				"id": id_counter,
				"type": node_type,
				"row": row,
				"col": col,
				"x": 0.5 if count == 1 else float(col + 1) / float(count + 1),
				"y": float(row) / float(rows - 1),
				"links": [],
				"visited": row == 0,
				"resolved": row == 0,
				"known": row <= 1
			}
			nodes.append(node)
			current_row.append(id_counter)
			id_counter += 1
		row_ids.append(current_row)

	for row in range(rows - 1):
		for from_id in row_ids[row]:
			var next_row: Array = row_ids[row + 1]
			var link_count: int = min(next_row.size(), rng.randi_range(1, 2))
			var shuffled := next_row.duplicate()
			_shuffle_array(shuffled, rng)
			for i in link_count:
				_link_nodes(nodes, int(from_id), int(shuffled[i]))
		# 次の行の孤立を防ぐ
		for to_id in row_ids[row + 1]:
			if _incoming_count(nodes, int(to_id)) == 0:
				var from_candidates: Array = row_ids[row]
				_link_nodes(nodes, int(from_candidates[rng.randi_range(0, from_candidates.size() - 1)]), int(to_id))

	return {"floor": floor, "nodes": nodes, "current_id": 0}

static func get_node(map_data: Dictionary, node_id: int) -> Dictionary:
	for node in map_data.nodes:
		if int(node.id) == node_id:
			return node
	return {}

static func get_available_nodes(map_data: Dictionary) -> Array[Dictionary]:
	var current := get_node(map_data, int(map_data.current_id))
	var result: Array[Dictionary] = []
	for link_id in current.get("links", []):
		var node := get_node(map_data, int(link_id))
		if not node.is_empty() and not bool(node.resolved):
			result.append(node)
	return result

static func mark_reachable_known(map_data: Dictionary) -> void:
	var current := get_node(map_data, int(map_data.current_id))
	for link_id in current.get("links", []):
		var node := get_node(map_data, int(link_id))
		if not node.is_empty():
			node.known = true

static func move_to(map_data: Dictionary, node_id: int) -> Dictionary:
	map_data.current_id = node_id
	var node := get_node(map_data, node_id)
	node.visited = true
	node.known = true
	mark_reachable_known(map_data)
	return node

static func resolve_current(map_data: Dictionary) -> void:
	var node := get_node(map_data, int(map_data.current_id))
	if not node.is_empty():
		node.resolved = true

static func _roll_type(floor: int, row: int, rows: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if row == rows - 2 and roll < 0.35:
		return "shop"
	if roll < 0.26:
		return "enemy"
	if roll < 0.36:
		return "elite"
	if roll < 0.52:
		return "chest"
	if roll < 0.66:
		return "trap"
	if roll < 0.8:
		return "fountain"
	if roll < 0.9:
		return "shop"
	return "event"

static func _link_nodes(nodes: Array[Dictionary], from_id: int, to_id: int) -> void:
	var from_node := get_node({"nodes": nodes}, from_id)
	if not from_node.links.has(to_id):
		from_node.links.append(to_id)

static func _incoming_count(nodes: Array[Dictionary], to_id: int) -> int:
	var count := 0
	for node in nodes:
		if node.links.has(to_id):
			count += 1
	return count

static func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = values[i]
		values[i] = values[j]
		values[j] = tmp
