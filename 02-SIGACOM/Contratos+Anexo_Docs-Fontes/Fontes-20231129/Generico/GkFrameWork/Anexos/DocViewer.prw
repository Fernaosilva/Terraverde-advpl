#include "TOTVS.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} DocViewer
Classe para visualizar do documento
@type class
@version 1.0
@author Geeker Company
@since 19/06/2021
@link https://gkcmp.com.br (Geeker Company)
/*/
Class DocViewer From LongClassName

	Data cTipo
	Data cChave
	Data cCompet
	Data cTitulo
	Data nLimite

	Data oDocViewerBLL

	data lInclui
	data lVisualiza
	data lAltera
	data lExcluir
	data lPodeDEL
	data lVldCria
	data lModify
	data cNomEmp

	// public
	Method New() Constructor
	Method Start()

	// protected
	Method Visualizar()
	Method Editar()
	Method Salvar()
	Method Adicionar()
	Method Excluir()
	Method LimpaEspaco()

	// private
	Method FPanel02()
	Method CriaCabec()
	Method Carregar()
	Method Legenda()
	Method CaracterEsp(cTextoEsp)

EndClass

/*/{Protheus.doc} New
Metodo construtor
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
@return variant, Nil
/*/
Method New(cTipo,cChave,cCompet) class DocViewer
	Default nLimite := -1
	Default cTipo   := ''
	Default cChave  := ''
	Default cCompet := ''

	::oDocViewerBLL	:= DocViewerBLL():New()

	::cTipo      := cTipo
	::cChave     := cChave
	::cCompet    := cCompet
	::nLimite    := nLimite
	::lInclui    := .T.
	::lVisualiza := .T.
	::lAltera    := .T.
	::lExcluir   := .T.
	::lPodeDEL   := .T.
	::lVldCria   := .T.
	::lModify    := .T.
	::cNomEmp    := "["+Capital(Substr(SM0->M0_NOMECOM,1,AT(" ",SM0->M0_NOMECOM)-1))+"] "

Return self

/*/{Protheus.doc} Start
Metodo para iniciar
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
@return variant, Nil
/*/
Method Start(cTipo,cChave,cTitulo,nLimite, cCompet,cDocCpo,cIniDtCpo,cFimDtCpo,cF3Doc) Class DocViewer
	local cDocto   := ""
	local aCompets := {}
	local bWHEN    := {}
	local bCHANGE  := {}

	private oGetDados
	private aBotoes := {}
	private aColsEx := {}

	default cTipo     := ""
	default cChave    := ""
	default cCompet   := ""
	default cTitulo   := ""
	default nLimite   := -1
	default cDocCpo   := ""
	default cIniDtCpo := ""
	default cFimDtCpo := ""
	default cF3Doc    := SubStr(cDocCpo,1,3)

	Static oDlg
	Static oBtnExec
	Static oPnlBot
	Static oPnlTop
	Static oPnlMid
	Static oBtnCnfrm
	Static oFont
	Static oDocto
	Static oCompets

	cDocto   := &cDocCpo	//--CN9->CN9_NUMERO
	if !Empty(&cIniDtCpo) .And. !Empty(&cFimDtCpo)
		aCompets := getCompets(&cIniDtCpo, &cFimDtCpo) // retorna as compentências do contrato.
	endif

	::cTipo   := cTipo
	::cCompet := cCompet

	::cChave  := cChave
	if !Empty(::cCompet) .And. RIGHT(::cChave,6) <> ::cCompet
		::cChave += '|'+StrTran(::cCompet,'/','')	// a chave completa inclui a competencia do contrato.
	endif
	::cTitulo := AllTrim(cTitulo)
	::nLimite := nLimite

	If ( ::lExcluir )
		AAdd( aBotoes, {"", {|| ::Excluir()}, "Excluir", "Excluir" , {|| .T.}} )
	EndIf

	// Exibo apenas os complementos
	DEFINE MSDIALOG oDlg TITLE "Visualizador de Documentos" FROM 0,0 TO 480,725 COLORS 0,16777215 PIXEL STYLE DS_MODALFRAME
	
	//-Parte Superior do Painel
	@ 030,000 MSPANEL oPnlTop SIZE 363,020 OF oDlg COLORS 0,16777215
	@ 007,005 SAY "Nr.Documento: " SIZE 035,007 OF oPnlTop COLORS 0,16777215 PIXEL
    @ 005,055 MSGET oDocto VAR cDocto SIZE 060,010 OF oPnlTop WHEN .F. F3 cF3Doc COLORS 0,16777215 PIXEL	//--"CN9"
	oDocto:lHasButton := .F.

    if !Empty(::cCompet) .Or. Len(aCompets) > 0
		bWHEN := {|| ::lModify }

		@ 007,140 SAY "Competência: " SIZE 035,007 OF oPnlTop COLORS 0,16777215 PIXEL
		if !Empty(::cCompet)
			bCHANGE := {|| ::cChave }
			//-New([anRow],[anCol],[abSetGet],[anItems], [anWidth],[anHeight],[aoWnd],[nPar8],[abChange],[abValid],[anClrText],[anClrBack],[alPixel],[aoFont],[cPar15],[lPar16],[abWhen],[lPar18],[aPar19],[bPar20],[cPar21],[acReadVar])
			oCompets := TComboBox():New(006,180,{|| self:cCompet},{self:cCompet},047,010,oPnlTop,,bCHANGE,,,,.T.,,,,bWHEN,,,,,'self:cCompet')
		else
			bCHANGE := {|| Iif(::lModify,(::cChave := cChave+ '|' +StrTran(oCompets:aItems[oCompets:nAt],'/',''),::Carregar(2)),NIL) }
			oCompets := TComboBox():New(006,180,{|u| Iif(PCount()>0,self:cCompet:=u,self:cCompet)},aCompets,047,010,oPnlTop,,bCHANGE,,,,.T.,,,,bWHEN,,,,,'self:cCompet')
		endif
	endif

	//-Parte do Meio do Painel
	@ 050,000 MSPANEL oPnlMid SIZE 363,171 OF oDlg COLORS 0,16777215
	oLayer := FWLayer():New()
	oLayer:Init( oPnlMid, .F. )
	oLayer:AddLine( "LINE02", 100 )
	oLayer:AddCollumn( "BOX02", 100,, "LINE02" )
	oLayer:AddWindow( "BOX02", "PANEL02", cTitulo, 100, .F.,,, "LINE02" )

	oGetDados := ::FPanel02( oLayer:GetWinPanel( "BOX02", "PANEL02", "LINE02" ) )
	oFont := TFont():New('Arial',,-11,.T.)

	//-Parte Inferior do Painel
	@ 030,000 MSPANEL oPnlBot SIZE 415,020 OF oDlg COLORS 0,16777215
	If ( ::lVisualiza )
		@ 002,012 BUTTON "Visualizar" SIZE 060,015 PIXEL OF oPnlBot ACTION (::Visualizar())
	EndIf
	If(::lAltera)
		@ 002,090 BUTTON "Editar" SIZE 060,015 PIXEL OF oPnlBot ACTION (::Editar())
	EndIf
	@ 002,168 BUTTON "Exportar" SIZE 060,015 PIXEL OF oPnlBot ACTION (::Salvar())
	If ( ::lInclui )
		@ 002,246 BUTTON "Adicionar" SIZE 060,015 PIXEL OF oPnlBot ACTION (::Adicionar())
	EndIf

	ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| oDlg:End()},{|| oDlg:End()},,aBotoes,/*NrEG*/,/*VALIAS*/,.F.,.F.,.F.,.F.,.F.,"TITULO"), oPnlBot:Align := CONTROL_ALIGN_BOTTOM) CENTERED

