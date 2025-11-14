#INCLUDE "totvs.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} TERPON03
Funcao para atualização do Evento do Resultado do Banco de Horas (Tabela SPB).
@type function
@author Cristiano Pedroni
@since 08/10/2024
@version 1.0
@return lRet
/*/

User Function TERPON03()

	Local aArea          := lj7GetArea({"SPB"})
	Local oBancoHoras    := ClassPontoEletronico():New()
	Local cEventoCre     := GetNewPar("ZZ_PONBA04","096") // Informar o Evento de credito para alteracao
	Local cEventoDeb     := GetNewPar("ZZ_PONBA05","454") // Informar o Evento de debito para alteracao
	Local cFil           := FWCodFil()
	Local cFilBanco      := ""
	Local cMatricula     := ""
	Local cEventoAju     := ""
	Local dDataFinal2Per := ""
	Local lRet           := .T.
	Local nSaldoBanco    := 0
	Local cChaveSPB      := SPB->PB_MAT + DTOS(SPB->PB_DATA)

	cFilBanco      := SPB->PB_FILIAL
	cMatricula     := SPB->PB_MAT
	dDataFinal2Per := dDataFinal2Per := DTOS(MV_PAR28)
	nSaldoBanco    := oBancoHoras:GetSaldoFinalResultado(cFil,cFilBanco,cMatricula,dDataFinal2Per)

	dbSelectArea("SPB")
	SPB->(DBOrderNickname("TERRAVERDE"))
	SPB->(dbGoTop())

	If SPB->(dbSeek(xFilial("SPB")+cChaveSPB))
		While SPB->(!Eof()) .and. SPB->(PB_MAT + DTOS(PB_DATA)) == cChaveSPB
			If SPB->PB_PD $ cEventoDeb
				cEventoAju := cEventoCre
			EndIf
			If Reclock("SPB",.F.)
				If nSaldoBanco > 0
					SPB->PB_HORAS := nSaldoBanco
					If !Empty(cEventoAju)
						SPB->PB_PD := cEventoAju
					EndIf
				ElseIf nSaldoBanco <= 0
					SPB->(DbDelete())
				EndIf
				SPB->(MsUnLock())
			Else
				lRet := .F.
			EndIf
			SPB->(dbSkip())
		EndDo
	EndIf

	SPB->(DbCloseArea())

	FreeObj(oBancoHoras)
	lj7RestArea(aArea)

Return(lRet)

































