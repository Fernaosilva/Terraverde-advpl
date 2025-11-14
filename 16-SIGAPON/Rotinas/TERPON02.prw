#INCLUDE "totvs.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

Static TITLE      := "Atualiza Data Baixa do Banco de Horas"  // Título da rotina

/*/{Protheus.doc} TERPON02
Funcao para atualização do Status e Data Baixa do banco de Horas (Tabela SPI).
@type function
@author Cristiano Pedroni
@since 07/10/2024
@version 1.0
@return Nil
/*/

User Function TERPON02()

	Local aArea          := lj7GetArea({"SPI", "SP9"})
	Local cTitulo        := TITLE
	Local cMensagem      := ""
	Local lRet           := .T.
	Local aDadosBanco    := {}

	Private oBancoHoras  := ClassPontoEletronico():New()
	Private cFil         := FWCodFil()
	Private cDataBaixa   := ""
	Private cDataInicial := ""
	Private cDataFinal   := ""
	Private cFilialDe    := ""
	Private cFilialAte   := ""
	Private cMatDe       := ""
	Private cMatAte      := ""
	Private cTipoBaixa   := ""

	If Parametro(.T.)
		If cTipoBaixa == "1"
			cMensagem += "Deseja atualizar o Status e Data Baixa do Banco de Horas de acordo com parâmetros da rotina?"
		Else
			cMensagem += "Deseja estornar o Status e Data Baixa do Banco de Horas de acordo com parâmetros da rotina"
		EndIf
		If MsgYesNo(cMensagem,cTitulo)
			aDadosBanco := oBancoHoras:GetDadosBancoDataBaixa(cFil)
			If Len(aDadosBanco) > 0
				FwMsgRun(, {|| lRet := ExecAuto(aDadosBanco)}, "Atualização do Status e Data Baixa do Banco de Horas","Aguarde a finalização do processo...")
				If lRet
					cMensagem := "O Status e Data Baixa do Banco de Horas foi atualizado com Sucesso."
				Else
					cMensagem := "Ocorreu um erro na atualização do Status e Data Baixa do Banco de Horas!"
				EndIf
			Else
				cMensagem := "Não foi identificado nenhum dado do banco de horas de acordo com os parâmetros da rotina!"
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

	BEGIN TRANSACTION

		AtualizaSPI(aDadosBanco)

		If !lRet
			DisarmTransaction()
		EndIf

	END TRANSACTION

Return(lRet)

/*
Função para atualizar o Status e Data Baixa do Banco de Horas (Tabela SPI).
*/
Static Function AtualizaSPI(aDadosBanco)

	Local cParEvePro := GetNewPar("ZZ_PONBA01","200") // Informar o Código do Evento para lançamento de Provento
	Local cParEveDes := GetNewPar("ZZ_PONBA02","201") // Informar o Código do Evento para lançamento de Desconto
	Local lRet       := .T.
	Local cLog       := " Data Baixa atualizada pelo Usuario " + usrFullName() + " em " + DTOC(DATE()) + " as " + Time() + " pela Rotina TERPON02"
	Local cEvento    := (cParEvePro + "," + cParEveDes)
	Local nRecnoSPI  := 0
	Local i

	dbSelectArea("SPI")

	For i := 1 to Len(aDadosBanco)
		nRecnoSPI := aDadosBanco[i]
		SPI->(dbGoTo(nRecnoSPI))
		If Reclock("SPI",.F.)
			If cTipoBaixa == "1"
				SPI->PI_STATUS := "B"
				SPI->PI_DTBAIX := STOD(cDataBaixa)
				SPI->PI_ZZLOG  := cLog
			Else
				SPI->PI_STATUS := ""
				SPI->PI_DTBAIX := CTOD("")
				If !(SPI->PI_PD $ cEvento)
					SPI->PI_ZZLOG  := ""
				EndIf
			EndIf
			SPI->(MsUnLock())
		Else
			lRet := .F.
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
	local aSimNao   := {"1=Atualiza Data Baixa", "2=Estorna Data Baixa"}
	Local cPerg     := TITLE + "_" + procName()
	Local cTitulo   := TITLE

	Default lPerg   := .T.

	aadd(aParambox, {1, "Data Inicial:"    , cToD("")                     , ""     , "" , ""                , "" , 050, .T.}) // MV_PAR01
	aadd(aParambox, {1, "Data Final:"      , cToD("")                     , ""     , "" , ""                , "" , 050, .T.}) // MV_PAR02
	aadd(aParambox, {1, "Data Baixa:"      , cToD("")                     , ""     , "" , ""                , "" , 050, .F.}) // MV_PAR03
	aadd(aParambox, {1, "Filial De:"       , space(TamSx3("PI_FILIAL")[1]), "@!"   , "" , "FWSM0"           , "" , 060, .F.}) // MV_PAR04
	aadd(aParambox, {1, "Filial Até:"      , space(TamSx3("PI_FILIAL")[1]), "@!"   , "" , "FWSM0"           , "" , 060, .T.}) // MV_PAR05
	aadd(aParambox, {1, "Matrícula De:"    , space(TamSx3("PI_MAT")[1])   , "@!"   , "" , "SRA"             , "" , 060, .F.}) // MV_PAR06
	aadd(aParambox, {1, "Matrícula Até:"   , space(TamSx3("PI_MAT")[1])   , "@!"   , "" , "SRA"             , "" , 060, .T.}) // MV_PAR07
	aadd(aParambox, {2, "Tipo Atualização:", "1"                          , aSimNao, 080, "Pertence( 'SN' )", .T.}) // MV_PAR10

	lRet := ParamBox(aParambox, cTitulo, @aRet,,,,,,, cPerg, .T., .T.)

	If lRet
		cDataInicial := dtos(MV_PAR01)
		cDataFinal   := dtos(MV_PAR02)
		cDataBaixa   := dtos(MV_PAR03)
		cFilialDe    := MV_PAR04
		cFilialAte   := MV_PAR05
		cMatDe       := MV_PAR06
		cMatAte      := MV_PAR07
		cTipoBaixa   := MV_PAR08
	EndIf
/*
	If cTipoBaixa .and. Empty(cDataBaixa)
		lRet := .F.
		MsgAlert("Para opção 1 deve informar a Data Baixa para atualização do Banco de Horas!",cTitulo)
	EndIf
*/
Return(lRet)

