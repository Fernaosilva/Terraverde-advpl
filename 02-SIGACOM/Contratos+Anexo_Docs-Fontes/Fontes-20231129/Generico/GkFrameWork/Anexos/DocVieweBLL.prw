#include "TOTVS.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} DocViewerBLL
Metodo para visualizar o documento
@type class 
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Class DocViewerBLL From LongClassName

	Data oDocViewerDAL

	Method new() constructor
	Method Carregar()
	Method Adicionar()   
	Method Editar()
	Method Salvar()
	Method Excluir()
	Method Cores()
	Method Destino()
	Method ArquivoServidor()
	Method NomeArquivo()

EndClass

/*/{Protheus.doc} New  
Metodo construtor
@type method   
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method New() Class DocViewerBLL
	::oDocViewerDAL := DocViewerDAL():New()
Return self

/*/{Protheus.doc} Carregar
Metodo para carregar
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Carregar(cTipo, cChave) Class DocViewerBLL
	Local aArea		:= GetArea()
	Local cAlias    := ::oDocViewerDAL:Carregar(cTipo, cChave)
	Local aLista    := {}

	// Adiciono o registro na lista de registros
	While !(cAlias)->(EoF())
		Aadd(aLista, {;
			(cAlias)->TITULO,;
			(cAlias)->OBSERVACAO,;
			(cAlias)->ANEXO,;
			(cAlias)->DTCRIACAO,;
			(cAlias)->CRIADOR,;
			(cAlias)->ID,;
			(cAlias)->DIRETORIO,;
			(cAlias)->ARQUIVO;
			})
		(cAlias)->(DbSkip())
	EndDo

	// Liberar o ambiente dos registros
	(cAlias)->(DbCloseArea())

	// Restaurar o ambiente em aberto
	RestArea(aArea)
Return aLista

/*/{Protheus.doc} Adicionar
Metodo para adicionar os arquivos
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Adicionar(cTipo, cChave, cTitulo, cObservacao, cAnexo) Class DocViewerBLL
	Local __cFilial     := ::oDocViewerDAL:Filial()
	Local cDiretorio	:= Left(cAnexo, RAt("\", cAnexo))
	Local cArquivo		:= SubStr(cAnexo, RAt("\", cAnexo) + 1)
    Local dDate         := Date()
    Local cCriador      := cUserName
	Local cId
	
	cId := ::oDocViewerDAL:Adicionar(__cFilial, cTipo, cChave, cTitulo, cObservacao, cAnexo, dDate, cCriador, cDiretorio, cArquivo)

	// Renomeio o arquivo no diretorio para evitar sobrescrita
	FRename(cAnexo, ::ArquivoServidor(cArquivo, cDiretorio, cId),/*nParam3*/,.T.)
Return Nil

/*/{Protheus.doc} Editar
Metodo para editar o arquivo
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Editar(cTipo, cChave, cId, cTitulo, cObservacao) Class DocViewerBLL
	Local __cFilial		:= ::oDocViewerDAL:Filial()
	::oDocViewerDAL:Editar(__cFilial, cTipo, cChave, cId, cTitulo, cObservacao)
Return Nil

/*/{Protheus.doc} Salvar
Metodo para salvar um arquivinho
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Salvar(cArquivo, cDiretorio, cDestino, cTipo, cChave, cId) Class DocViewerBLL
	local cMsgAlert   := ""
	local lGravaArq   := .T.
	Local lDeServidor := SubStr(Alltrim(cDiretorio), 1, 1) == "\"
	Local aDir        := StrTokArr(Alltrim(cDestino), "\")
	Local cDir        := ""
	Local cOrigem     := StrTran( cDiretorio + "\" + cArquivo, "\\", "\" )

	AEval(aDir, {|x| (cDir += x + "\", MakeDir(Alltrim(cDir)))})

	If lDeServidor
		//MsgInfo("De Servidor para Destino")
		cOrigem := ::ArquivoServidor(cArquivo, cDiretorio, cId)
		lSalvo := CpyS2T(cOrigem, cDestino, .T.)
	Else
		//MsgInfo("De Terminal para Servidor")
		if File(cDestino+"\"+cArquivo)
			cMsgAlert += OemToAnsi("Arquivo já existe no Servidor Protheus ...")+cDestino+"\"+cArquivo +CRLF
			cMsgAlert += OemToAnsi("Deseja regravar por cima do arquivo antigo?")
			
			if !MsgYesNo(cMsgAlert,OemToAnsi("[TerraVerde] Atenção!"))
				lSalvo    := .F.
				lGravaArq := .F.
			endif
		endif
		if lGravaArq
			lSalvo := CpyT2S(cOrigem, cDestino, .T.)
		endif
	endif

Return Iif(lSalvo, 0, FError())

/*/{Protheus.doc} Excluir
Metodo para excluir o documento
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Excluir(cTipo, cChave, cId, cArquivo, cDiretorio, cId) Class DocViewerBLL
	Local __cFilial		:= ::oDocViewerDAL:Filial()
	Local nArquivo		:= FErase(::ArquivoServidor(cArquivo, cDiretorio, cId), /*xParam*/, .T.)
	
	If nArquivo == 0
		::oDocViewerDAL:Excluir(__cFilial, cTipo, cChave, cId)
	EndIf

Return If(nArquivo == 0, nArquivo, FError())

/*/{Protheus.doc} Destino
Retorna o nome no destinatario
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Destino(cDestino, cTipo, cChave) Class DocViewerBLL
	local cRet := ""
	Default cDestino := ""

	if Len(cDestino) > 0
		cRet := cDestino
	else
		cRet := ::oDocViewerDAL:Destino()
		// cRet += iif(Right(cRet,1)<>"\","\","")+cTipo
		// cRet += iif(Right(cRet,1)<>"\","\","")+cChave
	endif
Return cRet

/*/{Protheus.doc} ArquivoServidor
Retornar o nome no servidor
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method ArquivoServidor(cArquivo, cDiretorio, cId) Class DocViewerBLL
	If Right(cDiretorio, 1) <> "\"
		cDiretorio += "\"
	EndIf
Return cDiretorio + ::NomeArquivo(cArquivo, cId)

/*/{Protheus.doc} NomeArquivo
Retorna o nome do arquivo
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method NomeArquivo(cArquivo, cId) Class DocViewerBLL
	Local cNomeArq, cExtensao
	cArquivo		:= AllTrim(cArquivo)
	cNomeArq		:= Left(AllTrim(cArquivo), RAt(".", cArquivo) - 1)
	cExtensao		:= Lower(SubStr(AllTrim(cArquivo), RAt(".", cArquivo) + 1))
Return cNomeArq + "." + cExtensao
