#INCLUDE "totvs.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

Static cParTpCond := GetNewPar("ZZ_PONBA03","24") // Informar o tipo de condicao para Evento de debito
Static TITLE      := "Cálculo do Banco de Horas"  // Título da rotina

/*/{Protheus.doc} TERPON01
Funcao para atualização do saldo do banco de Horas (Tabela SPI).
Chamada no Ponto de Entrada PNA200GRV.
@type function
@author Cristiano Pedroni
@since 14/08/2024
@version 1.0
@return Nil
/*/

User Function TERPON01()

	Local aArea         := lj7GetArea({"SPI", "SP9"})
	Local cTitulo       := TITLE
	Local cMensagem     := "Deseja executar o cálculo do Banco de Horas?"
	Local lRet          := .T.
	Local aDadosBanco   := {}

	Private oBancoHoras := ClassPontoEletronico():New()
	Private cFil        := FWCodFil()
	Private cPerInicial := ""
	Private cPer1Fecham := ""
	Private cPer2Fecham := ""
	Private cFilialDe   := ""
	Private cFilialAte  := ""
	Private cCustoDe    := ""
	Private cCustoAte   := ""
	Private cMatDe      := ""
	Private cMatAte     := ""
	Private cGeraAcerto := ""

	If Parametro(.T.)
		If MsgYesNo(cMensagem,cTitulo)
			aDadosBanco := oBancoHoras:GetDadosBanco(cFil)
			If Len(aDadosBanco) > 0
				FwMsgRun(, {|| lRet := ExecAuto(aDadosBanco)}, "Atualização do saldo do Banco de Horas","Aguarde a finalização do processo...")
				If lRet
					cMensagem := "Cálculo do Banco de Horas atualizado com Sucesso."
				Else
					cMensagem := "Ocorreu um erro no cálculo e atualização do Banco de Horas!"
				EndIf
			Else
				cMensagem := "Não foi identificado nenhum dado de acordo com os parâmetros da rotina!"
			EndIf
		Else
			cMensagem := "Cancelado pelo Usuário."
		EndIf
	Else
		cMensagem := "Cancelado pelo Usuário."
	EndIf

	If lRet
		MsgInfo(cMensagem,cTitulo)
	Else
		MsgAlert(cMensagem,cTitulo)
	EndIf

	FreeObj(oBancoHoras)
	lj7RestArea(aArea)

Return

/*
Função para controle de execução das rotinas automáticas.
*/
Static Function ExecAuto(aDadosBanco)

	Local lRet          := .T.
	Local lRobo         := .T.
	Local lSaldoInicial := .F.
	Local aEventoNovo   := {}
	Local aRecnoSPI     := {}
	Local cFilBanco     := ""
	Local cMatricula    := ""
	Local dDataFech1Per := ""
	Local nSaldoPer1    := 0
	Local nSaldoAcum    := 0
	Local nSaldoFecham  := 0
	Local nSaldoInicial := 0
	Local nSaldoPadrao  := 0
	Local nSaldoFolha   := 0
	Local i

	BEGIN TRANSACTION

		For i := 1 to Len(aDadosBanco)

			cFilBanco     := aDadosBanco[i,1]
			cMatricula    := aDadosBanco[i,2]
			aRecnoSPI     := oBancoHoras:GetRecnoBancoHoras(cFil,cFilBanco,cMatricula)
			aEventoNovo   := {}
			nSaldoFecham  := 0
			nSaldoInicial := 0
			nSaldoPadrao  := 0
			nSaldoAcum    := 0
			nSaldoPer1    := 0
			nSaldoFolha   := 0
			lSaldoInicial := .F.
			dDataFech1Per := ""

			// Deleta o saldo padrao do banco de horas.
			If Len(aRecnoSPI) > 0
				lRet := DeletaEvento(cFil,aRecnoSPI)
			EndIf

			// Atualiza o saldo padrao do banco de horas.
			If lRet
				lRet := AtualizaSaldoPadrao(cFilBanco,cMatricula)
			EndIf

			// Atualiza saldo novo e saldo anterior entre 1 Periodo e 2 Periodo de fechamento.
			If lRet
				oBancoHoras:GetSaldoFechamento(cFil,cFilBanco,cMatricula,@nSaldoPer1,@dDataFech1Per)
				nSaldoAcum := nSaldoPer1
				lRet       := AtualizaSPI(cFilBanco,cMatricula,nSaldoPer1,nSaldoAcum,dDataFech1Per)
			EndIf

			// Grava evento para ajuste do saldo final do banco de horas.
			If lRet .and. cGeraAcerto == "S"
				If lRet
					oBancoHoras:GetSaldoFinalFechamento(cFil,cFilBanco,cMatricula,lSaldoInicial,@aEventoNovo,@nSaldoFecham,@nSaldoInicial,@nSaldoPadrao)
					If Len(aEventoNovo) > 0
						lRet := GravaEvento(aEventoNovo)
					EndIf
				EndIf
				If lRet
					lRet := AtualizaSaldoPadrao(cFilBanco,cMatricula)
				EndIf
			EndIf

			// Grava evento para ajuste do saldo inicial do banco de horas.
			If lRet .and. cGeraAcerto == "S"
				If lRet
					lSaldoInicial := .T.
					aEventoNovo   := {}
					oBancoHoras:GetSaldoFinalFechamento(cFil,cFilBanco,cMatricula,lSaldoInicial,@aEventoNovo,nSaldoFecham,nSaldoInicial,nSaldoPadrao)
					If Len(aEventoNovo) > 0
						lRet := GravaEvento(aEventoNovo)
					EndIf
				EndIf
				If lRet
					lRet := AtualizaSaldoPadrao(cFilBanco,cMatricula)
				EndIf
			EndIf

		Next i

		If lRet .and. cGeraAcerto == "S"
			PONM070(lRobo)
		EndIf

		If !lRet
			DisarmTransaction()
		EndIf

	END TRANSACTION

