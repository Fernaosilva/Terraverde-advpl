#include "Protheus.ch"
#INCLUDE "TopConn.ch"

/*/{Protheus.doc} PONAPO3
Ponto de entrada no processo de marcação do Ponto eletronico.
Executado nas rotinas PONA040 (Lancamento de Marcacoes) e PONM010 (Leitura e Apontamento das Marcacoes). 
@type function
@author Alexandre Jose Conselvan - IP Campinas
@since 05/01/2024
@version 1.0
@return Nil

@ History
Ajustado por Cristiano Pedroni - 16/03/2024.
/*/

User Function PONAPO3()

	Local aArea       := lj7GetArea({"SPC","SRA","SPF","SPJ"})
	Local lHabilta    := GetNewPar("ZZ_PONAP01",.F.)
	Local cTurno      := SRA->RA_TNOTRAB
	Local cFunc       := SRA->RA_MAT

	Private cEvExtra     := GetNewPar("ZZ_PONAP02","060,064,068,072") // Eventos Hora Extra normal
	Private cEvExNot     := GetNewPar("ZZ_PONAP03","076,080,084,088") // Eventos Hora Extra Noturno
	Private dDtCorte     := GetNewPar("ZZ_PONAP04","20230116")        // Data corte
	Private nHoraNoturno := GetNewPar("ZZ_PONAP05",22.00)             // Horario considerar adicional noturno
	Private nHrMaxFer    := GetNewPar("ZZ_PONAP06",10.00)             // Total horas para considerar banco para feriado

	If lHabilta
		fTVCkTurno(cFunc,@cTurno)
		fMarBanco(Paramixb[1],Paramixb[2],cTurno,cFunc)
	Endif

	lj7RestArea(aArea)

Return

/*
Funcao que retorna Turno de trabalho.
*/
Static Function fTVCkTurno(cFunc,cTurno)

	Local cCmdSPF := ""

	cCmdSPF := " SELECT TOP 1 PF_TURNOPA " + CRLF
	cCmdSPF += " FROM " + RetSqlName("SPF") + " " + CRLF
	cCmdSPF += " WHERE 1 = 1 " + CRLF
	cCmdSPF += " 	AND PF_FILIAL  = '" + xFilial("SPF") + "' " + CRLF
	cCmdSPF += " 	AND PF_MAT     = '" + cFunc + "' " + CRLF
	cCmdSPF += " 	AND D_E_L_E_T_ = ' ' " + CRLF
	cCmdSPF += " ORDER BY PF_MAT,PF_DATA DESC " + CRLF

	If Select("ASPF") <> 0
		ASPF->(dbCloseArea())
	Endif

	TcQuery cCmdSPF Alias "ASPF" New
	ASPF->(dbGoTop())
	If !Eof()
		cTurno := ASPF->PF_TURNOPA
	Endif

	ASPF->(dbCloseArea())

Return

