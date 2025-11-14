#Include 'Protheus.ch'
#Include "Totvs.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} TV02R01
Relatório de conferência de pedidos de compras

Uso: TV02R01

@author    	Charlles Reis
@version   	1.0
@since      05/2021
@history 	21/03/2024,fernandodasilva,#2024022665 | Incluido para colocar desconto no relatorio de compras
@history 	21/03/2024,fernandodasilva,#2024022665|#122,#165,#195  | Incluido para colocar desconto no relatorio de compras
/*/
//-------------------------------------------------------------------------------------

User Function TV02R01()

	Local aAreaAtu 		:= GetArea()
	Local oReport		:= Nil
	Local aParamBox	    := {}
	Local aRet		    := {}
	Local nTipo			:= 0

	AAdd(aParamBox,{1,"Filial"	, xFilial("SF2")	    ,"@!",'',"SM0",".T.",100,.T.})
	AAdd(aParamBox,{1,"Filial"	, xFilial("SF2")	    ,"@!",'',"SM0",".T.",100,.T.})
	AAdd(aParamBox,{1,"DT Ini."	, FirstDay(dDatabase)   ,"@D",'',"",".T.",100,.T.})
	AAdd(aParamBox,{1,"DT Fim"	, LastDay(dDatabase)    ,"@D",'',"",".T.",100,.T.})
	aAdd(aParamBox,{2,"Tipo Relatório"		, nTipo	, {"1=PCs Abertos", "2=PCs Fechados", "3=Ambos"}, 100, ".T.", .T.}) //9
	//AAdd(aParamBox,{1,"DT p/ LeadTime"	, dDatabase    ,"@D",'',"",".T.",100,.T.})

	if ParamBox( aParamBox, "Relatório de Pedidos de Compras", @aRet,,,,,,,,.f.,.f. )

		oReport := ReportDef()
		oReport:PrintDialog()

	endif

	RestArea( aAreaAtu )

Return( Nil )


//-------------------------------------------------------------------------------------
/*/{Protheus.doc} ReportDef

Uso: ReportDef

@author    	Charlles Reis
@version   	1.0
@since      14/05/2018
@history 	21/03/2024,fernandodasilva,#2024022665 |#75, |Incluido para colocar desconto no relatorio de compras
/*/
//-------------------------------------------------------------------------------------

Static Function ReportDef()

	Local oReport		:= Nil
	Local oSection1		:= Nil

	oReport := TReport():New("RELPCOMPRA", "Relatório de PCs", "" , {| oReport | PrintRep( oReport ) }, "Relatório de PCs")
	oReport:nEnvironment := 2
	oReport:nDevice	     := 4
	oReport:nFontBody    := 10

	oSection1 := TRSection():New( oReport, "Relatório de PCs" )

	TRCell():New( oSection1, "FILIAL",, "Filial"			,'@!'	,10 , , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "SOLICI",, "Solicitante" 	    ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)
	TRCell():New( oSection1, "NUMSOL",, "Nro. Solicitação"  ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)
	TRCell():New( oSection1, "COMPRA",, "Comprador"	        ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)
	TRCell():New( oSection1, "NUMPED",, "Nro. PC"	        ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)
	TRCell():New( oSection1, "TOTPED",, "Valor "  			,'@E 999,999,999.99'	,14	, , , "RIGHT"	, , "RIGHT" 	)
	TRCell():New( oSection1, "TOTDES",, "Valor Desconto"	,'@E 999,999,999.99'	,14	, , , "RIGHT"	, , "RIGHT" 	) //21/03/2024,fernandodasilva,#2024022665 | Incluido para colocar desconto no relatorio de compras
	TRCell():New( oSection1, "ALCADA",, "Alcada" 	    ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)
	TRCell():New( oSection1, "EMISSA",, "Data Emissão PC"   ,'@D'	,10 , , , "LEFT" 	, , "LEFT" 	)
	TRCell():New( oSection1, "GRUITE",, "Grupo de Produto"  ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)	
	TRCell():New( oSection1, "CONDPG",, "Cond. Pgto"       	,'@!'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "STAPED",, "Pedido Aprovado?"	,'@!'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTPAPR",, "L.T Pend. Aprov."	,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "APRON1",, "Data Aprov. Nv1"   ,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTAPN1",, "L.T Aprov. Nv1"	,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "APRON2",, "Data Aprov. Nv2"   ,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTAPN2",, "L.T Aprov. Nv2"	,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "APRON3",, "Data Aprov. Nv3"   ,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTAPN3",, "L.T Aprov. Nv3"	,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "RECENF",, "Data Receb. NF"    ,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "CLASNF",, "Data Class. NF"    ,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "NRONFI",, "Nro. NFiscal"    	,'@!'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTCLAS",, "L.T Classificação"	,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "DATVEN",, "Data do Vencto."  	,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "STAPRO",, "Processo"    		,'@!'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTPROC",, "L.T Processo"		,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "DATPAG",, "Data do Pgto."    	,'@D'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "LTPFIN",, "L.T Financeiro"	,'@E 999999'	,6	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "PFINAL",, "Processo Finalizado?"	,'@!'	,10	, , , "LEFT"	, , "LEFT" 	)
	TRCell():New( oSection1, "CODITE",, "Código do Produto" ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)
	TRCell():New( oSection1, "OBSERV",, "Descrição" 	    ,'@!'	,10	, , , "LEFT" 	, , "LEFT"	)	

	oReport:SetLandscape()

Return( oReport )

/*/-------------------------------------------------------------------------------------
	{Protheus.doc} PrintRep

	Uso: ReportDef

	@author    	Charlles Reis
	@version   	1.0
	@since      11/10/2017
	@history 	21/03/2024,fernandodasilva,#2024022665|#122,#165,#195  | Incluido para colocar desconto no relatorio de compras
