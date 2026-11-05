extends Node
## Testes da classe Quantity: criação, soma com unidades mistas, subtração,
## comparação e igualdade com tolerância.


func test_criacao_com_unidade() -> void:
	var q: Quantity = Quantity.of(1.20, "m")
	assert(is_equal_approx(q.base_value, 1.2), "1,20 m deve virar 1,2 na base")
	assert(q.type == Units.QuantityType.LENGTH, "tipo deve ser comprimento")


func test_soma_unidades_mistas() -> void:
	var a: Quantity = Quantity.of(1.20, "m")
	var b: Quantity = Quantity.of(90.0, "cm")
	var soma: Quantity = a.add(b)
	assert(soma.format("m") == "2,1 m", "1,20 m + 90 cm = 2,1 m (obtido: %s)" % soma.format())


func test_subtracao() -> void:
	var total: Quantity = Quantity.of(2.4, "m")
	var parte: Quantity = Quantity.of(150.0, "cm")
	assert(total.sub(parte).format("m") == "0,9 m", "2,4 m - 150 cm = 0,9 m")


func test_comparacao() -> void:
	assert(Quantity.of(2.0, "m").compare(Quantity.of(150.0, "cm")) == 1, "2 m > 150 cm")
	assert(Quantity.of(1.0, "m").compare(Quantity.of(100.0, "cm")) == 0, "1 m == 100 cm")
	assert(Quantity.of(50.0, "cm").compare(Quantity.of(1.0, "m")) == -1, "50 cm < 1 m")


func test_igualdade_com_tolerancia() -> void:
	var alvo: Quantity = Quantity.of(2.4, "m")
	var perto: Quantity = Quantity.of(2.405, "m")
	var longe: Quantity = Quantity.of(2.5, "m")
	assert(alvo.is_equal(perto, 1.0, "cm"), "diferença de 0,5 cm fica dentro de 1 cm")
	assert(not alvo.is_equal(longe, 1.0, "cm"), "diferença de 10 cm fica fora de 1 cm")
