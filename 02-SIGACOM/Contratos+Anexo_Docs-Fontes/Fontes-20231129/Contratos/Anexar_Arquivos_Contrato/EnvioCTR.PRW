#include "protheus.ch"
#include "parmtype.ch"

/*/{Protheus.doc} EnvioCTR
Possibilita o envio por e-mail dos documentos atrelados ao contrato.
@type function
@version P12
@author Geeker Company
@since 14/09/2023
@return variant, Nil
/*/
User function EnvioCTR()
	Local __cFilial		AS CHARACTER
	Local cContra		AS CHARACTER
	Local cRevisa		AS CHARACTER
	Local cCompet		AS CHARACTER	
	Local cNumMed		AS CHARACTER	

	Local aAreaCN9		AS ARRAY
	Local oDocSend		AS OBJECT
	Local oDocViewer	AS OBJECT
	Local lSendMail		AS LOGICAL

	local cNomEmp := "["+Capital(Substr(SM0->M0_NOMECOM,1,AT(" ",SM0->M0_NOMECOM)-1))+"] "

	__cFilial	:= CND->CND_FILIAL
	cContra		:= CND->CND_CONTRA
	cRevisa		:= CND->CND_REVISA
	cCompet		:= CND->CND_COMPET
	cNumMed		:= CND->CND_NUMMED
	
	lSendMail	:= .F.

	oDocSend	:= TDocSend():New(__cFilial,cContra,cRevisa,cCompet,'CT',cNumMed)
	
	// Se não possuir anexos vinculados à chave informada
	// pergunta ao usuário se deseja anexar arquivos.
	If Empty(oDocSend:aDocs)

		If MsgNoYes("Nenhum anexo vinculado ao contrato! Deseja anexar arquivos?", OemToAnsi(cNomEmp+"Atenção!"))
			aAreaCN9 := CN9->(GetArea())
			CN9->(DbSetOrder(1))		// CN9_FILIAL+CN9_NUMERO+CN9_REVISA
			If CN9->(DbSeek(__cFilial+cContra+cRevisa))

				// chamo a tela de anexar arquivos.
				oDocViewer := DocViewer():new()
				oDocViewer:lModify	:= .F.

				//-Sintaxe Start(cTipo,cChave,cTitulo,nLimite, cCompet,cDocCpo,cIniDtCpo,cFimDtCpo,cF3Doc) Class DocViewer
				oDocViewer:Start(oDocSend:cTipo,oDocSend:cChave,"Anexos do Contrato",, oDocSend:cCompet,"CN9->CN9_NUMERO")

				// após o término elimino da memória.
				FreeObj(oDocViewer)

				oDocViewer := Nil
				// efetuo uma nova checagem de anexos.
				oDocSend:Carregar_Docs()
				// se ainda assim retornar vazio, não prossegue.
				If !Empty(oDocSend:aDocs)
					lSendMail	:= .T.
				EndIf
			EndIf
			RestArea(aAreaCN9)
		EndIf
	Else
		lSendMail	:= .T.
	EndIf

	If lSendMail
		oDocSend:Send()
	EndIf

	oDocSend	:= Nil
	FreeObj(oDocSend)

Return Nil


Class TDocSend from LongClassName

	PUBLIC Data oDocViewerBLL	AS OBJECT

	PUBLIC Data cTipo			AS CHARACTER
	PUBLIC Data cChave			AS CHARACTER
	PUBLIC Data cCompet			AS CHARACTER
	PUBLIC Data cClassName		AS CHARACTER
	PUBLIC Data __cFilial		AS CHARACTER
	PUBLIC Data cContrato		AS CHARACTER
	PUBLIC Data cRevisao		AS CHARACTER
	PUBLIC Data cNumMed			AS CHARACTER
	PUBLIC Data aDocs			AS ARRAY

	PUBLIC Method New() Constructor
	PUBLIC Method Carregar_Docs()
	PUBLIC Method Send()
	PUBLIC Method Send_Mail()

EndClass

