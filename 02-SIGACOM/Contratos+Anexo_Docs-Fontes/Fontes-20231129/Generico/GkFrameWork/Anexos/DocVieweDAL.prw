#include "TOTVS.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} DocViewerDAL
Metodo para visualizar o documento
@type class 
@version 1.0  
@author Geeker Company
@since 19/06/2021
/*/
Class DocViewerDAL From LongClassName
    
    Data cTipo
    Data cChave

    Method new() constructor
    Method Carregar()
    Method Adicionar()
    Method Editar()
    Method Excluir()
    Method Filial()
    Method Sequencial()
    Method Destino()

EndClass

/*/{Protheus.doc} New
Metodo construtor
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021  
/*/
Method New(cTipo, cChave) Class DocViewerDAL
    Default cTipo  := ""
    Default cChave := ""

    ::cTipo     := cTipo
    ::cChave    := cChave
Return self

/*/{Protheus.doc} Carregar
Metodo para carregar os registros
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Carregar(cTipo, cChave) class DocViewerDAL
    Local cAlias := GetNextAlias()

    cTipo  := PadR(cTipo, TamSX3("ZG9_TP")[01])
    cChave := PadR(cChave, TamSX3("ZG9_CHAVE")[01])

    BeginSql Alias cAlias
        Column DTCRIACAO AS DATE
		SELECT
            ZG9_TITULO  TITULO,
            ZG9_OBS     OBSERVACAO,
            ZG9_ANEXO   ANEXO,
            ZG9_DTCRI   DTCRIACAO,
            ZG9_USR     CRIADOR,
            ZG9_ID      ID,
            ZG9_DIRET   DIRETORIO,
            ZG9_ARQUIV  ARQUIVO
        FROM
            %table:ZG9% ZG9
        WHERE
            ZG9.ZG9_FILIAL  = %xFilial:ZG9% AND
            ZG9.ZG9_TP      = %Exp:cTipo% AND
            ZG9.ZG9_CHAVE   = %Exp:cChave% AND
            ZG9.%notDel%    
        ORDER BY DTCRIACAO ASC
	EndSql
Return cAlias

/*/{Protheus.doc} Adicionar
Metodo para adicionar os registros
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Adicionar(__cFilial, cTipo, cChave, cTitulo, cObservacao, cAnexo, dDate, cCriador, cDiretorio, cArquivo) Class DocViewerDAL
    Local cId := ::Sequencial(cTipo, cChave)
    
    ZG9->(RecLock("ZG9", .T.))
    ZG9->ZG9_FILIAL := __cFilial
    ZG9->ZG9_TP     := cTipo
    ZG9->ZG9_CHAVE  := cChave
    ZG9->ZG9_TITULO := cTitulo
    ZG9->ZG9_OBS    := cObservacao
    ZG9->ZG9_ANEXO  := cAnexo
    ZG9->ZG9_DTCRI  := dDate
    ZG9->ZG9_USR    := cCriador
    ZG9->ZG9_ID     := cId
    ZG9->ZG9_DIRET  := cDiretorio
    ZG9->ZG9_ARQUIV := cArquivo
    ZG9->(MsUnLock())
Return cId

/*/{Protheus.doc} Editar
Metodo para editar os registros
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Editar(__cFilial, cTipo, cChave, cId, cTitulo, cObservacao) Class DocViewerDAL
    cId	        := PadR(cId, TamSX3("ZG9_ID")[01])
    cTipo       := PadR(cTipo, TamSX3("ZG9_TP")[01])
    cChave      := PadR(cChave, TamSX3("ZG9_CHAVE")[01])

    DbSelectArea("ZG9")
    DbSetOrder(2)
    If DbSeek(__cFilial + cTipo + cChave + cId)
        RecLock("ZG9", .F.)
        ZG9->ZG9_TITULO := cTitulo
        ZG9->ZG9_OBS    := cObservacao
        MsUnLock()
    EndIf
Return Nil

/*/{Protheus.doc} Excluir
Metodo para excluir os registros
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Excluir(__cFilial, cTipo, cChave, cId) Class DocViewerDAL
    cId	    := PadR(cId, TamSX3("ZG9_ID")[01])
    cTipo   := PadR(cTipo, TamSX3("ZG9_TP")[01])
    cChave  := PadR(cChave, TamSX3("ZG9_CHAVE")[01])

    DbSelectArea("ZG9")
    DbSetOrder(2)
    If DbSeek(__cFilial + cTipo + cChave + cId)
        RecLock("ZG9", .F.)
        DbDelete()
        MsUnLock()
    EndIf
Return Nil

/*/{Protheus.doc} Sequencial
Metodo para retonar o sequencial
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Sequencial() Class DocViewerDAL
    Local cSequencial := GetSxeNum("ZG9", "ZG9_ID")
    ConfirmSX8()
Return cSequencial

/*/{Protheus.doc} Filial
Metodo para retornar a filial
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Filial() Class DocViewerDAL
Return xFilial("ZG9")

/*/{Protheus.doc} Destino
Metodo para retornar o destino
@type method
@version 1.0
@author Geeker Company
@since 19/06/2021
/*/
Method Destino() Class DocViewerDAL
Return "\anexos"
