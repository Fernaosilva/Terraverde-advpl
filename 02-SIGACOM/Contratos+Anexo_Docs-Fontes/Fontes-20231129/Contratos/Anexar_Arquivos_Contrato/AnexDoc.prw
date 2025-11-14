#Include "Protheus.ch"
#Include 'Topconn.ch'

/*/{Protheus.doc} AnexDoc
Funcao para executar a classe de Anexar documentos
@type function
@version 1.0
@author Geeker Company (Johny) / AJUSTES EFETUADOS POR: PATINI
@since 14/09/2023
@param cTipo, character, Tipo da rotina: CT|SC|PC|NFE
@link https://gkcmp.com.br (Geeker Company)
@history 06/11/2023, Ademar Fernandes Jr., Implementado tratamento generico, por CT, por NFE, etc.
@return variant, Nil
/*/
User Function AnexDoc(cTipo)
	local oDocViewer as OBJECT
	local aLjArea   := Lj7GetArea({"SF1","SD1","SE2","CND","CNE","CN9"})
	local cTitulo   := ""
	local cChave    := ""
	local cCompet   := ""

	local cDocCpo   := ""
	local cIniDtCpo := ""
	local cFimDtCpo := ""
	local cF3Doc    := ""
	local cQ1Alias  := ""
	local cMedicao  := ""
	local cContrato := ""
	local cFornece  := ""
	local cLoja     := ""
	local cSeekCND  := ""
	local cRevisa   := ""
	local lNvaMed   := .f.

	local lAnexMsg  := SuperGetMv('ZZ_ANEXMSG',.F.,.T.)    //-Habilita a apresentaçao de "Mensagem Informativa de Caracteres Especiais"
	local cMsgAnex  := ""

	local lFnsFIN   := FwIsInCallStack("FINA750") .Or.;	//-Funçoes do CP
						FwIsInCallStack("FINA080") .Or.;//-Baixas a Pagar Manual
						FwIsInCallStack("FINA290")		//-Faturas a Pagar (manual)
	local lFnsCOM   := FwIsInCallStack("MATA140") .Or.;	//-Pre-Nota
						FwIsInCallStack("MATA103")		//-Doc.de Entrada
	// local lFnsCNT   := FwIsInCallStack("CNTA300") .Or.;	//-Manutençao de Contratos
	// 					FwIsInCallStack("CNTA121")		//-Mediçao de Contratos
	local cNomEmp   := "["+Capital(Substr(SM0->M0_NOMECOM,1,AT(" ",SM0->M0_NOMECOM)-1))+"] "

	default cTipo := "CT"

	oDocViewer:= DocViewer():new()

	if lFnsCOM
		cMedicao := getQrySC7(1)	//-Tabela SF1 Posicionada		
	elseif lFnsFIN
		cMedicao := getQrySC7(2)	//-Tabela SE2 Posicionada
	endif

	if !Empty(cMedicao)
		cTipo := "CT"
	endif

	if lFnsCOM
		cQ1Alias := getQryNFE(1)	//-Tabela SF1 Posicionada
	elseif lFnsFIN
		cQ1Alias := getQryNFE(2)	//-Tabela SE2 Posicionada
	endif