/*
Funcao que retorna as horas trabalhadas na semana.
*/
Static Function fTVCkSPJ(cTurno,aHRDias)

	Local cCmdSPJ := ""

	cTurno  := SRA->RA_TNOTRAB

	cCmdSPJ := " SELECT * "
	cCmdSPJ += " FROM " + RetSqlName("SPJ") + " " + CRLF
	cCmdSPJ += " WHERE 1 = 1 " + CRLF
	cCmdSPJ += " 	AND PJ_FILIAL  = '"+xFilial("SPJ")+"'" + CRLF
	cCmdSPJ += " 	AND PJ_TURNO   = '" + cTurno + "'" + CRLF
	cCmdSPJ += " 	AND PJ_SEMANA  = '01'" + CRLF
	cCmdSPJ += " 	AND D_E_L_E_T_ = ' ' " + CRLF
	cCmdSPJ += " ORDER BY PJ_TURNO,PJ_SEMANA,PJ_DIA " + CRLF

	If Select("ASPJ") <> 0
		ASPJ->(dbCloseArea())
	Endif

	TcQuery cCmdSPJ Alias "ASPJ" New
	ASPJ->(dbGoTop())

	While !Eof()

		__Cc := 1
		nPjZZHrTra := ASPJ->PJ_ZZHRTRA

		aadd(aHRDias,{ASPJ->PJ_TURNO,;
			ASPJ->PJ_SEMANA,;
			ASPJ->PJ_DIA,;
			ASPJ->PJ_TPDIA,;
			ASPJ->PJ_HRSINT1,;
			Iif(ASPJ->PJ_ZZTOTHR=0,10,ASPJ->PJ_ZZTOTHR),;
			nPjZZHrTra})

		dbSelectARea("ASPJ")
		dbSkip()

	Enddo

	dbSelectARea("ASPJ")
	ASPJ->(dbCloseArea())

	If Len(aHRDias) = 0
		aadd(aHRDias,{"","01","1","D",1,10,0})
		aadd(aHRDias,{"","01","2","S",1,10,9})
		aadd(aHRDias,{"","01","3","S",1,10,9})
		aadd(aHRDias,{"","01","4","S",1,10,9})
		aadd(aHRDias,{"","01","5","S",1,10,9})
		aadd(aHRDias,{"","01","6","S",1,10,8})
		aadd(aHRDias,{"","01","7","C",1,10,0})
	Endif

Return()

