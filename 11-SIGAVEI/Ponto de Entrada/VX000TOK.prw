#Include "totvs.ch"
#Include "Protheus.ch"

/*/{Protheus.doc} VX000TOK
PE para validar a data de acordo com o parâmetro
@type function
@version 12.1.23
@author Manoel Nesio - Geeker Company
@since 31/08/2022
@return Logical, lRet, informa se os dados passaram na validação
/*/
User Function VX000TOK()
	Local lRet			:= .T.
	Local aParcelas		:= aIteParc
	Local nX			:= 0
	Local lBlqDtRetr	:= SuperGetMv("ZZ_LBLDR",.F.,.T.)  // Parametro que define se a customização bloqueio de data retroativa está ativa
	//Local dDTrava		:= SuperGetMv("MV_XDTCTP",.F.,'20220801')  // Parametro de Data de trava de vencimento contas a pagar.
	Local nDias			:= SuperGetMv("MV_XQTCTP",.F., 7)  // Parametro de quantidade de dias na trava de vencimento contas a pagar.
	Local cUsuarios		:= SuperGetMv("ZZ_EXCBLQ",.F.,"000754/000758/000880/000834/000528/000804/000755")  // Parametro de usuários que não serão travados pelo fonte
	Local dtvencMin		:= Date()+nDias

	If !(__cUserID $ cUsuarios) //Ignora o bloqueio se usuário estiver no parametro de exceção

		If FWIsInCallStack("VEIXX000") .OR. FWIsInCallStack("VEIXA001") .OR. FWIsInCallStack("VEIXA002");
				.OR. FWIsInCallStack("VEIXA005") .OR. FWIsInCallStack("VEIXA007") .OR. FWIsInCallStack("VEIXA003");
				.OR. FWIsInCallStack("VEIXA004") .OR. FWIsInCallStack("VEIXA003")
			lRet			:= .T.

		else

			If lBlqDtRetr
				//Varre o array do financeiro
				For nX := 1 to Len(aParcelas)
					If aParcelas[nX,1] < dtvencMin .AND. aParcelas[nX,2] > 0
						FWAlertError("Data de vencimento não permitida! Vencimento minimo: "+DTOC(dtvencMin)+"! Favor entrar em contato com o financeiro.")
						lRet := .F.
					Endif
				Next nX
			Endif
		Endif
	Endif
Return lRet