Return Nil

/*/{Protheus.doc} FPanel02
Metodo para o paniel
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method FPanel02( oPanel ) Class DocViewer
	Local aaCampos  	:= {}	// Variável contendo o campo editável no Grid
	Private oLista				// Declarando o objeto do browser
	Private aCabecalho  := {}	// Variavel que montará o aHeader do grid

	// chamar a função que cria a estrutura do aHeader
	::CriaCabec()

	// Monta o browser com inclusão, remoção e atualização
	oLista := MsNewGetDados():New( 053, 078, 200, 300, , "AllwaysTrue", "AllwaysTrue", "AllwaysTrue", aaCampos,1, 999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aCabecalho, aColsEx)

	// Carregar os itens que irão compor o conteudo do grid
	::Carregar()

	// Alinho o grid para ocupar todo o meu formulário
	oLista:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	// Ao abrir a janela o cursor está posicionado no meu objeto
	oLista:oBrowse:SetFocus()

	// Crio o menu que irá aparece no botão Ações relacionadas
	AAdd(aBotoes,{"NG_ICO_LEGENDA", {||::Legenda()},"Legenda","Legenda"})

Return oLista

/*/{Protheus.doc} Carregar
Metodo para carregar
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Carregar(nTipo) Class DocViewer
	Local nI
	Local aItens  := {}
	Default nTipo := 1

	aItens := ::oDocViewerBLL:Carregar(::cTipo, ::cChave)

	aColsEx := {}
	For nI := 1 to Len(aItens)
		AAdd(aColsEx,{})
		AAdd(aColsEx[nI], Cores(aItens[nI]))
		AEval(aItens[nI], {|x| AAdd(aColsEx[nI], x)},/*nStart*/,/*nCount*/)
		AAdd(aColsEx[nI], .F.)
	Next nI

	If nTipo <> 1
		// Setar array do aCols do Objeto.
		oGetDados:SetArray(aColsEx,.T.)

		//Atualizo as informações no grid
		oGetDados:Refresh()
	Else
		// Setar array do aCols do Objeto.
		oLista:SetArray(aColsEx,.T.)

		//Atualizo as informações no grid
		oLista:Refresh()
	EndIf
