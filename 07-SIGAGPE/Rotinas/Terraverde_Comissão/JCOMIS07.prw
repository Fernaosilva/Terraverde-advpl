#include "Totvs.ch"
#include "Topconn.ch"

User Function JCOMIS07()

Local cPerg := "AFI440" // "JCOMIS07"
Local NREGPROC := 0 

IF Pergunte(cPerg,.T.)

	Processa({|| fa440DelE3(3,@nRegProc)},"Excluindo Comiss”es n„o pagas") 
	
	MsgRun("Aguarde, Atualizando vendedores  ...",, { || ProcVendedor()} )

	MsgRun("Aguarde, Calculando das comissoes ...",, { || ProcStatus()} )

Endif

Return


Static Function ProcStatus()

Local cCmdSql 	:= "" 
Local nX		:= 0 
Local nTitBax   := 0 
Local __nTmMoed	:= TamSX3("CTO_MOEDA")[1]
Local __nTmComi	:= TamSX3("E3_COMIS")[2]

cCmdSql += " SELECT *, R_E_C_N_O_ as REGSE1 FROM  " +RetSqlName("SE1") 
cCmdSql += " WHERE "
cCmdSql += "     E1_BAIXA >= '"+DtoS(MV_PAR01)+"' " 
cCmdSql += " AND E1_BAIXA <= '"+DtoS(MV_PAR02)+"' "
cCmdSql += " AND D_E_L_E_T_ = ' ' "
cCmdSql += " AND  E1_TIPO  <> 'RA' AND  E1_TIPO    NOT LIKE '%-%' " 
cCmdSql += " AND E1_VEND1 >= '"+MV_PAR03+"' "
cCmdSql += " AND E1_VEND1 <= '"+MV_PAR04+"' "
cCmdSql += " AND E1_SALDO = 0  "
//cCmdSql += " AND E1_NUM IN ( '000021337','000021673','000021674','000021929')
cCmdSql += " ORDER BY E1_FILIAL, E1_NUM, E1_PREFIXO "

If Select("TITBAX") <> 0
	dbSelectArea("TITBAX")
	dbCloseArea()
Endif


TcQuery cCmdSql Alias "TITBAX" New
Count to nTotReg

If nTotReg = 0 
	MsGinfo("Não existe registros a serem processados para os paramentros selecionados.","INFO")
	Return()
Endif

dbSelectArea("TITBAX")
dbGoTop()

