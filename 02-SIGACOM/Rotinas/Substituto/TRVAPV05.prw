#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} TRVAPV05
Chamado pelo PE MTA094RO

@type function
@version 1.0
@author Gustavo
@since 18/04/2023
@link https://gkcmp.com.br (Geeker Company)
@return variant, Nil
/*/
user function TRVAPV05()
	local aAreaX	:= fwGetArea()
	local aMvPar	:= {}
	local nX		:= 0
	local aRotinaX	:= PARAMIXB[1]

	for nX := 1 to 60
		aadd( aMvPar, &( "MV_PAR" + strZero( nX, 2, 0 ) ) )
	next nX

	aadd( aRotinaX , { "Manter Aprovador" , "U_TRVAPV06" , 0 , 4 } )

	for nX := 1 to len( aMvPar )
		&( "MV_PAR" + strZero( nX, 2, 0 ) ) := aMvPar[ nX ]
	next nX

	fwRestArea( aAreaX )
return aRotinaX
