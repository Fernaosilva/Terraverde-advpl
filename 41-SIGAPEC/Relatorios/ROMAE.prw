#include "protheus.ch"

User Function ROMAE()
Private _cPerg  := PadR("ROMANEIO1", Len(SX1->X1_GRUPO))

CriaPerg(_cPerg)

Processa( {|| ReportDef()  }, "ROMANEIO DE ENTRADA" )                    

Return  

Static Function ReportDef()
Private oSessao1 := nil
Private oReport

pergunte(_cPerg,.F.) 

//######################
//##Cria Objeto TReport#
//######################
oReport := TReport():New("ROMANEIO DE ENTRADA","ROMANEIO DE ENTRADA", _cPerg ,{|| PrintReport()},"ROMANEIO DE ENTRADA")
//oReport:lParamPage := .F.   //Exibe parâmetros para impressão. 
//oReport:SetLandscape(.T.)   //Define orientação de página do relatório como paisagem. 
//oReport:nFontBody := 8.6  
//oReport:SetColSpace(1)
//oReport:cFontBody := 'Arial' 
//oReport:SetLineHeight(40)
                                 
oReport:SetTotalInLine(.F.)
oReport:SetLineHeight(40)
oReport:SetColSpace(1)
oReport:SetLeftMargin(0)
oReport:oPage:SetPageNumber(1)
//oReport:cFontBody := 'Courier New'
oReport:nFontBody := 8.6
oReport:lBold := .F.
oReport:lUnderLine := .F.
oReport:lHeaderVisible := .T.
oReport:lFooterVisible := .T.
oReport:lParamPage := .F.
//oReport:SetAutoSize := .T.




//###############
//##Cria Sessao1#
//###############    
//oSessao1 := TRSection():New(oReport, "ROMANEIO DE ENTRADA",3,4,5,6,7,.T.,9,10,11,12,13,14,15,16,17,18,19,20,21,22,)
oSessao1 := TRSection():New(oReport, "ROMANEIO DE ENTRADA",,,,,,.T.)    //A classe TRSection pode ser entendida como um layout do relatório, por conter células, quebras e totalizadores que darão um formato para sua impressão.
//oSessao1:SetHeaderSection(.T.) //Define que imprime cabeçalho das células na quebra de seção
//oSessao1:SetHeaderBreak(.F.)   //Define se imprime cabeçalho das células após uma quebra (TRBreak). lHeaderBreak Se verdadeiro, aponta que salta página na quebra                                      


oSessao1:SetTotalInLine(.F.)
//oSessao1:SetTotalText('Contas a Receber')
oSessao1:lUserVisible := .T.
oSessao1:lHeaderVisible := .F.
oSessao1:SetLineStyle(.F.)
oSessao1:SetLineHeight(30)
oSessao1:SetColSpace(1)
oSessao1:SetLeftMargin(0)
oSessao1:SetLinesBefore(0)
oSessao1:SetCols(80)
oSessao1:SetHeaderSection(.T.)
oSessao1:SetHeaderPage(.F.)
oSessao1:SetHeaderBreak(.F.)
oSessao1:SetLineBreak(.F.)
oSessao1:SetAutoSize(.T.)
oSessao1:SetPageBreak(.F.)
//oSessao1:SetClrBack(16777215)
//oSessao1:SetClrFore(0)
//oSessao1:SetBorder('')
//oSessao1:SetBorder('',,,.T.)

                       
//TRCell():New(oParent, cName , _cAlias, cTitle,     cPicture, nSize  ,lPixel  , bBlock  ,    cAlign      ,  lLineBreak  ,  cHeaderAlign ,  lCellBreak ,  nColSpace ,  lAutoSize ,  nClrBack ,  nClrFore ,  lBold,)                   
//TRCell():New(oSessao1,"FILIAL"   ,'TRB', "FIIIAL"       	,,TamSX3("F1_FILIAL")[1], , ,"CENTER", ,"CENTER", ,, , , , ,)

//TRCell():New(oSessao1,"EMISSA"   ,'TRB', "EMISSÃO"       	,,TamSX3("D1_EMISSAO")[1], , ,"LEFT", ,"LEFT", ,2, , , , ,)
TRCell():New(oSessao1,"EMISSA",'TRB', "EMISSÃO",,10,.F.)
TRCell():New(oSessao1,"FORNEC"   ,'TRB', "FORNECEDOR"      	,,17, , ,"LEFT", ,"LEFT", , , , , , ,)
TRCell():New(oSessao1,"NOTAFI"   ,'TRB', "NOTA FISCAL"	   	,,TamSX3("D1_DOC")[1],,,"LEFT", ,"LEFT", , , , , , ,)
TRCell():New(oSessao1,"CODIGO"   ,'TRB', "CÓDIGO" 	 		,,TamSX3("D1_COD")[1], , ,"LEFT", ,"LEFT", , , , , , ,) 
TRCell():New(oSessao1,"DESCRI"   ,'TRB', "DESCRIÇÃO" 	 	,,16, , ,"LEFT", ,"LEFT", , , , , , ,)   
TRCell():New(oSessao1,"GRUPOO"   ,'TRB', "GRUPO"	 	 	,,16, , ,"LEFT", ,"LEFT", , , , , , ,)   
TRCell():New(oSessao1,"QUANTI"   ,'TRB', "QTDE NF."    		,,7, , ,"CENTER", ,"CENTER", , , , , , ,)
TRCell():New(oSessao1,"LOCALI"   ,'TRB', "LOCALIZAÇÃO" 	   	,,TamSX3("BZ_LOCALI2")[1], , ,"LEFT", ,"LEFT", , , , , , ,)