While !EOF()
	nRegse1 := TITBAX->REGSE1
	ddtBx   := dDataBase

	// verificar se este titulo tem alguma outro qualquer com saldo positivo
	// Pois a data da baixa não esta confiavel.

	cCmdSql := " SELECT Count(*) AS TOTREG FROM " + RetSqlName("SE1")+ CRLF 
	cCmdSql += " WHERE "                                 + CRLF 
	cCmdSql += "     E1_NUM     = '"+TITBAX->E1_NUM+"'"     + CRLF 
	cCmdSql += " AND E1_FILIAL  = '"+TITBAX->E1_FILIAL+"'"  + CRLF 
	cCmdSql += " AND E1_TIPO  <> 'RA' AND  E1_TIPO    NOT LIKE '%-%' " 
	cCmdSql += " AND E1_SALDO <> 0 " + CRLF
	cCmdSql += " AND D_E_L_E_T_ = ' ' "                  + CRLF 
	
	If Select("TTIABER") <> 0
		dbSelectArea("TTIABER")
		dbCloseArea()
	Endif

	nQtdTitAber := 0 
	TcQuery cCmdSql Alias "TTIABER" New
	nQtdTitAber := TTIABER->TOTREG
	
	dbSelectArea("TTIABER")
	dbCloseArea()

	If nQtdTitAber <> 0 
		dbSelectArea("TITBAX")
		dbSkip()
		Loop
	Endif

	// Verificamos se tem  titulos deste processo em aberto dentro desta data.
	cCmdSql := " SELECT Count(*) AS TOTREG FROM " + RetSqlName("SE1")+ CRLF 
	cCmdSql += " WHERE "                                 + CRLF 
	cCmdSql += "     E1_NUM     = '"+TITBAX->E1_NUM+"'"     + CRLF 
	cCmdSql += " AND E1_FILIAL  = '"+TITBAX->E1_FILIAL+"'"  + CRLF 
	cCmdSql += " AND E1_TIPO  <> 'RA' AND  E1_TIPO    NOT LIKE '%-%' " 
	cCmdSql += " AND ( E1_BAIXA   = ' ' or  E1_BAIXA   > '"+DtoS(mv_par02)+"') " + CRLF
	cCmdSql += " AND D_E_L_E_T_ = ' ' "                  + CRLF 
	
	
	If Select("TTIABER") <> 0
		dbSelectArea("TTIABER")
		dbCloseArea()
	Endif

	TcQuery cCmdSql Alias "TTIABER" New
	nQtdTitAber := TTIABER->TOTREG
	
	dbSelectArea("TTIABER")
	dbCloseArea()

	If nQtdTitAber = 0 
		// devermos processar a comissão
		cCmdZZ1 := " SELECT ZZ1.R_E_C_N_O_ as NREGZZ1 FROM "+RetSqlName("ZZ1") + " ZZ1 " 
		cCmdZZ1 += " WHERE " 
		cCmdZZ1 += "     ZZ1.ZZ1_FILIAL = '"+TITBAX->E1_FILIAL+"'"  + CRLF 
		cCmdZZ1 += " AND ZZ1.ZZ1_DOC    = '"+TITBAX->E1_NUM+"'"     + CRLF 
		cCmdZZ1 += " AND ZZ1.D_E_L_E_T_ = ' ' "

		
		If Select("ZZ1REG") <> 0
			dbSelectArea("ZZ1REG")
			dbCloseArea()
		Endif

		TcQuery cCmdZZ1 Alias "ZZ1REG" New
		nRecZZ1 := ZZ1REG->NREGZZ1
		
		dbSelectArea("ZZ1REG")
		dbCloseArea()

		// BUSCAR A ULTIMA DATA DE BAIXA 
		ccmdSe5 := " SELECT * FROM " + RetSqlname("SE5")
		ccmdSe5 += " WHERE "
		ccmdSe5 += "     E5_FILIAL  = '"+TITBAX->E1_FILIAL+"' "
		ccmdSe5 += " AND E5_NUMERO  = '"+TITBAX->E1_NUM+"'"
		ccmdSe5 += " AND D_E_L_E_T_ = ' ' "
		ccmdSe5 += " ORDER BY E5_DATA DESC "

		If Select("SE5DTB") <> 0
			dbSelectArea("SE5DTB")
			dbCloseArea()
		Endif

		TcQuery ccmdSe5 Alias "SE5DTB" New
		Count to nTitBax
		dbGoTop()
		If nTitBax<> 0 
			ddtBx := Stod(SE5DTB->E5_DATA)
		Endif
		dbSelectArea("SE5DTB")
		dbCloseArea()

		dbSelectArea("ZZ1")
		dbGoTo(nRecZZ1)

		
		cCmdVSql := " SELECT * FROM " + RetSqlName("SE1")+ CRLF 
		cCmdVSql += " WHERE "                                 + CRLF 
		cCmdVSql += "     E1_NUM     = '"+TITBAX->E1_NUM+"'"     + CRLF 
		cCmdVSql += " AND E1_FILIAL  = '"+TITBAX->E1_FILIAL+"'"  + CRLF 
		cCmdVSql += " AND E1_CLIENTE = '"+TITBAX->E1_CLIENTE+"'" + CRLF 
		cCmdVSql += " AND E1_LOJA    = '"+TITBAX->E1_LOJA+"' "   + CRLF 
		cCmdVSql += " AND E1_TIPO  <> 'RA' AND  E1_TIPO    NOT LIKE '%-%' " 
		cCmdVSql += " AND D_E_L_E_T_ = ' ' "                  + CRLF 
		
	
		If Select("REGVEN") <> 0
			dbSelectArea("REGVEN")
			dbCloseArea()
		Endif

		TcQuery cCmdVSql Alias "REGVEN" New
		nRegse1 := REGVEN->R_E_C_N_O_
		
		dbSelectArea("REGVEN")
		dbCloseArea()


		dbSelectArea("SE1")
		dbGoTo(nRegse1)
		
		For nX := 1 to 5

			If !empty(&("SE1->E1_VEND" + cValToChar(nX)))

				cCodVend   := &("SE1->E1_VEND" + cValToChar(nX))
				nBaseComis := ZZ1->ZZ1_BASE
				nPerComis  := &("ZZ1->ZZ1_PERCV" + cValToChar(nX))

				// Adiciona os valores para calculo da comissao
				// aadd(aComissao,{cCodVend,nBaseComis,0,nBaseComis,0,nBaseComis,nPerComis,0,0,0,0,0,0})
				dbSelectARea("SE3")
				dbSetOrder(3) // E3_FILIAL+E3_VEND+E3_CODCLI+E3_LOJA+E3_PREFIXO+E3_NUM+E3_PARCELA+E3_TIPO+E3_SEQ
				IF !dbSeek(SE1->E1_FILIAL + cCodVend +SE1->E1_CLIENTE + SE1->E1_LOJA +SE1->E1_PREFIXO + SE1->E1_NUM)
		
					nValComis := (( nBaseComis/100 ) * nPerComis )
					If nValComis <> 0 
						RecLock("SE3",.T.)
						SE3->E3_FILIAL  := SE1->E1_FILIAL
						SE3->E3_VEND    := cCodVend
						SE3->E3_NUM     := SE1->E1_NUM
						SE3->E3_EMISSAO := Iif(nTitBax <> 0 , ddtBx, SE1->E1_BAIXA )
						SE3->E3_PREFIXO := SE1->E1_PREFIXO
						SE3->E3_TIPO    := SE1->E1_TIPO
						SE3->E3_BAIEMI  := "B"
						SE3->E3_ORIGEM  := "R"
						SE3->E3_PEDIDO  := SE1->E1_PEDIDO
						SE3->E3_SEQ     := "01"
						SE3->E3_CCUSTO  := SE1->E1_CCUSTO
						SE3->E3_MOEDA 	:= StrZero(SE1->E1_MOEDA,__nTmMoed)
						SE3->E3_BASE    := nBaseComis
						SE3->E3_COMIS   := Round(nValComis,__nTmComi )
						SE3->E3_PORC    := nPerComis
						SE3->E3_SERIE   := SE1->E1_SERIE
						SE3->E3_CODCLI  := SE1->E1_CLIENTE
						SE3->E3_LOJA    := SE1->E1_LOJA
						SE3->E3_PARCELA := TITBAX->E1_PARCELA
						
						// Posicionamento no vendedore
						dbSelectArea("SA3")
						dbSetOrder(1)
						dbSeek(SE1->E1_FILIAL + cCodVend)


						If Empty( SA3->A3_DIA )
							dVencto := SE1->E1_EMISSAO
						Else
							dVencto := Ctod( strzero(SA3->A3_DIA,2)+"/"+;
								strzero(month(SE1->E1_EMISSAO),2)+"/"+;
								strzero( year(SE1->E1_EMISSAO),4),"ddmmyy")
							nDia := SA3->A3_DIA

							While empty( dVencto)
								nDia -= 1
								dVencto := CtoD(strzero(nDia,2)+"/"+;
									strzero(month(SE1->E1_EMISSAO),2)+"/"+;
									strzero( year(SE1->E1_EMISSAO),4),"ddmmyy")
							EndDo
						EndIf

							if SA3->A3_DDD == "F" .or. dVencto < SE1->E1_EMISSAO		//Fora o mes
								nDia := SA3->A3_DIA
								nMes := month(dVencto) + 1
								nAno := year (dVencto)
								If nMes == 13
									nMes := 01
									nAno := nAno + 1
								Endif
								nDia	  := strzero(nDia,2)
								nMes	  := strzero(nMes,2)
								nAno	  := substr(lTrim(str(nAno)),3,2)
								dVencto := CtoD(nDia+"/"+nMes+"/"+nAno,"ddmmyy")
							Else
								nDia	  := strzero(day(dVencto),2)
								nMes	  := strzero(month(dVencto),2)
								nAno	  := substr(lTrim(str(Year(dVencto))),3,2)
							Endif

							While empty( dVencto)
								nDia := if(Valtype(nDia)=="C",Val(nDia),nDia)
								nDia -= 1
								dVencto := CtoD(strzero(nDia,2)+"/"+nMes+"/"+nAno,"ddmmyy")
								if !empty( dVencto )
									if dVencto < SE1->E1_EMISSAO
										dVencto += 2
									EndIf
								EndIf
							Enddo

							SE3->E3_VENCTO  := dVencto


							SE3->E3_DESPES := ZZ1->ZZ1_DESPES   
							SE3->E3_INCENT := ZZ1->ZZ1_INCENT   
							SE3->E3_ASSODI := ZZ1->ZZ1_ASSODI   
							SE3->E3_CUSTO  := ZZ1->ZZ1_CUSTO   

							// dia 20 02 2023
							SE3->E3_TFRETE := ZZ1->ZZ1_TFRETE       // Total do frete
							SE3->E3_TRBRUT := ZZ1->ZZ1_TRBRUT      // Total Resultado Bruto
							SE3->E3_TCFIXO := ZZ1->ZZ1_TCFIXO       // Total Custo Fixo
							SE3->E3_TCESTO := ZZ1->ZZ1_TCESTO       // TotalCuto do Estoque

							SE3->E3_TRLIQU := ZZ1->ZZ1_TRLIQU        // Total Receita Liquida
							SE3->E3_TTOTAL := ZZ1->ZZ1_TTOTAL        // Total Dos Itens 
								
							// Nota de ISS Incentivo
							SE3->E3_TCOFIS := ZZ1->ZZ1_TCOFIS       // Total Cofins
							SE3->E3_TPISIS := ZZ1->ZZ1_TPISIS       // Total PIS
							SE3->E3_TIRRIS := ZZ1->ZZ1_TIRRIS        // TotalIR
							SE3->E3_TISSIS := ZZ1->ZZ1_TISSIS       // Total ISS


							SE3->E3_TIMPOS := ZZ1->ZZ1_TIMPOS        // Total do Impostos 
							SE3->E3_TICMVE := ZZ1->ZZ1_TICMVE       // Total da Venda  ICMS
							SE3->E3_TPISVE := ZZ1->ZZ1_TPISVE       // Total da Venda PIS
							SE3->E3_TCOFVE := ZZ1->ZZ1_TCOFVE      // Total da Venda Cofins
							SE3->E3_TISSVE := ZZ1->ZZ1_TISSVE      // Total da Venda iss
							SE3->E3_TIRRVE := ZZ1->ZZ1_TIRRVE       // Total da Venda IR
							SE3->E3_DTUCOM := ZZ1->ZZ1_DTUCOM 		  // Data da Ultima Compra
						
							If FieldPos("E3_BASECOM") > 0 
								SE3->E3_BASECOM := ZZ1->ZZ1_BASECO // Valor do historico de comissões
							Endif
						MsUnlock()
					Endif
				Endif
			EndIf
		Next	
	Endif

	dbSelectArea("TITBAX")
	dbSkip()

