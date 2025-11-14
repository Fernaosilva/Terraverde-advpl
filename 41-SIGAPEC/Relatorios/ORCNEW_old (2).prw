#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} ORCAMTO
Substitui o fonte padrão ORCAMTO.PRW.
@type function
@version 1.0
@author Charlles Reis
@since 21/06/2018
@see https://tdn.totvs.com/display/tec/TMSPrinter
@link https://gkcmp.com.br (Geeker Company)
@history 13/02/2024, Ademar Fernandes Jr., Melhoria para diminuir o espaçamento entre as linhas impressas.
@history 15/05/2024, Ademar Fernandes Jr., Implementado melhoria de Impressao Resumida.
@history 31/07/2025, Ademar Fernandes Jr., Implementado melhoria de Impressao Linha Amarela ( Wirtgen JD ).
@return variant, True
/*/
User Function ORCAMTO()
	Local aAreaAtu	:= GetArea()
	Local aAreaVS1	:= VS1->(GetArea("VS1"))
	Local aAreaVS3	:= VS1->(GetArea("VS3"))

	Private oPrn    	:= TMSPrinter():New("Relatorio")
	Private oFnt		:= Nil
	Private oFnt2		:= Nil
	Private oFnt3		:= Nil
	Private oFnt4		:= Nil
	Private oFnt5		:= Nil
	Private oFnt6		:= Nil
	Private nPag    	:= 0
	Private nLi     	:= 1
	
	Private nTotPec  	:= nTotSer  := 0
	Private nTotDesS 	:= nTotDesP := 0
	Private aLista  	:= {}
	
	Private cQry	 	:= ""
	Private cStaRes	 	:= ""
	Private cStat	 	:= ""
	Private nA_		 	:= 0
	Private nPG		 	:= 0
	Private nPN		 	:= 0
	Private nNG		 	:= 0  
	Private nNP		 	:= 0 
	Private nNN		 	:= 0 
	Private nValFre	 	:= VS1->VS1_VALFRE
	Private nTotIcmST	:= 0
	Private nTotDESACE  := 0
	Private nTotICMS	:= 0
	Private nTotIPI		:= 0
	Private cPerg 		:= "ORCAMT2   "
/*
	//--->>>> Trecho utilizando durante o Desenvolvimento e Testes da rotina <<<<---// <<< TESTE_ADEMAR >>>
	if GetTempPath() <> "C:\Users\adema\AppData\Local\Temp\"
		MsgAlert(OemToAnsi("TAKE EASY... Rotina ainda em construção !!!"),FunDesc())
		Return
	endif
*/
	If !Pergunte(cPerg,.T.)
		Return
	EndIf
			
	FS_ORCAMENTO(ParamIXB[1])
	
	RestArea(aAreaAtu)
	RestArea(aAreaVS1)
	RestArea(aAreaVS3)