/*
	if cTipo == "SC"
		cTitulo   := OemToAnsi("Anexos da Solicitação de Compras")
		cChave    := "MATA410|"+CA110NUM	//-cA110Num := SC1->C1_NUM => Verificar qual a melhor chave a ser enviada !!!

	elseif cTipo == "CT"
*/
	if cTipo == "CT"
		cTitulo   := OemToAnsi("Anexos do Contrato")
		if FwIsInCallStack("CNTA121") //se for nova medição e for uma visualização ja pega o registro posicionado 
		    if !empty(CND->CND_COMPET)
		   		cCompet := SUBSTR(CND->CND_COMPET,1,2)+SUBSTR(CND->CND_COMPET,4,7)	
            endif
		else
			cCompet   := Right(AnoMes(Date()),2) +Left(AnoMes(Date()),4)
        endif
		
		if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
			cMedicao := (cQ1Alias)->C7_MEDICAO
			cContrato:= getQryCont(1)   //pegando o contrato
			cFornece := SF1->F1_FORNECE
			cLoja    := SF1->F1_LOJA
	
		elseif FwIsInCallStack("CNTA300") 	//-Manutençao de Contratos 
			cSeekCND := CN9->(CN9_NUMERO+CN9_REVISA)
			
			if Empty(cMedicao)
				//-CND_FILIAL+CND_CONTRA+CND_REVISA+CND_COMPET
				cMedicao := getQryCND(cSeekCND,cCompet)
			endif
        elseif FwIsInCallStack("CNTA121")  //- nova medição
		    cFili    := CND->CND_FILIAL
			cMedicao := CND->CND_NUMMED
			cContrato:= CND->CND_CONTRA
			cRevisa  := CND->CND_REVISA
			lNvaMed  := .t.
		endif
        
		//Patini:posicionando direto na (CND ) gera problemas
		//       reposicionei usando CND/CNC
        if !lNvaMed
			cQcnd := " SELECT CND_FILIAL "
			cQcnd += "       ,CND_NUMMED " 
			cQcnd += "       ,CND_NUMERO "
        	cQcnd += "       ,CND_CONTRA " 
        	cQcnd += "       ,CNC_CODIGO " 
        	cQcnd += "       ,CNC_LOJA " 
        	cQcnd += "       ,CND_REVISA " 
        	cQcnd += "       ,CND_COMPET " 
        	cQcnd += "       ,CND_DTINIC " 
        	cQcnd += "       ,CND_DTFIM " 
        	cQcnd += " FROM "+RetSqlName('CND') + " CND (NOLOCK) "
			cQcnd += " JOIN "+RetSqlName('CNC') + " CNC  ON CNC_FILIAL = CND_FILIAL AND CNC_NUMERO = CND_CONTRA AND CND_REVISA = CNC_REVISA AND CNC.D_E_L_E_T_=' ' "
			cQcnd += " WHERE CND_FILIAL= '"+Fwxfilial('CND')+"'"
			cQcnd += " 	AND CND_NUMMED = '"+cMedicao+"'"
			cQcnd += " 	AND CND_CONTRA = '"+cContrato+"'"
			cQcnd += " 	AND CNC_CODIGO = '"+cFornece+"'"
			cQcnd += " 	AND CNC_LOJA = '"+cLoja+"'"
			cQcnd += " ORDER BY CND_REVISA DESC "
				if select('TCND') > 0
					TCND->(dbCloseArea())
				endif
        	TCQUERY cQcnd ALIAS TCND NEW
        	TCSetField("TCND", "CND_DTINIC"  , "D")
        	TCSetField("TCND", "CND_DTFIM"  , "D")
	
			//Patini: Reposicionando o CND
        	DbSelectArea("TCND")
			TCND->(DBGOTOP(  ))
			dbSelectArea('CND')
			CND->(dbSetOrder(1))
			if CND->(dbSeek(TCND->CND_FILIAL+TCND->CND_CONTRA+TCND->CND_REVISA+TCND->CND_NUMERO+TCND->CND_NUMMED))
				//	cRevisa := getQryCND1(CND->CND_CONTRA,CND->CND_NUMMED,CND->CND_FORNEC,CND->CND_LJFORN)
				cChave := TCND->CND_FILIAL +'|'+TCND->CND_CONTRA +'|'+TCND->CND_REVISA+'|'+cCompet
			else
				dbSetOrder(1)	//-CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED
				if !Empty(cSeekCND) .And. dbSeek(FwxFilial("CND")+cSeekCND,.F.)
					cChave := CND->CND_FILIAL +'|'+CND->CND_CONTRA +'|'+CND->CND_REVISA+'|'+cCompet
				endif
			endif
			cDocCpo   := "CND->CND_CONTRA"
			cIniDtCpo := "CND->CND_DTINIC"
			cFimDtCpo := "CND->CND_DTFIM"
			cF3Doc    := "CND"
        	/* Patini: comentado para que exiba no CONTRATO os botoes.
			lAnexMsg := .F.
			oDocViewer:lInclui  := .F.
			oDocViewer:lAltera  := .F.
			oDocViewer:lExcluir := .F.
			oDocViewer:lPodeDEL := .F.
			oDocViewer:lVldCria := .F.
			oDocViewer:lModify  := .F.
        	*/
			if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
				(cQ1Alias)->(dbCloseArea())
			endif
        else 
			cChave:= cFili +'|'+cContrato +'|'+cRevisa+'|'+cCompet
			cDocCpo   := "CND->CND_CONTRA"
			cIniDtCpo := "CND->CND_DTINIC"
			cFimDtCpo := "CND->CND_DTFIM"
			cF3Doc    := "CND"
        endif
	elseif cTipo == "NFE"
		cTitulo   := OemToAnsi("Anexos de NF Entrada")
		cCompet   := ""

		if lFnsCOM
			//(1) D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
			cChave    := SF1->F1_FILIAL+ '|' +SF1->F1_DOC+ '|' +SF1->F1_SERIE+ '|' +SF1->F1_FORNECE+ '|' +SF1->F1_LOJA
			cDocCpo   := "SF1->F1_DOC"
			cF3Doc    := "SF1"

		elseif lFnsFIN
			//(6) E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
			cChave    := SE2->E2_FILIAL+ '|' +SE2->E2_NUM+ '|' +SE2->E2_PREFIXO+ '|' +SE2->E2_FORNECE+ '|' +SE2->E2_LOJA
			cDocCpo   := "SE2->E2_NUM"
			cF3Doc    := "SE2"

			lAnexMsg := .F.
			oDocViewer:lInclui  := .F.
			oDocViewer:lAltera  := .F.
			oDocViewer:lExcluir := .F.
			oDocViewer:lPodeDEL := .F.
			oDocViewer:lVldCria := .F.
			oDocViewer:lModify  := .F.
		endif
	else
		cChave    := CN9->CN9_FILIAL+ '|' +CN9->CN9_NUMERO+ '|' +CN9->CN9_REVISA
		cDocCpo   := "CN9->CN9_NUMERO"
		cIniDtCpo := "CN9->CN9_DTINIC"
		cFimDtCpo := "CN9->CN9_DTFIM"
		cF3Doc    := "CN9"
	endif

	if lAnexMsg
		cMsgAnex += OemToAnsi("Não são permitidos caracteres especiais no nome de arquivos, e se possível não deixe espaços também. ")
		cMsgAnex += OemToAnsi("Se existir, por favor, antes de anexar, renomeie o arquivo utilizando apenas letras, números e underline ( _ ).")
		MsgInfo(cMsgAnex, OemToAnsi(cNomEmp+"Atenção!"))
	endif

	//-Sintaxe Start(cTipo,cChave,cTitulo,nLimite, cCompet,cDocCpo,cIniDtCpo,cFimDtCpo,cF3Doc) Class DocViewer
	oDocViewer:Start(cTipo,cChave,cTitulo,, cCompet,cDocCpo,cIniDtCpo,cFimDtCpo)

	Lj7RestArea(aLjArea)

