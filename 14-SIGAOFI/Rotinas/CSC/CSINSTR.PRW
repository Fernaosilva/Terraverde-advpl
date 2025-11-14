#include "protheus.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CSINSTR
Impressão da instrução de trabalho
@type function
@version 1.0
@author Charlles Reis
@since  Janeiro/2022
@history 08/08/2025, Ademar Fernandes Jr., Melhoria de Impressao dos campos de Observação.
@return variant, nil
/*/
User Function CSINSTR()
	Local aArea	:= GetArea()
	Local lGera	:= .t.

	if FWIsInCallStack("U_CS14Z06")
		If	lGera
			FS_INSTRU()
		EndIf
	else
		If	Empty(Z01->Z01_CODERR)
			MsgStop("Não há código dtc informado.", "Atenção!")
			lGera := .f.
		Else
			dbSelectArea("Z06")
			Z06->(dbSetOrder(1))
			If	!Z06->(dbSeek(xFilial("Z06") + Z01->Z01_CODERR))
				MsgStop("Código de erro não encontrado no cadastro.", "Atenção!")
				lGera := .f.
			EndIf
		EndIf

		If	lGera
			FS_INSTRU()
		EndIf
	endif
	RestArea(aArea)

Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} FS_INSTRU
Realiza a impressão do relatório
@author 	Charlles Reis
@version   	1.0
@since 		04/07/2018
/*/
//-------------------------------------------------------------------------------------
Static Function FS_INSTRU()
	Local nPag			:= 1
	Local nQtdLin		:= 0
	Local nTamLin		:= 105	//-20250809
	Local i

	Private nTotal		:= 0
	Private nLin		:= 100
	Private nCol		:= 100
	Private nColunaI	:= 100
	Private nColIniS	:= 100
	Private nColunaF	:= 2100
	Private nAlturaI	:= 550
	Private nAlturaF	:= 2900	//-2600-20250809
	Private nLinSayI	:= 310
	Private nColSayI	:= 870

	SetPrvt( "oPrint", "oFont", "oFontTab", "oFontTabTit", "oFontNeg", "oFontTit" )
	oPrint	:= FWMsPrinter():New( "INSTRUCAO_DE_TRABALHO_"+Z06->Z06_CODDTC,,.T.,,.T. )
	oPrint:SetPortrait()
	oPrint:SetMargin(100,60,20,40)

	//oPrint	:Setup()
	//Definição de Fontes
	oFont			:= TFont():New( 'Courier',,-12,,.F.)
	oFontTab		:= TFont():New( 'Courier',,-8 ,,.F.)
	oFontTabTit		:= TFont():New( 'Courier',,-14,,.T.)
	oFontNeg		:= TFont():New( 'Courier',,-12,,.T.)
	oFontTit		:= TFont():New( 'Courier',,-16,,.T.,,,,,.F.)

	//Inicia a impressão da página
	oPrint:StartPage()

	//Imprime o cabeçalho
	ImprimCab2()

	//-------------------------------------------------------------------------------------------
	//Descrição do DTC
	//-------------------------------------------------------------------------------------------
	oPrint:Box( nAlturaI-5, nColIniS-25, nAlturaI+55, nColunaF, "-4")
	nAlturaI += 40
	oPrint:Say( nAlturaI, nColIniS, "DESCRIÇÃO DO DTC",oFontNeg,2100)
	nAlturaI += 40

	cDesCom := AllTrim(Z06->Z06_DESCOM)
	nQtdLin := MLCount(cDesCom, nTamLin)

	For i := 1 To nQtdLin
		oPrint:Say( nAlturaI, nColIniS, MemoLine(cDesCom,nTamLin,i,,.F.), oFont, nColunaF)
		nAlturaI += 25
		fnPageEnd(@nPag)
	Next

	nAlturaI += 30

	//-------------------------------------------------------------------------------------------
	//INSTRUÇÃO p/ Solução do DTC
	//-------------------------------------------------------------------------------------------
	oPrint:Box( nAlturaI-5, nColIniS-25, nAlturaI+55, nColunaF, "-4")
	nAlturaI += 40
	oPrint:Say( nAlturaI, nColIniS, "INSTRUÇÃO CSC",oFontNeg,2100)
	nAlturaI += 40

	cDesSol := AllTrim(Z06->Z06_SOLDTC)
	nQtdLin := MLCount(cDesSol, nTamLin)

	For i := 1 To nQtdLin
		oPrint:Say( nAlturaI, nColIniS, MemoLine(cDesSol,nTamLin,i,,.F.), oFont, nColunaF)
		nAlturaI += 25
		fnPageEnd(@nPag)
	Next

	fnPageEnd(@nPag)

	//-------------------------------------------------------------------------------------------
	//Peças e TMOs
	//-------------------------------------------------------------------------------------------
	nAlturaI += 50
	oPrint:Say( nAlturaI, nColIniS+800, "PEÇAS",oFontNeg,2100)
	nAlturaI += 30
	oPrint:Box( nAlturaI-5, nColIniS-25, nAlturaI+55, nColunaF, "-4")
	nAlturaI += 40
	oPrint:Say( nAlturaI, nColIniS    ,"CÓDIGO",oFontNeg,2100)
	oPrint:Say( nAlturaI, nColIniS+200,"DESCRIÇÃO",oFontNeg,2100)
	oPrint:Say( nAlturaI, nColIniS+1000,"QUANTIDADE",oFontNeg,2100)
	nAlturaI += 40

	dbSelectArea("Z08")
	Z08->(dbSetOrder(1))
	If	Z08->(dbSeek(xFilial("Z08") + Z06->Z06_CODIGO))
		While !Z08->(EOF()) .and. Z08->(Z08_FILIAL+Z08_CODIGO) == Z06->(Z06_FILIAL+Z06_CODIGO)

			oPrint:Say( nAlturaI, nColIniS    , Z08->Z08_CODPEC,oFont,2100)
			oPrint:Say( nAlturaI, nColIniS+200, Z08->Z08_DESPEC,oFont,2100)
			oPrint:Say( nAlturaI, nColIniS+1000, cValToChar(Z08->Z08_QTDPEC),oFont,2100)
			nAlturaI += 25
			fnPageEnd(@nPag)

			Z08->(dbSkip())
		EndDo
	EndIf

	nAlturaI += 50
	oPrint:Say( nAlturaI, nColIniS+800, "TMO",oFontNeg,2100)
	nAlturaI += 30
	oPrint:Box( nAlturaI-5, nColIniS-25, nAlturaI+55, nColunaF, "-4")
	nAlturaI += 40
	oPrint:Say( nAlturaI, nColIniS    ,"CÓDIGO",oFontNeg,2100)
	oPrint:Say( nAlturaI, nColIniS+200,"DESCRIÇÃO",oFontNeg,2100)
	oPrint:Say( nAlturaI, nColIniS+1000,"QUANTIDADE",oFontNeg,2100)
	nAlturaI += 40

	dbSelectArea("Z09")
	Z09->(dbSetOrder(1))
	If	Z09->(dbSeek(xFilial("Z09") + Z06->Z06_CODIGO))
		While !Z09->(EOF()) .and. Z09->(Z09_FILIAL+Z09_CODIGO) == Z06->(Z06_FILIAL+Z06_CODIGO)

			oPrint:Say( nAlturaI, nColIniS    , Z09->Z09_CODSER,oFont,2100)
			oPrint:Say( nAlturaI, nColIniS+200, POSICIONE("VO6",4,xFilial("VO6") + Z09->Z09_CODSER, "VO6_DESSER"),oFont,2100)
			oPrint:Say( nAlturaI, nColIniS+1000, Transform(Z09->Z09_TEMPAD,"@R 999:99"),oFont,2100)
			nAlturaI += 25
			fnPageEnd(@nPag)

			Z09->(dbSkip())
		EndDo
	EndIf

	/*----20250809
	nAlturaF := Iif(nAlturaF > nAlturaI, nAlturaF, nAlturaI)
	oPrint:SayAlign( nAlturaF-50, nColIniS-25, "Instrução de Trabalho | Pág.: "+cValToChar(nPag) +;
		" | DT Imp.: "+ DtoC(dDatabase) + " | Hr. Imp.:" + Time(), oFontNeg, nColunaF, 200, , 2 )

	oPrint:EndPage() //-- FINALIZA A PÁGINA
	----*/
	fnPageEnd(@nPag,"S")

	oPrint:Setup()
	if oPrint:nModalResult == PD_OK
		oPrint:Preview()
	else
		oPrint:DeActivate()
	EndIf

	FreeObj(oPrint)
	oPrint := Nil