Return (.T.)                    

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} FS_ORCAMENTO
Chama a impressão do orçamento.
Uso: ORCNEW()
@author    	Charlles Reis
@version   	1.0
@since      21/06/2018
/*/
//-------------------------------------------------------------------------------------
Static Function FS_ORCAMENTO(_cNumOrc)
	Private nTotResum  := 0
	Private lOpcResum  := .F.
	Private lOpcYellow := .F.

	//-Chama tela pra imprimir opçao Normal ou com "Orçamento Resumido"
	fnOpcResum(@lOpcResum,@lOpcYellow)

	//Posicionamento dos Arquivos
	DbSelectArea("VS1")
	DbSetOrder(1)
	DbSeek(xFilial("VS1")+_cNumOrc)
	//cMarca   := VS1->VS1_CODMAR
	
	DbSelectArea("VV1")
	FG_SEEK("VV1","VS1->VS1_CHAINT",1,.f.)
	
	DbSelectArea("VS1")
	FG_Seek("SE4","VS1->VS1_FORPAG",1,.f.)
	
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+VS1->VS1_CLIFAT+VS1->VS1_LOJA)
	
	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+VS1->VS1_CODVEN)
	
	ORCPRN()
Return

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} ORCPRN
Monta a impressão do orçamento.
Uso: ORCNEW()
@author    	Charlles Reis
@version   	1.0
@since      21/06/2018
/*/
//-------------------------------------------------------------------------------------
Static Function ORCPRN()
	Local nIt      := 0                        
	Local x        := 0
	Local cSld     := ""
	Local lVar1	   := .T.
	Local nVlrPad := 0
	Local nQuantC := 0
	
	DEFINE FONT oFnt  NAME "Calibri" SIZE 0,09 OF oPrn //BOLD
	DEFINE FONT oFnt2 NAME "Calibri" SIZE 0,10 OF oPrn BOLD
	DEFINE FONT oFnt3 NAME "Calibri" SIZE 0,14 OF oPrn BOLD
	DEFINE FONT oFnt4 NAME "Calibri" SIZE 0,10 OF oPrn 
	DEFINE FONT oFnt5 NAME "Calibri" SIZE 0,09 OF oPrn BOLD
	DEFINE FONT oFnt6 NAME "Calibri" SIZE 0,12 OF oPrn BOLD
	
    // Serviços
	If VS1->VS1_TIPORC == "2"	//-1=Orcamento Pecas;2=Orcamento Oficina;3=Transferência
		DbSelectArea("VS4")
		DbSeek(xFilial("VS4")+VS1->VS1_NUMORC)
		Do While !Eof() .and. VS4->VS4_NUMORC == VS1->VS1_NUMORC
			DbSelectArea("VO6")
			DbSetOrder(4)
			DbGotop()
			DbSeek(xFilial("VO6")+VS4->VS4_CODSER)
			DbSelectArea("VS4")
			aAdd(aLista, {	"2",;				//-01
							VS4->VS4_GRUSER,;	//-02
							VS4->VS4_CODSER,;	//-03
							left(AllTrim(VO6->VO6_DESSER),42),;	//-04
							VS4->VS4_TIPSER,; 	//-05
							VS4->VS4_TEMPAD,;	//-06
							0,;					//-07
							VS4->VS4_VALSER,;	//-08
							VS4->VS4_PERDES,;	//-09
							VS4->VS4_VALDES,;	//-10
							VS4->VS4_VALTOT,;	//-11
							"SV",;				//-12	
							VS4->VS4_VALVEN,;	//-13
							VS4->VS4_VALHOR	})	//-14-Prc.Unit.(KM,SRV,etc)
			VS4->(DbSkip())
		EndDo
	EndIf
	
	//oPrn:SetLandscape()
	oPrn:SetPortrait()
	
	DbSelectArea("VS3")
	DbGotop()
	DbSetOrder(2)
	If MsSeek(xFilial("VS3")+VS1->VS1_NUMORC)
		DbSelectArea("SB1")
		DbSetOrder(7)
		DbSelectArea("SB5")
		DbSelectArea("VS3")
		Do While !EOF() .and. VS3->VS3_NUMORC == VS1->VS1_NUMORC
			DbSelectArea("SB1")
			DbGotop()
			DbSeek(xFilial("SB1")+VS3->VS3_GRUITE+VS3->VS3_CODITE)
			
			DbSelectArea("SB5")
			DbGotop()
			DbSeek(xFilial("SB5")+SB1->B1_COD)
			
			DbSelectArea("SBM")
			DbGotop()
			DbSeek(xFilial("SBM")+VS3->VS3_GRUITE)
			
			DbSelectArea("SB2")
	 		DbSeek(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD)
			nSaldo := SaldoSB2()
			
			//Iif(Select('TMP') > 0, TMP->(DbCloseArea()),)
			cQry := "SELECT SUM(B2_QATU) AS QGRUP FROM " + RetSqlName('SB2') + " WITH (NOLOCK) WHERE SUBSTRING(B2_FILIAL,1,4) = '0203' AND B2_COD = '" + VS3->VS3_CODITE + "' AND B2_LOCAL = '01' AND D_E_L_E_T_= ' '"
			//TcQuery cQry New Alias "TMP"		
			//nQtGrup := TMP->QGRUP
			nQtGrup := FM_SQL(cQry)
					
			DbSelectArea("VS3")	
					
			If VS3->VS3_QTDITE > 0 .And. AllTrim(VS3->VS3_SEQUEN)<>""
				
				If 		nSaldo >= VS3->VS3_QTDITE
				   			cStat := 'A/-' //Filial Atende Total
				   			nA_   += 1
				ElseIf	nSaldo > 0 .And. nSaldo < VS3->VS3_QTDITE .And. nQtGrup >= VS3->VS3_QTDITE
							cStat := 'P/A' //Filial Atende Parcialente - Grupo Atende Total
							nPG   += 1			   			
				ElseIf	nSaldo > 0 .And. nSaldo < VS3->VS3_QTDITE .And. nQtGrup < VS3->VS3_QTDITE
							cStat := 'P/N' //Filial Atende Parcialente - Grupo Não Atende
							nPN   += 1 			   			
				ElseIf	nSaldo = 0 .And. nQtGrup >= VS3->VS3_QTDITE
							cStat := 'N/A' //Filial Não atende - Grupo Atende
							nNG   += 1 						
				ElseIf	nSaldo = 0 .And. nQtGrup > 0 .And. nQtGrup < VS3->VS3_QTDITE
							cStat := 'N/P' //Filial Não Atende - Grupo Atende Parcialmente
							nNP   += 1							
				ElseIf	nSaldo = 0 .And. nQtGrup = 0
							cStat := 'N/N' //Filial Não atende - Grupo Não Atende
							nNN	  += 1																						   			
				EndIf
				
				//Tratamento para buscar o CFOP a partir da TES
				cCFOP := posicione("SF4",1,xfilial("SF4")+VS3->VS3_CODTES,"F4_CF")
				//Verificar se é dentro ou fora do estado
				If SA1->A1_EST == "SP" 
					cCFOP := '5'+SUBSTR(cCFOP,2,3)
				Else
					cCFOP := '6'+SUBSTR(cCFOP,2,3)
				EndIf

				aAdd(aLista, 	{iif(nSaldo <= 0,"1","0"),; 	//[1]
								VS3->VS3_SEQUEN,; 				//[2]
								VS3->VS3_CODITE,;				//[3]
								Left(AllTrim(SB1->B1_DESC),42),;//[4]
								Left(FM_PRODSBZ(SB1->B1_COD,"SBZ->BZ_LOCALI2"),8),; //[5]
								VS3->VS3_QTDITE,;				//[6]
							 	nSaldo,;						//[7]
							  	VS3->VS3_VALPEC,;				//[8]
							   	VS3->VS3_PERDES,;				//[9]
							    VS3->VS3_VALDES,;				//[10]
							    VS3->VS3_VALTOT,;				//[11]
							    SB1->B1_POSIPI,;				//[12]
							    cStat ,;						//[13]
								VS3->VS3_ICMCAL,;				//[14]
								VS3->VS3_VIPIFB,;				//[15]
								cCFOP} )						//[16]
			EndIf			
																					
			VS3->(DbSkip())
		Enddo
	EndIf
	       
	//TMP->(DbCloseArea())
	//1=Reservado;2=Parcialmente Reservado;3=Nao Reservado                                                                            
	If  	VS1->VS1_STARES = "1"
	   		cStaRes := "Reservado"
	ElseIf  VS1->VS1_STARES = "2"
	   		cStaRes := "Parc. Reservado"
	ElseIf  VS1->VS1_STARES = "3"
	   		cStaRes := "Não Reservado"
	EndIf   
	
	If 		MV_PAR01 == 1
		aSort(aLista,,, { |x, y| x[3] < y[3] })
	ElseIf  MV_PAR01 == 2
		aSort(aLista,,, { |x, y| x[2] < y[2] })	
	ElseIf  MV_PAR01 == 3
		aSort(aLista,,, { |x, y| x[5] < y[5] })
	EndIf
	
	//Armazena os impostos e despesas
	nTotIcmST  := VS1->VS1_ICMRET
	nTotDESACE := VS1->VS1_DESACE
	nTotICMS   := VS1->VS1_ICMCAL
	nTotIPI    := VS1->VS1_VALIPI

	For x := 1 to len(aLista)
		cSld := aLista[x,1]
	
		If nLi == 1 .OR. nLi > 3000  // Trata Cabeçalho e Rodapé
			If nLi > 1
				oPrn:Endpage()
			EndIf
			
			nLi := 100
			oPrn:StartPage()
			nPag++
			xCabec(aLista[x,1])
			lVar1 := .T.		 
			IF aLista[x,1] <> "2" // se não for serviço
				nLi += 20
				oPrn:say(nLi,  50, "Peças do Orçamento", oFnt2)	
			EndIf	
			cSld := aLista[x,1]
			nLi += 80
		EndIf                  
		
		If aLista[x,1] == "2" .And. lVar1 == .T.
			xCabSer()																				
			lVar1 := .F.
		EndIf
			
		cSld := aLista[x,1]
		nLi += 10
			
		++nIt		
				
		//oPrn:Box(nLi-30,  40,nLi+30, 2350)
		IF cSld <> "2" // Peças
			//-Impressao do corpo do bloco "Peças do Orçamento"
			//-------------------------------------------------
			If MV_PAR04 == 2 //2-Imprime codigo 1-Não imprime código
				oPrn:say(nLi-10,   50, aLista[x,3], oFnt)								// Código
			EndIf
			oPrn:say(nLi-10,  290, substr(aLista[x,4],1,30), oFnt)						// Descrição 
			If MV_PAR04 == 2 //2-Imprime codigo 1-Não imprime código
				oPrn:say(nLi-10,  810, aLista[x,12], oFnt)								// NCM		
			EndIf
			oPrn:say(nLi-10, 970, aLista[x,13], oFnt4)									// Status 
			//oPrn:say(nLi-10, 970, aLista[x,5], oFnt4)									// Localização
			
			oPrn:say(nLi-10, 1100, Transform(aLista[x,6],"@E 999,999"), oFnt)			// Qtde.		
	//		oPrn:say(nLi-10, 1450, Transform(aLista[x,7],"@E 999,999"), oFnt4)        	// Saldo			
			If	MV_PAR03 == 2
				oPrn:say(nLi-10, 1250, Transform(aLista[x,8],"@E 999,999.99"), oFnt)    // Preço Unitário
				oPrn:say(nLi-10, 1400, Transform(aLista[x,9],"@R 9999.99"), oFnt)       // % Desconto
				oPrn:say(nLi-10, 1550, Transform(aLista[x,10],"@E 999,999.99"), oFnt)   // Valor Desconto
			Else
				nVUnitDesc := aLista[x,11]/aLista[x,6]
				oPrn:say(nLi-10, 1250, Transform(nVUnitDesc,"@E 999,999.99"), oFnt)     // Preço Unitário - Desconto
			EndIf
			oPrn:say(nLi-10, 1650, Transform(aLista[x,15],"@E 999,999.99"), oFnt)       // Valor Ipi
			oPrn:say(nLi-10, 1790, Transform(aLista[x,14],"@E 999,999.99"), oFnt)       // Valor Icms
			oPrn:say(nLi-10, 1950, aLista[x,16], oFnt)                	  				// CFOP
			oPrn:say(nLi-10, 2100, Transform(aLista[x,11],"@E 999,999,999.99"), oFnt)   // Valor Total
			nTotDesP += aLista[x,10]
			nTotPec  += aLista[x,11]

		Else
			//-Impressao do corpo do bloco "Serviços"
			//---------------------------------------