Return(lRet)

/*
Função para atualizar o saldo padrao do Banco de Horas.
*/
Static Function AtualizaSaldoPadrao(cFilBanco,cMatricula)

	Local lRet        := .T.
	Local lFiltraData := .F.
	Local aDadosSPI   := {}
	Local cCusto      := ""
	Local cEvento     := ""
	Local cStatus     := ""
	Local dDataBanco  := ""
	Local cTipo       := "N"
	Local nSaldoRet   := 0
	Local nValor      := 0
	Local nQuantHr    := 0
	Local nSaldoAnt   := 0
	Local i

	nSaldoAnt := oBancoHoras:GetSaldoAnteriorDataInicial(cFil,cFilBanco,cMatricula)
	aDadosSPI := oBancoHoras:GetDadosEventos(cFil,cFilBanco,cMatricula,lFiltraData)

	For i := 1 to Len(aDadosSPI)

		cCusto     := aDadosSPI[i,03]
		cEvento    := aDadosSPI[i,04]
		nQuantHr   := aDadosSPI[i,05]
		dDataBanco := aDadosSPI[i,06]
		cStatus    := aDadosSPI[i,07]
		cChaveSPI  := cFilBanco + cMatricula + dDataBanco + cEvento

		dbSelectArea("SPI")
		SPI->(dbGoTop())
		SPI->(dbSetOrder(2))

		If SPI->(DbSeek(cChaveSPI))
			While SPI->(!Eof()) .and. SPI->(PI_FILIAL+PI_MAT+Dtos(PI_DATA)+PI_PD) == cChaveSPI .and. (SPI->PI_QUANT == nQuantHr)
				nSaldoRet := oBancoHoras:GetSaldoBancoHoras(cFilBanco,cEvento,cTipo,cStatus,@nValor,nQuantHr)
				If RecLock("SPI",.F.)
					SPI->PI_ZZSLDPA := nSaldoRet
					SPI->(MsUnlock())
				EndIf
				SPI->(dbSkip())
			EndDo
		EndIf

	Next i

	SPI->(DbCloseArea())

Return(lRet)