Method New(__cFilial,cContrato,cRevisao,cCompet,cTipo,cNumMed) Class TDocSend
	
	PARAMTYPE 0 VAR __cFilial	AS CHARACTER
	PARAMTYPE 1 VAR cContrato	AS CHARACTER
	PARAMTYPE 2 VAR cRevisao	AS CHARACTER
	PARAMTYPE 3 VAR cCompet		AS CHARACTER
	PARAMTYPE 4 VAR cTipo		AS CHARACTER
	PARAMTYPE 5 VAR cNumMed		AS CHARACTER

	::__cFilial		:= __cFilial
	::cContrato		:= cContrato
	::cRevisao		:= cRevisao

	::oDocViewerBLL	:= DocViewerBLL():New()
	::cTipo			:= cTipo
	::cNumMed		:= cNumMed
	::cChave		:= ::__cFilial+'|'+::cContrato+'|'+::cRevisao
	::cCompet		:= cCompet
	::cClassName	:= 'TDocSend'
	::aDocs			:= {}
	
	// Carrega a lista de documentos em aDocs
	::Carregar_Docs()
Return Nil


Method Carregar_Docs() Class TDocSend
	Local cChaveAux := ::cChave+'|'+StrTran(::cCompet,'/','')
	::aDocs	:= ::oDocViewerBLL:Carregar(::cTipo,cChaveAux)
Return Nil


Method Send() Class TDocSend
	Local aPergs     as ARRAY
	Local cRecipient as CHARACTER
	local cNomEmp := "["+Capital(Substr(SM0->M0_NOMECOM,1,AT(" ",SM0->M0_NOMECOM)-1))+"] "

	aPergs		:= {}
	cRecipient	:= SuperGetMV("ZZ_XMAILAN",.T.,"Contasti@terraverdeagro.com.BR")

	AAdd(aPergs ,{01,"Email Copia"  , Space(250),"@!","","",".T.",120,.F.})
    AAdd(aPergs ,{01,"Destinatário" , cRecipient,"","","",".F.",120,.T.})

    AAdd(aPergs ,{11,"Observações"     , "",".T.",".T.",.F.})
	
	If ParamBox(aPergs,"Enviar Documentos",,,,,,,,,.F.,.F.)

		If MsgNoYes("Confirma o envio de e-mail?", OemToAnsi(cNomEmp+"Atenção!"))
			FWMsgRun(,{|| ::Send_Mail(Alltrim(MV_PAR01),Alltrim(MV_PAR02),MV_PAR03)},"Enviando Email","Aguarde... enviando email...")
		EndIf
	EndIf
Return Nil