Enddo




//-------------------------------------------------------------------
/*{Protheus.doc} Fa440DelE3
Zera as comissoes do periodo antes do recálculo

@param nTipo Indica o tipo de comissão as ser excluida
		1 = Baixa e Emissão
		2 = Emissão
		3 = Baixa

@author  Eduardo Riera
@version 12.1.27
@since   19/12/1997
*/
//-------------------------------------------------------------------
Static Function Fa440DelE3(nTipo,nRegProc)

Local aArea			:= GetArea()
Local cChave    	:= ""
Local nValComis		:= ""
Local lDelFisico	:= GetNewPar('MV_FIN440D',.T.)
Local cQuery		:= ""
Local nX			:= 0
Local nMax			:= 0
Local nMin			:= 0
Local nTamE2_NATUR	:= TamSX3("E2_NATUREZ")[1]
Local cNatCom		:= PADR(&(GetNewPar("MV_NATCOM",'"COMISSOES"')),nTamE2_NATUR)
Local cFunName 		:= Alltrim(FUNNAME())

DEFAULT nRegProc	:= 0

If Empty(cNatCom)
	cNatCom := "COMISSOES"
EndIf

dbSelectArea("SE3")
dbSetOrder(1)
ProcRegua(RecCount())

//Atualiza saldo das naturezas antes de deletar as comissoes
cQuery := "SELECT E3_VENCTO, SUM(E3_COMIS) VLRCOMIS, E3_EMISSAO, E3_MOEDA "
cQuery += "FROM "+RetSqlName("SE3")+" SE3 "
cQuery += " WHERE 1 = 1 " // SE3.E3_FILIAL   = '"+xFilial("SE3")+"'"
cQuery += 	" AND SE3.E3_EMISSAO BETWEEN '"+ Dtos(mv_par01) +"' AND '"+ Dtos(mv_par02) +"' "
cQuery += 	" AND SE3.E3_VEND BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
cQuery += 	" AND SE3.E3_DATA     = '"+Dtos(Ctod(""))+"'"
cQuery += 	" AND SE3.E3_ORIGEM NOT IN(' ','L') AND "
Do Case
	Case nTipo == 2
		cQuery += "SE3.E3_BAIEMI='E' AND "
	Case nTipo == 3
		cQuery += "SE3.E3_BAIEMI='B' AND "
