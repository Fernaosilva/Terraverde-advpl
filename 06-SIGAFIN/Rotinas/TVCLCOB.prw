#include "TOTVS.ch"
#include "topconn.ch"
#Include "Tbiconn.ch"

/*
  Classe para realizar o envio de email com titulos vencidos aos clientes,vendedores e supervidor.
*/
Class TVCLCOB

	data aDadosTitulos

	Method New() Constructor
	Method execute()
	Method getDadosTitulos()
	Method montaHtmlEmail()
	Method fEnvMail()

	Method dadosVencidos()
	Method dadosAVencer()
	//Method dadosLimiteCreditoVend()

	Method MontaHtml()
	Method MontaCabecHtml()
	Method MontaBodyHtml()

	Method setTitulos()
	Method getTitulos()

EndClass

Method New() Class TVCLCOB
	::aDadosTitulos := {}
Return


/* -------- execute -------- */
Method execute() Class TVCLCOB
	::getDadosTitulos("vencidos")
	::getDadosTitulos("avencer5")
	::getDadosTitulos("avencer0")
	//::getDadosTitulos("limitePorVendedor")
Return

/* -------- getDadosTitulos -------- */
Method getDadosTitulos(cTipo) Class TVCLCOB
	local nX              	:= 0
	local cDiasVenc         := ""
	local aDadosVencidos   	:= {}
	local aDadosAVencer  	:= {}

	if Alltrim(cTipo) == "vencidos"

		cDiasVenc := SUPERGETMV( "ZZ_WFDVENC", .F., "5" ) //Número de dias vencidos para envio do primeiro email cobrança
		cMltEnv   := SUPERGETMV( "ZZ_WFMVENC", .F., "5" ) //Número de dias entre os envios do email cobrança
		aDadosVencidos := ::dadosVencidos(cDiasVenc)
		for nX := 1 to Len(aDadosVencidos)
			::montaHtmlEmail(cTipo, aDadosVencidos[nX])
		next nX

	elseif Alltrim(cTipo) == "avencer5"
		cDiasVenc := "5"
		aDadosAVencer := ::dadosavencer(cDiasVenc)
		for nX := 1 to Len(aDadosAVencer)
			::montaHtmlEmail(cTipo, aDadosAVencer[nX])
		next nX

	elseif Alltrim(cTipo) == "avencer0"
		cDiasVenc := "0"
		aDadosAVencer := ::dadosavencer(cDiasVenc)
		for nX := 1 to Len(aDadosAVencer)
			::montaHtmlEmail(cTipo, aDadosAVencer[nX])
		next nX

	endif

Return

