extends Node
## Testes da camada de unidades: conversões métricas e formatação pt-BR.


func test_conversao_cm_para_m() -> void:
	assert(is_equal_approx(Units.convert(150.0, "cm", "m"), 1.5))


func test_conversao_m_para_cm() -> void:
	assert(is_equal_approx(Units.convert(2.4, "m", "cm"), 240.0))


func test_conversao_km_para_m() -> void:
	assert(is_equal_approx(Units.convert(1.0, "km", "m"), 1000.0))


func test_tipo_de_unidade() -> void:
	assert(Units.get_type("cm") == Units.QuantityType.LENGTH)
	assert(Units.get_type("kg") == Units.QuantityType.MASS)
	assert(Units.get_type("mL") == Units.QuantityType.CAPACITY)
	assert(Units.get_type("xyz") == -1)


func test_formatacao_ptbr() -> void:
	assert(Units.format_value(2.4) == "2,4", "2,4 usa vírgula")
	assert(Units.format_value(90.0) == "90", "90 sem casas decimais")
	assert(Units.format(2.4, Units.QuantityType.LENGTH) == "2,4 m")


func test_formatacao_automatica() -> void:
	# 0,9 m fica mais legível em cm; 2400 m em km.
	assert(Units.format(0.9, Units.QuantityType.LENGTH) == "90 cm")
	assert(Units.format(2400.0, Units.QuantityType.LENGTH) == "2,4 km")
