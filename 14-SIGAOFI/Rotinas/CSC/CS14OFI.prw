#Include 'Protheus.ch'
#Include 'TopConn.ch'
#include 'FWMVCDEF.ch'



//-------------------------------------------------------------------
/*/{Protheus.doc} CS14OFI

Realiza a abertura de OS e requisição do serviço

@author Charlles Reis
@since  Agosto/2021
@version 1.0
/*/
//-------------------------------------------------------------------

User Function CS14OFI(nChamada)

	Local lRet      	:= .T.
	Local cNumOS    	:= ""
	Local cNroOrc		:= ""

	Private aArea     	:= GetArea() // Claudia
	Private aIndVO1   	:= {} // Claudia
	Private cCondicao 	:= "" // Claudia
	Private aMemos  	:= {{"VO1_OBSMEM","VO1_OBSERV"}}
	Private aCpoEnchoice := {}

//	Private aRotina     := MenuDef()
	Private nLimCre     := val(&(GetMV("MV_LIMCRE"))) , nIndVO1 := 0
	Private lAuto       := .f.
	Private lImpOsv     := .t.
	Private cPerg       := "OFM010"

	Private cCadastro   := OemToAnsi("Abertura de OS - CSC")
	Private cGetDados   := "oGD010"
	Private lA1_IBGE    := If(SA1->(FieldPos("A1_IBGE"))>0,.t.,.f.)

	// Especifico para integração com Garantia
	Private aRetWS      := {}

	Private lGarMut     := (VO1->(FieldPos("VO1_GARMUT")) <> 0 )
	Private nValGarMut  := 0

	Private nOpc        := nChamada

	If  nOpc == 0

		If  Empty(Z01->Z01_NUMORC)

			If  MsgYesNo("Deseja abrir um orçamento p/ o Dpto. de Oficina?", "Atenção!")

				FwMsgRun(Nil, {|| lRet := CS14AOR(@cNroOrc) }, "Abrir Orçamento", "Gerando Orçamento Oficina...")

				If  lRet

					MsgInfo("Orçamento gerado. Nro: " + cNroOrc, "Atenção")
					RecLock("Z01",.F.)
					Z01->Z01_NUMORC := cNroOrc
					Z01->Z01_STATUS := "3"
					MsunLock()

					If	MsgYesNo("Deseja visualizar e/ou o orçamento gerado?", "Atenção")

						If	Type("oModel") <> "U"
							oModel:DeActivate()
						EndIf

						OFIC170( xFilial("VS1") , cNroOrc )

						If ExistBlock("ORCAMTO")
							ExecBlock("ORCAMTO",.f.,.f.,{VS1->VS1_NUMORC})
						Endif

						If	Type("oModel") <> "U"
							oModel:Activate()
						EndIf

					EndIf

				EndIf

			EndIf

		Else

			MsgStop("Já existe um orçamento gerado para este atendimento.","Atenção!")
			Return .F.

		EndIf

	ElseIf  nOpc == 1

		If  !Empty(Z01->Z01_NUMORC)
			MsgStop("Já existe um ORÇAMENTO para este atendimento, não será possível abrir uma OS, faça a geração da OS a partir do Orçamento nro.: " + Z01->Z01_NUMORC,"Atenção!")
			Return .f.
		EndIf

		If  Empty(Z01->Z01_NUMOSV)

			If  MsgYesNo("Deseja abrir uma ordem de serviços p/ o Dpto. de Oficina?", "Atenção!")

				FwMsgRun(Nil, {|| lRet := CS14AOS(@cNumOS) }, "Abrir OS", "Gerando OS Oficina...")

				If  lRet

					RecLock("Z01",.F.)
					Z01->Z01_NUMOSV := cNumOS
					Z01->Z01_STATUS := "3"
					MsunLock()

				EndIf

			EndIf

		Else

			MsgStop("Já existe uma OS Aberta para este atendimento, não será possível abrir uma nova OS.","Atenção!")
			Return .F.

		EndIf

	ElseIf  nOpc == 2

		//Consultar OS
		If  !Empty(Z01->Z01_NUMOSV)

			dbSelectArea("VO1")
			VO1->(dbSetOrder(1))
			VO1->(dbSeek(xFilial("VO1") + Z01->Z01_NUMOSV))
			FwMsgRun(Nil, {|| OFIOC060(.T.)}, "Consulta OS", "Abrindo consulta...")

		Else

			MsgStop("Não há OS Aberta para este Atendimento.","Atenção!")
			Return .F.

		EndIf

	ElseIf	nOpc == 3

		If	Type("oModel") <> "U"
			oModel:DeActivate()
		EndIf

		OFIXA120()

		If	Type("oModel") <> "U"
			oModel:Activate()
		EndIf

	EndIf

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} CS14OFI

