#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'


/*/{Protheus.doc} F450ORDEM
Permite a alteração da ordem dos títulos apresentados para seleção, no momento de realizar a compensação entre carteiras.Deve retornar a nova chave para a Indregua
@type     function
@since       2023.01.01
/*/
User Function F450ORDEM()

Local cChave  := PARAMIXB[1]

cChave := "TITULO"

Return( cChave )