/* -------- getDadosTitulos vencidos -------- */
Method dadosVencidos(cDiasVenc) Class TVCLCOB
	local cAlias      := getNextAlias()
	local cQuery      := ""
	local aTitCliente := {}
	local ca1email      := ''
	Local cSepNeg   := If("|"$MV_CPNEG,"|",",")
	Local cSepProv  := If("|"$MVPROVIS,"|",",")
	Local cSepRec   := If("|"$MVPAGANT,"|",",")
	Local cSepRet   := If("|"$MVRECANT,"|",",")
	Local cSepCNeg  := If("|"$MV_CRNEG,"|",",")

	cQuery := " SELECT "+ CRLF
	cQuery += " SA1.A1_NOME, CONCAT(TRIM(SA1.A1_EMAIL),'-',TRIM(A1_XEMAILC)) A1_EMAIL, "+ CRLF
	cQuery += " SE1.E1_CLIENTE,E1_LOJA,E1_VEND1,E1_CLIENTE,E1_LOJA,E1_NUM,E1_PARCELA,E1_EMISSAO,E1_VENCREA,E1_VALOR,E1_SALDO,E1_NFELETR, "   + CRLF                                        + CRLF
	cQuery += " DATEDIFF(day,SubsTring(SE1.E1_VENCREA,1,4) + '-' + SubsTring(SE1.E1_VENCREA,5,2) + '-' + SubsTring(SE1.E1_VENCREA,7,2),CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23)) DIFERENCA_DATAS_DIAS, " + CRLF
	cQuery += " CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23) DATA_ATUAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SE1") + " " 										+ CRLF
	cQuery += " INNER JOIN " + RetSqlTab("SA1") + " " 						+ CRLF
	cQuery += " ON  SA1.A1_FILIAL = '" + xFilial("SA1") + "' " 	+ CRLF
	cQuery += " AND SA1.D_E_L_E_T_ = ' '" 											+ CRLF
	cQuery += " AND SA1.A1_COD  = SE1.E1_CLIENTE "					  	+ CRLF
	cQuery += " AND SA1.A1_LOJA = SE1.E1_LOJA "						      + CRLF
	cQuery += " WHERE SE1.D_E_L_E_T_ = ' ' " 										+ CRLF
	cQuery += " AND  SE1.E1_FILIAL = '" + xFilial("SE1") + "'" 	+ CRLF
	cQuery += " AND E1_EMISSAO >= '20230301' "
	cQuery += " AND DATEDIFF(day,SubsTring(SE1.E1_VENCREA,1,4) + '-' + SubsTring(SE1.E1_VENCREA,5,2) + '-' + SubsTring(SE1.E1_VENCREA,7,2),CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23)) > "+cDiasVenc
	cQuery += " AND DATEDIFF(day,SubsTring(SE1.E1_VENCREA,1,4) + '-' + SubsTring(SE1.E1_VENCREA,5,2) + '-' + SubsTring(SE1.E1_VENCREA,7,2),CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23)) % "+cMltEnv+" = 0" 
	cQuery += " AND SE1.E1_SALDO > 0 " + CRLF
	cQuery += " AND TRIM(SA1.A1_EMAIL)+TRIM(A1_XEMAILC) <> ' ' "+ CRLF 
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVPAGANT,cSepRec)  + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv) + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MV_CPNEG,cSepNeg)  + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRet) + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepCNeg) + " "
	cQuery += " AND E1_TIPO NOT IN ('CC ','CD ') "
	
	/*PARA TESTES*/
	 //cQuery += "  AND SE1.E1_PREFIXO = '1'"
	 //cQuery += "  AND SE1.E1_NUM     = '000072017'"
	 //cQuery += "  AND SE1.E1_PARCELA = ' '"
	/*PARA TESTES*/

	cQuery += "ORDER BY SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_PREFIXO, SE1.E1_NUM"

	MEMOWRITE("c:\temp\queryvencidos"+cfilant+".txt", cQuery)

	TCQUERY cQuery NEW ALIAS (cAlias)

	aDados := {}
	While (cAlias)->(!Eof())
		cCliente    := (cAlias)->E1_CLIENTE
		cLoja       := (cAlias)->E1_LOJA
		lPreenche   := .T.
		aTitulos    := {}
		aCliente    := {}

		While (cAlias)->E1_CLIENTE + (cAlias)->E1_LOJA == cCliente+cLoja
			aTemp := {}

			If lPreenche
				AADD(aCliente, cCliente)
				AADD(aCliente, cLoja)
				AADD(aCliente, (cAlias)->A1_NOME)
				ca1email := StrTran((cAlias)->A1_EMAIL,"-",";")
				AADD(aCliente,ca1email )
				lPreenche := .F.

				aAdd(aTemp, "Numero NF")
				aAdd(aTemp, "Numero RPS") //Patini: Novo campo adicionado
				aAdd(aTemp, "Parcela")
				aAdd(aTemp, "Emissao")
				aAdd(aTemp, "Vencimento Real")
				aAdd(aTemp, "Valor")
				aAdd(aTemp, "Saldo")
				aAdd(aTemp, "Dias em atraso")
				aAdd(aTitulos, aTemp)

				aTemp := {}

			endif

			nDiasAtraso := (cAlias)->DIFERENCA_DATAS_DIAS

			aAdd(aTemp, (cAlias)->E1_NUM)
			aAdd(aTemp, (cAlias)->E1_NFELETR)
			aAdd(aTemp, (cAlias)->E1_PARCELA)
			aAdd(aTemp, DTOC(STOD((cAlias)->E1_EMISSAO)))
			aAdd(aTemp, DTOC(STOD((cAlias)->E1_VENCREA)))
			aAdd(aTemp, Transform((cAlias)->E1_VALOR, "@E 99,999,999,999.99"))
			aAdd(aTemp, Transform((cAlias)->E1_SALDO, "@E 99,999,999,999.99"))
			aAdd(aTemp, nDiasAtraso)

			aAdd(aTitulos, aTemp)

			(cAlias)->(DbSkip())
		end

		if len(aTitulos) > 0
			aAdd(aTitCliente, {aCliente, aTitulos})
		endif

	End

	(cAlias)->(DbCloseArea())

