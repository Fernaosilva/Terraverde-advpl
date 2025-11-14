#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} LCJLFCAB
Manutenção de campos no cabeçalho e itens, antes da geração do pedido de vendas no faturamento automático.
Ponto de entrada utilizado para incluir o campo C6_CLVL com o valor de FPA_ZZCLVL no array de itens do pedido de venda
@Processo Faturamento Automático
@author  Rodrigo Machado
@since   30/07/2024
*/
User Function LCJLFCAB()
    local aDados    := {}
    local cIdent    := ""
    local nI        := 0
    local cFilProje := ''
    local cProjeto  := ''
    local cAsProj   := ''
    local nCLVL     := 0
    aDados          := PARAMIXB[1]
    cIdent          := PARAMIXB[2]

    If cIdent == "I"
        //Percorre os itens do pedido de venda
        For nI := 1 to Len(aDados)

            cFilProje := xFilial('FPA')
            //Tratamento para faturamento de custos extras
            if len(_AASS) > 0
                cProjeto  := _AASS[nI][1]
                cAsProj   := _AASS[nI][2]
            else
                cProjeto  := FPA->FPA_PROJET 
                cAsProj   := FPA->FPA_AS
            endif 

            nCLVL := getCLVL(cFilProje,cProjeto,cAsProj)
            //Adiciona no array de itens do pedido de venda o campo C6_CLVL com o valor de campo FPA_ZZCLVL (Classe Valor)
            aadd(aDados[nI], {'C6_CLVL', nCLVL, NIL})
        Next nI
    Endif
Return aDados


Static Function getCLVL(cFilProje,cProjeto,cAsProj)
    local cRet := ''

    FPA->(DbSetOrder(1))
    FPA->(DbGoTop())
    if FPA->(DbSeek(cFilProje+cProjeto))
        while FPA->(!EOF()) .AND. cFilProje+cProjeto == FPA->(FPA_FILIAL+FPA_PROJET)
            if cAsProj == FPA->FPA_AS
                cRet := FPA->FPA_ZZCLVL
            endif
            FPA->(DbSkip())
        enddo
    endif
Return cRet
