#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

//-------------------------------------------//
// Ponto de entrada                          //
// Valida classificacao                      //
// Chama rotina de aviso de chegada de peças //
//-------------------------------------------//

User Function MT100TOK()
	Local lRet := .T.

	// Aviso de chegada de peças
	If lRet
		U_TV_SIB01(aNFEDanfe[13],'MT100TOK')
	Endif

Return(lRet)