/*			aAdd(aLista, {	"2",;				//-01
							VS4->VS4_GRUSER,;	//-02
							VS4->VS4_CODSER,;	//-03
							left(AllTrim(VO6->VO6_DESSER),42),;	//-04
							VS4->VS4_TIPSER,; 	//-05
							VS4->VS4_TEMPAD,;	//-06
							0,;					//-07
							VS4->VS4_VALSER,;	//-08
							VS4->VS4_PERDES,;	//-09
							VS4->VS4_VALDES,;	//-10
							VS4->VS4_VALTOT,;	//-11
							"SV",;				//-12	
							VS4->VS4_VALVEN,;	//-13
							VS4->VS4_VALHOR	})	//-14-Prc.Unit.(KM,SRV,etc)
*/
			if !lOpcResum .And. !lOpcYellow
				oPrn:say(nLi-10,   50, aLista[x,2], oFnt)									// Grupo
				oPrn:say(nLi-10,  150, aLista[x,3], oFnt)									// Código
				oPrn:say(nLi-10,  600, substr(aLista[x,4],1,23), oFnt)						// Descrição
				oPrn:say(nLi-10, 1320, aLista[x,5], oFnt)									// Tipo Serviço
		//		oPrn:say(nLi-10, 1450, Transform(aLista[x,6],"@R 99:99"), oFnt4)			// Tempo
				oPrn:say(nLi-10, 1050, Iif(aLista[x,8]>0,Transform(aLista[x,8],"@E 999,999.99"),Transform(aLista[x,13],"@E 999,999.99")), oFnt)	// Preço Unitário
				If MV_PAR03 == 2
					oPrn:say(nLi-10, 1250, Transform(aLista[x,9],"@E 9999.99"), oFnt)		// % Desconto
					oPrn:say(nLi-10, 1400, Transform(aLista[x,10],"@E 999,999.99"), oFnt)	// Valor Desconto
				EndIf
				oPrn:say(nLi-10, 2100, Iif(aLista[x,11]>0,Transform(aLista[x,11],"@E 999,999,999.99"),Transform(aLista[x,13],"@E 999,999,999.99")), oFnt) // Valor Total

			elseif !lOpcResum .And. lOpcYellow	//-20250805
				oPrn:say(nLi-10,   50, aLista[x,2], oFnt)									// Grupo
				oPrn:say(nLi-10,  150, aLista[x,3], oFnt)									// Código Srv.
				oPrn:say(nLi-10,  600, substr(aLista[x,4],1,23), oFnt)						// Descrição
				oPrn:say(nLi-10, 1320, aLista[x,5], oFnt)									// Tipo Serviço
				nVlrPad := Iif(aLista[x,8]>0, aLista[x,8], aLista[x,13])
				nQuantC := Iif(!Empty(nVlrPad), (nVlrPad / aLista[x,14]), 0)
				oPrn:say(nLi-10, 1470, Transform(nQuantC,"@E 99999.99"), oFnt4)				// Tempo Padrao / Qtde.
				oPrn:say(nLi-10, 1630, Transform(aLista[x,14],"@E 999,999.99"), oFnt4)		// Preço Unitário
				If MV_PAR03 == 2 .And. aLista[x,9]+aLista[x,10] > 0
					oPrn:say(nLi-10, 1800, Transform(aLista[x,9],"@E 9999.99"), oFnt)		// % Desconto
					oPrn:say(nLi-10, 1950, Transform(aLista[x,10],"@E 999,999.99"), oFnt)	// Valor Desconto
				EndIf
				oPrn:say(nLi-10, 2100, Iif(aLista[x,11]>0,Transform(aLista[x,11],"@E 999,999,999.99"),Transform(aLista[x,13],"@E 999,999,999.99")), oFnt) // Valor Total

			else
				//-Soma o total da linha de serviço (abaixo)
				nLi -= (10 + 45)	//-Subtrai para ajustar com as somas desta funçao!!
			endif
			nTotDesS += aLista[x,10]
			If	aLista[x,11]>0	
				nTotSer  += aLista[x,11]
			Else	
				nTotSer  += aLista[x,13]		
			EndIf
		EndIf	
		
		nLi += 45
	Next X

	if nTotSer > 0 .And. lOpcResum
		//-Melhoria Impressao Rsumida !!
		oPrn:say(nLi-10,  150, "001", oFnt)										// Código
		oPrn:say(nLi-10,  600, "SERVIÇOS - DIVERSOS", oFnt)						// Descrição
		oPrn:say(nLi-10, 2100, Transform(nTotSer,"@E 999,999,999.99"), oFnt)	// Valor Total
		nLi += 20
	endif

	X := Len(aLista)
	xRoda()
	oPrn:Endpage()
	oPrn:End()
	oPrn:Preview()
	//oPrn:Print()
