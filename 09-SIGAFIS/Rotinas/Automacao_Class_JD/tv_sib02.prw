#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#include "ap5mail.ch"

//-------------------------------------------//
// Valida classificacao                      //
// Chamada do ponto de entrada MT100TOK      //
//-------------------------------------------//
// 06/10

User Function TV_SIB02(cChave)
	Local y
	Local nY
	Local lRet 			:= .T.
	Local aSitTrib  := {}
	Local cError    := ""
	Local cWarning  := ""

	Local nBIcms := 0
	Local nVIcms := 0
	Local nBST   := 0
	Local nVST   := 0
	Local nBIpi  := 0
	Local nVIpi  := 0
	Local nBPis  := 0
	Local nVPis  := 0
	Local nBCof  := 0
	Local nVCof  := 0

	Local cToken   := 'rsr62QPwUDLIIP3Ko6UL9g24A'
	Local CnpjGrup := '09282594000145'

	Local cPathLog := "\classJD\"
	Local cFileLog := ''
	Local nHandle := 0

	Private oNotaXml
	Private aErros := {}

	Private nX

	Private nPosBIPI		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_BASEIPI" } )
	Private nPosVIPI		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_VALIPI"  } )

	Private nPosBICM 		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_BASEICM"	} )
	Private nPosVICM 		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_VALICM" 	} )

	Private nPosBST 		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_BRICMS" 	} )
	Private nPosVST 		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_ICMSRET"	} )

	Private nPosBPIS		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_BASIMP6"  } )
	Private nPosVPIS		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_VALIMP6" 	} )

	Private nPosBCOF		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_BASIMP5"  } )
	Private nPosVCOF		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_VALIMP5" 	} )

	Private nPosCOD 		:= aScan(aHeader , { |x| AllTrim(x[2]) == "D1_COD"	    } )


	//--------------------------------//
	// Valida usuario e filial        //
	//--------------------------------//
	/*
	If !(__cUserID $ GetMv("TV_UVALJD"))
		Return(.T.)
	Endif

	If !(cFilAnt $ GetMv("TV_FVALJD"))
		Return(.T.)
	Endif
	*/

	aadd(aSitTrib,"00")
	aadd(aSitTrib,"10")
	aadd(aSitTrib,"20")
	aadd(aSitTrib,"30")
	aadd(aSitTrib,"40")
	aadd(aSitTrib,"41")
	aadd(aSitTrib,"50")
	aadd(aSitTrib,"51")
	aadd(aSitTrib,"60")
	aadd(aSitTrib,"70")
	aadd(aSitTrib,"90")

	// antiga cString := u_SI_GetXML(Alltrim(cChave), cCpfCnpjAgrupador,cToken)
	cString := u_SI_GetXML(Alltrim(cChave),CnpjGrup,cToken)
	oNotaxml := xmlparser(cString, "_", @cError, @cWarning)
	oNfe := WSAdvValue( oNotaxml,"_NFEPROC","string",NIL,NIL,NIL,NIL,NIL)
	oNF       := oNFe:_NFe
	oDet      := oNF:_InfNfe:_Det
	oDet := IIf(ValType(oDet)=="O",{oDet},oDet)
	nDetImp := Len(oDet)  // numero de itens
	For nX 		:= 1 To nDetImp
		cItem   := Strzero(Val(oDet[nX]:_nItem:TEXT),4)
		cCod    := oDet[nX]:_Prod:_cProd:TEXT
		cCfopX  := oDet[nX]:_Prod:_CFOP:TEXT
		cCstIcm := ''
		cCstIpi := ''
		cCstPis := ''
		cCstCof := ''
		nBIcms  := 0
		nVIcms  := 0
		nBST    := 0
		nVST    := 0
		nBIPI   := 0
		nVIpi   := 0
		nBPIS   := 0
		nVPIS   := 0
		nBCOF   := 0
		nVCOF   := 0

		oImposto 	:= oDet[nX]
		If ValAtrib("oImposto:_Imposto")<>"U"

			// ICMS
			If ValAtrib("oImposto:_Imposto:_ICMS")<>"U"
				nLenSit := Len(aSitTrib)
				For nY := 1 To nLenSit
					If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY])<>"U"
						cCstIcm := aSitTrib[nY]
						If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_VBC:TEXT")<>"U"
							nBIcms := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_VBC:TEXT"))
						Endif
						If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_VICMS:TEXT")<>"U"
							nVIcms := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_VICMS:TEXT"))
						Endif

						If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vBCST:TEXT")<>"U"
							nBST := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vBCST:TEXT"))
						Endif
						If ValAtrib("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMSST:TEXT")<>"U"
							nVST := Val(&("oImposto:_Imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMSST:TEXT"))
						Endif
					Endif
				Next
			Endif

			// IPI
			If ValAtrib("oImposto:_Imposto:_IPI")<>"U"
				If ValAtrib("oImposto:_Imposto:_IPI:_IPITrib:_vBC:TEXT")<>"U"
					nBIPI   := Val(oImposto:_Imposto:_IPI:_IPITrib:_vBC:TEXT)
				EndIf
				If ValAtrib("oImposto:_Imposto:_IPI:_IPITrib:_vIPI:TEXT")<>"U"
					nVIpi := Val(oImposto:_Imposto:_IPI:_IPITrib:_vIPI:TEXT)
				EndIf
				If ValAtrib("oImposto:_Imposto:_IPI:_IPITrib:_CST:TEXT")<>"U"
					cCstIpi := oImposto:_Imposto:_IPI:_IPITrib:_CST:TEXT
				EndIf
				If ValAtrib("oImposto:_Imposto:_IPI:_IPINT:_CST:TEXT")<>"U"
					cCstIpi := oImposto:_Imposto:_IPI:_IPINT:_CST:TEXT
				EndIf

			EndIf

			//PIS
			If ValAtrib("oImposto:_Imposto:_PIS")<>"U"
				If ValAtrib("oImposto:_Imposto:_PIS:_PISAliq:_vBC:TEXT")<>"U"
					nBPis := Val(oImposto:_Imposto:_PIS:_PISAliq:_vBC:TEXT)
				EndIf
				If ValAtrib("oImposto:_Imposto:_PIS:_PISAliq:_vPIS:TEXT")<>"U"
					nVPis := Val(oImposto:_Imposto:_PIS:_PISAliq:_vPIS:TEXT)
				EndIf
				If ValAtrib("oImposto:_Imposto:_PIS:_PISAliq:_CST:TEXT")<>"U"
					cCstPis := oImposto:_Imposto:_PIS:_PISAliq:_CST:TEXT
				EndIf
			EndIf

			//COFINS
			If ValAtrib("oImposto:_Imposto:_COFINS")<>"U"
				If ValAtrib("oImposto:_Imposto:_COFINS:_COFINSAliq:_vBC:TEXT")<>"U"
					nBCof := Val(oImposto:_Imposto:_COFINS:_COFINSAliq:_vBC:TEXT)
				EndIf
				If ValAtrib("oImposto:_Imposto:_COFINS:_COFINSAliq:_vCOFINS:TEXT")<>"U"
					nVCof := Val(oImposto:_Imposto:_COFINS:_COFINSAliq:_vCOFINS:TEXT)
				EndIf
				If ValAtrib("oImposto:_Imposto:_COFINS:_COFINSAliq:_CST:TEXT")<>"U"
					cCstCof := oImposto:_Imposto:_COFINS:_COFINSAliq:_CST:TEXT
				EndIf
			EndIf


		Endif

		cNada :=0

		// ICMS
		RegraZ12(SF1->F1_FORNECE,SF1->F1_LOJA,'ICMS',cCfopX,cCstIcm,nBIcms,nVIcms,aCols[nX,nPosBICM],aCols[nX,nPosVICM],cItem,cCod)

		// ICRET
		RegraZ12(SF1->F1_FORNECE,SF1->F1_LOJA,'ICRET',cCfopX,cCstIcm,nBST,nVST,aCols[nX,nPosBST],aCols[nX,nPosVST],cItem,cCod)

		// IPI
		RegraZ12(SF1->F1_FORNECE,SF1->F1_LOJA,'IPI',cCfopX,cCstIpi,nBIPI,nVIpi,aCols[nX,nPosBIPI],aCols[nX,nPosVIPI],cItem,cCod)

		// PIS
		RegraZ12(SF1->F1_FORNECE,SF1->F1_LOJA,'PIS',cCfopX,cCstPis,nBPIS,nVPIS,aCols[nX,nPosBPIS],aCols[nX,nPosVPIS],cItem,cCod)

		// COFINS
		RegraZ12(SF1->F1_FORNECE,SF1->F1_LOJA,'COFINS',cCfopX,cCstCof,nBCOF,nVCOF,aCols[nX,nPosBCOF],aCols[nX,nPosVCOF],cItem,cCod)

	Next

	If Len(aErros) > 0
		cTexto := ''
		cTexto := '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"> '
		cTexto += '<html> '
		cTexto += '<head> '
		cTexto += '  <meta content="text/html; charset=ISO-8859-1" http-equiv="content-type"> '
		cTexto += '  <title></title> '
		cTexto += '</head> '
		cTexto += '<body> '
		cTexto += 'Revisar os dados da nota fiscal<br> '
		cTexto += 'Data   : ' + Dtoc(Date()) + ' as ' + Time() + '<br> '
		cTexto += '<br> '

		cTexto += '<table style="text-align: left; width: 100%;" border="1" cellpadding="2" cellspacing="2"> '
		cTexto += '  <tbody> '
		cTexto += '    <tr> '

		cTexto += '    <tr> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Filial</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Documento</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Emissao</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Fornecedor</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Item</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Produto</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Imposto</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Referencia</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Xml</td> '
		cTexto += '      <td '
		cTexto += ' style="width: 100px; background-color: rgb(0, 102, 0); color: rgb(255, 255, 255);">Protheus</td> '
		cTexto += '    </tr> '

		For y = 1 to Len(aErros)
			cTexto += '<tr> '
			cTexto += '<td>'+aErros[y, 1]+'</td> '
			cTexto += '<td>'+aErros[y, 2]+'</td> '
			cTexto += '<td>'+aErros[y, 3]+'</td> '
			cTexto += '<td>'+aErros[y, 4]+'</td> '
			cTexto += '<td>'+aErros[y, 5]+'</td> '
			cTexto += '<td>'+aErros[y, 6]+'</td> '
			cTexto += '<td>'+aErros[y, 7]+'</td> '
			cTexto += '<td>'+aErros[y, 8]+'</td> '
			cTexto += '<td>'+aErros[y, 9]+'</td> '
			cTexto += '<td>'+aErros[y,10]+'</td> '
			cTexto += '</tr> '
		Next
		//grava html em arquivo validação remover após teste
		cFileLog := cPathLog + "Log_Email_" + SF1->F1_FILIAL + SF1->F1_DOC + SF1->F1_SERIE + DtoS(Date()) + "_" + StrTran(Time(),":","") + ".html"
		If !ExistDir(cPathLog)
			MakeDir(cPathLog)
		EndIf
		nHandle := FCreate(cFileLog)
		If nHandle >= 0
			FWrite(nHandle, cTexto)
			FClose(nHandle)
		EndIf

		cContas := GETMV("TV_EMAILCL")
		GPEMail("Revisar e classificar a nota fiscal " + SF1->F1_DOC,cTexto,cContas)
		lRet := .F.
	else
		Dbselectarea('SF1')
		Dbsetorder(1)
		Dbseek(SF1->F1_FILIAL + SF1->F1_DOC + SF1->F1_SERIE +SF1->F1_FORNECE + SF1->F1_LOJA ,.F.)
		If found()
			RecLock('SF1',.F.)
			SF1->F1_XSTVLD := 'S'
			SF1->F1_XUSCLAS := 'SMARTDOCS'
			MsUnLock()
		EndIf
	Endif

	FreeObj(oNotaxml)
	FreeObj(oNfe)
	FreeObj(oNF)
	FreeObj(oDet)