//------------------------------------------------------------------------------------/*/

Static Function PrintRep( oReport )

	Local oS1  		:= oReport:Section(1)
	Local nFim		:= 0
	Local nAtual	:= 0
	Local nTotal	:= 0
	Local nDesc		:= 0 //21/03/2024,fernandodasilva,#2024022665| Incluido para colocar desconto no relatorio de compras
	Local cSC7	    := GetNextAlias()
	Local cFILTRO	:= ""
	Local cQuery	:= ""


	mv_par05 := Iif(ValType(mv_par05)=="N",cValToChar(mv_par05),mv_par05)

	If		mv_par05 == "1"
		cFILTRO := " AND C7_QUJE < C7_QUANT "
	ElseIf	mv_par05 == "2"
		cFILTRO := " AND C7_QUJE >= C7_QUANT "
	Else
		cFILTRO := ""
	EndIf

	BeginSQL Alias cSC7
        SELECT DISTINCT C7_FILIAL, C7_NUM FROM %TABLE:SC7% C7	
        WHERE
            C7_FILIAL BETWEEN %exp:mv_par01% AND %exp:mv_par02% AND
        C7_EMISSAO BETWEEN %exp:dtos(mv_par03)% AND %exp:dtos(mv_par04)% AND	
        C7.%NOTDEL%
	EndSQL
	Count To nFim

	(cSC7)->(dbGoTop())

	oS1:SetMeter(nFim)
	oS1:Init()

	While !(cSC7)->(EOF())

		If oReport:Cancel( )
			Return( Nil )
		EndIf

		nAtual++
		oReport:IncMeter()
		oReport:SetMsgPrint("Imprimindo relatório: " + cValToChar(nAtual) + " de " + cValToChar(nFim))

		cNomeSol 	:= ""
		cObserv		:= ""
		nTotal		:= 0
		nDesc		:= 0 //21/03/2024,fernandodasilva,#2024022665| Incluido para colocar desconto no relatorio de compras
		cQuery 		:= "SELECT COUNT(*) FROM " + RetSQLName("SC7") +;
			" WHERE C7_FILIAL = '" + (cSC7)->C7_FILIAL + "' AND C7_NUM = '" + (cSC7)->C7_NUM + "' AND C7_RESIDUO = '' AND D_E_L_E_T_=''"

		cQuery		+= cFILTRO

		If	(mv_par05 $ "1/2")
			If	FM_SQL(cQuery) == 0
				(cSC7)->(dbSkip())
				LOOP
			EndIf
		EndIf

		cGrupo 		:= ""
		cProd		:= ""
		lAprovado	:= .t.
		lParcial	:= .f.


		dbSelectArea("SC7")
		SC7->(dbSetOrder(1))
		SC7->(dbSeek( (cSC7)->C7_FILIAL + (cSC7)->C7_NUM ))
		While !SC7->(EOF()) .and. SC7->(C7_FILIAL+C7_NUM) == (cSC7)->C7_FILIAL + (cSC7)->C7_NUM

			If	lAprovado
				lAprovado := (SC7->C7_CONAPRO $ " ,L")
			EndIf

			cObserv += AllTrim(SC7->C7_DESCRI) + "-" + AllTrim(SC7->C7_OBS) + "/"
			nTotal 	+= SC7->C7_TOTAL
			nDesc	+= SC7->C7_VLDESC//21/03/2024,fernandodasilva,#2024022665| Incluido para colocar desconto no relatorio de compras

			dbSelectArea("SB1")
			SB1->(dbSetORder(1))
			SB1->(dbSeek(xFilial("SB1") + SC7->C7_PRODUTO ))

			If	!( SB1->B1_GRUPO $ cGrupo )
				cGrupo 	+= SB1->B1_GRUPO + "/"
			EndIf

			If	!( AllTrim(SC7->C7_PRODUTO) $ cProd )
				cProd	+= AllTrim(SC7->C7_PRODUTO) + "/"
			EndIf

			SC7->(dbSkip())

		EndDo

		If  !Empty(SC7->C7_NUMSC)

			dbSelectArea("SC1")
			SC1->(dbSetOrder(1))
			SC1->(dbSeek( SC7->C7_FILIAL + SC7->C7_NUMSC + SC7->C7_ITEMSC ))
			cNomeSol := SC1->C1_SOLICIT

		EndIf

		SC7->(dbSeek( (cSC7)->C7_FILIAL + (cSC7)->C7_NUM ))

		oS1:Cell("FILIAL"):SetValue( FWFilialName(,SC7->C7_FILIAL,1) )
		oS1:Cell("SOLICI"):SetValue( Upper(AllTrim(cNomeSol)) )
		oS1:Cell("NUMSOL"):SetValue( SC7->C7_NUMSC + "-" + SC7->C7_ITEMSC)
		oS1:Cell("COMPRA"):SetValue( Upper(UsrRetName(SC7->C7_USER)) )
		oS1:Cell("NUMPED"):SetValue( SC7->C7_NUM )
		oS1:Cell("EMISSA"):SetValue( SC7->C7_EMISSAO )
		oS1:Cell("GRUITE"):SetValue( cGrupo )
		oS1:Cell("CODITE"):SetValue( cProd )
		oS1:Cell("TOTPED"):SetValue( nTotal )
		oS1:Cell("TOTDES"):SetValue( nDesc )
		oS1:Cell("OBSERV"):SetValue( cObserv )

		If	nTotal <= 500
			oS1:Cell("ALCADA"):SetValue( "Até 500,00" )
		Else
			oS1:Cell("ALCADA"):SetValue( "Acima de 500,01" )
		EndIf

		cQuery  := "SELECT CR_DATALIB FROM " + RetSQLName("SCR") + " SCR "
		cQuery  += "WHERE "
		cQuery  += "CR_FILIAL = '" + (cSC7)->C7_FILIAL + "' AND "
		cQuery  += "CR_NUM = '" + (cSC7)->C7_NUM + "' AND "
		cQuery  += "CR_TIPO = 'PC' AND CR_NIVEL = '01' AND CR_DATALIB != '' AND "
		cQuery  += "SCR.D_E_L_E_T_='' "

		dApr_N1 := STOD(FM_SQL(cQuery))

		cQuery  := "SELECT CR_DATALIB FROM " + RetSQLName("SCR") + " SCR "
		cQuery  += "WHERE "
		cQuery  += "CR_FILIAL = '" + (cSC7)->C7_FILIAL + "' AND "
		cQuery  += "CR_NUM = '" + (cSC7)->C7_NUM + "' AND "
		cQuery  += "CR_TIPO = 'PC' AND CR_NIVEL = '02' AND CR_DATALIB != '' AND "
		cQuery  += "SCR.D_E_L_E_T_='' "

		dApr_N2 := STOD(FM_SQL(cQuery))

		cQuery  := "SELECT CR_DATALIB FROM " + RetSQLName("SCR") + " SCR "
		cQuery  += "WHERE "
		cQuery  += "CR_FILIAL = '" + (cSC7)->C7_FILIAL + "' AND "
		cQuery  += "CR_NUM = '" + (cSC7)->C7_NUM + "' AND "
		cQuery  += "CR_TIPO = 'PC' AND CR_NIVEL = '03' AND CR_DATALIB != '' AND "
		cQuery  += "SCR.D_E_L_E_T_='' "

		dApr_N3 := STOD(FM_SQL(cQuery))

		//Criar aqui um select que retorne todas as notas fiscais referentes ao pedido;
			//Informar número de todas as notas e datas de recebimento/lançamento;
			//Informar data do pagamento da nota fiscal;

		cQuery  := "SELECT TOP 1 F1_FILIAL, F1_FORNECE, F1_LOJA, F1_SERIE, F1_DOC, F1_STATUS, F1_DTDIGIT, F1_RECBMTO FROM " + RetSQLName("SD1") + " SD1 "
		cQuery  += "INNER JOIN " + RetSQLName("SF1") + " SF1 ON F1_FILIAL = D1_FILIAL AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE AND F1_FORNECE = D1_FORNECE AND F1_LOJA = D1_LOJA AND SF1.D_E_L_E_T_='' "
		cQuery  += "WHERE "
		cQuery  += "D1_FILIAL = '" + (cSC7)->C7_FILIAL + "' AND "
		cQuery  += "D1_PEDIDO = '" + (cSC7)->C7_NUM + "' AND "
		cQuery  += "D1_TES != '' AND "
		cQuery  += "SD1.D_E_L_E_T_='' "
		cQuery  += "ORDER BY SF1.R_E_C_N_O_ DESC "

		TCQuery cQuery Alias "TMP01" New

		nCnt := 0

		dBaixa_NF 	:= CTOD("")
		dReceb_NF 	:= CTOD("")
		dClass_NF 	:= CTOD("")
		dVenc_NF	:= CTOD("")
		cNroNf		:= ""
		lConcluido	:= .f.

		If TMP01->(!Eof())

			lConcluido	:= !Empty(F1_STATUS)
			cNroNf		:= TMP01->F1_DOC

			cQuery := "SELECT E2_BAIXA FROM SE2010 "
			cQuery += "WHERE "
			cQuery += "E2_FILIAL = '" + TMP01->F1_FILIAL + "' "
			cQuery += "AND E2_NUM = '" + TMP01->F1_DOC + "' "
			cQuery += "AND E2_PREFIXO = '" + TMP01->F1_SERIE + "' "
			cQuery += "AND E2_FORNECE = '" + TMP01->F1_FORNECE + "' "
			cQuery += "AND E2_LOJA = '" + TMP01->F1_LOJA + "' "
			//cQuery += "AND E2_SALDO>0 "
			cQuery += "AND D_E_L_E_T_='' "

			dBaixa_NF	:= STOD(FM_SQL(cQuery))

			cQuery := StrTran(cQuery,"E2_BAIXA","E2_VENCREA")

			dVenc_NF	:= STOD(FM_SQL(cQuery))

			dClass_NF 	:= STOD(TMP01->F1_DTDIGIT)
			dReceb_NF 	:= STOD(TMP01->F1_RECBMTO)

		EndIf

		If select("TMP01") > 0
			TMP01->(dbCloseArea())
		EndIf

		oS1:Cell("APRON1"):SetValue( dApr_N1 )

		If	!Empty(dApr_N1)
			oS1:Cell("LTAPN1"):SetValue( DateDiffDay(SC7->C7_EMISSAO, dApr_N1) )
		EndIf

		oS1:Cell("APRON2"):SetValue( dApr_N2 )
		If	!Empty(dApr_N2)
			oS1:Cell("LTAPN2"):SetValue( DateDiffDay(dApr_N1, dApr_N2) )
		EndIf

		oS1:Cell("APRON3"):SetValue( dApr_N3 )
		If	!Empty(dApr_N3)
			oS1:Cell("LTAPN3"):SetValue( DateDiffDay(dApr_N2, dApr_N3) )
		EndIf

		oS1:Cell("STAPED"):SetValue( Iif(lAprovado, "SIM", "NÃO") )

		oS1:Cell("RECENF"):SetValue( dReceb_NF )
		oS1:Cell("CLASNF"):SetValue( dClass_NF )
		oS1:Cell("LTCLAS"):SetValue( DateDiffDay(dReceb_NF, dClass_NF) )
		oS1:Cell("NRONFI"):SetValue( cNroNf )
		oS1:Cell("STAPRO"):SetValue( Iif(lConcluido, "Concluído", "Pendente") )
		oS1:Cell("DATVEN"):SetValue( dVenc_NF )
		oS1:Cell("DATPAG"):SetValue( dBaixa_NF )
		oS1:Cell("CONDPG"):SetValue( SC7->C7_COND + "/" + Posicione("SE4",1,xFilial("SE4") + SC7->C7_COND, "E4_DESCRI") )

		If	lAprovado
			If		!Empty(dApr_N3)
				oS1:Cell("LTPAPR"):SetValue( DateDiffDay( SC7->C7_EMISSAO, dApr_N3 ))
			ElseIf	!Empty(dApr_N2)
				oS1:Cell("LTPAPR"):SetValue( DateDiffDay( SC7->C7_EMISSAO, dApr_N2 ))
			ElseIf	!Empty(dApr_N1)
				oS1:Cell("LTPAPR"):SetValue( DateDiffDay( SC7->C7_EMISSAO, dApr_N1 ))
			EndIf
		Else
			oS1:Cell("LTPAPR"):SetValue( DateDiffDay( SC7->C7_EMISSAO, dDatabase ))
		EndIf

		If	!Empty(dClass_NF)
			oS1:Cell("LTPROC"):SetValue( DateDiffDay( SC7->C7_EMISSAO, dClass_NF ) )
		EndIf

		If	!Empty(dClass_NF) .and. !Empty(dBaixa_NF)
			oS1:Cell("LTPFIN"):SetValue( DateDiffDay( dClass_NF, dBaixa_NF ) )
			oS1:Cell("PFINAL"):SetValue( 'Concluído' )
		Else
			oS1:Cell("PFINAL"):SetValue( 'Pendente' )
		EndIf


		oS1:PrintLine()

		(cSC7)->(dbSkip())

	EndDo


	oS1:Finish( )
	(cSC7)->(DbCloseArea())

Return