Return

//***************************************************************************************************************************
Static Function xCabSer()

	oPrn:Say(nLi-10 , 1100, "Serviços", oFnt3)
	nLi+=40
	If !lOpcResum .And. lOpcYellow	//-20250805
		//oPrn:Box(nLi-10,  40,nLi+100, 2350)
		oPrn:Say(nLi-10,  50,"Grp"		,oFnt2)
		oPrn:Say(nLi-10, 150,"Código"	,oFnt2)
		oPrn:Say(nLi-10, 600,"Descrição",oFnt2)
		oPrn:Say(nLi-10,1320,"Tipo"		,oFnt2)
		oPrn:Say(nLi-10,1500,"Qtde"		,oFnt2)
		oPrn:Say(nLi-10,1650,"Vlr Unit.",oFnt2)
		If MV_PAR03 == 1
			oPrn:Say(nLi-10,1800,"% Desc"	,oFnt2)
			oPrn:Say(nLi-10,1950,"Vlr Desc" ,oFnt2)
		EndIf
		oPrn:Say(nLi-10,2100,"Vlr Total"	,oFnt2)
	Else
		//oPrn:Box(nLi-10,  40,nLi+100, 2350)
		oPrn:Say(nLi-10,  50,"Grp"		,oFnt2)
		oPrn:Say(nLi-10, 150,"Código"	,oFnt2)
		oPrn:Say(nLi-10, 600,"Descrição",oFnt2)
		oPrn:Say(nLi-10,1320,"Tipo"		,oFnt2)
		//oPrn:Say(nLi+30,1450,"Tempo"	,oFnt2)
		oPrn:Say(nLi-10,1600,"Vlr Serv.",oFnt2)
		If MV_PAR03 == 1
			oPrn:Say(nLi-10,1800,"% Desc"	,oFnt2)
			oPrn:Say(nLi-10,1950,"Vlr Desc" ,oFnt2)
		EndIf
		oPrn:Say(nLi-10,2150,"Vlr Total"	,oFnt2)
	EndIf
	nLi += 50
	
Return

//***************************************************************************************************************************
Static Function xCabPec()
	
	oPrn:Box(nLi   ,  40,nLi+100, 2350)
	If MV_PAR04 == 2 //1-Imprime codigo 2-Não imprime código
		oPrn:Say(nLi+30,  50,"Código",oFnt2)    
	EndIf
	oPrn:Say(nLi+30, 310,"Descrição",oFnt2)
	If MV_PAR04 == 2 //1-Imprime codigo 2-Não imprime código
		oPrn:Say(nLi+30, 810,"NCM",oFnt2)
	EndIf
	//oPrn:Say(nLi+30,850,"Status",oFnt2)
	oPrn:Say(nLi+30,970,"Status",oFnt2)
	//oPrn:Say(nLi+30,970,"Localiz",oFnt2)
	oPrn:Say(nLi+30,1100,"Qtde",oFnt2)
	//oPrn:Say(nLi+30,1450,"Saldo",oFnt2)
	oPrn:Say(nLi+30,1250,"Pr Unit",oFnt2)
	If	MV_PAR03 == 2
		oPrn:Say(nLi+30,1400,"% Desc",oFnt2)
		oPrn:Say(nLi+30,1550,"Vlr Desc",oFnt2)
	EndIf
	oPrn:Say(nLi+30,1700,"IPI",oFnt2)
	oPrn:Say(nLi+30,1800,"ICMS",oFnt2)
	oPrn:Say(nLi+30,1950,"CFOP",oFnt2)
	oPrn:Say(nLi+30,2150,"Vlr Total",oFnt2)
	nLi += 100
	
