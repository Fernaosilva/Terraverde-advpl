#include "OFINJD22.CH"
#include "PROTHEUS.CH"

/*/{Protheus.doc} MTA103MNU
Vincular Pré Nota com Pedido de Compra JD
Programa Fonte: MATA103.PRW
@type function
@version 1.0
@author TOTVS
@since 03/2017
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com/pages/releaseview.action?pageId=6085783
@history 08/11/2023, Ademar Fernandes Jr., Implementado chamada da rotina de Anexos.
@return variant, True
/*/
USER FUNCTION MTA103MNU()
	local lAnexo2 := SuperGetMv('ZZ_ANEXNF2',.F.,.T.)    //-Habilita rotina de Anexos da NF Entrada (MATA103)
	// local lAnexo3 := SuperGetMv('ZZ_ANEXNF3',.F.,.F.)    //-Habilita rotina de Anexos de Contratos (CNTA300)

	if lAnexo2
        AAdd(aRotina,{OemToAnsi("(*) Consultar Anexos"),"U_ANEXDOC('NFE')",0,4,0,.F.})
    endif
	// if lAnexo3
    //     AAdd(aRotina,{OemToAnsi("(*) Consultar Anexos Contratos"),"U_ANEXDOC('CT')",0,4,0,.F.})
    // endif

	aAdd(aRotina,{"Vinc. Pedido JD", "U_VINCPED()", 0 , 4, 0, nil}) 	

Return .T.


/*-------------------------------------------------------------------------*/
User Function VINCPED()
Local i         := 0   
Local nQtdItem  := 0 
Local cAliasSC7 := "SQLSC7"
Local cAliasSD1 := "SQLSD1"

cNumNF := SF1->F1_DOC
cSerNF := SF1->F1_SERIE  
cForn  := SF1->F1_FORNECE
cLoja  := SF1->F1_LOJA

cNumNF := PADR(cNumNF, TamSX3("F1_DOC"  )[1])
cSerNF := PADR(cSerNF, TamSX3("F1_SERIE")[1])
cForn  := PADR(cForn, TamSX3("A2_COD")[1])
cLoja  := PADR(cLoja, tamsx3("A2_LOJA")[1])

// Conecta no Web Service

dbSelectArea("SF1")
dbSetOrder(1)
if dbSeek( xFilial("SF1") + cNumNF + cSerNF + cForn + cLoja )
	if !Empty(SF1->F1_STATUS)
		MsgStop("NF já foi classificada")	
		Return(.f.)
	Endif
Else                                         
	MsgStop("Nota Fiscal não encontrada")	
	Return(.f.)
Endif

oWS := WSJohnDeereJDPointNF():New()
oWS:SetDebug()
oWS:oWSInput:cinvSequenceNumber := AllTrim(strzero(val(cNumNF),6))
//oWS:oWSInput:cinvoiceSeriesNumber   := alltrim(cSerNF)
oWS:oWSInput:csoldByUnitCode := "2003"
oWS:oWSInput:caccountID := alltrim(GetNewPar("MV_MIL0005",""))
lProcessado:= .f.

MsgRun("Atualizando Pré-Nota","Processando",{|| lProcessado := oWS:getAdvanceShipNotice() })
If !lProcessado
	oWS:ExibeErro()
	Return(.t.)                                                             
EndIf              

If oWS:oWSgetAdvanceShipNoticeReturn:creturnCode == "0"
	MsgInfo("Error: " +oWS:oWSgetAdvanceShipNoticeReturn:cresponseMessage )
Else
	nQtdItem := oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem
	For i := 1 to Len(nQtdItem)
		
		cQuery := "  SELECT SC7.R_E_C_N_O_ SC7RECNO , SC7.C7_NUM , SC7.C7_ITEM , SC7.C7_PRODUTO "
		cQuery += "  FROM "
		cQuery += RetSqlName( "SC7" ) + " SC7 " 
		cQuery += "  WHERE " 
		cQuery += "  SC7.C7_FILIAL  = '"+ xFilial("SC7")+ "' AND "
		cQuery += "  SC7.C7_PEDFAB  = '"+oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:corderID+"' AND "
		cQuery += "  SC7.C7_PRODUTO = '"+oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cpartNumber+"' AND "
		cQuery += "  SC7.C7_ITEPED  = '"+substr(oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cMoveOrderID,11,4)+"' AND "
		cQuery += "  SC7.C7_QUJE < SC7.C7_QUANT AND (SC7.C7_QUANT-SC7.C7_QUJE) >= " + oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cquantity +" AND "
		cQuery += "  SC7.C7_RESIDUO <> 'S' AND SC7.C7_ENCER <>'E' AND "
		cQuery += "  SC7.D_E_L_E_T_ = ' ' "
		
		dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), cAliasSC7, .T., .T. )

		if !( cAliasSC7 )->( Eof() )
         
			nValor   := oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cunitValue
			nPosicao := at(",",nValor)
			nVlr     := substr(nValor,1,nPosicao-1)+"."+substr(nValor,nPosicao+1,2)

			cQuery := "SELECT SD1.R_E_C_N_O_ SD1RECNO , SD1.D1_DOC , SD1.D1_SERIE , SD1.D1_COD , SD1.D1_QUANT , SD1.D1_TOTAL "
			cQuery += "FROM "
			cQuery += RetSqlName("SD1") + " SD1 " 
			cQuery += "WHERE " 
			cQuery += "SD1.D1_FILIAL='"+ xFilial("SD1")+ "' AND SD1.D1_COD = '"+( cAliasSC7 )->C7_PRODUTO+"' AND "
			cQuery += "SD1.D1_DOC = '"+SF1->F1_DOC+"' AND SD1.D1_SERIE = '"+SF1->F1_SERIE+"' AND SD1.D1_QUANT = "+oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cquantity+" AND "
			cQuery += "SD1.D1_ITEMPC = ' ' AND "
			cQuery += "SD1.D_E_L_E_T_=' ' "

			dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), cAliasSD1, .T., .T. )

			if !( cAliasSD1 )->( Eof() )  
			
				dbSelectArea("SD1")
				DbGoTo(( cAliasSD1 )->(SD1RECNO))
				Reclock("SD1",.f.)
				SD1->D1_PEDIDO := ( cAliasSC7 )->C7_NUM
				SD1->D1_ITEMPC := ( cAliasSC7 )->C7_ITEM
				MsUnlock()
			Else
				MsgStop("Produto não encontrado, impossível continuar!")
				(cAliasSD1)->(dbCloseArea())
				(cAliasSC7)->(dbCloseArea())
				Return(.f.)
			Endif
	
			(cAliasSD1)->(dbCloseArea())
		Else
			cProduto := oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cpartNumber
			cItePed  := substr(oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cMoveOrderID,11,4)
			cQuant   := oWS:oWSgetAdvanceShipNoticeReturn:oWSinvoice:oWSinvoiceitem[i]:cquantity
		   //	Alert(STR0013 /*"Não foi possível localizar Pedido com quantidade suficiente para baixar. Produto: "*/ + cProduto + STR0014 /*" Item do Pedido: "*/ + cItePed + STR0015/*" Quantidade: "*/ + cQuant) 
		    Alert("Não foi possível localizar Pedido com quantidade suficiente para baixar. Produto: " + cProduto + " Item do Pedido: " + cItePed + " Quantidade: " + cQuant)
		Endif
		(cAliasSC7)->(dbCloseArea())   
    Next
	
	MsgInfo("Pré-Nota atualizada com sucesso!")
Endif	

Return(.t.)