/*
Funcao atualiza as Marcacoes do ponto eletronico.
*/
Static Function fMarBanco(aMarca,aCols,cTurno,cFunc)

	Local lProcBHTV    := .F.
	Local cSemana      := ""
	Local cDiaSemana   := ""
	Local cEvento      := ""
	Local cEvento028   := "028"
	Local cFeriado     := ""
	Local cRegraApto   := ""
	Local aPonto       := {}
	Local aHRDias      := {}
	Local aMarcaNova   := {}
	Local nSumHrReal   := 0
	Local nLoops       := 0
	Local nLoop        := 0
	Local nHRReal      := 0
	Local nHrLimBanco  := 0
	Local nVlEv028     := 0
	Local nTotalHrLim  := 0
	Local nTotalHr     := 0
	Local nTotalAdi    := 0
	Local nSaldoDi     := 0
	Local nSaldoNo     := 0
	Local nVlBancoDi   := 0
	Local nVlBancoNo   := 0
	Local nVlFolhaDi   := 0
	Local nVlFolhaNo   := 0
	Local nVlToler     := 0
	Local nContMarc    := 0
	Local nk           := 0
	Local i

	For nk := 1 to Len(aMarca)

		If Empty(Alltrim(dDtCorte))
			Return()
		Endif

		dDataIni     := aMarca[nk][1]
		cHoraini     := Iif(Upper(Alltrim(Funname())) = "PONM010",aMarca[nk][2], aMarca[nk][5])
		cSemana      := ""
		cDiaSemana   := ""
		cFeriado     := ""
		cRegraApto   := SRA->RA_REGRA
		nCtoMarc     := 0
		nHrReal      := 0
		nVlEv028     := 0
		nTotalHrLim  := 0
		nTotalHr     := 0
		nTotalAdi    := 0
		nVlBancoDi   := 0
		nVlBancoNo   := 0
		nVlFolhaDi   := 0
		nVlFolhaNo   := 0
		nSaldoDi     := 0
		nSaldoNo     := 0
		nVlToler     := 0
		nContMarc    := 0
		nKCtoMar     := nk
		aPonto       := {}
		lLimiteBanco := .F.

		While DtoS(dDataIni) = DtoS(aMarca[nKCtoMar][1])
			cHorafim := Iif(Upper(Alltrim(Funname())) = "PONM010",aMarca[nKCtoMar][2], aMarca[nKCtoMar][5])
			dDataFim := aMarca[nKCtoMar][1]
			aadd(aPonto, {aMarca[nKCtoMar][12],dDataFim,cHorafim})
			nCtoMarc ++
			nKCtoMar ++
			If nKCtoMar > Len(aMarca)
				EXIT
			Endif
		Enddo

		// Valida se teve marcacao repetida (1E, 2E, 3E, 4E)
		For i := 1 to Len(aPonto)
			nContMarc += Val(SUBSTR(aPonto[i,1],1,1))
		Next i

		lProcBHTV := Iif ( Upper(Alltrim(Funname())) <> "PONM010" ,.T., Iif( (aMarca[nk][1] >= MV_PAR13 .AND. aMarca[nk][1] <= MV_PAR14 ),.T.,.F.))
		nPtPar  := ( Len( aPonto ) % 2 == 0) .and. (nContMarc % 2 == 0)

		IF DtoS(aMarca[nk][1]) >= dDtCorte .and. lProcBHTV .and. nPtPar

			nSumHrReal := 0
			nLoops     := Len(aPonto) / 2

			For nLoop := 1 To nLoops

				nPosEnt	:= aScan(aPonto, {|x| Alltrim(x[1]) = Alltrim(Str(nloop))+"E" })
				nPosSai	:= aScan(aPonto, {|x| Alltrim(x[1]) = Alltrim(Str(nloop))+"S" })

				If nPosEnt = 0 .and. nPosSai = 0
					nLoop := nLoops + 1
				Endif

				// Temos os dois movimentos ( Entrada e saida )
				cHoraini := Iif ( Upper(Alltrim(Funname())) <> "PONM010", VAl(aPonto[nPosEnt][3]), (aPonto[nPosEnt][3]))
				cHorafim := Iif ( Upper(Alltrim(Funname())) <> "PONM010", VAl(aPonto[nPosSai][3]), (aPonto[nPosSai][3]))

				cHorafim := fConvHr(cHorafim,'D',,4)
				cHoraini := fConvHr(cHoraini,'D',,4)

				If cHorafim > nHoraNoturno
					nHoraNoturno := fConvHr(nHoraNoturno, 'D' ,,4)
					nTotalAdi    := cHorafim - IIF(cHoraini > nHoraNoturno, cHoraini, nHoraNoturno)
				EndIf

				nHrReal := cHorafim  - cHoraini
				nSumHrReal += nHrReal

			Next nLoop

			nHrReal := nSumHrReal
			aHRDias := {}
			fTVCkSPJ(cTurno,@aHRDias)

			nDiaSemana := Alltrim(Str(dow(dDataIni)))
			nPosArr    := aScan(aHRDias, {|x| x[3] == nDiaSemana })

			cDiaSemana := aHRDias[nPosArr][4] // Retorna dia da Semana

			dbSelectArea("SP8")
			dbSetOrder(2)
			If dbSeek(xFilial("SP8") + cFunc + DtoS(dDataIni))
				cSemana:= SP8->P8_SEMANA
				cTurno := SP8->P8_TURNO
			Endif

			If cDiaSemana $ "SDC"

				nHrMaximo   := fConvHr(aHRDias[nPosArr][6], 'D' ,,4)
				nHrFood     := fConvHr(aHRDias[nPosArr][5], 'D' ,,4)
				nHrTrab     := fConvHr(aHRDias[nPosArr][7], 'D' ,,4)
				nHrLimBanco := (nHrMaximo - nHrTrab)
				nVlToler    := POSICIONE("SPA",1,xFilial("SPA")+cRegraApto,"PA_TOLHEPE")
				cFeriado    := POSICIONE("SP3",1,xFilial("SP3")+DtoS(dDataIni),"P3_DATA")
				nVlEv028    := POSICIONE("SPC",1,xFilial("SPC")+cFunc+cEvento028+DtoS(dDataIni),"PC_QUANTC")

				nVlEv028    := fConvHr(nVlEv028,'D',,4)
				nVlToler    := fConvHr(nVlToler,'D',,4)

				If !Empty(cFeriado)
					cDiaSemana  := "F"
					nHrTrab     := 0
					nHrLimBanco := nHrMaxFer
				EndIf

				nTotalHr    := nHrReal
				nTotalHrLim := nHrReal - nTotalAdi
				nSaldoDi    := nTotalHrLim - nHrTrab

				If nSaldoDi < nHrLimBanco
					nVlBancoDi := nSaldoDi
					If nTotalAdi > 0
						nVlBancoNo := nHrLimBanco - nSaldoDi
						If cDiaSemana $ "DCF" .and. nVlEv028 < nVlBancoNo
							nVlBancoNo := nVlEv028
						EndIf
					EndIf
				Else
					nVlBancoDi := nHrLimBanco
				EndIf

				If nSaldoDi > nHrLimBanco .and. ((nTotalHrLim - nHrTrab) > nHrLimBanco)
					nVlFolhaDi := (nTotalHrLim - nHrTrab) - nVlBancoDi
				EndIf

				If nTotalAdi != 0
					nVlFolhaNo := nVlEv028 - nVlBancoNo
				EndIf

				// Valor Banco Diurno
				If nVlBancoDi > 0 .and. (nSumHrReal - nHrTrab) > nVlToler
					If cDiaSemana == "S"
						cEvento    := "060"
					ElseIf cDiaSemana == "D"
						cEvento    := "064"
					ElseIf cDiaSemana == "C"
						cEvento    := "068"
					ElseIf cDiaSemana == "F"
						cEvento    := "072"
					EndIf
					nVlBancoDi := fConvHr(nVlBancoDi , 'H' ,,2)
					aAdd(aMarcaNova,{;
						SRA->RA_FILIAL,;
						cFunc,;
						dDataIni,;
						cEvento,;
						nVlBancoDi,;
						cTurno,;
						cSemana})
				EndIf

				// Valor Folha Diurno
				If nVlFolhaDi > 0
					If cDiaSemana == "S"
						cEvento    := "062"
					ElseIf cDiaSemana == "D"
						cEvento    := "066"
					ElseIf cDiaSemana == "C"
						cEvento    := "070"
					ElseIf cDiaSemana == "F"
						cEvento    := "074"
					EndIf
					nVlFolhaDi := fConvHr(nVlFolhaDi ,'H',,2)
					aAdd(aMarcaNova,{;
						SRA->RA_FILIAL,;
						cFunc,;
						dDataIni,;
						cEvento,;
						nVlFolhaDi,;
						cTurno,;
						cSemana})
				EndIf

				// Valor Banco Noturno
				If nVlBancoNo > 0
					If cDiaSemana == "S"
						cEvento    := "076"
					ElseIf cDiaSemana == "D"
						cEvento    := "080"
					ElseIf cDiaSemana == "C"
						cEvento    := "084"
					ElseIf cDiaSemana == "F"
						cEvento    := "088"
					EndIf
					nVlBancoNo := fConvHr(nVlBancoNo ,'H',,2)
					aAdd(aMarcaNova,{;
						SRA->RA_FILIAL,;
						cFunc,;
						dDataIni,;
						cEvento,;
						nVlBancoNo,;
						cTurno,;
						cSemana})
				EndIf

				// Valor Folha Noturno
				If nVlFolhaNo > 0
					If cDiaSemana == "S"
						cEvento    := "078"
					ElseIf cDiaSemana == "D"
						cEvento    := "082"
					ElseIf cDiaSemana == "C"
						cEvento    := "086"
					ElseIf cDiaSemana == "F"
						cEvento    := "090"
					EndIf
					nVlFolhaNo := fConvHr(nVlFolhaNo ,'H',,2)
					aAdd(aMarcaNova,{;
						SRA->RA_FILIAL,;
						cFunc,;
						dDataIni,;
						cEvento,;
						nVlFolhaNo,;
						cTurno,;
						cSemana})
				EndIf

				If Len(aMarcaNova) > 0
					AtualizaSPC(aMarcaNova)
					ValidaSPC(cFunc,dDataIni)
				EndIf

			EndIf

		Endif

		nk := nKCtoMar - 1

	Next nK