Return

//***************************************************************************************************************************
Static Function xCabec(cTipo)
	
	nUltKil := 0
	
	if VS1->VS1_KILOME != 0
		nUltKil := VS1->VS1_KILOME
	else
		nUltKil := FG_UltKil(VV1->VV1_CHAINT)
	endif
	
	//oPrn:sayBitmap(nLi,090,"LOGOBMP.BMP",280,260)
	//oPrn:sayBitmap(nLi,070,"LOGOBMP.BMP",410,250)
	If  SM0->M0_CODIGO = '01' .AND. SUBSTR(SM0->M0_CODFIL,1,2) = '05'  
		oPrn:sayBitmap(nLi,070,"LOGO_IR.BMP",410,250)
	Else
		oPrn:sayBitmap(nLi,070,"LOGOBMP.BMP",410,250)
	Endif	
	oPrn:Box(nLi- 50,  40, nLi+280, 2350)
	oPrn:Say(nLi- 10, 500, AllTrim(SM0->M0_NOMECOM), oFnt3)
	oPrn:Say(nLi- 10,2150, "Pag. "+ StrZero(nPag,3), oFnt)
	oPrn:Say(nLi+ 60, 500, "End.:", oFnt)                 
	oPrn:Say(nLi+ 60, 620, AllTrim(SM0->M0_ENDCOB)+" - "+AllTrim(SM0->M0_BAIRCOB), oFnt)
	oPrn:Say(nLi+110, 500, "Mun.:", oFnt)                 
	oPrn:Say(nLi+110, 620, AllTrim(SM0->M0_CIDCOB)+"/"+AllTrim(SM0->M0_ESTCOB), oFnt)
	oPrn:Say(nLi+110,1500, "CEP:", oFnt)                 
	oPrn:Say(nLi+110,1600, Transform(AllTrim(SM0->M0_CEPCOB),"@r 99999-999"), oFnt)
	oPrn:Say(nLi+160, 500, "Tel.:", oFnt)                 
	oPrn:Say(nLi+160, 620, AllTrim(Str(fisGetTel( SM0->M0_TEL)[2],3))+" "+AllTrim(str(fisGetTel( SM0->M0_TEL)[3],15)), oFnt)
	oPrn:Say(nLi+210, 500, "CNPJ:", oFnt)
	oPrn:Say(nLi+210, 620, Transform(SM0->M0_CGC,"@r 99.999.999/9999-99"), oFnt)
	oPrn:Say(nLi+210,1500, "Inscr. Est.:", oFnt)
	oPrn:Say(nLi+210,1680, AllTrim(SM0->M0_INSC), oFnt)
	//oPrn:Say(nLi+40, 100, FisGetTel(SM0->M0_TEL), oFnt)
	
	nLi+=280
	
	oPrn:Box(nLi    ,  40,nLi+100, 2350)
	oPrn:Say(nLi+ 30,  50,"Orçamento: ", oFnt3)
	oPrn:Say(nLi+ 30, 400,VS1->VS1_NUMORC, oFnt3)
	oPrn:Say(nLi+ 30,1900,"Data: "+ DTOC(Date()), oFnt3)
	
	nLi+=100
	
	oPrn:Box(nLi    ,  40,nLi+180, 2350)
	oPrn:Say(nLi+ 30,  50,"Cliente:", oFnt)
	oPrn:Say(nLi+ 30, 170,AllTrim(SA1->A1_COD)+"/"+AllTrim(SA1->A1_LOJA)+"  -   "+AllTrim(SA1->A1_NOME), oFnt)
	oPrn:Say(nLi+ 80,  50,"End.:", oFnt)
	oPrn:Say(nLi+ 80, 170,AllTrim(SA1->A1_END)+"  -  "+AllTrim(SA1->A1_BAIRRO), oFnt)
	oPrn:Say(nLi+ 80,1300,"Cidade:", oFnt)                                  
	oPrn:Say(nLi+ 80,1420,AllTrim(SA1->A1_MUN)+"/"+SA1->A1_EST, oFnt)
	oPrn:Say(nLi+ 80,2045,"CEP:", oFnt)
	oPrn:Say(nLi+ 80,2135,Transform(AllTrim(SA1->A1_CEP),"@r 99999-999"), oFnt)
	oPrn:Say(nLi+130,  50,Iif(SA1->A1_PESSOA = "F", "CPF:", "CNPJ:"), oFnt)
	oPrn:Say(nLi+130, 170,Transform(SA1->A1_CGC,"@R 99.999.999/9999-99"), oFnt)
	oPrn:Say(nLi+130,1300,Iif(SA1->A1_PESSOA = "F", "", "Inscr. Est.:"), oFnt)
	oPrn:Say(nLi+130,1480,Iif(SA1->A1_PESSOA = "F", "", AllTrim(SA1->A1_INSCR)), oFnt)
	
	nLi+=180
	      
	If VS1->VS1_TIPORC == "2"	//-1=Orcamento Pecas;2=Orcamento Oficina;3=Transferência
		If VV1->VV1_COMVEI = "0"
			cCombus := "GASOLINA"
		ElseIf VV1->VV1_COMVEI == "1"
			cCombus := "ALCOOL"
		ElseIf VV1->VV1_COMVEI == "2"
			cCombus := "DIESEL"
		ElseIf VV1->VV1_COMVEI == "3"
			cCombus := "GAS NATURAL"
		ElseIf VV1->VV1_COMVEI == "4"
			cCombus := "GASOLINA/ALCOOL"
		ElseIf VV1->VV1_COMVEI == "9"
			cCombus := "SEM COMBUSTIVEL"
		Else
			cCombus := Space(15)
		EndIf                                                                                
		                      
		oPrn:Box(nLi    ,  40,nLi+130, 2350)
		oPrn:Say(nLi+ 30,  50,"Chassi: " + left(VV1->VV1_CHASSI,17), oFnt)
		oPrn:Say(nLi+ 30, 850,"Frota: " + AllTrim(VV1->VV1_CODFRO), oFnt)
		oPrn:Say(nLi+ 30,1250,"Cor: " + left(VVC->VVC_DESCRI,13), oFnt)
		oPrn:Say(nLi+ 30,1700,"Comb.: " + cCombus, oFnt)
		
		oPrn:Say(nLi+ 80,  50,"Modelo: " + left(AllTrim(VV1->VV1_MODVEI)+"-"+VV2->VV2_DESMOD+space(38),38), oFnt)
		oPrn:Say(nLi+ 80,1250,"Fab/Mod: " + left(VV1->VV1_FABMOD,4)+"/"+right(VV1->VV1_FABMOD,4), oFnt)
		oPrn:Say(nLi+ 80,1700,"Km: " + str(nUltKil,10), oFnt)
		nLi+=130
	EndIf	  		    
	
	oPrn:Box(nLi   ,  40,nLi+100, 2350)
	oPrn:Say(nLi+30,  50,"Vendedor: ", oFnt2)
	oPrn:Say(nLi+30, 250,AllTrim(SA3->A3_NOME), oFnt) 
	oPrn:Say(nLi+30,0900,"Status da Reserva: ", oFnt2)
	oPrn:Say(nLi+30,1200,cStaRes, oFnt)	
	oPrn:Say(nLi+30,1600,"Validade do Orçamento:", oFnt2)
	oPrn:Say(nLi+30,2050,dtoc(VS1->VS1_DATVAL), oFnt)
	
	nLi+=100
	
	If cTipo == "2"
		nLi+=20
		xCabSer()
	Else
		xCabPec()
	EndIf