Return Nil

/*/{Protheus.doc} Cores
Metodo para retornar o anexo
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Static Function Cores(aItem)
	Local cTipoArq		:= Lower(SubStr(AllTrim(aItem[3]), RAt(".", aItem[3]) + 1))
	Local aResources	:= GetResources()

	Do Case
	Case cTipoArq $ 'jpg,jpeg,png,bmp'
		oDocumento := LoadBitmap(aResources, "ANEX_IMAGEM")
	Case cTipoArq $ 'pdf'
		oDocumento := LoadBitmap(aResources, "ANEX_PDF")
	Case cTipoArq $ 'xls,xlsx,csv'
		oDocumento := LoadBitmap(aResources, "ANEX_PLANILHA")
	Case cTipoArq $ 'doc,docx'
		oDocumento := LoadBitmap(aResources, "ANEX_DOC")
	Case cTipoArq $ 'zip,rar,7zip,gzip'
		oDocumento := LoadBitmap(aResources, "ANEX_WINRAR")
	OtherWise
		oDocumento := LoadBitmap(aResources, "ANEX_DESCONH")
	EndCase

Return oDocumento

/*/{Protheus.doc} CriaCabec
Metodo para criacao do cabecalho o documento
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method CriaCabec() Class DocViewer
	Local cCampos	:= "ZG9_TITULO|ZG9_OBS|ZG9_ANEXO|ZG9_DTCRI|ZG9_USR|"
	Local aCampos	:= StrTokArr(cCampos,"|")
	Local nI

	// Incluo um ícone na primeira coluna do cabeçalho
	AAdd(aCabecalho, {;
						"",;		//X3Titulo()
						"IMAGEM",;  //X3_CAMPO
						"@BMP",;	//X3_PICTURE
						3,;			//X3_TAMANHO
						0,;			//X3_DECIMAL
						".F.",;		//X3_VALID
						"",;		//X3_USADO
						"C",;		//X3_TIPO
						"",; 		//X3_F3
						"V",;		//X3_CONTEXT
						"",;		//X3_CBOX
						"",;		//X3_RELACAO
						"",;		//X3_WHEN
						"V"})		//

	For nI := 1 to Len(aCampos)
		DbSelectArea("SX3")
		DbSetOrder(2)
		If DbSeek(aCampos[nI])
			AAdd(aCabecalho, {;
								X3_TITULO,;		//X3Titulo()
								X3_CAMPO,;  	//X3_CAMPO
								X3_PICTURE,;	//X3_PICTURE
								X3_TAMANHO,;	//X3_TAMANHO
								X3_DECIMAL,;	//X3_DECIMAL
								X3_VALID,;		//X3_VALID
								X3_USADO,;		//X3_USADO
								X3_TIPO,;		//X3_TIPO
								X3_F3,;			//X3_F3
								X3_CONTEXT,;	//X3_CONTEXT
								X3_CBOX,;		//X3_CBOX
								X3_RELACAO,;	//X3_RELACAO
								".F."})			//X3_WHEN
		EndIf
	Next nI
Return Nil