Realiza a abertura de OS e requisição do serviço

@author Charlles Reis
@since  Agosto/2021
@version 1.0
/*/
//-------------------------------------------------------------------

Static FunCtion CS14AOR(cNroOrc)

	Local cCodDTC		:= Z01->Z01_CODERR
	Local cModelo		:= Z01->Z01_MODVEI
	Local nRegDTC		:= 0
	Local cQuery		:= ""
	Local aPecas		:= {}
	Local aSrvc			:= {}
	Local nTAMSEQ		:= TAMSX3("VS3_SEQUEN")[1]
	Local nY			:= 0
	Local nQtdPec		:= 0
	Local nValSer		:= 0
	Local nTotSer		:= 0
	Local nValHor		:= 0
	Local nVlrPec		:= 0
	Local nTotPec		:= 0
	Local nTotOrc		:= 0
	Local cFormula 		:= GETMV("MV_FMLPECA")
	Local cOper			:= GETMV("TV_OPERBAL",.F.,"59")
	Local cTTPec		:= "" //"CEP "
	Local cTTSrv		:= "" //Posicione("VOI", 1, xFilial("VOI") + cTTPec, "VOI_TTRELA")
	Local cCodSer		:= ""
	Local cGruSer		:= ""
	Local cTipSer		:= ""
	Local nTemPad		:= 0
	Local nKilRod		:= 0
	Local cTESPad		:= "" //Posicione("VOI", 1, xFilial("VOI") + cTTPec, "VOI_CODTES")
	Local cCodTES		:= ""
	Local cNatureza		:= "" //Posicione("VOI", 1, xFilial("VOI") + cTTPec, "VOI_NATPEC")
	Local cCodMar		:= ""
	Local cObsOrc		:= ""
	Local aParamBox		:= {}
	Local aRet			:= {}
	Local nMV			:= 0
	Local aMvPar		:= {}

	Private aMemos   	:= {{"VS1_OBSMEM","VS1_OBSERV"}}

	Default	cNroOrc		:= ""

	//Busca Proximo  número do Orçamento
	If FindFunction( "OX001PrxNro" )
		cNroOrc := OX001PrxNro()
	Else
		cNroOrc := GetSXENum("VS1","VS1_NUMORC")
		ConfirmSx8()
	Endif

	cQuery := "SELECT R_E_C_N_O_ RECNO "
	cQuery += "FROM " + RetSqlName("Z06") + " Z06 "
	cQuery += "WHERE "
	cQuery += "	   Z06_FILIAL = '" + xFilial("Z06") + "' "
	cQuery += "AND Z06_CODDTC = '" + cCodDTC + "' "
	cQuery += "AND Z06_MODVEI = '" + cModelo + "' "
	cQuery += "AND Z06.D_E_L_E_T_= ' ' "

	If	(nRegDTC := FM_SQL(cQuery)) == 0

		If	MsgYesNo('Não foi encontrado código DTC para este modelo. Deseja pesquisar por um código sem modelo informado?', 'Atenção!')

			cQuery := "SELECT R_E_C_N_O_ RECNO "
			cQuery += "FROM " + RetSqlName("Z06") + " Z06 "
			cQuery += "WHERE "
			cQuery += "	   Z06_FILIAL = '" + xFilial("Z06") + "' "
			cQuery += "AND Z06_CODDTC = '" + cCodDTC + "' "
			cQuery += "AND Z06.D_E_L_E_T_= ' ' "

			If	(nRegDTC := FM_SQL(cQuery)) == 0
				Help( ,, 'CS14AOR',, 'Não foi encontrado código DTC.', 1, 0 )
				Return ""
			EndIf

		Else

			Return ""

		EndIf

	EndIf

	dbSelectArea("Z06")
	Z06->(MsGoTo(nRegDTC))

	cCodMar := Z06->Z06_CODMAR

	cQuery := "SELECT Z08_TIPTEM, Z08_CODPEC, Z08_QTDPEC, SB1.R_E_C_N_O_ RECSB1 "
	cQuery += "FROM " + RetSqlName("Z08") + " Z08 "
	cQuery += "INNER JOIN " + RetSqlName("SB1") + " SB1 ON B1_FILIAL  = '" + xFilial("SB1") + "' AND B1_COD = Z08_CODPEC AND SB1.D_E_L_E_T_=' ' "
	cQuery += "INNER JOIN " + RetSqlName("VOI") + " VOI ON VOI_FILIAL = '" + xFilial("VOI") + "' AND VOI_TIPTEM = Z08_TIPTEM AND VOI.D_E_L_E_T_=' ' "
	cQuery += "WHERE "
	cQuery += "	   Z08_FILIAL = '" + xFilial("Z08")  + "' "
	cQuery += "AND Z08_CODIGO = '" + Z06->Z06_CODIGO + "' "
	cQuery += "AND Z08.D_E_L_E_T_= ' ' "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "TMPZ08"

	While !TMPZ08->(EOF())

		aAdd(aPecas, { TMPZ08->RECSB1,; //1
		TMPZ08->Z08_CODPEC,;  //2
		TMPZ08->Z08_QTDPEC,;  //3
		TMPZ08->Z08_TIPTEM }) //4

		TMPZ08->(dbSkip())

	EndDo

	If	SELECT("TMPZ08") > 0
		TMPZ08->(dbCloseArea())
	EndIf

	cQuery := "SELECT Z09_TIPTEM, Z09_TIPSER, Z09_GRUSER, Z09_CODSER, Z09_TEMPAD, VOK_INCMOB, VOK_PREKIL "
	cQuery += "FROM " + RetSqlName("Z09") + " Z09 "
	cQuery += "INNER JOIN " + RetSqlName("VOI") + " VOI ON VOI_FILIAL = '" + xFilial("VOI") + "' AND VOI_TIPTEM = Z09_TIPTEM AND VOI.D_E_L_E_T_=' ' "
	cQuery += "INNER JOIN " + RetSqlName("VOK") + " VOK ON VOK_FILIAL = '" + xFilial("VOK") + "' AND VOK_TIPSER = Z09_TIPSER AND VOK.D_E_L_E_T_=' ' "
	cQuery += "WHERE "
	cQuery += "	   Z09_FILIAL = '" + xFilial("Z09")  + "' "
	cQuery += "AND Z09_CODIGO = '" + Z06->Z06_CODIGO + "' "
	cQuery += "AND Z09.D_E_L_E_T_= ' ' "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "TMPZ09"

	While !TMPZ09->(EOF())

		aAdd(aSrvc, { TMPZ09->Z09_TIPTEM,; //1
		TMPZ09->Z09_TIPSER,; //2
		TMPZ09->Z09_GRUSER,; //3
		TMPZ09->Z09_CODSER,; //4
		TMPZ09->Z09_TEMPAD,; //5
		TMPZ09->VOK_INCMOB,; //6
		TMPZ09->VOK_PREKIL })//7

		TMPZ09->(dbSkip())

	EndDo

	If	SELECT("TMPZ09") > 0
		TMPZ09->(dbCloseArea())
	EndIf

	If 	Len(aPecas) > 0 .or. Len(aSrvc) > 0

		If 	Len(aPecas) > 0
			cTTPec := aPecas[1,4]
		EndIf

		If 	Len(aSrvc) > 0
			cTTSrv := aSrvc[1,1]
		EndIf

		If	!Empty(cTTPec) .and. Empty(cTTSrv)
			cTTSrv := Posicione("VOI", 1, xFilial("VOI") + cTTPec, "VOI_TTRELA")
		EndIf

		If	!Empty(cTTSrv) .and. Empty(cTTPec)
			cTTPec := Posicione("VOI", 1, xFilial("VOI") + cTTSrv, "VOI_TTRELA")
		EndIf

		cTESPad		:= Posicione("VOI", 1, xFilial("VOI") + cTTPec, "VOI_CODTES")
		cNatureza	:= Posicione("VOI", 1, xFilial("VOI") + cTTPec, "VOI_NATPEC")

		Begin Transaction

			dbSelectArea("SA1")
			SA1->(dbSetOrder(1))
			SA1->(MsSeek(xFilial("SA1") + Z01->Z01_CODCLI + Z01->Z01_LOJCLI))

			dbSelectArea("VV1")
			VV1->(dbSetOrder(1))
			VV1->(MsSeek(xFilial("VV1") + Z01->Z01_CHAINT))

			dbSelectArea("VS1")
			VS1->(dbSetOrder(1))

			RecLock("VS1",.t.)
			VS1->VS1_FILIAL := xFilial("VS1")
			VS1->VS1_NUMORC := cNroOrc
			VS1->VS1_TIPORC := "2" // Oficina
			VS1->VS1_DATORC := Date()
			VS1->VS1_DATVAL := Date()+30
			VS1->VS1_DATALT := Date()
			VS1->VS1_HORORC	:= CriaVar("VS1_HORORC")
			VS1->VS1_FORMUL := &cFormula
			VS1->VS1_CENCUS	:= VAI->VAI_CC
			VS1->VS1_CLIFAT := Z01->Z01_CODCLI
			VS1->VS1_LOJA   := Z01->Z01_LOJCLI
			VS1->VS1_NCLIFT := Z01->Z01_NOMCLI
			VS1->VS1_CHAINT	:= Z01->Z01_CHAINT
			//VS1->VS1_CHASSI	:= Z01->Z01_CHASSI
			VS1->VS1_CODMAR	:= Z06->Z06_CODMAR
			VS1->VS1_KILOME	:= Z01->Z01_HORIME
			VS1->VS1_TIPTEM := cTTPec
			VS1->VS1_TIPTSV := cTTSrv
			VS1->VS1_STATUS := "0"
			VS1->VS1_PEDSTA := "0"
			VS1->VS1_RESERV := "0"
			VS1->VS1_XVDPNE := "N"
			VS1->VS1_XVDSDZ := "N"
			VS1->VS1_TPATEN := "0"
			VS1->VS1_NATURE := ""
			VS1->VS1_CODVEN := VAI->VAI_CODVEN
			VS1->VS1_TIPVEN := VAI->VAI_TIPVEN
			VS1->VS1_RESFRE := "2"
			VS1->VS1_VLBRNF := "1"
			VS1->VS1_PGTFRE := "F"
			VS1->VS1_NATURE	:= Iif(!Empty(cNatureza), cNatureza, "10105")
			VS1->VS1_TIPCLI := SA1->A1_TIPO
			VS1->VS1_XATCSC := Z01->Z01_NUMATE

			cObsOrc := "Ordem de Serviço aberta a partir do Atendimento CSC (" + Z01->Z01_NUMATE + "). " + CRLF
			cObsOrc += "Problema relatado: " + Z01->Z01_PROBLE + CRLF
			If	!Empty(Z01->Z01_SOLUCA)
				cObsOrc += "Solução Sugerida CSC: " + Z01->Z01_SOLUCA
			EndIf

			MSMM(VS1->VS1_OBSMEM,TamSx3("VS1_OBSERV")[1],,cObsOrc,1,,,"VS1","VS1_OBSMEM")

			MsUnlock()

			If 	Len(aPecas) > 0

				dbSelectArea("VS3")
				VS3->(dbSetOrder(1))

				dbSelectArea("SB1")
				SB1->(dbSetOrder(1))

				dbSelectArea("SA1")
				SA1->(dbSetOrder(1))
				SA1->(MsSeek(xFilial("SA1") + Z01->Z01_CODCLI + Z01->Z01_LOJCLI))

				MaFisSave()
				MaFisEnd()

				MaFisIni(VS1->VS1_CLIFAT,VS1->VS1_LOJA,'C','N',IIF(!Empty(VS1->VS1_TIPCLI),VS1->VS1_TIPCLI,SA1->A1_TIPO), MaFisRelImp("OF110",{"VS1","VS3"} ))

				For nY := 1 To Len(aPecas)

					cSitTrib := ""

					SB1->(MsGoTo(aPecas[nY,1]))

					nQtdPec	:= Iif(aPecas[nY,3]>0,aPecas[nY,3],1)
					nVlrPec	:= FG_VALPEC(VS1->VS1_TIPTEM, cFormula, SB1->B1_GRUPO, SB1->B1_COD, Nil, .f., .t.)
					nTotPec	:= Round(nQtdPec * nVlrPec, 2)

					//Função padrão para buscar a TES de acordo com a operação.
					cCodTES	:= MaTesInt( 2, cOper, SA1->A1_COD, SA1->A1_LOJA, "C", SB1->B1_COD )

					If  Empty(cCodTES)
						cCodTES := cTESPad
					EndIf

					If !Empty(SB1->B1_ORIGEM) .and. !Empty(cCodTES)

						SF4->(dbSeek(xFilial("SF4")+cCodTES))

						If !Empty(SF4->F4_SITTRIB)

							cSitTrib := Left(SB1->B1_ORIGEM,1) + SF4->F4_SITTRIB

						EndIf

					EndIf

					RecLock("VS3",.t.)

					VS3->VS3_FILIAL := xFilial("VS3")
					VS3->VS3_NUMORC := cNroOrc
					VS3->VS3_SEQUEN := StrZero(nY, nTAMSEQ)
					VS3->VS3_CODSIT := "01"
					VS3->VS3_GRUITE := SB1->B1_GRUPO
					VS3->VS3_CODITE := SB1->B1_COD
					VS3->VS3_QTDINI := nQtdPec
					VS3->VS3_QTDITE := nQtdPec
					VS3->VS3_QESTNA := OX001SLDPC(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD)
					//VS3->VS3_QTDEST := VS3->VS3_QESTNA
					If	VS3->(FieldPos("VS3_OPER")) > 0
						VS3->VS3_OPER   := cOper
					EndIf
					VS3->VS3_CODTES	:= cCodTES
					VS3->VS3_SITTRI := cSitTrib
					VS3->VS3_LOCAL  := SB1->B1_LOCPAD
					VS3->VS3_FORMUL := &cFormula
					VS3->VS3_VALPEC := nVlrPec
					VS3->VS3_VALTOT := nTotPec
					VS3->VS3_CENCUS := VAI->VAI_CC
					VS3->VS3_CONTA  := SB1->B1_CONTA

					MsUnlock()

					aDadosCfo := {{"OPERNF", "S"},;
						{"TPCLIFOR",	SA1->A1_TIPO},;
						{"UFDEST"	,	SA1->A1_EST},;
						{"INSCR"	,	SA1->A1_INSCR}}

					cCfo := MaFisCfo(,POSICIONE("SF4",1,xFilial("SF4")+cCodTES,"F4_CF"), aDadosCfo )

					n := MaFisAdd(SB1->B1_COD,;			// 1-Codigo do Produto ( Obrigatorio )
					cCodTES,;						// 2-Codigo do TES ( Opcional )
					nQtdPec,;						// 3-Quantidade ( Obrigatorio )
					nVlrPec,;						// 4-Preco Unitario ( Obrigatorio )
					0,;								// 5-Valor do Desconto ( Opcional )
					Nil,;							// 6-Numero da NF Original ( Devolucao/Benef )
					Nil,;							// 7-Serie da NF Original ( Devolucao/Benef )
					0,;								// 8-RecNo da NF Original no arq SD1/SD2
					0,;								// 9-Valor do Frete do Item ( Opcional )
					0,;								// 10-Valor da Despesa do item ( Opcional )
					0,;								// 11-Valor do Seguro do item ( Opcional )
					0,;								// 12-Valor do Frete Autonomo ( Opcional )
					nTotPec,;						// 13-Valor da Mercadoria ( Obrigatorio )
					0,;     						// 14-Valor da Embalagem ( Opiconal )
					,;								// 15
					,;								// 16
					"",;							// 17
					0,;								// 18-Despesas nao tributadas - Portugal
					0,;								// 19-Tara - Portugal
					cCfo)								// 20-CFO


					RecLock("VS3",.F.)
					VS3->VS3_VALPIS := MaFisRet(n,"IT_VALPIS") + MaFisRet(n,"IT_VALPS2")
					VS3->VS3_VALCOF := MaFisRet(n,"IT_VALCOF") + MaFisRet(n,"IT_VALCF2")
					VS3->VS3_ICMCAL := MaFisRet(n,"IT_VALICM")
					VS3->VS3_PICMSB := MaFisRet(n,"IT_ALIQSOL")
					VS3->VS3_BICMSB := MaFisRet(n,"IT_BASESOL")
					VS3->VS3_VICMSB := MaFisRet(n,"IT_VALSOL")
					VS3->VS3_VALCMP := MaFisRet(n,"IT_VALCMP")
					VS3->VS3_DIFAL  := MaFisRet(n,"IT_DIFAL")
					MsUnLock()

					nTotOrc += nTotPec

				Next

				RecLock("VS1",.F.)

				VS1->VS1_VTOTNF := MaFisRet(,"NF_TOTAL") - MaFisRet(,"NF_DESCZF")
				VS1->VS1_ICMCAL := MaFisRet(,"NF_VALICM")
				VS1->VS1_VALDES := MaFisRet(,"NF_DESCONTO")
				VS1->VS1_VALIPI := MaFisRet(,"NF_VALIPI")

				If VS1->(FieldPos("VS1_VALCMP")) > 0
					VS1->VS1_VALCMP := MaFisRet(,"NF_VALCMP")
				Endif

				If VS1->(FieldPos("VS1_DIFAL")) > 0
					VS1->VS1_DIFAL := MaFisRet(,"NF_DIFAL")
				Endif

				MsunLock()

			EndIf

			If 	Len(aSrvc) > 0

				dbSelectArea("VS4")
				VS4->(dbSetOrder(1))

				For nY := 1 To Len(aSrvc)

					cTipSer := aSrvc[nY,2]
					cGruSer := aSrvc[nY,3]
					cCodSer := aSrvc[nY,4]
					nTemPad := aSrvc[nY,5]
					cCodSec	:= "OFI"
					nKilRod	:= 0
					nValSer	:= 0
					nTotSer	:= 0

					cMarVO6 := FG_MARSRV(cCodMar, cCodSer)

					nValHor	:= FMX_VALHOR(cTTSrv, DDATABASE, "0", 0, cCodMar, cCodSer, cTipSer, SA1->A1_COD, SA1->A1_LOJA, cCodMar ) //cTipTem , dDataRef , cVHRDIG , nVlrComp , cCodMar , cCodSrv , cTipSer , cCodCli , cLojCli , cPMarcaVO6

					If	aSrvc[nY,6] == "5" //se for KM

						nKilRod	:= aSrvc[nY,5]
						nValSer := Round( nKilRod * aSrvc[nY,7], 2 )
						nTotSer := Round( nKilRod * aSrvc[nY,7], 2 )

					Else

						nValSer := Round( (nTemPad/100) * nValHor, 2 )
						nTotSer := Round( (nTemPad/100) * nValHor, 2 )

					EndIf

					RecLock("VS4",.t.)

					VS4->VS4_FILIAL := xFilial("VS4")
					VS4->VS4_NUMORC := cNroOrc
					VS4->VS4_SEQUEN := StrZero(nY, nTAMSEQ)
					VS4->VS4_GRUSER := cGruSer
					VS4->VS4_CODSER := cCodSer
					VS4->VS4_TIPSER := cTipSer
					VS4->VS4_TEMPAD := nTemPad
					VS4->VS4_VALHOR := nValHor
					VS4->VS4_KILROD := nKilRod
					VS4->VS4_CODSEC := cCodSec
					VS4->VS4_VALSER := nValSer
					VS4->VS4_VALVEN := nTotSer
					VS4->VS4_VALTOT := nTotSer

					MsUnlock()

					nTotOrc += nTotSer

				Next

				RecLock("VS1",.F.)
				VS1->VS1_VTOTNF := nTotOrc
				VS1->VS1_VALDUP := nTotOrc
				MsUnLock()

			EndIf

		End Transaction

	EndIf

Return .t.

//-------------------------------------------------------------------
/*/{Protheus.doc} CS14OFI

