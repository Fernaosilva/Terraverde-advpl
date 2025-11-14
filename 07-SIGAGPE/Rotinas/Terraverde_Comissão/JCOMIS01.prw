#include "Totvs.ch"
#include "TopConn.ch"

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³JCOMIS01   ³ Autor ³TOTVS                 ³ Rev. ³08.02.2017 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Funcao para calculo da Base e Porcentagem de comissao        ³±±
±±³          ³Terra Verde Jonh Deere. Funcao chamada atraves dos pontos de ³±±
±±³          ³entrada M460FIM e VM011DNF                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Faturamento                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/

User Function JCOMIS01(cNF,cSerie,lAtuDesp) // JCOMIS01

 	Local nCusto      	:= 0        // Custo estoque
	Local nTxCustP    	:= GetMv("TV_TXCUSTP",.F.,4)   // Taxa Custo Fixo PEÇAS
	Local nTxCustV    	:= GetMv("TV_TXCUSTV",.F.,8)   // Taxa Custo Fixo VEICULOS
	Local nTXCustC      := SuperGetMV("TV_TXCUSTC",,10)// Taxa Custo Fixo CONSORCIO
	Local cGrpJD		:= SuperGetMV("TV_EQUIJDE",, "VEIC")
	Local cGrpCon		:= SuperGetMV("TV_CONSORC",, "CCON")
	Local cRetForTV		:= SuperGetMV("TV_RETFORT",, "282594")
	Local nQtdVend      := SuperGetMV("TV_QTDVEN",, 1)
	Local nVlrComBasic  := SuperGetMV("TV_VLRBASC",, 500)
	Local nVlrComAMSBa  := SuperGetMV("TV_VLRBAMS",, 300)
	Local nTxCusto    	:= 0
	Local nTxEstk     	:= 0.0400   // Taxa Estoque
	Local nCustoEstk  	:= 0        // Custo Estoque
	Local nImpostos   	:= 0        // Valor impostos
	Local nTotalItem  	:= 0
	Local nPerComis   	:= 0
	Local aPerComis   	:= {0,0,0,0,0}
	Local nBaseTotCom 	:= 0
	Local nPerProd    	:= 0
	Local aValComTot  	:= {0,0,0,0,0}
	Local aXPerComis  	:= {0,0,0,0,0}
	Local nValComis   	:= 0
	Local nParcelas   	:= 0
	Local nInceVeic  	:= 0
	Local nDespVeic   	:= 0
	Local cSeqParc    	:= ""
	Local lComiss     	:= .F.
	Local nTxAssodeer 	:= SuperGetMV("TV_TXASSOE",,  0.001 ) // 0.001
	Local nValAssodeer	:= 0
	Local nCustoTotal 	:= 0
	Local nTotTit     	:= 0
	Local nx          	:= 0
	Local nDespTotal  	:= 0
	Local nInceTotal  	:= 0
	Local nAssoTotal  	:= 0
	Local aArea       	:= GetArea()
	Local aAreaSF2    	:= SF2->(GetArea())
	Local aAreaSD2    	:= SD2->(GetArea())
	Local aAreaSE1    	:= SE1->(GetArea())
	Local aAreaSB1    	:= SB1->(GetArea())
	Local aAreaSA3    	:= SA3->(GetArea())
	Local aAreaSF4    	:= SF4->(GetArea())
	Local cAliasVVD		:= ""
	Local dDtUcom		:= ctod("  /  /  ")

	Local nVlrPis 	:=  0
	Local nVlrCof 	:=  0
	Local nVlrISS 	:=  0
	Local nVlrir  	:=  0

	Local nFreteTotal  :=  0 // Total do frete
	Local nRBrutoTotal :=  0 // Total Resultado Bruto
	Local nCFixoTotal  :=  0 // Total Custo Fixo
	Local nCTotalEstk  :=  0 // TotalCuto do Estoque

	Local nRLiqTotal   :=  0 // Total Receita Liquida
    Local nItemTotal   :=  0 // Total Dos Itens 
			  
	// Nota de ISS Incentivo
	Local nVlrTCofISS  :=  0 // Total Cofins
	Local nVlrTPisISS  :=  0 // Total PIS
	Local nVlrTirISS   :=  0 // TotalIR
	Local nVlrTISSISS  :=  0 // Total ISS
	

	Local nImptTotal  :=  0 // Total do Impostos 
	Local nVLrICMVTot  :=  0 // Total da Venda  ICMS
	Local nVLrPISVTot  :=  0 // Total da Venda PIS
	Local nVLrCOFVTot  :=  0// Total da Venda Cofins
	Local nVLrISSVTot  :=  0// Total da Venda iss
	Local nVLrIRVTot   :=  0// Total da Venda IR

	Local nBaseCHist   := 0 // total do historico de Comissoes

	SB1->(dbSetOrder(1))
	SA3->(dbSetOrder(1))
	SF2->(dbSetOrder(1))
	SD2->(dbSetOrder(3))
	//cNF	   := Iif(Alltrim(Funname()) $ "MATA460/MATA461/MATA410",SF2->F2_DOC, SE1->E1_NUM )
	//cSerie := Iif(Alltrim(Funname()) $ "MATA460/MATA461/MATA410",SF2->F2_SERIE, SE1->E1_PREFIXO)
	
	cNF	   := SF2->F2_DOC
	cSerie := SF2->F2_SERIE

	SF2->(dbSeek(xFilial("SF2")+cNF+cSerie))

	If SD2->(dbSeek(xFilial("SD2")+cNF+cSerie))
		
		cDiretorio := "c:\temp\"
		cFile := xFilial("SD2") +"_"+ cNF +"_"+ cSerie+ ".csv" // "PAU000001.XML"
		cFile := cDiretorio+cFile
		nHdl  := FCreate(cFile)

		cDiretorio := "\Comissoes\"
		If !ExistDir(cDiretorio)
			If MakeDir(cDiretorio) == -1
				MSGSTOP("Não foi possível criar o diretório " + cDiretorio+"sku.",FunName())
				Return Nil
			EndIf
		EndIf

		cFile2 := "\Comissoes\"+xFilial("SD2") +"_"+ cNF +"_"+ cSerie+ ".csv"
		nHdl2  := FCreate(cFile2)

		cCabec := "Filial;NOTA;SERIE;PRODUTO;DATA ULT. COMPRA;TOTAL VENDA;CUSTO;IR;IMPOSTOS;ASSODEERE;INCENTIVOS;FRETE;COFINS_INCENTIVO;PIS_INCENTIVO;IR_INCENTIVO;ISS_INCENTIVO;FLAT BANCARIO;ACESSORIOS;RECEITA LIQUIDA;CUSTO FIXO;RESULTADO BRUTO;CUSTO ESTOQUE;BASE COMISSAO;VALOR DA COMISSAO" + CHR(13)+CHR(10)

		fWrite(nHdl,cCabec)
		fWrite(nHdl2,cCabec)


		While SD2->(!Eof()) .and. xFilial("SD2")+cNF+cSerie == SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE

			// Caso o TES nao gere duplicata devera desconsiderar o item da NF
			If Posicione("SF4",1,xFilial("SF4")+SD2->D2_TES,"F4_DUPLIC") == "N"
				SD2->(dbSkip())
				Loop
			EndIf

			cMens := xFilial("SD2") + ";" +cNF+";"+cSerie +";"+ SD2->D2_COD

			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1") + SD2->D2_COD )

			nTxCusto := Iif(SB1->B1_GRUPO $ cGrpJD,nTxCustV/100, Iif( SB1->B1_GRUPO $  cGrpCon , nTXCustC / 100,nTxCustP/100))
			
			nPerProd     := 0  
			dDtUcom      := SB1->B1_UCOM                                                                                                 // Percentual de comissao do produto
			nTotalItem   := SD2->D2_TOTAL                                                                                       // Pega o Total do Item NF
			nCusto       := iif(SB1->B1_GRUPO $ cGrpJD,Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_UPRC"),SD2->D2_CUSTO1)  // Custo do Produto
			If nCusto = 0 
				// Deveremos pegar o valor da ultima nota fiscal de entrada
				cCmdSql := " SELECT D1_VUNIT, D1_EMISSAO , D1_CUSTO , D1_QUANT "
				cCmdSql += " FROM " + RetSqlName("SD1") 
				cCmdSql += " WHERE "
				cCmdSql += "     D1_COD    = '"+SD2->D2_COD+"' "
				cCmdSql += " AND D1_FORNECE <> '"+cRetForTV+"' "
				cCmdSql += " AND D1_TIPO = 'N' "
				cCmdSql += " AND D_E_L_E_T_ = ' ' "
				cCmdSql += "  ORDER BY D1_EMISSAO DESC" 

				If Select("QRYCUSTO") <> 0
					dbSelectArea("QRYCUSTO")
					dbCloseArea()
				Endif

				TcQuery cCmdSql Alias "QRYCUSTO" New 

				nCusto 	:= QRYCUSTO->D1_VUNIT * SD2->D2_QUANT
				dDtUcom := StoD(QRYCUSTO->D1_EMISSAO)

				dbSelectArea("QRYCUSTO")
				dbCloseArea()
				
			Endif

			cMens += ";" + Dtoc(dDtUcom) 
			cMens += ";" + AllTrim(Transform(nTotalItem,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nCusto,"@E 999,999,999.99"))


			If SB1->B1_GRUPO $  cGrpCon
				nVlrIr := (( SD2->D2_BASEIRR / 100 ) * SD2->D2_ALQIRRF )
			Endif

			cMens += ";" + AllTrim(Transform(nVlrIr,"@E 999,999,999.99"))

			IF SB1->B1_GRUPO $ cGrpJD .or. SB1->B1_GRUPO $  cGrpCon 
				nImpostos    := SD2->D2_VALICM + SD2->D2_VALIMP5 + SD2->D2_VALIMP6 + SD2->D2_VALISS  + SD2->D2_VALIRRF // Soma os impostos do item da NF
			Else
				// Este tratamento é para retirar os valores de Pis e Cofins , pois algumas notas 
				// principalmente as de peças o sistema tem muito PIS e Cofins e a redução destes valores 
				// Estava reduzindo fortemente o valor de base de Comissão.
				// Dia 04-04-2023 - Analista Alexandre J. Conselvan - Totvs IP Campinas 
				nImpostos    := SD2->D2_VALICM + SD2->D2_VALISS  + SD2->D2_VALIRRF // Soma os impostos do item da NF
			Endif

			cMens += ";" + AllTrim(Transform(nImpostos,"@E 999,999,999.99"))

			dbSelectArea("SB1")
			dbSetOrder(1)
			dbSeek(xFilial("SB1") + SD2->D2_COD )
			
			nVlrPis 	:=  0
			nVlrCof 	:=  0
			nVlrISS 	:=  0
			nVlrir  	:=  0
			nInceVeic 	:=  0
			nFlatBanc   := 0 
			nDespVeic   := 0 


			// Caso seja venda de Equipamento, devera buscar Incentivos e Despesas da tabela VVD (DMS)
			// Somente irá considerar incentivos e taxa assodeere para empresas que iniciam com 01 (Concessionária)
			IF SB1->B1_GRUPO $ cGrpJD
				If	SubStr(SD2->D2_FILIAL,1,2) == "01" //Somente quando for a Concessionária
					nValAssodeer := nCusto * nTxAssodeer // Valor Assodieere
				EndIf


				//----------------------------------------------------------------------------------------------------------------
				//Charlles Reis - 18/12/2020
				//Alteração na regra para buscar os incentivos, pois anteriormente utilizava-se o xFilial da VVD
				//que quando exclusiva não retorna os incentivos do chassi quando foi cadastrado em outra filial.
				//----------------------------------------------------------------------------------------------------------------
				cAliasVVD := GetNextAlias()
				BeginSQL Alias cAliasVVD
					SELECT * FROM %TABLE:VVD% VVD
					WHERE
						VVD_CHAINT = %exp:SubStr(SD2->D2_COD,6,6)%
					AND SUBSTRING(VVD_FILIAL,1,2) = %exp:SubStr(SD2->D2_FILIAL,1,2)%
					AND VVD.D_E_L_E_T_=''
				EndSQL

				While	!(cAliasVVD)->(EOF())

					// Trata o incentivo/despesas JD
					If 	(cAliasVVD)->VVD_CODIGO == padr("INCENTIVO JD",20)
						nDespVeic += (cAliasVVD)->VVD_VALOR * 0.1375
						nInceVeic += (cAliasVVD)->VVD_VALOR
						// Despesas do Veiculo
					ElseIf	(cAliasVVD)->VVD_TIPOPE == "0"
						nDespVeic += (cAliasVVD)->VVD_VALOR
						// Incentivos do Veiculo
					ElseIf	(cAliasVVD)->VVD_TIPOPE == "1"
						nInceVeic += (cAliasVVD)->VVD_VALOR
					EndIf

					(cAliasVVD)->(dbSkip())

				EndDo

				(cAliasVVD)->(dbCloseArea())


			EndIf

			// tratamento para os valores de frete
			// Hoje eles tem uma tratativa que esta na tabela VVR , que é o frete por familia 
			// ou grupo .
			nFrete  := 0
			cMarca  := " "
			cModulo := " "
			cChassi := " "
			lAMS    := .F.

			dbSelectArea("SC6")
			If dbSeek(xFilial("SC6") + SD2->D2_PEDIDO + SD2->D2_ITEM)
				// Pegamos o Chassis
				dbSelectArea("VV1")
				dbSetOrder(2)
				If dbSeek(xFilial("VV1") +  SC6->C6_CHASSI )
					// VV1_CODMAR + VV1_MODVEI
					dbSelectArea("VV2")
					dbSetOrder(1)
					If dbSeek(xFilial("VV2") + VV1->VV1_CODMAR + VV1->VV1_MODVEI)
						// Tratamento para o processo de produto do Tipo AMS
						lAMS := Iif(Alltrim(VV2->VV2_GRUMOD) = "AMS",.T.,.F.)
						
						dbSelectArea("VVR")
						dbSetOrder(2)
						If dbSeek(xFilial("VVR") + VV2->VV2_CODMAR + VV2->VV2_GRUMOD)
							nFrete := VVR->VVR_XVLFRE
						Endif
					Endif	

					// Se achei o VV1 para este chassi, deveremos pesquisar e ver se tem valores na 
					// VVR - lançamento de despesas e acessorios para este CHASSI.
					cAliasVVD := GetNextAlias()
					BeginSQL Alias cAliasVVD
						SELECT * FROM %TABLE:VVD% VVD
						WHERE
							VVD_CHAINT = %exp:VV1->VV1_CHAINT%
						AND SUBSTRING(VVD_FILIAL,1,2) = %exp:SubStr(SD2->D2_FILIAL,1,2)%
						AND VVD.D_E_L_E_T_=''
					EndSQL

					While	!(cAliasVVD)->(EOF())

						// Trata o incentivo/despesas JD
						If 	(cAliasVVD)->VVD_CODIGO == padr("INCENTIVO JD",20)
							nDespVeic += (cAliasVVD)->VVD_VALOR * 0.1375
							nInceVeic += (cAliasVVD)->VVD_VALOR
							// Despesas do Veiculo
						ElseIf	(cAliasVVD)->VVD_TIPOPE == "0"
							If (cAliasVVD)->VVD_CODIGO $ 'FLAT'
								nFlatBanc += (cAliasVVD)->VVD_VALOR
							Else
								nDespVeic += (cAliasVVD)->VVD_VALOR
							Endif
							// Incentivos do Veiculo
						ElseIf	(cAliasVVD)->VVD_TIPOPE == "1"
							nInceVeic += (cAliasVVD)->VVD_VALOR
						EndIf

						(cAliasVVD)->(dbSkip())

					EndDo

					(cAliasVVD)->(dbCloseArea())
				Endif
			Endif

			If !Empty(Alltrim(SC6->C6_CHASSI))
				cCmdInc := " SELECT VQ0.*, VQ1.*  " 
				cCmdInc += " FROM " + RetSqlName("VQ0") + " AS VQ0 "
				cCmdInc += " INNER JOIN  " + RetSqlName("VQ1") + " VQ1 ON "
				cCmdInc += "     VQ1.VQ1_FILIAL = '"+xFilial("VQ1")+"' "
				cCmdInc += " AND VQ1.VQ1_CODIGO = VQ0.VQ0_CODIGO "
				cCmdInc += " AND VQ1.D_E_L_E_T_ = ' ' "
				cCmdInc += " WHERE"
				cCmdInc += "     VQ0.VQ0_FILIAL = '"+xFilial("VQ0")+"' "
				cCmdInc += " AND VQ0.VQ0_CHASSI = '"+Alltrim(SC6->C6_CHASSI)+"' "
				cCmdInc += " AND VQ0.D_E_L_E_T_ = ' ' "

				If Select("QRYINC") <> 0
					dbSelectArea("QRYINC")
					dbCloseArea()
				Endif

				TcQuery cCmdInc Alias "QRYINC" New 

				While !EOF()
					nInceVeic 	+= QRYINC->VQ1_VLRLIQ 
					
					aAreaXSd2    	:= SD2->(GetArea())

					// Deveremos ir na nota fiscal de saida da Terra Verde para pegar os percentuais de Impostos
					dbSelectArea("SD2")
					dbSetOrder(3)
					If dbSeek(QRYINC->VQ1_FILNFI + QRYINC->VQ1_NUMNFI +QRYINC->VQ1_SERNFI )
						nPerPis := SD2->D2_ALQIMP5
						nPerCof := SD2->D2_ALQIMP6
						nPerISS := SD2->D2_ALIQISS
						nPerIR  := 1.5

						nVlrPis +=  ( QRYINC->VQ1_VLRLIQ / 100 ) * nPerPis
						nVlrCof +=  ( QRYINC->VQ1_VLRLIQ / 100 ) * nPerCof
						nVlrISS +=  ( QRYINC->VQ1_VLRLIQ / 100 ) * nPerISS
						nVlrir  +=  ( QRYINC->VQ1_VLRLIQ / 100 ) * nPerIR
					Endif

					RestArea(aAreaXSd2)

					dbSelectArea("QRYINC")
					dbSkip()
				Enddo

				dbSelectArea("QRYINC")
				dbCloseArea()

			Endif
			cMens += ";" + AllTrim(Transform(nValAssodeer,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nInceVeic,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nFrete,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nVlrCof,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nVlrPis,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nVlrir,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nVlrISS,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nFlatBanc,"@E 999,999,999.99"))
			cMens += ";" + AllTrim(Transform(nDespVeic,"@E 999,999,999.99"))
			



			nReceitaLiq  := nTotalItem + nInceVeic - nImpostos  - nFrete  - nVlrCof  - nVlrPis - nVlrir -  nVlrISS - nFlatBanc                // Calcula a Receita Operacional Liquida

			cMens += ";" + AllTrim(Transform(nReceitaLiq,"@E 999,999,999.99"))

			nCustoFixo   := nTotalItem * nTxCusto   
			cMens += ";" + AllTrim(Transform(nCustoFixo,"@E 999,999,999.99"))
            
			//Calcula o valor Custo Fixo
			nResultBruto := nReceitaLiq - nCusto - nDespVeic - nValAssodeer  - nFrete            // Calcula o Resultado Bruto
			cMens += ";" + AllTrim(Transform(nResultBruto,"@E 999,999,999.99"))

			nCustoEstk   := 0 // Zera o Custo de Estoque

			If SB1->B1_GRUPO $ cGrpJD
				nCustoEstk := nCusto * (((SD2->D2_EMISSAO - dDtUcom) * nTxEstk) / 100) // Calcula o custo de estoque
			EndIf
			cMens += ";" + AllTrim(Transform(nCustoEstk,"@E 999,999,999.99"))

			nBaseComis := nResultBruto - nCustoFixo - nCustoEstk  // Calcula a Base Comissao
			cMens += ";" + AllTrim(Transform(nBaseComis,"@E 999,999,999.99"))// +CHR(13)+chr(10)
			
			nBaseCHist += nBaseComis

			// fWrite(nHdl,cMens)
			// fWrite(nHdl2,cMens)
			lGrvTxt := .F.
			// Calcula os valores de comissao para cada vendedor
			for nx:=1 to nQtdVend // 5
				If !empty(&("SF2->F2_VEND" + cValToChar(nx)))

					// Implementado a validação da data de admissão do funcionario
					// se a data de admissão for menor que 90 dias não processa comissão para o mesmo
					SA3->(dbSeek(xFilial("SA3")+&("SF2->F2_VEND" + cValToChar(nx)))) 
					cNumRa := SA3->A3_NUMRA

					dbSelectARea("SRA")
					dbSetOrder(1)
					If dbSeek(xFilial("SRA") + cNumRa)

						If Dtos(dDatabase) >= Dtos( SRA->RA_ADMISSA+90 )
							nPerComis := 0

							If !SB1->B1_GRUPO $  cGrpCon
								// Devera considerar a comissao do produto caso o B1_COMIS esteja informado
								//If 	SB1->(dbSeek(xFilial("SB1")+SD2->D2_COD)) .and. SB1->B1_COMIS > 0 .and. nx == 1
								//	nPerComis := SB1->B1_COMIS
								//Else
								If	SA3->(dbSeek(xFilial("SA3")+&("SF2->F2_VEND" + cValToChar(nx)))) .and. SA3->A3_COMIS > 0
									nPerComis := SA3->A3_COMIS
								EndIf

								// Novo tratamento para o conceito do cliente ( Varejo / Atacado ).
								// Para esta condição temos um novo campo no cadastro do cliente que indica se 
								// este cliente é Atacado ou varejo.
								// A1_ZZATACA = Se igual a "S" , indica que esta cliente é Atacado e deve ser 
								// Utilizado a taxa de comissão diferenciada para o respectivo vendedor.
								// Este campo de percentual é por um campo personalizado
								// A3_ZZCOMIS.
								
								IF !SB1->B1_GRUPO $ cGrpJD .or. !SB1->B1_GRUPO $  cGrpCon 
									dbSelectArea("SA1")
									dbSetOrder(1)
									If dbSeek(xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA)
										//Verifica se o campo existe
										If FieldPos("A1_ZZATACA") > 0
											If SA1->A1_ZZATACA = "S"
												// Deveremos pegar o percentual do atacado para este vendedor
												If FieldPos("A3_ZZCOMIS") > 0
													IF SA3->A3_ZZCOMIS <> 0 
														nPerComis := SA3->A3_ZZCOMIS
													Endif
												Endif
											Endif
										Endif
									Endif
								Endif


								// Validação da certificação.
								If SA3->A3_ZZCERT = 'S'
								// Vendedor certificado

									nValComis      := nBaseComis * (nPerComis / 100)  // Calcula valor de comissao por item para o vendedor
									aValComTot[nx] += nValComis                       // Soma o Valor Total de Comissoes para o vendedor
									aXPerComis[nx] := nPerComis
								Else
									// Vendedor sem certificação
									nValComis		:= 500
									nPerComis		:= 100
									aValComTot[nx] += nValComis 
									nBaseComis		:= 500
									aXPerComis[nx] := nPerComis 
								Endif
								
							elseIf SB1->B1_GRUPO $  cGrpCon
								nValComis    := ( nBaseComis / 100 ) * 80
								aValComTot[nx] += nValComis
								aXPerComis[nx] := 80
							Endif							
						Endif
					else
						If !SB1->B1_GRUPO $  cGrpCon

							aAreaXSB1    	:= SB1->(GetArea())
							// Devera considerar a comissao do produto caso o B1_COMIS esteja informado
							//If 	SB1->(dbSeek(xFilial("SA3")+SD2->D2_COD)) .and. SB1->B1_COMIS > 0 .and. nx == 1
							//	nPerComis := SB1->B1_COMIS
							//Else
							If	SA3->(dbSeek(xFilial("SA3")+&("SF2->F2_VEND" + cValToChar(nx)))) .and. SA3->A3_COMIS > 0
								nPerComis := SA3->A3_COMIS
							EndIf


							// Novo tratamento para o conceito do cliente ( Varejo / Atacado ).
							// Para esta condição temos um novo campo no cadastro do cliente que indica se 
							// este cliente é Atacado ou varejo.
							// A1_ZZATACA = Se igual a "S" , indica que esta cliente é Atacado e deve ser 
							// Utilizado a taxa de comissão diferenciada para o respectivo vendedor.
							// Este campo de percentual é por um campo personalizado
							// A3_ZZCOMIS.
							
							IF !SB1->B1_GRUPO $ cGrpJD .or. !SB1->B1_GRUPO $  cGrpCon 
								dbSelectArea("SA1")
								dbSetOrder(1)
								If dbSeek(xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA)
									//Verifica se o campo existe
    								If FieldPos("A1_ZZATACA") > 0
										If SA1->A1_ZZATACA = "S"
											// Deveremos pegar o percentual do atacado para este vendedor
											// If FieldPos("A3_ZZCOMIS") > 0
												IF SA3->A3_ZZCOMIS <> 0 
													nPerComis := SA3->A3_ZZCOMIS
												Endif
											// Endif
										Endif
									Endif
								Endif
							Endif

							RestArea(aAreaXSB1)

							If nPerComis <> 0 
								// Validação da certificação.
								IF SB1->B1_GRUPO $ cGrpJD  .and. !lAMS
									If /* SA3->A3_ZZCERT = 'S' .and.*/    nBaseComis * (nPerComis / 100) >= nVlrComBasic // 500    // nBaseComis >   0 
											// Vendedor certificado

										nValComis      := nBaseComis * (nPerComis / 100)  // Calcula valor de comissao por item para o vendedor
										aValComTot[nx] += nValComis                       // Soma o Valor Total de Comissoes para o vendedor
										aXPerComis[nx] := nPerComis
									Else 
										// Vendedor sem certificação
										nValComis		:= 500
										nPerComis		:= 100
										aValComTot[nx] += nValComis 
										nBaseComis		:= 500 
										aXPerComis[nx] := nPerComis
									Endif
								elseiF lAMS
									iF SA3->A3_ZZCERT = 'S' .AND.  nBaseComis * (nPerComis / 100) >= nVlrComBasic //500 
										nValComis      := nBaseComis * (nPerComis / 100)  // Calcula valor de comissao por item para o vendedor
										aValComTot[nx] += nValComis	
										aXPerComis[nx] := nPerComis	
									ELSE
										// Vendedor sem certificação
										nValComis		:= nVlrComAMSBa // 500
										nPerComis		:= 100
										aValComTot[nx] += nValComis 
										nBaseComis		:= nVlrComAMSBa // 500 
										aXPerComis[nx] := nPerComis
									eNDIF
								else
									nValComis      := nBaseComis * (nPerComis / 100)  // Calcula valor de comissao por item para o vendedor
									aValComTot[nx] += nValComis	
									aXPerComis[nx] := nPerComis	
								Endif
							Endif

						elseIf SB1->B1_GRUPO $  cGrpCon
							nValComis    := ( nBaseComis / 100 ) * 80
							aValComTot[nx] += nValComis 
							aXPerComis[nx] := 80
						Endif							
						cMens += ";" + AllTrim(Transform(nValComis,"@E 999,999,999.99"))+CHR(13)+chr(10)
						fWrite(nHdl,cMens)
						fWrite(nHdl2,cMens)
						lGrvTxt := .T.
					Endif
				Else
					cMens += ";" + AllTrim(Transform(0,"@E 999,999,999.99"))+CHR(13)+chr(10)
					fWrite(nHdl,cMens)
					fWrite(nHdl2,cMens)
					lGrvTxt := .T.	
				EndIf
			next nx

			If !lGrvTxt 
				cMens += ";" + AllTrim(Transform(0,"@E 999,999,999.99"))+CHR(13)+chr(10)
				fWrite(nHdl,cMens)
				fWrite(nHdl2,cMens)
			Endif

			If SB1->B1_GRUPO $ cGrpJD
				nBaseTotCom  += nBaseComis
			Else
				nBaseTotCom  += nBaseComis // IIF(nBaseComis<0,0,nBaseComis)     // Totaliza a Base de Comissao
			Endif

			nDespTotal   += nDespVeic      // Totaliza as Despesas JD
			nInceTotal   += nInceVeic      // Totaliza os Incentivos JD
			nAssoTotal   += nValAssodeer   // Totaliza os valores Assodieere
			nCustoTotal  += nCusto         // Totaliza os Custos dos itens

			nFreteTotal  +=  nFrete // Total do frete
			nRBrutoTotal +=  nResultBruto // Total Resultado Bruto
			nCFixoTotal  +=  nCustoFixo // Total Custo Fixo
			nCTotalEstk  +=  nCustoEstk // TotalCuto do Estoque

			nRLiqTotal   +=  nReceitaLiq // Total Receita Liquida
            nItemTotal   +=  nTotalItem // Total Dos Itens 
			  
			// Nota de ISS Incentivo
			nVlrTCofISS  +=  nVlrCof // Total Cofins
			nVlrTPisISS  +=  nVlrPis // Total PIS
			nVlrTirISS   +=  nVlrir // TotalIR
			nVlrTISSISS  +=  nVlrISS // Total ISS
	

			nImptTotal   +=  nImpostos // Total do Impostos 
			nVLrICMVTot  +=  SD2->D2_VALICM + SD2->D2_ICMSRET // Total da Venda  ICMS
			nVLrPISVTot  +=  SD2->D2_VALIMP5 // Total da Venda PIS
			nVLrCOFVTot  +=  SD2->D2_VALIMP6// Total da Venda Cofins
			nVLrISSVTot  +=  SD2->D2_VALISS// Total da Venda iss
			nVLrIRVTot   +=  SD2->D2_VALIRRF// Total da Venda IR


			SD2->(dbSkip())
		EndDo

		// Verifica se existe valor de comissao para gravacao na tabela ZZ1
		If aValComTot[1]+aValComTot[2]+aValComTot[3]+aValComTot[4]+aValComTot[5] > 0
			lComiss  := .T.
		EndIf

	EndIf

	fClose(nHdl)
	fClose(nHdl2)

	If lComiss 
		// Distribui a porcentagem de comissao
		If lComiss
			for nx:=1 to 5
				aPerComis[nx] :=  aXPerComis[nx] // (aValComTot[nx] / nBaseTotCom) * 100
			next nx
		EndIf

		// Verifica quantas parcelas e valor total gerado no contas a receber
		QtdParcelas(cNF,cSerie,@nParcelas,@nTotTit)

		// Busca a sequencia da parcela na tabela SE1
		SE1->(dbSetOrder(1))
		If SE1->(dbSeek(xFilial("SE1")+SF2->F2_SERIE+SF2->F2_DOC))
			While SE1->(!Eof()) .and. xFilial("SE1")+SF2->F2_SERIE+SF2->F2_DOC == SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM
				If SE1->E1_TIPO $ "NF /DP /FI /TF "
					cSeqParc := alltrim(SE1->E1_PARCELA)
					exit
				EndIf
				SE1->(dbSkip())
			EndDo
		EndIf

		ZZ1->(dbSetOrder(1))

		// Deleta o registro caso ja exista
		If ZZ1->(dbSeek(xFilial("ZZ1")+cNF+cSerie)) // +cSeqParc)) // +nParcelas /*cSeqParc*/))
			RecLock("ZZ1",.F.)
			ZZ1->(dbDelete())
			ZZ1->(MsUnlock())
		EndIf



		RecLock("ZZ1",.T.)
		ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
		ZZ1->ZZ1_DOC    := cNF
		ZZ1->ZZ1_SERIE  := cSerie
		ZZ1->ZZ1_PARCEL := cSeqParc
		ZZ1->ZZ1_BASE 	:= nBaseTotCom
		ZZ1->ZZ1_PERCV1 := aPerComis[1]
		ZZ1->ZZ1_PERCV2 := aPerComis[2]
		ZZ1->ZZ1_PERCV3 := aPerComis[3]
		ZZ1->ZZ1_PERCV4 := aPerComis[4]
		ZZ1->ZZ1_PERCV5 := aPerComis[5]
		ZZ1->ZZ1_DESPES := Iif(nDespTotal=0,SF2->F2_DESPESA,nDespTotal)  // nDespTotal 
		ZZ1->ZZ1_INCENT := nInceTotal 
		ZZ1->ZZ1_ASSODI := nAssoTotal 
		ZZ1->ZZ1_CUSTO  := nCustoTotal
		// dia 20 02 2023
		ZZ1->ZZ1_TFRETE := Iif(nFreteTotal=0,SF2->F2_FRETE,nFreteTotal)  // nFreteTotal     // Total do frete
		ZZ1->ZZ1_TRBRUT := nRBrutoTotal    // Total Resultado Bruto
		ZZ1->ZZ1_TCFIXO := nCFixoTotal     // Total Custo Fixo
		ZZ1->ZZ1_TCESTO := nCTotalEstk     // TotalCuto do Estoque

		ZZ1->ZZ1_TRLIQU := nRLiqTotal      // Total Receita Liquida
		ZZ1->ZZ1_TTOTAL := nItemTotal      // Total Dos Itens 
			
		// Nota de ISS Incentivo
		ZZ1->ZZ1_TCOFIS := nVlrTCofISS     // Total Cofins
		ZZ1->ZZ1_TPISIS := nVlrTPisISS     // Total PIS
		ZZ1->ZZ1_TIRRIS := nVlrTirISS      // TotalIR
		ZZ1->ZZ1_TISSIS := nVlrTISSISS     // Total ISS


		ZZ1->ZZ1_TIMPOS := nImptTotal      // Total do Impostos 
		ZZ1->ZZ1_TICMVE := nVLrICMVTot     // Total da Venda  ICMS
		ZZ1->ZZ1_TPISVE := nVLrPISVTot     // Total da Venda PIS
		ZZ1->ZZ1_TCOFVE := nVLrCOFVTot    // Total da Venda Cofins
		ZZ1->ZZ1_TISSVE := nVLrISSVTot    // Total da Venda iss
		ZZ1->ZZ1_TIRRVE := nVLrIRVTot     // Total da Venda IR
		ZZ1->ZZ1_DTUCOM := dDtUcom		  // Data da Ultima Compra

		If FieldPos("ZZ1_BASECO") > 0 
			ZZ1->ZZ1_BASECO := nBaseCHist // Valor do historico de comissões
		Endif

		ZZ1->(MsUnlock())
	ElseIf SB1->B1_GRUPO $ cGrpJD
			// Deleta o registro caso ja exista
		If ZZ1->(dbSeek(xFilial("ZZ1")+cNF+cSerie)) // +nParcelas /*cSeqParc*/))
			RecLock("ZZ1",.F.)
			ZZ1->(dbDelete())
			ZZ1->(MsUnlock())
		EndIf

		nBaseTotCom := 500
		RecLock("ZZ1",.T.)
		ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
		ZZ1->ZZ1_DOC    := cNF
		ZZ1->ZZ1_SERIE  := cSerie
		ZZ1->ZZ1_BASE 	:= nBaseTotCom
		ZZ1->ZZ1_PERCV1 := 100
		ZZ1->ZZ1_PERCV2 := 0
		ZZ1->ZZ1_PERCV3 := 0
		ZZ1->ZZ1_PERCV4 := 0
		ZZ1->ZZ1_PERCV5 := 0

		ZZ1->ZZ1_DESPES := Iif(nDespTotal=0,SF2->F2_DESPESA,nDespTotal) 
		ZZ1->ZZ1_INCENT := nInceTotal 
		ZZ1->ZZ1_ASSODI := nAssoTotal 
		ZZ1->ZZ1_CUSTO  := nCustoTotal

		// dia 20 02 2023
		ZZ1->ZZ1_TFRETE := Iif(nFreteTotal=0,SF2->F2_FRETE,nFreteTotal)     // Total do frete
		ZZ1->ZZ1_TRBRUT := nRBrutoTotal    // Total Resultado Bruto
		ZZ1->ZZ1_TCFIXO := nCFixoTotal     // Total Custo Fixo
		ZZ1->ZZ1_TCESTO := nCTotalEstk     // TotalCuto do Estoque

		ZZ1->ZZ1_TRLIQU := nRLiqTotal      // Total Receita Liquida
		ZZ1->ZZ1_TTOTAL := nItemTotal      // Total Dos Itens 
			
		// Nota de ISS Incentivo
		ZZ1->ZZ1_TCOFIS := nVlrTCofISS     // Total Cofins
		ZZ1->ZZ1_TPISIS := nVlrTPisISS     // Total PIS
		ZZ1->ZZ1_TIRRIS := nVlrTirISS      // TotalIR
		ZZ1->ZZ1_TISSIS := nVlrTISSISS     // Total ISS


		ZZ1->ZZ1_TIMPOS := nImptTotal      // Total do Impostos 
		ZZ1->ZZ1_TICMVE := nVLrICMVTot     // Total da Venda  ICMS
		ZZ1->ZZ1_TPISVE := nVLrPISVTot     // Total da Venda PIS
		ZZ1->ZZ1_TCOFVE := nVLrCOFVTot    // Total da Venda Cofins
		ZZ1->ZZ1_TISSVE := nVLrISSVTot    // Total da Venda iss
		ZZ1->ZZ1_TIRRVE := nVLrIRVTot     // Total da Venda IR
		ZZ1->ZZ1_DTUCOM := dDtUcom		  // Data da Ultima Compra

		If FieldPos("Z1_BASECOM") > 0 
			ZZ1->Z1_BASECOM := nBaseCHist // Valor do historico de comissões
		Endif


		ZZ1->(MsUnlock())

	
	Endif



	RestArea(aArea)
	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
	RestArea(aAreaSE1)
	RestArea(aAreaSB1)
	RestArea(aAreaSA3)
	RestArea(aAreaSF4)

Return

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³QtdParcelas³ Autor ³TOTVS                 ³ Rev. ³08.02.2017 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Funcao para calcular as quantidades de parcelas geradas no   ³±±
±±³          ³contas a receber                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Faturamento                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Static Function QtdParcelas(cNF,cSerie,nParcelas,nTotTit)

	Local cTipos := SuperGetMv("TV_TPCOMIS",.F.,"")

	If	empty(cTipos)
		cTipos := "('NF','DP','FI','TF')"
	Else
		cTipos := FormatIn(cTipos,";")
	EndIf

	cQuery := "SELECT COUNT(*) PARCELAS, SUM(E1_VALOR) TOTAL "
	cQuery += "FROM "+RetSqlName("SE1")+" SE1 "
	cQuery += "WHERE E1_FILIAL = '"+xFilial("SE1")+"' "
	cQuery += "AND E1_NUM      = '"+cNF+"' "
	cQuery += "AND E1_PREFIXO  = '"+cSerie+"'  "
	cQuery += "AND E1_TIPO IN  " + cTipos + " "
	cQuery += "AND SE1.D_E_L_E_T_!='*' "

	TCQUERY cQuery NEW ALIAS "cAlias"

	nParcelas := cAlias->PARCELAS
	nTotTit   := cAlias->TOTAL

	If select("cAlias") > 0
		cAlias->(dbCloseArea())
	EndIf

Return()

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³CalcBaseComi³ Autor ³TOTVS                ³ Rev. ³08.02.2017 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Funcao para calcular a base de comissao para cada parcela    ³±±
±±³          ³Devido ao processo de venda de equipamentos, foi necessaria  ³±±
±±³          ³a utilizacao dessa funcao.                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Faturamento                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Static Function CalcBaseComi(cNF,cSerie,cSeqParc,nBaseTotCom,nTotTit)

	Local nFator     := 0
	Local nValorBase := 0

	SE1->(dbSetOrder(1))
	If SE1->(dbSeek(xFilial("SE1")+cSerie+cNF+cSeqParc))
		nFator     := nBaseTotCom / nTotTit
		nValorBase := SE1->E1_VALOR * nFator
	EndIf

Return(nValorBase)
