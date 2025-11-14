#Include "Totvs.ch"

/*/{Protheus.doc} tvGetMemo
Funçao para retornar o conteudo do campo Memo da SYP.
@type function
@version P12
@author Ademar Fernandes Jr.
@since 29/07/2025
@param cMemoCod, character, Codigo do campo Memo
@param nTamLinha, numeric, Tamanho da linha
@param lWrapMemo, logical, Wrap do texto
@param lExcEnter, logical, Excluir Enter
@return variant, Retorna o conteudo do campo Memo
/*/
User Function tvGetMemo(cMemoCod,nTamLinha,lWrapMemo,lExcEnter)
    Local cObsMemo := ""
    Local nOpcMemo := 3

    Default cMemoCod  := ""
    Default nTamLinha := 80
    Default lWrapMemo := .T.
    Default lExcEnter := .T.

    If !Empty(cMemoCod)
		//MSMM( cChave, nTam, nLin, cString, nOpc, nTabSize, lWrap, cAlias, cCpochave, cRealAlias, lSoInclui )
		cObsMemo := AllTrim(MSMM(cMemoCod,nTamLinha,,,nOpcMemo,,lWrapMemo,,,,))
		//-Busca as Mensagens dos campos novos da VO1
		If VO1->(FieldPos("VO1_FALHA")) > 0 .And. !Empty(VO1->VO1_FALHA)
			cObsMemo += AllTrim(MSMM(VO1->VO1_FALHA,TamSx3("VO1_OBSERV")[1],.T.,.T.))
		EndIf
		If VO1->(FieldPos("VO1_CAUSA")) > 0 .And. !Empty(VO1->VO1_CAUSA)
			cObsMemo += AllTrim(MSMM(VO1->VO1_CAUSA,TamSx3("VO1_OBSERV")[1],.T.,.T.))
		EndIf
		If VO1->(FieldPos("VO1_SOLUCA")) > 0 .And. !Empty(VO1->VO1_SOLUCA)
			cObsMemo += AllTrim(MSMM(VO1->VO1_SOLUCA,TamSx3("VO1_OBSERV")[1],.T.,.T.))
		EndIf
		//-Retira os caracteres de quebra de linha
		cObsMemo := iif(!Empty(cObsMemo) .And. lExcEnter, StrTran(cObsMemo,"\13\10",""), "")
		cObsMemo := iif(!Empty(cObsMemo) .And. lExcEnter, StrTran(cObsMemo,"\14\10",""), "")
    EndIf

Return cObsMemo

/*/{Protheus.doc} tvConvMemo
Função para quebrar o texto em linhas num array
@type function
@version P12
@author Ademar Fernandes Jr.
@since 30/07/2025
@param cTxtCompl, character, Texto completo
@param nTamLinha, numeric, Tamanho da linha
@return variant, Retorna o texto quebrado em linhas
/*/
User Function tvConvMemo(cTxtCompl,nTamLinha)
	Local aLinhasObs := {}
	Local aFinal	 := {}
	Local cUltimo    := ""
	Local nLinhas	 := 0

	Default cTxtCompl := ""
	Default nTamLinha := 80

	If !Empty(cTxtCompl)
		Q_MemoArray(cTxtCompl, @aLinhasObs, nTamLinha)

		For nLinhas := 1 to len(aLinhasObs)
			If Alltrim(aLinhasObs[1]) == Alltrim(aLinhasObs[nLinhas]) .And. nLinhas > 1 .And. !Empty(Alltrim(aLinhasObs[nLinhas]))
				Exit
			Else
				If SubStr(aLinhasObs[nLinhas],1,1) == cUltimo
					aAdd(aFinal, SubStr(aLinhasObs[nLinhas],2))
				Else
					aAdd(aFinal, aLinhasObs[nLinhas])
				EndIf
				cUltimo := SubStr(aLinhasObs[nLinhas],Len(aLinhasObs[nLinhas]))
			EndIf
		Next
	EndIf

Return aFinal
