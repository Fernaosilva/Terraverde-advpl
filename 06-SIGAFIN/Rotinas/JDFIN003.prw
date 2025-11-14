#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#include "rwmake.ch"
#INCLUDE "FWPrintSetup.ch"
#Include 'Protheus.ch'
#Include 'Totvs.ch'

/*/{Protheus.doc} JDFIN003
Impressão de boleto +Bradesco +Itau
@type function
@version 1.0
@author Charlles Reis
@since 26/11/2018
@link https://gkcmp.com.br (Geeker Company)
@history 25/10/2023, Ademar Fernandes Jr., Implementado o projeto Banco do Dia
@return variant, Arquivo do banco
/*/
User Function JDFIN003(cNota,cSerie,oDanfe,cFilProc,nRec, lDbg)
	Local aCpos  	:= {}
	Local _aCores 	:= {}
	Local lInverte 	:= .F.
	Local oBtnConf  := NIL
	Local oBtnSair  := NIL
	Local cFilBkp	:= cFilAnt
	Local cArq		:= ""
	local lPadCon	:= SuperGetMV("ZZ_PDCNBR", .F., .T.)
	local lBcoDia	:= SuperGetMV("ZZ_BCODIA", .F., .T.)	//-Indica se deve usar o Banco do Dia ou pegar dos Parâmetros da rotina
	local cPdBanco	:= SuperGetMV("ZZ_PDABCL", .F., "237")	//-Banco padrao para impressao do boleto
	local cPdAgencia:= SuperGetMV("ZZ_PDAGBL", .F., "3371")	//-Agencia do banco na impressao do boleto personalizado
	local cPdConta	:= SuperGetMV("ZZ_PDCTBL", .F., "33220")//-Conta do banco quando do boleto personalizado
	local cPdSub	:= SuperGetMV("ZZ_PDSUBL", .F., "001")	//-Sub conta na impressao do boleto

	Private aBcoDia	:= {}
	Private nOpc 	:= 0
	Private _oDlg   := NIL
	Private oMark  	:= NIL
	Private cMark  	:= GetMark()
	Private oDuplic
	Private cPerg 	:= PADR(("FBBOLTRS"+ cFilAnt),LEN(SX1->X1_GRUPO)," ")
	Private cNomeArq:= ""
	Private cArqPDF	:= ""
	Private lOk		:= Nil
	Private lAuto	:= .F.
	Private aDadosB	:= StrTokArr(SuperGetMv("TVD_BCOBOL", .F., {}, cFilAnt),";")
	Private cPDFBol	:= ""
	Private cPDFNota:= ""
	Private cNroDoc := ""
	Private _lSent	:= .T.
	Private lTeste	:= .F.
	Private	lDebug	:= .F.

	Default lDbg	:= .F.
	Default cNota	:= ""
	Default cSerie	:= ""
	Default oDanfe 	:= Nil
	Default cFilProc:= xFilial("SE1")
	Default nRec	:= 0

	lTeste 	:= lDbg
	lAuto 	:= Iif(!Empty(cNota),.T.,.F.)

	ValidPerg()

	//-Busca qual o Banco do Dia a ser utilizados para gerar os Boletos!
	if lBcoDia
		aBcoDia := U_TvBcoDia()

		MV_PAR05 := aBcoDia[2]
		MV_PAR06 := aBcoDia[3]
		MV_PAR07 := aBcoDia[4]
		MV_PAR08 := aBcoDia[5]
	endif

	if !lAuto

		if !lBcoDia .And. lPadCon
			u_zAtuPerg(cPerg, "MV_PAR05", PadR(AllTrim(cPdBanco)	, TamSX3("EE_CODIGO"	)[1]))
			u_zAtuPerg(cPerg, "MV_PAR06", PadR(AllTrim(cPdAgencia)	, TamSX3("EE_AGENCIA"	)[1]))
			u_zAtuPerg(cPerg, "MV_PAR07", PadR(AllTrim(cPdConta)	, TamSX3("EE_CONTA"		)[1]))
			u_zAtuPerg(cPerg, "MV_PAR08", PadR(AllTrim(cPdSub)		, TamSX3("EE_SUBCTA"	)[1]))
		endIf

		if !Pergunte(cPerg, .T.)
			Return
		else
			lOk := .T.
			cArqPDF := strtran(LOWER("BOLETO_"+DTOS(DATE())+STRTRAN(TIME(),":","")+".PDF")," ","_")
		endif

		//-Valida se o Banco Padrao ou "do Dia" foi alterado nas perguntas!
		if !lBcoDia .And. lPadCon .And.;
			(	Alltrim( MV_PAR05 ) != Alltrim( cPdBanco 	) 	.OR.;	
				Alltrim( MV_PAR06 ) != Alltrim( cPdAgencia 	) 	.OR.;
				Alltrim( MV_PAR07 ) != AllTrim( cPdConta	) 	.OR.;
				Alltrim( MV_PAR08 ) != AllTrim( cPdSub		)  	)
			
			MsgStop("Dados diferente do padrao. Favorentrar na rotina novamente, sem alterar os dados do banco.")
			return

		elseif lBcoDia
			MV_PAR05 := aBcoDia[2]
			MV_PAR06 := aBcoDia[3]
			MV_PAR07 := aBcoDia[4]
			MV_PAR08 := aBcoDia[5]
		endIf
	else

		if !lBcoDia .And. Empty(aDadosB)
			MsgStop("Parâmbro TVD_BCOBOL não foi preenchido corretamente para esta filial.")
			Return
		endif

		Pergunte(cPerg, .F.)
		MV_PAR01 := cSerie
		MV_PAR02 := cSerie
		MV_PAR03 := cNota
		MV_PAR04 := cNota

		if !lBcoDia
			MV_PAR05 := aDadosB[1]
			MV_PAR06 := PadR(AllTrim(aDadosB[2]),TamSX3("EE_AGENCIA")[1])
			MV_PAR07 := PadR(AllTrim(aDadosB[3]),TamSX3("EE_CONTA")[1])
			MV_PAR08 := PadR(AllTrim(aDadosB[4]),TamSX3("EE_SUBCTA")[1])
		else
			MV_PAR05 := aBcoDia[2]
			MV_PAR06 := aBcoDia[3]
			MV_PAR07 := aBcoDia[4]
			MV_PAR08 := aBcoDia[5]
		endif
		lOk := .T.

		cFilAnt := cFilProc

		if	nRec <> 0
			dbSelectArea("SE1")
			SE1->(dbGoTo(nRec))
			cArqPDF := StrTran(LOWER("BOLETO_"+alltrim(SE1->E1_NOMCLI)+"_"+alltrim(SE1->E1_NUM)+"_"+alltrim(SE1->E1_PARCELA)+".PDF")," ","_")
		else
			cArqPDF := StrTran(LOWER("BOLETO_"+alltrim(SF2->F2_CLIENTE)+"_"+alltrim(SF2->F2_DOC)+"_"+alltrim(SF2->F2_SERIE)+".PDF")," ","_")
		endif

		// cArqPDF := AllTrim(StrTran(cArqPDF,"."," "))	//-2023.11.22
	endif

	if lOk

		//-Bancos Liberados para Uso nesta Customização !!!
		_aBancos:= {}
		aadd(_aBancos, '237') // Banco Bradesco
		aadd(_aBancos, '341') // Banco Itau

		if aScan(_aBancos, MV_PAR05) == 0
			MsgBox('Banco '+ MV_PAR05 +' não liberado para uso.', OemToAnsi('Atenção!'), 'STOP')
			Return
		endif

		// Crio TRB utilizado no MsSelect
		_criaArqT()

		// Define as cores dos itens de legenda.
		_aCores := {}

		// Define quais colunas (campos da MTRB) serao exibidas na MsSelect
		_criaSelect(@aCpos)

		//Carrega os titulos na tabela temporaria
		_CarregaTrb()

		if !lAuto
			DEFINE MSDIALOG _oDlg FROM 0,0 TO oMainWnd:nClientHeight - 70, oMainWnd:nClientWidth - 10 OF oMainWnd PIXEL TITLE "Impressão de Boletos"

			oMark := MsSelect():New("MTRB","OK","",aCpos,@lInverte,@cMark,{10,5,_oDlg:nClientHeight / 2 - 45, _oDlg:nClientWidth / 2 - 20},,,,,_aCores)
			oMark:bMark := {|| _MarkTRB() }

			@ (_oDlg:nClientHeight / 2 - 35), 090  BUTTON "Imprimir"	SIZE 60, 14 ACTION Processa({|| IniciaBol() }) OBJECT oBtnConf
			@ (_oDlg:nClientHeight / 2 - 35), 170  BUTTON "(Des)Marcar"	SIZE 60, 14 ACTION Processa({|| _Markall() }) OBJECT oBtnConf
			@ (_oDlg:nClientHeight / 2 - 35), 250  BUTTON "Sair"		SIZE 60, 14 ACTION _Sair () OBJECT oBtnSair

			ACTIVATE DIALOG _oDlg CENTERED
		else
			Processa({|| cArq := IniciaBol(oDanfe) })
		endif

		//Elimina arquivo de trabalho
		dbSelectArea("MTRB")
		MTRB->(dbCloseArea())
		SET FILTER TO
	endif

	cFilAnt := cFilBkp

Return cArq

