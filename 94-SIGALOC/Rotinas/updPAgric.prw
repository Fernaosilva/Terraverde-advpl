#INCLUDE "protheus.ch"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UpdPAgric

Função de update de dicionários para compatibilização

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UpdPAgric( cEmpAmb, cFilAmb )
Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça"
Local   cDesc4    := "um BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para"
Local   cDesc5    := "que caso ocorram eventuais falhas, esse backup possa ser restaurado."
Local   cDesc6    := ""
Local   cDesc7    := ""
Local   cMsg      := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.

Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf

If lOk

	If GetVersao(.F.) < "12" .OR. ( FindFunction( "MPDicInDB" ) .AND. !MPDicInDB() )
		cMsg := "Este update NÃO PODE ser executado neste Ambiente." + CRLF + CRLF + ;
				"Os arquivos de dicionários se encontram em formato ISAM" + " (" + GetDbExtension() + ") " + "Os arquivos de dicionários se encontram em formato ISAM" + " " + ;
				"para atualizar apenas ambientes com dicionários no Banco de Dados."

		If lAuto
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( cMsg )
			ConOut( DToC(Date()) + "|" + Time() + cMsg )
		Else
			MsgInfo( cMsg )
		EndIf

		Return NIL
	EndIf

	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else
		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

			If lAuto
				If lOk
					MsgInfo( "Atualização realizada.", "UpdPAgric" )
				Else
					MsgStop( "Atualização não realizada.", "UpdPAgric" )
				EndIf
				dbCloseAll()
			Else
				If lOk
					Final( "Atualização realizada." )
				Else
					Final( "Atualização não realizada." )
				EndIf
			EndIf

		Else
			Final( "Atualização não realizada." )

		EndIf

	Else
		Final( "Atualização não realizada." )

	EndIf

EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc

Função de processamento da gravação dos arquivos

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
Local   cAux      := ""
Local   cFile     := ""
Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// Só adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )
			AutoGrLog( " Dados Ambiente" )
			AutoGrLog( " --------------------" )
			AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
			AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
			AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
			AutoGrLog( " Environment........: " + GetEnvServer()  )
			AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
			AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
			AutoGrLog( " Versão.............: " + GetVersao(.T.) )
			AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
			AutoGrLog( " Computer Name......: " + GetComputerName() )

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				AutoGrLog( " " )
				AutoGrLog( " Dados Thread" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
				AutoGrLog( " Estação............: " + aInfo[nPos][2] )
				AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
				AutoGrLog( " Environment........: " + aInfo[nPos][6] )
				AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
			EndIf
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )

			If !lAuto
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
			EndIf

			oProcess:SetRegua1( 8 )

			//------------------------------------
			// Atualiza o dicionário SX3
			//------------------------------------
			FSAtuSX3()

			//------------------------------------
			// Atualiza o dicionário SIX
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSIX()

			oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/índices" )

			// Alteração física dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
					AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX

			//------------------------------------
			// Atualiza o dicionário SX6
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX6()

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
			AutoGrLog( Replicate( "-", 128 ) )

			RpcClearEnv()

		Next nI

		If !lAuto

			cTexto := LeLog()

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3