Method Send_Mail(cBCC,cToMail,cObs) Class TDocSend
	Local oEnviaMail	AS OBJECT
	Local cAliasQry		AS CHARACTER
	Local __cFilial		AS CHARACTER
	Local cContrato		AS CHARACTER
	Local cRevisao		AS CHARACTER
	Local cCompet		AS CHARACTER
	Local cNumMed		AS CHARACTER
	Local cCorpo		AS CHARACTER
	Local cFile			AS CHARACTER
	Local nX			AS NUMERIC

	PARAMTYPE 0 VAR cBCC		AS CHARACTER	OPTIONAL DEFAULT ''
	PARAMTYPE 1 VAR cToMail		AS CHARACTER	
	PARAMTYPE 2 VAR cObs		AS CHARACTER	OPTIONAL DEFAULT ''

	__cFilial	:= ::__cFilial
	cContrato	:= ::cContrato
	cRevisao	:= ::cRevisao
	cCompet		:= ::cCompet
	cNumMed		:= ::cNumMed

	cAliasQry	:= GetNextAlias()
	
	// carrego as informações do e-mail
	BEGINSQL ALIAS cAliasQry

		COLUMN CN9_DTINIC	AS DATE
		COLUMN CN9_DTFIM	AS DATE
		COLUMN CND_DTFIM	AS DATE

		SELECT	A2_COD,A2_LOJA,A2_NOME,CN9_NUMERO,CN9_TPCTO,
				CN1_DESCRI,CN9_DTINIC,CN9_DTFIM,
				CND_NUMMED,CND_VLTOT,CND_DTFIM,
				ISNULL(CXJ_NUMPED,'') CXJ_NUMPED
		FROM %TABLE:CND% CND (NOLOCK) 
		INNER JOIN %TABLE:CN9% CN9 (NOLOCK) ON CN9.%NOTDEL% AND CN9_FILIAL = CND_FILCTR AND CN9_NUMERO = CND_CONTRA AND CN9_REVISA = CND_REVISA 
		INNER JOIN %TABLE:CN1% CN1 (NOLOCK) ON CN1.%NOTDEL% AND CN1_CODIGO = CN9_TPCTO AND CN1_FILIAL = %EXP:FWXFILIAL("CN1")%
		INNER JOIN %TABLE:CNC% CNC (NOLOCK) ON CNC.%NOTDEL% AND CNC_FILIAL = CN9_FILIAL AND CNC_NUMERO = CN9_NUMERO AND CNC_REVISA = CN9_REVISA 
		INNER JOIN %TABLE:SA2% SA2 (NOLOCK) ON SA2.%NOTDEL% AND A2_COD = CNC_CODIGO AND A2_LOJA = CNC_LOJA AND A2_FILIAL = %EXP:FWXFILIAL("SA2")%
		LEFT  JOIN %TABLE:CXJ% CXJ (NOLOCK) ON CXJ.%NOTDEL% AND CXJ_FILIAL = CND_FILIAL AND CXJ_CONTRA = CND_CONTRA AND CXJ_NUMMED = CND_NUMMED 
		WHERE CND.%NOTDEL% AND CND_FILIAL = %EXP:__cFilial% 
			AND CND_CONTRA = %EXP:cContrato% AND CND_REVISA = %EXP:cRevisao% 
			AND CND_COMPET = %EXP:cCompet% AND CND_NUMMED = %EXP:cNumMed% 

	ENDSQL

	cAssunto := "MEDIÇÃO DO CONTRATO - COMPETÊNCIA " + cCompet + " CONTRATO N " + cContrato + " MEDICAO " + (cAliasQry)->CND_NUMMED + " FORNECEDOR " + (cAliasQry)->A2_COD

	// montagem do corpo do e-mail.
	cCorpo	:= "<p><b>Dados do Fornecedor</b></p>" + CRLF
	cCorpo	+= "<p><b>Cod. Fornecedor: </b>"+(cAliasQry)->A2_COD+'/'+(cAliasQry)->A2_LOJA+"</p>" + CRLF
	cCorpo	+= "<p><b>Nome Fornecedor: </b>"+Upper(AllTrim((cAliasQry)->A2_NOME))+"</p>" + CRLF
	cCorpo	+= "<br>" + CRLF
	cCorpo	+= "<p><b>Dados do Contrato</b></p>" + CRLF
	cCorpo	+= "<p><b>Número do Contrato: </b>"+(cAliasQry)->CN9_NUMERO+"</p>" + CRLF
	cCorpo	+= "<p><b>Tipo de Contrato: </b>"+(cAliasQry)->CN9_TPCTO+'-'+Upper(AllTrim((cAliasQry)->CN1_DESCRI))+"</p>" + CRLF
	cCorpo	+= "<p><b>Data Final do Contrato: </b>"+DtoC((cAliasQry)->CN9_DTFIM)+"</p>" + CRLF
	cCorpo	+= "<p><b>Data Inicial do Contrato: </b>"+DtoC((cAliasQry)->CN9_DTINIC)+"</p>" + CRLF
	cCorpo	+= "<br>" + CRLF
	cCorpo	+= "<p><b>Data da Medição</b></p>" + CRLF
	cCorpo	+= "<p><b>Número da Medição: </b>"+(cAliasQry)->CND_NUMMED+"</p>" + CRLF
	cCorpo	+= "<p><b>Valor da Medição: </b>"+AllTrim(Transform((cAliasQry)->CND_VLTOT,"@e 999,999,999.99"))+"</p>" + CRLF
	cCorpo	+= "<p><b>Data da Medição: </b>"+DtoC((cAliasQry)->CND_DTFIM)+"</p>" + CRLF
	cCorpo	+= "<p><b>Número do Pedido: </b>"+(cAliasQry)->CXJ_NUMPED+"</p>" + CRLF
	cCorpo	+= "<br>" + CRLF
	cCorpo	+= "<p><b>Observações: </b>"+cObs+"</p>"

	// montagem dos anexos do e-mail.
	cFile	:= ''
	For nX := 1 To Len(::aDocs)
		cFile += AllTrim(::aDocs[nX][3])
		If nX < Len(::aDocs)
			cFile += ';'
		EndIf
	Next nX

	oEnviaMail	:= EnviaMail():New()
	oEnviaMail:EnviaEmail(cCorpo,cAssunto,cToMail,cFile,,,cBCC)

	oEnviaMail	:= Nil
	FreeObj(oEnviaMail)

Return Nil
