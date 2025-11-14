////////////////
// Versao  02 //
////////////////

#Include "PROTHEUS.CH" 

user function OM450IMP()
	Local cAlias    := GetNextAlias()
	Local cTitulo   := "Requisição/Devoluções de Ferramentas"
	Local cDesc2    := ""
	Local cDesc3    := ""
	Local cAliasP   := "VO9"
	Local cQuery    := ""
	Local cNomeRel  := "OM450"
	Local cTamanho  := "M" // P/M/G
	Local nLin      := 0
			
	aReturn := {'######', 1, '!!!!!', 2, 2, 1,            "", 1}
	cNomeRel := SetPrint(cAliasP, cNomeRel,, @cTitulo, cTitulo, cDesc2, cDesc3, .F.,,, cTamanho)
	If aReturn[1] == '######' // Caso cancelar a impressão
		Return                  // não imprime nada
	EndIf
	SetDefault(aReturn, cAliasP)

	cVdpCod := PARAMIXB[1]
	dbSelectArea('VDP')
	dbSetOrder(1)
	msSeek(xFilial('VDP') + cVdpCod)

	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY 'Código da Requisição: ' + cVdpCod
	nLin += 1
	@ nLin, 00 PSAY 'Número da OS: ' + VDP->VDP_NUMOSV
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1

	// Cabeçalho impresso agora vem o relatório em si
	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY 'Data:' + TRANSFORM( VDP->VDP_DATMOV, PESQPICT('VDP', 'VDP_DATMOV') )
	nLin += 1

	DbSelectArea('VAI')
	DbSetOrder(1) // Filial + CodTecnico/Produtivo
	DbSeek( xFilial('VAI') + VDP->VDP_CODPRO )

	@ nLin, 00 PSAY 'Prestador: ' + VAI->VAI_NOMTEC
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY 'Ferramentas' + " " + IIF( VDP->VDP_TIPMOV == oReqFer:TipoDevolucao(), 'Devolvidas', 'Requisitadas')
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1
	//                                Cod Ferramenta      Ferramenta          Qtd                 CodProduto Sb1
	@ nLin, 00 PSAY PADR('Código Ferramenta', 22) + PADR('Ferramenta', 22) + PADR('Quant.', 10) + PADR('Código Produto', 20) + PADR('Local',20)
	nLin += 1
	@ nLin, 00 PSAY Replicate("-", 70) // separador cabecalho x lista de dados
	nLin += 1

	cQuery += "SELECT VD3.VD3_SEQUEN, VD3.VD3_CODFER, VO9.VO9_CODPRO, VO9.VO9_XLOCAL, "
	cQuery += "VO9.VO9_DESFER, VD3.VD3_DATMOV, VD3.VD3_QTDMOV, VD3.R_E_C_N_O_ "
	cQuery += "FROM " + RetSqlName('VD3') + " VD3 " 
	cQuery += "JOIN " + RetSqlName('VO9') + " VO9 ON VO9_FILIAL = '" + xFilial('VO9') + "' AND VO9_CODFER = VD3_CODFER AND VO9.D_E_L_E_T_ = ' ' "
	cQuery += "WHERE VD3.VD3_FILIAL = '" + xFilial('VD3')  + "' "
	cQuery += "AND VD3.VD3_CODIGO = '" + cVdpCod + "' "
	cQuery += "AND VD3.D_E_L_E_T_ = ' ' "
	cQuery += "ORDER BY VD3.VD3_SEQUEN ASC "

	dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery),cAlias, .F., .T. )
	While ! (cAlias)->(EOF()) // Enquanto o cursor da area de trabalho ativa nao indicar fim de arquivo
		cLinha := ''
		cLinha += PADR( (cAlias)->VD3_CODFER   , 21 ) + ' ' // Cod fer
		cLinha += PADR( (cAlias)->VO9_DESFER   , 21 ) + ' ' // Nome Fer
		cLinha += PADR( (cAlias)->VD3_QTDMOV   , 09 ) + ' ' // Qtd.
		cLinha += PADR( (cAlias)->VO9_CODPRO   , 19 ) + ' ' // Cod. SB1
		cLinha += PADR( (cAlias)->VO9_XLOCAL   , 19 ) + ' ' // Local fer

		@ nLin, 00 PSAY cLinha
		nLin += 1

		DbSkip()
	End
	(cAlias)->(dbCloseArea())

	// Espaço para assinaturas
	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1
	@ nLin, 00 PSAY ''
	nLin += 1

	// Assinaturas
	@ nLin, 00 PSAY Replicate("_", 40)
	@ nLin, 00 PSAY PADL(Replicate("_", 40), 110)
	nLin += 1

	@ nLin, 00 PSAY PADC('Responsável', 40)
	@ nLin, 00 PSAY PADL( PADC('Prestador', 40), 110) // 80 é o tamanho da coluna em caracteres dando espaco de 30 entre os '_' da 110
	nLin += 1

	If aReturn[5] == 1
		OurSpool( cNomeRel )
	EndIf
return nLin