EndCase

cQuery += 	" SE3.D_E_L_E_T_ = ' '"
cQuery += 	" GROUP BY E3_VENCTO , E3_EMISSAO, E3_MOEDA "
	
cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBNAT")

TCSetField('TRBNAT','E3_VENCTO','D',8,0)
TCSetField('TRBNAT','VLRCOMIS' ,'N',17,2)
TCSetField('TRBNAT','E3_EMISSAO','D',8,0)

dbSelectArea("TRBNAT")

//Ajuste do Saldo de Naturezas
If cNatCom != NIL

	While TRBNAT->(!Eof())
		// Tratamento de outras moedas no controle de saldos do fluxo de caixa por natureza
		If VAL(TRBNAT->E3_MOEDA) > 1
			nValComis := NOROUND(XMOEDA(TRBNAT->VLRCOMIS,01,VAL(TRBNAT->E3_MOEDA),TRBNAT->E3_EMISSAO))
		Else
			nValComis := TRBNAT->VLRCOMIS
		EndIf

		//Atualizo o valor atual para o saldo da natureza
		//Diminuo pois as comissoes serao recalculadas e somadas posteriormente
		AtuSldNat(cNatCom, TRBNAT->E3_VENCTO, TRBNAT->E3_MOEDA, "2", "P",nValComis, TRBNAT->VLRCOMIS,"-",,cFunName,"SE3",0)
		dbSkip()
	Enddo
