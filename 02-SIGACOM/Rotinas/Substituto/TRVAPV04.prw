#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRVAPV04
XXXXXXXXXXXXXXXXXXXXXXXX

@type function
@version 1.0
@author Gustavo
@since 18/04/2023
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com.br/display/public/framework/FWFormModelStruct
@see https://devforum.totvs.com.br/2695-adicionar-campo-view-e-model-atraves-do-ponto-de-entrada-em-mvc
@return variant, Nil
/*/
user function TRVAPV04()
	local aAreaX	:= fwGetArea()
	local aMvPar	:= {}
	local nX		:= 0
	local cRet		:= ""

	//Se tiver parâmetros
	for nX := 1 to 60
		aadd( aMvPar, &( "MV_PAR" + strZero( nX, 2, 0 ) ) )
	next nX

	cRet := "CR_ZMANTER|"

	for nX := 1 to len( aMvPar )
		&( "MV_PAR" + strZero( nX, 2, 0 ) ) := aMvPar[ nX ]
	next nX

	fwRestArea( aAreaX )
return cRet