Return

//***************************************************************************************************************************
Static Function xRoda()
	Local aObs    	:= {}
	Local x 		:= Len(aLista)
	Local x2		:= 0
/*
	Local nPos    	:= 0
	Local cObserv 	:= ""

	cKeyAce 		:= VS1->VS1_OBSMEM + [001]

	DbSelectArea("SYP")
	DbSetOrder(1)
	FG_SEEK("SYP","cKeyAce",1,.f.)
	do while xFilial("SYP")+VS1->VS1_OBSMEM == SYP->YP_FILIAL+SYP->YP_CHAVE .and. !eof()
	   nPos := AT("\13\10",SYP->YP_TEXTO)
	   if nPos > 0
	      nPos-=1
	   Else
	      nPos := Len(SYP->YP_TEXTO)
	   EndIf
	   cObserv := Substr(SYP->YP_TEXTO,1,nPos)
	   aadd(aObs, cObserv)
	   DbSkip()
	enddo
*/
	///////////////////////////////////////////////////////////////////////////
	// Tratamento para que saiam os dados da observação do VS1
	///////////////////////////////////////////////////////////////////////////
	cTxtCompl := ""
	cTxtCompl += U_tvGetMemo(VS1->VS1_OBSMEM,TamSx3("VS1_OBSERV")[1],.T.,.T.)

	//- Quebra o texto em linhas num array
	If !Empty(cTxtCompl)
		aObs := U_tvConvMemo(cTxtCompl,100)
	EndIf
