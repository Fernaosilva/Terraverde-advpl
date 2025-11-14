#include 'totvs.ch'
#include 'topconn.ch'

User Function LCJLFFIM()
    

    Local cQuery := ""
    Local cCodFil := xFilial('SC6')
    Local cNum    := sc6->C6_NUM
    Local cItem   := ""
    Local cZZCLVL := ""
    Local cProjet := FPA->FPA_PROJET
    Local nRecno  := 0

    dbSelectArea("SC6")
    dBsetorder(1)
    SC6->(DbGoTop())
    DbSeek(cCodFil + cNum)

    While !SC6->(Eof()) .AND. SC6->C6_FILIAL + SC6->C6_NUM == cCodFil + cNum

        // Captura os dados necessários para montar a query
        cItem   := AllTrim(SC6->C6_ITEM)
        cCodFil := AllTrim(SC6->C6_FILIAL)
        // Monta a query específica para o item atual
        cQuery := ""
        cQuery += "SELECT FPA.FPA_ZZCLVL " + CRLF
        cQuery += "FROM FPZ010 FPZ " + CRLF
        cQuery += "INNER JOIN SC6010 SC6 ON " + CRLF
        cQuery += "    FPZ.FPZ_FILIAL = SC6.C6_FILIAL AND " + CRLF
        cQuery += "    FPZ.D_E_L_E_T_ = ' ' AND " + CRLF
        cQuery += "    FPZ.FPZ_PEDVEN = SC6.C6_NUM AND " + CRLF
        cQuery += "    FPZ.FPZ_ITEM = SC6.C6_ITEM " + CRLF
        cQuery += "INNER JOIN FPA010 FPA ON " + CRLF
        cQuery += "    FPZ.FPZ_FILIAL = FPA.FPA_FILIAL AND " + CRLF
        cQuery += "    FPZ.FPZ_PROJET = FPA.FPA_PROJET AND " + CRLF
        cQuery += "    FPZ.FPZ_AS = FPA.FPA_AS " + CRLF
        cQuery += "WHERE " + CRLF
        cQuery += "    FPZ.FPZ_PROJET = '" + cProjet + "' AND " + CRLF
        cQuery += "    SC6.C6_FILIAL = '" + cCodFil + "' AND " + CRLF
        cQuery += "    SC6.C6_NUM = '" + cNum + "' AND " + CRLF
        cQuery += "    SC6.C6_ITEM = '" + cItem + "'"

        // Executa a query
        TcQuery cQuery New Alias "FPAQRY"

        // Se retornar resultado, atualiza o campo C6_CLVL
        dbSelectArea("FPAQRY")
        DbGoTo(1)
        While FPAQRY->(!Eof()) 
            cZZCLVL := FPAQRY->FPA_ZZCLVL

            nRecno := SC6->(Recno())
            If SC6->(RecLock("SC6", .F.))
                SC6->C6_CLVL := cZZCLVL
                SC6->(MsUnlock())
                ConOut("Atualizado: Pedido " + cNum + " Item " + cItem + " => " + cZZCLVL)
                FPAQRY->(DbSkip())
            Else
                ConOut("Falha ao dar lock no registro: " + cNum + " / " + cItem)
                FPAQRY->(DbSkip())
            EndIf
        EndDo
            ConOut("Sem dados para: Pedido " + cNum + " / Item " + cItem)
        DbCloseArea("FPAQRY")

        SC6->(DbSkip())
    EndDo

    Alert("Processo de atualização concluído.")
    DbCloseArea("SC6")
Return

