#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#include "ap5mail.ch"

#INCLUDE "TBICONN.CH"
#INCLUDE "TBICODE.CH"

//---------------------------------------//
// Schedule de classificacao de notas JD //
//---------------------------------------//


User Function TV_SIB04()
	Local _aCab1   := {}
	Local _aItens  := {}
	Local _aItem1  := {}
	Local aAutoImp := {}
	Local cQuery   := ''
	Local cChave   := ''
	Local lOk      := .F.
	Local lContinua := .T.

	Private cOpera   := ''
	Private cCondi   := ''
	Private cNatur   := ''
	Private cString

	Private nBasPis := 0
	Private nBasCof := 0
	Private nValPis := 0
	Private nValCof := 0

	PREPARE ENVIRONMENT EMPRESA '01' FILIAL '0101'

	// criar campo na sf1 de flag que ja validou
	// pra nao rodar a segunda vez
	Do While lContinua == .T.
		cQuery  := " SELECT TOP 1 F1_FILIAL,F1_DOC,F1_SERIE,"
		cQuery	+= " F1_FORNECE,F1_LOJA,F1_CHVNFE FROM " + RetSQLName('SF1') + " SF1"
		cQuery	+= " INNER JOIN " + RetSQLName('VM0') + " VM0 ON"
		cQuery	+= " 	VM0_DOC=F1_DOC AND VM0_SERIE=F1_SERIE AND VM0_FILIAL=F1_FILIAL AND VM0_STATUS='4' AND VM0.D_E_L_E_T_='' "
		cQuery  += " WHERE F1_FORNECE = '674782' "
		cQuery  += " AND   F1_LOJA    = '0013' "
		//cQuery  += " AND   F1_FILIAL  = '0103' " //REMOVER TESTE ASSISTIDO
		cQuery  += " AND   F1_STATUS  = '' "
		cQuery  += " AND   F1_EMISSAO >= '20250901' "
		cQuery  += " AND   F1_XSTVLD <> 'S' "
		cQuery  += " AND   SF1.D_E_L_E_T_ = ' '"
		cQuery  += " ORDER BY F1_XALERTA DESC, SF1.R_E_C_N_O_ "

		DBUSEAREA(.T.,'TOPCONN', TCGenQry(,,cQuery),'TMPSF1', .F., .T.)
		Dbselectarea("TMPSF1")
		Dbgotop()


		Do while .not. eof()
			cChave := ''
			Dbselectarea('VM0')
			Dbsetorder(3) // VM0_FILIAL+VM0_DOC+VM0_SERIE+VM0_FORNEC+VM0_LOJA
			Dbseek( TMPSF1->F1_FILIAL + TMPSF1->F1_DOC + TMPSF1->F1_SERIE + TMPSF1->F1_FORNECE + TMPSF1->F1_LOJA,.F. )
			If found()
				If VM0->VM0_STATUS == '4'
					cChave := TMPSF1->F1_CHVNFE
				EndIf
			Endif
			If cChave <> ''
				ClasDoc(cChave,TMPSF1->F1_FILIAL)
			Endif
			Dbselectarea("TMPSF1")
			Dbgotop()
			Loop
		Enddo

		Dbselectarea("TMPSF1")
		Dbclosearea()
	Enddo

	RESET ENVIRONMENT

Return

Static Function ClasDoc(cChave,cFilNf)
	cFilAnt := cFilNf
	aAutoImp :={}
	_aItens := {}
	_aCab1 :={}

	Dbselectarea("SF1")
	Dbsetorder(8)
	Dbseek( xFilial("SF1") + cChave, .F.)
//ajusta Dt digit para passar pelo bloqueio contabil
	If RecLock('SF1', .F.)
		SF1->F1_DTDIGIT:= DDATABASE
		MsUnlock()
	Endif

	//If .not. found()
	//	Msgstop('Chave nao encontrada')
	//	Return
	//Endif

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
		nBasPis := 0
		nBasCof := 0
		nValPis := 0
		nValCof := 0

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
	aAdd(_aCab1, {"F1_DTDIGIT"  , dDataBase         , NIL})
	aadd(_aCab1, {"E2_NATUREZ"  , cNatur            , NIL})
	aAdd(_aCab1, {"F1_XUSCLAS"  ,"SmartDocs"				, NIL})

	lMSHelpAuto := .T.
	lMSErroAuto := .F.
	MATA103(_aCab1,_aItens,4,.F.,aAutoImp)     // sem tela e com impostos

	If lMsErroAuto
		mostraerro("\classJD\","LogClassJD.txt")
		//GPEMail("Teste Erro na Classifica  o","Erro na Classificacao NF JD: "+SF1->F1_DOC,"fernandodasilva@terraverdegrupo.com.br;silviamiake@terraverdegrupo.com.br")
		GPEMail("Erro na Classificacao","Erro na Classificacao NF JD: "+SF1->F1_DOC,"valerio@sibe.com.br;fernandodasilva@terraverdegrupo.com.br")
	Else
		//GPEMail("Teste Nota Classificada","Nota Fiscal "+SF1->F1_DOC+" Classificada","fernandodasilva@terraverdegrupo.com.br;silviamiake@terraverdegrupo.com.br")
		GPEMail("Nota Classificada","Nota Fiscal "+SF1->F1_DOC+" Classificada","valerio@sibe.com.br;fernandodasilva@terraverdegrupo.com.br")
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
	oNotaxml := xmlparser(cString, "", @cError, @cWarning)
	oNfe  := WSAdvValue( oNotaxml,"_NFEPROC","string",NIL,NIL,NIL,NIL,NIL)
	oNF   := oNFe:_NFe
	oDet  := oNF:_InfNfe:_Det
	oDet  := IIf(ValType(oDet)=="O",{oDet},oDet)
	nX    := Val(D1ITEM)
	cCod  := oDet[nX]:_Prod:_cProd:TEXT
	cCfop := oDet[nX]:_Prod:_CFOP:TEXT

	oImposto 	:= oDet[nX]
	//PIS
	If ValAtrib("oImposto:_Imposto:_PIS")<>"U"
		If ValAtrib("oImposto:_Imposto:_PIS:_PISAliq:_vBC:TEXT")<>"U"
			nBasPis := Val(oImposto:_Imposto:_PIS:_PISAliq:_vBC:TEXT)
		EndIf
		If ValAtrib("oImposto:_Imposto:_PIS:_PISAliq:_vPIS:TEXT")<>"U"
			nValPis := Val(oImposto:_Imposto:_PIS:_PISAliq:_vPIS:TEXT)
		EndIf
	EndIf

	//COFINS
	If ValAtrib("oImposto:_Imposto:_COFINS")<>"U"
		If ValAtrib("oImposto:_Imposto:_COFINS:_COFINSAliq:_vBC:TEXT")<>"U"
			nBasCof := Val(oImposto:_Imposto:_COFINS:_COFINSAliq:_vBC:TEXT)
		EndIf
		If ValAtrib("oImposto:_Imposto:_COFINS:_COFINSAliq:_vCOFINS:TEXT")<>"U"
			nValCof := Val(oImposto:_Imposto:_COFINS:_COFINSAliq:_vCOFINS:TEXT)
		EndIf
	EndIf


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


Static Function ValAtrib(atributo)
Return (type(atributo) )