return(aTitCliente)


/* -------- getDadosTitulos -------- */

Method dadosavencer(cDiasVenc) Class TVCLCOB
		
	local cAlias      := getNextAlias()
	local cQuery      := ""
	local aTitCliente := {}
	local ca1email    := ""
	Local cSepNeg   := If("|"$MV_CPNEG,"|",",")
	Local cSepProv  := If("|"$MVPROVIS,"|",",")
	Local cSepRec   := If("|"$MVPAGANT,"|",",")
	Local cSepRet   := If("|"$MVRECANT,"|",",")
	Local cSepCNeg  := If("|"$MV_CRNEG,"|",",")


	cQuery := " SELECT "+ CRLF
	cQuery += " SA1.A1_NOME, CONCAT(TRIM(SA1.A1_EMAIL),'-',TRIM(A1_XEMAILC)) A1_EMAIL, "+ CRLF 
	cQuery += " SE1.E1_CLIENTE,E1_LOJA,E1_VEND1,E1_CLIENTE,E1_LOJA,E1_NUM,E1_PARCELA,E1_EMISSAO,E1_VENCREA,E1_VALOR,E1_SALDO,E1_NFELETR, "   + CRLF                                        + CRLF
	cQuery += " DATEDIFF(day,SubsTring(SE1.E1_VENCREA,1,4) + '-' + SubsTring(SE1.E1_VENCREA,5,2) + '-' + SubsTring(SE1.E1_VENCREA,7,2),CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23)) DIFERENCA_DATAS_DIAS, " + CRLF
	cQuery += " CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23) DATA_ATUAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SE1") + " " 										+ CRLF
	cQuery += " INNER JOIN " + RetSqlTab("SA1") + " " 						+ CRLF
	cQuery += " ON  SA1.A1_FILIAL = '" + xFilial("SA1") + "' " 	+ CRLF
	cQuery += " AND SA1.D_E_L_E_T_ = ' '" 											+ CRLF
	cQuery += " AND SA1.A1_COD  = SE1.E1_CLIENTE "					  	+ CRLF
	cQuery += " AND SA1.A1_LOJA = SE1.E1_LOJA "						      + CRLF
	cQuery += " WHERE SE1.D_E_L_E_T_ = ' ' " 										+ CRLF
	cQuery += " AND  SE1.E1_FILIAL = '" + xFilial("SE1") + "'" 	+ CRLF
	//cQuery += "  AND SubsTring(SE1.E1_VENCREA,1,4)+'-'+SubsTring(SE1.E1_VENCREA,5,2)+'-'+SubsTring(SE1.E1_VENCREA,7,2) = CONVERT(CHAR(10), CURRENT_TIMESTAMP, 23)" + CRLF //2006-02-22
	cQuery += " AND E1_EMISSAO >= '20230301' "
	cQuery += " AND CONVERT(DATE, SE1.E1_VENCREA, 103) BETWEEN CONVERT(DATE, DATEADD(day,"+cDiasVenc+", GETDATE()), 103) AND CONVERT(DATE, DATEADD(day,"+cDiasVenc+", GETDATE()), 103) "
	cQuery += " AND SE1.E1_SALDO > 0 " + CRLF
	//cQuery += "  AND SE1.E1_TIPO = 'NF' " + CRLF
	cQuery += " AND TRIM(SA1.A1_EMAIL)+TRIM(A1_XEMAILC) <> ' ' "+ CRLF 
	//cQuery += "  AND SE1.E1_NATUREZ NOT IN ('JURIDICO','NRECUPERA') " + CRLF
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVPAGANT,cSepRec)  + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv) + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MV_CPNEG,cSepNeg)  + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRet) + " "
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepCNeg) + " "
	cQuery += " AND E1_TIPO NOT IN ('CC ','CD ') "

		
	/*PARA TESTES*/
	 //cQuery += "  AND SE1.E1_PREFIXO = '1'"
	 //cQuery += "  AND SE1.E1_NUM     IN ('000157171','000166135')"
	// cQuery += "  AND SE1.E1_PARCELA = ' '"
	/*PARA TESTES*/


	cQuery += "ORDER BY SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_PREFIXO, SE1.E1_NUM"

	//MEMOWRITE("c:\temp\queryavencer"+cfilant+"-"+cDiasVenc+".txt", cQuery)
	TCQUERY cQuery NEW ALIAS (cAlias)
	
	aDados := {}
	While (cAlias)->(!Eof())
		cCliente    := (cAlias)->E1_CLIENTE
		cLoja       := (cAlias)->E1_LOJA
		lPreenche   := .T.
		aTitulos    := {}
		aCliente    := {}

		While (cAlias)->E1_CLIENTE + (cAlias)->E1_LOJA == cCliente+cLoja
			aTemp := {}

			If lPreenche
				AADD(aCliente, cCliente)
				AADD(aCliente, cLoja)
				AADD(aCliente, (cAlias)->A1_NOME)
				ca1email := StrTran((cAlias)->A1_EMAIL,"-",";")
				AADD(aCliente, ca1email)
				lPreenche := .F.

				aAdd(aTemp, "Numero NF")
				aAdd(aTemp, "Numero RPS")
				aAdd(aTemp, "Parcela")
				aAdd(aTemp, "Emissao")
				aAdd(aTemp, "Vencimento Real")
				aAdd(aTemp, "Valor")
				aAdd(aTemp, "Saldo")
				aAdd(aTemp, "Dias para o vencimento")
				aAdd(aTitulos, aTemp)

				aTemp := {}

			endif

			nDiasAtraso := ABS((cAlias)->DIFERENCA_DATAS_DIAS)
						
			aAdd(aTemp, (cAlias)->E1_NUM)
			aAdd(aTemp, (cAlias)->E1_NFELETR)
			aAdd(aTemp, (cAlias)->E1_PARCELA)
			aAdd(aTemp, DTOC(STOD((cAlias)->E1_EMISSAO)))
			aAdd(aTemp, DTOC(STOD((cAlias)->E1_VENCREA)))
			aAdd(aTemp, Transform((cAlias)->E1_VALOR, "@E 99,999,999,999.99"))
			aAdd(aTemp, Transform((cAlias)->E1_SALDO, "@E 99,999,999,999.99"))
			aAdd(aTemp, nDiasAtraso)

			aAdd(aTitulos, aTemp)

			(cAlias)->(DbSkip())
		end

		if len(aTitulos) > 0
			aAdd(aTitCliente, {aCliente, aTitulos})
		endif

	End

	(cAlias)->(DbCloseArea())

