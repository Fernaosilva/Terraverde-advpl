#Include 'Protheus.ch'
// _________________________________________________________________________________________________
//|Quando se referir aos complementos para geracao dos registros C110, C111, C112, C113, C114 e C115|
//|  a tabela CDT também deve ser alimentada, pois ela que efetua o relacionamentos com as outras   |
//|  conforme registro. C110 = Tab. CDT, C111 = Tab. CDG, , C112 = Tab. CDC, C113 = Tab. CDD,       |
//|  C114 = Tab. CDE e C115 = Tab. CDF                                                              |
//| Este PONTO DE ENTRADA é apenas um exemplo de como pode ser utilizado, deve ser adequado conforme|
//| a regra de negócio específica do cliente                                                        | 
//|_________________________________________________________________________________________________|*/
User Function MATUCOMP()
     
    Local lInclui   := .F.
    Local cEntSai   := ParamIXB[1] // E=Entrada ou S=Saida
    Local cSerie    := ParamIXB[2] // Serie do documento fiscal
    Local cDoc      := ParamIXB[3] // Numero do documento
    Local cCliefor  := ParamIXB[4] // Cliente/Fornecedor
    Local cLoja     := ParamIXB[5] // Loja do Cliente/Fornecedor
    Local lDeleta   := !Inclui .AND. !Altera



    // customizações do cliente, deve ser adequadas as regras do cliente
    If !lDeleta
     
        lInclui := !CD6->(dbSeek(xFilial("CD6")+cEntSai+cDoc+cSerie+cClieFor+cLoja))
 
        RecLock("CD6",lInclui)
            CD6->CD6_FILIAL := xFilial("CD6")
            CD6->CD6_TPMOV  := cEntSai
            CD6->CD6_DOC    := cDoc
            CD6->CD6_SERIE  := cSerie
            CD6->CD6_CLIFOR := cClieFor
            CD6->CD6_LOJA   := cLoja
            CD6->CD6_CODANP := ''// Vem do produto
            CD6->CD6_HORA   := ''//PEGAR HORA
            CD6->CD6_VOLUME := ''//PEGAR VOLUME DA NOTA
            CD6->CD6_VCIDE  := '0,01'


        CD6->(MsUnLock())
 
    Else
         
        If CD6->(dbSeek(xFilial("CD6")+cEntSai+cDoc+cSerie+cClieFor+cLoja))
            RecLock("CDT",.F.)
            CD6->(DbDelete())
            CD6->(MsUnLock())
        EndIf
         
    EndIf
 
Return