Return

/*/{Protheus.doc} fnPageEnd
Verifica se a página está cheia e se sim, finaliza a página
@type function
@version P12
@author Ademar Fernandes Jr.
@since 09/08/2025
@param nPag, numeric, Número da página
@return variant, nil
/*/
Static Function fnPageEnd(nPag,cObrig)
	Default cObrig := "N"

	If cObrig == "N" .And. nAlturaI > nAlturaF-50
		nAlturaF := Iif(nAlturaF > nAlturaI, nAlturaF, nAlturaI+50)

		oPrint:SayAlign( nAlturaF-50, nColIniS-25, "Instrução de Trabalho | Pág.: "+cValToChar(nPag) +;
			" | DT Imp.: "+ DtoC(dDatabase) + " | Hr. Imp.:" + Time(), oFontNeg, nColunaF, 200, , 2 )

		oPrint:EndPage()

		//-Reinicia as variáveis de impressão
		nColIniS	:= 100
		nColunaF	:= 2100
		nAlturaI	:= 150	//-550-20250809
		nAlturaF	:= 2900	//-2600-20250809
		nLinSayI	:= 310
		nColSayI	:= 870

		oPrint:StartPage()

		oPrint:Say( nAlturaI, nColIniS+800, "Continuação...",oFontNeg,2100)
		nAlturaI += 50
		nPag += 1
	
	ElseIf cObrig == "S"
		nAlturaF := Iif(nAlturaF > nAlturaI, nAlturaF, nAlturaI+50)

		oPrint:SayAlign( nAlturaF-50, nColIniS-25, "Instrução de Trabalho | Pág.: "+cValToChar(nPag) +;
			" | DT Imp.: "+ DtoC(dDatabase) + " | Hr. Imp.:" + Time(), oFontNeg, nColunaF, 200, , 2 )

		oPrint:EndPage()

	EndIf