return(aTitCliente)

/* -------- dadosLimiteCreditoVend -------- */
/*
Method dadosLimiteCreditoVend() Class TVCLCOB
	local cAlias      		:= getNextAlias()
	local cQuery      		:= ""
	local aLimiteCliente 	:= {}

	cQuery := "SELECT " + CRLF
	cQuery += " SA1.A1_COD,SA1.A1_LOJA, SA1.A1_NREDUZ,SA1.A1_LC,SA1.A1_SALDUP,SA1.A1_VEND, (SA1.A1_LC - SA1.A1_SALDUP) SALDO_CLIENTE, " + CRLF
	cQuery += " SA3.A3_COD,SA3.A3_NOME, SA3.A3_EMAIL " 						+ CRLF
	cQuery += "FROM " + RetSqlTab("SA3") + " " 										+ CRLF
	cQuery += " INNER JOIN " + RetSqlTab("SA1") + " " 						+ CRLF
	cQuery += " 	ON  SA1.A1_FILIAL = '" + xFilial("SA1") + "' " 	+ CRLF
	cQuery += " 	AND SA1.D_E_L_E_T_ <> '*'" 											+ CRLF
	cQuery += "   AND SA1.A1_MSBLQL = '2'" 										    + CRLF
	cQuery += "   AND SA1.A1_VEND = SA3.A3_COD "					    		+ CRLF
	cQuery += " WHERE SA3.D_E_L_E_T_ <> '*' " 										+ CRLF
	cQuery += "  AND  SA3.A3_FILIAL = '" + xFilial("SA3") + "'" 	+ CRLF
	cQuery += "  AND  AND SA3.A3_EMAIL <> ''" 										+ CRLF
	cQuery += " ORDER BY SA3.A3_COD"

	// MEMOWRITE("c:\temp\queryLimiteCreditoVendedores.txt", cQuery)

	TCQUERY cQuery NEW ALIAS (cAlias)

	aDados := {}
	While (cAlias)->(!Eof())
		cVendedor   := Alltrim((cAlias)->A3_COD)
		cNomeVend   := (cAlias)->A3_NOME
		cEmailVend  := (cAlias)->A3_EMAIL
		lPreenche   := .T.
		aVendedor   := {}
		aDados	    := {}

		AADD(aVendedor, cVendedor)
		AADD(aVendedor, "")
		AADD(aVendedor, cNomeVend)
		AADD(aVendedor, cEmailVend)

		While Alltrim((cAlias)->A1_VEND) == Alltrim(cVendedor)

			aTemp := {}

			If lPreenche
				aAdd(aTemp, "Cliente")
				aAdd(aTemp, "Loja")
				aAdd(aTemp, "N Fantasia")
				aAdd(aTemp, "Limite Credito")
				aAdd(aTemp, "Saldo Titulo")
				aAdd(aTemp, "Diferença")
				aAdd(aDados, aTemp)
				lPreenche := .F.
				aTemp := {}
			endif

			aAdd(aTemp, (cAlias)->A1_COD)
			aAdd(aTemp, (cAlias)->A1_LOJA)
			aAdd(aTemp, (cAlias)->A1_NREDUZ)
			aAdd(aTemp, Transform((cAlias)->A1_LC, "@E 99,999,999,999.99"))
			aAdd(aTemp, Transform((cAlias)->A1_SALDUP, "@E 99,999,999,999.99"))
			aAdd(aTemp, Transform((cAlias)->SALDO_CLIENTE, "@E 99,999,999,999.99"))
			aAdd(aDados, aTemp)

			(cAlias)->(DbSkip())
		end

		if len(aDados) > 0
			aAdd(aLimiteCliente, {aVendedor, aDados})
		endif

	End

	(cAlias)->(DbCloseArea())

return(aLimiteCliente)
*/
/* -------- MontaHtml -------- */
Method montaHtmlEmail(cTipo, aDados) Class TVCLCOB
	local cHtml       := ""
	local cPara       := ""
	local cAssunto    := ""
	local cCorpo      := ""
	local aAnexos     := {}
	local lMostraLog  := .F.
	local lSalvaLog   := SUPERGETMV( "ZZ_LOGMCOB", .f., .F. )
	local lUsaTLS     := .F.
	local lUsaSSL     := .T.
	local cEmailComp  := SuperGetMV("ZZ_EMAILCO",.F.,"contasareceber@terraverdeagro.com.br")

	if len(aDados) > 0

		cHtml   := ::MontaHtml(cTipo, aDados)
		cCorpo  := cHtml

		if cTipo == "vencidos"

			cPara       := Alltrim(aDados[1][4]) + ";" + Alltrim(cEmailComp)
			cAssunto    := "Fatura(s) em aberto"

		Elseif cTipo == "avencer5"

			cPara       := Alltrim(aDados[1][4]) + ";" + Alltrim(cEmailComp)
			cAssunto    := "Lembrete de vencimento"

		Elseif cTipo == "avencer0"
			cPara       := Alltrim(aDados[1][4]) + ";" + Alltrim(cEmailComp)
			cAssunto    := "Lembrete de vencimento"
		endif

		conout('TVCLCOB TIPO => ' + cTipo)
		conout('TVCLCOB EMAIL => ' + cPara)

		::fEnvMail(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS, lUsaSSL, lSalvaLog)
		conout('TVCLCOB => enviando o email')
	else
		conout('TVCLCOB => nao ha dados para enviar')
	endif