Return

/*
Funcao para limpar os dados da tabela SPC.
*/
Static Function LimpaDate(cFunc,cEvExcluir,dDataIni)

	Default cFunc      := ""
	Default cEvExcluir := ""
	Default dDataIni   := ""

	BEGIN TRANSACTION

		dbSelectARea("SPC")
		dbSetOrder(1)
		If dbSeek(xFilial("SPC") + cFunc + cEvExcluir + DtoS(dDataIni))
			DBSelectArea("SPC")
			Reclock("SPC",.F.)
			SPC->(dbDelete())
			SPC->(MSUNLOCK())
		Endif

	END TRANSACTION

Return

/*
Funcao para validar os dados da tabela SPC.
*/
Static Function ValidaSPC(cFunc,dDataIni)

	Local lEvAtual   := .F.
	Local cEvAtual   := ""
	Local cEvExcluir := ""

	dbSelectArea("SPC")
	SPC->(dbSetOrder(2))
	SPC->(dbGoTop())
	If dbSeek(xFilial("SPC") + cFunc + DtoS(dDataIni))
		While SPC->(!Eof()) .and. DTOS(SPC->PC_DATA) == DTOS(dDataIni)
			cEvAtual := SPC->PC_PD
			If cEvAtual $ cEvExtra
				lEvAtual := .T.
			EndIf
			If lEvAtual .and. cEvAtual $ cEvExNot
				cEvExcluir := cEvAtual
			EndIf
			SPC->(dbSkip())
		EndDo
	EndIf

	If !Empty(cEvExcluir)
		LimpaDate(cFunc,cEvExcluir,dDataIni)
	EndIf