Função de processamento da gravação do SX3 - Campos

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cMsg      := ""
Local cSeqAtu   := ""
Local cX3Campo  := ""
Local cX3Dado   := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nPosVld   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
             { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
             { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
             { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
             { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
             { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
             { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )

//
// --- ATENÇÃO ---
// Coloque .F. na 2a. posição de cada elemento do array, para os dados do SX3
// que não serão atualizados quando o campo já existir.
//

//
// Campos Tabela SA1
//
aAdd( aSX3, { ;
	{ 'SA1'																	, .T. }, ; //X3_ARQUIVO
	{ 'F0'																	, .T. }, ; //X3_ORDEM
	{ 'A1_XTIPCLI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Tip. Cliente'														, .T. }, ; //X3_TITULO
	{ 'Tip. Cliente'														, .T. }, ; //X3_TITSPA
	{ 'Tip. Cliente'														, .T. }, ; //X3_TITENG
	{ 'Tipo de Cliente'														, .T. }, ; //X3_DESCRIC
	{ 'Tipo de Cliente'														, .T. }, ; //X3_DESCSPA
	{ 'Tipo de Cliente'														, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ 'K=Kam;S=Sam;V=Varejo;C=Corp'											, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SA1'																	, .T. }, ; //X3_ARQUIVO
	{ 'FA'																	, .T. }, ; //X3_ORDEM
	{ 'A1_XSEGTIP'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Seg. Tipo'															, .T. }, ; //X3_TITULO
	{ 'Seg. Tipo'															, .T. }, ; //X3_TITSPA
	{ 'Seg. Tipo'															, .T. }, ; //X3_TITENG
	{ 'Segmentacao: Tipo'													, .T. }, ; //X3_DESCRIC
	{ 'Segmentacao: Tipo'													, .T. }, ; //X3_DESCSPA
	{ 'Segmentacao: Tipo'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ 'R=Rural;U=Usina;C=Corporativo'										, .T. }, ; //X3_CBOX
	{ 'R=Rural;U=Usina;C=Corporativo'										, .T. }, ; //X3_CBOXSPA
	{ 'R=Rural;U=Usina;C=Corporativo'										, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

//
// Campos Tabela VMJ
//
aAdd( aSX3, { ;
	{ 'VMJ'																	, .T. }, ; //X3_ARQUIVO
	{ '03'																	, .T. }, ; //X3_ORDEM
	{ 'VMJ_XLOJA'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 4																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Loja'																, .T. }, ; //X3_TITULO
	{ 'Loja'																, .T. }, ; //X3_TITSPA
	{ 'Loja'																, .T. }, ; //X3_TITENG
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCRIC
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCSPA
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x xx', .T. }, ; //X3_USADO
	{ 'SA1->A1_LOJA'														, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ '     xx'																, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '  x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ '002'																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'S'																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ '2'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMJ'																	, .T. }, ; //X3_ARQUIVO
	{ '25'																	, .T. }, ; //X3_ORDEM
	{ 'VMJ_UUID'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 36																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'ID'																	, .T. }, ; //X3_TITULO
	{ 'ID'																	, .T. }, ; //X3_TITSPA
	{ 'ID'																	, .T. }, ; //X3_TITENG
	{ ''																	, .T. }, ; //X3_DESCRIC
	{ ''																	, .T. }, ; //X3_DESCSPA
	{ ''																	, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMJ'																	, .T. }, ; //X3_ARQUIVO
	{ '26'																	, .T. }, ; //X3_ORDEM
	{ 'VMJ_DATINC'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 14																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Data ini'															, .T. }, ; //X3_TITULO
	{ 'Data ini'															, .T. }, ; //X3_TITSPA
	{ 'Data ini'															, .T. }, ; //X3_TITENG
	{ ''																	, .T. }, ; //X3_DESCRIC
	{ ''																	, .T. }, ; //X3_DESCSPA
	{ ''																	, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMJ'																	, .T. }, ; //X3_ARQUIVO
	{ '27'																	, .T. }, ; //X3_ORDEM
	{ 'VMJ_DATALT'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 14																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Data Alt'															, .T. }, ; //X3_TITULO
	{ 'Data Alt'															, .T. }, ; //X3_TITSPA
	{ 'Data Alt'															, .T. }, ; //X3_TITENG
	{ ''																	, .T. }, ; //X3_DESCRIC
	{ ''																	, .T. }, ; //X3_DESCSPA
	{ ''																	, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMJ'																	, .T. }, ; //X3_ARQUIVO
	{ '28'																	, .T. }, ; //X3_ORDEM
	{ 'VMJ_XTAMSG'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 2																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Tam/Segment.'														, .T. }, ; //X3_TITULO
	{ 'Tam/Segment.'														, .T. }, ; //X3_TITSPA
	{ 'Tam/Segment.'														, .T. }, ; //X3_TITENG
	{ 'Tamanho/Segmentaçao'													, .T. }, ; //X3_DESCRIC
	{ 'Tamanho/Segmentaçao'													, .T. }, ; //X3_DESCSPA
	{ 'Tamanho/Segmentaçao'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ '"NA"'																, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ '  x x'																, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '  x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ '2'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

//
// Campos Tabela VMK
//
aAdd( aSX3, { ;
	{ 'VMK'																	, .T. }, ; //X3_ARQUIVO
	{ '03'																	, .T. }, ; //X3_ORDEM
	{ 'VMK_XLOJA'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 4																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Loja'																, .T. }, ; //X3_TITULO
	{ 'Loja'																, .T. }, ; //X3_TITSPA
	{ 'Loja'																, .T. }, ; //X3_TITENG
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCRIC
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCSPA
	{ 'Loja do Cliente'														, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x xx', .T. }, ; //X3_USADO
	{ 'SA1->A1_LOJA'														, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ '     xx'																, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '  x'																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ '002'																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'S'																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ '2'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMK'																	, .T. }, ; //X3_ARQUIVO
	{ '21'																	, .T. }, ; //X3_ORDEM
	{ 'VMK_UUID'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 36																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'ID'																	, .T. }, ; //X3_TITULO
	{ 'ID'																	, .T. }, ; //X3_TITSPA
	{ 'ID'																	, .T. }, ; //X3_TITENG
	{ ''																	, .T. }, ; //X3_DESCRIC
	{ ''																	, .T. }, ; //X3_DESCSPA
	{ ''																	, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMK'																	, .T. }, ; //X3_ARQUIVO
	{ '22'																	, .T. }, ; //X3_ORDEM
	{ 'VMK_DATINC'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 14																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Data Ini'															, .T. }, ; //X3_TITULO
	{ 'Data Ini'															, .T. }, ; //X3_TITSPA
	{ 'Data Ini'															, .T. }, ; //X3_TITENG
	{ ''																	, .T. }, ; //X3_DESCRIC
	{ ''																	, .T. }, ; //X3_DESCSPA
	{ ''																	, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMK'																	, .T. }, ; //X3_ARQUIVO
	{ '23'																	, .T. }, ; //X3_ORDEM
	{ 'VMK_DATALT'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 14																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Data Alt'															, .T. }, ; //X3_TITULO
	{ 'Data Alt'															, .T. }, ; //X3_TITSPA
	{ 'Data Alt'															, .T. }, ; //X3_TITENG
	{ ''																	, .T. }, ; //X3_DESCRIC
	{ ''																	, .T. }, ; //X3_DESCSPA
	{ ''																	, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ 'xxxxxx x'															, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .T. }, ; //X3_OBRIGAT
	{ ''																	, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMK'																	, .T. }, ; //X3_ARQUIVO
	{ '24'																	, .T. }, ; //X3_ORDEM
	{ 'VMK_XAREPR'															, .T. }, ; //X3_CAMPO
	{ 'N'																	, .T. }, ; //X3_TIPO
	{ 7																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Area Propria'														, .T. }, ; //X3_TITULO
	{ 'Area Propria'														, .T. }, ; //X3_TITSPA
	{ 'Area Propria'														, .T. }, ; //X3_TITENG
	{ 'Area Propria'														, .T. }, ; //X3_DESCRIC
	{ 'Area Propria'														, .T. }, ; //X3_DESCSPA
	{ 'Area Propria'														, .T. }, ; //X3_DESCENG
	{ '@E 9,999,999'														, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ '  x x'																, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '  x'																	, .T. }, ; //X3_OBRIGAT
	{ 'U_TvAgricValid("VMJ_AREPRO")'										, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ '2'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'VMK'																	, .T. }, ; //X3_ARQUIVO
	{ '25'																	, .T. }, ; //X3_ORDEM
	{ 'VMK_XAREAR'															, .T. }, ; //X3_CAMPO
	{ 'N'																	, .T. }, ; //X3_TIPO
	{ 7																		, .T. }, ; //X3_TAMANHO
	{ 2																		, .T. }, ; //X3_DECIMAL
	{ 'Area Arrend'															, .T. }, ; //X3_TITULO
	{ 'Area Arrend'															, .T. }, ; //X3_TITSPA
	{ 'Area Arrend'															, .T. }, ; //X3_TITENG
	{ 'Area Arrend'															, .T. }, ; //X3_DESCRIC
	{ 'Area Arrend'															, .T. }, ; //X3_DESCSPA
	{ 'Area Arrend'															, .T. }, ; //X3_DESCENG
	{ '@E 9,999.99'															, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ 'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ '  x x'																, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '  x'																	, .T. }, ; //X3_OBRIGAT
	{ 'U_TvAgricValid("VMJ_AREARR")'										, .T. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .T. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ ''																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ '2'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME


//
// Atualizando dicionário
//
nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

aSort( aSX3,,, { |x,y| x[nPosArq][1]+x[nPosOrd][1]+x[nPosCpo][1] < y[nPosArq][1]+y[nPosOrd][1]+y[nPosCpo][1] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajusta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG][1] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG][1] ) )
			If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
				aSX3[nI][nPosTam][1] := SXG->XG_SIZE
				AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
				AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
				" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq][1] $ cAlias )
		cAlias += aSX3[nI][nPosArq][1] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq][1] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo][1], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq][1] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq][1]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

			ElseIf aEstrut[nJ][2] > 0
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] ) )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo][1] )

	Else

		//
		// Verifica se o campo faz parte de um grupo e ajsuta tamanho
		//
		If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG][1]
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( SX3->X3_GRPSXG ) )
				If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
					aSX3[nI][nPosTam][1] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
					AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF + ;
					"   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF )
				EndIf
			EndIf
		EndIf

		//
		// Verifica todos os campos
		//
		For nJ := 1 To Len( aSX3[nI] )

			//
			// Se o campo estiver diferente da estrutura
			//
			If aSX3[nI][nJ][2]
				cX3Campo := AllTrim( aEstrut[nJ][1] )
				cX3Dado  := SX3->( FieldGet( aEstrut[nJ][2] ) )

				If  aEstrut[nJ][2] > 0 .AND. ;
					PadR( StrTran( AllToChar( cX3Dado ), " ", "" ), 250 ) <> ;
					PadR( StrTran( AllToChar( aSX3[nI][nJ][1] ), " ", "" ), 250 ) .AND. ;
					!cX3Campo == "X3_ORDEM"

					cMsg := "O campo " + aSX3[nI][nPosCpo][1] + " está com o " + cX3Campo + ;
					" com o conteúdo" + CRLF + ;
					"[" + RTrim( AllToChar( cX3Dado ) ) + "]" + CRLF + ;
					"que será substituído pelo NOVO conteúdo" + CRLF + ;
					"[" + RTrim( AllToChar( aSX3[nI][nJ][1] ) ) + "]" + CRLF + ;
					"Deseja substituir ? "

					If      lTodosSim
						nOpcA := 1
					ElseIf  lTodosNao
						nOpcA := 2
					Else
						nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SX3" )
						lTodosSim := ( nOpcA == 3 )
						lTodosNao := ( nOpcA == 4 )

						If lTodosSim
							nOpcA := 1
							lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SX3 e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SX3 que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
						EndIf

					EndIf

					If nOpcA == 1
						AutoGrLog( "Alterado campo " + aSX3[nI][nPosCpo][1] + CRLF + ;
						"   " + PadR( cX3Campo, 10 ) + " de [" + AllToChar( cX3Dado ) + "]" + CRLF + ;
						"            para [" + AllToChar( aSX3[nI][nJ][1] )           + "]" + CRLF )

						RecLock( "SX3", .F. )
						FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] )
						MsUnLock()
					EndIf

				EndIf

			EndIf

		Next

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3) ..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX

Função de processamento da gravação do SIX - Indices

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
Local aEstrut   := {}
Local aSIX      := {}
Local lAlt      := .F.
Local lDelInd   := .F.
Local nI        := 0
Local nJ        := 0

AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
             "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

//
// Tabela VMJ
//
aAdd( aSIX, { ;
	'VMJ'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'VMJ_FILIAL+VMJ_CODCLI+VMJ_XLOJA+VMJ_CODSEQ'							, ; //CHAVE
	'Cliente + Loja + Sequencial'											, ; //DESCRICAO
	'Cliente + Loja + Sequencial'											, ; //DESCSPA
	'Cliente + Loja + Sequencial'											, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	'VMJAUX2'																, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela VMK
//
aAdd( aSIX, { ;
	'VMK'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'VMK_FILIAL+VMK_CODCLI+VMK_XLOJA+VMK_PAISEQ+VMK_CODSEQ+VMK_CODCUL+VMK_ANO'	, ; //CHAVE
	'Cliente + Loja + Propr.Agric. + Sequencial + Cod Cultura + Ano Produca'	, ; //DESCRICAO
	'Cliente + Loja + Propr.Agric. + Sequencial + Cod Cultura + Ano Produca'	, ; //DESCSPA
	'Cliente + Loja + Propr.Agric. + Sequencial + Cod Cultura + Ano Produca'	, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	'VMKAUX2'																, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSIX ) )

dbSelectArea( "SIX" )
SIX->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSIX )

	lAlt    := .F.
	lDelInd := .F.

	If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
		AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
	Else
		lAlt := .T.
		aAdd( aArqUpd, aSIX[nI][1] )
		If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
		    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
			AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
			lDelInd := .T. // Se for alteração precisa apagar o indice do banco
		EndIf
	EndIf

	RecLock( "SIX", !lAlt )
	For nJ := 1 To Len( aSIX[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
		EndIf
	Next nJ
	MsUnLock()

	dbCommit()

	If lDelInd
		TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
	EndIf

	oProcess:IncRegua2( "Atualizando índices ..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6

Função de processamento da gravação do SX6 - Parâmetros

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
Local aEstrut   := {}
Local aSX6      := {}
Local cAlias    := ""
Local cMsg      := ""
Local lContinua := .T.
Local lReclock  := .T.
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nTamFil   := Len( SX6->X6_FIL )
Local nTamVar   := Len( SX6->X6_VAR )

AutoGrLog( "Ínicio da Atualização" + " SX6" + CRLF )

aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
             "X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
             "X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
             "X6_PYME"   }

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_APIBB'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'SBX - SandBox ambiente de Desenvolvimento'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'HML- Homologacao ambiente de Validacao'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'PRD - Producao, ambiente de Producao'									, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'SBX'																	, ; //X6_CONTEUD
	'SBX'																	, ; //X6_CONTSPA
	'SBX'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_APPKEY'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Api Banco do Brasil Key dev'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'6fc60c9bfc26e2657b0e27f4aa7b6395'										, ; //X6_CONTEUD
	'6fc60c9bfc26e2657b0e27f4aa7b6395'										, ; //X6_CONTSPA
	'6fc60c9bfc26e2657b0e27f4aa7b6395'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_CLIID'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Api Banco do Brasil informar o ID Client'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'eyJpZCI6Ijk4ZTViNDU5LTFjMmItNDIxYy1hZjg4LTk4NDE5ZGZiZTlkNiIsImNvZGlnb1B1YmxpY2Fkb3IiOjAsImNvZGlnb1NvZnR3YXJlIjo2Mzk0MSwic2VxdWVuY2lhbEluc3RhbGFjYW8iOjF9', ; //X6_CONTEUD
	'eyJpZCI6Ijk4ZTViNDU5LTFjMmItNDIxYy1hZjg4LTk4NDE5ZGZiZTlkNiIsImNvZGlnb1B1YmxpY2Fkb3IiOjAsImNvZGlnb1NvZnR3YXJlIjo2Mzk0MSwic2VxdWVuY2lhbEluc3RhbGFjYW8iOjF9', ; //X6_CONTSPA
	'eyJpZCI6Ijk4ZTViNDU5LTFjMmItNDIxYy1hZjg4LTk4NDE5ZGZiZTlkNiIsImNvZGlnb1B1YmxpY2Fkb3IiOjAsImNvZGlnb1NvZnR3YXJlIjo2Mzk0MSwic2VxdWVuY2lhbEluc3RhbGFjYW8iOjF9', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_CLISEC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Api Banco do Brasil Secret ID'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'eyJpZCI6Ijc0MGE5NDctMWY0OC00YjQzIiwiY29kaWdvUHVibGljYWRvciI6MCwiY29kaWdvU29mdHdhcmUiOjYzOTQxLCJzZXF1ZW5jaWFsSW5zdGFsYWNhbyI6MSwic2VxdWVuY2lhbENyZWRlbmNpYWwiOjEsImFtYmllbnRlIjoiaG9tb2xvZ2FjYW8iLCJpYXQiOjE2ODYwNDkyOTY3MzR9', ; //X6_CONTEUD
	'eyJpZCI6Ijc0MGE5NDctMWY0OC00YjQzIiwiY29kaWdvUHVibGljYWRvciI6MCwiY29kaWdvU29mdHdhcmUiOjYzOTQxLCJzZXF1ZW5jaWFsSW5zdGFsYWNhbyI6MSwic2VxdWVuY2lhbENyZWRlbmNpYWwiOjEsImFtYmllbnRlIjoiaG9tb2xvZ2FjYW8iLCJpYXQiOjE2ODYwNDkyOTY3MzR9', ; //X6_CONTSPA
	'eyJpZCI6Ijc0MGE5NDctMWY0OC00YjQzIiwiY29kaWdvUHVibGljYWRvciI6MCwiY29kaWdvU29mdHdhcmUiOjYzOTQxLCJzZXF1ZW5jaWFsSW5zdGFsYWNhbyI6MSwic2VxdWVuY2lhbENyZWRlbmNpYWwiOjEsImFtYmllbnRlIjoiaG9tb2xvZ2FjYW8iLCJpYXQiOjE2ODYwNDkyOTY3MzR9', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_URLHML'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Url Api Banco do Brasil Homologacao'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'https://api.hm.bb.com.br'												, ; //X6_CONTEUD
	'https://api.hm.bb.com.br'												, ; //X6_CONTSPA
	'https://api.hm.bb.com.br'												, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_URLPRD'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Url Api Banco do Brasil Producao'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'https://api.bb.com.br'													, ; //X6_CONTEUD
	'https://api.bb.com.br'													, ; //X6_CONTSPA
	'https://api.bb.com.br'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'BB_URLSBX'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Url Api Banco do Brazil SandBox'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'https://api.sandbox.bb.com.br'											, ; //X6_CONTEUD
	'https://api.sandbox.bb.com.br'											, ; //X6_CONTSPA
	'https://api.sandbox.bb.com.br'											, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'CV_TPCAD'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Indica tipo de produto que gerar SBZ no cadastrado'					, ; //X6_DESCRIC
	'Indica tipo de produto que gerar SBZ no cadastrado'					, ; //X6_DSCSPA
	'Indica tipo de produto que gerar SBZ no cadastrado'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'OI;MP;MC;KT;MN;AI;EM;SV;PA;ME;GG;PV;IA;MO'								, ; //X6_CONTEUD
	'OI;MP;MC;KT;MN;AI;EM;SV;PA;ME;GG;PV;IA;MO'								, ; //X6_CONTSPA
	'OI;MP;MC;KT;MN;AI;EM;SV;PA;ME;GG;PV;IA;MO'								, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ES_NEGOCIA'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	''																		, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'S'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ES_RECIBO'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Numero Sequencia Recibo'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0000000005'															, ; //X6_CONTEUD
	'0000000005'															, ; //X6_CONTSPA
	'0000000005'															, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ES_SEQBDN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Ultimo Sequencial do Arquivo BDN referente'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'ao recibo de pagamento eletronico.'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000000024'																, ; //X6_CONTEUD
	'000000024'																, ; //X6_CONTSPA
	'000000024'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'FB_URLCOM'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL do WSDL para cotacoes Comlink'										, ; //X6_DESCRIC
	'URL do WSDL para cotacoes Comlink'										, ; //X6_DSCSPA
	'URL do WSDL para cotacoes Comlink'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://www.comlink.com.br/ws/integracaofornecedor/v1.4/wscot.asmx?WSDL'	, ; //X6_CONTEUD
	'http://www.comlink.com.br/ws/integracaofornecedor/v1.4/wscot.asmx?WSDL'	, ; //X6_CONTSPA
	'http://www.comlink.com.br/ws/integracaofornecedor/v1.4/wscot.asmx?WSDL'	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'FB_URLSRV'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL do WSDL para servicos Comlink'										, ; //X6_DESCRIC
	'URL do WSDL para servicos Comlink'										, ; //X6_DSCSPA
	'URL do WSDL para servicos Comlink'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://www.comlink.com.br/ws/integracaofornecedor/v1.4/wsserv.asmx?WSDL'	, ; //X6_CONTEUD
	'http://www.comlink.com.br/ws/integracaofornecedor/v1.4/wsserv.asmx?WSDL'	, ; //X6_CONTSPA
	'http://www.comlink.com.br/ws/integracaofornecedor/v1.4/wsserv.asmx?WSDL'	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'FL_EXCREGC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuários autorizados a realizar exclusão de regist'					, ; //X6_DESCRIC
	'Usuários autorizados a realizar exclusão de regist'					, ; //X6_DSCSPA
	'Usuários autorizados a realizar exclusão de regist'					, ; //X6_DSCENG
	'ro'																	, ; //X6_DESC1
	'ro'																	, ; //X6_DSCSPA1
	'ro'																	, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000897;000871;001100;'													, ; //X6_CONTEUD
	'000897;000871;001100;'													, ; //X6_CONTSPA
	'000897;000871;001100;'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'FS_GCTCOT'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo Contrato para cotacao'											, ; //X6_DESCRIC
	'Tipo Contrato para cotizacion'											, ; //X6_DSCSPA
	'Contract type for quotation'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'001'																	, ; //X6_CONTEUD
	'001'																	, ; //X6_CONTSPA
	'001'																	, ; //X6_CONTENG
	'S'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	'001'																	, ; //X6_DEFPOR
	'001'																	, ; //X6_DEFSPA
	'001'																	, ; //X6_DEFENG
	'S'																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_A190REF'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Reprocessar o custo de entrada (MATA190)'								, ; //X6_DESCRIC
	'Reprocesar el costo de entrada (MATA190)'								, ; //X6_DSCSPA
	'Reprocess the inbound cost (MATA190)'									, ; //X6_DSCENG
	'através das referencias fiscais.'										, ; //X6_DESC1
	'mediante referencias fiscales.'										, ; //X6_DSCSPA1
	'through fiscal references.'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_A330GRV'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Indica se todos produtos/armazéns terão seu saldo'						, ; //X6_DESCRIC
	'Indica si todo producto/almacén tendrá su saldo'						, ; //X6_DSCSPA
	'Indicates if all products/warehouses will have the'					, ; //X6_DSCENG
	'inicial calculado no processamento do Custo Médio'						, ; //X6_DESC1
	'inicial calculado en procesamiento de Costo medio'						, ; //X6_DSCSPA1
	'initial balance calculated in the Average Cost pro'					, ; //X6_DSCENG1
	'T= Todos registros F=Apenas produtos com saldo/Mov'					, ; //X6_DESC2
	'T= Todos registros F=Solo productos con saldo/Mov'						, ; //X6_DSCSPA2
	'cessing.T=All records F=Only prod with bal/mov'						, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_BACKEND'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Endereço REST para execução de telas PO-UI (APP'						, ; //X6_DESCRIC
	'Dirección REST para ejecutar pantallas PO-UI (APP'						, ; //X6_DSCSPA
	'REST address for running PO-UI screens (APP'							, ; //X6_DSCENG
	'função FwCallApp).'													, ; //X6_DESC1
	'función FwCallApp).'													, ; //X6_DSCSPA1
	'function FwCallApp).'													, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://10.0.0.228:8086/rest'											, ; //X6_CONTEUD
	'http://10.0.0.228:8086/rest'											, ; //X6_CONTSPA
	'http://10.0.0.228:8086/rest'											, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_COFLSPD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Informe .F. para não concatenar o código da filial'					, ; //X6_DESCRIC
	'Informe .F. para no concatenar código de Suc.'							, ; //X6_DSCSPA
	'Enter .F. to not concatenate the branch code'							, ; //X6_DSCENG
	' nos códigos dos registros do SPED Fiscal e SPED C'					, ; //X6_DESC1
	'en códigos de registros del SPED Fiscal y SPED'						, ; //X6_DSCSPA1
	'in the Contributions SPED and Tax SPED'								, ; //X6_DSCENG1
	'ontribuições'															, ; //X6_DESC2
	'Aportes'																, ; //X6_DSCSPA2
	'record codes.'															, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_CTBSPRC'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita procedure dinamica na escrituração'							, ; //X6_DESCRIC
	'Habilita procedure dinámica en registro'								, ; //X6_DSCSPA
	'Enable dynamic procedure in'											, ; //X6_DSCENG
	'contábil'																, ; //X6_DESC1
	'contable'																, ; //X6_DSCSPA1
	'bookkeeping.'															, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_CXFIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caixa Geral Financeiro'												, ; //X6_DESCRIC
	'Caja General Financiero'												, ; //X6_DSCSPA
	'Main Financial Cash'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'CX1/00001/0000000001'													, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_DEVCFOP'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Para NF Devolução na versão 3.10,permitido informa'					, ; //X6_DESCRIC
	'Para Fact Devolucion en version 3.10 permitido inf'					, ; //X6_DSCSPA
	'For NF Return in version 3.10 allowed enter'							, ; //X6_DSCENG
	'CFOP diferente do Anexo XI.01 da NT 2013.005.v1.03'					, ; //X6_DESC1
	'CFOP diferente de Adj. XI.01 de NT 2013.005.v1.03'						, ; //X6_DSCSPA1
	'CFOP different from Attachment XI.01 of NT 2013.00'					, ; //X6_DSCENG1
	'para ser gerada tag finnfe igual a 1 (normal).'						, ; //X6_DESC2
	'para generarse la tag finnfe igual a 1 (normal).'						, ; //X6_DSCSPA2
	'to be generated tag finnfe equal to 1 (normal)'						, ; //X6_DSCENG2
	'1901;1914;5914;1913,5912;5913;6913;5915;5916;6916;1916;2916;2913;2949;1949;1909;1415;2553;5902;5909;5949;6949;1908;5908;1910;6902', ; //X6_CONTEUD
	'1901;1914;5914;1913,5912;5913;6913;5915;5916;6916;1916;2916;2913;2949;1949;1909;1415;2553;5902;5909;5949;6949;1908;5908;1910;6902', ; //X6_CONTSPA
	'1901;1914;5914;1913,5912;5913;6913;5915;5916;6916;1916;2916;2913;2949;1949;1909;1415;2553;5902;5909;5949;6949;1908;5908;1910;6902', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_ESOCDIS'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Define se as informações de dissidio serão geradas'					, ; //X6_DESCRIC
	'Define si la Inform. del Acuerdo Lab. se generará'						, ; //X6_DSCSPA
	'Defines if information of collective agreement wil'					, ; //X6_DSCENG
	'nas informações de período anterior (.T.)'								, ; //X6_DESC1
	'en la información del período anterior (.T.)'							, ; //X6_DSCSPA1
	'l be generated in the information from the previou'					, ; //X6_DSCENG1
	'ou no período atual (.F.)'												, ; //X6_DESC2
	'o en el período actual (.F.)'											, ; //X6_DSCSPA2
	's (.T.) or the current period (.F)'									, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_ESPOBG'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Determina se o campo F1_ESPECIE deve ser'								, ; //X6_DESCRIC
	'Determina si el campo F1_ESPECIE debe ser'								, ; //X6_DSCSPA
	'Determines whether field F1_ESPECIE must be'							, ; //X6_DSCENG
	'obrigatório no cabeçalho do Documento de Entrada.'						, ; //X6_DESC1
	'obligatorio en el encabezado del Documento de Entr'					, ; //X6_DSCSPA1
	'mandatory in Inbound Document header;'									, ; //X6_DSCENG1
	'(.T.) Sim (.F.) Não;'													, ; //X6_DESC2
	'ada. (.T.) Sí (.F.) No.'												, ; //X6_DSCSPA2
	'(.T.) Yes (.F.) No;'													, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_GCTPURL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	''																		, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://10.0.0.228:8086/'												, ; //X6_CONTEUD
	'http://10.0.0.228:8086/'												, ; //X6_CONTSPA
	'http://10.0.0.228:8086/'												, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_GRUPCOB'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Indica se leva para o Xml o grupo de cobrança'							, ; //X6_DESCRIC
	'Indica si lleva el grupo de cobranza al Xml'							, ; //X6_DSCSPA
	'Indicates whether to take the collection group to'						, ; //X6_DSCENG
	'Sendo .T.=Será levado o grupo de cobrança.'							, ; //X6_DESC1
	'Siendo .T.=Se llevará el grupo de cobranza.'							, ; //X6_DSCSPA1
	'the Xml Being .T.=Takes collection group'								, ; //X6_DSCENG1
	'Sendo .F.= Não será levado o grupo de cobrança.'						, ; //X6_DESC2
	'Siendo .F.= No se llevará el grupo de cobranza.'						, ; //X6_DSCSPA2
	'Being .F.=Does not take collection group'								, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_JURFAT'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Indica se os juros do titulo original compoe o'						, ; //X6_DESCRIC
	'Indica se os juros do titulo original compoe o'						, ; //X6_DSCSPA
	'Indica se os juros do titulo original compoe o'						, ; //X6_DSCENG
	'valor da nova fatura'													, ; //X6_DESC1
	'valor da nova fatura'													, ; //X6_DSCSPA1
	'valor da nova fatura'													, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_LBVACB'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Valida vendas com valor abaixo do custo médio'							, ; //X6_DESCRIC
	'Valida ventas con valor inferior al costo promedio'					, ; //X6_DSCSPA
	'Validate sales with value below average cost'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'S'																		, ; //X6_CONTEUD
	'S'																		, ; //X6_CONTSPA
	'S'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_LJMLTRC'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Informa se esta habilitado o recebimento de titulo'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'de diversos clientes no Venda Assistida.'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_LJTPNFE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de título a receber considerado Fatura'							, ; //X6_DESCRIC
	'Tipo de título por cobrar considerado Factura'							, ; //X6_DSCSPA
	'Type of bill receivable considered Invoice'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'DP,NF,CH,CC,CD,R$,BOL,SDZ,PIX,PD'										, ; //X6_CONTEUD
	'DP,NF,CH,CC,CD,R$,BOL,SDZ,PIX,PD'										, ; //X6_CONTSPA
	'DP,NF,CH,CC,CD,R$,BOL,SDZ,PIX,PD'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_M330TRF'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilta busca custo orig transf. filiais em'							, ; //X6_DESCRIC
	'Habilta búsqueda costo orig transf. sucursales en'						, ; //X6_DSCSPA
	'Enables search orig cost transf branches in'							, ; //X6_DSCENG
	'Periodos diferentes'													, ; //X6_DESC1
	'Períodos diferentes'													, ; //X6_DSCSPA1
	'different periods'														, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MFATIPR'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Mensagem do faturamento para descrição do meio de'						, ; //X6_DESCRIC
	'Mensaje de facturación p/descripción del medio de'						, ; //X6_DSCSPA
	'Message from billing for description of the paymen'					, ; //X6_DSCENG
	'pagamento referente a tag xPag da NT 2020.006.'						, ; //X6_DESC1
	'pago referente a la tag vs.Pag de NT 2020.006.'						, ; //X6_DSCSPA1
	'method referring to xPag tag from NT 2020.006.'						, ; //X6_DSCENG1
	'Parâmetro macroexecutado, deve estar entre aspas'						, ; //X6_DESC2
	'Parámetro macroejecutado, debe estar entre comilla'					, ; //X6_DSCSPA2
	'Parameter macro-run, must be between quotes'							, ; //X6_DSCENG2
	'"Negociacao Futura"'													, ; //X6_CONTEUD
	'"Negociacao Futura"'													, ; //X6_CONTSPA
	'"Negociacao Futura"'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0072'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Inventario de Pecas – Filtro do Produto'								, ; //X6_DESCRIC
	'Inventario de piezas–Filtro del producto'								, ; //X6_DSCSPA
	'Parts Inventory - Product Filter'										, ; //X6_DSCENG
	'0=sem filtro / 1=Marca/Linha/Familia /'								, ; //X6_DESC1
	'0=sin filtro / 1=Marca/Línea/Familia /'								, ; //X6_DSCSPA1
	'0=no filter / 1=Brand/Line/Family /'									, ; //X6_DSCENG1
	'2=Familia/Grupo/SubGrupo'												, ; //X6_DESC2
	'2=Familia/Grupo/Subgrupo'												, ; //X6_DSCSPA2
	'2=Family/Group/SubGroup'												, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0088'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail origem do JDPRISM'												, ; //X6_DESCRIC
	'E-mail origen de JDPRISM'												, ; //X6_DSCSPA
	'Source e-mail of JDPRISM'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'sistemastv@terraverdeagro.com.br'										, ; //X6_CONTEUD
	'sistemastv@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'sistemastv@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0089'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail destinatarios JDPRISM'											, ; //X6_DESCRIC
	'E-mail destinatarios JDPRISM'											, ; //X6_DSCSPA
	'JDPRISM recipients e-mail'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'jdprisma@terraverdeagro.com.br'										, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0111'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Gera apontamento no intervalo do período. Opções'						, ; //X6_DESCRIC
	'Genera apunte en intervalo del período. Opciones'						, ; //X6_DSCSPA
	'Generates an annotation in period interval. Option'					, ; //X6_DSCENG
	'0=Não apont. / 1=Aponta. Formato: xxx, sendo'							, ; //X6_DESC1
	'0=No apunta / 1=Apunta. Formato: xxx, siendo'							, ; //X6_DSCSPA1
	'0=Does not annotate/1=Annotates Format: xxx, being'					, ; //X6_DSCENG1
	'1º=Intervalo 1, 2º=Refeição, 3º Intervalo 2'							, ; //X6_DESC2
	'1º=Intervalo 1, 2º=Comida, 3º Intervalo 2'								, ; //X6_DSCSPA2
	'1st=Interval 1,2nd=Meal,3rd=Interval 2'								, ; //X6_DSCENG2
	'010'																	, ; //X6_CONTEUD
	'010'																	, ; //X6_CONTSPA
	'010'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0113'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agrega/Desagrega - Tipo Doc. Gerar? ( 1=Sempre NF'						, ; //X6_DESCRIC
	'¿Agrega/Desagrega - Generar Tipo Doc.? ( 1=Siempre'					, ; //X6_DSCSPA
	'Aggreg/Desaggr - Doc Type Gener? (1=Always'							, ; //X6_DSCENG
	'2=Sempre Mov.Interna, 3=Usuário seleciona o tipo )'					, ; //X6_DESC1
	'2=Siempre Mov.Interno, 3=Usuario selecciona el tip'					, ; //X6_DSCSPA1
	'2=Always Int Movem=User selects type )'								, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'2'																		, ; //X6_CONTEUD
	'2'																		, ; //X6_CONTSPA
	'2'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0114'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agrega/Desagrega - Tipo Movimentação Interna de'						, ; //X6_DESCRIC
	'Agrega/Desagrega - Tipo de movimiento interno de'						, ; //X6_DSCSPA
	'Aggreg/Desaggr - Inbound Internal Movement'							, ; //X6_DSCENG
	'Entrada'																, ; //X6_DESC1
	'entrada'																, ; //X6_DSCSPA1
	'Type'																	, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'201'																	, ; //X6_CONTEUD
	'201'																	, ; //X6_CONTSPA
	'201'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0115'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agrega/Desagrega - Tipo Movimentação Interna de'						, ; //X6_DESCRIC
	'Agrega/Desagrega - Tipo de movimiento interno de'						, ; //X6_DSCSPA
	'Aggreg/Desaggr - Outbound Internal Movement'							, ; //X6_DSCENG
	'Saída'																	, ; //X6_DESC1
	'salida'																, ; //X6_DSCSPA1
	'Type'																	, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'601'																	, ; //X6_CONTEUD
	'601'																	, ; //X6_CONTSPA
	'601'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0162'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Levanta Bonus automaticamente na Venda Veic./Máq.'						, ; //X6_DESCRIC
	'Levanta bonos automáticamente en Venta Vehíc./Máq.'					, ; //X6_DSCSPA
	'Raise Bonus Automatically and in Veh./Mach.'							, ; //X6_DSCENG
	'do Atendimento ( 0=Não / 1=Lev.apagando existentes'					, ; //X6_DESC1
	'de Atención ( 0=No / 1=Lev.Borrando existentes'						, ; //X6_DSCSPA1
	'Sales of Service (0=No/1=Raise deleting existing'						, ; //X6_DSCENG1
	'/ 2=Lev.NAO apagando existentes )'										, ; //X6_DESC2
	'/ 2=Lev.NO borrando existentes )'										, ; //X6_DSCSPA2
	'/ 2=Raise NOT deleting existing)'										, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0163'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Levanta Incentivos automaticamente na Finalização'						, ; //X6_DESCRIC
	'Levanta incentivos automáticamente al finalizar'						, ; //X6_DSCSPA
	'Raise incentive automatically and Finalization'						, ; //X6_DSCENG
	'do Fat.Direto ( 0=Não / 1=Sim )'										, ; //X6_DESC1
	'la Fact.Directa ( 0=No / 1=Sí )'										, ; //X6_DSCSPA1
	'of Direct Inv. (0=No/1=Yes)'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0165'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizacao da Conf.Maquinas - selecionar mais de'						, ; //X6_DESCRIC
	'Utilización de Conf.Máquinas - ¿seleccionar más de'					, ; //X6_DSCSPA
	'Use of Machine Conf. - Select more than'								, ; //X6_DSCENG
	'um item por agrupador?'												, ; //X6_DESC1
	'un ítem por agrupador?'												, ; //X6_DSCSPA1
	'one item per consolidator?'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	'0'																		, ; //X6_CONTSPA
	'0'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0166'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Gravação da configuração basica da máquina.'							, ; //X6_DESCRIC
	'Grabación de configuración básica de la máquina.'						, ; //X6_DSCSPA
	'Recording of basic configuration of machine.'							, ; //X6_DSCENG
	'0=Descrição Opcional (padrão) / 1=Opcional JD /'						, ; //X6_DESC1
	'0=Descripción opcional (estándar) / 1=Opcional JD'						, ; //X6_DSCSPA1
	'0=Optional description (default) / 1=Optional JD /'					, ; //X6_DSCENG1
	'2=Descrição Opcional Usuário'											, ; //X6_DESC2
	'2=Descripción opcional usuario'										, ; //X6_DSCSPA2
	'2=User Optional Description'											, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	'0'																		, ; //X6_CONTSPA
	'0'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0167'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Configuração de Veículos/Máquinas, gravar o Valor'						, ; //X6_DESCRIC
	'Configuración vehículos/máquinas, ¿grabar el valor'					, ; //X6_DSCSPA
	'Vehicles/Machines Configuration. Save the value'						, ; //X6_DSCENG
	'Sugerido? 1=Sim (default) / 0=Não'										, ; //X6_DESC1
	'sugerido? 1=Sí (estándar) / 0=No'										, ; //X6_DSCSPA1
	'suggested? 1=Yes (default) / 0=No'										, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1'																		, ; //X6_CONTEUD
	'1'																		, ; //X6_CONTSPA
	'1'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0168'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Trabalha com Pacote de Configurações.'									, ; //X6_DESCRIC
	'Trabaja con paquete de configuraciones.'								, ; //X6_DSCSPA
	'Work with Configuration Package.'										, ; //X6_DSCENG
	'0=Não / 1=Sim'															, ; //X6_DESC1
	'0=No / 1=Sí'															, ; //X6_DSCSPA1
	'0=No / 1=Yes'															, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	'0'																		, ; //X6_CONTSPA
	'0'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0169'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail destinatario ao alterar a Lista de Preços'						, ; //X6_DESCRIC
	'E-mail destinatario al modificar Lta de precios'						, ; //X6_DSCSPA
	'Recipient e-mail when changing Price List'								, ; //X6_DSCENG
	'dos Pacotes'															, ; //X6_DESC1
	'de los paquetes'														, ; //X6_DSCSPA1
	'of Packages'															, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'luisguilherme@terraverdeagro.com.br;rafaelfernandes@terraverdeagro.com.br;karenoliveira@terraverdeagro.com.br', ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	'luisguilherme@terraverdeagro.com.br;rafaelfernandes@terraverdeagro.com.br;karenoliveira@terraverdeagro.com.br', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0170'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Preços Pacotes - utilizar arredondamento (round)'						, ; //X6_DESCRIC
	'Precios paquetes - utilizar redondeo (round)'							, ; //X6_DSCSPA
	'Package Prices - use rounding'											, ; //X6_DSCENG
	'Exemplo: 2 = 2 casas decimais, 1 = 1 casa decimal'						, ; //X6_DESC1
	'Ejemplo: 2 = 2 decimales, 1 = 1 decimal'								, ; //X6_DSCSPA1
	'Example: 2 = 2 decimal places, 1 = 1 decimal place'					, ; //X6_DSCENG1
	'0 = valor sem decimal'													, ; //X6_DESC2
	'0 = valor sin decimal'													, ; //X6_DSCSPA2
	'0 = value without decimal places'										, ; //X6_DSCENG2
	'2'																		, ; //X6_CONTEUD
	'2'																		, ; //X6_CONTSPA
	'2'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0194'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utiliza Agrega/Desagrega Multieventos'									, ; //X6_DESCRIC
	'Utiliza Agrega/Desagrega multieventos'									, ; //X6_DSCSPA
	'Use multi-event Aggregate/Disaggregate'								, ; //X6_DSCENG
	'( 0 = Não / 1 = Sim )'													, ; //X6_DESC1
	'( 0 = No / 1 = Sí)'													, ; //X6_DSCSPA1
	'( 0 = No / 1 = Yes )'													, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1'																		, ; //X6_CONTEUD
	'1'																		, ; //X6_CONTSPA
	'1'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MIL0204'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'COLETOR VALIDAR ITENS SEM ENDERECO NA GUARDA DOS'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' ITENS ( 0=NAO VISUALIZA E NAO BLOQUEIA / 1=VISUAL'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'E NAO BLOQUEIA / 2=VISUALIZA E BLOQU'									, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'2'																		, ; //X6_CONTEUD
	'2'																		, ; //X6_CONTSPA
	'2'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_MPCSCLI'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Define se sincroniza os clientes no aplicativo'						, ; //X6_DESCRIC
	'Define si sincroniza clientes en aplicación'							, ; //X6_DSCSPA
	'Set whether to sync customers in app'									, ; //X6_DSCENG
	'Minha Prestação de Contas.'											, ; //X6_DESC1
	'Mi rendición de cuentas'												, ; //X6_DSCSPA1
	'My Rendering of Accounts.'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_PARTCC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Parts Advisor: centro de custo padrao para'							, ; //X6_DESCRIC
	'Parts Advisor: centro de custo padrao para'							, ; //X6_DSCSPA
	'Parts Advisor: centro de custo padrao para'							, ; //X6_DSCENG
	'aplicar o desconto parametrizado'										, ; //X6_DESC1
	'aplicar o desconto parametrizado'										, ; //X6_DSCSPA1
	'aplicar o desconto parametrizado'										, ; //X6_DSCENG1
	'na rotina Criterio de Desconto'										, ; //X6_DESC2
	'na rotina Criterio de Desconto'										, ; //X6_DSCSPA2
	'na rotina Criterio de Desconto'										, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_PARTSEN'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuario que vai executar o job do Advisor'								, ; //X6_DESCRIC
	'Usuario que vai executar o job do Advisor'								, ; //X6_DSCSPA
	'Usuario que vai executar o job do Advisor'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'TerraVerde@advisor123'													, ; //X6_CONTEUD
	'TerraVerde@advisor123'													, ; //X6_CONTSPA
	'TerraVerde@advisor123'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_PARTUSU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'senha do usuario que vai processar o schedule dos'						, ; //X6_DESCRIC
	'senha do usuario que vai processar o schedule dos'						, ; //X6_DSCSPA
	'senha do usuario que vai processar o schedule dos'						, ; //X6_DSCENG
	'que vai executar o Job de integracao do Advisor'						, ; //X6_DESC1
	'que vai executar o Job de integracao do Advisor'						, ; //X6_DSCSPA1
	'que vai executar o Job de integracao do Advisor'						, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'advisor'																, ; //X6_CONTEUD
	'advisor'																, ; //X6_CONTSPA
	'advisor'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_PCHABPG'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita utilização do pergunte MTR110 definido pa'					, ; //X6_DESCRIC
	'Habilita uso de pregunta MTR110 definida pa'							, ; //X6_DSCSPA
	'Enable the use of question MTR110 set for the logg'					, ; //X6_DSCENG
	'ra o usuario logado na impressao do relatorio MATR'					, ; //X6_DESC1
	'ra usuario conectado en Impres. de informe MATR'						, ; //X6_DSCSPA1
	'ed user in the MATR100 report printing via Deliv A'					, ; //X6_DSCENG1
	'110 via Browse do Pedido de Compra/Aut. Entrega'						, ; //X6_DESC2
	'110 vía Browse de Pedido de compra/Aut. Entrega'						, ; //X6_DSCSPA2
	'uth/Purchase Order browse'												, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_PORT671'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Indica se as alterações da portaria 671 estão habi'					, ; //X6_DESCRIC
	'Indica si los cambios de la resolución 671 están h'					, ; //X6_DSCSPA
	'Indicate if the changes in decree 671 are enabled'						, ; //X6_DSCENG
	'litadas no ambiente.'													, ; //X6_DESC1
	'litadas en el entorno.'												, ; //X6_DSCSPA1
	'in the environment.'													, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_R460TPC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Configuracao do custo de produtos em terceiros'						, ; //X6_DESCRIC
	'Configuración costo de productos en terceros'							, ; //X6_DSCSPA
	'Configuration of product cost in third parties'						, ; //X6_DSCENG
	'M=Custo médio ou R=Custo Remessa'										, ; //X6_DESC1
	'M=Costo medio o R=Costo remesa'										, ; //X6_DSCSPA1
	'M=Average Cost or R=Remittance Cost'									, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'R'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_SOMAVIS'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Indica se os Valores e as Médias do Aviso Prévio'						, ; //X6_DESCRIC
	'Indica si los Valores y los promedios del Aviso Pr'					, ; //X6_DSCSPA
	'Indicates whether Values and Averages of Prior Not'					, ; //X6_DSCENG
	'Indenizado serão considerados na remuneração'							, ; //X6_DESC1
	'evio indemnizado se considerará en la remuneración'					, ; //X6_DSCSPA1
	'compensated are considered in compensation'							, ; //X6_DSCENG1
	'ao gerar o arquivo da SEFIP.'											, ; //X6_DESC2
	'al generar el archivo de la SEFIP.'									, ; //X6_DSCSPA2
	'when generating SEFIP file.'											, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_SUGCOS'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Gera sugestao de compra das pecas sem saldo em'						, ; //X6_DESCRIC
	'Genera sugestion de compra de las piezas sin saldo'					, ; //X6_DSCSPA
	'Generate parts purchase suggestionwithout balance'						, ; //X6_DSCENG
	'estoque na exportacao do Orcamento para OS'							, ; //X6_DESC1
	'en stock en la exportacion del Presupuesto para OS'					, ; //X6_DSCSPA1
	'in stock on exporting Quotation to SO'									, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'S'																		, ; //X6_CONTEUD
	'S'																		, ; //X6_CONTSPA
	'S'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_TAFLPRC'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Dividendo utilizado no processo de multiThread Fis'					, ; //X6_DESCRIC
	'Dividendo usado en proceso de multiThread Fis'							, ; //X6_DSCSPA
	'Dividend used in the multiThread Fis process'							, ; //X6_DSCENG
	'exemplo se o parâmetro estiver configurado com 200'					, ; //X6_DESC1
	'ejemplo si el parámetro está configurado con 200'						, ; //X6_DSCSPA1
	'exampre if the parameter is set with 200'								, ; //X6_DSCENG1
	'o sistema vai pegar selecionar este numero de regi'					, ; //X6_DESC2
	'el sistema seleccionará este número de reg'							, ; //X6_DSCSPA2
	'the system will select ths rec number'									, ; //X6_DSCENG2
	'2000'																	, ; //X6_CONTEUD
	'2000'																	, ; //X6_CONTSPA
	'2000'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_TAFTRUB'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Define se o sistema deve validar a tag ideTabRubr'						, ; //X6_DESCRIC
	'Define si el sistema debe validar la tag ideTabRub'					, ; //X6_DSCSPA
	'Enter if system must validate tag ideTabRubr'							, ; //X6_DSCENG
	'na integracao dos xmls da folha de pagamento'							, ; //X6_DESC1
	'en la integración de los xmls de la planilla de pa'					, ; //X6_DSCSPA1
	'In payroll xml integration'											, ; //X6_DSCENG1
	'e-Social'																, ; //X6_DESC2
	'go e-Social'															, ; //X6_DSCSPA2
	'e-Social'																, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_TPAGCOM'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Mensagem para o tipo de pagamento 99 - Compras'						, ; //X6_DESCRIC
	'Mensaje para el tipo de pago 99 - Compras'								, ; //X6_DSCSPA
	'Message for payment type 99 - Purchases'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'"Negociacao Futura"'													, ; //X6_CONTEUD
	'"Negociacao Futura"'													, ; //X6_CONTSPA
	'"Negociacao Futura"'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_URLMSHP'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL Mashups'															, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://localhost:8055/TOTVSSoa.Host/SOAManager.svc'					, ; //X6_CONTEUD
	'http://localhost:8055/TOTVSSoa.Host/SOAManager.svc'					, ; //X6_CONTSPA
	'http://localhost:8055/TOTVSSoa.Host/SOAManager.svc'					, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_VMLOROF'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Verifica margem de lucro na exportação do'								, ; //X6_DESCRIC
	'Verifica margen de ganancia en la exportacion del'						, ; //X6_DSCSPA
	'Check profit margin on exporting'										, ; //X6_DSCENG
	'orçamento oficina'														, ; //X6_DESC1
	'presupuesto taller'													, ; //X6_DSCSPA1
	'repairshop quotation'													, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'S'																		, ; //X6_CONTEUD
	'S'																		, ; //X6_CONTSPA
	'S'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XDTCTP'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'DAta minima para vencimento contas a pagar'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20220908'																, ; //X6_CONTEUD
	'20220908'																, ; //X6_CONTSPA
	'20220908'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XJD0001'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Campo que sera usado como sku no projeto superacao'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XMAILPR'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios que recebem notificacao da'									, ; //X6_DESCRIC
	'Usuarios que recebem notificacao da'									, ; //X6_DSCSPA
	'Usuarios que recebem notificacao da'									, ; //X6_DSCENG
	'inclusao/ateracao do Cadastro de Produtos'								, ; //X6_DESC1
	'inclusao/ateracao do Cadastro de Produtos'								, ; //X6_DSCSPA1
	'inclusao/ateracao do Cadastro de Produtos'								, ; //X6_DSCENG1
	'Rotina Personalizada'													, ; //X6_DESC2
	'Rotina Personalizada'													, ; //X6_DSCSPA2
	'Rotina Personalizada'													, ; //X6_DSCENG2
	'valterbetiol@terraverdeagro.com.br'									, ; //X6_CONTEUD
	'almirsilva@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'almirsilva@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XMIL002'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo do titulo a ser emitido duplicata.'								, ; //X6_DESCRIC
	'Tipo do titulo a ser emitido duplicata.'								, ; //X6_DSCSPA
	'Tipo do titulo a ser emitido duplicata.'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'CC;CD;CH;CN;DH;DP;FI;JD;TF'											, ; //X6_CONTEUD
	'CC;CD;CH;CN;DH;DP;FI;JD;TF'											, ; //X6_CONTSPA
	'CC;CD;CH;CN;DH;DP;FI;JD;TF'											, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XMIL003'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Diretorio do logotipo.'												, ; //X6_DESCRIC
	'Diretorio do logotipo.'												, ; //X6_DSCSPA
	'Diretorio do logotipo.'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'imagem\JDFIN004.BMP'													, ; //X6_CONTEUD
	'imagem\JDFIN004.BMP'													, ; //X6_CONTSPA
	'imagem\JDFIN004.BMP'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XMLSIZE'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Parâmetro criado para aumentar a limitação de'							, ; //X6_DESCRIC
	'Parámetro creado para aumentar limitación de'							, ; //X6_DSCSPA
	'Parameter created to increase the limitation of'						, ; //X6_DSCENG
	'transmissão do XML que atualmente e de 500 KB.'						, ; //X6_DESC1
	'Transmisión del XML que actualmente es de 500 KB.'						, ; //X6_DSCSPA1
	'XML transmission, which is currently 500 KB.'							, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'500000'																, ; //X6_CONTEUD
	'500000'																, ; //X6_CONTSPA
	'500000'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_XQTCTP'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Parametro de quantidade de dias na trava de vencim'					, ; //X6_DESCRIC
	'Parametro de quantidade de dias na trava de vencim'					, ; //X6_DSCSPA
	'Parametro de quantidade de dias na trava de vencim'					, ; //X6_DSCENG
	'ento contas a pagar.'													, ; //X6_DESC1
	'ento contas a pagar.'													, ; //X6_DSCSPA1
	'ento contas a pagar.'													, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'5'																		, ; //X6_CONTEUD
	'5'																		, ; //X6_CONTSPA
	'5'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_X_UBLFM'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios que podem bloquear os periodos'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'renatooliveira\elisangelaanastacio'									, ; //X6_CONTEUD
	'elisangelaanastacio\renatooliveira'									, ; //X6_CONTSPA
	'elisangelaanastacio\renatooliveira'									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_Y00E4A'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Parametro Ativa ponto de entrada OX100E4A'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_ZUSRFEC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DESCRIC
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DSCSPA
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DSCENG
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DESC1
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DSCSPA1
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DSCENG1
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DESC2
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DSCSPA2
	'D do usuario autorizado a abrir e fechar o periodo'					, ; //X6_DSCENG2
	'000000/000015/000804'													, ; //X6_CONTEUD
	'000000/000015/000804'													, ; //X6_CONTSPA
	'000000/000015/000804'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_ZZPCMX'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Parcelamento maximo SIGALOJA'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'6'																		, ; //X6_CONTEUD
	'6'																		, ; //X6_CONTSPA
	'6'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'MV_ZZVLRM'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Vlr Min Parcelas SIGALOJA - PE LJVLDPGT'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'300'																	, ; //X6_CONTEUD
	'300'																	, ; //X6_CONTSPA
	'300'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'PM_USRGAR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'codigo do usuario do protheus  baixa BJD'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000076'																, ; //X6_CONTEUD
	'000076'																, ; //X6_CONTSPA
	'000076'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SDZ_NEWURL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Parametro Seedz'														, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'S'																		, ; //X6_CONTEUD
	'S'																		, ; //X6_CONTSPA
	'S'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SDZ_SENHA'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Senha Seedz'															, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'"T6fRx+uUSzne#G3g",'													, ; //X6_CONTEUD
	'"T6fRx+uUSzne#G3g",'													, ; //X6_CONTSPA
	'"T6fRx+uUSzne#G3g",'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SDZ_TIPAMB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Envia dados producao ou homologacao'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'H'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SDZ_USER'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'User Seez'																, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'"Evr^-xw#+^7H?UZV",'													, ; //X6_CONTEUD
	'"Evr^-xw#+^7H?UZV",'													, ; //X6_CONTSPA
	'"Evr^-xw#+^7H?UZV",'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_DESTSRV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Servico Padrao para Deslocamento (KM)'							, ; //X6_DESCRIC
	'Tipo de Servico Padrao para Deslocamento (KM)'							, ; //X6_DSCSPA
	'Tipo de Servico Padrao para Deslocamento (KM)'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'KM'																	, ; //X6_CONTEUD
	'KM'																	, ; //X6_CONTSPA
	'KM'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_MAILENV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'e-mail dos usuarios que serao notificados'								, ; //X6_DESCRIC
	'e-mail dos usuarios que serao notificados'								, ; //X6_DSCSPA
	'e-mail dos usuarios que serao notificados'								, ; //X6_DSCENG
	'quando houver problemas na integracao'									, ; //X6_DESC1
	'quando houver problemas na integracao'									, ; //X6_DSCSPA1
	'quando houver problemas na integracao'									, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_SRVDES'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Servico Padrao de Deslocamento  (KM)'						, ; //X6_DESCRIC
	'Codigo do Servico Padrao de Deslocamento  (KM)'						, ; //X6_DSCSPA
	'Codigo do Servico Padrao de Deslocamento  (KM)'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'KM'																	, ; //X6_CONTEUD
	'KM'																	, ; //X6_CONTSPA
	'KM'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_TDECSRV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DESCRIC
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DSCSPA
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'MODC1'																	, ; //X6_CONTEUD
	'MODC1'																	, ; //X6_CONTSPA
	'MODC1'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_TDETSRV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DESCRIC
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DSCSPA
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'SPO'																	, ; //X6_CONTEUD
	'SPO'																	, ; //X6_CONTSPA
	'SPO'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_TEMMIN'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Qtde minima de minutos a cobrar na OS'									, ; //X6_DESCRIC
	'Qtde minima de minutos a cobrar na OS'									, ; //X6_DSCSPA
	'Qtde minima de minutos a cobrar na OS'									, ; //X6_DSCENG
	'Abaixo desse valor nao cobra, mas aponta'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'5'																		, ; //X6_CONTEUD
	'5'																		, ; //X6_CONTSPA
	'5'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SO_USUAPP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Somente as horas apontadas por quem estava'						, ; //X6_DESCRIC
	'.T. = Somente as horas apontadas por quem estava'						, ; //X6_DSCSPA
	'.T. = Somente as horas apontadas por quem estava'						, ; //X6_DSCENG
	'logado no aplicativo serao cobradas'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_ACESS'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios permitidos para acessar determinados camp'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'nas tabelas do protheus'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000784;000400;000774;000031;000524;000791'								, ; //X6_CONTEUD
	'000784;000400;000774;000031;000524;000791'								, ; //X6_CONTSPA
	'000784;000400;000774;000031;000524;000791'								, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_BCOCART'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Banco;agencia;conta - liquidacao do cartao'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	';;'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_CLIECAR'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Cliente;Loja cartoes'													, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'482331;0001'															, ; //X6_CONTEUD
	'482331;0001'															, ; //X6_CONTSPA
	'482331;0001'															, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME


aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_HOFFIN'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'hora final aos sabados'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'hora final aos sabados'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'hora final aos sabados'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1200'																	, ; //X6_CONTEUD
	'1200'																	, ; //X6_CONTSPA
	'1200'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_HOFINI'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Hora inicial aos sabados'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Hora inicial aos sabados'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Hora inicial aos sabados'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'730'																	, ; //X6_CONTEUD
	'730'																	, ; //X6_CONTSPA
	'730'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_HORFIN'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Hora final em dias de semana'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Hora final em dias de semana'											, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Hora final em dias de semana'											, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1748'																	, ; //X6_CONTEUD
	'1748'																	, ; //X6_CONTSPA
	'1748'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_HORINI'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'inicial em dias de semana'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'inicial em dias de semana'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'inicial em dias de semana'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'730'																	, ; //X6_CONTEUD
	'730'																	, ; //X6_CONTSPA
	'730'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_HPAGEM'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo da Empresa'														, ; //X6_DESCRIC
	'Codigo da Empresa'														, ; //X6_DSCSPA
	'Codigo da Empresa'														, ; //X6_DSCENG
	'Codigo da Empresa'														, ; //X6_DESC1
	'Codigo da Empresa'														, ; //X6_DSCSPA1
	'Codigo da Empresa'														, ; //X6_DSCENG1
	'Codigo da Empresa'														, ; //X6_DESC2
	'Codigo da Empresa'														, ; //X6_DSCSPA2
	'Codigo da Empresa'														, ; //X6_DSCENG2
	'000011562'																, ; //X6_CONTEUD
	'000011562'																, ; //X6_CONTSPA
	'000011562'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_LIBTORC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios que podem liberar fat interno balcao'							, ; //X6_DESCRIC
	'Usuarios que podem liberar fat interno balcao'							, ; //X6_DSCSPA
	'   Usuarios que podem liberar fat interno balcao'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000004/000784/000021/000053'											, ; //X6_CONTEUD
	'000004/000784/000021/000053'											, ; //X6_CONTSPA
	'000004/000784/000021/000053'											, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_LIBTPEC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuario que podem liberar fat interno de pecas'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000004/000784/000053'													, ; //X6_CONTEUD
	'000004/000784/000053'													, ; //X6_CONTSPA
	'000004/000784/000053'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_LIBTSER'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuario que podem liberar fat interno de servicos'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000004/000784/000053'													, ; //X6_CONTEUD
	'000004/000784/000053'													, ; //X6_CONTSPA
	'000004/000784/000053'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_LIQCART'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Se habilita a liquidacao automatica .t./.f.'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_LTHPAG'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Numero Sequencial do Lote'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'592'																	, ; //X6_CONTEUD
	'592'																	, ; //X6_CONTSPA
	'592'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_MAILFI2'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	''																		, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'vivianealmeida@terraverdeagro.com.br;lucasedomingos@terraverdeagro.com.br'	, ; //X6_CONTEUD
	'vivianealmeida@terraverdeagro.com.br;lucasedomingos@terraverdeagro.com.br'	, ; //X6_CONTSPA
	'vivianealmeida@terraverdeagro.com.br;lucasedomingos@terraverdeagro.com.br'	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_NATCART'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Natureza p/ cartoes'													, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'11008'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_PMINVN'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Percentual minimo de lucro p/ venda de novos'							, ; //X6_DESCRIC
	'TV_SUPVENV'															, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'abaixo desta margem o sistema ira disparar'							, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'um e-mail ao gerente cadastrado no parametro'							, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0.85'																	, ; //X6_CONTEUD
	'0.85'																	, ; //X6_CONTSPA
	'0.85'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_PMINVU'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Percentual minimo de lucro p/ venda de usados'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0.97'																	, ; //X6_CONTEUD
	'0.97'																	, ; //X6_CONTSPA
	'0.97'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME



aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_STATENV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'O conteudo significa que o e-mail sera disparado'						, ; //X6_DESCRIC
	'F = "Finalizado" C = "Cancelado"'										, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'de acordo com a legenda: A = "Em Aberto"'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'O = "Pre-Aprovado" L = "Aprovado" R = "Reprovado"'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'F'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_SUPVENV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Email do(os) gerente(es) de vendas que'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'recebera aviso de venda com margem abaixo'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'do minimo estipulado'													, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'luisguilherme@terraverdeagro.com.br;rafaelfernandes@terraverdeagro.com.br'	, ; //X6_CONTEUD
	'luisguilherme@terraverdeagro.com.br'									, ; //X6_CONTSPA
	'luisguilherme@terraverdeagro.com.br'									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_TXCUSTP'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Custo de Pecas para comissao'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Custo de Pecas para comissao'											, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Custo de Pecas para comissao'											, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'4'																		, ; //X6_CONTEUD
	'4'																		, ; //X6_CONTSPA
	'4'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_TXCUSTV'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Custo de Veiculos para comissao'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' Custo de Veiculos para comissao'										, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Custo de Veiculos para comissao'										, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'10'																	, ; //X6_CONTEUD
	'10'																	, ; //X6_CONTSPA
	'10'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_USREXCL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuario com permissao de estornar'										, ; //X6_DESCRIC
	'docs na central xml'													, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000756/000751/000757/000871'											, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_VERCOMI'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo de usuario que pode ver o valor da comissao'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' no relatorio TVFIR01'													, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000000/000010'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_VLDDIGC'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Se valida a digitacao do codigo do cartao/seedz'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_VLDFINT'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Define se valida fat interno'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'TV_XPEDJD'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Parametro para definir se o APP Sibe vai ou nao ut'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'ilizar os pedidos da JonDeere'											, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'N'																		, ; //X6_CONTEUD
	'N'																		, ; //X6_CONTSPA
	'N'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXCP1'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita rotina de Anexos na Funcoes do CP'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'(FINA750)'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXCP2'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita rotina de Anexos na Baixas do CP'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'(FINA080)'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXCP3'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita rotina de Anexos na Faturas a Pagar'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'(FINA290)'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXCT1'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	' Habilita rotina de Anexos na Manut.de Contratos'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'(CNTA300)'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXESP'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caracteres Especiais a serem validados'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'"=/*-+,;()[]{}!@?#$%&"'												, ; //X6_CONTEUD
	'"=/*-+,;()[]{}!@?#$%&"'												, ; //X6_CONTSPA
	'"=/*-+,;()[]{}!@?#$%&"'												, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXMSG'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita a apresentacao de "Mensagem Informativa'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'de Caracteres Especiais"'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXNF1'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita rotina de Anexos na Pre-Nota'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' (MATA140)'															, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_ANEXNF2'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita rotina de Anexos da NF Entrada'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'(MATA103)'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_BCODIA'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Indica se deve usar o Banco do Dia ou pegar dos Pa'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'râmetros da rotina.'													, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_CLTRIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo de cliente TerraVerde para Fat. Interno'						, ; //X6_DESCRIC
	'Codigo de cliente TerraVerde para Fat. Interno'						, ; //X6_DSCSPA
	'Codigo de cliente TerraVerde para Fat. Interno'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'092825|282594|'														, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_EXCBLQ'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios que nao serao bloqueados na trava do'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'financeiro'															, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000754/000758/000880/000834/000528/000804/000755'						, ; //X6_CONTEUD
	'000754/000758/000880/000834/000528/000804/000755'						, ; //X6_CONTSPA
	'000754/000758/000880/000834/000528/000804/000755'						, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_GRPJON'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupos de Produtos para processamento da amarracao'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Produto x Fornecedor John Deere'										, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'JDPC,JDCO,JDLB,JDSI'													, ; //X6_CONTEUD
	'JDPC,JDCO,JDLB,JDSI'													, ; //X6_CONTSPA
	'JDPC,JDCO,JDLB,JDSI'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_LBLDR'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Parametro que ativa ou desativa o bloqueio de'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'lancamento de data retroativa'											, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PDABCL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Banco para impressao do boleto'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'237'																	, ; //X6_CONTEUD
	'341'																	, ; //X6_CONTSPA
	'237'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PDAGBL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agencia do banco na impressao do boleto personaliz'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'ado'																	, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'3371'																	, ; //X6_CONTEUD
	'3371'																	, ; //X6_CONTSPA
	'3371'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PDCTBL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Conta do banco quando do boleto personalizado'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'33220'																	, ; //X6_CONTEUD
	'33220'																	, ; //X6_CONTSPA
	'33220'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PDSUBL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'sub conta na imrpressao do boleto'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'001'																	, ; //X6_CONTEUD
	'001'																	, ; //X6_CONTSPA
	'001'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PONAP01'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Liga/Desliga execucao do ponto de entrada'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'# Utilizado PE PONAPO3 (ponto eletronico)'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PONAP02'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Informar os Eventos Hora Extra normal'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'# Utilizado PE PONAPO3 (ponto eletronico)'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'060,064,068,072'														, ; //X6_CONTEUD
	'060,064,068,072'														, ; //X6_CONTSPA
	'060,064,068,072'														, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PONAP03'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Informar os Eventos Hora Extra Noturno'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'# Utilizado PE PONAPO3 (ponto eletronico)'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'076,080,084,088'														, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PONAP04'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Informar data inicio novo calculo banco de horas'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'# Utilizado PE PONAPO3 (ponto eletronico)'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240116'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PONAP05'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Informar horario para inicio adicional noturno'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'# Utilizado PE PONAPO3 (ponto eletronico)'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'22.00'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_PONAP06'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Informar total horas considerar banco Feriado'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'# Utilizado PE PONAPO3 (ponto eletronico)'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'10.00'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_QFDBMH'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Numero de dias que iremos subtrair para geracao do'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'arquivo da Michellin - Final'											, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1'																		, ; //X6_CONTEUD
	'1'																		, ; //X6_CONTSPA
	'1'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_QIDBMH'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Numero de dias que iremos subtrair para geracao do'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' arquivo da Michellin - Inicio'										, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'7'																		, ; //X6_CONTEUD
	'7'																		, ; //X6_CONTSPA
	'7'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TIPSRV'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupos Excluidos do Relat. Capa de OS (IMPORD)'						, ; //X6_DESCRIC
	'Grupos Excluidos do Relat. Capa de OS (IMPORD)'						, ; //X6_DSCSPA
	'Grupos Excluidos do Relat. Capa de OS (IMPORD)'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS/CSIS/CSIP/FGP/FGS', ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TIPTEM'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupos que solicitam aprovacao no Fat. Interno'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS/CSIS/CSIP/C001', ; //X6_CONTEUD
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS/CSIS/CSIP/C001', ; //X6_CONTSPA
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS/CSIS/CSIP/C001', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TOPFILT'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	''																		, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'70'																	, ; //X6_CONTEUD
	'70'																	, ; //X6_CONTSPA
	'70'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TPFLLD'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipos de documentos na Liberação MT094FIL'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'SC|PC|NF|IP|MD|'														, ; //X6_CONTEUD
	'SC|PC|NF|IP|MD|'														, ; //X6_CONTSPA
	'SC|PC|NF|IP|MD|'														, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TPITEM'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupos que solicitam aprovacao no faturamento inte'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'rno'																	, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS', ; //X6_CONTEUD
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS/CSIS/CSIP', ; //X6_CONTSPA
	'AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TVLCDIA'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Dias de Validade da Aval. Credito de Cliente'							, ; //X6_DESCRIC
	'Dias de Validade da Aval. Credito de Cliente'							, ; //X6_DSCSPA
	'Dias de Validade da Aval. Credito de Cliente'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'5'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TVLCLIM'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Limite de Credito Padrao para novos clientes'							, ; //X6_DESCRIC
	'Limite de Credito Padrao para novos clientes'							, ; //X6_DSCSPA
	'Limite de Credito Padrao para novos clientes'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'3000'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TVLCUSR'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios que podem utilizar a Aval. Credito'							, ; //X6_DESCRIC
	'Usuarios que podem utilizar a Aval. Credito'							, ; //X6_DSCSPA
	'Usuarios que podem utilizar a Aval. Credito'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000925/000871/001047/001100/000880/001060/000399/000400/00758/000754/000989/000834/001012', ; //X6_CONTEUD
	'000925/000871/001047/001100/000880/001060/000399/000400/00758/000754/000989/000834/001012', ; //X6_CONTSPA
	'000925/000871/001047/001100/000880/001060/000399/000400/00758/000754/000989/000834/001012', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TVPGTO1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Cond. Pgto. A Vista pra cliente novo, com Risco D'						, ; //X6_DESCRIC
	'Cond. Pgto. A Vista pra cliente novo, com Risco D'						, ; //X6_DSCSPA
	'Cond. Pgto. A Vista pra cliente novo, com Risco D'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'500'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_TVPGTO2'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Cond. Pgto. Parcel. pra cliente novo, com Risco D'						, ; //X6_DESCRIC
	'Cond. Pgto. Parcel. pra cliente novo, com Risco D'						, ; //X6_DSCSPA
	'Cond. Pgto. Parcel. pra cliente novo, com Risco D'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'501'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_WFEMAIL'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Envia e-mail de aprovaçao do WF Fat Interno?'							, ; //X6_DESCRIC
	'Envia e-mail de aprovaçao do WF Fat Interno?'							, ; //X6_DSCSPA
	'Envia e-mail de aprovaçao do WF Fat Interno?'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'ZZ_XMAILAN'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DESCRIC
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DSCSPA
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DSCENG
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DESC1
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DSCSPA1
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DSCENG1
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DESC2
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DSCSPA2
	'Email que ira enviar o anexo do modulo GCT'							, ; //X6_DSCENG2
	'classificacaofiscal@terraverdeagro.com.br'								, ; //X6_CONTEUD
	'marcosbenatto@terraverdeagro.com.br'									, ; //X6_CONTSPA
	'marcosbenatto@terraverdeagro.com.br'									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'MV_XAGEN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agencia de recebimento'												, ; //X6_DESCRIC
	'Agencia de recebimento'												, ; //X6_DSCSPA
	'Agencia de recebimento'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'MV_XBANCO'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Canta de recebimento'													, ; //X6_DESCRIC
	'Canta de recebimento'													, ; //X6_DSCSPA
	'Canta de recebimento'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'MV_XCONTA'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Conta recebimento'														, ; //X6_DESCRIC
	'Conta recebimento'														, ; //X6_DSCSPA
	'Conta recebimento'														, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'MV_XNAT'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Natureza de transferencia'												, ; //X6_DESCRIC
	'Natureza de transferencia'												, ; //X6_DSCSPA
	'Natureza de transferencia'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SD_ATVSHOP'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Ativa a integração com o ShopDeere.'									, ; //X6_DESCRIC
	'Ativa a integração com o ShopDeere.'									, ; //X6_DSCSPA
	'Ativa a integração com o ShopDeere.'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAAUTH'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de Validacao Uso Integracao SIMOVA SmartOS'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'PcQ17e+NfvBWCNWMS8mhNsAnzCxOP4LGPCW+yFql8OQ1KZTkw7ACERD+Pp77AxJg'		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVABTTD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utiliza Tipo de Tempo Deslocamento da Origem da'						, ; //X6_DESCRIC
	'Utiliza Tipo de Tempo Deslocamento da Origem da'						, ; //X6_DSCSPA
	'Utiliza Tipo de Tempo Deslocamento da Origem da'						, ; //X6_DSCENG
	'Requisicao VO4 (0=Padrao Inativo;1=Ativo)'								, ; //X6_DESC1
	'Requisicao VO4 (0=Padrao Inativo;1=Ativo)'								, ; //X6_DSCSPA1
	'Requisicao VO4 (0=Padrao Inativo;1=Ativo)'								, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	'0'																		, ; //X6_CONTSPA
	'0'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVACARD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Habiilta Card Painel SmartOS'										, ; //X6_DESCRIC
	'.T.= Habiilta Card Painel SmartOS'										, ; //X6_DSCSPA
	'.T.= Habiilta Card Painel SmartOS'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVACONF'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Busca GrpServico Marca X Codigo de Servico'						, ; //X6_DESCRIC
	'.T. = Busca GrpServico Marca X Codigo de Servico'						, ; //X6_DSCSPA
	'.T. = Busca GrpServico Marca X Codigo de Servico'						, ; //X6_DSCENG
	'Muda comportamento conf SIMOVACONF de SIMOVAGS06'						, ; //X6_DESC1
	'Muda comportamento conf SIMOVACONF de SIMOVAGS06'						, ; //X6_DSCSPA1
	'Muda comportamento conf SIMOVACONF de SIMOVAGS06'						, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	'Integracao com SmartOs'												, ; //X6_DSCSPA2
	'Integracao com SmartOs'												, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVACPDI'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Cliente com Legado PDI'												, ; //X6_DESCRIC
	'Cliente com Legado PDI'												, ; //X6_DSCSPA
	'Cliente com Legado PDI'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVACSPD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Servico Padrao de Deslocamento  (KM)'						, ; //X6_DESCRIC
	'Codigo do Servico Padrao de Deslocamento  (KM)'						, ; //X6_DSCSPA
	'Codigo do Servico Padrao de Deslocamento  (KM)'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'KM'																	, ; //X6_CONTEUD
	'KM'																	, ; //X6_CONTSPA
	'KM'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVACSPT'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo de Servico Padrao p/ Tempo de Deslocamento'						, ; //X6_DESCRIC
	'Codigo de Servico Padrao p/ Tempo de Deslocamento'						, ; //X6_DSCSPA
	'Codigo de Servico Padrao p/ Tempo de Deslocamento'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'MODC1'																	, ; //X6_CONTEUD
	'MODC1'																	, ; //X6_CONTSPA
	'MODC1'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVADBG'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Ativa Log Integracao'													, ; //X6_DESCRIC
	'Ativa Log Integracao'													, ; //X6_DSCSPA
	'Ativa Log Integracao'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVADEOS'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Qtd dias a somar database p/ Dt/Entrega OS'							, ; //X6_DESCRIC
	'Qtd dias a somar database p/ Dt/Entrega OS'							, ; //X6_DSCSPA
	'Qtd dias a somar database p/ Dt/Entrega OS'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVADPOS'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Informa Data Entrega OS Automatica'								, ; //X6_DESCRIC
	'.T. = Informa Data Entrega OS Automatica'								, ; //X6_DSCSPA
	'.T. = Informa Data Entrega OS Automatica'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVADTPD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Data de referencia Producao.'											, ; //X6_DESCRIC
	'Data de referencia Producao.'											, ; //X6_DSCSPA
	'Data de referencia Producao.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'27/03/23'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAEXPD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Habilita Menu Carga/NFS.'											, ; //X6_DESCRIC
	'.T.= Habilita Menu Carga/NFS.'											, ; //X6_DSCSPA
	'.T.= Habilita Menu Carga/NFS.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAFORI'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiza Cli/Fat da origem do serv.'									, ; //X6_DESCRIC
	'.T.= Utiza Cli/Fat da origem do serv.'									, ; //X6_DSCSPA
	'.T.= Utiza Cli/Fat da origem do serv.'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAGKMD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupo de Servico para KM de Deslocamento'								, ; //X6_DESCRIC
	'Grupo de Servico para KM de Deslocamento'								, ; //X6_DSCSPA
	'Grupo de Servico para KM de Deslocamento'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAGKMT'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupo de Servico para KM Tempo Deslocamento'							, ; //X6_DESCRIC
	'Grupo de Servico para KM Tempo Deslocamento'							, ; //X6_DSCSPA
	'Grupo de Servico para KM Tempo Deslocamento'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAGS06'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Busca GrpServico pelo Codigo de Servico VO6'						, ; //X6_DESCRIC
	'.T. = Busca GrpServico pelo Codigo de Servico VO6'						, ; //X6_DSCSPA
	'.T. = Busca GrpServico pelo Codigo de Servico VO6'						, ; //X6_DSCENG
	'Uso na Intergacao ao incluir apontamentos IncVO4'						, ; //X6_DESC1
	'Uso na Intergacao ao incluir apontamentos IncVO4'						, ; //X6_DSCSPA1
	'Uso na Intergacao ao incluir apontamentos IncVO4'						, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	'Integracao com SmartOs'												, ; //X6_DSCSPA2
	'Integracao com SmartOs'												, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAGSA'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Usar Grupo de Servico do Apontamento'									, ; //X6_DESCRIC
	'Usar Grupo de Servico do Apontamento'									, ; //X6_DSCSPA
	'Usar Grupo de Servico do Apontamento'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAITPD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Grava TemPad na inclusao de apontamento'							, ; //X6_DESCRIC
	'.T.= Grava TemPad na inclusao de apontamento'							, ; //X6_DSCSPA
	'.T.= Grava TemPad na inclusao de apontamento'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME



aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAKROD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO4_KILROD'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO4_KILROD'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO4_KILROD'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALCAL'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Par.Local no Painel'										, ; //X6_DESCRIC
	'.T.= Utiliza Par.Local no Painel'										, ; //X6_DSCSPA
	'.T.= Utiliza Par.Local no Painel'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALCSD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Tabela ZZX para substituir CSPD'							, ; //X6_DESCRIC
	'.T.= Utiliza Tabela ZZX para substituir CSPD'							, ; //X6_DSCSPA
	'.T.= Utiliza Tabela ZZX para substituir CSPD'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALCST'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Tabela ZZX para substituir CSPT'							, ; //X6_DESCRIC
	'.T.= Utiliza Tabela ZZX para substituir CSPT'							, ; //X6_DSCSPA
	'.T.= Utiliza Tabela ZZX para substituir CSPT'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALEG0'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Ativa Legenda SIMOVA na OS'										, ; //X6_DESCRIC
	'.T. = Ativa Legenda SIMOVA na OS'										, ; //X6_DSCSPA
	'.T. = Ativa Legenda SIMOVA na OS'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALEG1'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Ativa Legenda SIMOVA NT na OS'									, ; //X6_DESCRIC
	'.T. = Ativa Legenda SIMOVA NT na OS'									, ; //X6_DSCSPA
	'.T. = Ativa Legenda SIMOVA NT na OS'									, ; //X6_DSCENG
	'(Nao Transmitida)'														, ; //X6_DESC1
	'(Nao Transmitida)'														, ; //X6_DSCSPA1
	'(Nao Transmitida)'														, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALEGC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Cor padrao legenda SIMOVA'												, ; //X6_DESCRIC
	'Cor padrao legenda SIMOVA'												, ; //X6_DSCSPA
	'Cor padrao legenda SIMOVA'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'VERDE_LARANJA'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALIB'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de Liberacao Integracao SIMOVA SmartOS'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'PcQ17e833af85a3485f762827a82dd4e04bbf3+NfvBWCNWMS8mhNsAnzCxOP4LGPCW+yFql8OQ1KZTkw7ACERD+Pp77AxJg', ; //X6_CONTEUD
	'PcQ17e833af85a3485f762827a82dd4e04bbf3+NfvBWCNWMS8mhNsAnzCxOP4LGPCW+yFql8OQ1KZTkw7ACERD+Pp77AxJg', ; //X6_CONTSPA
	'PcQ17e833af85a3485f762827a82dd4e04bbf3+NfvBWCNWMS8mhNsAnzCxOP4LGPCW+yFql8OQ1KZTkw7ACERD+Pp77AxJg', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALIBE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de Liberacao de Emergencia SmartOS'								, ; //X6_DESCRIC
	'Chave de Liberacao de Emergencia SmartOS'								, ; //X6_DSCSPA
	'Chave de Liberacao de Emergencia SmartOS'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Licenca de Uso Integracao SIMOVA SmartOS'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'4nd30sgATBDRK3ZkJe/50DAm2ljSoRARVOHoEObT69e7mgkVxKeEitNcoMsHPC1Z5OjEJT3/rV81/mRdlWlyS5QIZSLLOWDtKTt/e22GdL0=', ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALTSD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Tabela ZZX para substituir TSPD'							, ; //X6_DESCRIC
	'.T.= Utiliza Tabela ZZX para substituir TSPD'							, ; //X6_DSCSPA
	'.T.= Utiliza Tabela ZZX para substituir TSPD'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALTST'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Tabela ZZX para substituir TSPT'							, ; //X6_DESCRIC
	'.T.= Utiliza Tabela ZZX para substituir TSPT'							, ; //X6_DSCSPA
	'.T.= Utiliza Tabela ZZX para substituir TSPT'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALTTD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Tabela ZZX para substituir TTPD'							, ; //X6_DESCRIC
	'.T.= Utiliza Tabela ZZX para substituir TTPD'							, ; //X6_DSCSPA
	'.T.= Utiliza Tabela ZZX para substituir TTPD'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVALTTT'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Tabela ZZX para substituir TTPT'							, ; //X6_DESCRIC
	'.T.= Utiliza Tabela ZZX para substituir TTPT'							, ; //X6_DSCSPA
	'.T.= Utiliza Tabela ZZX para substituir TTPT'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAMAIL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'e-mail dos usuarios que serao notificados'								, ; //X6_DESCRIC
	'e-mail dos usuarios que serao notificados'								, ; //X6_DSCSPA
	'e-mail dos usuarios que serao notificados'								, ; //X6_DSCENG
	'quando houver problemas na integracao'									, ; //X6_DESC1
	'quando houver problemas na integracao'									, ; //X6_DSCSPA1
	'quando houver problemas na integracao'									, ; //X6_DSCENG1
	' com SmartOs'															, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVANIZO'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Busca TemPad Padrão de Interface'								, ; //X6_DESCRIC
	'.T. = Busca TemPad Padrão de Interface'								, ; //X6_DSCSPA
	'.T. = Busca TemPad Padrão de Interface'								, ; //X6_DSCENG
	'em IncVO4 quando igual a Zero'											, ; //X6_DESC1
	'em IncVO4 quando igual a Zero'											, ; //X6_DSCSPA1
	'em IncVO4 quando igual a Zero'											, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVANUMS'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Nao utiliza Marca no Servico'									, ; //X6_DESCRIC
	'.T. = Nao utiliza Marca no Servico'									, ; //X6_DSCSPA
	'.T. = Nao utiliza Marca no Servico'									, ; //X6_DSCENG
	'Uso em conjunto com SIMOVACONF'										, ; //X6_DESC1
	'Uso em conjunto com SIMOVACONF'										, ; //X6_DSCSPA1
	'Uso em conjunto com SIMOVACONF'										, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVANUPD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza dados da VO4 e VO1'									, ; //X6_DESCRIC
	'.T.= Nao atualiza dados da VO4 e VO1'									, ; //X6_DSCSPA
	'.T.= Nao atualiza dados da VO4 e VO1'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVANVHR'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO4_VALHOR'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO4_VALHOR'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO4_VALHOR'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAORCF'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza Orcamento por Fases'										, ; //X6_DESCRIC
	'.T.= Utiliza Orcamento por Fases'										, ; //X6_DSCSPA
	'.T.= Utiliza Orcamento por Fases'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAORCK'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Atualiza Km Orcamento'											, ; //X6_DESCRIC
	'.T.= Atualiza Km Orcamento'											, ; //X6_DSCSPA
	'.T.= Atualiza Km Orcamento'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAORCS'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Sincroniza Servicos Orcamento'									, ; //X6_DESCRIC
	'.T.= Sincroniza Servicos Orcamento'									, ; //X6_DSCSPA
	'.T.= Sincroniza Servicos Orcamento'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAOSBO'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Apontamento ( 0=OS / 1=Boletim )'								, ; //X6_DESCRIC
	'Tipo de Apontamento ( 0=OS / 1=Boletim )'								, ; //X6_DSCSPA
	'Tipo de Apontamento ( 0=OS / 1=Boletim )'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAPILH'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Habiilta Debug Pilha.'											, ; //X6_DESCRIC
	'.T.= Habiilta Debug Pilha.'											, ; //X6_DSCSPA
	'.T.= Habiilta Debug Pilha.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVARAIT'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Padrao de resposta p/ Alerta Integracao'								, ; //X6_DESCRIC
	'Padrao de resposta p/ Alerta Integracao'								, ; //X6_DSCSPA
	'Padrao de resposta p/ Alerta Integracao'								, ; //X6_DSCENG
	'NOYES = Nao; YESNO = Sim'												, ; //X6_DESC1
	'NOYES = Nao; YESNO = Sim'												, ; //X6_DSCSPA1
	'NOYES = Nao; YESNO = Sim'												, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'NOYES'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVARLOG'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Ativa Registro Log Erro'												, ; //X6_DESCRIC
	'Ativa Registro Log Erro'												, ; //X6_DSCSPA
	'Ativa Registro Log Erro'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVASMRK'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Habiilta Menu ListaMark OS.'										, ; //X6_DESCRIC
	'.T.= Habiilta Menu ListaMark OS.'										, ; //X6_DSCSPA
	'.T.= Habiilta Menu ListaMark OS.'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVASVO1'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Ativa sincronismo na inclusao da O.S'							, ; //X6_DESCRIC
	'.T. = Ativa sincronismo na inclusao da O.S'							, ; //X6_DSCSPA
	'.T. = Ativa sincronismo na inclusao da O.S'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVASYKM'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Ativa sincronismo Req.Serv.KM Desloc'							, ; //X6_DESCRIC
	'.T. = Ativa sincronismo Req.Serv.KM Desloc'							, ; //X6_DSCSPA
	'.T. = Ativa sincronismo Req.Serv.KM Desloc'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATENV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Token de Ambiente SmartOS'												, ; //X6_DESCRIC
	'Token de Ambiente SmartOS'												, ; //X6_DSCSPA
	'Token de Ambiente SmartOS'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'9c90406cdf2a5cc5295ebd71518dbeff'										, ; //X6_CONTEUD
	'9c90406cdf2a5cc5295ebd71518dbeff'										, ; //X6_CONTSPA
	'9c90406cdf2a5cc5295ebd71518dbeff'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATMOS'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Qtde minima de minutos a cobrar na OS'									, ; //X6_DESCRIC
	'Qtde minima de minutos a cobrar na OS'									, ; //X6_DSCSPA
	'Qtde minima de minutos a cobrar na OS'									, ; //X6_DSCENG
	'Abaixo desse valor nao cobra, mas aponta'								, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'5'																		, ; //X6_CONTEUD
	'5'																		, ; //X6_CONTSPA
	'5'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATPAD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO4_TEMPAD'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO4_TEMPAD'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO4_TEMPAD'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATPIN'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Solicita informacao OS Automatica'								, ; //X6_DESCRIC
	'.T. = Solicita informacao OS Automatica'								, ; //X6_DSCSPA
	'.T. = Solicita informacao OS Automatica'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATPOI'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Integracao SmartOS (0=API/1=PDI)'								, ; //X6_DESCRIC
	'Tipo de Integracao SmartOS (0=API/1=PDI)'								, ; //X6_DSCSPA
	'Tipo de Integracao SmartOS (0=API/1=PDI)'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1'																		, ; //X6_CONTEUD
	'1'																		, ; //X6_CONTSPA
	'1'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATPOS'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tecnico padrao para abertura OS automatica'							, ; //X6_DESCRIC
	'Tecnico padrao para abertura OS automatica'							, ; //X6_DSCSPA
	'Tecnico padrao para abertura OS automatica'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATSPD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Servico Padrao para Deslocamento (KM)'							, ; //X6_DESCRIC
	'Tipo de Servico Padrao para Deslocamento (KM)'							, ; //X6_DSCSPA
	'Tipo de Servico Padrao para Deslocamento (KM)'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'KM'																	, ; //X6_CONTEUD
	'KM'																	, ; //X6_CONTSPA
	'KM'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATSPT'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DESCRIC
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DSCSPA
	'Tipo de Servico Padrao para Tempo de Deslocamento'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'SPO'																	, ; //X6_CONTEUD
	'SPO'																	, ; //X6_CONTSPA
	'SPO'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATTPD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Tempo Padrao para Deslocamento'								, ; //X6_DESCRIC
	'Tipo de Tempo Padrao para Deslocamento'								, ; //X6_DSCSPA
	'Tipo de Tempo Padrao para Deslocamento'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATTPT'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tipo de Tempo Padrao para Tempo de Deslocamento'						, ; //X6_DESCRIC
	'Tipo de Tempo Padrao para Tempo de Deslocamento'						, ; //X6_DSCSPA
	'Tipo de Tempo Padrao paraTempo de  Deslocamento'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATTRA'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO4_TEMTRA'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO4_TEMTRA'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO4_TEMTRA'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATVEN'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO4_TEMVEN'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO4_TEMVEN'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO4_TEMVEN'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVATVOH'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Valida Escala tabela VOH'										, ; //X6_DESCRIC
	'.T. = Valida Escala tabela VOH'										, ; //X6_DSCSPA
	'.T. = Valida Escala tabela VOH'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAUAPP'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T. = Somente as horas apontadas por quem estava'						, ; //X6_DESCRIC
	'.T. = Somente as horas apontadas por quem estava'						, ; //X6_DSCSPA
	'.T. = Somente as horas apontadas por quem estava'						, ; //X6_DSCENG
	'logado no aplicativo serao cobradas'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAUTPC'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utiliza pecas no Processo de integracao'							, ; //X6_DESCRIC
	'.T.= Utiliza pecas no Processo de integracao'							, ; //X6_DSCSPA
	'.T.= Utiliza pecas no Processo de integracao'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAVO1H'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO1_HORTRI'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO1_HORTRI'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO1_HORTRI'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAVO1K'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao atualiza VO1_KILOME'											, ; //X6_DESCRIC
	'.T.= Nao atualiza VO1_KILOME'											, ; //X6_DSCSPA
	'.T.= Nao atualiza VO1_KILOME'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAVO4O'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Utilizar Dados Origem VO4'										, ; //X6_DESCRIC
	'.T.= Utilizar Dados Origem VO4'										, ; //X6_DSCSPA
	'.T.= Utilizar Dados Origem VO4'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAVPTC'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Controle de versao Patch'												, ; //X6_DESCRIC
	'Controle de versao Patch'												, ; //X6_DSCSPA
	'Controle de versao Patch'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'T0s='																	, ; //X6_CONTEUD
	'T0s='																	, ; //X6_CONTSPA
	'T0s='																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAVSYN'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Valida falta de Sincronismo na Integracao'						, ; //X6_DESCRIC
	'.T.= Valida falta de Sincronismo na Integracao'						, ; //X6_DSCSPA
	'.T.= Valida falta de Sincronismo na Integracao'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAWEB0'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de Verificacao Servico HTTP SmartOS'								, ; //X6_DESCRIC
	'Chave de Verificacao Servico HTTP SmartOS'								, ; //X6_DSCSPA
	'Chave de Verificacao Servico HTTP SmartOS'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'2i4xkokOUwySfi95Z9amjHd3xBKJ9E1SDPu/Q+mHpJj3yQZclKnUwoM='				, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAWEB1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de Verificacao Servico Rest SmartOS'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'2i4xkokOUwyScys7Yt7lgntjmASX/EBXBKGtQ+idroO0lX5QhtTB2IUV4450VUA2kom0VlKMox5mszw=', ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZKRO'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Nao Zera VO4_KILROD'												, ; //X6_DESCRIC
	'.T.= Nao Zera VO4_KILROD'												, ; //X6_DSCSPA
	'.T.= Nao Zera VO4_KILROD'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZTPD'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'.T.= Grava TemPad quando zero no apontamento'							, ; //X6_DESCRIC
	'.T.= Grava TemPad quando zero no apontamento'							, ; //X6_DSCSPA
	'.T.= Grava TemPad quando zero no apontamento'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Integracao com SmartOs'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZZS'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela SMARTOS utilizada para ZZS'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZS'																	, ; //X6_CONTEUD
	'ZZS'																	, ; //X6_CONTSPA
	'ZZS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZZT'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela SMARTOS utilizada para ZZT'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZT'																	, ; //X6_CONTEUD
	'ZZT'																	, ; //X6_CONTSPA
	'ZZT'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZZU'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela SMARTOS utilizada para ZZU'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZU'																	, ; //X6_CONTEUD
	'ZZU'																	, ; //X6_CONTSPA
	'ZZU'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZZV'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela SMARTOS utilizada para ZZV'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZV'																	, ; //X6_CONTEUD
	'ZZV'																	, ; //X6_CONTSPA
	'ZZV'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZZW'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela SMARTOS utilizada para ZZW'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZW'																	, ; //X6_CONTEUD
	'ZZW'																	, ; //X6_CONTSPA
	'ZZW'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'SIMOVAZZX'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela SMARTOS utilizada para ZZX'										, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZX'																	, ; //X6_CONTEUD
	'ZZX'																	, ; //X6_CONTSPA
	'ZZX'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'01'																	, ; //X6_FIL
	'ZZ_CHVITAU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do PIX banco Itau'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'09282594000145'														, ; //X6_CONTEUD
	'09282594000145'														, ; //X6_CONTSPA
	'09282594000145'														, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'6T22GSTSM398V6JDMWRDWXA4SM4JGQ'										, ; //X6_CONTEUD
	'6T22GSTSM398V6JDMWRDWXA4SM4JGQ'										, ; //X6_CONTSPA
	'6T22GSTSM398V6JDMWRDWXA4SM4JGQ'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao'								, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'203932'																, ; //X6_CONTEUD
	'203932'																, ; //X6_CONTSPA
	'203932'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_AUTHURL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL de autenticação.'													, ; //X6_DESCRIC
	'URL de autenticação.'													, ; //X6_DSCSPA
	'URL de autenticação.'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_CIFTPSW'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Senha/SecretId de acesso ao Cift.'										, ; //X6_DESCRIC
	'Senha/SecretId de acesso ao Cift.'										, ; //X6_DSCSPA
	'Senha/SecretId de acesso ao Cift.'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_CIFTURL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL do Cift.'															, ; //X6_DESCRIC
	'URL do Cift.'															, ; //X6_DSCSPA
	'URL do Cift.'															, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_CIFTUSR'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuário/ClientId de acesso ao Cift.'									, ; //X6_DESCRIC
	'Usuário/ClientId de acesso ao Cift.'									, ; //X6_DSCSPA
	'Usuário/ClientId de acesso ao Cift.'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_TBCABDV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela de cabeçalho de devolução ShopDeere.'							, ; //X6_DESCRIC
	'Tabela de cabeçalho de devolução ShopDeere.'							, ; //X6_DSCSPA
	'Tabela de cabeçalho de devolução ShopDeere.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZ5'																	, ; //X6_CONTEUD
	'ZZ5'																	, ; //X6_CONTSPA
	'ZZ5'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_TBCABPD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela de cabeçalho de pedido ShopDeere.'								, ; //X6_DESCRIC
	'Tabela de cabeçalho de pedido ShopDeere.'								, ; //X6_DSCSPA
	'Tabela de cabeçalho de pedido ShopDeere.'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZ3'																	, ; //X6_CONTEUD
	'ZZ3'																	, ; //X6_CONTSPA
	'ZZ3'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_TBCPPED'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela de conteúdo padrão de pedido ShopDeere.'						, ; //X6_DESCRIC
	'Tabela de conteúdo padrão de pedido ShopDeere.'						, ; //X6_DSCSPA
	'Tabela de conteúdo padrão de pedido ShopDeere.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZ7'																	, ; //X6_CONTEUD
	'ZZ7'																	, ; //X6_CONTSPA
	'ZZ7'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_TBDPCON'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela de de/para concessionário ShopDeere.'							, ; //X6_DESCRIC
	'Tabela de de/para concessionário ShopDeere.'							, ; //X6_DSCSPA
	'Tabela de de/para concessionário ShopDeere.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZ8'																	, ; //X6_CONTEUD
	'ZZ8'																	, ; //X6_CONTSPA
	'ZZ8'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_TBITEDV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela de itens de devolução ShopDeere.'								, ; //X6_DESCRIC
	'Tabela de itens de devolução ShopDeere.'								, ; //X6_DSCSPA
	'Tabela de itens de devolução ShopDeere.'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZ6'																	, ; //X6_CONTEUD
	'ZZ6'																	, ; //X6_CONTSPA
	'ZZ6'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'SD_TBITEPD'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Tabela de itens de pedido ShopDeere.'									, ; //X6_DESCRIC
	'Tabela de itens de pedido ShopDeere.'									, ; //X6_DSCSPA
	'Tabela de itens de pedido ShopDeere.'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ZZ4'																	, ; //X6_CONTEUD
	'ZZ4'																	, ; //X6_CONTSPA
	'ZZ4'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_DIASP'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Relatorio de conferencia de Pedidos de Compras a V'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'dias de antecedencia'													, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'10'																	, ; //X6_CONTEUD
	'10'																	, ; //X6_CONTSPA
	'10'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTEUD
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0101'																	, ; //X6_FIL
	'TV_VNDPNEU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do vendedor de pneus'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000547'																, ; //X6_CONTEUD
	'000547'																, ; //X6_CONTSPA
	'000547'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ONMTMKKUP9APEYB63A6AVJ0MZKI7UH'										, ; //X6_CONTEUD
	'ONMTMKKUP9APEYB63A6AVJ0MZKI7UH'										, ; //X6_CONTSPA
	'ONMTMKKUP9APEYB63A6AVJ0MZKI7UH'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'198575'																, ; //X6_CONTEUD
	'198575'																, ; //X6_CONTSPA
	'198575'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'jau@terraverdeagro.com.br'												, ; //X6_CONTEUD
	'jau@terraverdeagro.com.br'												, ; //X6_CONTSPA
	'jau@terraverdeagro.com.br'												, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0102'																	, ; //X6_FIL
	'TV_VNDPNEU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do vendedor de pneu'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Codigo do vendedor externo de pneus'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000566'																, ; //X6_CONTEUD
	'000566'																, ; //X6_CONTSPA
	'000566'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'MV_MIL0177'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Armazem reserva de orcamento'											, ; //X6_DESCRIC
	'Almacen reserva de presupuesto'										, ; //X6_DSCSPA
	'Budget reserve warehouse'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'70'																	, ; //X6_CONTEUD
	'70'																	, ; //X6_CONTSPA
	'70'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'MV_TPCONFF'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Indica se a conferência física será realizada na'						, ; //X6_DESCRIC
	'Indica si la conferencia fisica se realizara en la'					, ; //X6_DSCSPA
	'Indicates whether physical checking is made in'						, ; //X6_DSCENG
	'Pré-Nota ou na Nota Fiscal de Entrada. O valor'						, ; //X6_DESC1
	'Fact. Prev. o en la Factura de Entrada.El valor'						, ; //X6_DSCSPA1
	'Pro Forma or Inflow Invoice. The default'								, ; //X6_DSCENG1
	'default (padrão) desse parâmetro será Pré-Nota.'						, ; //X6_DESC2
	'default (estandar) de ese parametro sera Fact.Prev'					, ; //X6_DSCSPA2
	'value of this parameter is Pro Forma.'									, ; //X6_DSCENG2
	'2'																		, ; //X6_CONTEUD
	'2'																		, ; //X6_CONTSPA
	'2'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'mogimirim@terraverdeagro.com.br'										, ; //X6_CONTEUD
	'mogimirim@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'mogimirim@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'TV_VNDPNEU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do vendedor de pneu'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Codigo do vendedor externo de pneus'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000547'																, ; //X6_CONTEUD
	'000547'																, ; //X6_CONTSPA
	'000547'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0103'																	, ; //X6_FIL
	'XM_CONFCEG'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Ativa conferencia cega'												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Ativa conferencia cega'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'Ativa conferencia cega'												, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0104'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0104'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0104'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao'								, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'  lencoispaulista@terraverdeagro.com.br'								, ; //X6_CONTEUD
	'  lencoispaulista@terraverdeagro.com.br'								, ; //X6_CONTSPA
	'  lencoispaulista@terraverdeagro.com.br'								, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0105'																	, ; //X6_FIL
	'TV_VNDPNEU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do vendedor de pneu'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Codigo do vendedor externo de pneus'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000566'																, ; //X6_CONTEUD
	'000566'																, ; //X6_CONTSPA
	'000566'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'araras@terraverdeagro.com.br'											, ; //X6_CONTEUD
	'araras@terraverdeagro.com.br'											, ; //X6_CONTSPA
	'araras@terraverdeagro.com.br'											, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0106'																	, ; //X6_FIL
	'TV_VNDPNEU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do vendedor de pneu'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Codigo do vendedor externo de pneus'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000547'																, ; //X6_CONTEUD
	'000547'																, ; //X6_CONTSPA
	'000547'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0107'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0107'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0107'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0108'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'mogidascruzes@terraverdeagro.com.br'									, ; //X6_CONTEUD
	'mogidascruzes@terraverdeagro.com.br'									, ; //X6_CONTSPA
	'mogidascruzes@terraverdeagro.com.br'									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'MV_MIL0177'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Armazem reserva de orcamento'											, ; //X6_DESCRIC
	'Almacen reserva de presupuesto'										, ; //X6_DSCSPA
	'Budget reserve warehouse'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'70'																	, ; //X6_CONTEUD
	'70'																	, ; //X6_CONTSPA
	'70'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'MV_MIL0179'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Armazem reserva de oficina'											, ; //X6_DESCRIC
	'Almacen reserva de taller'												, ; //X6_DSCSPA
	'Workshop reserve warehouse'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'80'																	, ; //X6_CONTEUD
	'80'																	, ; //X6_CONTSPA
	'80'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'MV_MIL0181'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Controla reserva rastreavel no ambiente?'								, ; //X6_DESCRIC
	'Controla reserva rastreable en el entorno'								, ; //X6_DSCSPA
	'Control traceable reserve in the envir.?'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'MV_MIL0192'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Armazem reserva de pedido de orcamento'								, ; //X6_DESCRIC
	'Almacen reserva de pedido de presupuesto'								, ; //X6_DSCSPA
	'Reserve warehouse for budget order'									, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'90'																	, ; //X6_CONTEUD
	'90'																	, ; //X6_CONTSPA
	'90'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0109'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTEUD
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'MV_MIL0005'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Código do Concessionário no portal de Garantia'						, ; //X6_DESCRIC
	'Codigo do Concesionario en John Deere'									, ; //X6_DSCSPA
	'Code of John Deere Car Dealer'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'201426'																, ; //X6_CONTEUD
	'201426'																, ; //X6_CONTSPA
	'201426'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'MV_MIL0177'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Armazem reserva de orcamento'											, ; //X6_DESCRIC
	'Almacen reserva de presupuesto'										, ; //X6_DSCSPA
	'Budget reserve warehouse'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'70'																	, ; //X6_CONTEUD
	'70'																	, ; //X6_CONTSPA
	'70'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0110'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'taubate@terraverdeagro.com.br'											, ; //X6_CONTEUD
	'taubate@terraverdeagro.com.br'											, ; //X6_CONTSPA
	'taubate@terraverdeagro.com.br'											, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'203932'																, ; //X6_CONTEUD
	'203932'																, ; //X6_CONTSPA
	'203932'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_ALIQISS'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Aliquota do ISS em casos de prestacao de servicos.'					, ; //X6_DESCRIC
	'Alicuota del ISS en casos de prestacion de'							, ; //X6_DSCSPA
	'ISS tax rate in case of service rendering'								, ; //X6_DSCENG
	'usando percentuais definidos pelo municipio.'							, ; //X6_DESC1
	'servicios. Usa porcentajes definidos por el'							, ; //X6_DSCSPA1
	'using percentages defined by the district mentione'					, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	'municipio.'															, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'5'																		, ; //X6_CONTEUD
	'5'																		, ; //X6_CONTSPA
	'5'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_CONVP12'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Trata se conversao foi finalizada'										, ; //X6_DESCRIC
	'Trata se conversao foi finalizada'										, ; //X6_DSCSPA
	'Trata se conversao foi finalizada'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_CTBLOCK'															, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Interno SIGACTB - Controle de concorrencia entre'						, ; //X6_DESCRIC
	'Interno SIGACTB-Control de competencia entre'							, ; //X6_DSCSPA
	'Internal SIGACTB - Control of competition between'						, ; //X6_DSCENG
	'reprocessamentos de saldos'											, ; //X6_DESC1
	'reprocesamiento de saldos.'											, ; //X6_DSCSPA1
	'reprocessing of balances'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_CXFIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caixa Geral Financeiro'												, ; //X6_DESCRIC
	'Caja General Financiero'												, ; //X6_DSCSPA
	'Main Financial Cash'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'C11/00001/0000000001'													, ; //X6_CONTEUD
	'C11/00001/0000000001'													, ; //X6_CONTSPA
	'C11/00001/0000000001'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_DIAISS'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Dia padrao para gerar os titulos de  ISS.'								, ; //X6_DESCRIC
	'Dia estandar para emitir los titulos del ISS.'							, ; //X6_DSCSPA
	'Standard day for generating ISS bills.'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'10'																	, ; //X6_CONTEUD
	'10'																	, ; //X6_CONTSPA
	'10'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_DIFALIQ'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Informe a aliquota especifica a ser'									, ; //X6_DESCRIC
	'Informe la alicuota especifica que se'									, ; //X6_DSCSPA
	'Enter the specific rate to be'											, ; //X6_DSCENG
	'utilizada no calculo do'												, ; //X6_DESC1
	'utilizara en el calculo del'											, ; //X6_DSCSPA1
	'used in the calculation of'											, ; //X6_DSCENG1
	'ICMS Complementar.'													, ; //X6_DESC2
	'ICMS Complementar.'													, ; //X6_DSCSPA2
	'Additional ICMS.'														, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_FILSCP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Identifica se a filial é uma SCP -'									, ; //X6_DESCRIC
	'Identifica si la sucursal es una SCP -'								, ; //X6_DSCSPA
	'Identifies if branch is a SCP -'										, ; //X6_DSCENG
	'Sociedade em Conta de Participação'									, ; //X6_DESC1
	'Sociedad en Cuenta de Participacion'									, ; //X6_DSCSPA1
	'Society in Account of Participation'									, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'F'																		, ; //X6_CONTEUD
	'F'																		, ; //X6_CONTSPA
	'F'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_FPADISS'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Fornecedor padrão a ser considerado'									, ; //X6_DESCRIC
	'Proveedor estandar por considerar'										, ; //X6_DSCSPA
	'Default supplier to be considered'										, ; //X6_DSCENG
	'na apuração de ISS por município'										, ; //X6_DESC1
	'en el calculo de ISS por municipio'									, ; //X6_DSCSPA1
	'on ISS calculation by city'											, ; //X6_DSCENG1
	'caso não seja possível obtê-lo da tabela CE1.'							, ; //X6_DESC2
	'si no se pueda obtenerlo de tabla CE1.'								, ; //X6_DSCSPA2
	'if not possible get from CE1 table.'									, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_LOCKCT'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Controle de Geracao de Cotacoes por Filial'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_MIL0005'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Concessionario no portal de Garantia'						, ; //X6_DESCRIC
	'Codigo do Concesionario en John Deere'									, ; //X6_DSCSPA
	'Code of John Deere Car Dealer'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'201461'																, ; //X6_CONTEUD
	'201461'																, ; //X6_CONTSPA
	'201461'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_MIL0111'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Gera apontamento no intervalo do período. Opções'						, ; //X6_DESCRIC
	'Genera apunte en intervalo del período. Opciones'						, ; //X6_DSCSPA
	'Generates an annotation in period interval. Option'					, ; //X6_DSCENG
	'0=Não apont. / 1=Aponta. Formato: xxx, sendo'							, ; //X6_DESC1
	'0=No apunta / 1=Apunta. Formato: xxx, siendo'							, ; //X6_DSCSPA1
	'0=Does not annotate/1=Annotates Format: xxx, being'					, ; //X6_DSCENG1
	'1º=Intervalo 1, 2º=Refeição, 3º Intervalo 2'							, ; //X6_DESC2
	'1º=Intervalo 1, 2º=Comida, 3º Intervalo 2'								, ; //X6_DSCSPA2
	'1st=Interval 1,2nd=Meal,3rd=Interval 2'								, ; //X6_DSCENG2
	'000'																	, ; //X6_CONTEUD
	'000'																	, ; //X6_CONTSPA
	'000'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_PAPONTA'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Periodo para apontamento das marcacoes'								, ; //X6_DESCRIC
	'Periodo para apunte de las marcaciones.'								, ; //X6_DSCSPA
	'Period for marking annotations'										, ; //X6_DSCENG
	'0131'																	, ; //X6_DESC1
	'0131.'																	, ; //X6_DSCSPA1
	'0131'																	, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'21/20'																	, ; //X6_CONTEUD
	'21/20'																	, ; //X6_CONTSPA
	'21/20'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_PONMES'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Periodo de Apontamento em aberto para a   Apuracao'					, ; //X6_DESCRIC
	'Periodo de Apunte en abierto para el Computo de'						, ; //X6_DSCSPA
	'Open Annotation Period to Calculate'									, ; //X6_DSCENG
	'das Marcacoes/Apontamentos no Ponto Eletronico'						, ; //X6_DESC1
	'las Marcaciones/Apuntes en Reloj Fich. Electronico'					, ; //X6_DSCSPA1
	'Marks/Annotations in Time and Attend. Terminal.'						, ; //X6_DSCENG1
	'Será atualizado pelo sistema no Fechamento Mensal.'					, ; //X6_DESC2
	'Sera actualizado por el sistema en Cierre Mensual.'					, ; //X6_DSCSPA2
	'It will be used by the system during Month Closing'					, ; //X6_DSCENG2
	'20240421/20240520'														, ; //X6_CONTEUD
	'20240421/20240520'														, ; //X6_CONTSPA
	'20240421/20240520'														, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_SGBEBRJ'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Identifica o segmento do ponto de venda de bebidas'					, ; //X6_DESCRIC
	'Identifica segmento del punto de venta de bebida'						, ; //X6_DSCSPA
	'Identifies segment of beverage point of sale'							, ; //X6_DSCENG
	' no Estado do Rio de Janeiro conforme resolução'						, ; //X6_DESC1
	'en el estado de Rio de Janeiro según resolución'						, ; //X6_DSCSPA1
	'in the State of Rio de Janeiro according to'							, ; //X6_DSCENG1
	'SEFAZ/RJ 821/2014'														, ; //X6_DESC2
	'SEFAZ/RJ 821/2014'														, ; //X6_DSCSPA2
	'Resolution SEFAZ/RJ 821/2014'											, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240430'																, ; //X6_CONTEUD
	'20240430'																, ; //X6_CONTSPA
	'20240430'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'E'																		, ; //X6_CONTEUD
	'E'																		, ; //X6_CONTSPA
	'E'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0111'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'piracicaba@terraverdeagro.com.br'										, ; //X6_CONTEUD
	'piracicaba@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'piracicaba@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'203932'																, ; //X6_CONTEUD
	'203932'																, ; //X6_CONTSPA
	'203932'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_ALIQISS'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Aliquota do ISS em casos de prestacao de servicos.'					, ; //X6_DESCRIC
	'Alicuota del ISS en casos de prestacion de'							, ; //X6_DSCSPA
	'ISS tax rate in case of service rendering'								, ; //X6_DSCENG
	'usando percentuais definidos pelo municipio.'							, ; //X6_DESC1
	'servicios. Usa porcentajes definidos por el'							, ; //X6_DSCSPA1
	'using percentages defined by the district mentione'					, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	'municipio.'															, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'3'																		, ; //X6_CONTEUD
	'3'																		, ; //X6_CONTSPA
	'3'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_CONVP12'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Trata se conversao foi finalizada'										, ; //X6_DESCRIC
	'Trata se conversao foi finalizada'										, ; //X6_DSCSPA
	'Trata se conversao foi finalizada'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_CTBLOCK'															, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Interno SIGACTB - Controle de concorrencia entre'						, ; //X6_DESCRIC
	'Interno SIGACTB-Control de competencia entre'							, ; //X6_DSCSPA
	'Internal SIGACTB - Control of competition between'						, ; //X6_DSCENG
	'reprocessamentos de saldos'											, ; //X6_DESC1
	'reprocesamiento de saldos.'											, ; //X6_DSCSPA1
	'reprocessing of balances'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_CXFIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caixa Geral Financeiro'												, ; //X6_DESCRIC
	'Caja General Financiero'												, ; //X6_DSCSPA
	'Main Financial Cash'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'C12/00001/0000000001'													, ; //X6_CONTEUD
	'C12/00001/0000000001'													, ; //X6_CONTSPA
	'C12/00001/0000000001'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_DIAISS'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Dia padrao para gerar os titulos de  ISS.'								, ; //X6_DESCRIC
	'Dia estandar para emitir los titulos del ISS.'							, ; //X6_DSCSPA
	'Standard day for generating ISS bills.'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'10'																	, ; //X6_CONTEUD
	'10'																	, ; //X6_CONTSPA
	'10'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_DIFALIQ'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Informe a aliquota especifica a ser'									, ; //X6_DESCRIC
	'Informe la alicuota especifica que se'									, ; //X6_DSCSPA
	'Enter the specific rate to be'											, ; //X6_DSCENG
	'utilizada no calculo do'												, ; //X6_DESC1
	'utilizara en el calculo del'											, ; //X6_DSCSPA1
	'used in the calculation of'											, ; //X6_DSCENG1
	'ICMS Complementar.'													, ; //X6_DESC2
	'ICMS Complementar.'													, ; //X6_DSCSPA2
	'Additional ICMS.'														, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_FILSCP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Identifica se a filial é uma SCP -'									, ; //X6_DESCRIC
	'Identifica si la sucursal es una SCP -'								, ; //X6_DSCSPA
	'Identifies if branch is a SCP -'										, ; //X6_DSCENG
	'Sociedade em Conta de Participação'									, ; //X6_DESC1
	'Sociedad en Cuenta de Participacion'									, ; //X6_DSCSPA1
	'Society in Account of Participation'									, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'F'																		, ; //X6_CONTEUD
	'F'																		, ; //X6_CONTSPA
	'F'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_FPADISS'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Fornecedor padrão a ser considerado'									, ; //X6_DESCRIC
	'Proveedor estandar por considerar'										, ; //X6_DSCSPA
	'Default supplier to be considered'										, ; //X6_DSCENG
	'na apuração de ISS por município'										, ; //X6_DESC1
	'en el calculo de ISS por municipio'									, ; //X6_DSCSPA1
	'on ISS calculation by city'											, ; //X6_DSCENG1
	'caso não seja possível obtê-lo da tabela CE1.'							, ; //X6_DESC2
	'si no se pueda obtenerlo de tabla CE1.'								, ; //X6_DSCSPA2
	'if not possible get from CE1 table.'									, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_LOCKCT'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Controle de Geracao de Cotacoes por Filial'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_LOJARPS'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da Nota Fiscal de Servico (RPS)'									, ; //X6_DESCRIC
	'Serie de Factura de Servicio (RPS)'									, ; //X6_DSCSPA
	'Service Invoice Series (RPS)'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_MIL0005'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Concessionario no portal de Garantia'						, ; //X6_DESCRIC
	'Codigo do Concesionario en John Deere'									, ; //X6_DSCSPA
	'Code of John Deere Car Dealer'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'201462'																, ; //X6_CONTEUD
	'201462'																, ; //X6_CONTSPA
	'201462'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_MIL0177'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Armazem reserva de orcamento'											, ; //X6_DESCRIC
	'Almacen reserva de presupuesto'										, ; //X6_DSCSPA
	'Budget reserve warehouse'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'70'																	, ; //X6_CONTEUD
	'70'																	, ; //X6_CONTSPA
	'70'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_PAPONTA'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Periodo para apontamento das marcacoes'								, ; //X6_DESCRIC
	'Periodo para apunte de las marcaciones.'								, ; //X6_DSCSPA
	'Period for marking annotations'										, ; //X6_DSCENG
	'0131'																	, ; //X6_DESC1
	'0131.'																	, ; //X6_DSCSPA1
	'0131'																	, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'21/20'																	, ; //X6_CONTEUD
	'21/20'																	, ; //X6_CONTSPA
	'21/20'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_PONMES'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Periodo de Apontamento em aberto para a   Apuracao'					, ; //X6_DESCRIC
	'Periodo de Apunte en abierto para el Computo de'						, ; //X6_DSCSPA
	'Open Annotation Period to Calculate'									, ; //X6_DSCENG
	'das Marcacoes/Apontamentos no Ponto Eletronico'						, ; //X6_DESC1
	'las Marcaciones/Apuntes en Reloj Fich. Electronico'					, ; //X6_DSCSPA1
	'Marks/Annotations in Time and Attend. Terminal.'						, ; //X6_DSCENG1
	'Será atualizado pelo sistema no Fechamento Mensal.'					, ; //X6_DESC2
	'Sera actualizado por el sistema en Cierre Mensual.'					, ; //X6_DSCSPA2
	'It will be used by the system during Month Closing'					, ; //X6_DSCENG2
	'20240421/20240520'														, ; //X6_CONTEUD
	'20240421/20240520'														, ; //X6_CONTSPA
	'20240421/20240520'														, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_SGBEBRJ'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Identifica o segmento do ponto de venda de bebidas'					, ; //X6_DESCRIC
	'Identifica segmento del punto de venta de bebida'						, ; //X6_DSCSPA
	'Identifies segment of beverage point of sale'							, ; //X6_DSCENG
	' no Estado do Rio de Janeiro conforme resolução'						, ; //X6_DESC1
	'en el estado de Rio de Janeiro según resolución'						, ; //X6_DSCSPA1
	'in the State of Rio de Janeiro according to'							, ; //X6_DSCENG1
	'SEFAZ/RJ 821/2014'														, ; //X6_DESC2
	'SEFAZ/RJ 821/2014'														, ; //X6_DSCSPA2
	'Resolution SEFAZ/RJ 821/2014'											, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240430'																, ; //X6_CONTEUD
	'20240430'																, ; //X6_CONTSPA
	'20240430'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_ALTPED'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Usuarios com permissao para alteracao de pedido de'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	' compra'																, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000706/000681'															, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'bragancapaulista@terraverdeagro.com.br'								, ; //X6_CONTEUD
	'bragancapaulista@terraverdeagro.com.br'								, ; //X6_CONTSPA
	'bragancapaulista@terraverdeagro.com.br'								, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0112'																	, ; //X6_FIL
	'TV_VNDPNEU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do vendedor de pneu'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'Codigo do vendedor externo de pneus.'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000567'																, ; //X6_CONTEUD
	'000567'																, ; //X6_CONTSPA
	'000567'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0113'																	, ; //X6_FIL
	'FB_CHAVE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DESCRIC
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCSPA
	'Chave de acesso para autenticacao Comlink'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'6T22GSTSM398V6JDMWRDWXA4SM4JGQ'										, ; //X6_CONTEUD
	'6T22GSTSM398V6JDMWRDWXA4SM4JGQ'										, ; //X6_CONTSPA
	'6T22GSTSM398V6JDMWRDWXA4SM4JGQ'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0113'																	, ; //X6_FIL
	'FB_CODFOR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Fornecedor para autenticacao Comlink'						, ; //X6_DESCRIC
	'Codigo do Fornecedor para autenticacao'								, ; //X6_DSCSPA
	'Codigo do Fornecedor para autenticacao'								, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'203932'																, ; //X6_CONTEUD
	'203932'																, ; //X6_CONTSPA
	'203932'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0113'																	, ; //X6_FIL
	'TV_MAILAD1'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'E-mail administrativo de loja (este deve ser criad'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'o 1 para cada filial e informado os respectivos e-'					, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'mails, se houver necessidade, pode separar por ;'						, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTEUD
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTSPA
	'casabranca@terraverdeagro.com.br'										, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'02'																	, ; //X6_FIL
	'MV_XAGEN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agencia de Recebimento'												, ; //X6_DESCRIC
	'Agencia de Recebimento'												, ; //X6_DSCSPA
	'Agencia de Recebimento'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'02'																	, ; //X6_FIL
	'MV_XBANCO'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Canta de recebimento'													, ; //X6_DESCRIC
	'Canta de recebimento'													, ; //X6_DSCSPA
	'Canta de recebimento'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'341'																	, ; //X6_CONTEUD
	'341'																	, ; //X6_CONTSPA
	'341'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'02'																	, ; //X6_FIL
	'MV_XCONTA'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Conta de recebimento'													, ; //X6_DESCRIC
	'Conta de recebimento'													, ; //X6_DSCSPA
	'Conta de recebimento'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'02'																	, ; //X6_FIL
	'MV_XNAT'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Natureza de transferencia'												, ; //X6_DESCRIC
	'Natureza de transferencia'												, ; //X6_DSCSPA
	'Natureza de transferencia'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'02'																	, ; //X6_FIL
	'TVD_BCOBOL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do banco para boleto automatico'								, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'237;3371;70100;001'													, ; //X6_CONTEUD
	'237;3371;70100;001'													, ; //X6_CONTSPA
	'237;3371;70100;001'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'02'																	, ; //X6_FIL
	'ZZ_CHVITAU'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do PIX no banco Itau'											, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20105067000106'														, ; //X6_CONTEUD
	'20105067000106'														, ; //X6_CONTSPA
	'20105067000106'														, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_CXFIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caixa Geral Financeiro'												, ; //X6_DESCRIC
	'Caja General Financiero'												, ; //X6_DSCSPA
	'Main Financial Cash'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'C01/00001/0000000001'													, ; //X6_CONTEUD
	'C01/00001/0000000001'													, ; //X6_CONTSPA
	'C01/00001/0000000001'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_ESPECIE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Contém tipos de documentos fiscais utilizados na'						, ; //X6_DESCRIC
	'Contiene tipos de documentos fiscales usados en'						, ; //X6_DSCSPA
	'Contain categories of fiscal documents used in'						, ; //X6_DSCENG
	'emissão de notas fiscais'												, ; //X6_DESC1
	'la emision de facturas'												, ; //X6_DSCSPA1
	'the issuance of invoices.'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ND=RPS;1=SPED;3=CTE'													, ; //X6_CONTEUD
	'ND=RPS;1=SPED;3=CTE'													, ; //X6_CONTSPA
	'ND=RPS;1=SPED;3=CTE'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	'735479'																, ; //X6_CONTSPA
	'735479'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_PCAPROV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupo de Aprovacao default que sera utilizado na a'					, ; //X6_DESCRIC
	'Grupo de Aprobacion default que se usadra en la'						, ; //X6_DSCSPA
	'Evaluation Group default that will be used in'							, ; //X6_DSCENG
	'provacao dos Pedidos de Compras.'										, ; //X6_DESC1
	'aprobacion de los Pedidos de Compra.'									, ; //X6_DSCSPA1
	'Purchase Orders evaluation.'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000001'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_TXCOFIN'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Taxa para calculo do COFINS'											, ; //X6_DESCRIC
	'Tasa para calculo del COFINS.'											, ; //X6_DSCSPA
	'Rate for COFINS calculation.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'7.60'																	, ; //X6_CONTEUD
	'3.0'																	, ; //X6_CONTSPA
	'3.0'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_TXPIS'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Taxa para calculo do PIS.'												, ; //X6_DESCRIC
	'Tasa para calculo del PIS.'											, ; //X6_DSCSPA
	'Rate for PIS calculation.'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1.65'																	, ; //X6_CONTEUD
	'0.65'																	, ; //X6_CONTSPA
	'0.65'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240430'																, ; //X6_CONTEUD
	'20240430'																, ; //X6_CONTSPA
	'20240430'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'TV_INVAJU'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DESCRIC
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCSPA
	'Valida se já executou o ajuste do inventário.'							, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'TV_INVCUS'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DESCRIC
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCSPA
	'Valida se já executou o Recalc. Custo Médio para o'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'TV_INVEXP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a exportação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a exportação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'TV_INVIMP'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a importação do inventário.'						, ; //X6_DESCRIC
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCSPA
	'Valida se já executou a importação do inventário.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'TV_INVNFE'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DESCRIC
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCSPA
	'Valida se já executou a Geração da nota fiscal.'						, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'TV_INVSLD'																, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DESCRIC
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCSPA
	'Valida se já executou o Refaz Saldos para o invent'					, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.F.'																	, ; //X6_CONTEUD
	'.F.'																	, ; //X6_CONTSPA
	'.F.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'ZZ_PDAGBL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Agencia do banco na impressao do boleto personaliz'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'ado'																	, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'0809'																	, ; //X6_CONTEUD
	'0809'																	, ; //X6_CONTSPA
	'0809'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0201'																	, ; //X6_FIL
	'ZZ_PDCTBL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Conta do banco quando do boleto personalizado'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'171416'																, ; //X6_CONTEUD
	'171416'																, ; //X6_CONTSPA
	'171416'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_CXFIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caixa Geral Financeiro'												, ; //X6_DESCRIC
	'Caja General Financiero'												, ; //X6_DSCSPA
	'Main Financial Cash'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'C01/00001/0000000001'													, ; //X6_CONTEUD
	'C01/00001/0000000001'													, ; //X6_CONTSPA
	'C01/00001/0000000001'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_ESPECIE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Contém tipos de documentos fiscais utilizados na'						, ; //X6_DESCRIC
	'Contiene tipos de documentos fiscales usados en'						, ; //X6_DSCSPA
	'Contain categories of fiscal documents used in'						, ; //X6_DSCENG
	'emissão de notas fiscais'												, ; //X6_DESC1
	'la emision de facturas'												, ; //X6_DSCSPA1
	'the issuance of invoices.'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'ND=RPS;1=SPED;3=CTE'													, ; //X6_CONTEUD
	'ND=RPS;1=SPED;3=CTE'													, ; //X6_CONTSPA
	'ND=RPS;1=SPED;3=CTE'													, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	'735479'																, ; //X6_CONTSPA
	'735479'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_PCAPROV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupo de Aprovacao default que sera utilizado na a'					, ; //X6_DESCRIC
	'Grupo de Aprobacion default que se usadra en la'						, ; //X6_DSCSPA
	'Evaluation Group default that will be used in'							, ; //X6_DSCENG
	'provacao dos Pedidos de Compras.'										, ; //X6_DESC1
	'aprobacion de los Pedidos de Compra.'									, ; //X6_DSCSPA1
	'Purchase Orders evaluation.'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000001'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_TXCOFIN'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Taxa para calculo do COFINS'											, ; //X6_DESCRIC
	'Tasa para calculo del COFINS.'											, ; //X6_DSCSPA
	'Rate for COFINS calculation.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'7.60'																	, ; //X6_CONTEUD
	'3.0'																	, ; //X6_CONTSPA
	'3.0'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_TXPIS'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Taxa para calculo do PIS.'												, ; //X6_DESCRIC
	'Tasa para calculo del PIS.'											, ; //X6_DSCSPA
	'Rate for PIS calculation.'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1.65'																	, ; //X6_CONTEUD
	'0.65'																	, ; //X6_CONTSPA
	'0.65'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0202'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240430'																, ; //X6_CONTEUD
	'20240430'																, ; //X6_CONTSPA
	'20240430'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0203'																	, ; //X6_FIL
	'MV_ESPECIE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Contem tipos de documentos fiscais utilizados na'						, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'emissao de notas fiscais'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1=SPED;RPS=RPS;A=RPS;NF =RPS;99 =RPS;001=SPED;X=RPS; E=RPS; 2=SPED; ND=RPS', ; //X6_CONTEUD
	'1=SPED;RPS=RPS;A=RPS;NF =RPS;99 =RPS;001=SPED;X=RPS; E=RPS; 2=SPED; ND=RPS', ; //X6_CONTSPA
	'1=SPED;RPS=RPS;A=RPS;NF =RPS;99 =RPS;001=SPED;X=RPS; E=RPS; 2=SPED; ND=RPS', ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0203'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	'735479'																, ; //X6_CONTSPA
	'735479'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0203'																	, ; //X6_FIL
	'MV_TXCOFIN'															, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Taxa para calculo do COFINS'											, ; //X6_DESCRIC
	'Tasa para calculo del COFINS.'											, ; //X6_DSCSPA
	'Rate for COFINS calculation.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'7.60'																	, ; //X6_CONTEUD
	'3.0'																	, ; //X6_CONTSPA
	'3.0'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0203'																	, ; //X6_FIL
	'MV_TXPIS'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Taxa para calculo do PIS.'												, ; //X6_DESCRIC
	'Tasa para calculo del PIS.'											, ; //X6_DSCSPA
	'Rate for PIS calculation.'												, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1.65'																	, ; //X6_CONTEUD
	'0.65'																	, ; //X6_CONTSPA
	'0.65'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0203'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240430'																, ; //X6_CONTEUD
	'20240430'																, ; //X6_CONTSPA
	'20240430'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0203'																	, ; //X6_FIL
	'MV_ZSERIEB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Serie da NF de Serviço - Por Filial'									, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'RPS'																	, ; //X6_CONTEUD
	'RPS'																	, ; //X6_CONTSPA
	'RPS'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0301'																	, ; //X6_FIL
	'MV_CXFIN'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Caixa Geral Financeiro'												, ; //X6_DESCRIC
	'Caja General Financiero'												, ; //X6_DSCSPA
	'Main Financial Cash'													, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'C01/00001/0000000001'													, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0301'																	, ; //X6_FIL
	'MV_ESPECIE'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Contém tipos de documentos fiscais utilizados na'						, ; //X6_DESCRIC
	'Contiene tipos de documentos fiscales usados en'						, ; //X6_DSCSPA
	'Contain categories of fiscal documents used in'						, ; //X6_DSCENG
	'emissão de notas fiscais'												, ; //X6_DESC1
	'la emision de facturas'												, ; //X6_DSCSPA1
	'the issuance of invoices.'												, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'1=SPED;ND=RPS;'														, ; //X6_CONTEUD
	'1=SPED;RPS=RPS;A=RPS;NF =RPS;99=RPS;'									, ; //X6_CONTSPA
	'1=SPED;RPS=RPS;A=RPS;NF =RPS;99=RPS;'									, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0301'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	'735479'																, ; //X6_CONTSPA
	'735479'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0301'																	, ; //X6_FIL
	'MV_PCAPROV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupo de Aprovacao default que sera utilizado na a'					, ; //X6_DESCRIC
	'Grupo de Aprobacion default que se usadra en la'						, ; //X6_DSCSPA
	'Evaluation Group default that will be used in'							, ; //X6_DSCENG
	'provacao dos Pedidos de Compras.'										, ; //X6_DESC1
	'aprobacion de los Pedidos de Compra.'									, ; //X6_DSCSPA1
	'Purchase Orders evaluation.'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000001'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0301'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20230131'																, ; //X6_CONTEUD
	'20200831'																, ; //X6_CONTSPA
	'20160831'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0401'																	, ; //X6_FIL
	'MV_PCAPROV'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Grupo de Aprovacao default que sera utilizado na a'					, ; //X6_DESCRIC
	'Grupo de Aprobacion default que se usadra en la'						, ; //X6_DSCSPA
	'Evaluation Group default that will be used in'							, ; //X6_DSCENG
	'provacao dos Pedidos de Compras.'										, ; //X6_DESC1
	'aprobacion de los Pedidos de Compra.'									, ; //X6_DSCSPA1
	'Purchase Orders evaluation.'											, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'000001'																, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0401'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20230131'																, ; //X6_CONTEUD
	'20200831'																, ; //X6_CONTSPA
	'20160831'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0501'																	, ; //X6_FIL
	'MV_MIL0005'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Codigo do Concessionario no portal de Garantia'						, ; //X6_DESCRIC
	'Codigo do Concesionario en John Deere'									, ; //X6_DSCSPA
	'Code of John Deere Car Dealer'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	''																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	'201461'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0501'																	, ; //X6_FIL
	'MV_MIL0111'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Gera apontamento no intervalo do período. Opções'						, ; //X6_DESCRIC
	'Genera apunte en intervalo del período. Opciones'						, ; //X6_DSCSPA
	'Generates an annotation in period interval. Option'					, ; //X6_DSCENG
	'0=Não apont. / 1=Aponta. Formato: xxx, sendo'							, ; //X6_DESC1
	'0=No apunta / 1=Apunta. Formato: xxx, siendo'							, ; //X6_DSCSPA1
	'0=Does not annotate/1=Annotates Format: xxx, being'					, ; //X6_DSCENG1
	'1º=Intervalo 1, 2º=Refeição, 3º Intervalo 2'							, ; //X6_DESC2
	'1º=Intervalo 1, 2º=Comida, 3º Intervalo 2'								, ; //X6_DSCSPA2
	'1st=Interval 1,2nd=Meal,3rd=Interval 2'								, ; //X6_DSCENG2
	'000'																	, ; //X6_CONTEUD
	'000'																	, ; //X6_CONTSPA
	'000'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0501'																	, ; //X6_FIL
	'MV_MUNIC'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Utilizado para identificar o codigo dado a  secre-'					, ; //X6_DESCRIC
	'Usado para identificar el codigo dado a la Secre-'						, ; //X6_DSCSPA
	'Used to identify the code given from the'								, ; //X6_DSCENG
	'taria das financas do municipio para recolher o'						, ; //X6_DESC1
	'taria de Finanzas del municipio para recaudar'							, ; //X6_DSCSPA1
	'department of finances of the city for collecting'						, ; //X6_DSCENG1
	'ISS.'																	, ; //X6_DESC2
	'ISS.'																	, ; //X6_DSCSPA2
	'ISS tax.'																, ; //X6_DSCENG2
	'735479'																, ; //X6_CONTEUD
	'735479'																, ; //X6_CONTSPA
	'735479'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'0501'																	, ; //X6_FIL
	'MV_ULMES'																, ; //X6_VAR
	'D'																		, ; //X6_TIPO
	'Data ultimo fechamento do estoque.'									, ; //X6_DESCRIC
	'Fecha del ultimo cierre de stock.'										, ; //X6_DSCSPA
	'Inventory last closing date.'											, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'20240430'																, ; //X6_CONTEUD
	'20240430'																, ; //X6_CONTSPA
	'20240430'																, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSX6 ) )

dbSelectArea( "SX6" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX6 )
	lContinua := .F.
	lReclock  := .F.

	If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
		lContinua := .T.
		lReclock  := .T.
		AutoGrLog( "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]" )
	EndIf

	If lContinua
		If !( aSX6[nI][1] $ cAlias )
			cAlias += aSX6[nI][1] + "/"
		EndIf

		RecLock( "SX6", lReclock )
		For nJ := 1 To Len( aSX6[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
			EndIf
		Next nJ
		dbCommit()
		MsUnLock()
	EndIf

	oProcess:IncRegua2( "Atualizando Arquivos (SX6) ..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
             Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Parâmetro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta só com Empresas
// 3 - Monta só com Filiais de uma Empresa
//
// Parâmetro  aMarcadas
// Vetor com Empresas/Filiais pré marcadas
//
// Parâmetro  cEmpSel
// Empresa que será usada para montar seleção
//---------------------------------------------
Local   aRet      := {}
Local   aSalvAmb  := GetArea()
Local   aSalvSM0  := {}
Local   aVetor    := {}
Local   cMascEmp  := "??"
Local   cVar      := ""
Local   lChk      := .F.
Local   lOk       := .F.
Local   lTeveMarc := .F.
Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

Local   aMarcadas := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "Máscara Empresa ( ?? )"  Of oDlg
oSay:cToolTip := oMascEmp:cToolTip

@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Seleção" Of oDlg
oButInv:SetCss( CSSBOTAO )
@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
oButMarc:SetCss( CSSBOTAO )
@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
oButDMar:SetCss( CSSBOTAO )
@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "UpdPAgric" ) ) ) ;
Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
oButOk:SetCss( CSSBOTAO )
@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
oButCanc:SetCss( CSSBOTAO )

Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] := lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0

Função de processamento abertura do SM0 modo exclusivo

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0( lShared )
Local lOpen := .F.
Local nLoop := 0

If FindFunction( "OpenSM0Excl" )
	For nLoop := 1 To 20
		If OpenSM0Excl(,.F.)
			lOpen := .T.
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
Else
	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
EndIf

If !lOpen
	MsgStop( "Não foi possível a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog

Função de leitura do LOG gerado com limitacao de string

@author UPDATE gerado automaticamente
@since  30/07/2024
@obs    Gerado por EXPORDIC - V.7.6.3.4 EFS / Upd. V.6.4.1 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
Local cRet  := ""
Local cFile := NomeAutoLog()
Local cAux  := ""

FT_FUSE( cFile )
FT_FGOTOP()

While !FT_FEOF()

	cAux := FT_FREADLN()

	If Len( cRet ) + Len( cAux ) < 1048000
		cRet += cAux + CRLF
	Else
		cRet += CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
		cRet += "LOG Completo no arquivo " + cFile + CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		Exit
	EndIf

	FT_FSKIP()
End

FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