Return

/* -------- MontaHtml -------- */
Method MontaHtml(cTipo, aDados) Class TVCLCOB
	local cMensagem   := "Relação de titulos "
	local cTitulo     := "" //SM0->M0_NOMECOM
	local aCabecalho  := aDados[1]
	local aItens      := aDados[2]
	local cTexto	  := ""
	//local nX          := 0


	if cTipo == "vencidos"

		cTitulo    := "Fatura em aberto"

	Elseif cTipo == "avencer5"

		cTitulo    := "Lembrete de vencimento"

	Elseif cTipo == "avencer0"

		cTitulo    := "Lembrete de vencimento"
	endif


	cMensagem :="<html>"
	cMensagem += '<font size="4" face="arial">'
	cMensagem +="<head>"
	cMensagem +="<title>" + cTitulo + "</title>"
	cMensagem +="</head>"
	cMensagem +="<body>"
	cMensagem +='</br></br>'
	cMensagem +='<center>'
	cMensagem +='<table border="0" width="85%">'

	// titulo
	//cMensagem +="<tr><td><center><h3>"+cTitulo+"</h3></center></td></tr>"
	cMensagem += '<font size="5" face="arial"><b>'
	cMensagem += cTitulo
	cMensagem += "<p>"

	// cabecalho
	//cMensagem += "<tr><td>"
	//cMensagem += '<table border="0" width="100%">'

	//cMensagem += "</table>"
	//cMensagem += "</td></tr>"

	// espaco
	//cMensagem += "<tr><td>&nbsp;</td></tr>"

	// regua horizontal
	//cMensagem += "<tr>"
	//cMensagem += "<td>"
	//cMensagem += '<hr width="100%">'
	//cMensagem += "</td>"
	//cMensagem += "</tr>"

	// espaco
	//cMensagem += "<tr><td>&nbsp;</td></tr>"
