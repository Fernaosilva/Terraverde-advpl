#Include "Protheus.ch"
#Include "TopConn.ch"

User Function GetCodCliente(cCNPJ)
    Local cRootCNPJ   := SubStr(cCNPJ, 1, 8)
    Local cFilialCNPJ := SubStr(cCNPJ, 9, 4)
    Local cQuery := ""
    Local cCodigo := ""
    Local cLoja := ""
    Local cSQL := ""
    Local aResult := {}
    
    // 1?? Verifica se o CNPJ completo já existe
    cSQL := "SELECT A1_COD, A1_LOJA, A1_CGC FROM " + RetSqlName("SA1") + ;
             " WHERE A1_CGC = '" + cCNPJ + "' AND D_E_L_E_T_ = ' '"
    
    TCQuery cSQL New Alias "Q1"
    If !Q1->(EoF())
        MsgStop("CNPJ já cadastrado para o cliente " + Q1->A1_COD + "/" + Q1->A1_LOJA, "Erro")
        Q1->(DbCloseArea())
        Return Nil
    EndIf
    Q1->(DbCloseArea())

    // 2?? Busca clientes com a mesma raiz
    cSQL := "SELECT A1_COD, A1_LOJA FROM " + RetSqlName("SA1") + ;
             " WHERE SUBSTRING(A1_CGC,1,8) = '" + cRootCNPJ + "'" + ;
             " AND D_E_L_E_T_ = ' ' ORDER BY A1_LOJA DESC"

    TCQuery cSQL New Alias "Q2"
    If Q2->(EoF()) // Raiz não existe ? novo cliente
        cCodigo := Soma1( GetLastCodCli() ) // Gera novo código (exemplo fictício)
        cLoja   := "0001"
    Else
        // Usa mesmo código e gera nova loja
        cCodigo := Q2->A1_COD
        cLoja := Soma1(Q2->A1_LOJA)
        
        // 3?? Se loja já existe (duplicidade antiga)
        If ExistLoja(cCodigo, cLoja)
            MsgAlert("Loja " + cLoja + " já existe para este cliente. Gerando nova loja...", "Aviso")
            cLoja := Soma1(cLoja)
        EndIf
    EndIf
    Q2->(DbCloseArea())

Return { cCodigo, cLoja }