Realiza a abertura de OS e requisição do serviço

@author Charlles Reis
@since  Agosto/2021
@version 1.0
/*/
//-------------------------------------------------------------------

Static FunCtion CS14AOS(cNumOS)

	Local cNewOS	:= ""
	Local aArea		:= GetArea()
	Local aAreaVO1	:= VO1->(GetArea())
	Local nKilomet  := 0
	Local cObsOsv	:= ""
	Local cLaudo    := ""
	//Local cTecFil   := GetMv("14_TECOFIO",.F.,"")
	//Local cTecCSC   := GetMv("14_TECCSCO",.F.,"")
	Local aPergs	:= {}
	Local aRet		:= {}
	Local cTec1		:= Space(6)
	Local cTec2		:= Space(6)
	Local cTec3		:= Space(6)


	dbSelectArea("VAI")
	VAI->(dbSetOrder(4)) // VAI_FILIAL+VAI_CODUSR
	If !VAI->(dbSeek(xFilial("VAI")+__cUserID))
		MsgStop("Usuário sem cadastro na tabela VAI.","Atenção!")
		Return .f.
	EndIf

	aAdd(aPergs,{1,"Técnico 1"			, cTec1		,"@!","","VAIAGE",".T.",100,.T.})
	aAdd(aPergs,{1,"Técnico 2"			, cTec2		,"@!","","VAIAGE",".T.",100,.F.})
	aAdd(aPergs,{1,"Técnico 3"			, cTec3		,"@!","","VAIAGE",".T.",100,.F.})

	If	!ParamBox( aPergs, "Informe os Técnicos e Auxiliares", @aRet,,,,,,,,.F.,.F. )
		Return .F.
	EndIf

	dbSelectArea("VV1")
	VV1->(dbSetOrder(1))
	VV1->(dbSeek(xFilial("VV1")+Z01->Z01_CHAINT))

	cObsOsv := "Ordem de Serviço aberta a partir do Atendimento CSC (" + Z01->Z01_NUMATE + "). " + CRLF
	cObsOsv += "Problema relatado: " + Z01->Z01_PROBLE

	cCodCli     := Z01->Z01_CODCLI
	cLojCli     := Z01->Z01_LOJCLI
	cTpOS       := "9"
	nKilomet    := Z01->Z01_HORIME
	cNumOS      := GetSXENum("VO1","VO1_NUMOSV")

	dbSelectArea("VO1")
	VO1->(dbSetOrder(1))
	While VO1->(dbSeek(xFilial("VO1") + cNumOS))

		ConfirmSx8()
		cNumOS      := GetSXENum("VO1","VO1_NUMOSV")

	EndDo

	RecLock("VO1",.T.)
	VO1->VO1_FILIAL := xFilial("VO1")
	VO1->VO1_NUMOSV := cNumOS
	VO1->VO1_TIPOS  := cTpOS
	VO1->VO1_TPATEN := "1"
	If	VO1->(FieldPos("VO1_XMAQPA")) > 0
		VO1->VO1_XMAQPA := Iif(Z01->Z01_MAQPAR == "S", "1", "0")
	EndIf
	VO1->VO1_DATENT := DaySum(DATE(),7)
	VO1->VO1_CODMAR := VV1->VV1_CODMAR
	VO1->VO1_CHASSI := VV1->VV1_CHASSI
	VO1->VO1_PLAVEI := VV1->VV1_PLAVEI
	VO1->VO1_CODFRO := VV1->VV1_CODFRO
	VO1->VO1_CHAINT := VV1->VV1_CHAINT

	If  VO1->(FieldPos("VO1_FABMOD")) > 0
		VO1->VO1_FABMOD := VV1->VV1_FABMOD
	Endif

	VO1->VO1_PROVEI := Z01->Z01_CODCLI
	VO1->VO1_LOJPRO := Z01->Z01_LOJCLI
	VO1->VO1_DATABE := DATE()
	VO1->VO1_KILOME := nKilomet
	VO1->VO1_HORABE := Val(Substr( Time(),1,2)+Substr( Time(),4,2))
	VO1->VO1_FUNABE := VAI->VAI_CODTEC
	VO1->VO1_XCODME := MV_PAR01
	VO1->VO1_XCODM1 := MV_PAR02
	VO1->VO1_XCODM2 := MV_PAR03
	VO1->VO1_STATUS := "A"
	VO1->VO1_FATPAR := cCodCli
	VO1->VO1_LOJA   := cLojCli
	VO1->VO1_XATCSC := Z01->Z01_NUMATE

	If !Empty(cObsOsv)
		MSMM(VO1->VO1_OBSMEM,TamSx3("VO1_OBSERV")[1],,cObsOsv,1,,,"VO1","VO1_OBSMEM")
	EndIf

	If  !Empty(Z01->Z01_PROCED)
		cLaudo += "Procedimento já executado anteriormente? => " + Z01->Z01_PROCED + CRLF
	Else
		cLaudo += "Procedimento já executado anteriormente? => NÃO." + CRLF
	EndIf

	If  !Empty(Z01->Z01_SOLUCA)
		cLaudo += "Solução/Diganóstico CSC? => " + Z01->Z01_SOLUCA + CRLF
	Else
		cLaudo += "Solução/Diganóstico CSC? => NÃO." + CRLF
	EndIf

	MsUnLock()

	cNewOS  := VO1->VO1_NUMOSV

	MsgInfo("OS Aberta: " + cNumOS)

	If  MsgYesNo("Deseja visualizar/complementar informações na OS?","Atenção")

		OM010I_A(Alias(), VO1->(RECNO()), 4)

	EndIf


	RestArea(aArea)
	RestArea(aAreaVO1)

Return .T.
