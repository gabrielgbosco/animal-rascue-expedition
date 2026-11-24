class_name SpeciesDB
extends RefCounted
## Catálogo de espécies do jogo (GDD, seções 9 e 6.3).
##
## Cada entrada traz os campos da ficha. "fonte" fica vazio até termos a
## referência científica (exigência do GDD, Pilar 4). Não publicar sem preencher.

const SPECIES: Dictionary = {
	"tartaruga": {
		"nome": "Tartaruga",
		"cientifico": "Ordem Testudines",
		"habitat": "rios, lagos e florestas úmidas (varia conforme a espécie)",
		"alimentacao": "varia conforme a espécie: plantas aquáticas, frutos, insetos e pequenos peixes",
		"curiosidade": "Algumas tartarugas podem viver 100 anos ou mais e têm casca dura que as protege de predadores.",
		"imagem": "res://assets/generated/turtle_base.png",
		"fonte": "",
	},
	"golfinho": {
		"nome": "Golfinho",
		"cientifico": "Família Delphinidae",
		"habitat": "oceanos e mares costeiros",
		"alimentacao": "peixes e lulas",
		"curiosidade": "Golfinhos respiram ar pelo orifício no topo da cabeça, e não pelo focinho.",
		"imagem": "",
		"fonte": "",
	},
	"cabra-montesa": {
		"nome": "Cabra-montesa",
		"cientifico": "a confirmar",
		"habitat": "regiões montanhosas e rochosas",
		"alimentacao": "a confirmar",
		"curiosidade": "As cabras-monteses têm cascos adaptados para se equilibrar em rochas íngremes.",
		"imagem": "",
		"fonte": "",
	},
	"elefante": {
		"nome": "Elefante",
		"cientifico": "Loxodonta africana",
		"habitat": "savanas e florestas",
		"alimentacao": "plantas: folhas, cascas, raízes e frutos",
		"curiosidade": "Elefantes precisam beber água com frequência e usam a tromba para isso.",
		"imagem": "",
		"fonte": "",
	},
}


static func has_species(species_id: String) -> bool:
	return SPECIES.has(species_id)


static func get_data(species_id: String) -> Dictionary:
	return SPECIES.get(species_id, {})


static func ids() -> Array[String]:
	var result: Array[String] = []
	for key: String in SPECIES:
		result.append(key)
	return result