/*
Função para atualizar o Saldo Novo e Saldo Acumulado do banco de horas.
*/
Static Function AtualizaSPI(cFilBanco,cMatricula,nSaldoPer1,nSaldoAcum,dDataFech1Per)

	Local lRet           := .T.
	Local lFiltraData    := .T.
	Local lPrimeiroSaldo := .T.
	Local aDadosSPI      := {}
	Local cTipoCond      := ""
	Local cEvento        := ""
	Local cStatus        := ""
	Local dDataBanco     := ""
	Local nSaldoNovo     := 0
	Local nVlAcumulado   := 0
	Local nQuantHr       := 0
	Local i

	aDadosSPI := oBancoHoras:GetDadosEventos(cFil,cFilBanco,cMatricula,lFiltraData)

	For i := 1 to Len(aDadosSPI)

		cCusto     := aDadosSPI[i,03]
		cEvento    := aDadosSPI[i,04]
		nQuantHr   := aDadosSPI[i,05]
		dDataBanco := aDadosSPI[i,06]
		cStatus    := aDadosSPI[i,07]
		cChaveSPI  := cFilBanco + cMatricula + dDataBanco + cEvento
		cTipoCond  := POSICIONE("SP9",1,xFilial("SP9")+cEvento,"P9_TIPOCOD")

		dbSelectArea("SPI")
		SPI->(dbGoTop())
		SPI->(dbSetOrder(2))

		If SPI->(DbSeek(cChaveSPI))
			While SPI->(!Eof()) .and. SPI->(PI_FILIAL+PI_MAT+Dtos(PI_DATA)+PI_PD) == cChaveSPI
				If (cTipoCond $ cParTpCond)
					nQuantHr := nQuantHr * (-1)
				EndIf
				If (dDataBanco > cPer1Fecham .and. dDataBanco <= cPer2Fecham)
					If nSaldoPer1 > 0
						If (nQuantHr > 0 .or. nSaldoAcum = 0)
							nSaldoNovo := __TimeSum( nSaldoNovo , nQuantHr )
						Else
							If (dDataFech1Per == dDataBanco .and. lPrimeiroSaldo) .or. !(lPrimeiroSaldo)
								nSaldoAcum := __TimeSum( nSaldoAcum , nQuantHr )
							EndIf
						EndIf
						If nSaldoAcum > 0
							nVlAcumulado := nSaldoAcum
						ElseIf nSaldoAcum < 0
							nVlAcumulado := 0
						EndIf
						If nSaldoAcum < 0
							nSaldoNovo := __TimeSum( nSaldoNovo , nSaldoAcum )
							nSaldoAcum := 0
						EndIf
					ElseIf nSaldoPer1 < 0
						If (nQuantHr < 0 .or. nSaldoAcum = 0)
							nSaldoNovo := __TimeSum( nSaldoNovo , nQuantHr )
						Else
							If (dDataFech1Per == dDataBanco .and. lPrimeiroSaldo) .or. !(lPrimeiroSaldo)
								nSaldoAcum := __TimeSum( nSaldoAcum , nQuantHr )
							EndIf
						EndIf
						If nSaldoAcum < 0
							nVlAcumulado := nSaldoAcum
						ElseIf nSaldoAcum > 0
							nVlAcumulado := 0
						EndIf
						If nSaldoAcum > 0
							nSaldoNovo := __TimeSum( nSaldoNovo , nSaldoAcum )
							nSaldoAcum := 0
						EndIf
					EndIf
				EndIf
				If RecLock("SPI",.F.)
					SPI->PI_ZZACUM  := nVlAcumulado
					SPI->PI_ZZSALDO := nSaldoNovo
					SPI->(MsUnlock())
				EndIf
				SPI->(dbSkip())
				lPrimeiroSaldo := .F.
			EndDo
		EndIf
	Next i

	SPI->(DbCloseArea())

Return(lRet)

/*
Função para deletar os Eventos do saldo final e inicial do fechamento do banco (Tabela SPI).
*/
Static Function DeletaEvento(cFil,aRecnoSPI)

	Local lRet      := .T.
	Local nRecnoSPI := 0
	Local i

	dbSelectArea("SPI")

	For i := 1 to Len(aRecnoSPI)
		nRecnoSPI := aRecnoSPI[i]
		SPI->(dbGoTo(nRecnoSPI))
		If Reclock("SPI",.F.)
			SPI->(DbDelete())
			SPI->(MsUnLock())
		Else
			lRet := .F.
		EndIf
	Next i

	SPI->(DbCloseArea())