oBreak1 := TRBreak():New(oSessao1,'',"Notas",.F.)                                                                                                                                  
oBreak1 := TRBreak():New(oSessao1,{||TRB->NOTAFI},"Total",.F.)
TRFunction():New(oSessao1:Cell("QUANTI"), ""	, "SUM"		, oBreak1, ""/*cTitle*/	, /*cPicture*/	, /*uFormula*/		, .F./*lEndSection*/, .F./*lEndReport*/, .F./*lEndPage*/) 


oReport:PrintDialog()
Return  


Static Function PrintReport() 
U_Selecao200()///Seleciona Dados para o Relatório
oReport:SetMeter(TRB->(RecCount()))
oSessao1:Init() 

TRB->(DbGoTop())  //Move o cursor da área de trabalho ativa para o primeiro registro lógico.
While TRB->(!EOF())    
   
	oReport:IncMeter() //IncMeter() Incrementa a regua de progreção do relatório  
    oSessao1:PrintLine(.T.)
    
	TRB->(DBSKIP())        
ENDDO

oSessao1:Finish()
TRB->(DbCloseArea())
TMP3->(DbCloseArea())
Return                       


Static Function CriaPerg(cPerg)
	PutSX1(_cPerg,"01","Filial De....................:?","","","MV_CH1","C",6,00,0,"G","","SM0" ,"   ","S","mv_par01","","","","","","","","","","","","","","","","")  
	PutSX1(_cPerg,"02","Filial Ate...................:?","","","MV_CH2","C",6,00,0,"G","","SM0" ,"   ","S","mv_par02","","","","","","","","","","","","","","","","")  
  	PutSX1(_cPerg,"03","Data de Digitação De.........:?","","","MV_CH3","D",8,00,0,"G","","" ,"   ","S","mv_par03","","","","","","","","","","","","","","","","")  	
	PutSX1(_cPerg,"04","Data de Digitação Até........:?","","","MV_CH4","D",8,00,0,"G","","" ,"   ","S","mv_par04","","","","","","","","","","","","","","","","")  	
	PutSX1(_cPerg,"05","Notas Fiscais................:?","","","MV_CH5","C",99,00,0,"G","","" ,"   ","S","mv_par05","","","","","","","","","","","","","","","","")                                                                                                               
//	PutSX1(_cPerg,"06","Nota Ate.....................:?","","","MV_CH6","C",9,00,0,"G","","" ,"   ","S","mv_par06","","","","","","","","","","","","","","","","")
Return  

User Function Selecao200() 
Local cQuery   := ''
Local cVetor   := ''
Local _QtdPDV  := 0 
Local _VlrPDV  := 0 
Local _cComp   := 0
Local _nQuant  := 0   
Local aArqTrab := {}   
Local cTabAux  := ""
Private aStru  := {}
			
  
aadd(aArqTrab,{"EMISSA"  ,"D",10,0})
aadd(aArqTrab,{"NOTAFI"  ,"C",13,0})
aadd(aArqTrab,{"CODIGO"  ,   TamSX3("D1_COD")[3]        ,TamSX3("D1_COD")[1]  		,TamSX3("D1_COD")[2]})
aadd(aArqTrab,{"DESCRI"  , 	 TamSX3("B1_DESC")[3]  		,TamSX3("B1_DESC")[1]		,TamSX3("B1_DESC")[2]})   
aadd(aArqTrab,{"QUANTI"  ,   TamSX3("D1_QUANT")[3]  	,TamSX3("D1_QUANT")[1]  	,TamSX3("D1_QUANT")[2]})
aadd(aArqTrab,{"LOCALI"  ,   TamSX3("BZ_LOCALI2")[3]  	,TamSX3("BZ_LOCALI2")[1] 	,TamSX3("BZ_LOCALI2")[2]})
aadd(aArqTrab,{"GRUPOO"  ,"C",17,0})
aadd(aArqTrab,{"FORNEC"  ,"C",17,0})
                                                                               	
cTabAux := CriaTrab(aArqTrab, .T.)     
DbCreate(cTabAux, aArqTrab)
//cInd := LEFT(cTabAux, 7) + "1"
//cInd2 := LEFT(cTabAux, 7) + "2"

Iif(Select('TRB') > 0, TRB->(DbCloseArea()),)
DbUseArea(.T., , cTabAux, 'TRB', .F., .F.)

//Indice de organização do relatório    
//IndRegua('TRB', cInd, "NOTAFI")    
//TRB->(DbClearIndex())	
//DbSetIndex(cInd , +  OrdBagExt())

 
//// Registros para a seção Total Consumo Via Requisições
Iif(Select("TMP3") > 0, TMP3->(DbCloseArea()),)

