extends SceneTree
## Executor headless das suítes de teste do projeto.
##
## Uso (a partir da raiz do projeto):
##   godot --headless --path . -s res://tests/run_tests.gd
##
## Cada suíte é um Node com métodos "test_*" (podem ser coroutines). Falhas
## registradas em "failures" via check() são contadas aqui. Asserts nativos
## (usados em test_units.gd e test_quantity.gd) aparecem como erro no log.

const SUITES: Array[String] = [
	"res://tests/test_units.gd",
	"res://tests/test_quantity.gd",
	"res://tests/test_journal.gd",
	"res://tests/test_forest_flow.gd",
]

var _total: int = 0
var _failed: int = 0


func _init() -> void:
	_run_all.call_deferred()


func _run_all() -> void:
	for path: String in SUITES:
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			# Erro de parse na suíte (ou em algo que ela usa): conta como falha e segue.
			_total += 1
			_failed += 1
			print("\n== %s\n  FAIL  não foi possível carregar a suíte (veja os erros acima)" % path.get_file())
			continue
		var suite: Node = script.new()
		root.add_child(suite)
		print("\n== %s" % path.get_file())

		for method: Dictionary in script.get_script_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue

			_total += 1
			var before: int = _failure_list(suite).size()
			await suite.call(test_name)
			var new_failures: Array = _failure_list(suite).slice(before)

			if new_failures.is_empty():
				print("  ok    %s" % test_name)
			else:
				_failed += 1
				print("  FAIL  %s" % test_name)
				for message: String in new_failures:
					print("        - %s" % message)

		suite.queue_free()
		await process_frame

	print("\n%d teste(s), %d falha(s)." % [_total, _failed])
	quit(1 if _failed > 0 else 0)


func _failure_list(suite: Node) -> Array:
	var value: Variant = suite.get("failures")
	return value if value is Array else []