Endif

dbSelectArea("TRBNAT")
dbCloseArea()
dbSelectArea("SE3")

If lDelFisico

	// Verifica qual eh o maior e o menor Recno que satisfaca a selecao
	cQuery := "SELECT MIN(R_E_C_N_O_) MINRECNO,"
	cQuery += 		" MAX(R_E_C_N_O_) MAXRECNO "
	cQuery += 	" FROM "+RetSqlName("SE3")+" SE3 "
	cQuery += " WHERE 1 = 1 " // SE3.E3_FILIAL   = '"+xFilial("SE3")+"'"
	cQuery += 	" AND SE3.E3_EMISSAO BETWEEN '"+ Dtos(mv_par01) +"' AND '"+ Dtos(mv_par02) +"' "
	cQuery += 	" AND SE3.E3_VEND BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
	cQuery += 	" AND SE3.E3_DATA     = '"+Dtos(Ctod(""))+"'"
	cQuery += 	" AND SE3.E3_ORIGEM NOT IN(' ','L') AND "
	Do Case
		Case nTipo == 2
			cQuery += "SE3.E3_BAIEMI='E' AND "
		Case nTipo == 3
			cQuery += "SE3.E3_BAIEMI='B' AND "
	EndCase

	cQuery += 	" SE3.D_E_L_E_T_ = ' '"
	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"FA440DELE3")
	
	nMax := FA440DELE3->MAXRECNO
	nMin := FA440DELE3->MINRECNO
	dbCloseArea()

	dbSelectArea("SE3")
	//--------------------------------------
	// Monta a string de execucao no banco
	//--------------------------------------
	cQuery := "DELETE FROM "+ RetSqlName("SE3") +" "
	cQuery += " WHERE 1 = 1 " // E3_FILIAL = '"+ xFilial("SE3" )+"'"
	cQuery += 	" AND E3_EMISSAO BETWEEN '"+ Dtos(mv_par01) +"' AND '"+ Dtos(mv_par02) +"'"
	cQuery += 	" AND E3_VEND BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery += 	" AND E3_DATA = '"+ Dtos(Ctod("")) +"'"
	cQuery += 	" AND E3_ORIGEM NOT IN(' ','L') AND "
	Do Case
		Case nTipo == 2
			cQuery += "E3_BAIEMI='E' AND "
		Case nTipo == 3
			cQuery += "E3_BAIEMI='B' AND "
	EndCase
	cQuery += 	" D_E_L_E_T_ = ' ' AND "
	
	//----------------------------------------------------------------------------------------------------------
	//³Executa a string de execucao no banco para os proximos 1024 registro a fim de nao estourar o log do SGBD
	//----------------------------------------------------------------------------------------------------------
	For nX := nMin To nMax STEP 1024
		cChave := "R_E_C_N_O_>="+Str(nX,10,0)+" AND R_E_C_N_O_<="+Str(nX+1023,10,0)+""
		TcSqlExec(cQuery+cChave)
	Next nX

	// A tabela eh fechada para restaurar o buffer da aplicacao
	dbSelectArea("SE3")
	dbCloseArea()
	ChkFile("SE3",.F.)

