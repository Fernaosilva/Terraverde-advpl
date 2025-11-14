#include 'totvs.ch'

/*/{Protheus.doc} GERREMFIM
Ponto de entrada depois da geração da NF
Ponto de entrada utilizado para gravação da classe valor nas tabelas SC6 e SD2
@Processo Gera NF de remessa
@author  Rodrigo Machado
@since   30/07/2024
*/
User Function GERREMFIM()
    local aSC5          := PARAMIXB[3]
    local aSC6          := PARAMIXB[4]
    local nPosPed       := aScan(aSC5, {|x| Alltrim(x[1]) == 'C5_NUM'})
    local nPosItem      := ""
    local cPedido       := aSC5[nPosPed][2]
    local cItem         := ""
    local aArea         := Lj7GetArea({"SC6","SD2",'FPA'})
    local aAreaSC6      := GetArea()
    local cClasseVlr    := FPA->FPA_ZZCLVL
    local cFilProje     := FPA->FPA_FILIAL
    local cProjeto      := FPA->FPA_PROJET
    local nI            := 0

    //Percorre os itens do pedido de venda
    For nI := 1 to Len(aSC6)
        SC6->(DbGoTop())
        SD2->(DbGoTop())
        //pega o item atual do pedido de venda
        nPosItem := aScan(aSC6[nI], {|x| Alltrim(x[1]) == 'C6_ITEM'})
        cItem   := aSC6[nI][nPosItem][2]

        cClasseVlr := getCLVL(cFilProje,cProjeto,cPedido,cItem)
        //Posiciona na tabela de pedido de vendas SC6 e efetua a gravação
        //da classe valor no campo C6_CLVL
        if SC6->(dbSeek(xFilial("SC6") + cPedido + cItem))
            Reclock("SC6", .F.)
                SC6->C6_CLVL := cClasseVlr
            SC6->(MsUnlock())
        Endif

        //Efetua a gravação da classe valor no campo D2_CLVL
        SD2->(DbSetOrder(8))
        if SD2->(dbSeek(xFilial("SD2") + cPedido + cItem))
            Reclock("SD2", .F.)
                SD2->D2_CLVL := cClasseVlr 
            SD2->(MSUnlock())
        endif

    Next nI

    RestArea(aAreaSC6)
    Lj7RestArea(aArea)
Return


Static Function getCLVL(cFilProje,cProjeto,cPedido,cItem)
    local cRet := ''

    FPA->(DbSetOrder(1))
    FPA->(DbGoTop())
    if FPA->(DbSeek(cFilProje+cProjeto))
        while FPA->(!EOF()) .AND. cFilProje+cProjeto == FPA->(FPA_FILIAL+FPA_PROJET)
            if cPedido == FPA->FPA_PEDIDO .AND. cItem == FPA->FPA_ITEREM
                cRet := FPA->FPA_ZZCLVL
            endif
            FPA->(DbSkip())
        enddo
    endif
Return cRet
