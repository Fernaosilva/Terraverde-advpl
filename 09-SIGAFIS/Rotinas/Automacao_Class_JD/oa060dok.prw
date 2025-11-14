#INCLUDE "PROTHEUS.CH"
#INCLUDE "Totvs.ch"
#INCLUDE "topconn.ch"

//-------------------------------------------//
// Ponto de entrada que                      //
// classifica pre nota de transferencia      //
// e John Deere na conferencia               //
// browse mata103 (documento de entrada)     //
//-------------------------------------------//
// 06/10

User Function OA060DOK()
	Local aArea	  := GetArea()
	Local nRecSF1 := ParamIxb[2] // RecNo do registro da tabela de Nota Fiscal de Entrada (SF1)
	ClasDoc(nRecSF1)
	RestArea(aArea)

Return


//--------------------------------------//
// Classifica                           //
//--------------------------------------//
Static Function ClasDoc(nRecSF1)
	Local aFilSM0  := FWSM0Util():GetSM0Data( cEmpAnt , cFilAnt , {"M0_CGC"} )
	Local CnpjSMat := aFilSM0[1][2]

	Dbselectarea("SF1")
	Dbgotop()
	Dbgoto(nRecSF1)

	Dbselectarea("SA2")
	Dbsetorder(1)
	Dbseek( xFilial("SA2") + SF1->F1_FORNECE + SF1->F1_LOJA, .f.)

	// ALTERA F1_DTDIGIT PARA A DATA BASE PARA PULAR O BLOQUEIO CONTABIL
	If RecLock('SF1', .F.)
		SF1->F1_DTDIGIT:= DDATABASE
		MsUnlock()
	Endif

	If SF1->F1_FORNECE+SF1->F1_LOJA $ GETMV("TV_FORNCLA")
		IF (DTOS(SF1->F1_EMISSAO+30)) > DTOS(DDATABASE+7)
		//	ClassJD()
		ELSE
			//cContas := GETMV("TV_EMAILCL")
			//cTexto := 'Data de vencimento fora da regra financeira.'
			//GPEMail("Revisar e classificar a nota fiscal " + SF1->F1_DOC,cTexto,cContas)
			GPEMail("Erro na Classifica  o","Data de Vencimento fora da regra para NF: "+SF1->F1_DOC,"fernandodasilva@terraverdegrupo.com.br;silviamiake@terraverdegrupo.com.br")
		ENDIF
	Endif

	If Substr(SA2->A2_CGC,1,8) = Substr(CnpjSMat,1,8)
		ClassTr()
	Endif

	If Substr(SA2->A2_CGC,1,8) <> Substr(CnpjSMat,1,8)
		Return
	Endif



Return