Else

	//Deleção dos registros - NORMAL
	cQuery := "SELECT R_E_C_N_O_ RECSE3 "
	cQuery += "FROM "+RetSqlName("SE3")+" SE3 "
	cQuery += " WHERE 1 = 1 " // SE3.E3_FILIAL   = '"+xFilial("SE3")+"'"
	cQuery += 	" AND SE3.E3_EMISSAO BETWEEN '"+ Dtos(mv_par01) +"' AND '"+ Dtos(mv_par02) +"' "
	cQuery += 	" AND SE3.E3_VEND BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
	cQuery += 	" AND SE3.E3_DATA     = '"+Dtos(Ctod(""))+"'"
	cQuery += 	" AND SE3.E3_ORIGEM NOT IN(' ','L') AND "
	Do Case
		Case nTipo == 2
			cQuery += "SE3.E3_BAIEMI='E' AND "
		Case nTipo == 3
			cQuery += "SE3.E3_BAIEMI='B' AND "
	EndCase
	cQuery += 	" SE3.D_E_L_E_T_ = ' '"
		
	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"FA440DELE3")

	dbSelectArea("FA440DELE3")

	FA440DELE3->(dbGoTop())

	While FA440DELE3->(!Eof())
		SE3->(DBGoto(FA440DELE3->RECSE3))

		nRegProc += 1

		RecLock("SE3")
		dbDelete()
		MsUnlock()

		FA440DELE3->(dbSkip())
		IncProc()
	Enddo
	IF Select("FA440DELE3") > 0
		dbSelectArea("FA440DELE3")
		FA440DELE3->(dbCloseArea())
	EndIf
	dbSelectArea("SE3")
Endif

RestArea(aArea)
Return(.T.)




Static Function ProcVendedor()

Local cCmdTIV := ""
Local cCmdTIO := "" 
Local nTotTitV:= 0 
// Local nX	  := 0 

cCmdTIV := " SELECT *, R_E_C_N_O_ as REGSE1 FROM  " +RetSqlName("SE1") 
cCmdTIV += " WHERE "
cCmdTIV += "     1=1 " 
cCmdTIV += " AND E1_BAIXA >= ' ' " 
// cCmdTIV += " AND E1_BAIXA <= '"+DtoS(MV_PAR02)+"' "
cCmdTIV += " AND D_E_L_E_T_ = ' ' "
cCmdTIV += " AND E1_PREFIXO IN ('DUP','NEG') "
cCmdTIV += " AND E1_VEND1 = ' ' "
// cCmdTIV += " AND E1_NUM = '000021336' " 
cCmdTIV += " ORDER BY E1_FILIAL, E1_NUM, E1_PREFIXO "

If Select("TITVEN") <> 0
	dbSelectArea("TITVEN")
	dbCloseArea()
Endif


TcQuery cCmdTIV Alias "TITVEN" New
Count to nTotTitV
dbGoTop()