/*
	cMensagem += "  <tr>"
	cMensagem += "    <td>"
	if cTipo == "limitePorVendedor"
		cMensagem += "      <h4>" + "Limite de credito" + "</h4>"
	else
		cMensagem += "      <h4>" + "Titulos Vencidos" + "</h4>"
	endif
	cMensagem += "    </td>"
	cMensagem += "  </tr>"
*/
	cTexto += '<font size="4" face="arial">'
	if cTipo == "vencidos"
		cTexto += "Prezado cliente, constam em nossos registros o não pagamento do(s) título(s) abaixo"
			
		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>" + cTexto + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"
	
	ElseIf cTipo == "avencer5" 
		cTexto += "Prezado cliente, viemos lembrá-lo(a) que o(s) título(s) abaixo vence(m) em 5 dias."
	
		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>" + cTexto + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"

	ElseIf cTipo == "avencer0" 
		cTexto += "Prezado cliente, viemos lembrá-lo(a) que o(s) título(s) abaixo vence(m) hoje. "
	
		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>" + cTexto + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"
	endif

	cMensagem += "<tr><td>&nbsp;</td></tr>"

		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>Cliente: " + aCabecalho[1]+"-"+aCabecalho[2] + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"
		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>Nome: " + aCabecalho[3] + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"
	

	cMensagem += "<tr><td>&nbsp;</td></tr>"

	//if cTipo == "vencidos"

		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem +=        MontaTabelaHTML(aItens, .T., "100%")
		cMensagem += "    </td>"
		cMensagem += "  </tr>"

	// espaco
	cMensagem += "<tr><td>&nbsp;</td></tr>"

	cTexto := '<font size="4" face="arial">'
	if cTipo == "vencidos"
		cTexto += "Qualquer dúvida entre em contato pelo telefone (19) 3424-2995, Ramal 127. "
		cTexto += "<p/>"
		cTexto += "Caso o pagamento tenha sido efetuado, por favor desconsidere essa mensagem. "
		cTexto += "<p/>"
		cTexto += "NÃO RESPONDA ESSE E-MAIL."

		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>" + cTexto + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"
	
	ElseIf cTipo == "avencer5" 
		cTexto += "Qualquer dúvida entre em contato pelo telefone (19) 3424-2995, Ramal 127. "
		cTexto += "<p/>"
		cTexto += "Caso o pagamento tenha sido efetuado, por favor desconsidere essa mensagem. "
		cTexto := "<p/>"
		cTexto += "NÃO RESPONDA ESSE E-MAIL."

		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>" + cTexto + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"

	ElseIf cTipo == "avencer0" 
		cTexto += "Qualquer dúvida entre em contato pelo telefone (19) 3424-2995, Ramal 127. "
		cTexto += "<p/>"
		cTexto += "<p/>"
		cTexto += "Caso o pagamento tenha sido efetuado, por favor desconsidere essa mensagem. "
		cTexto += "<p/>"
		cTexto += "NÃO RESPONDA ESSE E-MAIL."

		cMensagem += "  <tr>"
		cMensagem += "    <td>"
		cMensagem += "      <div>" + cTexto + "</div>"
		cMensagem += "    </td>"
		cMensagem += "  </tr>"
	endif

	// regua horizontal
	cMensagem += "<tr><td>"
	cMensagem += '<hr width="100%">'
	cMensagem += "</td></tr>"

	// espaco
	cMensagem += "<tr><td>&nbsp;</td></tr>"

	// fim
	cMensagem +="</table>"
	cMensagem +="</center>"
	cMensagem +="</body>"
	cMensagem +="</html>"

	MemoWrite( "C:\temp\html\layout_" + cTipo +"_"+ aCabecalho[1] + "_" + aCabecalho[2] + ".html", cMensagem )