//----
	if len(aObs) > 0
		oPrn:Box(nLi+ 20,  30, nLi+30+(50*len(aObs)), 2350)
		For x2 := 1 to len(aObs)
			if x2 = 1 
				nLi+=30
				oPrn:Say(nLi,  50,"Obs.: ",oFnt5)
				oPrn:Say(nLi, 150, AllTrim(aObs[x2]),oFnt)
			else
				nLi+=50
				oPrn:Say(nLi, 150, AllTrim(aObs[x2]),oFnt)
			EndIf		
		Next x2                                             
		nLi+=50
	endif 
	
	If nLi == 1 .OR. nLi > 3100  // Trata Cabeçalho e Rodapé
		oPrn:Endpage()
		nLi := 100
		oPrn:StartPage()
		nPag++
		xCabec(aLista[x,1]) 
		nLi += 280
	EndIf                  
	
	oPrn:Box(nLi+ 20,  30, nLi+230, 2350)
	oPrn:Say(nLi+ 30, 385,"(=) Total + Frete",oFnt5)
	oPrn:Say(nLi+ 30, 615,"(-) Descontos",oFnt5)
	oPrn:Say(nLi+ 30, 815,"(+) ICMS ST",oFnt5)
	oPrn:Say(nLi+ 30, 1000,"(+) IPI",oFnt5)
	oPrn:Say(nLi+ 30, 1150,"() ICMS",oFnt5)
	oPrn:Say(nLi+ 30, 1300,"(+) Desp. Acess.",oFnt5)
	oPrn:Say(nLi+ 30,1550,"(=) Total Geral",oFnt5)
	
	oPrn:Say(nLi+ 80,  50,"Total Peças",oFnt5)

	If	mv_par03 == 2
		oPrn:say(nLi+ 80, 400, Transform(nTotPec+nTotDesP,"@E 999,999,999.99"), oFnt)            	 
		oPrn:say(nLi+ 80, 600, Transform(nTotDesP,"@E 999,999,999.99"), oFnt)
	Else
		//nTotPec := nTotPec+nTotDesP
		oPrn:say(nLi+ 80, 400, Transform(nTotPec,"@E 999,999,999.99"), oFnt)            	 
		oPrn:say(nLi+ 80, 600, Transform(0,"@E 999,999,999.99"), oFnt)
	EndIf

	oPrn:say(nLi+ 80,  800, Transform(nTotIcmST,"@E 999,999,999.99"), oFnt)          	 
	oPrn:say(nLi+ 80, 970, Transform(nTotIPI,"@E 999,999,999.99"), oFnt)          	 
	oPrn:say(nLi+ 80, 1100, Transform(nTotICMS,"@E 999,999,999.99"), oFnt)          	 
	oPrn:say(nLi+ 80, 1300, Transform(nTotDESACE,"@E 999,999,999.99"), oFnt) 
	oPrn:say(nLi+ 80, 1550, Transform(nTotPec+nTotIcmST+nTotDESACE+nTotIPI,"@E 999,999,999.99"), oFnt) 	
	
	If VS1->VS1_TIPORC <> '2'	//-1=Orcamento Pecas;2=Orcamento Oficina;3=Transferência
		oPrn:Say(nLi+130,  50,"Frete",oFnt5)
		oPrn:say(nLi+130, 400, Transform(nValFre,"@E 999,999,999.99"), oFnt)            	 
		oPrn:say(nLi+130, 600, Transform(0,"@E 999,999,999.99"), oFnt)
		oPrn:say(nLi+130, 800, Transform(0,"@E 999,999,999.99"), oFnt)            	 
		oPrn:say(nLi+130, 970, Transform(0,"@E 999,999,999.99"), oFnt)            	 
		oPrn:say(nLi+130, 1100, Transform(0,"@E 999,999,999.99"), oFnt)            	 
		oPrn:say(nLi+130, 1300, Transform(0,"@E 999,999,999.99"), oFnt) 
		oPrn:say(nLi+130, 1550, Transform(nValFre,"@E 999,999,999.99"), oFnt) 			
		oPrn:Say(nLi+130, 1900,"Cond. de Pagto.",oFnt5)                                      
		
		oPrn:Say(nLi+180,  50,"Total do Orçamento",oFnt5)

		If	mv_par03 == 2
			oPrn:say(nLi+180, 400, Transform(nTotPec+nTotDesP+nValFre,"@E 999,999,999.99"), oFnt)            	 
			oPrn:say(nLi+180, 600, Transform(nTotDesP,"@E 999,999,999.99"), oFnt)    
		Else
			//nTotPec := nTotPec-nTotDesP
			oPrn:say(nLi+180, 400, Transform(nTotPec+nTotDesP+nValFre,"@E 999,999,999.99"), oFnt)            	 
			oPrn:say(nLi+180, 600, Transform(0,"@E 999,999,999.99"), oFnt)    
		EndIf

		oPrn:say(nLi+180,  800, Transform(nTotIcmST,"@E 999,999,999.99"), oFnt)  
		oPrn:say(nLi+180, 970, Transform(nTotIPI,"@E 999,999,999.99"), oFnt)  
		oPrn:say(nLi+180, 1100, Transform(nTotICMS,"@E 999,999,999.99"), oFnt)  
		oPrn:say(nLi+180, 1300, Transform(nTotDESACE,"@E 999,999,999.99"), oFnt)          	 
		oPrn:say(nLi+180, 1550, Transform(nTotPec+nTotIcmST+nValFre+nTotDESACE+nTotIPI,"@E 999,999,999.99"), oFnt) 	       
		If !empty(VS1->VS1_FORPAG)     	 
			oPrn:Say(nLi+180,1900,AllTrim(VS1->VS1_FORPAG) + " - " + AllTrim(SE4->E4_DESCRI),oFnt)
		EndIf
	Else	

		oPrn:Say(nLi+130,  50,"Total Serviços",oFnt5)

		If	mv_par03 == 2
			oPrn:say(nLi+130, 400, Transform(nTotSer+nTotDesS,"@E 999,999,999.99"), oFnt)            	 
			oPrn:say(nLi+130, 600, Transform(nTotDesS,"@E 999,999,999.99"), oFnt)
		Else
			nTotSer := nTotSer-nTotDesS
			oPrn:say(nLi+130, 400, Transform(nTotSer+nValFre,"@E 999,999,999.99"), oFnt)            	 
			oPrn:say(nLi+130, 600, Transform(0,"@E 999,999,999.99"), oFnt)
		EndIf

		oPrn:say(nLi+130, 800, Transform(0,"@E 999,999,999.99"), oFnt)             	 
		oPrn:say(nLi+130,1000, Transform(nTotSer,"@E 999,999,999.99"), oFnt)            	 
		oPrn:Say(nLi+130,1900,"Cond. de Pagto.",oFnt5)
		
		oPrn:Say(nLi+180,  50,"Total do Orçamento",oFnt5)

		If mv_par03 == 2
			oPrn:say(nLi+180, 400, Transform(nTotPec+nTotSer+nTotDesP+nTotDesS+nValFre,"@E 999,999,999.99"), oFnt)            	 
			oPrn:say(nLi+180, 600, Transform(nTotDesP+nTotDesS,"@E 999,999,999.99"), oFnt)
		Else					
			oPrn:say(nLi+180, 400, Transform(nTotPec+nTotSer+nValFre,"@E 999,999,999.99"), oFnt)            	 
			oPrn:say(nLi+180, 600, Transform(0,"@E 999,999,999.99"), oFnt)
		EndIf

		oPrn:say(nLi+180, 800, Transform(nTotIcmST,"@E 999,999,999.99"), oFnt)           	 
		oPrn:say(nLi+180,1000, Transform(nTotPec+nTotSer+nTotIcmST+nValFre,"@E 999,999,999.99"), oFnt)       
		if !empty(VS1->VS1_FORPAG)     	 
			oPrn:Say(nLi+180,1900,AllTrim(VS1->VS1_FORPAG) + " - " + AllTrim(SE4->E4_DESCRI),oFnt)
		endif
	EndIf 	
	nLi += 230
	
	If nLi == 1 .OR. nLi > 3100  // Trata Cabeçalho e Rodapé
		oPrn:Endpage()
		nLi := 100
		oPrn:StartPage()
		nPag++ 
		If x > len(aLista)
	   		xCabec()
	   	Else
	   		xCabec(aLista[x,1])
	   	EndIf 
		nLi += 280
	EndIf
	
	//If mv_par02 == 2 //1 - Orcamento Simples / 2 - Orcamento Completo                 
	
		oPrn:Say(nLi+050,050,"A/- - " + AllTrim(Str(nA_)) + " | ",oFnt5)
		oPrn:Say(nLi+050,200,"P/A - " + AllTrim(Str(nPG)) + " | ",oFnt5)
		oPrn:Say(nLi+050,350,"P/N - " + AllTrim(Str(nPN)) + " | ",oFnt5) 
		oPrn:Say(nLi+050,500,"N/A - " + AllTrim(Str(nNG)) + " | ",oFnt5)
		oPrn:Say(nLi+050,650,"N/P - " + AllTrim(Str(nNP)) + " | ",oFnt5)	
		oPrn:Say(nLi+050,800,"N/N - " + AllTrim(Str(nNN)),oFnt5)
	
	//EndIf
	oPrn:Say(nLi+100,850,"Autorizo(amos) o faturamento deste Orçamento",oFnt5)
	oPrn:Say(nLi+250,250,"Carimbo",oFnt5)
	oPrn:Say(nLi+250,850,"Local: _____________________________, Data: _____/_____/_____",oFnt5)
	
	If VS1->VS1_TIPORC == '2'	//-1=Orcamento Pecas;2=Orcamento Oficina;3=Transferência
		oPrn:Say(nLi+390,100, "__________________________________________________",oFnt5)
		oPrn:Say(nLi+430,250,"Supervisor de Serviços",oFnt5)
		oPrn:Say(nLi+390,1200,"__________________________________________________",oFnt5)
		oPrn:Say(nLi+430,1350,"Assinatura do Cliente",oFnt5)
	Else
		oPrn:Say(nLi+390,100, "__________________________________________________",oFnt5)
		oPrn:Say(nLi+430,250,"Assinatura do Cliente",oFnt5)	    
	EndIf
	
	oPrn:Say(nLi+600,100,"ESTE ORÇAMENTO NÃO TEM VALOR FISCAL - PREÇOS VÁLIDOS POR 7 DIAS A PARTIR DA DATA DO ORÇAMENTO.",oFnt6)
