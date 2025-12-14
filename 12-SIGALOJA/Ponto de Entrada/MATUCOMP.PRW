#Include 'Protheus.ch'
#Include 'TbiConn.ch'
#Include 'PRTOPDEF.CH'

//---------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MATUCOMP
Relatório de conferência de notas fiscais pendentes de serem classificadas no módulo
compras/documento de entrada.

Quando se referir aos complementos para geracao dos registros C110, C111, C112, C113, C114 e C115
a tabela CDT também deve ser alimentada, pois ela que efetua o relacionamentos com as outras   
conforme registro. C110 = Tab. CDT, C111 = Tab. CDG, , C112 = Tab. CDC, C113 = Tab. CDD,       
C114 = Tab. CDE e C115 = Tab. CDF                                                              

@author    	Charlles Reis
@version   	1.0
@since      Setembro/2021
/*/
//---------------------------------------------------------------------------------------------------

User Function MATUCOMP()

	Local aAreaAtu  := GetArea()
	Local aAreaCDD  := CDD->(GetArea())
	Local aAreaCD6  := CD6->(GetArea())
	Local aAreaSD2  := SD2->(GetArea())
	Local aAreaSB1  := SB1->(GetArea())
	Local cEntSai   := ParamIXB[1]
	Local cSerie    := ParamIXB[2]
	Local cDoc      := ParamIXB[3]	
	Local cCliefor  := ParamIXB[4]
	Local cLoja     := ParamIXB[5]
	//Local cTipo     := ParamIXB[6]
	Local cAliasSD1 := ""
	Local lGrava	:= .T.

	If  cEntSai <> "E"

		SD2->(dbSelectArea("SD2"))
		SD2->(dbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM

		CD6->(dbSelectArea("CD6"))
		CD6->(dbSetOrder(1))	//-CD6_FILIAL+CD6_TPMOV+CD6_SERIE+CD6_DOC+CD6_CLIFOR+CD6_LOJA+CD6_ITEM+CD6_COD+CD6_PLACA+CD6_TANQUE+CD6_UFORIG

		SD2->( DBSEEK ( XFILIAL("SD2") + cDoc + cSerie + cCliefor + cLoja ) )

		DO WHILE .NOT. SD2->(EOF()) .AND. XFILIAL("SD2") + SD2->D2_DOC + SD2->D2_SERIE + SD2->D2_CLIENTE + SD2->D2_LOJA == ;
			XFILIAL("SD2") + cDoc + cSerie + cCliefor + cLoja
			
			If SUBSTR(SD2->D2_CF,2,3) $ '655/656/659'

				dbselectarea("SB1")
				dbsetorder(01)
				If dbseek(xFilial("SB1")+SD2->D2_COD)

					If CD6->(dbSeek(xFilial("CD6")+"S"+SD2->(D2_SERIE+D2_DOC+D2_CLIENTE+D2_LOJA+D2_ITEM+D2_COD)))
						lGrava := .F.
					Else
						lGrava := .T.
					EndIf

					RECLOCK("CD6", lGrava)
					CD6->CD6_FILIAL := SD2->D2_FILIAL
					CD6->CD6_TPMOV  := "S"
					CD6->CD6_DOC    := SD2->D2_DOC
					CD6->CD6_SERIE  := SD2->D2_SERIE
					CD6->CD6_CLIFOR := SD2->D2_CLIENTE
					CD6->CD6_LOJA   := SD2->D2_LOJA
					CD6->CD6_ITEM   := SD2->D2_ITEM
					CD6->CD6_COD    := SD2->D2_COD
					CD6->CD6_QTDE   := SD2->D2_QUANT
					CD6->CD6_CODANP := IIF(!Empty(SB1->B1_XANP),SB1->B1_XANP,"620505001")
					CD6->CD6_DESANP := IIF(!Empty(SB1->B1_XDESANP),SB1->B1_XDESANP,"OUTROS OLEOS LUBRIFICANTES AUTOMOTIVOS")
					CD6->CD6_UFCONS := SD2->D2_EST
					CD6->(MSUNLOCK())
				EndIf
				
			EndIf
			SD2->(dbskip())
		EndDo
	Else
		If	!(cTipo$"DB") .or. !INCLUI
			Return
		EndIf
	EndIf

	cAliasSD1	:= GetNextAlias()

	BeginSql Alias cAliasSD1

		SELECT D1_NFORI, D1_SERIORI, F4_CODINFC
		FROM %TABLE:SD1% D1
		INNER JOIN SF4010 F4 ON F4_FILIAL = %exp:xFilial("SF4")% AND F4_CODIGO = D1_TES AND F4.D_E_L_E_T_=''
		WHERE 
			D1_DOC = %exp:cDoc%
		AND D1_SERIE = %exp:cSerie%
		AND D1_FORNECE = %exp:cClieFor%
		AND D1_LOJA = %exp:cLoja%
		AND F4_CODINFC <> ''
		AND D1.%NOTDEL%
		ORDER BY %Order:SD1%

	EndSql

    (cAliasSD1)->(dbGoTop())

    If  !(cAliasSD1)->(EOF())

        //CDD_FILIAL+CDD_TPMOV+CDD_DOC+CDD_SERIE+CDD_CLIFOR+CDD_LOJA+CDD_DOCREF+CDD_SERREF+CDD_PARREF+CDD_LOJREF
        dbSelectArea("CDD")
        CDD->(dbSetOrder(1))
        If  CDD->(dbSeek(xFilial("CDD")+cEntSai+cDoc+cSerie+cClieFor+cLoja+(cAliasSD1)->(D1_NFORI+D1_SERIORI)+cClieFor+cLoja))

            RecLock("CDD",.F.)
            CDD->CDD_IFCOMP := (cAliasSD1)->F4_CODINFC
            MsUnLock()
            FkCommit()
        EndIf
    EndIf

	RestArea(aAreaCDD)
	RestArea(aAreaCD6)
	RestArea(aAreaSD2)
	RestArea(aAreaSB1)
	RestArea(aAreaAtu)

Return