Return(cMensagem)

Method fEnvMail(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS, lUsaSSL, lSalvaLog) Class TVCLCOB
	Local aArea        := GetArea()
	Local nAtual       := 0
	Local lRet         := .T.
	Local oMsg         := Nil
	Local oSrv         := Nil
	Local nRet         := 0

	Local cFrom        := Alltrim(GetMV("MV_RELACNT")) //SuperGetMv('ZZ_EMLCOB', .f. ,"" ) 		
	Local cUser        := Alltrim(GetMV("MV_RELACNT"))
	Local cSrvFull     := Alltrim(GetMV("MV_RELSERV"))														
	Local cPass        := Alltrim(GetMV("MV_RELPSW"))	
	
	Local lUsaTLS	   	:= GetMV("MV_RELTLS" ,,.T.)
	Local lUsaSSL  		:= GetMV("MV_RELSSL" ,,.T.)
	//Local cRFrom	   	:= GetMV("MV_RELFROM",,"" )

/*
	Local cPasAut     := AllTrim(GetMv("MV_RELAPSW"))	//Senha autenticação
	Local cSMTPServer   := GetMV("MV_RELSERV",,"" )
	Local cSMTPUser		:= GetMV("MV_RELACNT",,"" )
	Local _cFrom	   	:= GetMV("MV_RELFROM",,"" )
	Local cSMTPPass		:= GetMV("MV_RELPSW" ,,"" )
	Local nPort	   		:= GetMV("MV_GCPPORT",,587)
	Local _lTls	   		:= GetMV("MV_RELTLS" ,,.T.)
	Local _lSSl	   		:= GetMV("MV_RELSSL" ,,.T.)
*/

	Local cServer      := Iif(':' $ cSrvFull, SubStr(cSrvFull, 1, At(':', cSrvFull)-1), cSrvFull)
	Local nPort        := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull, At(':', cSrvFull)+1, Len(cSrvFull))), 587)
	Local nTimeOut     := GetMV("MV_RELTIME")
	Local cLog         := ""
	Default cPara      := ""
	Default cAssunto   := ""
	Default cCorpo     := ""
	Default aAnexos    := {}
	Default lMostraLog := .F.
	//Default lUsaTLS    := .T.
	//Default lUsaSSL    := .F.

	//Se tiver em branco o destinatário, o assunto ou o corpo do email
	If Empty(cPara) .Or. Empty(cAssunto) .Or. Empty(cCorpo)
		cLog += "001 - Destinatario, Assunto ou Corpo do e-Mail vazio(s)!" + CRLF
		lRet := .F.
	EndIf

	If lRet
		//Cria a nova mensagem
		oMsg := TMailMessage():New()
		oMsg:Clear()

		//Define os atributos da mensagem
		if Left(cFilAnt,2) == "01"
			cFrom    := 'cobranca.noreply@terraverdeagro.com.br'
			cUser    := 'cobranca.noreply@terraverdeagro.com.br'  
			cPass    := 'Terra#10@@*68'
		elseIf Left(cFilAnt,2) == "02"
			cUser    := 'cobranca.noreply@terraverderental.com.br'
			cFrom    := 'cobranca.noreply@terraverderental.com.br'
			cPass    := 'Terra#10@@*68'			
		endif

		oMsg:cFrom    := cFrom
		
		//PARA TESTES - ini
		//cpara :="denis.guedes@obify.com.br"
		//PARA TESTES - fim

		oMsg:cTo      := cPara
				
		oMsg:cSubject := cAssunto
		oMsg:cBody    := cCorpo

		//Percorre os anexos
		For nAtual := 1 To Len(aAnexos)
			//Se o arquivo existir
			If File(aAnexos[nAtual])

				//Anexa o arquivo na mensagem de e-Mail
				nRet := oMsg:AttachFile(aAnexos[nAtual])
				If nRet < 0
					cLog += "002 - Nao foi possivel anexar o arquivo '"+aAnexos[nAtual]+"'!" + CRLF
				EndIf

				//Senao, acrescenta no log
			Else
				cLog += "003 - Arquivo '"+aAnexos[nAtual]+"' nao encontrado!" + CRLF
			EndIf
		Next

		//Cria servidor para disparo do e-Mail
		oSrv := tMailManager():New()

		//Define se irá utilizar o TLS
		If lUsaTLS
			oSrv:SetUseTLS(.T.)
		EndIf

		If lUsaSSL
			oSrv:SetUseSSL(.T.)
		EndIf

		//Inicializa conexão
		nRet := oSrv:Init("", cServer, cUser, cPass, 0, nPort)
		
		If nRet != 0
			cLog += "004 - Nao foi possivel inicializar o servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
			lRet := .F.
		EndIf

		If lRet
			//Define o time out
			nRet := oSrv:SetSMTPTimeout(nTimeOut)
			If nRet != 0
				cLog += "005 - Nao foi possivel definir o TimeOut '"+cValToChar(nTimeOut)+"'" + CRLF
			EndIf

			//Conecta no servidor
			nRet := oSrv:SMTPConnect()
			If nRet <> 0
				cLog += "006 - Nao foi possivel conectar no servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
				lRet := .F.
			EndIf

			If lRet
				
				//Realiza a autenticação do usuário e senha
				nRet := oSrv:SmtpAuth(cFrom, cPass)
				
				If nRet <> 0
					cLog += "007 - Nao foi possivel autenticar no servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
					lRet := .F.
				EndIf

				If lRet
					//Envia a mensagem
					nRet := oMsg:Send(oSrv)
					
					If nRet <> 0
						cLog += "008 - Nao foi possivel enviar a mensagem: " + oSrv:GetErrorString(nRet) + CRLF
						conout( "008 - Nao enviou o e-mail.", oSrv:GetErrorString( nRet ) )
						lRet := .F.
					EndIf
				EndIf

				//Disconecta do servidor
				nRet := oSrv:SMTPDisconnect()
				If nRet <> 0
					cLog += "009 - Nao foi possivel disconectar do servidor SMTP: " + oSrv:GetErrorString(nRet) + CRLF
				EndIf
			EndIf
		EndIf
	EndIf

	//Se tiver log de avisos/erros
	If !Empty(cLog)
		cLog := "fEnvMail - "+dToC(Date())+ " " + Time() + CRLF + ;
			"Funcao - " + FunName() + CRLF + CRLF +;
			"Existem mensagens de aviso: "+ CRLF +;
			cLog
		ConOut(cLog)

		//Se for para mostrar o log visualmente e for processo com interface com o usuário, mostra uma mensagem na tela
		If lMostraLog .And. ! IsBlind()
			Aviso("Log", cLog, {"Ok"}, 2)
		else
			If lSalvaLog
				MEMOWRITE("c:\temp\FalhaEnvEMailCob"+dtoc(date())+date()=".txt", cQuery)
			EndIf
		EndIf
	EndIf

	RestArea(aArea)
Return lRet

/* -------- Metos Get e Set -------- */
Method setTitulos(aParam) Class TVCLCOB
	::aDadosTitulos := aParam
return

Method getTitulos() Class TVCLCOB
	local aRet := ::aDadosTitulos
return(aRet)