//------------------------------------------//
// Classifica transferencia                 //
//------------------------------------------//
Static Function ClassTr()
	Local cQuery   := ''
	Local cChaveNf := ''

	Local cOpera   := GETMV("TV_OPERTRA",.F.,"02")
	Local cCondi   := '000'
	Local cNatur   := ''
	Local _aCab1   := {}
	Local _aItens  := {}
	Local _aItem1  := {}

	cChaveNf := ChvTrans()
	cQuery  := " SELECT * FROM " + RetSQLName('SD1')
	cQuery  += " WHERE D1_DOC     = '" + SF1->F1_DOC      + "'"
	cQuery  += " AND   D1_SERIE   = '" + SF1->F1_SERIE    + "'"
	cQuery  += " AND   D1_FORNECE = '" + SF1->F1_FORNECE  + "'"
	cQuery  += " AND   D1_LOJA    = '" + SF1->F1_LOJA     + "'"
	cQuery  += " AND   D1_FILIAL  = '" + SF1->F1_FILIAL   + "'"
	cQuery  += " AND   D_E_L_E_T_ = ' '"
	cQuery  += " ORDER BY D1_ITEM "

	DBUSEAREA(.T.,'TOPCONN', TCGenQry(,,cQuery),'TMPD1', .F., .T.)
	Dbselectarea("TMPD1")
	Dbgotop()

	Do while .not. eof()
		_aItem1 := {}
		aAdd(_aItem1, {"D1_ITEM"    , TMPD1->D1_ITEM    , NIL})
		aAdd(_aItem1, {"D1_COD"     , TMPD1->D1_COD     , NIL})
		aAdd(_aItem1, {"D1_UM"      , TMPD1->D1_UM 		, NIL})
		aAdd(_aItem1, {"D1_QUANT"   , TMPD1->D1_QUANT 	, NIL})
		aAdd(_aItem1, {"D1_VUNIT"   , TMPD1->D1_VUNIT   , NIL})
		aAdd(_aItem1, {"D1_TOTAL"   , TMPD1->D1_TOTAL   , NIL})
		aAdd(_aItem1, {"D1_OPER"    , cOpera    	    , NIL})
		aAdd(_aItem1, {"D1_LOCAL"   , TMPD1->D1_LOCAL 	, NIL})
		aAdd(_aItem1, {"LINPOS"     , "D1_ITEM",  TMPD1->D1_ITEM})
		aAdd( _aItens, AClone( _aItem1 ) )
		Dbskip()
		Loop
	Enddo

	Dbselectarea("TMPD1")
	Dbclosearea()

	Dbselectarea('SF1')

	aAdd(_aCab1, {"F1_TIPO"     , "N"                , NIL})
	aAdd(_aCab1, {"F1_FORMUL"   , "N"                , NIL})
	aAdd(_aCab1, {"F1_DOC"      , SF1->F1_DOC        , NIL})
	aAdd(_aCab1, {"F1_SERIE"    , SF1->F1_SERIE      , NIL})
	aAdd(_aCab1, {"F1_EMISSAO"  , SF1->F1_EMISSAO	 , NIL})
	aAdd(_aCab1, {"F1_FORNECE"  , SF1->F1_FORNECE 	 , NIL})
	aAdd(_aCab1, {"F1_LOJA"     , SF1->F1_LOJA	     , NIL})
	aAdd(_aCab1, {"F1_ESPECIE"  , "SPED"       	     , NIL})
	aAdd(_aCab1, {"F1_FILIAL"   , SF1->F1_FILIAL     , NIL})
	//VLDAMNFE indicando se deve ou n o fazer a valida  o da chave juntamente
	aAdd(_aCab1, {"F1_CHVNFE"   , cChaveNf      	 , NIL})
	aAdd(_aCab1, {"VLDAMNFE"    , "N"                , Nil})
	aAdd(_aCab1, {"F1_COND"     , cCondi             , NIL})
	aadd(_aCab1, {"E2_NATUREZ"  , cNatur             , NIL})
	//MUDA O USUARIO DA CLASSIFICA  O
	aAdd(_aCab1, {"F1_XUSCLAS"  ,"OFIA060", NIL})

	lMSHelpAuto := .T.
	lMSErroAuto := .F.
	MATA103(_aCab1,_aItens,4,.F.,)
	If lMsErroAuto
		mostraerro("\classAuto\",trim(SF1->F1_DOC)+trim(SF1->F1_SERIE)+"LogClassTr-"+StrTran(Time(), ":", "")+".txt")
		GPEMail("Erro na Classificacao","Erro na Classificacao NF Transf: "+SF1->F1_DOC,"fernandodasilva@terraverdegrupo.com.br")
	Else
		GPEMail("Nota Transf Classificada","Nota Fiscal "+SF1->F1_DOC+" Classificada","fernandodasilva@terraverdegrupo.com.br")
	Endif


Return

//-------------------------------------//
// Encontra a chave nfe                //
//-------------------------------------//
Static Function ChvTrans()
	Local cRet     := ''
	Local cQuery   := ''
	Local cFilTran := FilTrans()

	cQuery  := " SELECT F2_CHVNFE FROM " + RetSQLName('SF2')
	cQuery  += " WHERE F2_DOC     = '" + SF1->F1_DOC    + "'"
	cQuery  += " AND   F2_SERIE   = '" + SF1->F1_SERIE  + "'"
	cQuery  += " AND   F2_FILIAL  = '" + cFilTran       + "'"
	cQuery  += " AND   D_E_L_E_T_ = ' '"

	DBUSEAREA(.T.,'TOPCONN', TCGenQry(,,cQuery),'TMPF2', .F., .T.)
	Dbselectarea("TMPF2")
	Dbgotop()
	Do while .not. eof()
		cRet := TMPF2->F2_CHVNFE
		Dbskip()
		Loop
	Enddo

	Dbselectarea("TMPF2")
	Dbclosearea()

Return(cRet)


//--------------------------------//
// Filial da nota de origem       //
//--------------------------------//
Static Function FilTrans()
	Local cRet   := ''
	Local cQuery := ''
	cQuery  := "SELECT M0_CODFIL FROM SYS_COMPANY "
	cQuery  += " WHERE M0_CGC  = '" + SA2->A2_CGC + "' "
	cQuery  += " AND  D_E_L_E_T_ <> '*' "
	DBUSEAREA(.T.,'TOPCONN', TCGenQry(,,cQuery),'TMPFIL', .F., .T.)
	Dbselectarea("TMPFIL")
	Dbgotop()
	Do while .not. eof()
		cRet := TMPFIL->M0_CODFIL
		Dbskip()
		Loop
	Enddo
	Dbselectarea("TMPFIL")
	Dbclosearea()
Return(cRet)



//--------------------------------//
// Classifica NF John Deere       //
//--------------------------------//
Static Function ClassJD()
	Local _aCab1   := {}
	Local _aItens  := {}
	Local _aItem1  := {}
	Local aAutoImp := {}
	Local cQuery   := ''

	Private cOpera   := ''
	Private cCondi   := ''
	Private cNatur   := ''
	Private cString

	cQuery  := " SELECT * FROM " + RetSQLName('SD1')
	cQuery  += " WHERE D1_DOC     = '" + SF1->F1_DOC      + "'"
	cQuery  += " AND   D1_SERIE   = '" + SF1->F1_SERIE    + "'"
	cQuery  += " AND   D1_FORNECE = '" + SF1->F1_FORNECE  + "'"
	cQuery  += " AND   D1_LOJA    = '" + SF1->F1_LOJA     + "'"
	cQuery  += " AND   D1_FILIAL  = '" + SF1->F1_FILIAL   + "'"
	cQuery  += " AND   D_E_L_E_T_ = ' '"
	cQuery  += " ORDER BY D1_ITEM "

	DBUSEAREA(.T.,'TOPCONN', TCGenQry(,,cQuery),'TMPD1', .F., .T.)
	Dbselectarea("TMPD1")
	Dbgotop()
	Do while .not. eof()
		nItem := VAL(TMPD1->D1_ITEM)
		QueOper(SF1->F1_FILIAL,SF1->F1_FORNECE,SF1->F1_LOJA,TMPD1->D1_ITEM,TMPD1->D1_COD,SF1->F1_CHVNFE)
		_aItem1 := {}
		Dbselectarea("TMPD1")
		aAdd(_aItem1, {"D1_ITEM"    , TMPD1->D1_ITEM    , NIL})
		aAdd(_aItem1, {"D1_COD"     , TMPD1->D1_COD     , NIL})
		aAdd(_aItem1, {"D1_UM"      , TMPD1->D1_UM 		, NIL})
		aAdd(_aItem1, {"D1_QUANT"   , TMPD1->D1_QUANT 	, NIL})
		aAdd(_aItem1, {"D1_VUNIT"   , TMPD1->D1_VUNIT   , NIL})
		aAdd(_aItem1, {"D1_TOTAL"   , TMPD1->D1_TOTAL   , NIL})
		aAdd(_aItem1, {"D1_OPER"    , cOpera    	    , NIL})
		aAdd(_aItem1, {"D1_LOCAL"   , TMPD1->D1_LOCAL 	, NIL})

		aAdd(aAutoImp, {'IT_BASEIPI', TMPD1->D1_BASEIPI, nItem}) //Base IPI
		aAdd(aAutoImp, {'IT_VALIPI' , TMPD1->D1_VALIPI , nItem}) //Valor imposto

		aAdd(aAutoImp, {'IT_BASEICM', TMPD1->D1_BASEICM, nItem}) //Base ICMS
		aAdd(aAutoImp, {'IT_VALICM' , TMPD1->D1_VALICM,  nItem}) //Valor imposto

		aAdd(aAutoImp, {'IT_BASESOL', TMPD1->D1_BRICMS,  nItem}) //Base ST
		aAdd(aAutoImp, {'IT_VALSOL' , TMPD1->D1_ICMSRET, nItem}) //Valor imposto

		aAdd(aAutoImp, {'IT_BASEPS2', TMPD1->D1_BASIMP6, nItem}) //Base PIS
		aAdd(aAutoImp, {'IT_VALPS2' , TMPD1->D1_VALIMP6, nItem}) //Valor imposto

		aAdd(aAutoImp, {'IT_BASECF2', TMPD1->D1_BASIMP5, nItem}) //Base COFINS
		aAdd(aAutoImp, {'IT_VALCF2' , TMPD1->D1_VALIMP5, nItem}) //Valor imposto

		aAdd(_aItem1, {"LINPOS"     , "D1_ITEM",  TMPD1->D1_ITEM})
		aAdd( _aItens, AClone( _aItem1 ) )
		Dbskip()
		Loop
	Enddo

	Dbselectarea("TMPD1")
	Dbclosearea()

	Dbselectarea('SF1')

	aAdd(_aCab1, {"F1_TIPO"     , "N"               , NIL})
	aAdd(_aCab1, {"F1_FORMUL"   , "N"               , NIL})
	aAdd(_aCab1, {"F1_DOC"      , SF1->F1_DOC       , NIL})
	aAdd(_aCab1, {"F1_SERIE"    , SF1->F1_SERIE     , NIL})
	aAdd(_aCab1, {"F1_EMISSAO"  , SF1->F1_EMISSAO	, NIL})
	aAdd(_aCab1, {"F1_FORNECE"  , SF1->F1_FORNECE 	, NIL})
	aAdd(_aCab1, {"F1_LOJA"     , SF1->F1_LOJA	    , NIL})
	aAdd(_aCab1, {"F1_ESPECIE"  , "SPED"       	    , NIL})
	aAdd(_aCab1, {"F1_FILIAL"   , SF1->F1_FILIAL    , NIL})
	aAdd(_aCab1, {"F1_CHVNFE"   , SF1->F1_CHVNFE   	, NIL})
	aAdd(_aCab1, {"F1_COND"     , cCondi            , NIL})
	aadd(_aCab1, {"E2_NATUREZ"  , cNatur            , NIL})
	//aadd(_aCab1, {"E2_VENCTO"   , Dtoc(dDataBase+15), NIL})

	lMSHelpAuto := .T.
	lMSErroAuto := .F.
	MATA103(_aCab1,_aItens,4,.F.,aAutoImp)     // sem tela e com impostos

	If lMsErroAuto
		mostraerro("\classJD\","LogClassJD.txt")
		GPEMail("Erro na Classifica  o","Erro na Classificacao NF JD: "+SF1->F1_DOC,"fernandodasilva@terraverdegrupo.com.br;silviamiake@terraverdegrupo.com.br")
	Else
		GPEMail("Nota Classificada","Nota Fiscal "+SF1->F1_DOC+" Classificada","fernandodasilva@terraverdegrupo.com.br;silviamiake@terraverdegrupo.com.br")
	Endif


Return


//----------------------------------------//
// Busca a operacao, condicao e natureza  //
//----------------------------------------//
Static Function QueOper(F1FILIAL,F1FORNECE,F1LOJA,D1ITEM,D1COD,F1CHAVE)
	Local nX
	Local cToken   := 'rsr62QPwUDLIIP3Ko6UL9g24A'
	Local CnpjGrup := '09282594000145'
	Local cError   := ''
	Local cWarning := ''
	Local oNotaXml

	If D1ITEM = '0001'
		cString := u_SI_GetXML(Alltrim(F1CHAVE), CnpjGrup,cToken)
	Endif
	oNotaxml := xmlparser(cString, "_", @cError, @cWarning)
	oNfe  := WSAdvValue( oNotaxml,"_NFEPROC","string",NIL,NIL,NIL,NIL,NIL)
	oNF   := oNFe:_NFe
	oDet  := oNF:_InfNfe:_Det
	oDet  := IIf(ValType(oDet)=="O",{oDet},oDet)
	nX    := Val(D1ITEM)
	cCod  := oDet[nX]:_Prod:_cProd:TEXT
	cCfop := oDet[nX]:_Prod:_CFOP:TEXT

	cQuery := "SELECT * FROM " + RetSQLName('Z12')
	cQuery  += " WHERE Z12_FILIAL = '" + xFilial('Z12')  + "'"
	cQuery  += " AND   Z12_CODFOR = '" + F1FORNECE  + "'"
	cQuery  += " AND   Z12_LOJA   = '" + F1LOJA     + "'"
	cQuery  += " AND   Z12_CFOPXM = '" + cCfop      + "'"
	cQuery  += " AND   D_E_L_E_T_ = ' '"
	cQuery := ChangeQuery(cQuery)

	//MemoWrite('c:\temp\sqlz12.txt',cQuery)

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPR",.T.,.T.)
	DbSelectArea('TMPR')
	DbGoTop()
	nnRec := 0
	Do while .not. eof()
		cOpera   := TMPR->Z12_OPERAC
		cCondi   := TMPR->Z12_CONDPA
		cNatur   := TMPR->Z12_NATURE
		Dbskip()
		Loop
	Enddo
	DbSelectArea('TMPR')
	Dbclosearea()

	FreeObj(oNotaxml)
	FreeObj(oNfe)
	FreeObj(oNF)
	FreeObj(oDet)

Return