/**/
Static Function IniciaBol(_oDanfe)
	// Local cPathMP12       := GetPvProfString(GetEnvServer(),"RootPath","",GetAdv97())	//->"C:\totvs12\homolog\protheus12_data"
	Local cStartPath      := ""		//-GetPvProfString( GetEnvServer(), "StartPath", "", GetAdv97() )	//->"\system\"
	Local cPathBoleto     := MsDocPath()
	Local cEmailCli       := ""
	Local cEmailCop       := ""
	Local cBodyMail       := ""
	Local aInfo           := {}
	Local aAnexos         :={"", ""}
	Local cArqRel         := ""
	//Local cPDFNota		:= ""
	Local cFilePrint      := ""
	Local lAdjustToLegacy := .F.
	Local lDisabeSetup    := .T.
	Local _lDanfe         := (_oDanfe <> Nil)

	if	lAuto

		if !Empty(cPathBoleto)

			cPathBoleto	:= AllTrim(cPathBoleto)
			if !File( cPathBoleto )
				MakeDir(cPathBoleto)
			endif
			if SubStr(cPathBoleto,Len(cPathBoleto),1) <> "\"
				cPathBoleto	+= "\"
			endif

			cPathBoleto := cPathBoleto+alltrim(FwCodEmp())
			if !File( cPathBoleto )
				MakeDir(cPathBoleto)
			endif

			cPathBoleto := cPathBoleto+"\"+"boleto_automatico"
			if !File( cPathBoleto )
				MakeDir(cPathBoleto)
			endif

			cPathBoleto := cPathBoleto+"\"
		endif

		if !Empty(cPathBoleto)
			if File( cPathBoleto + cArqPDF  )
				FErase( cPathBoleto + cArqPDF   )
			endif
		else
			FErase( cArqPDF  )
		endif
	endif

	if	( lAuto .and. isBlind() ) .or. lDebug
		oDuplic := FWMSPrinter():New( cArqPDF ,IMP_PDF,lAdjustToLegacy,cPathBoleto,lDisabeSetup,,@oDuplic,,.T.,,,.F.)
		oDuplic:CPATHPDF := cPathBoleto
		oDuplic:lInJob := .t.
	else
		oDuplic := FWMSPrinter():New( cArqPDF ,IMP_PDF,lAdjustToLegacy,cStartPath,,,@oDuplic,,,,,.T.)
	endif

	oDuplic:SetResolution(72)
	oDuplic:SetPortrait()

	oDuplic:SetPaperSize(DMPAPER_A4)
	oDuplic:SetMargin(10,10,10,10)

	processa({|| FBBOL001(@aInfo)}, "Buscando Dados...")

	oDuplic:Preview()

	if	lAuto

		if oDuplic:cPathPDF != cPathBoleto .and. oDuplic:nDevice  == IMP_PDF
			cPathBoleto := oDuplic:cPathPDF
		endif

		cPDFBol 	:= StrTran(oDuplic:cFilePrint,"rel","pdf")
		cEmailCli  	:= SA1->A1_EMAIL  //ja esta posicionado no cliente
		cEmailCop 	:= SA1->A1_XEMAILCO
		cCCo 		:= ""
		cBodyMail   := MontaHtml(aInfo)

		if	!File(cPDFBol)

			File2Printer( oDuplic:cFilePrint, "PDF" )
			Sleep(3000) //Aguarda 3 segundos

			cArqRel := cPathBoleto + StrTran(oDuplic:cFileName,"rel","pdf")

			if	!File(cPDFBol)

				cNewFile := cPDFBol
				cPDFBol  := StrTran(cPDFBol,"pdf","pd_")

				If	!File(cPDFBol)
					ConOut("Erro no nome do arquivo.")
				EndIf

				if FRENAME(cPDFBol, cNewFile) = -1
					ConOut("Erro na operação: " + STR(FERROR()))
				else
					cPDFBol := cNewFile
				endif
			EndIf

			If	!__CopyFile( cPDFBol, cArqRel )
				ConOut("[1] Erro ao copiar o arquivo.")
			EndIf

			sleep(1000)
		endif

		if	_lDanfe

			cPDFNota	:= cPathBoleto +  StrTran(_oDanfe:cFileName,"rel","pdf")

			if 	!File(cPDFNota)

				File2Printer( _oDanfe:cFilePrint, "PDF" )

				Sleep(2000) //Aguarda 2 segundos

				cPDFNota	:= cPathBoleto +  StrTran(_oDanfe:cFileName,"rel","pdf")
				cFilePrint	:= StrTran(_oDanfe:cFilePrint,"rel","pdf")

				if	File(cFilePrint)

					if	__CopyFile( cFilePrint, cPDFNota )
						Sleep(2000) //Aguarda 2 segundos
					else
						Alert("Não foi possível copiar o arquivo: " + cFilePrint + " para a pasta destino.")
					endif
				else
					Alert("Falha ao gerar o pdf da nota para enviar juntamente por e-mail")
				endif
			endif
		endif

		aAnexos := { cPDFBol, cPDFNota }

		//boleto: renomeia para o numero do titulo + parcela + emissao
		if	!empty(aAnexos[1])

			nPos 	:= rAt("\",aAnexos[1])
			cDir	:= substr(aAnexos[1],1,nPos)
			cPDFBol := cDir + "boleto_" + AllTrim(SE1->E1_NUM) + "_" + iif(!empty(SE1->E1_PARCELA),AllTrim(SE1->E1_PARCELA),"uni") + "_" + DTOS(SE1->E1_EMISSAO) + "_" + StrTran(Time(),":","") + ".pdf"

			if FRENAME(aAnexos[1], cPDFBol) = -1
				ConOut("Erro na operação: " + STR(FERROR()))
			else
				aAnexos[1] := cPDFBol
			endif
		endif

		//nota fiscal: renomeia para numero + serie + emissao
		if	!empty(aAnexos[2])

			nPos 	 := rAt("\",aAnexos[2])
			cDir	 := substr(aAnexos[2],1,nPos)
			cPDFNota := cDir + "nota_fiscal_" + AllTrim(SF2->F2_DOC) + "_" + AllTrim(SF2->F2_SERIE) + "_" + DTOS(SF2->F2_EMISSAO) + "_" + StrTran(SF2->F2_HORA,":","") + ".pdf"

			if FRENAME(aAnexos[2], cPDFNota) = -1
				ConOut("Erro na operação: " + STR(FERROR()))
			else
				aAnexos[2] := cPDFNota
			endif
		endif

		cAssunto := Alltrim(FWFilialName())+' - Fatura: [ '+Alltrim(SE1->E1_NUM)+' ]'

		If	lTeste
			// cEmailCli := "charlles.maestro@gmail.com"
			// cEmailCop := "lucasedomingos@terraverdeagro.com.br"
			cEmailCli := "ademar@gkcmp.com.br"
			cEmailCop := ""
		endif

		/*--INICIO-- 
			O envio de e-mail para o cliente estah desabilitado desde 10/2021, aproximadamente !!

		if	( lAuto .and. _lDanfe ) .or. lDebug
			//_lSent := F_MAIL( "", cEmailCli, cEmailCop, cAssunto, cBodyMail, aAnexos, "", .F. )
			If	!_lSent
				MsgAlert("E-mail não enviado para o cliente: " + SA1->A1_COD + "-" + SA1->A1_LOJA + "/Email: " + cEmailCli + "-" + cEmailCop)
			EndIf
		endif
		--FINAL--*/
	endif
return cPDFBol

/**/
static function FBBOL001(CB_RN)
	Local oFont07    	:= TFont():New("Arial",06,06,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 07
	Local oFont07N    	:= TFont():New("Arial",06,06,,.T.,,,,.T.,.F.)	//Fonte Times New Roman 07
	Local oFont08    	:= TFont():New("Arial",08,08,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 08
	Local oFont10    	:= TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)	//Fonte Times New Roman 08
	Local oFont24 	    := TFont():New("Arial",,20,,.T.,,,,,.F.)

	Local oFont12  		:= TFont():New("Arial",,12,,.T.,,,,,.F.)
	// local lTrtItau		:= GetMV("ZZ_TRITBC", .F., .F.)
	// Local oFont14    	:= TFont():New("Arial",14,14,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 08

	Local _x 			:= 0
	Local _j 			:= 0
	Local aDadosEmp		:= {}

	default CB_RN		:= {}

	DbSelectArea("SA6")
	DbSetOrder(1)
	if !DbSeek(xFilial("SA6")+mv_par05 + mv_par06 + mv_par07,.t.)
		MsgBox("Banco / Agencia / Conta nao cadastrados" + chr(13) + mv_par05 + ' / ' + mv_par06 + ' / ' + mv_par07 ,"ATENCAO!!!","STOP")
		Return
	endif

	aadd(aDadosEmp, ALLTRIM(SM0->M0_NOMECOM))													// Nome da Empresa
	aadd(aDadosEmp, SM0->M0_ENDCOB)																// Endereço
	aadd(aDadosEmp, AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB)	// Complemento
	aadd(aDadosEmp, "CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3))			// CEP
	aadd(aDadosEmp, "FONE: " + SM0->M0_TEL)														// Telefones
	aadd(aDadosEmp, "CNPJ: " + tran(SM0->M0_CGC, '@R 99.999.999/9999-99'))						// CNPJ
	aadd(aDadosEmp, "I.E.: " + ALLTRIM(SM0->M0_INSC))											// Inscricao Estadual

	aBitMap := {}
	aadd(aBitMap, alltrim(GetSrvProfString("StartPath",""))+"banco"+mv_par05+".bmp")			// logo do banco
	aadd(aBitMap, alltrim(GetSrvProfString("StartPath",""))+AllTrim(SM0->M0_CODFIL)+"boleto.bmp" )  	    // Logo da Empresa //Add parametro para pegar a logo da empresa para boletos
	aadd(aBitMap, FisxLogo("1") )   				   											// Logo da Empresa // existe mas não está sendo usada

	MTRB->(dbGoTop())

	While MTRB->(!EoF())

		if MTRB->OK == cMark

			nOpc := 0

			dbselectarea("SE1")
			Dbsetorder(1)
			SE1->(DBseek(xFilial("SE1")+MTRB->PREFIXO+MTRB->TITULO+MTRB->PARCELA+MTRB->TIPO ))

			SEE->(DbSelectArea("SEE"))
			SEE->(DbSetOrder(1))
			if SEE->(DbSeek(xFilial("SEE") + mv_par05 + mv_par06 + mv_par07+mv_par08,.f.))
				_nNumBco := val(SEE->EE_FAXATU)
				_nBolIni := val(SEE->EE_FAXINI)
				_nBolFim := val(SEE->EE_FAXFIM)
				_nRecno  :=	SEE->(RECNO())
				_cBcoBol := SEE->EE_CODIGO
				_cAgeBol := SEE->EE_AGENCIA
				_cDigAge := SEE->EE_DVAGE
				_cDigCon := SEE->EE_DVCTA
				_cCtaBol := SEE->EE_CONTA

			elseif SEE->(DbSeek(xFilial("SEE") + mv_par05 + mv_par06 + mv_par07 + mv_par08))
				_nNumBco := val(SEE->EE_FAXATU)
				_nBolIni := val(SEE->EE_FAXINI)
				_nBolFim := val(SEE->EE_FAXFIM)
				_nRecno  :=	SEE->(RECNO())
				_cBcoBol := SEE->EE_CODIGO
				_cAgeBol := SEE->EE_AGENCIA
				_cDigAge := SEE->EE_DVAGE
				_cDigCon := SEE->EE_DVCTA
				_cCtaBol := SEE->EE_CONTA
			else
				MsgBox("Nao Encontrado Dados Param. Bancos.", "ATENCAO!!!","STOP")
				DbSelectArea("SE1")
				Exit
			endif

			if  !(EMPTY(SE1->E1_NUMBCO)) .and. !isblind()
				if SE1->E1_PORTADO == mv_par05
					if lDebug
						_nNumBco := alltrim(SE1->E1_NUMBCO)
						nOpc := 1
					else
						if MsgBox("Boleto " + AllTrim(SE1->E1_NUMBCO) + " Titulo " + SE1->E1_NUM + " ja impresso","Confirma re-impressao??","YESNO")
							_nNumBco := alltrim(SE1->E1_NUMBCO)
							nOpc := 1
						else
							nOpc := 3
							MTRB->(dbSkip())
							Loop
						endif
					endif
				else
					_cTexto := "Boleto " + AllTrim(SE1->E1_NUMBCO) + " Titulo " + SE1->E1_NUM + " ja impresso no Banco " + SE1->E1_PORTADO + chr(13)
					_cTexto += "Este boleto nao sera re-impresso"
					MsgBox(_cTexto, " ATENCAO!!!","STOP")
					nOpc := 3
					MTRB->(dbSkip())
					Loop
				endif
			elseif	!(EMPTY(SE1->E1_NUMBCO)) .and. isblind()
				if SE1->E1_PORTADO == mv_par05
					_nNumBco := SE1->E1_NUMBCO
					nOpc := 1
				else
					nOpc := 3
					MTRB->(dbSkip())
					Loop
				endif
			endif

			aDadosBco := {}
			aDadosBco := {	SEE->EE_CODIGO  						,;	//	[1]	Numero do Banco
							SUBSTR(Alltrim(SA6->A6_NOME),1,15)		,;	//	[2]	Nome do Banco
							SUBSTR(SEE->EE_AGENCIA, 1, 4)			,;	//	[3]	Agência
							SUBSTR(SA6->A6_NUMCON,1,6)				,;	//	[4]	Conta Corrente
							SUBSTR(SA6->A6_DVCTA,1,1) 				,;	//	[5]	Dígito da conta corrente
							SUBSTR(SEE->EE_CODCART,1,3)				,;
							SUBSTR(SEE->EE_DVAGE,1,1)				,;
							AllTrim(SA6->A6_NUMCON)}

			if !Empty(SE1->E1_NUMBCO) // reimpressao

				if aDadosBco[1] == "001"
					cNroDoc	:= SubStr(SE1->E1_NUMBCO,1,5)
				elseif aDadosBco[1] = "237"
					cNroDoc := SubStr(SE1->E1_NUMBCO,1,11)
				elseif aDadosBco[1] == "341"
					cNroDoc := SubStr(SE1->E1_NUMBCO,1,8)
				elseif aDadosBco[1] == "033"
					cNroDoc := SubStr(SE1->E1_NUMBCO,1,12)
				endif

			elseif !Empty(SEE->EE_FAXATU)   // a partir da 2 vez vez

				if aDadosBco[1] == "001"
					cNroDoc	:= StrZero(Val(SEE->EE_FAXATU),5)
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(Val(SEE->EE_FAXATU)+1,5)
					msUnLock()
				elseif aDadosBco[1] = "237"
					cNroDoc := StrZero(Val(SEE->EE_FAXATU),11)
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(Val(SEE->EE_FAXATU)+1,11)
					msUnLock()
				elseif aDadosBco[1] == "341"
					cNroDoc := StrZero(Val(SEE->EE_FAXATU),8)
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(Val(SEE->EE_FAXATU)+1,8)
					msUnLock()
				elseif aDadosBco[1] == "033"
					cNroDoc := StrZero(Val(SEE->EE_FAXATU),12)
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(Val(SEE->EE_FAXATU)+1,12)
					msUnLock()
				endif
			else
				if aDadosBco[1] == "001"
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(1,5)
					msUnLock()
				elseif aDadosBco[1] = "237"
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(1,11)
					msUnLock()
				elseif aDadosBco[1] == "341"
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(1,8)
					msUnLock()
				elseif aDadosBco[1] == "033"
					RecLock("SEE",.f.)
					SEE->EE_FAXATU := StrZero(1,12)
					msUnLock()
				endif
			endif

			nVlrAbat 	:= (SE1->E1_DECRESC + SE1->E1_IRRF + SE1->E1_VRETISS + SE1->E1_INSS + SE1->E1_CSLL + SE1->E1_COFINS + SE1->E1_PIS)
			//nVlrAbat 	:= SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA) - correção do valor na linha digitavel - 03/09/2025
			cParcel  	:= if(Empty(SE1->E1_PARCELA),"00",SE1->E1_PARCELA)

			//Monta codigo de barras ({cCodBarra,cLinDig,cNossoNum})
			CB_RN    := Ret_cBarra(	Subs(aDadosBco[1],1,3)+"9" 			,;//Banco
									Subs(aDadosBco[3],1,4)				,;//Agencia
									aDadosBco[4]						,;//Conta
									aDadosBco[5]						,;//Digito da Conta
									aDadosBco[6]						,;//Carteira
									AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA),;//Documento
									(SE1->E1_SALDO-nVlrAbat)			,;//Valor do Titulo
									SE1->E1_VENCTO						,;//Vencimento
									SEE->EE_CODEMP 						,;//Convenio
									cNroDoc  							,;//Sequencial
									Iif(SE1->E1_DECRESC > 0,.t.,.f.)	,;//Se tem desconto
									SE1->E1_PARCELA						,;//Parcela
									aDadosBco[3])						  //Agencia Completa

			if nOpc == 0
				dbSelectArea("SE1")
				recLock("SE1",.F.)
				SE1->E1_PORTADO	:= mv_par05
				If mv_par05 == "237"
					SE1->E1_NUMBCO 	:= SubStr(CB_RN[3],4,13)
				Else
					SE1->E1_NUMBCO 	:= SubStr(CB_RN[3],5,13)
				EndIf				
				SE1->E1_AGEDEP  := Subs(aDadosBco[3],1,4)
				SE1->E1_CONTA	:= aDadosBco[4]
				//SE1->E1_IDCNAB	:= GeraId()
				msUnlock()
				
				_nNumBco 		:= SE1->E1_NUMBCO
			endif

			// if lTrtItau .and. !Empty(SE1->E1_NUMBCO) .and. AllTrim(SA6->A6_COD) == "341"
			// 	if Empty(SE1->E1_ZZQRCOD)
			// 		U_TVItBlPx(SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
			// 	endIf
			// endIf

			aDadosTit   := {}
			aadd(aDadosTit, SE1->E1_PREFIXO + iif(!Empty(SE1->E1_NFELETR) .and. SE1->E1_NFELETR != StrZero (0, TamSX3("E1_NFELETR")[1]),Alltrim(SE1->E1_NFELETR),Alltrim(SE1->E1_NUM) + iif(!empty(SE1->E1_PARCELA), "-" + SE1->E1_PARCELA,"") ))	// Alterado por Lucas dia 28-10-15
			aadd(aDadosTit, SE1->E1_EMISSAO)						   // Data da emissão do título
			aadd(aDadosTit, Date())									   // Data da emissão do boleto
			aadd(aDadosTit, SE1->E1_VENCTO)   						   // Data do vencimento
			aadd(aDadosTit, SE1->E1_SALDO - SE1->E1_DECRESC - SE1->E1_IRRF - SE1->E1_VRETISS - SE1->E1_INSS - SE1->E1_CSLL - SE1->E1_COFINS - SE1->E1_PIS)		   // Valor do título
			aadd(aDadosTit, CB_RN[3])
			aadd(aDadosTit, DDATABASE)								   // Data do Processamento
			aadd(aDadosTit, SE1->E1_DECRESC)								   // Data do Processamento

			aDadosBanco := {}
			aadd(aDadosBanco, SA6->A6_COD)						       // Numero do Banco
			aadd(aDadosBanco, SA6->A6_NREDUZ)// Nome do Banco
			aadd(aDadosBanco,ALLTRIM(SEE->EE_AGENCIA)+Iif(!EMPTY(SEE->EE_DVAGE),"-"+ALLTRIM(SEE->EE_DVAGE),""))//AGENCIA
			aadd(aDadosBanco,ALLTRIM(SEE->EE_CONTA)+Iif(!EMPTY(SEE->EE_DVCTA),"-"+ALLTRIM(SEE->EE_DVCTA),""))//CONTA
			aadd(aDadosBanco,iif(mv_par05 == '748' ,  ALLTRIM(SEE->EE_AGENCIA) + ALLTRIM(SEE->EE_CODEMP),ALLTRIM(SEE->EE_CODEMP) ))//cedente
			aadd(aDadosBanco,ALLTRIM(SEE->EE_CODEMP)+ Iif(!EMPTY(SEE->EE_DVCTA),"-"+ALLTRIM(SEE->EE_DVCTA),""))//cedente Caixa

			dbselectarea("SA1")
			SA1->(dbsetorder(1))
			SA1->(dbseek(xfilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))

			_xCGCCPF    := Iif(Len(AllTrim(SA1->A1_CGC))<>14,Transform(SA1->A1_CGC,"@R 999.999.999-99"),Transform(SA1->A1_CGC,"@R 99.999.999/9999-99"))
			aDatSacado  := {}
			aadd(aDatSacado, AllTrim(SA1->A1_NOME))									// Razão Social
			aadd(aDatSacado, AllTrim(SA1->A1_COD))  								// Código
			if !Empty(SA1->A1_ENDCOB)
				aadd(aDatSacado, AllTrim(SA1->A1_ENDCOB )+" "+SA1->A1_BAIRROC)		// Endereço
			else
				aadd(aDatSacado, AllTrim(SA1->A1_END )+" "+SA1->A1_BAIRRO)			// Endereço
			endif
			if !Empty(SA1->A1_MUNC)
				aadd(aDatSacado, AllTrim(SA1->A1_MUNC))								// Cidade
				// Cidade
			else
				aadd(aDatSacado, AllTrim(SA1->A1_MUN))								// Cidade
			endif
			if !Empty(SA1->A1_ESTC)
				aadd(aDatSacado, SA1->A1_ESTC)										// Estado
			else
				aadd(aDatSacado, SA1->A1_EST)										// Estado
			endif
			_xCEPBANRI:=SA1->A1_CEP

			if !Empty(SA1->A1_CEPC)
				aadd(aDatSacado, LEFT(SA1->A1_CEPC,5)+"-"+RIGHT(SA1->A1_CEPC,3))	// CEP
				_xCEPBANRI:=SA1->A1_CEPC
			else
				aadd(aDatSacado, LEFT(SA1->A1_CEP,5)+"-"+RIGHT(SA1->A1_CEP,3))		// CEP
				_xCEPBANRI:=SA1->A1_CEP
			endif
			aadd(aDatSacado, _xCGCCPF)

			oDuplic:StartPage()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ BOX: Inciais Padrões				                                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oDuplic:Box(0030 + _x, 0015, 0130 + _x, 0550)
			oDuplic:Box(0160 + _x, 0015, 0430 + _x, 0550)
			oDuplic:Box(0490 + _x, 0015, 0765 + _x, 0550)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Tracejados Entre Comprovantes                         				  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			//Entrega
			for _j := 15 to 550 step 2
				oDuplic:Say( 0135 + _x ,_j + _x, "-",oFont07)
			next _j

			//Recibo Sacado
			for _j := 15 to 550 step 2
				oDuplic:Say( 0470 + _x ,_j + _x, "-",oFont07)
			next _j

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ BOX: Comprovante de Entrega                         				  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oDuplic:Line(0013+ _x, 0120, 0030+ _x, 0120)
			oDuplic:Line(0013+ _x, 0170, 0030+ _x, 0170)
			oDuplic:Line(0105+ _x, 0350, 0105+ _x, 0550)
			oDuplic:Line(0030+ _x, 0350, 0130+ _x, 0350)

			oDuplic:Line(105+ _x, 0430, 0130+ _x, 0430)
			oDuplic:Line(105+ _x, 0480, 0130+ _x, 0480)

			oDuplic:SayBitMap(0008+ _x,0018,aBitMap[2], 50, 20)

			oDuplic:Say(0025+ _x, 0470, "Comprovante de Entrega"                      ,oFont07N)
			oDuplic:Say(0040+ _x, 0018, "Beneficiário"                                ,oFont07)
			oDuplic:Say(0050+ _x, 0018, aDadosEmp[1] +" - "+ aDadosEmp[6]             ,oFont10)
			oDuplic:Say(0060+ _x, 0018, "Pagador",oFont07)
			oDuplic:Say(0070+ _x, 0018, left(aDatSacado[1],55) + " (" + aDatSacado[2] + ")" 		,oFont10)
			oDuplic:Say(0080+ _x, 0018, "Data de Vencimento"                          ,oFont07)
			oDuplic:Say(0090+ _x, 0018, substr(Dtos(aDadosTit[4]),7,2)+"/"+substr(Dtos(aDadosTit[4]),5,2)+"/"+substr(Dtos(aDadosTit[4]),1,4),oFont10)
			oDuplic:Say(0080+ _x, 0100, "Nro. Documento"                              ,oFont07)
			oDuplic:Say(0090+ _x, 0100, aDadosTit[1]                              		,oFont10)
			oDuplic:Say(0080+ _x, 0170, "Moeda"                                       ,oFont07)
			oDuplic:Say(0090+ _x, 0170, "R$"                              		        ,oFont10)
			oDuplic:Say(0080+ _x, 0190, "Valor"                                       ,oFont07)
			oDuplic:Say(0090+ _x, 0190, alltrim(Tran(aDadosTit[5],"@E 9,999,999.99")) ,oFont10)

			oDuplic:Say(0100+ _x, 0018, "Agencia/ Cod. Cedente",oFont07)

			if mv_par05 = '748'
				oDuplic:Say(0110+ _x, 0018 ,Substr(aDadosBanco[5], 1,4)+ "." + Substr(aDadosBanco[5], 5,2) + "." + Substr(aDadosBanco[5], 7,5) ,oFont10)
			elseif mv_par05 = '001' .or. mv_par05 = '237'
				oDuplic:Say(0110+ _x, 0018 ,aDadosBanco[3]+"/"+ aDadosBanco[4],oFont10)
			elseif mv_par05 = '104'
				oDuplic:Say(0110+ _x, 0018 ,aDadosBanco[3]+"/"+ aDadosBanco[6],oFont10)
			else
				oDuplic:Say(0110+ _x, 0018 ,aDadosBanco[3]+"/"+ aDadosBanco[5],oFont10)
			endif

			oDuplic:Say(0100+ _x, 0150, "Nosso Numero",oFont07)
			if	aDadosBanco[1]=='341'
				oDuplic:Say(0110+ _x, 0150 , Left(aDadosTit[6],3)+'/'+substr(aDadosTit[6],5),oFont10)
			else
				oDuplic:Say(0110+ _x, 0150 , aDadosTit[6],oFont10)
			endif

			oDuplic:Say(0040+ _x, 0355, "MOTIVOS DE NÃO ENTREGA(para uso do entregador)",oFont07)
			oDuplic:Say(0060+ _x, 0355, "[  ] Mudou-se",oFont07)
			oDuplic:Say(0080+ _x, 0355, "[  ] Recusado",oFont07)
			oDuplic:Say(0100+ _x, 0355, "[  ] Desconhecido",oFont07)

			oDuplic:Say(0060+ _x, 0400, "[  ] Ausente",oFont07)
			oDuplic:Say(0080+ _x, 0400, "[  ] Não Procurado",oFont07)
			oDuplic:Say(0100+ _x, 0400, "[  ] Endereço Insuficiente",oFont07)

			oDuplic:Say(0060+ _x, 0465, "[  ] Não Existe o Número",oFont07)
			oDuplic:Say(0080+ _x, 0465, "[  ] Falecido",oFont07)
			oDuplic:Say(0100+ _x, 0465, "[  ] Outros (anotar no verso)",oFont07)

			oDuplic:Say(0110+ _x, 0355, "Recebí(emos) o bloqueto",oFont07)
			oDuplic:Say(0120+ _x, 0355, "com os dados ao lado.",oFont07)

			oDuplic:Say(0110+ _x, 0435, "Data",oFont07)
			oDuplic:Say(0110+ _x, 0485, "Assinatura",oFont07)

			if mv_par05=='001'
				oDuplic:Say(0028 + _x , 0125, '001-9' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '001-9' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '001-9' ,oFont24 )
			elseif mv_par05=='341'
				oDuplic:Say(0028 + _x , 0125, '341-7' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '341-7' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '341-7' ,oFont24 )
			elseif mv_par05=='041'
				oDuplic:Say(0028 + _x, 0125, '041-8' ,oFont24 )
				oDuplic:Say(0158 + _x, 0125, '041-8' ,oFont24 )
				oDuplic:Say(0488 + _x, 0125, '041-8' ,oFont24 )
			elseif mv_par05=='399'
				oDuplic:Say(0028 + _x, 0125, '399-9' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '399-9' ,oFont24 )
				oDuplic:Say(0488 + _x, 0125, '399-9' ,oFont24 )
			elseif mv_par05=='237'
				oDuplic:Say(0028 + _x, 0125, '237-2' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '237-2' ,oFont24 )
				oDuplic:Say(0488 + _x, 0125, '237-2' ,oFont24 )
			elseif mv_par05=='033'
				oDuplic:Say(0028 + _x , 0125, '033-7' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '033-7' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '033-7' ,oFont24 )
			elseif mv_par05=='748'
				oDuplic:Say(0028 + _x , 0125, '748-X' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '748-X' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '748-X' ,oFont24 )
			elseif mv_par05=='104'
				oDuplic:Say(0028 + _x , 0125, '104-0' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '104-0' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '104-0' ,oFont24 )
			endif

			oDuplic:Say(0158 + _x, 0250 ,CB_RN[2]    ,oFont12)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³  BOX: Recibo do Sacado                           				  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oDuplic:Line(0143+ _x, 0120, 0160+ _x, 0120)
			oDuplic:Line(0143+ _x, 0170, 0160+ _x, 0170)

			oDuplic:Line(0180+ _x, 0015, 0180+ _x, 0550)
			oDuplic:Line(0200+ _x, 0015, 0200+ _x, 0550)

			oDuplic:Line(0240+ _x, 0100, 0200+ _x, 0100)

			oDuplic:Line(0240+ _x, 0150, 0220+ _x, 0150)
			oDuplic:Line(0220+ _x, 0270, 0200+ _x, 0270)

			oDuplic:Line(0240+ _x, 0320, 0200+ _x, 0320)
			oDuplic:Line(0240+ _x, 0210, 0200+ _x, 0210)

			oDuplic:Line(0220+ _x, 0015, 0220+ _x, 0550)
			oDuplic:Line(0240+ _x, 0015, 0240+ _x, 0550)

			oDuplic:Line(0260+ _x, 0420, 0260+ _x, 0550)
			oDuplic:Line(0280+ _x, 0420, 0280+ _x, 0550)
			oDuplic:Line(0300+ _x, 0420, 0300+ _x, 0550)
			oDuplic:Line(0320+ _x, 0420, 0320+ _x, 0550)

			oDuplic:Line(0160+ _x, 0420, 0340+ _x, 0420)
			oDuplic:Line(0340+ _x, 0015, 0340+ _x, 0550)

			oDuplic:Line(0200+ _x, 0045, 0180+ _x, 0045)

			oDuplic:SayBitMap(0140+ _x,0017,aBitmap[1], 60, 18)

			oDuplic:Say(0140+ _x, 0470, "Recibo do Sacado",oFont07N)

			oDuplic:Say(0165+ _x, 0017, "Local de Pagamento",oFont07)

			if mv_par05 == '041'
				oDuplic:Say(0175+ _x, 0017 ,_CepBR(_xCEPBANRI),oFont10)
			elseif mv_par05 == '399'
				oDuplic:Say(0175+ _x, 0017 ,"Pagar preferencialmente em agencias HSBC" 	,oFont10)
			elseif  mv_par05 == '237'
				oDuplic:Say(0175+ _x, 0017 ,"Pagável preferencialmente nas agencias BRADESCO"   ,oFont10)
			elseif  mv_par05 == '341'
				oDuplic:Say(0175+ _x, 0017 ,"Até o vencimento, preferencialmente no ITAÚ. Após o vencimento, somente no ITAÚ."   ,oFont10)
			elseif  mv_par05 == '033'
				oDuplic:Say(0175+ _x, 0017 ,"Pagável preferencialmente no Grupo Santander."   ,oFont10)
			elseif  mv_par05 == '748'
				oDuplic:Say(0175+ _x, 0017 ,"Pagável preferencialmente nas Coop. de Crédito do Sicredi"   ,oFont10)
			elseif  mv_par05 == '104'
				oDuplic:Say(0175+ _x, 0017 ,"Preferencialmente nas Casas Lotéricas até o valor limite"   ,oFont10)
			else
				oDuplic:Say(0175+ _x, 0017 ,"Pagável em Qualquer Banco até o Vencimento" 	,oFont10)
			endif

			oDuplic:Say(0165+ _x, 0423, "Vencimento",oFont07)
			oDuplic:Say(0175+ _x, 0423 ,substr(Dtos(aDadosTit[4]),7,2)+"/"+substr(Dtos(aDadosTit[4]),5,2)+"/"+substr(Dtos(aDadosTit[4]),1,4),oFont10)
			oDuplic:Say(0193+ _x, 0017, "Beneficiário",oFont07)
			oDuplic:Say(0188+ _x, 0050 ,aDadosEmp[1] +" "+ aDadosEmp[6]              ,oFont10)
			oDuplic:Say(0198+ _x, 0050 , alltrim(SM0->M0_ENDCOB) +",  "+ AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB + " CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)	,oFont08)

			oDuplic:Say(0185+ _x, 0423, "Agencia/Cod. Cedente",oFont07)

			if mv_par05 = '748'
				oDuplic:Say(0195+ _x, 0423 ,Substr(aDadosBanco[5], 1,4)+ "." + Substr(aDadosBanco[5], 5,2) + "." + Substr(aDadosBanco[5], 7,5) ,oFont10)
			elseif mv_par05 = '001' .or. mv_par05 = '237'
				oDuplic:Say(0195+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[4],oFont10)
			elseif mv_par05 = '104'
				oDuplic:Say(0195+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[6],oFont10)
			else
				oDuplic:Say(0195+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[5],oFont10)
			endif

			oDuplic:Say(0205+ _x, 0017, "Data Documento",oFont07)
			oDuplic:Say(0215+ _x, 0017 ,substr(Dtos(aDadosTit[2]),7,2)+"/"+substr(Dtos(aDadosTit[2]),5,2)+"/"+substr(Dtos(aDadosTit[2]),1,4)                        		,oFont10)

			oDuplic:Say(0205+ _x, 0103, "Nro. Documento",oFont07)
			oDuplic:Say(0215+ _x, 0103 ,aDadosTit[1]                                	,oFont10)

			oDuplic:Say(0205+ _x, 0215, "Espécie Doc.",oFont07)
			oDuplic:Say(0215+ _x, 0215 ,'DM'		                                	,oFont10)

			oDuplic:Say(0205+ _x, 0277, "Aceite",oFont07)
			oDuplic:Say(0215+ _x, 0277 ,"N"                                       ,oFont10)

			oDuplic:Say(0205+ _x, 0323, "Data do Processamento",oFont07)
			oDuplic:Say(0215+ _x, 0323 ,substr(Dtos(aDadosTit[7]),7,2)+"/"+substr(Dtos(aDadosTit[7]),5,2)+"/"+substr(Dtos(aDadosTit[7]),1,4)                        		,oFont10)

			oDuplic:Say(0205+ _x, 0423, "Nosso Numero",oFont07)

			if(aDadosBanco[1]=='341')
				oDuplic:Say(0215+ _x, 0423 ,left(aDadosTit[6],3)+'/'+substr(aDadosTit[6],4),oFont10)
			elseif(aDadosBanco[1]=='237')
				oDuplic:Say(0215+ _x, 0423 ,aDadosTit[6],oFont10) //oDuplic:Say(0215+ _x, 0423 ,substr(aDadosTit[6],1,2)+'/'+substr(aDadosTit[6],3),oFont10)
			else
				oDuplic:Say(0215+ _x, 0423 ,aDadosTit[6],oFont10)
			endif

			oDuplic:Say(0225+ _x, 0017, "Uso do Banco",oFont07)
			oDuplic:Say(0225+ _x, 0103, "Carteira",oFont07)
			if(aDadosBanco[1]!='237')
				//oDuplic:Say(0235+ _x , 0103 ,SEE->EE_CODCART + "/" + SEE->EE_VCART            ,oFont10)
				oDuplic:Say(0235+ _x , 0103 ,SEE->EE_CODCART + "/" + SEE->EE_VARCART            ,oFont10)
			else
				oDuplic:Say(0235+ _x , 0103 ,SEE->EE_CODCART 	            ,oFont10)
			endif

			oDuplic:Say(0225+ _x, 0153, "Moeda",oFont07)
			oDuplic:Say(0235+ _x, 0153 ,"R$"                                        	,oFont10)

			oDuplic:Say(0225+ _x, 0213, "Quantidade",oFont07)
			oDuplic:Say(0225+ _x, 0323, "Valor",oFont07)
			oDuplic:Say(0225+ _x, 0423, "(=) Valor do Documento",oFont07)
			oDuplic:Say(0235+ _x, 0423 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)

			if !(aDadosBanco[1]=='341')
				oDuplic:Say(0245+ _x, 0017, "Instruções/Texto de Responsabilidade do Cedente",oFont07n)
			else
				oDuplic:SayBitMap(0265+ _x, 0018,aBitMap[2]     , 90, 40)
				oDuplic:Say(0277+ _x, 0153, "Pague com PIX"     ,oFont24)
				oDuplic:Say(0297+ _x, 0133, "Escaneie o QR Code",oFont24)
				if !Empty(SE1->E1_ZZQRCOD)
					oDuplic:SayBitMap(0245+ _x, 0315, SE1->E1_ZZQRCOD, 70, 70)//Imprime Qr Code do PIx
				endIf
			endIf

			if(aDadosBanco[1]=='001')
				oDuplic:Say( 0265 + _x, 0017, "Cobrar juros de: R$" + Transform((((SE1->E1_SALDO - SE1->E1_DECRESC - SE1->E1_IRRF - SE1->E1_VRETISS - SE1->E1_INSS - SE1->E1_CSLL - SE1->E1_COFINS - SE1->E1_PIS)* 0.01) / 30),"@E 9,999,999.99") + " ao dia.",oFont07n)
			endif

			oDuplic:Say(0280+ _x, 0017, alltrim(MV_PAR09)		,oFont07n)
			if !empty(SEE->EE_FORMEN1)
				oDuplic:Say(0295+ _x, 0017, SEE->EE_FORMEN1,oFont07n)
			endif
			if !empty(SEE->EE_FORMEN2)
				oDuplic:Say(0305+ _x, 0017, SEE->EE_FORMEN2,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT1)
				oDuplic:Say(0315+ _x, 0017, SEE->EE_FOREXT1,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT2)
				oDuplic:Say(0325+ _x, 0017, SEE->EE_FOREXT2,oFont07n)
			endif

			if MV_par05 == "041"
				oDuplic:Say(0340+ _x, 0017, "SAC BANRISUL - 0800 646 1515    OUVIDORIA BANRISUL - 0800 644 2200",oFont07n)
			endif

			oDuplic:Say(0245+ _x, 0423, "(-) Desconto/Abatimanto",oFont07)
			oDuplic:Say(0265+ _x, 0423, "(-) Outras Deduções",oFont07)
			oDuplic:Say(0285+ _x, 0423, "(+) Mora/Multa",oFont07)
			oDuplic:Say(0305+ _x, 0423, "(+) Outros Acréscimos",oFont07)
			oDuplic:Say(0325+ _x, 0423, "(=) Valor Cobrado",oFont07)

			oDuplic:Say(0345+ _x, 0017, "Pagador",oFont07)
			oDuplic:Say(0355+ _x, 0017 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
			oDuplic:Say(0365+ _x, 0017 ,aDatSacado[3]                                                ,oFont10)
			oDuplic:Say(0375+ _x, 0017 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
			oDuplic:Say(0385+ _x, 0017 ,aDatSacado[6]                                                ,oFont10)

			oDuplic:Say(0425+ _x, 0017, "Sacador/Avalista",oFont07)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³  BOX: Ficha de Compensação                             				  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oDuplic:Line(0473+ _x, 0120, 0490+ _x, 0120)
			oDuplic:Line(0473+ _x, 0170, 0490+ _x, 0170)

			oDuplic:Line(0510+ _x, 0015, 0510+ _x, 0550)
			oDuplic:Line(0530+ _x, 0015, 0530+ _x, 0550)
			oDuplic:Line(0550+ _x, 0015, 0550+ _x, 0550)
			oDuplic:Line(0570+ _x, 0015, 0570+ _x, 0550)

			oDuplic:Line(0570+ _x, 0100, 0530+ _x, 0100)

			oDuplic:Line(0570+ _x, 0320, 0530+ _x, 0320)
			oDuplic:Line(0570+ _x, 0210, 0530+ _x, 0210)

			oDuplic:Line(0570+ _x, 0150, 0550+ _x, 0150)
			oDuplic:Line(0550+ _x, 0270, 0530+ _x, 0270)

			oDuplic:Line(0590+ _x, 0420, 0590+ _x, 0550)
			oDuplic:Line(0610+ _x, 0420, 0610+ _x, 0550)
			oDuplic:Line(0630+ _x, 0420, 0630+ _x, 0550)
			oDuplic:Line(0650+ _x, 0420, 0650+ _x, 0550)

			oDuplic:Line(0490+ _x, 0420, 0670+ _x, 0420)
			oDuplic:Line(0670+ _x, 0015, 0670+ _x, 0550)

			oDuplic:Line(0530+ _x, 0045, 0510+ _x, 0045)

			oDuplic:Say(0495+ _x, 0017, "Local de Pagamento",oFont07)

			oDuplic:SayBitMap(0470+ _x,0017,aBitmap[1], 60, 18)

			oDuplic:Say(0488 + _x, 0250 ,CB_RN[2]    ,oFont12)

			if mv_par05 == '041'
				oDuplic:Say(0505+ _x, 0017 ,_CepBR(_xCEPBANRI),oFont10)
			elseif mv_par05 == '399'
				oDuplic:Say(0505+ _x, 0017 ,"Pagar preferencialmente em agencias HSBC" 	,oFont10)
			elseif  mv_par05 == '237'
				oDuplic:Say(0505+ _x, 0017 ,"Pagável preferencialmente nas agencias BRADESCO"   ,oFont10)
			elseif  mv_par05 == '341'
				oDuplic:Say(0505+ _x, 0017 ,"Até o vencimento, preferencialmente no ITAÚ. Após o vencimento, somente no ITAÚ."   ,oFont10)
			elseif  mv_par05 == '033'
				oDuplic:Say(0505+ _x, 0017 ,"Pagável preferencialmente no Grupo Santander."   ,oFont10)
			elseif  mv_par05 == '748'
				oDuplic:Say(0505+ _x, 0017 ,"Pagável preferencialmente nas Coop. de Crédito do Sicredi"   ,oFont10)
			elseif  mv_par05 == '104'
				oDuplic:Say(0505+ _x, 0017 ,"Preferencialmente nas Casas Lotéricas até o valor limite"   ,oFont10)
			else
				oDuplic:Say(0505+ _x, 0017 ,"Pagável em Qualquer Banco até o Vencimento" 	,oFont10)
			endif

			oDuplic:Say(0495+ _x, 0423, "Vencimento",oFont07)
			oDuplic:Say(0505+ _x, 0423 ,substr(Dtos(aDadosTit[4]),7,2)+"/"+substr(Dtos(aDadosTit[4]),5,2)+"/"+substr(Dtos(aDadosTit[4]),1,4),oFont10)
			oDuplic:Say(0523+ _x, 0017, "Beneficiário",oFont07)
			oDuplic:Say(0518+ _x, 0050 ,aDadosEmp[1] +" "+ aDadosEmp[6]              ,oFont10)
			oDuplic:Say(0528+ _x, 0050 , alltrim(SM0->M0_ENDCOB) +",  "+ AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB + " CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)	,oFont08)
			oDuplic:Say(0515+ _x, 0423, "Agencia/Cod. Cedente",oFont07)

			if mv_par05 = '748'
				oDuplic:Say(0525+ _x, 0423 ,Substr(aDadosBanco[5], 1,4)+ "." + Substr(aDadosBanco[5], 5,2) + "." + Substr(aDadosBanco[5], 7,5) ,oFont10)
			elseif mv_par05 = '001' .or. mv_par05 = '237'
				oDuplic:Say(0525+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[4],oFont10)
			elseif mv_par05 = '104'
				oDuplic:Say(0525+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[6],oFont10)
			else
				oDuplic:Say(0525+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[5],oFont10)
			endif
			oDuplic:Say(0535+ _x, 0017, "Data Documento",oFont07)
			oDuplic:Say(0545+ _x, 0017 ,substr(Dtos(aDadosTit[2]),7,2)+"/"+substr(Dtos(aDadosTit[2]),5,2)+"/"+substr(Dtos(aDadosTit[2]),1,4)                        		,oFont10)
			oDuplic:Say(0535+ _x, 0103, "Nro. Documento",oFont07)
			oDuplic:Say(0545+ _x, 0103 ,aDadosTit[1]                                	,oFont10)
			oDuplic:Say(0535+ _x, 0213, "Espécie Doc.",oFont07)
			oDuplic:Say(0545+ _x, 0213 ,'DM'		                                	,oFont10)
			oDuplic:Say(0535+ _x, 0277, "Aceite",oFont07)
			oDuplic:Say(0545+ _x, 0277 ,"N"                                       ,oFont10) //Aqui
			oDuplic:Say(0535+ _x, 0323, "Data do Processamento",oFont07)
			oDuplic:Say(0545+ _x, 0323 ,substr(Dtos(aDadosTit[7]),7,2)+"/"+substr(Dtos(aDadosTit[7]),5,2)+"/"+substr(Dtos(aDadosTit[7]),1,4)                        		,oFont10)
			oDuplic:Say(0535+ _x, 0423, "Nosso Numero",oFont07)

			if(aDadosBanco[1]=='341')
				oDuplic:Say(0545+ _x, 0423 ,left(aDadosTit[6],3)+'/'+substr(aDadosTit[6],4),oFont10)
			elseif(aDadosBanco[1]=='237')
				oDuplic:Say(0545+ _x, 0423 ,aDadosTit[6],oFont10) //oDuplic:Say(0545+ _x, 0423 ,substr(aDadosTit[6],1,2)+'/'+substr(aDadosTit[6],3),oFont10)
			else
				oDuplic:Say(0545+ _x, 0423 ,aDadosTit[6],oFont10)
			endif

			oDuplic:Say(0555+ _x, 0017, "Uso do Banco",oFont07)
			oDuplic:Say(0555+ _x, 0103, "Carteira",oFont07)
			if(aDadosBanco[1]!='237')
				//oDuplic:Say(0565+ _x, 0103 ,SEE->EE_CODCART + "/" + SEE->EE_VCART             ,oFont10)
				oDuplic:Say(0565+ _x, 0103 ,SEE->EE_CODCART + "/" + SEE->EE_VARCART             ,oFont10)
			else
				oDuplic:Say(0565+ _x, 0103 ,SEE->EE_CODCART              ,oFont10)
			endif

			oDuplic:Say(0555+ _x, 0153, "Moeda",oFont07)
			oDuplic:Say(0565+ _x, 0153 ,"R$"                                        	,oFont10)
			oDuplic:Say(0555+ _x, 0213, "Quantidade",oFont07)
			oDuplic:Say(0555+ _x, 0323, "Valor",oFont07)
			oDuplic:Say(0555+ _x, 0423, "(=) Valor do Documento",oFont07)
			oDuplic:Say(0565+ _x, 0423 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)

			if !(aDadosBanco[1]=='341')
				oDuplic:Say(0575+ _x, 0017, "Instruções/Texto de Responsabilidade do Cedente",oFont07n)
			else
				oDuplic:SayBitMap(0595+ _x, 0018,aBitMap[2]     , 90, 40)
				oDuplic:Say(0607+ _x, 0153, "Pague com PIX"     ,oFont24)
				oDuplic:Say(0627+ _x, 0133, "Escaneie o QR Code",oFont24)
				if !Empty(SE1->E1_ZZQRCOD)
					oDuplic:SayBitMap(0575+ _x, 0315, SE1->E1_ZZQRCOD, 70, 70)//Imprime Qr Code do PIx
				endIf
				oDuplic:Say(0727+ _x, 0018,"Após 1 dia de atraso."     , oFont07n)
				oDuplic:Say(0737+ _x, 0018,"Juros de 1,0% a.m"     , oFont07n)
				oDuplic:Say(0747+ _x, 0018,"Multa de 2,0% a.m"     , oFont07n)
			endIf

			if(aDadosBanco[1]=='001')
				oDuplic:Say(0595+ _x, 0017, "Cobrar juros de: R$"+ Transform((((SE1->E1_SALDO - SE1->E1_DECRESC - SE1->E1_IRRF - SE1->E1_VRETISS - SE1->E1_INSS - SE1->E1_CSLL - SE1->E1_COFINS - SE1->E1_PIS)* 0.01) / 30),"@E 9,999,999.99") + " ao dia.",oFont07n)
			endif
			oDuplic:Say(0610+ _x, 0017, alltrim(MV_PAR09),oFont07n)
			if !empty(SEE->EE_FORMEN1)
				oDuplic:Say(0625+ _x, 0017, SEE->EE_FORMEN1,oFont07n)
			endif
			if !empty(SEE->EE_FORMEN2)
				oDuplic:Say(0635+ _x, 0017, SEE->EE_FORMEN2,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT1)
				oDuplic:Say(0645+ _x, 0017, SEE->EE_FOREXT1,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT2)
				oDuplic:Say(0655+ _x, 0017, SEE->EE_FOREXT1,oFont07n)
			endif

			if MV_par05 == "041"
				oDuplic:Say(0670+ _x, 0017, "SAC BANRISUL - 0800 646 1515    OUVIDORIA BANRISUL - 0800 644 2200",oFont07n)
			endif

			oDuplic:Say(0575+ _x, 0423, "(-) Desconto/Abatimanto",oFont07)
			oDuplic:Say(0595+ _x, 0423, "(-) Outras Deduções",oFont07)
			oDuplic:Say(0615+ _x, 0423, "(+) Mora/Multa",oFont07)
			oDuplic:Say(0635+ _x, 0423, "(+) Outros Acréscimos",oFont07)
			oDuplic:Say(0655+ _x, 0423, "(=) Valor Cobrado",oFont07)

			oDuplic:Say(0675+ _x, 0017, "Pagador",oFont07)

			oDuplic:Say(0685+ _x, 0017 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
			oDuplic:Say(0695+ _x, 0017 ,aDatSacado[3]                                                ,oFont10)
			oDuplic:Say(0705+ _x, 0017 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
			oDuplic:Say(0715+ _x, 0017 ,aDatSacado[6]                                                ,oFont10)

			oDuplic:Say(0755+ _x, 0017, "Sacador/Avalista",oFont07)
			oDuplic:Say(0770+ _x, 0470, "Ficha de Compensação",oFont07N)
			oDuplic:Say(0770+ _x, 0380, "Autenticação Mecânica",oFont07)

			//oDuplic:Code128C(0827+ _x,020,CB_RN[1], 55 )
			//oDuplic:Int25( 0780+ _x, 20, CB_RN[1], 0.84, 36.7676, .F., .F., oFont08)
			
			//MsBar("INT25",0827+ _x,020,CB_RN[1],oDuplic,.F.,Nil,Nil,0.028,1.8,Nil,Nil,"A",.F.) 
			//oDuplic:FwMsBar("INT25",0827+ _x,020,CB_RN[1],oDuplic,.F.,,.F.,,1,,,"A",.F.)
			oDuplic:FWMSBAR("INT25",65.5,2, CB_RN[1],oDuplic,.F.,,,,1,.F.,,"A",.F.,,,)

			oDuplic:EndPage()
		endif

		MTRB->(dbSkip())
	Enddo
	MTRB->(dbgotop())
return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³ VALIDPERG ³ Autor ³ Claudio H. Ferreira  ³ Data ³10.06.13  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Cria perguntas no SX1. Se a pergunta ja existir, atualiza. ³±±
±±³          ³ Se houver mais perguntas no SX1 do que as definidas aqui,  ³±±
±±³          ³ deleta as excedentes do SX1.                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ValidPerg()
	local _aArea  := GetArea ()
	local _aRegs  := {}

	_aRegs = {}
//           GRUPO  ORDEM PERGUNT                           PERSPA PERENG VARIAVL   TIPO TAM DEC PRESEL GSC  VALID         VAR01       DEF01              DEFSPA1             DEFENG1             CNT01 VAR02 DEF02             DEFSPA2             DEFENG2            CNT02 VAR03 DEF03   DEFSPA3  DEFENG3  CNT03 VAR04 DEF04  DEFSPA4  DEFENG4  CNT04 VAR05 DEF05   DEFSPA5   DEFENG5  CNT05  F3   PYME   GRPSXG   HELP   PICTURE
	aadd(_aRegs,{cPerg, "01", "Prefixo de:                     ", "",    "",    "mv_ch1", "C", 03, 0,  0,     "G", "",           "mv_par01", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "02", "Prefixo até:                    ", "",    "",    "mv_ch2", "C", 03, 0,  0,     "G", "",           "mv_par02", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "03", "Título de:                      ", "",    "",    "mv_ch3", "C", 09, 0,  0,     "G", "",           "mv_par03", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "04", "Título até:                     ", "",    "",    "mv_ch4", "C", 09, 0,  0,     "G", "",           "mv_par04", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "05", "Banco p/ Emissão:               ", "",    "",    "mv_ch5", "C", 03, 0,  0,     "G", "",           "mv_par05", "",				  "",                 "",                 "",   "",   "",          		 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "A64","S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "06", "Agência:                        ", "",    "",    "mv_ch6", "C", 05, 0,  0,     "G", "",           "mv_par06", "",                "",                 "",                 "",   "",   "",             	 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "07", "Conta:                          ", "",    "",    "mv_ch7", "C", 10, 0,  0,     "G", "",           "mv_par07", "",           	  "",                 "",                 "",   "",   "",    			 "",                "",                "",   "",   "",	   "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "08", "Sub-Conta:                      ", "",    "",    "mv_ch8", "C", 03, 0,  0,     "G", "",           "mv_par08", "",                "",                 "",                 "",   "",   "",         	     "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "09", "Mensagem Extra:                 ", "",    "",    "mv_ch9", "C", 60, 0,  0,     "G", "",           "mv_par09", "",                "",                 "",                 "",   "",   "",   	         "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "10", "Cliente de:               	   ", "",    "",    "mv_cha", "C", 06, 0,  0,     "G", "",           "mv_par10", "",				  "",                 "",                 "",   "",   "",          		 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "SA1","S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "11", "Cliente até:               	   ", "",    "",    "mv_chb", "C", 06, 0,  0,     "G", "",           "mv_par11", "",				  "",                 "",                 "",   "",   "",          		 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "SA1","S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "12", "Emissão de:                     ", "",    "",    "mv_chc", "D", 10, 0,  0,     "G", "",           "mv_par12", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	aadd(_aRegs,{cPerg, "13", "Emissão até:                    ", "",    "",    "mv_chd", "D", 10, 0,  0,     "G", "",           "mv_par13", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })

	Restarea(_aArea)

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ _criaArqT  ³ Autor ³Cláudio H. Ferreira         ³ Data ³ 18/06/13 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Cria área de trabalho.                                            ³±±
±±³          ³                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ FBBOLTRS                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function _criaArqT()

	Local aCampos		:= {}

	aadd(aCampos,{"OK", "C", 02, 0}) // CAMPO DE SELEÇÃO

	aadd(aCampos,{"STATUS", "C", 01, 0})

	aTam:=TamSX3 ("E1_NOMCLI")
	aadd(aCampos,{"Cliente",         aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_PREFIXO")
	aadd(aCampos,{"Prefixo",    aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_NUM")
	aadd(aCampos,{"Titulo",      aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_PARCELA")
	aadd(aCampos,{"Parcela",         aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_VALOR")
	aadd(aCampos,{"Valor",      aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_VENCTO")
	aadd(aCampos,{"Vencimento",   aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_TIPO")
	aadd(aCampos,{"Tipo",   aTam[3],aTam[1],aTam[2]})

	cNomeArq   := CriaTrab(aCampos)
	cIndOrdPag := CriaTrab(Nil,.F.)

	if Select("MTRB") <> 0
		DbSelectArea("MTRB")
		MTRB->(DbCloseArea())
	endif

	dbUseArea( .T., __cRDDNTTS, cNomeArq,"MTRB", .T., .F. )
	IndRegua("MTRB",cNomeArq,"Cliente",,,OemToAnsi("Selecionando Registros...")) // Índice

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ _criaSelect³ Autor ³Claudio H. Ferreira         ³ Data ³ 18/06/13 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Cria vetor utilizado no MsSelect.                                 ³±±
±±³          ³                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ fbboltrs                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function _criaSelect(aCpos)

	dbSelectArea("SX3")
	_nOrdem := IndexOrd()

	SX3->(dbSetOrder(2))

	aadd(aCpos,{"OK",""," "})

	aadd(aCpos,{"STATUS", "", "Status", "@!"})

	SX3->(DbSeek("E1_NOMCLI"))
	aadd(aCpos,{"Cliente","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_PREFIXO"))
	aadd(aCpos,{"Prefixo","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_NUM"))
	aadd(aCpos,{"Titulo","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_PARCELA"))
	aadd(aCpos,{"Parcela","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_VALOR"))
	aadd(aCpos,{"Valor","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_VENCTO"))
	aadd(aCpos,{"Vencimento","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_TIPO"))
	aadd(aCpos,{"Tipo","",X3Titulo(),SX3->X3_PICTURE})

	dbSetOrder(_nOrdem)

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ _CarregaTrb³ Autor ³Claudio H. Ferreira         ³ Data ³ 18/06/13 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Cria area de trabalho com a  duplicata					         ³±±
±±³          ³                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ FB110PCP                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function _CarregaTrb()

	cAliasTmp := GetNextAlias()

	cQuery := " SELECT E1_NOMCLI,E1_PREFIXO,E1_NUM,E1_PARCELA, E1_VALOR, E1_VENCTO, E1_TIPO  "
	cQuery += " FROM "+RetSqlName("SE1")+" SE1 "
	cQuery += " WHERE " + RetSqlCond("SE1") + " AND "
	cQuery += "E1_PREFIXO >= '" + mv_par01 + "' AND "
	cQuery += "E1_PREFIXO <= '" + mv_par02 + "' AND "
	cQuery += "E1_NUM >= '" + mv_par03 + "' AND "
	cQuery += "E1_NUM <= '" + mv_par04 + "' AND "
	if	lAuto .and. !isBlind() //executando via menu (SPEDNFE/Ponto de Entrada)
		cQuery += "E1_CLIENTE >= '" + SF2->F2_CLIENTE + "' AND "
		cQuery += "E1_CLIENTE <= '" + SF2->F2_CLIENTE + "' AND "
		cQuery += "E1_EMISSAO >= '" + DTOS(SF2->F2_EMISSAO) + "' AND "
		cQuery += "E1_EMISSAO <= '" + DTOS(SF2->F2_EMISSAO) + "' AND "
	elseif	!lAuto .and. !isBlind()	//executando via rotina do boleto pelo menu
		cQuery += "E1_CLIENTE >= '" + mv_par10 + "' AND "
		cQuery += "E1_CLIENTE <= '" + mv_par11 + "' AND "
		cQuery += "E1_EMISSAO >= '" + DTOS(mv_par12) + "' AND "
		cQuery += "E1_EMISSAO <= '" + DTOS(mv_par13) + "' AND "
		//cQuery += "E1_NUMBCO = '' AND " // Add para re-impressão erro de duplicidade
	endif
	cQuery += "NOT (E1_VENCREA = E1_EMISSAO) AND "
	cQuery += "E1_SALDO > 0"

	cQuery := ChangeQuery(cQuery)

	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasTmp, .F., .T. )

	Do While !(cAliasTmp)->(EoF())
	
		dbSelectArea("MTRB")
		RecLock("MTRB",.T.)
			Replace MTRB->OK        	With cMark
			Replace MTRB->STATUS    	With " "
			Replace MTRB->CLIENTE  		With (cAliasTmp)->E1_NOMCLI
			Replace MTRB->PREFIXO   	With (cAliasTmp)->E1_PREFIXO
			Replace MTRB->TITULO    	With (cAliasTmp)->E1_NUM
			Replace MTRB->PARCELA   	With (cAliasTmp)->E1_PARCELA
			Replace MTRB->VALOR	    	With (cAliasTmp)->E1_VALOR
			Replace MTRB->VENCIMENTO    With Stod((cAliasTmp)->E1_VENCTO)
			Replace MTRB->TIPO    		With (cAliasTmp)->E1_Tipo
		MTRB->(MsUnLock())
	
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->(dbCloseArea())

	dbSelectArea("MTRB")
	MTRB->(dbGotop())

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ _Sair      ³ Autor ³Claudio H. Ferreira         ³ Data ³ 23/11/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Fecha rotina                                                       ±±
±±³          ³                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ FB110PCP                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function _Sair()
	_oDlg:End()
Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ _MarkTRB   ³ Autor ³Claudio H. Ferreira         ³ Data ³ 23/11/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Função executada ao marcar algum item no grid.                     ±±
±±³          ³                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ FBBOLTRS                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function _MarkTRB()

	RecLock("MTRB",.F.)
		if Marked("OK")
			MTRB->OK := cMark
		else
			MTRB->OK := ""
		endif
	MsUnLock()

	oMark:oBrowse:Refresh()

Return()

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ _MarkAll   ³ Autor ³Claudio H. Ferreira         ³ Data ³ 13/05/13 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Função executada para marcar todos os registros validos.           ±±
±±³          ³                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ FBBOLTRS                                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function _MarkAll()

	MTRB->(dbGoTop())
	While MTRB->(!EoF())
	
		RecLock("MTRB",.F.)
			if !Marked("OK")
				MTRB->OK := cMark
			else
				MTRB->OK := ""
			endif
		MsUnLock()

		MTRB->(dbSkip())
	Enddo

	MTRB->(dbGoTop())
	oMark:oBrowse:Refresh()

Return()


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Chamada da Funcao Modulo10()                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function Modulo10(cData)

	Local L,D,P := 0
	Local B     := .F.
	L := Len(cData)
	B := .T.
	D := 0
	While L > 0
		P := Val(SubStr(cData, L, 1))
		if (B)
			P := P * 2
			if P > 9
				P := P - 9
			endif
		endif
		D := D + P
		L := L - 1
		B := !B
	Enddo
	D := 10 - (Mod(D,10))
	if D = 10
		D := 0
	endif

Return(D)

/**/
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,_lTemDesc,_cParcela,_cAgCompleta,_NSOMA,_NDVCALC,_NmULT,_CNOSSONUM,_LGEROU,_AAREA)

	Local cCodEmp 		:= StrZero(Val(SubStr(cConvenio,1,6)),6)
	Local cNumSeq 		:= strzero(val(Right(cSequencial,5)),5)
	Local blvalorfinal 	:= strzero((nValor*100),10)
	Local cNNumSDig 	:= cCpoLivre := cCBSemDig := cCodBarra := cNNum := cFatVenc := ''
	Local cNossoNum		:= ""
	Local _cDigito 		:= ""
	Local _cSuperDig 	:= ""

	if Substr(cBanco,1,3) == '341'
		cCarteira := Right(cCarteira,3)
	else
		cCarteira := Right(cCarteira,2)
	endif

	_cParcela := NumParcela(_cParcela)

	//Fator Vencimento - POSICAO DE 06 A 09 
	if dvencimento < CtoD("21/02/2025")
		cFatVenc := STRZERO(dvencimento - CtoD("07/10/1997"),4)
	else
		cFatVenc := STRZERO(dvencimento - CtoD("29/05/2022"),4)
	endif
	
	//Campo Livre (Definir campo livre com cada banco)

	if Substr(cBanco,1,3) == "001"  // Banco do brasil

		if Len(AllTrim(cConvenio)) == 7

			//Nosso Numero sem digito
			cNNumSDig := AllTrim(cConvenio)+strzero(val(cSequencial),10)
			
			//Nosso Numero com digito
			cNNum := cNNumSDig

			//Nosso Numero para impressao
			cNossoNum := cNNumSDig

			//Campo Livre
			cCpoLivre := "000000"+cNNumSDig+cCarteira

		else

			//Nosso Numero sem digito
			cNNumSDig := cCodEmp+cNumSeq
			//Nosso Numero com digito
			cNNum := cNNumSDig + modulo11(cNNumSDig,SubStr(cBanco,1,3))

			//Nosso Numero para impressao
			cNossoNum := cNNumSDig +"-"+ modulo11(cNNumSDig,SubStr(cBanco,1,3))

			//Campo Livre
			cCpoLivre := cNNumSDig+cAgencia + StrZero(Val(cConta),8) + cCarteira

		endif

	elseif Substr(cBanco,1,3) == "033"

		cNumSeq := strzero(val(cNumSeq),12)

		//Nosso Numero sem digito
		cNNumSDig := cNumSeq

		//Nosso Numero
		cNNum := cNumSeq

		//Nosso Numero para impressao
		cNossoNum := cNNumSDig +"-"+ sMod11(cNNumSDig,2,9)

		cCpoLivre := "9" + cCodEmp + cNNumSDig + sMod11(cNNumSDig,2,9) + "0" + cCarteira

	elseif Substr(cBanco,1,3) == "389" // Banco mercantil
	
		//Nosso Numero sem digito
		cNNumSDig := "09"+cCarteira+ strzero(val(cSequencial),6)

		//Nosso Numero
		cNNum := "09"+cCarteira+ strzero(val(cSequencial),6) + modulo11(cAgencia+cNNumSDig,SubStr(cBanco,1,3))

		//Nosso Numero para impressao
		cNossoNum := "09"+cCarteira+ strzero(val(cSequencial),6) +"-"+ modulo11(cAgencia+cNNumSDig,SubStr(cBanco,1,3))

		cCpoLivre := cAgencia + cNNum + StrZero(Val(SubStr(cConvenio,1,9)),9)+Iif(_lTemDesc,"0","2")

	elseif Substr(cBanco,1,3) == "237" // Banco bradesco

		cNrDoc := Right(cSequencial,11)

		//Nosso Numero sem digito
		cNNumSDig := Right(cCarteira,2) + cNrDoc

		//Nosso Numero		
		cNNum := cNNumSDig + AllTrim( modulo11( cNNumSDig ) )

		//Nosso Numero para impressao		
		cNossoNum := Right(cCarteira,2) + '/'+ Right(cNrDoc,11) + '-' + AllTrim( modulo11( cNNumSDig,"237" ) )

		cCpoLivre := cAgencia + Right(cCarteira,2) + cNrDoc + StrZero(Val(cConta),7) + "0"

	elseif Substr(cBanco,1,3)$("341")  // Banco Itau

		//Nosso Numero sem digito
		cNNumSDig := cCarteira+strzero(val(/*cNroDoc*/cSequencial),/*6*/8)/*+ _cParcela*/

		//Nosso Numero
		cNNum := cCarteira+strzero(val(/*cNroDoc*/cSequencial),/*6*/8) /*+_cParcela*/ + AllTrim( Str( modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+cNNumSDig ) ) )

		//Nosso Numero para impressao
		cNossoNum := cCarteira+"/"+strzero(val(/*cNroDoc*/cSequencial),/*6*/8)/*+_cParcela*/ +'-' + AllTrim( Str( modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5) + cNNumSDig ) ) )

		cCpoLivre := cNNumSDig+AllTrim( Str( modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+cNNumSDig ) ) )+StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5)+AllTrim( Str( modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),5) ) ) )+"000"

	elseif Substr(cBanco,1,3) == "453"  // Banco rural
		
		//Nosso Numero sem digito
		cNNumSDig := strzero(val(cSequencial),7)
		
		//Nosso Numero
		cNNum := cNNumSDig + AllTrim( Str( modulo10( cNNumSDig ) ) )
		
		//Nosso Numero para impressao
		cNossoNum := cNNumSDig +"-"+ AllTrim( Str( modulo10( cNNumSDig ) ) )

		cCpoLivre := "0"+StrZero(Val(cAgencia),3) + StrZero(Val(cConta),10)+cNNum+"000"

	elseif Substr(cBanco,1,3) == "399"  // Banco HSBC
		
		//Nosso Numero sem digito
		cNNumSDig := StrZero(Val(SubStr(cConvenio,1,5)),5)+strzero(val(cSequencial),5)
		
		//Nosso Numero
		cNNum := cNNumSDig + modulo11(cNNumSDig,SubStr(cBanco,1,3))
		
		//Nosso Numero para impressao
		cNossoNum := cNNumSDig +"-"+ modulo11(cNNumSDig,SubStr(cBanco,1,3))

		cCpoLivre := cNNum+StrZero(Val(cAgencia),4) + StrZero(Val(cConta),7)+"001"

	elseif Substr(cBanco,1,3) == "422"  // Banco Safra
		
		//Nosso Numero sem digito
		cNNumSDig := strzero(val(cSequencial),8)
		
		//Nosso Numero
		cNNum := cNNumSDig + modulo11(cNNumSDig,SubStr(cBanco,1,3))
		
		//Nosso Numero para impressao
		cNossoNum := cNNumSDig +"-"+ modulo11(cNNumSDig,SubStr(cBanco,1,3))

		cCpoLivre := "7"+StrZero(Val(cAgencia),4) + StrZero(Val(cConta),10)+cNNum+"2"

	elseif Substr(cBanco,1,3) == "479" // Banco Boston
		
		cNumSeq := strzero(val(cSequencial),8)
		cCodEmp := StrZero(Val(SubStr(cConvenio,1,9)),9)
		
		//Nosso Numero sem digito
		cNNumSDig := strzero(val(cSequencial),8)
		
		//Nosso Numero
		cNNum := cNNumSDig + modulo11(cNNumSDig,SubStr(cBanco,1,3))
		
		//Nosso Numero para impressao
		cNossoNum := cNNumSDig +"-"+ modulo11(cNNumSDig,SubStr(cBanco,1,3))

		cCpoLivre := cCodEmp+"000000"+cNNum+"8"

	elseif Substr(cBanco,1,3) == "409" // Banco UNIBANCO
		
		cNumSeq := strzero(val(cSequencial),10)
		cCodEmp := StrZero(Val(SubStr(cConvenio,1,9)),9)
		
		//Nosso Numero sem digito
		cNNumSDig := strzero(val(cSequencial),10)
		
		//Nosso Numero
		_cDigito := modulo11(cNNumSDig,SubStr(cBanco,1,3))
		
		//Calculo do super digito
		_cSuperDig := modulo11("1"+cNNumSDig + _cDigito,SubStr(cBanco,1,3))
		cNNum := "1"+cNNumSDig + _cDigito + _cSuperDig
		
		//Nosso Numero para impressao
		cNossoNum := "1/" + cNNumSDig + "-" + _cDigito + "/" + _cSuperDig
		
		// O codigo fixo "04" e para a combranco som registro
		cCpoLivre := "04" + SubStr(DtoS(dvencimento),3,6) + StrZero(Val(StrTran(_cAgCompleta,"-","")),5) + cNNumSDig + _cDigito + _cSuperDig

	elseif Substr(cBanco,1,3) == "356" // Banco REAL
		
		cNumSeq := strzero(val(cNumSeq),13)
		
		//Nosso Numero sem digito
		cNNumSDig := cNumSeq
		
		//Nosso Numero
		cNNum := cNumSeq
		
		//Nosso Numero para impressao
		cNossoNum := cNNum
		cCpoLivre := StrZero(Val(cAgencia),4) + StrZero(Val(cConta),7) + AllTrim(Str( modulo10( StrZero(Val(cAgencia),4) + StrZero(Val(cConta),7)+cNNumSDig ) ) ) + cNNumSDig

	endif

	//Dados para Calcular o Dig Verificador Geral
	cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre
	
	//Codigo de Barras Completo
	cCodBarra := cBanco + Modulo11(cCBSemDig) + cFatVenc + blvalorfinal + cCpoLivre

	//Digito Verificador do Primeiro Campo                  
	cPrCpo := cBanco + SubStr(cCodBarra,20,5)
	cDvPrCpo := AllTrim(Str(Modulo10(cPrCpo)))

	//Digito Verificador do Segundo Campo
	cSgCpo := SubStr(cCodBarra,25,10)
	cDvSgCpo := AllTrim(Str(Modulo10(cSgCpo)))

	//Digito Verificador do Terceiro Campo
	cTrCpo := SubStr(cCodBarra,35,10)
	cDvTrCpo := AllTrim(Str(Modulo10(cTrCpo)))

	//Digito Verificador Geral
	cDvGeral := SubStr(cCodBarra,5,1)

	//Linha Digitavel
	cLindig := SubStr(cPrCpo,1,5) + "." + SubStr(cPrCpo,6,4) + cDvPrCpo + " "   //primeiro campo
	cLinDig += SubStr(cSgCpo,1,5) + "." + SubStr(cSgCpo,6,5) + cDvSgCpo + " "   //segundo campo
	cLinDig += SubStr(cTrCpo,1,5) + "." + SubStr(cTrCpo,6,5) + cDvTrCpo + " "   //terceiro campo
	cLinDig += " " + cDvGeral              //dig verificador geral
	cLinDig += "  " + SubStr(cCodBarra,6,4)+SubStr(cCodBarra,10,10)  // fator de vencimento e valor nominal do titulo

Return({cCodBarra,cLinDig,cNossoNum})

/**/
STATIC Function _CepBR(_xCEP)

	Local _aArea   := GetArea()
	Local _aAreaSX5:= SX5->(GetArea())
	Local _lRet    := "ATE O VENCIMENTO PAGAR NA REDE BANCARIA"
	Local _xCEPINI := ""
	Local _xCEPFIN := ""

	DbSelectArea("SX5")
	DbSetOrder(1)
	DbSeek(xFilial("SX5")+"ZC",.T.)
	Do While !Eof() .And. SX5->X5_FILIAL==xFilial("SX5") .And. SX5->X5_TABELA == "ZC"
		_xCEPINI :=SubStr(SX5->X5_DESCRI,1,8)
		_xCEPFIN :=SubStr(SX5->X5_DESCRI,1,8)

		// Verifica Se eh Valido
		if left(_xCEP,5) = left(_xCEPINI,5)
			_lRet  :=SubStr(SX5->X5_DESCRI,10,20)
			Exit
		endif

		DbSelectArea("SX5")
		DbSkip()
	Enddo

	RestArea(_aAreaSX5)
	RestArea(_aArea)
Return(_lRet)


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ CHAMADA DA FUNCAO NUMPARCELA()                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function NumParcela(_cParcela)
	Local _cRet := ""
	if ASC(_cParcela) >= 65 .Or. ASC(_cParcela) <= 90
		_cRet := StrZero(Val(Chr(ASC(_cParcela)-16)),2)
	else
		_cRet := StrZero(Val(_cParcela),2)
	endif
Return(_cRet)

/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
	±±³Programa  ³ Modulo11 ³ Autor ³                       ³ Data ³ 29/11/06 ³±±
	±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
	±±³Descri‡…o ³ IMPRESSAO DO BOLETO LASER                                  ³±±
	±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
	±±³Uso       ³ Generico                                                   ³±±
	±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Modulo11(cData,cBanc)
	Local L, D, P := 0

	if cBanc == "001"  // Banco do brasil
		L := Len(cdata)
		D := 0
		P := 10
		While L > 0
			P := P - 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 2
				P := 10
			End
			L := L - 1
		End
		D := mod(D,11)
		if D == 10
			D := "X"
		else
			D := AllTrim(Str(D))
		End
	elseif cBanc == "341" .Or. cBanc == "453" .Or. cBanc == "399" .or. cBanc == "422" // Itau/Mercantil/Rural/HSBC/Safra
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 9
				P := 1
			End
			L := L - 1
		End
		D := 11 - (mod(D,11))

		if (D == 10 .Or. D == 11) .and. (cBanc == "341" .or. cBanc == "422")
			D := 1
		End
		if (D == 1 .Or. D == 0 .Or. D == 10 .Or. D == 11) .and. (cBanc == "289" .Or. cBanc == "453" .Or. cBanc == "399")
			D := 0
		End
		D := AllTrim(Str(D))

	elseif cBanc == "237"// Bradesco Calculo do Modulo11 base 7

		L := Len(cdata)
		D := 0
		P := 2

		While L > 0
			D := D + Val(SubStr(cdata, L, 1)) * P
			P := P + 1
			L := L - 1
			if P = 8
				P:= 2
			End
		End

		if mod(D,11) = 0
			D := str(0)
		else
			D := str(11 - (mod(D,11)))
		End

		if D = str(10)
			D := "P"
		End

		D := AllTrim(D)

	elseif cBanc == "389" //Mercantil
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 9
				P := 1
			End
			L := L - 1
		End
		D := mod(D,11)
		if D == 1 .Or. D == 0
			D := 0
		else
			D := 11 - D
		End
		D := AllTrim(Str(D))
	elseif cBanc == "479"  //BOSTON
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 9
				P := 1
			End
			L := L - 1
		End
		D := Mod(D*10,11)
		if D == 10
			D := 0
		End
		D := AllTrim(Str(D))
	elseif cBanc == "409"  //UNIBANCO
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 9
				P := 1
			End
			L := L - 1
		End
		D := Mod(D*10,11)
		if D == 10 .or. D == 0
			D := 0
		End
		D := AllTrim(Str(D))
	elseif cBanc == "356"  //Real
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 9
				P := 1
			End
			L := L - 1
		End
		D := Mod(D*10,11)
		if D == 10 .or. D == 0
			D := 0
		End
		D := AllTrim(Str(D))

	elseif cBanc == "748"// Sicredi Calculo do Modulo11 base 7

		L := Len(cdata)
		D := 0
		P := 2

		While L > 0
			D := D + Val(SubStr(cdata, L, 1)) * P
			P := P + 1
			L := L - 1
			if P = 8
				P:= 2
			End
		End

		if mod(D,11) = 0
			D := str(0)
		else
			D := str(11 - (mod(D,11)))
		End

		if D = str(10)
			D := "P"
		End

		D := AllTrim(D)
	else

		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			if P = 9
				P := 1
			End
			L := L - 1
		End
		D := 11 - (mod(D,11))
		if (D == 10 .Or. D == 11)
			D := 1
		End
		D := AllTrim(Str(D))
	endif
Return(D)

//--------------------------------------------------------------------------------------+
/*/{Protheus.doc} MontaHtml																

Cria layout HTML para corpo do e-mail a ser enviado.
														
@author    	Joalisson/Charlles									
@version   	1.2																			
@since      Jan/2019
/*/																												
//--------------------------------------------------------------------------------------+
Static Function MontaHtml(aCB_RN_NN)
	local cAux
	Local cBodyMail
	Local cMaskCpf    := "@R 999.999.999-99"
	Local cMaskCnpj	  := "@R 99.999.999/9999-99"

	Begin Sequence

		cBodyMail :='<html>'
		cBodyMail +='	<head>'
		cBodyMail +='		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">'
		cBodyMail +='		<style type="text/css" style="display:none;"><!-- P {margin-top:0;margin-bottom:0;} --></style>'
		cBodyMail +='	</head>'
		cBodyMail +='<body dir="ltr" style="background-color:#efefef; margin:0; padding:10px 0">'
		cBodyMail +='	<div id="divtagdefaultwrapper" style="font-size:12pt;color:#000000;font-family:Calibri,Helvetica,sans-serif;" dir="ltr">'
		cBodyMail +='		<p style="margin-top:0;margin-bottom:0"><br></p>'
		cBodyMail +='		<div style="color: rgb(0, 0, 0);">'
		cBodyMail +='			<div style="background-color:#efefef; margin:0; padding:10px 0">'
		cBodyMail +='				<table width="700" border="0" cellspacing="0" cellpadding="0" bgcolor="#FFFFFF" align="center" style="border-collapse:collapse; font-family:Calibri,Verdana,sans-serif; font-size:13px; border:1px solid #cfcfcf">'
		cBodyMail +='					<tbody>'
		cBodyMail +='						<tr>'
		cBodyMail +='							<td>'
		cBodyMail +='								<table width="100%" border="0" align="center" cellpadding="20" cellspacing="0" style="background-color:#FFF">'
		cBodyMail +='									<tbody>'
		cBodyMail +='										<tr>'
		cBodyMail +='											<td>'
		cBodyMail +='													<div style="float: left;padding-right: 10px; padding-top: 10px;margin-left: 20px;font-family: Calibri;">'
		cBodyMail +='                                                        <p style="font-size: 12px;color: #666666;text-align: left;text-decoration: none;font-family: Calibri;">Concessionário Autorizado John&nbsp;Deere</p>'
		cBodyMail +='														<div>'
		cBodyMail +='															<a style="font-family: Calibri;font-size: 28px;text-decoration: none;font-weight: normal;color: #000;" href="http://www.terraverdeagro.com.br" target="_blank" title="Terraverde" rel="home">'
		cBodyMail +='																Terraverde  '
		cBodyMail +='															</a>'
		cBodyMail +='														</div>'
		cBodyMail +='													</div>'
		cBodyMail +='											</td>'
		cBodyMail +='											<td align="right">'
		cBodyMail +='												<a href="http://www.terraverdeagro.com.br" target="_blank" title="John Deere">'
		cBodyMail +='													<img alt="John Deere" border="0" style="float: right; user-select: none;" src="http://myjohndeere.deere.com/common/deere-resources/img/email/jd-logo.png">'
		cBodyMail +='												</a>'
		cBodyMail +='											</td>'
		cBodyMail +='										</tr>'
		cBodyMail +='									</tbody>'
		cBodyMail +='								</table>'
		cBodyMail +='							</td>'
		cBodyMail +='						</tr>'
		cBodyMail +='						<tr>'
		cBodyMail +='							<td height="15" style="height:15px; line-height:15px; background-color:#266B1A"></td>'
		cBodyMail +='						</tr>'
		cBodyMail +='						<tr>'
		cBodyMail +='							<td height="6" style="height:6px; line-height:6px; background-color:#FDDA01"></td>'
		cBodyMail +='						</tr>'
		cBodyMail +='						<tr>'
		cBodyMail +='							<td>'
		cBodyMail +='								<table width="100%" border="0" cellspacing="0" cellpadding="20">'
		cBodyMail +='									<tbody>	'
		cBodyMail +='										<tr>'
		cBodyMail +='											<td style="word-wrap:break-word; word-break:break-all">'
		cBodyMail +='												<h1 style="color:#333333; font-family:Calibri,Verdana,sans-serif; font-size:20px; line-height:20px; font-weight:bold; margin:0 0 20px 0; padding:0px; display:block">'
		cBodyMail +='													Sua fatura chegou! :)'
		cBodyMail +='												</h1>'
		cBodyMail +='												<div style="font:14px/18px Calibri,Verdana,sans-serif; color:#333; overflow:hidden; margin:0; padding:0">'
		cBodyMail +='													<p style="margin:0 0 20px 0; padding:0px; display:block; font:14px/18px Calibri,Verdana,sans-serif; color:#333">'
		cBodyMail +='														Este e-mail é um resumo da sua fatura.</br>'
		cBodyMail +='														Para visualizar a versão completa, baixe o anexo ou entre em contato conosco. '
		cBodyMail +='													</p>'
		cBodyMail +='													<p style="margin:0; padding:0; display:block; font:14px/18px Calibri,Verdana,sans-serif; color:#333"></p>'
		cBodyMail +='													<table border="0" cellpadding="0" cellspacing="0" style="overflow:hidden; height:28px; border-collapse:collapse">'
		cBodyMail +='														<tbody>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<td width="45" bgcolor="#ffffff"></td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#eaeaea"></td>'
		cBodyMail +='																				<td width="550" align="left" bgcolor="#eaeaea">'
		cBodyMail +='																					<font face="Arial, sans-serif" color="#333" style="font-size:7px">&nbsp;'
		cBodyMail +='																					<br>'
		cBodyMail +='																					</font>'
		cBodyMail +='																					<font face="Arial, sans-serif" color="#333" style="font-size:15px">'
		cBodyMail +='																						Cliente:'
		cBodyMail +='																					</font>'
		cBodyMail +='																					<font face="Arial, sans-serif" color="#000000" style="font-size:15px">'
		cBodyMail +='																						'+SA1->A1_NOME+' <br>'
		cBodyMail +='																					</font>'
		cBodyMail +='																					<font face="Arial, sans-serif" color="#333" style="font-size:7px">&nbsp; </font>'
		cBodyMail +='																				</td>'
		cBodyMail +='																				<td width="45" bgcolor="#ffffff"></td>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<th height="15"></th>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#eaeaea"></td>'
		cBodyMail +='																				<td width="270" align="left" bgcolor="#eaeaea"><font face="Arial, sans-serif" color="#333" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#333" style="font-size:15px">'+Iif(Len(AllTrim(SA1->A1_CGC))>11,"CNPJ:","CPF:")
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#000000" style="font-size:15px">'+ TransForm( AllTrim(SA1->A1_CGC) , Iif(Len(AllTrim(SA1->A1_CGC))>11,cMaskCnpj,cMaskCpf))+''
		cBodyMail +='																					<br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#000000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font>'
		cBodyMail +='																				</td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#eaeaea"></td>'
		cBodyMail +='																				<td width="20" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#eaeaea"></td>'
		cBodyMail +='																				<td width="230" align="left" bgcolor="#eaeaea"><font face="Arial, sans-serif" color="#333" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#333" style="font-size:15px">Nº da Fatura:'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#000000" style="font-size:15px">'+Alltrim(SE1->E1_NUM) + Iif(!Empty(SE1->E1_PARCELA),'   Parc: ' + Alltrim(SE1->E1_PARCELA),'')
		cBodyMail +='																					<br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#000000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font>'
		cBodyMail +='																				</td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#eaeaea"></td>'
		cBodyMail +='																				<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<th height="15"></th>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='															<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='															<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='															<tbody>'
		cBodyMail +='															<tr>'
		cBodyMail +='															<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='															<td width="10" align="left" bgcolor="#FFCC00"></td>'
		cBodyMail +='															<td width="270" align="left" bgcolor="#FFCC00"><font face="Arial, sans-serif" color="#000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='															</font><font face="Arial, sans-serif" color="#000" style="font-size:15px">Vencimento:'
		cBodyMail +='															<b>'+DtoC(SE1->E1_VENCREA)+'</b> <br>'
		cBodyMail +='															</font><font face="Arial, sans-serif" color="#000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='															</font></td>'
		cBodyMail +='															<td width="10" align="left" bgcolor="#FFCC00"></td>'
		cBodyMail +='															<td width="20" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='															<td width="10" align="left" bgcolor="#FFCC00"></td>'
		cBodyMail +='															<td width="230" align="left" bgcolor="#FFCC00"><font face="Arial, sans-serif" color="#000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='															</font><font face="Arial, sans-serif" color="#000" style="font-size:15px">Valor:'
		cBodyMail +='															<b>R$ '+Alltrim(Transform(SE1->E1_SALDO,"@E 999,999.99"))+'</b> <br>'
		cBodyMail +='															</font><font face="Arial, sans-serif" color="#000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='															</font></td>'
		cBodyMail +='															<td width="10" align="left" bgcolor="#FFCC00"></td>'
		cBodyMail +='															<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															</tbody>'
		cBodyMail +='															</table>'
		cBodyMail +='															</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<th height="15"></th>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																				<td width="540" align="left" bgcolor="#ffffff"><font face="Arial, sans-serif" color="#ffffff" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#333" style="font-size:12px">Utilize o número do código de barras abaixo para realizar o pagamento.<br>'
		cBodyMail +='																					</font>'
		cBodyMail +='																				</td>'
		cBodyMail +='																				<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='															<tr>'
		cBodyMail +='																<td width="650" align="center" bgcolor="#ffffff">'
		cBodyMail +='																	<table width="650" border="0" cellspacing="0" cellpadding="0" align="center">'
		cBodyMail +='																		<tbody>'
		cBodyMail +='																			<tr>'
		cBodyMail +='																				<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#FFCC00"></td>'
		cBodyMail +='																				<td width="540" align="left" bgcolor="#FFCC00"><font face="Arial, sans-serif" color="#000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#000" style="font-size:15px">Código de barras:'
		cAux := iif(len(aCB_RN_NN)>0, aCB_RN_NN[2],"")
		cBodyMail +='																					<b>'+cAux+'</b> <br>'
		cBodyMail +='																					</font><font face="Arial, sans-serif" color="#000" style="font-size:7px">&nbsp;<br>'
		cBodyMail +='																					</font>'
		cBodyMail +='																				</td>'
		cBodyMail +='																				<td width="10" align="left" bgcolor="#FFCC00"></td>'
		cBodyMail +='																				<td width="45" align="left" bgcolor="#ffffff"></td>'
		cBodyMail +='																			</tr>'
		cBodyMail +='																		</tbody>'
		cBodyMail +='																	</table>'
		cBodyMail +='																</td>'
		cBodyMail +='															</tr>'
		cBodyMail +='														</tbody>'
		cBodyMail +='													</table>'
		cBodyMail +='													<p>&nbsp;</p>'
		cBodyMail +='													<p style="margin:20px 0 20px 0; padding:0px; display:block; font:14px/18px Calibri,Verdana,sans-serif; color:#333">'
		cBodyMail +='													&nbsp;</p>'
		cBodyMail +='													<p style="margin:0 0 20px 0; padding:0px; display:block; font:14px/18px Calibri,Verdana,sans-serif; color:#333">'
		cBodyMail +='														<br>Entre em contato com a Terraverde por meio de nossos canais de atendimento:  '
		cBodyMail +='														<a href="http://www.terraverdeagro.com.br/staff" target="_blank" style="color:#367c2b; text-decoration:underline">'
		cBodyMail +='														Clique aqui!'
		cBodyMail +='														</a>'
		cBodyMail +='													</p>'
		cBodyMail +='												</div>'
		cBodyMail +='											</td>'
		cBodyMail +='										</tr>'
		cBodyMail +='									</tbody>'
		cBodyMail +='								</table>'
		cBodyMail +='							</td>'
		cBodyMail +='						</tr>'
		cBodyMail +='					</tbody>'
		cBodyMail +='				</table>'
		cBodyMail +='				<table width="700" border="0" cellspacing="0" cellpadding="20" align="center">'
		cBodyMail +='					<tbody>'
		cBodyMail +='						<tr>'
		cBodyMail +='							<td>'
		cBodyMail +='								<strong style="font-family:Calibri,Verdana,sans-serif; font-size:13px; color:#333; line-height:18px">'
		cBodyMail +='									Copyright © 2018 Terraverde. Todos os direitos reservados'
		cBodyMail +='								</strong>'
		cBodyMail +='							</td>'
		cBodyMail +='						</tr>'
		cBodyMail +='					</tbody>'
		cBodyMail +='				</table>'
		cBodyMail +='			</div>'
		cBodyMail +='		</div>'
		cBodyMail +='	</div>'
		cBodyMail +='</body>'
		cBodyMail +='</html>'
	End Sequence

Return cBodyMail

//--------------------------------------------------------------------------------------+
/*/{Protheus.doc} F_MAIL																
Envia o html por email
@author    	Charlles Reis									
@version   	1.0																	
@since      Abril/2020
/*/																												
//--------------------------------------------------------------------------------------+
Static Function F_MAIL( cRemet, cPara, cConhCopia, cAssunto, cTexto, aFile, cCco, lMsg )
	Local oMail , oMessage , nErro
	Local lOk 			:= .T.
	Local cSMTPServer   := GetMV("MV_RelseRV",,"" )
	Local cSMTPUser		:= GetMV("MV_RELACNT",,"" )
	Local _cFrom	   	:= GetMV("MV_RELFROM",,"" )
	Local cSMTPPass		:= GetMV("MV_RELPSW" ,,"" )
	Local nPort	   		:= GetMV("MV_GCPPORT",,587)
	Local _lTls	   		:= GetMV("MV_RELTLS" ,,.T.)
	Local _lSSl	   		:= GetMV("MV_RELSSL" ,,.T.)
	Local _aFileInf     := {}
	Local _nTamFile		:= 0
	Local _nX, nI

	oMail := TMailManager():New()

	if At(":",cSMTPServer) > 0
		// Retira a porta pois deve pegar pelo parametro MV_GCPPORT
		cSMTPServer := SubStr(cSMTPServer , 01 , At(":",cSMTPServer) - 1 )
	endif
	cRemet := _cFrom
	oMail:SetUseSSL(_lSSl)
	oMail:SetUseTLS(_lTls)
	oMail:Init( '', cSMTPServer , cSMTPUser, cSMTPPass, 0, nPort  )
	oMail:SetSmtpTimeOut( 30 )

	nErro := oMail:SmtpConnect()

	if nErro == 0 // Conseguiu conectar.

		nErro := oMail:SmtpAuth(cSMTPUser ,cSMTPPass) // Autenticacao do usuario

		if nErro == 0 // Autenticacao correta
			oMessage := TMailMessage():New()
			oMessage:Clear()
			oMessage:cFrom	:= cRemet
			oMessage:cTo	:= cPara

			if !Empty(cConhCopia)
				oMessage:cCc	:= cConhCopia
			endif

			if !Empty(cCco)
				oMessage:cBCc	:= cCco
			endif

			oMessage:cSubject	:= cAssunto

			if !Empty(aFile)
				if ValType(aFile) == "C"
					_aFileInf := Directory(aFile)
					if Len(_aFileInf) > 0
						if   _aFileInf[1][2] <= _nTamFile
							oMessage:AttachFile(aFile)
						else
							cTexto := "O arquivo gerado excedeu o tamanho permitido e não pode ser anexado. Caminho do Arquivo " + GetSrvProfString ("ROOTPATH","") + aFile
						endif
					endif
				else

					For _nX := 1 To Len(aFile)
						oMessage:AttachFile(aFile[_nX])
					Next _nX

					nAttach := oMessage:GetAttachCount()

					CONOUT( "Number of attachments: " + CVALTOCHAR( nAttach ) )

					if	nAttach > 0
						For nI := 1 to nAttach
							aAttInfo := oMessage:GetAttachInfo( nI )
							varinfo( "attachment " + cValToChar( nI ), aAttInfo )
						Next nI
					endif
				endif
			endif

			oMessage:cBody		:= cTexto
			nErro := oMessage:Send( oMail )

			if nErro == 0
				lOk := .T.
			else
				cMAilError := oMail:GetErrorString(nErro)
				CONOUT(cMAilError+CRLF+cValToChar(nErro)+ CRLF + "3","Envia")
				lOk := .F.
				oMail:SMTPDisconnect()
			endif

		else // Nao autenticou
			cMAilError := oMail:GetErrorString(nErro)
			Alert(cMAilError+CRLF+cValToChar(nErro)+CRLF+"2","Autenticacao")
			lOk := .F.
			oMail:SMTPDisconnect()
		endif

	else // Nao conseguiu conectar.
		cMAilError := oMail:GetErrorString(nErro)
		Alert(cMAilError+CRLF+cValToChar(nErro)+CRLF+"1","Connexao")
		lOk := .F.
		oMail:SMTPDisconnect()

	endif

	For _nX := 1 To Len(aFile)
		FErase(aFile[_nX])
	Next _nX
Return lOk

/*/{Protheus.doc} GeraId
description
@type function
@version  
@author leonardo.robes
@since 01/02/2023
@return variant, return_description
/*/
Static Function GeraId()
    Local cNextNum  := NIL // passar nil caso não atender as regras para obtenção de nova sequencia
    Local aArea 	:= GetArea()
    Local cNewAlias := GetNextAlias()
    Local cAlias 	:= "SE1" 	// Nome da Tabela
    Local cCpoSx8   := "E1_IDCNAB" 	// Nome do campo que será utilizado para verificar o próximo sequencial;    
    //Local nOrdSX8   := paramixb[4] 	// nOrdSX8 - Índice de pesquisa a ser usada na tabela.
    Local nTamCpo   := 0
    Local lNextNum  := .T.	
	Local lContinue	:= .T.

    If AliasInDic(cAlias) .and. (cAlias)->(FieldPos(cCpoSx8)) > 0    
		cQuery := "SELECT MAX(" + cCpoSx8 + ") CONTEUDO" + CRLF
		cQuery += " FROM " + RetSQLName(cAlias) + CRLF
		//cQuery += "WHERE " + PrefixoCpo(cAlias) + "_FILIAL  = '" + xFilial(cAlias) + "'" + CRLF
		cQuery += "  WHERE D_E_L_E_T_  = ' ' " + CRLF

		cQuery := ChangeQuery(cQuery)
		DbUseArea( .T., "TopConn", TCGenQry(,,cQuery), cNewAlias, .F., .F. )

		nTamCpo     := TamSX3(cCpoSx8)[1]
		cNextNum    := Soma1(PadL((cNewAlias)->CONTEUDO,nTamCpo,"0"))

		(cNewAlias)->(dbCloseArea())
	
		RestArea(aArea)
	Endif	
Return cNextNum
