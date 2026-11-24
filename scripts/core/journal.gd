extends Node
## Journal (autoload): diário do explorador, com o estado de cada espécie.
##
## Estados:
##  - UNKNOWN: nunca vista. Aparece como "???" no diário.
##  - OBSERVED: fotografada pelo explorador. Mostra só o nome popular.
##  - HELPED: ajudada na missão. Libera a ficha completa (GDD, Pilar 4).
##
## Salva automaticamente em user://journal.json. Testes desligam [member persist]
## para não gravar em disco.

const UNKNOWN: int = 0
const OBSERVED: int = 1
const HELPED: int = 2

## Emitido na primeira vez que uma espécie é observada.
signal species_observed(species_id: String)
## Emitido quando uma espécie é ajudada.
signal species_helped(species_id: String)
## Emitido sempre que o diário muda, para atualizar telas abertas.
signal changed

const DEFAULT_SAVE_PATH: String = "user://journal.json"

var save_path: String = DEFAULT_SAVE_PATH
var persist: bool = true

var _states: Dictionary = {}


func _ready() -> void:
	load_from_disk()


func get_state(species_id: String) -> int:
	return int(_states.get(species_id, UNKNOWN))


## Registra a observação (foto). Retorna true só na primeira vez.
func observe(species_id: String) -> bool:
	if not SpeciesDB.has_species(species_id) or get_state(species_id) != UNKNOWN:
		return false
	_states[species_id] = OBSERVED
	species_observed.emit(species_id)
	changed.emit()
	_save()
	return true


## Marca a espécie como ajudada. Retorna true só na primeira vez.
func help(species_id: String) -> bool:
	if not SpeciesDB.has_species(species_id) or get_state(species_id) == HELPED:
		return false
	_states[species_id] = HELPED
	species_helped.emit(species_id)
	changed.emit()
	_save()
	return true


func reset() -> void:
	_states.clear()
	changed.emit()
	_save()


func load_from_disk() -> void:
	_states.clear()
	if persist and FileAccess.file_exists(save_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if parsed is Dictionary:
			for species_id: String in parsed:
				if SpeciesDB.has_species(species_id):
					_states[species_id] = int(parsed[species_id])
	changed.emit()


func _save() -> void:
	if not persist:
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Journal: não foi possível salvar em %s" % save_path)
		return
	file.store_string(JSON.stringify(_states))