Return Nil

/**/
Static Function ImprimCab2()
	Local cLogo     := "LOGOBMP.BMP" //FisxLogo("1")
	Local cTitulo	:= "INSTRUÇÃO DE TRABALHO: " + Z06->Z06_CODDTC
	Local cCabec1	:= "Modelo: " + Alltrim(Z06->Z06_MODVEI)
	Local cCabec2	:= ""
	Local cCabec4	:= "Componente: " + AllTrim(Z06->Z06_COMPON) //+ " Controladora: "
	Local cInfInc	:= ""

	oPrint:Box( nLin    , nCol-25 , nAlturaI, nColunaF, "-4") //Box pega todo o cabeçalho
	oPrint:Box( nLin    , nCol+360, nLin+165, nColunaF, "-4") //Box pega parte de cima
	oPrint:Box( nLin+165, nCol+360, nAlturaI, nColunaF, "-4") //Box pega parte de baixo

	cCabec2	:= "Severidade: "

	If		Z06->Z06_PRIORI == "1"
		cCabec2 += "Alta"
	ElseIf	Z06->Z06_PRIORI == "2"
		cCabec2 += "Média"
	ElseIf	Z06->Z06_PRIORI == "3"
		cCabec2 += "Baixa"
	ElseIf	Z06->Z06_PRIORI == "4"
		cCabec2 += "Informação"
	EndIf

	cInfInc := "Dt. Criação: " + FWLeUserLg("Z06_USERGI",2)

	If	!Empty(Z06->Z06_USERGA)
		cInfInc += " Dt. Alteração: " + FWLeUserLg("Z06_USERGA",2) //FWLeUserLg("Z06_USERGI",1) + " - " + FWLeUserLg("Z06_USERGI",2)
	EndIf

	nLin += 30
	oPrint:SayBitmap(nLin+5, nCol+30, cLogo, 270, 260)
	nLin -= 20
	oPrint:SayAlign( nLin, nCol, cTitulo, oFontTit, nColunaF, 200, , 2 )
	nLin += 50
	oPrint:SayAlign( nLin, nCol, cCabec1, oFontTit, nColunaF, 200, , 2 )
	nLin += 110
	oPrint:SayAlign( nLin, nCol, cCabec2, oFont, nColunaF, 200, , 2 )
	nLin += 50
	oPrint:SayAlign( nLin, nCol, cInfInc, oFont, nColunaF, 200, , 2 )
	nLin += 50
	oPrint:SayAlign( nLin, nCol, cCabec4, oFont, nColunaF, 200, , 2 )
	nAlturaI += 90

Return Nil