While !EOF()

	cCmdTIO := " SELECT *, R_E_C_N_O_ as REGSE1 FROM  " +RetSqlName("SE1") 
	cCmdTIO += " WHERE "
	cCmdTIO += "     E1_FILIAL  = '"+TITVEN->E1_FILIAL+"'"
	cCmdTIO += " AND E1_NUM     = '"+TITVEN->E1_NUM+"'"
	cCmdTIO += " AND E1_CLIENTE = '"+TITVEN->E1_CLIENTE+"'"
	cCmdTIO += " AND E1_LOJA    = '"+TITVEN->E1_LOJA+"'"
	cCmdTIO += " AND D_E_L_E_T_ = ' ' "

	cCmdTIO += " ORDER BY E1_EMISSAO "

	If Select("TITORI") <> 0
		dbSelectArea("TITORI")
		dbCloseArea()
	Endif


	TcQuery cCmdTIO Alias "TITORI" New
	Count to nTotTIO
	dbGoTop()
	If nTotTIO > 0 
		cVend1 := TITORI->E1_VEND1
		cVend2 := TITORI->E1_VEND2
		cVend3 := TITORI->E1_VEND3
		cVend4 := TITORI->E1_VEND4
		cVend5 := TITORI->E1_VEND5

		cComi1 := TITORI->E1_COMIS1
		cComi2 := TITORI->E1_COMIS2
		cComi3 := TITORI->E1_COMIS3
		cComi4 := TITORI->E1_COMIS4
		cComi5 := TITORI->E1_COMIS5

		If !Empty(Alltrim(cVend1))

			dbSelectARea("SE1")
			dbGoTo(TITVEN->REGSE1)

			RecLock("SE1",.F.)
			If Empty(Alltrim(SE1->E1_VEND1))
				SE1->E1_VEND1 := cVend1
			Endif
			If Empty(Alltrim(SE1->E1_VEND2))
				SE1->E1_VEND2 := cVend2
			Endif
			If Empty(Alltrim(SE1->E1_VEND3))
				SE1->E1_VEND3 := cVend3
			Endif
			If Empty(Alltrim(SE1->E1_VEND4))
				SE1->E1_VEND4 := cVend4
			Endif
			If Empty(Alltrim(SE1->E1_VEND5))
				SE1->E1_VEND5 := cVend5
			Endif

			If Empty(Alltrim(SE1->E1_COMIS1))
				SE1->E1_COMIS1 := cComi1
			Endif
			
			If Empty(Alltrim(SE1->E1_COMIS2))
				SE1->E1_COMIS2 := cComi2
			Endif
			
			If Empty(Alltrim(SE1->E1_COMIS3))
				SE1->E1_COMIS3 := cComi3
			Endif
			
			If Empty(Alltrim(SE1->E1_COMIS4))
				SE1->E1_COMIS4 := cComi4
			Endif
			
			If Empty(Alltrim(SE1->E1_COMIS5))
				SE1->E1_COMIS5 := cComi5
			Endif
			MsUnlock()
		Endif
	Endif

	DbSelectArea("TITVEN")
	dbSkip()
Enddo

Return()


	/*
	// Retorna a quanidade de titulos para este processo 
	cCmdSql += " SELECT * FROM  " +RetSqlName("SE1") 
	cCmdSql += " WHERE "
	cCmdSql += "     E1_FILIAL  = '"+TITBAX->E1_FILIAL+'"'
	cCmdSql += " AND E1_NUM  =  '"+TITBAX->E1_NUM +'"'
	cCmdSql += " AND D_E_L_E_T_ = ' ' "
	cCmdSql += " AND E1_TIPO  <> 'RA' AND  E1_TIPO    NOT LIKE '%-%' " 
	cCmdSql += " AND E1_VEND1 = '"+TITBAX->E1_VEND1+"' "
	cCmdSql += " ORDER BY E1_FILIAL, E1_NUM, E1_PREFIXO "

	If Select("QRYTOTPAR") <> 0
		dbSelectArea("QRYTOTPAR")
		dbCloseArea()
	Endif

	TcQuery cCmdSql Alias "QRYTOTPAR" New 
	Count to nTotParcTit

	dbSelectArea("QRYTOTPAR")
	dbCloseArea()
	*/