Return

/*/{Protheus.doc} fnOpcResum
Chama tela pra imprimir opçao Normal ou com Orçamento Resumido
@type function
@version P12
@author Ademar Fernandes Jr.
@since 31/07/2025
@param lOpcResum, logical, Opcão de impressão
@param lOpcYellow, logical, Opcão de impressão
@return variant, Retorna a opção de impressão
/*/
Static function fnOpcResum(lOpcResum,lOpcYellow)
	local aLjArea   := Lj7GetArea({"SA1","VV1","VV2","VVC"})
	local aParamBox := {}
	local cTitle	:= OemToAnsi("Tipo de impressão de Orçamento -")
	local aRetBox   := {}
	local bOk       := {|| (.T.)}
	local aButtons  := {}
	local lCentered := .T.
	local nPosX     := 0
	local nPosY     := 0
	local cLoad     := "" //--ProcName(1)
	local lCanSave  := .F.
	local lUserSave := .F.

	local nRisco	:= 1
	// local aRisco	:= StrTokArr("1-Orçamento Normal;2-Orçamento Resumido",";")
	local aRisco	:= StrTokArr("1-Orçamento Normal;2-Orçamento Resumido;3-Linha Amarela ( Wirtgen JD )",";")
	local aSvPar	:= {MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05,MV_PAR06,MV_PAR07,MV_PAR08,MV_PAR09}

	// Parametros da função Parambox()
	// -------------------------------
	// 1 - < aParametros > - Vetor com as configurações
	// 2 - < cTitle >      - Título da janela
	// 3 - < aRet >        - Vetor passador por referencia que contém o retorno dos parâmetros
	// 4 - < bOk >         - Code block para validar o botão Ok
	// 5 - < aButtons >    - Vetor com mais botões além dos botões de Ok e Cancel
	// 6 - < lCentered >   - Centralizar a janela
	// 7 - < nPosX >       - Se não centralizar janela coordenada X para início
	// 8 - < nPosY >       - Se não centralizar janela coordenada Y para início
	// 9 - < oDlgWizard >  - Utiliza o objeto da janela ativa
	//10 - < cLoad >       - Nome do perfil se caso for carregar
	//11 - < lCanSave >    - Salvar os dados informados nos parâmetros por perfil
	//12 - < lUserSave >   - Configuração por usuário

	// Tipo 1 -> MsGet()
	//			[2]-Descricao
	//          [3]-String contendo o inicializador do campo
	//          [4]-String contendo a Picture do campo
	//          [5]-String contendo a validacao
	//          [6]-Consulta F3
	//          [7]-String contendo a validacao When
	//          [8]-Tamanho do MsGet
	//          [9]-Flag .T./.F. Parametro Obrigatorio ?
	// Tipo 2 -> Combo
	//           [2]-Descricao
	//           [3]-Numerico contendo a opcao inicial do combo
	//           [4]-Array contendo as opcoes do Combo
	//           [5]-Tamanho do Combo
	//           [6]-Validacao
	//           [7]-Flag .T./.F. Parametro Obrigatorio ?
	aadd(aParamBox, {2 , "Tipo de Relatório "    , nRisco, aRisco, 100, "", .T.})

    //-ParamBox(aParametros,cTitle,aRet,bOk,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave)
    if ParamBox(aParamBox,cTitle,aRetBox,bOk,aButtons,lCentered,nPosX,nPosY,,cLoad,lCanSave,lUserSave)

		if Valtype(aRetBox[1]) == "N"
			if aRetBox[1] == 2
				lOpcResum := .T.
			elseif aRetBox[1] == 3
				lOpcYellow := .T.
			endif
		elseif Valtype(aRetBox[1]) <> "N"
			if Substr(aRetBox[1],1,1) == "2"
				lOpcResum := .T.
			elseif Substr(aRetBox[1],1,1) == "3"
				lOpcYellow := .T.
			endif
		endif

    endIf
	
	MV_PAR01 := aSvPar[01]
	MV_PAR02 := aSvPar[02]
	MV_PAR03 := aSvPar[03]
	MV_PAR04 := aSvPar[04]
	MV_PAR05 := aSvPar[05]
	MV_PAR06 := aSvPar[06]
	MV_PAR07 := aSvPar[07]
	MV_PAR08 := aSvPar[08]
	MV_PAR09 := aSvPar[09]
	Lj7RestArea(aLjArea)
Return
