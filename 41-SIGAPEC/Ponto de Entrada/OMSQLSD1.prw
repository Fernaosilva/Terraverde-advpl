#Include "totvs.ch"

/*

Ponto de Entrada para completar o SQL de Levantamento das NFs de Entrada a Conferir,
executado no levantamento das NFs das rotinas de:
- Conferencia de Itens NF Entrada no desktop (OFIOM390)
- Conferencia de Itens NF Entrada no coletor (OFIA060)
- Painel de Novas Conferencias de Entrada no coletor (OFIC090)
*/

User Function OMSQLSD1()

	Local cChamada := ParamIxb[1] 			// Origem da chamada
	Local cRet := "" 						// Retorno em SQL complementar
    LOCAL cGrupo1 := GETMV("TV_GRSCON1") 	// Grupos de produtos que não passa por conferencia configurados no sistema
		LOCAL cGrupo2 := GETMV("TV_GRSCON2") 	// Grupos de produtos que não passa por conferencia configurados no sistema
											/*
											Origem da chamada
											"1" = Levantamento das NFs da rotina de Conferencia de Itens NF Entrada no desktop (OFIOM390)
											"2" = Levantamento das NFs da rotina de Conferencia de Itens NF Entrada no coletor (OFIA060)
											"3" = Levantamento das NFs da rotina de Painel de Novas Conferencias de Entrada no coletor (OFIC090)
											*/

	cRet := " AND SD1.D1_GRUPO NOT IN ("+ cGrupo1 +") AND SD1.D1_GRUPO NOT IN("+ cGrupo2 + ")"

Return cRet