/*/{Protheus.doc} Adicionar
Metodo para adicionar documentos no ...\protheus_data\anexos
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Adicionar() Class DocViewer
	local cMsgAlert   := ""
	Local aPergs      := {}
	Local cTitulo     := Space(100)
	Local cObservacao := Space(100)
	Local cArquivo    := Space(100)
	Local dData       := Date()
	Local cUser       := cUserName
	Local nResultado  := 0
	Local cNomeArq, cDiretorio, cDestino, cArqAux, aArquivos, nI, nX

	If ::nLimite > 0 .And. ::nLimite <= Len(oGetDados:aCols)
		MsgInfo("Quantidade total de documentos excedeu o limite máx. de "+cValToChar(::nLimite)+" documento(s).", OemToAnsi(::cNomEmp+"Atenção!"))
		Return Nil
	EndIf

    cArqAux := cGetFile('Todos os arquivos (*.*)|*.*','Seleção de arquivos',0,'C:\',.T.,GETF_LOCALHARD +GETF_LOCALFLOPPY +GETF_NETWORKDRIVE +GETF_MULTISELECT,.F.,.T.)

	aArquivos := StrTokArr(cArqAux,'|')

	//-Verifica se algum dos arquivos tem caracter especiais nao permitidos
	For nX := 1 to Len(aArquivos)
		if ::CaracterEsp(Alltrim(aArquivos[nX]))
			cMsgAlert += OemToAnsi("Não são permitidos caracteres especiais no nome de arquivos, e se possível não deixe espaços também. ")
			cMsgAlert += OemToAnsi("Favor renomear o arquivo abaixo: ") +CRLF
			cMsgAlert += OemToAnsi(Alltrim(aArquivos[nX])) +CRLF

			MsgAlert(cMsgAlert, OemToAnsi(::cNomEmp+"Atenção!"))

			aArquivos := {}
			Exit
		endif
	Next nX

	Do Case
		Case Len(aArquivos) == 0
		Case Len(aArquivos) == 1			
			
			cDestino		:= ::oDocViewerBLL:Destino(,::cTipo,::cChave)
			cNomeArq		:= SubStr(cArqAux, RAt("\", cArqAux) + 1)		
			cDiretorio		:= Left(cArqAux, RAt("\", cArqAux))

			AAdd(aPergs, {1, "Título"		, cTitulo     , "", ".T.", "", ".T.", 80,  .T.})
			AAdd(aPergs, {1, "Observacao"	, cObservacao , "", ".T.", "", ".T.", 80,  .F.})
			AAdd(aPergs, {1, "Arquivo"		, cNomeArq	  , "", ".T.", "", ".F.", 80,  .T.})
			AAdd(aPergs, {1, "Criador"		, cUser		  , "", ".T.", "", ".F.", 80,  .F.})
			AAdd(aPergs, {1, "Data Criação" , dData		  , "", ".T.", "", ".F.", 80,  .F.})

			If ParamBox(aPergs, "Novo Documento")
				cTitulo			:= MV_PAR01
				cObservacao		:= MV_PAR02

				MsgRun("Adicionando arquivo "+cNomeArq, ::cNomEmp+"Copiando....", {|| CursorWait(), nResultado := ::oDocViewerBLL:Salvar(cNomeArq, cDiretorio, cDestino, ::cTipo, ::cChave), CursorArrow()})
				If nResultado <> 0
					MsgInfo("Não foi possível enviar o arquivo. Por favor, tente novamente mais tarde.", ::cNomEmp+"Erro "+StrZero(nResultado,4))
				Else
					::oDocViewerBLL:Adicionar(::cTipo, ::cChave, cTitulo, cObservacao, cDestino + "\" + cNomeArq)
					MsgInfo("Documento adicionado com sucesso", ::cNomEmp+"Documento adicionado")
					::Carregar(2)
				EndIf
			EndIf

		OtherWise
			nTotalSucesso := 0
			nTotalErro  := 0
			For nI := 1 to Len(aArquivos)
				
				cDestino		:= ::oDocViewerBLL:Destino(,::cTipo,::cChave)
				cArquivo		:= AllTrim(aArquivos[nI])
				cNomeArq		:= SubStr(cArquivo, RAt("\", cArquivo) + 1)
				cDiretorio		:= ::LimpaEspaco( Left(cArquivo, RAt("\", cArquivo)) )
				cTitulo			:= SubStr(cNomeArq, 1, Rat(".",cNomeArq) - 1)
				cObservacao		:= ""

				MsgRun("Adicionando arquivo "+cNomeArq, ::cNomEmp+"Copiando....", {|| CursorWait(), nResultado := ::oDocViewerBLL:Salvar(cNomeArq,cDiretorio,cDestino,::cTipo,::cChave),CursorArrow()})
				
				If nResultado <> 0
					nTotalErro++
				Else
					::oDocViewerBLL:Adicionar(::cTipo, ::cChave, cTitulo, cObservacao, cDestino + "\" + cNomeArq)
					nTotalSucesso++
				Endif

			Next nI

			If nTotalSucesso > 0
				MsgInfo(cValToChar(nTotalSucesso)+" documento(s) de "+cValToChar(Len(aArquivos))+" adicionado(s) com sucesso", ::cNomEmp+"Documento(s) adicionado(s)")
			Else
				MsgInfo("Não foi possível enviar o arquivo. Por favor, tente novamente mais tarde.", ::cNomEmp+"Erro "+StrZero(nResultado,4))
			EndIf
			::Carregar(2)
	EndCase

Return Nil

/*/{Protheus.doc} Visualizar
Metodo para visualizar documentos
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Visualizar() Class DocViewer
	Local cDestino		:= GetTempPath(.T.)
	Local nResultado	:= 0
	Local cArquivo, cNomeArq, cDiretorio, cId

	If Len(oGetDados:aCols) == 0
		MsgInfo("Nenhum documento selecionado", OemToAnsi(::cNomEmp+"Atenção!"))
		Return Nil
	EndIf

	cId	  		:= AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][7])
	cArquivo  	:= oGetDados:aCols[oGetDados:oBrowse:nAt][4]
	cDiretorio  := ::LimpaEspaco( AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][8]) )
	cNomeArq  	:= AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][9])

	MsgRun("Abrindo arquivo "+cNomeArq, ::cNomEmp+"Copiando....", {|| CursorWait(), nResultado := ::oDocViewerBLL:Salvar(cNomeArq, cDiretorio, cDestino, ::cTipo, ::cChave, cId) ,CursorArrow()})
	
	If nResultado <> 0
		MsgInfo("Não foi possível visualizar o arquivo. Por favor, tente novamente mais tarde.", ::cNomEmp+"Erro "+StrZero(nResultado,4))
	Else
		cNomeArq := ::oDocViewerBLL:NomeArquivo(cNomeArq, cId)
		nRet := ShellExecute("open", cNomeArq, "", cDestino, 1)

		//Se houver algum erro
		If nRet <= 32
			MsgInfo("Não foi possível abrir o arquivo "+cDestino+cNomeArq+".", OemToAnsi(::cNomEmp+"Atenção!"))
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc} Editar
Metodo para editar documentos
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Editar() Class DocViewer
	Local aPergs   := {}
	Local cTitulo, cObservacao, dData, cUser, cId
	Local cArquivo, cNomeArq

	If Len(oGetDados:aCols) == 0
		MsgInfo("Nenhum documento selecionado", OemToAnsi(::cNomEmp+"Atenção!"))
		Return Nil
	EndIf

	cTitulo  		:= oGetDados:aCols[oGetDados:oBrowse:nAt][2]
	cObservacao  	:= oGetDados:aCols[oGetDados:oBrowse:nAt][3]
	cArquivo  		:= oGetDados:aCols[oGetDados:oBrowse:nAt][4]
	dData			:= oGetDados:aCols[oGetDados:oBrowse:nAt][5]
	cUser			:= oGetDados:aCols[oGetDados:oBrowse:nAt][6]
	cId				:= oGetDados:aCols[oGetDados:oBrowse:nAt][7]
	cNomeArq		:= SubStr(cArquivo, RAt("\", cArquivo) + 1)

	AAdd(aPergs, {1, "Título"       , cTitulo     , "", ".T.", "", ".T.", 80,  .T.})
	AAdd(aPergs, {1, "Observacao"   , cObservacao , "", ".T.", "", ".T.", 80,  .F.})
	AAdd(aPergs, {1, "Arquivo"      , cNomeArq    , "", ".T.", "", ".F.", 80,  .T.})
	AAdd(aPergs, {1, "Criador"      , cUser       , "", ".T.", "", ".F.", 80,  .F.})
	AAdd(aPergs, {1, "Data Criação" , dData       , "", ".T.", "", ".F.", 80,  .F.})

	If ParamBox(aPergs, "Editar Documento")
		::oDocViewerBLL:Editar(::cTipo, ::cChave, cId, MV_PAR01, MV_PAR02)
		MsgInfo("Documento editado com sucesso", ::cNomEmp+"Documento editado")
		::Carregar(2)
	EndIf

Return Nil

/*/{Protheus.doc} Excluir
Metodo para excluir documentos
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Excluir() Class DocViewer
	Local cUser			:= Lower(Lower(cUsername))
	Local nExclusao		:= 0
	Local cId, cCriador, cNomeArq, cArquivo

	If Len(oGetDados:aCols) == 0
		MsgInfo("Nenhum documento selecionado", OemToAnsi(::cNomEmp+"Atenção!"))
		Return Nil
	EndIf

	cId				:= oGetDados:aCols[oGetDados:oBrowse:nAt][7]
	cCriador		:= Lower(AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][6]))
	cArquivo		:= AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][4])
	cDiretorio  	:= ::LimpaEspaco(AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][8]))
	cNomeArq  		:= AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][9])
			
	If( ::lVldCria )
		If cUser <> cCriador
			MsgBox("Apenas usuários criadores podem realizar essa operação. Por favor, selecione outro documento.")
			Return Nil
		EndIf
	ElseIf( !::lPodeDEL )
		MsgBox("Usuário sem permissão para realizar essa operação.")
		Return Nil
	EndIf

	If MsgYesNo("Deseja realmente excluir o documento '"+cNomeArq+"'? Essa operação não pode ser desfeita.", OemToAnsi(::cNomEmp+"Atenção!"))
		nExclusao := ::oDocViewerBLL:Excluir(::cTipo, ::cChave, cId, cNomeArq, cDiretorio, cId)
		If nExclusao == 0
			MsgInfo("Documento excluído com sucesso", ::cNomEmp+"Documento excluído")
			::Carregar(2)
		Else
			MsgInfo("Não foi possível excluir o documento. Por favor, tente novamente mais tarde.", ::cNomEmp+"Erro "+StrZero(nExclusao,4))
		EndIf
	EndIf
	
Return Nil

/*/{Protheus.doc} Salvar
Metodo para salvar documentos em diretório local
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Salvar() Class DocViewer
	Local cMask 		:= ""		//"XLS (*.XLS) | *.XLS"
	Local cTitle 		:= "Salvar em"
	Local nMask 		:= 1
	Local cDir 			:= "C:\"	//SubStr(cTemp, 1, AT("\AppData", cTemp)) + "desktop"
	Local lSave	 		:= .F.
	Local nOpc			:= nOR(GETF_LOCALHARD, GETF_LOCALFLOPPY, GETF_RETDIRECTORY)
	Local lServer		:= .F.
	Local nResultado	:= 0
	Local cArquivo, cNomeArq, cDestino, cId

	If Len(oGetDados:aCols) == 0
		MsgInfo("Nenhum documento selecionado", OemToAnsi(::cNomEmp+"Atenção!"))
		Return Nil
	EndIf

	cDestino := cGetFile(cMask, cTitle, nMask, cDir, lSave, nOpc, lServer)

	If Len(cDestino) == 0
		Return Nil
	EndIf

	cId	  		:= oGetDados:aCols[oGetDados:oBrowse:nAt][7]
	cArquivo  	:= oGetDados:aCols[oGetDados:oBrowse:nAt][4]
	cDiretorio  := ::LimpaEspaco( AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][8]) )
	cNomeArq  	:= AllTrim(oGetDados:aCols[oGetDados:oBrowse:nAt][9])

	MsgRun("Salvando arquivo "+cNomeArq, ::cNomEmp+"Copiando....", {|| CursorWait(), nResultado:=::oDocViewerBLL:Salvar(cNomeArq, cDiretorio, cDestino, ::cTipo, ::cChave, cId) ,CursorArrow()})
	If nResultado <> 0
		MsgInfo("Não foi possível salvar o arquivo. Por favor, tente novamente mais tarde.", ::cNomEmp+"Erro "+StrZero(nResultado,4))
	Else
		nRet := ShellExecute("open", "explorer.exe", "/select," + cDestino + ::oDocViewerBLL:NomeArquivo(cNomeArq, cId), "", 1)
		// Se houver algum erro
		If nRet <= 32
			MsgInfo("Não foi possível abrir o diretório " + cDestino + ".", OemToAnsi(::cNomEmp+"Atenção!"))
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc} Legenda
Metodo para legenda
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Legenda() Class DocViewer
	Local aLegenda 	:= {}

	AAdd(aLegenda,{"ANEX_IMAGEM"	,"   Arquivos de imagem (*.jpg,*.jpeg,*.png,*.bmp)" })
	AAdd(aLegenda,{"ANEX_PDF"		,"   Arquivos PDF (*.pdf)" })
	AAdd(aLegenda,{"ANEX_PLANILHA"	,"   Arquivos de planilha (*.xls,*.xlsx,*.csv)" })
	AAdd(aLegenda,{"ANEX_DOC"		,"   Arquivos Word (*.doc,*.docx)" })
	AAdd(aLegenda,{"ANEX_WINRAR"	,"   Arquivos comprimidos (*.zip,*.rar,*.7zip,*.gzip)" })
	AAdd(aLegenda,{"ANEX_DESCONH"	,"   Arquivo desconhecido" })

	BrwLegenda("Legenda", "Legenda", aLegenda)

