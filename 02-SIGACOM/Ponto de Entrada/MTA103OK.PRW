#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

//-------------------------------------------//
// Ponto de entrada                          //
// Valida classificacao                      //
// Chama rotina de aviso de chegada de peças //
//-------------------------------------------//

User Function MTA103OK()
	Local lRet := .T.
	Local lClass    := l103Class


	If FWIsInCallStack("U_TV_SIB04") .OR. FWIsInCallStack("U_TV_SIB03")
		If SF1->F1_FORNECE+SF1->F1_LOJA $ GETMV("TV_FORNCLA") //Verificar se será necessário incluir a loja na valiação
			lRet := U_TV_SIB02(aNFEDanfe[13])
		Endif
	Endif
//Grava usuario na Classificação da nota
	if lClass .AND. (!(FWIsInCallStack("U_TV_SIB04")) .AND. !(FWIsInCallStack("U_TV_SIB03")))
    u_LgIncDoc()
	endif

Return(lRet)