Return

/*
Funcao para atualizar os eventos da tabela SPC (Banco de Horas / Folha - Hora Extra Diurno e Noturno).
*/
Static Function AtualizaSPC(aMarcaNova)

	Local cFil       := ""
	Local cFunc      := ""
	Local dDataIni   := ""
	Local cEvento    := ""
	Local cTurno     := ""
	Local cSemana    := ""
	Local nVlrEvento := 0
	Local i

	BEGIN TRANSACTION

		For i := 1 to Len(aMarcaNova)

			cFil       := aMarcaNova[i,1]
			cFunc      := aMarcaNova[i,2]
			dDataIni   := aMarcaNova[i,3]
			cEvento    := aMarcaNova[i,4]
			nVlrEvento := aMarcaNova[i,5]
			cTurno     := aMarcaNova[i,6]
			cSemana    := aMarcaNova[i,7]

			dbSelectARea("SPC")
			SPC->(dbSetOrder(1))
			SPC->(dbGoTop())
			If dbSeek(xFilial("SPC") + cFunc + cEvento + DtoS(dDataIni))
				RecLock("SPC", .F.)
				SPC->PC_QUANTC := nVlrEvento
				SCP->(MSUnLock())
			EndIf
			If !(dbSeek(xFilial("SPC") + cFunc + cEvento + DtoS(dDataIni)))
				RecLock("SPC", .T.)
				SPC->PC_FILIAL := cFil         // Filial
				SPC->PC_MAT    := cFunc        // Numero da Matricula
				SPC->PC_DATA   := dDataIni     // Data da Marcacao
				SPC->PC_PD     := cEvento      // Código do Evento
				SPC->PC_CC     := SRA->RA_CC   // Código do Centro de Custo
				SPC->PC_QUANTC := nVlrEvento   // Horas Calculadas
				SPC->PC_TURNO  := cTurno       // Turno
				SPC->PC_SEMANA := cSemana      // Semana
				SCP->(MSUnLock())
			EndIf

		Next i

	END TRANSACTION

Return