Return Nil

/*/{Protheus.doc} LimpaEspaco
Metodo para retirar os espacos
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method LimpaEspaco( cTitulo ) Class DocViewer
	Local nPosEsp := 0

    cTitulo := Alltrim(cTitulo)
    
    While( .T. )
        nPosEsp := At( " ", cTitulo)

        If( nPosEsp <= 0 )
            Exit
        Else
            cTitulo :=  SubStr( cTitulo, 1                      , At( " ", cTitulo) - 1) + ;
                        SubStr( cTitulo, At( " ", cTitulo) + 1  , Len( cTitulo ) )
        EndIf
    End

Return cTitulo

/*/{Protheus.doc} CaracterEsp
Metodo para verificar se existem caracteres especiais no texto
@type method
@version 1.0
@author Ademar Fernandes Jr.
@since 07/11/2023
@param cTextoEsp, character, Texto para analise
@return variant, Trfue / False
/*/
Method CaracterEsp(cTextoEsp) Class DocViewer
	local lRetorno   := .F.
	local cEspeciais := SuperGetMv("ZZ_ANEXESP",.F.," =/*-+,;()[]{}!@?#$%&") //-Caracteres Especiais a serem validados
	local aEspeciais := {}
	//-Converte uma String em Array consideranto os conteudos em branco entre os separadores!
	//-StrTokArr2( < cValue >, < cToken >, [ lEmptyStr ] )
	// local aEspeciais := StrTokArr2(Alltrim(cEspeciais),"",.T.)
	local nX,nY

	default cTextoEsp := ""

	//-Adiciona Espaço como Caracter Especial
	if Substr(cEspeciais,1,1) == " "
		aAdd(aEspeciais, " ")
	endif
	cEspeciais := Alltrim(cEspeciais)

	For nY := 1 to Len(cEspeciais)
		aAdd(aEspeciais, Substr(cEspeciais,nY,1))
	Next nY

	if !Empty(cTextoEsp)
		For nX := 1 to Len(aEspeciais)
			if !lRetorno .And. aEspeciais[nX] $ Alltrim(cTextoEsp)
				lRetorno := .T.
			endif
		Next nX
	endif

Return lRetorno

/*/{Protheus.doc} getCompets
Funcao para carregar as competencias validas entre duas datas
@type function
@version 1.0
@author Geeker Company (Johny)
@since 01/09/2023
@param dDtInic, date, Data de inicio
@param dDtFim, date, Data final
@return variant, Array com as competencias
/*/
Static function getCompets(dDtInic,dDtFim)
	Local nMesAux	:= ""
	Local nAnoAux	:= ""
	Local aCompets 	:= {}

	Default dDtInic	:= CToD('')
	Default dDtFim	:= CToD('')

	nMesAux := Month( dDtInic )
    nAnoAux := Year( dDtInic )

    While nMesAux <= Month( dDtFim ) .OR. nAnoAux < Year( dDtFim )
        If nMesAux > 12
            nMesAux := 1
            nAnoAux++
        EndIf
        AAdd( aCompets, StrZero(nMesAux,2)+"/"+Str(nAnoAux,4) )
		nMesAux++
    EndDo

Return aCompets