Return Nil

/*/{Protheus.doc} getQryNFE
Busca os dados da NF Entrada posicionada
@type function
@version 1.0
@author Ademar Fernandes Jr.
@since 10/11/2023
@return variant, Alias com o resultado da Query
/*/
Static function getQryNFE(nMyOpc)
    local nTReg1   := 0
	local cQuery1  := ""
	local cQ1Alias := ""
	default nMyOpc := 1

	cQuery1 += " SELECT DISTINCT "
	cQuery1 += " F1_FILIAL,F1_DOC,F1_SERIE, "
	cQuery1 += " D1_PEDIDO,D1_FORNECE,D1_LOJA, "
	cQuery1 += " C7_FORNECE,C7_LOJA,C7_NUM,C7_MEDICAO "
	cQuery1 += " FROM "+RetSqlName("SF1")+" SF1 "
	cQuery1 += " INNER JOIN "+RetSqlName("SD1")+" SD1 "
	cQuery1 += " 	ON SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = F1_FILIAL " 
	cQuery1 += " 	AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE "
	cQuery1 += " 	AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
	cQuery1 += " INNER JOIN "+RetSqlName("SC7")+" SC7 "
	cQuery1 += " 	ON SC7.D_E_L_E_T_ = ' ' AND C7_FILIAL = '"+FwxFilial("SC7")+"' "
	cQuery1 += " 	AND C7_FORNECE = F1_FORNECE AND C7_LOJA = F1_LOJA "
	cQuery1 += " 	AND C7_NUM = D1_PEDIDO AND C7_MEDICAO > '' "
	cQuery1 += " WHERE SF1.D_E_L_E_T_ = ' ' "
	cQuery1 += "	AND F1_FILIAL = '"+FwxFilial("SF1")+"' "
	if nMyOpc == 1		//-Tabela SF1 Posicionada
		cQuery1 += "	AND F1_DOC    = '"+SF1->F1_DOC+"' "
		cQuery1 += "	AND F1_SERIE  = '"+SF1->F1_SERIE+"' "
		cQuery1 += "    AND F1_FORNECE= '"+SF1->F1_FORNECE+"'"
		cQuery1 += "    AND F1_LOJA   = '"+SF1->F1_LOJA+"'"
		cQuery1 += "	AND F1_TIPO   = '"+SF1->F1_TIPO+"' "
	elseif nMyOpc == 2	//-Tabela SE2 Posicionada
		cQuery1 += "	AND F1_DOC    = '"+SE2->E2_NUM+"' "
		cQuery1 += "	AND F1_SERIE  = '"+SE2->E2_PREFIXO+"' "
	endif
	//-F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO                                                                                                            
	cQuery1 += " ORDER BY F1_FILIAL,F1_DOC,F1_SERIE "

	cQuery1 := ChangeQuery(cQuery1)

	cQ1Alias := GetNextAlias()
	if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
		(cQ1Alias)->(dbCloseArea())
	endif
	TcQuery cQuery1 New Alias (cQ1Alias)

	COUNT to nTReg1
	(cQ1Alias)->(dbGoTop())

