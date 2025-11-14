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

User Function TV_SIB03()
	Local _aCab1   := {}
	Local _aItens  := {}
	Local _aItem1  := {}
	Local aAutoImp := {}
	Local cQuery   := ''
	Local cChave := space(44)
	Local lOk    := .F.

	Private cOpera   := ''
	Private cCondi   := ''
	Private cNatur   := ''
	Private cString
	Private cTempo := ''

	Define MsDialog oDlg From 000,000 To 170,500 Title " Informe " Of oMainWnd Pixel
	@ 020,008 Say "Chave Nfe : "		Of oDlg Pixel
	@ 020,065 MsGet cChave             	Size 150,08  of oDlg Pixel
	Define SButton From 065,010	  Type 1 Action ( lOk := .t.,oDlg:End()) Enable Of oDlg
	Activate MsDialog oDlg Centered

	Dbselectarea("SF1")
	Dbsetorder(8)
	Dbseek( xFilial("SF1") + cChave, .F.)
	If .not. found()
		Msgstop('Chave nao encontrada')
		Return
	Endif
	//Altera data de digitação para não parar no bloqueio de data de calendario contabil
	SF1->( RecLock( "SF1", .F. ) )
			SF1->F1_DTDIGIT	:= dDataBase
	SF1->( MsUnlock() )

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
	aAdd(_aCab1, {"F1_EMISSAO"  , SF1->F1_EMISSAO	  , NIL})
	aAdd(_aCab1, {"F1_FORNECE"  , SF1->F1_FORNECE 	, NIL})
	aAdd(_aCab1, {"F1_LOJA"     , SF1->F1_LOJA	    , NIL})
	aAdd(_aCab1, {"F1_ESPECIE"  , "SPED"       	    , NIL})
	aAdd(_aCab1, {"F1_FILIAL"   , SF1->F1_FILIAL    , NIL})
	aAdd(_aCab1, {"VLDAMNFE"    , "N"               , Nil})
	aAdd(_aCab1, {"F1_CHVNFE"   , SF1->F1_CHVNFE   	, NIL})
	aAdd(_aCab1, {"F1_COND"     , cCondi            , NIL})
	aadd(_aCab1, {"E2_NATUREZ"  , cNatur            , NIL})
	aAdd(_aCab1, {"F1_XUSCLAS"  ,"SmartDocs"        , NIL})

	lMSHelpAuto := .T.
	lMSErroAuto := .F.
	MATA103(_aCab1,_aItens,4,.F.,aAutoImp)     // sem tela e com impostos


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
	oNotaxml := xmlparser(cString, "", @cError, @cWarning)
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