Return(lRet)

/*
Função para gravar Evento para ajuste do saldo final e saldo inicial do Banco de Horas.
*/
Static Function GravaEvento(aEventoNovo)

	Local lRet := .T.
	Local i

	dbSelectArea("SPI")

	For i := 1 to Len(aEventoNovo)
		If RecLock("SPI",.T.)
			SPI->PI_FILIAL  := aEventoNovo[i,1] // Filial
			SPI->PI_MAT     := aEventoNovo[i,2] // Matricula
			SPI->PI_DATA    := aEventoNovo[i,3] // Data banco
			SPI->PI_PD      := aEventoNovo[i,4] // Evento
			SPI->PI_CC      := aEventoNovo[i,5] // Centro de Custo
			SPI->PI_QUANT   := aEventoNovo[i,6] // Quantidade Horas
			SPI->PI_ZZSLDPA := aEventoNovo[i,7] // Saldo
			SPI->PI_FLAG    := aEventoNovo[i,8] // Flag
			SPI->PI_ZZLOG   := aEventoNovo[i,9] // Log da inclusao
			SPI->(MsUnlock())
		EndIf
	Next i

	SPI->(DbCloseArea())

Return(lRet)

/*
Funcao para montar a tela de parâmetros da rotina.
*/
Static Function Parametro(lPerg)

	Local lRet      := .T.
	Local aParamBox := {}
	Local aRet      := {}
	local aSimNao   := {"S=Sim", "N=Não"}
	Local cPerg     := TITLE + "_" + procName()
	Local cTitulo   := TITLE

	Default lPerg   := .T.

	aadd(aParambox, {1, "Data Inicial:"       , cToD("")                     , ""     , "" , ""                , "" , 050, .T.}) // MV_PAR01
	aadd(aParambox, {1, "Data 1 Fechamento:"  , cToD("")                     , ""     , "" , ""                , "" , 050, .T.}) // MV_PAR02
	aadd(aParambox, {1, "Data 2 Fechamento:"  , cToD("")                     , ""     , "" , ""                , "" , 050, .T.}) // MV_PAR03
	aadd(aParambox, {1, "Filial De:"          , space(TamSx3("PI_FILIAL")[1]), "@!"   , "" , "FWSM0"           , "" , 060, .F.}) // MV_PAR04
	aadd(aParambox, {1, "Filial Até:"         , space(TamSx3("PI_FILIAL")[1]), "@!"   , "" , "FWSM0"           , "" , 060, .T.}) // MV_PAR05
	aadd(aParambox, {1, "Centro de Custo De:" , space(TamSx3("PI_CC")[1])    , "@!"   , "" , "CTT"             , "" , 060, .F.}) // MV_PAR06
	aadd(aParambox, {1, "Centro de Custo Até:", space(TamSx3("PI_CC")[1])    , "@!"   , "" , "CTT"             , "" , 060, .T.}) // MV_PAR07
	aadd(aParambox, {1, "Matrícula De:"       , space(TamSx3("PI_MAT")[1])   , "@!"   , "" , "SRA"             , "" , 060, .F.}) // MV_PAR08
	aadd(aParambox, {1, "Matrícula Até:"      , space(TamSx3("PI_MAT")[1])   , "@!"   , "" , "SRA"             , "" , 060, .T.}) // MV_PAR09
	aadd(aParambox, {2, "Gera Acerto Banco:"  , "1"                          , aSimNao, 050, "Pertence( 'SN' )", .f.}) // MV_PAR10

	lRet := ParamBox(aParambox, cTitulo, @aRet,,,,,,, cPerg, .T., .T.)

	If lRet
		cPerInicial := dtos(MV_PAR01)
		cPer1Fecham := dtos(MV_PAR02)
		cPer2Fecham := dtos(MV_PAR03)
		cFilialDe   := MV_PAR04
		cFilialAte  := MV_PAR05
		cCustoDe    := MV_PAR06
		cCustoAte   := MV_PAR07
		cMatDe      := MV_PAR08
		cMatAte     := MV_PAR09
		cGeraAcerto := MV_PAR10
	EndIf

Return(lRet)