Return cQ1Alias

/*/{Protheus.doc} getQrySC7
Busca se existe Mediçao nos dados da SC
@type function
@version 1.0
@author Ademar Fernandes Jr.
@since 14/11/2023
@return variant, Codigo da Mediçao existente na SC7
/*/
Static function getQrySC7(nMyOpc)
    local nTReg1   := 0
	local cQuery1  := ""
	local cQ1Alias := ""
	local cRetorno := ""
	default nMyOpc := 1

	cQuery1 += " SELECT DISTINCT "
	cQuery1 += " C7_MEDICAO "
	cQuery1 += " FROM "+RetSqlName("SF1")+" SF1 "
	cQuery1 += " INNER JOIN "+RetSqlName("SD1")+" SD1 "
	cQuery1 += " 	ON SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = F1_FILIAL " 
	cQuery1 += " 	AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE "
	cQuery1 += " 	AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
	cQuery1 += " INNER JOIN "+RetSqlName("SC7")+" SC7 "
	cQuery1 += " 	ON SC7.D_E_L_E_T_ = ' ' AND C7_FILIAL = '"+FwxFilial("SC7")+"' "
	cQuery1 += " 	AND C7_FORNECE = F1_FORNECE AND C7_LOJA = F1_LOJA "
	cQuery1 += " 	AND C7_NUM = D1_PEDIDO AND C7_MEDICAO > '' "
	cQuery1 += " WHERE SF1.D_E_L_E_T_ = ' ' "
	cQuery1 += "	AND F1_FILIAL = '"+FwxFilial("SF1")+"' "
	if nMyOpc == 1		//-Tabela SF1 Posicionada
		cQuery1 += "	AND F1_DOC      = '"+SF1->F1_DOC+"' "
		cQuery1 += "	AND F1_SERIE    = '"+SF1->F1_SERIE+"' "
		cQuery1 += "	AND F1_FORNECE  = '"+SF1->F1_FORNECE+"' "
		cQuery1 += "	AND F1_LOJA     = '"+SF1->F1_LOJA+"' "
		cQuery1 += "	AND F1_TIPO     = '"+SF1->F1_TIPO+"' "
		
	elseif nMyOpc == 2	//-Tabela SE2 Posicionada
		cQuery1 += "	AND F1_DOC    = '"+SE2->E2_NUM+"' "
		cQuery1 += "	AND F1_SERIE  = '"+SE2->E2_PREFIXO+"' "
	endif

	cQuery1 := ChangeQuery(cQuery1)

	cQ1Alias := GetNextAlias()
	if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
		(cQ1Alias)->(dbCloseArea())
	endif
	TcQuery cQuery1 New Alias (cQ1Alias)

	COUNT to nTReg1
	(cQ1Alias)->(dbGoTop())

	if nTReg1 > 0
		cRetorno := C7_MEDICAO
	endif

	if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
		(cQ1Alias)->(dbCloseArea())
	endif