Return(lRet)


//--------------------------------//
// Valida se tag existe           //
//--------------------------------//
Static Function ValAtrib(atributo)
Return (type(atributo) )


//-------------------------------//
// Regras da tabela Z12          //
//-------------------------------//
Static Function RegraZ12(F1FORNECE,F1LOJA,xImposto,xCfopX,xCst,xBase,xVal,pBase,pVal,xItem,xProd)
	Local nZ12   := 0
	Local cQuery := ''

	cQuery := "SELECT * FROM " + RetSQLName('Z12')
	cQuery += " WHERE Z12_CODFOR = '" + F1FORNECE  + "'"
	cQuery += " AND   Z12_LOJA   = '" + F1LOJA     + "'"
	cQuery += " AND   Z12_IMPOST = '" + xImposto   + "'"
	cQuery += " AND   Z12_CFOPXM = '" + xCfopX     + "'"
	cQuery += " AND   Z12_CSTIMP = '" + xCst       + "'"
	cQuery += " AND   D_E_L_E_T_ = ' '"
	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPR",.T.,.T.)
	DbSelectArea('TMPR')
	DbGoTop()

	Do while .not. eof()
		nZ12 += 1

		// bases devem ser iguais
		If Z12_BSXML == '1' .AND. Z12_BS_ERP == '1'
			If Str(xBase,15,2) <> Str(pBase,15,2)
				if (int(xBase,15,2)-int(pBase,15,2)) > 2 .or. (int(pBase,15,2)-int(xBase,15,2)) < -2
					aAdd(aErros,{SF1->F1_FILIAL,SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'BASE', Str(xBase,15,2),Str(pBase,15,2) } )
				Else
					If xImposto == 'ICMS'
						aCols[nX,nPosBICM] := xBase
						MaFisAlt("IT_BASEICM", aCols[nX,nPosBICM], nX)
					Endif
					If xImposto == 'ICRET'
						aCols[nX,nPosBST] := xBase
						MaFisAlt("IT_BASESOL", aCols[nX,nPosBST], nX)
					Endif
					If xImposto == 'IPI'
						aCols[nX,nPosBIPI] := xBase
						MaFisAlt("IT_BASEIPI", aCols[nX,nPosBIPI], nX)
					Endif
					If xImposto == 'PIS'
						aCols[nX,nPosBPIS] := xBase
						MaFisAlt("IT_BASEPS2", aCols[nX,nPosBPIS], nX)
					Endif
					If xImposto == 'COFINS'
						aCols[nX,nPosBCOF] := xBase
						MaFisAlt("IT_BASECF2", aCols[nX,nPosBCOF], nX)
					Endif
				Endif
			Endif
			//aAdd(aErros,{SF1->F1_FILIAL,'OK BASE IGUAL ' + SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'BASE', Str(xBase,15,2),Str(pBase,15,2) } )
		Else
			If xImposto == 'ICMS'
				aCols[nX,nPosBICM] := xBase
				MaFisAlt("IT_BASEICM", aCols[nX,nPosBICM], nX)
			Endif
			If xImposto == 'ICRET'
				aCols[nX,nPosBST] := xBase
				MaFisAlt("IT_BASESOL", aCols[nX,nPosBST], nX)
			Endif
			If xImposto == 'IPI'
				aCols[nX,nPosBIPI] := xBase
				MaFisAlt("IT_BASEIPI", aCols[nX,nPosBIPI], nX)
			Endif
			If xImposto == 'PIS'
				aCols[nX,nPosBPIS] := xBase
				MaFisAlt("IT_BASEPS2", aCols[nX,nPosBPIS], nX)
			Endif
			If xImposto == 'COFINS'
				aCols[nX,nPosBCOF] := xBase
				MaFisAlt("IT_BASECF2", aCols[nX,nPosBCOF], nX)
			Endif
		Endif

		DbSelectArea('TMPR')

		// impostos devem ser iguais
		If Z12_VIMXML == '1' .AND. Z12_VIMERP == '1'
			If Str(xVal,15,2) <> Str(pVal,15,2)
				if (int(xVal,15,2)-int(pVal,15,2)) > 2 .or. (int(pVal,15,2)-int(xVal,15,2)) < -2
					aAdd(aErros,{SF1->F1_FILIAL,SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'VALOR', Str(xVal,15,2),Str(pVal,15,2) } )
				Else
					If xImposto == 'ICMS'
						aCols[nX,nPosVICM] := xVal
						MaFisAlt("IT_VALICM", aCols[nX,nPosVICM], nX)
					Endif
					If xImposto == 'ICRET'
						aCols[nX,nPosVST] := xVal
						MaFisAlt("IT_VALSOL", aCols[nX,nPosVST], nX)
					Endif
					If xImposto == 'IPI'
						aCols[nX,nPosVIPI] := xVal
						MaFisAlt("IT_VALIPI", aCols[nX,nPosVIPI], nX)
					Endif
					If xImposto == 'PIS'
						aCols[nX,nPosVPIS] := xVal
						MaFisAlt("IT_VALPS2", aCols[nX,nPosVPIS], nX)
					Endif
					If xImposto == 'COFINS'
						aCols[nX,nPosVCOF] := xVal
						MaFisAlt("IT_VALCF2", aCols[nX,nPosVCOF], nX)
					Endif
				Endif
				//aAdd(aErros,{SF1->F1_FILIAL,'OK VALIMP IGUAL ' + SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'VALOR', Str(xVal,15,2),Str(pVal,15,2) } )
			Else
				If xImposto == 'ICMS'
					aCols[nX,nPosVICM] := xVal
					MaFisAlt("IT_VALICM", aCols[nX,nPosVICM], nX)
				Endif
				If xImposto == 'ICRET'
					aCols[nX,nPosVST] := xVal
					MaFisAlt("IT_VALSOL", aCols[nX,nPosVST], nX)
				Endif
				If xImposto == 'IPI'
					aCols[nX,nPosVIPI] := xVal
					MaFisAlt("IT_VALIPI", aCols[nX,nPosVIPI], nX)
				Endif
				If xImposto == 'PIS'
					aCols[nX,nPosVPIS] := xVal
					MaFisAlt("IT_VALPS2", aCols[nX,nPosVPIS], nX)
				Endif
				If xImposto == 'COFINS'
					aCols[nX,nPosVCOF] := xVal
					MaFisAlt("IT_VALCF2", aCols[nX,nPosVCOF], nX)
				Endif
			Endif
		Endif
		DbSelectArea('TMPR')

		//                     deve ser zero
		If Z12_BSXML == '1' .AND. Z12_BS_ERP == '0'
			If pBase > 0
				aAdd(aErros,{SF1->F1_FILIAL,SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'BASE', Str(xBase,15,2),Str(pBase,15,2) } )
			Else
				//aAdd(aErros,{SF1->F1_FILIAL,'OK BASE XML>0 PROTHEUS=0 ' + SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'BASE', Str(xBase,15,2),Str(pBase,15,2) } )
			Endif
		Endif
		DbSelectArea('TMPR')

		//                      deve ser zero
		If Z12_VIMXML == '1' .AND. Z12_VIMERP == '0'
			If pVal > 0
				aAdd(aErros,{SF1->F1_FILIAL,SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'VALOR', Str(xVal,15,2),Str(pVal,15,2) } )
			Else
				//aAdd(aErros,{SF1->F1_FILIAL,'OK VAIMP XML>=0 PROTHEUS=0 ' + SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'VALOR', Str(xVal,15,2),Str(pVal,15,2) } )
			Endif
		Endif
		DbSelectArea('TMPR')

		Dbskip()
		Loop
	Enddo

	DbSelectArea('TMPR')
	Dbclosearea()
	If nz12 = 0
		aAdd(aErros,{SF1->F1_FILIAL,SF1->F1_DOC+' - ' + SF1->F1_SERIE, DTOC(SF1->F1_EMISSAO), ALLTRIM(SA2->A2_NOME), xItem, xProd, xImposto + xCst, 'REGRA Z12 NAO ENCONTRADA','CFOP '+xCfopX,'' } )
	Endif
Return