// Seleção de dados
cQuery += "SELECT NOTA.F1_FILIAL, NOTA.F1_DOC AS DOC, RTRIM(ITENS.D1_COD) AS CODIGO, SUBSTRING(RTRIM(UPPER(CADAS.B1_DESC)),1,16) AS DESCRICAO, ITENS.D1_TIPO, ITENS.D1_QUANT AS QTDENF, RTRIM(LOCALL.BZ_LOCALI2) AS LOCALL, NOTA.F1_EMISSAO, RTRIM(ITENS.D1_GRUPO) +'-'+ SUBSTRING(RTRIM(GRUPO.BM_DESC),1,16) AS GRUPO, SUBSTRING(RTRIM(FORNEC.A2_NOME),1,17) AS FORNECEDOR"

//Tabela Principal e seus relacionamentos
cQuery += " FROM " + RetSqlName("SD1") + " ITENS " 
cQuery += " LEFT JOIN " + RetSqlName("SBZ") + " LOCALL " + " ON (LOCALL.BZ_FILIAL = ITENS.D1_FILIAL) AND (LOCALL.BZ_COD = ITENS.D1_COD) "
cQuery += " INNER JOIN " + RetSqlName("SB1") + " CADAS " + " ON (CADAS.B1_COD = ITENS.D1_COD)"
cQuery += " INNER JOIN " + RetSqlName("SF1") + " NOTA " + " ON (NOTA.F1_FILIAL = ITENS.D1_FILIAL) AND (NOTA.F1_DOC = ITENS.D1_DOC) AND (NOTA.F1_SERIE = ITENS.D1_SERIE) "
cQuery += " LEFT JOIN " + RetSqlName("SBM") + " GRUPO " + " ON (GRUPO.BM_GRUPO = ITENS.D1_GRUPO) AND SUBSTRING(GRUPO.BM_FILIAL,1,2)=SUBSTRING(ITENS.D1_FILIAL,1,2)"
cQuery += " INNER JOIN " + RetSqlName("SA2") + " FORNEC " + " ON (FORNEC.A2_COD = ITENS.D1_FORNECE) AND (FORNEC.A2_LOJA = ITENS.D1_LOJA) "

//Pré Parametros
cQuery += " WHERE ITENS.D_E_L_E_T_ = '' AND CADAS.D_E_L_E_T_ = '' AND NOTA.D_E_L_E_T_ = '' AND GRUPO.D_E_L_E_T_ = '' AND FORNEC.D_E_L_E_T_ = ''" //AND LOCALL.D_E_L_E_T_ <> '*' tratar exclusao da SBZ

//Parametros de Perguntas
cQuery += " and ITENS.D1_FILIAL  >= '" + MV_PAR01 + "'"  
cQuery += " and ITENS.D1_FILIAL  <= '" + MV_PAR02 + "'" 
cQuery += " AND ITENS.D1_DTDIGIT >= '" + DTOS(MV_PAR03) + "'"
cQuery += " AND ITENS.D1_DTDIGIT <= '" + DTOS(MV_PAR04) + "'"

// caso nao encontre SBZ

//cQuery += " AND ISNULL(LOCALL.BZ_FILIAL, 0) = 0 AND ISNULL(LOCALL.BZ_COD, 0) = 0 "

//cVetor += "'"
//cVetor += ALLTRIM(MV_PAR05)
//STRTRAN(MV_PAR05,",","','")
//MV_PAR05 += "'"
If !empty(MV_PAR05)      // filtrar alguma nota
	cQuery += " and ITENS.D1_DOC IN ('" + STRTRAN(ALLTRIM(MV_PAR05),",","','") +"')"
Endif
cQuery += " ORDER BY 2,3 "     // Caique Mercadante - Ordenação NOTAFI + CODIGO - Removi a ordenação por Indice na linha 157  

dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),'TMP3',.T.,.T.)  
   
TMP3->(dbgotop())


While TMP3->(!Eof())                                                                   
		            
  	 	RecLock('TRB', .T.)    
  	 	                                                 
  	 	//TRB->FILIAL := TMP3-> F1_FILIAL     	//FILIAL
		TRB->EMISSA := STOD(TMP3->F1_EMISSAO)  	//DATA DE EMISSÃO
	   	TRB->NOTAFI := TMP3-> DOC		   		//CODUMENTO
		TRB->CODIGO := TMP3-> CODIGO       		//CODIGO
		TRB->DESCRI := TMP3-> DESCRICAO    		//SÉRIE
		TRB->QUANTI := TMP3-> QTDENF  			//QUANTIDADE
		TRB->LOCALI := TMP3-> LOCALL		  	//LOCAL ESTOQUE   	   	
	   	TRB->GRUPOO := TMP3-> GRUPO            //GRUPO
	   	TRB->FORNEC := TMP3-> FORNECEDOR       //FORNECEDOR
					
	    TRB->(MsUnlock())
		TMP3->(DbSkip())
EndDo     

Return