Return cRetorno

/*/{Protheus.doc} getQryCND
Busca se existe Mediçao nos dados da CND
@type function
@version 1.0
@author Ademar Fernandes Jr.
@since 28/11/2023
@return variant, Codigo da Mediçao existente na CND
/*/
Static function getQryCND(cSeekCND,cCompet)
    local nTReg1   := 0
	local cQuery1  := ""
	local cQ1Alias := ""
	local cRetorno := ""
	default nMyOpc := 1

	cQuery1 += " SELECT DISTINCT "
	cQuery1 += " CND_NUMMED "
	cQuery1 += " FROM "+RetSqlName("CND")+" CND "
	cQuery1 += " WHERE CND.D_E_L_E_T_ = ' ' "
	cQuery1 += "	AND CND_FILIAL = '"+FwxFilial("CND")+"' "
	cQuery1 += "	AND CND_CONTRA+CND_REVISA = '"+cSeekCND+"' "
	cQuery1 += "	AND CND_COMPET = '"+cCompet+"' "

	cQuery1 := ChangeQuery(cQuery1)

	cQ1Alias := GetNextAlias()
	if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
		(cQ1Alias)->(dbCloseArea())
	endif
	TcQuery cQuery1 New Alias (cQ1Alias)

	COUNT to nTReg1
	(cQ1Alias)->(dbGoTop())

	if nTReg1 > 0
		cRetorno := CND_NUMMED
	endif

	if !Empty(cQ1Alias) .And. Select(cQ1Alias) > 0
		(cQ1Alias)->(dbCloseArea())
	endif

Return cRetorno

/*/{Protheus.doc} getQryNFE
Busca os dados da NF Entrada posicionada
@type function
@version 1.0
@author PATiNI
@since 07/24
@return variant, Alias com o resultado da Query
/*/
Static function getQryCont(nMyOpc)
    local nTReg1   := 0
	local cQuery1  := ""
	local cAliasC7 := ""
	local cRetorno := ""
	default nMyOpc := 1

	cQuery1 += " SELECT DISTINCT "
	cQuery1 += " C7_CONTRA "
	cQuery1 += " FROM "+RetSqlName("SF1")+" SF1 "
	cQuery1 += " INNER JOIN "+RetSqlName("SD1")+" SD1 "
	cQuery1 += " 	ON SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = F1_FILIAL " 
	cQuery1 += " 	AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE "
	cQuery1 += " 	AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
	cQuery1 += " INNER JOIN "+RetSqlName("SC7")+" SC7 "
	cQuery1 += " 	ON SC7.D_E_L_E_T_ = ' ' AND C7_FILIAL = '"+FwxFilial("SC7")+"' "
	cQuery1 += " 	AND C7_FORNECE = F1_FORNECE AND C7_LOJA = F1_LOJA "
	cQuery1 += " 	AND C7_NUM = D1_PEDIDO AND C7_MEDICAO > '' "
	cQuery1 += " WHERE SF1.D_E_L_E_T_ = ' ' "
	cQuery1 += "	AND F1_FILIAL = '"+FwxFilial("SF1")+"' "
	if nMyOpc == 1		//-Tabela SF1 Posicionada
		cQuery1 += "	AND F1_DOC      = '"+SF1->F1_DOC+"' "
		cQuery1 += "	AND F1_SERIE    = '"+SF1->F1_SERIE+"' "
		cQuery1 += "	AND F1_FORNECE  = '"+SF1->F1_FORNECE+"' "
		cQuery1 += "	AND F1_LOJA     = '"+SF1->F1_LOJA+"' "
		cQuery1 += "	AND F1_TIPO     = '"+SF1->F1_TIPO+"' "
	endif

	cQuery1 := ChangeQuery(cQuery1)

	cAliasC7 := GetNextAlias()
	if !Empty(cAliasC7) .And. Select(cAliasC7) > 0
		(cAliasC7)->(dbCloseArea())
	endif
	TcQuery cQuery1 New Alias (cAliasC7)

	COUNT to nTReg1
	(cAliasC7)->(dbGoTop())

	if nTReg1 > 0
		cRetorno := C7_CONTRA
	endif

	if !Empty(cAliasC7) .And. Select(cAliasC7) > 0
		(cAliasC7)->(dbCloseArea())
	endif

Return cRetorno
