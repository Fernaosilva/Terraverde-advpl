#Include 'Totvs.ch'
#Include 'Topconn.ch'
#Include 'Tbiconn.ch'

user function LC001ROT()
	Local aRotina := ParamIxb[1]
	
	aAdd( aRotina, { "* Fatura de Locacao"  , "u_TRVRP001" , 0, 9} )
	aAdd( aRotina, { "* Contrato TerraVerde", "u_TRVRW002" , 0, 8} )
	aAdd( aRotina, { "* Aditivo TerraVerde" , "u_TRVRW003" , 0, 8} )

return aRotina
