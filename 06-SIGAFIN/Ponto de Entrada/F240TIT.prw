#Include 'Protheus.ch'
 
//-------------------------------------------------------------------------------------
/*/{Protheus.doc} F240TIT
O ponto de entrada F240TIT sera executado durante a marcação dos
títulos que irão compor o borderô de pagamento.
 
@author     Charlles Reis
@version    1.0
@since      Maio/2021
/*/
//-------------------------------------------------------------------------------------
 
User Function F240TIT()
 
    Local lRet      := .t.
    Local lVldCCSA2 := GetMV("PM_VLDCCFO",.f.,.t.)
    Local lVldCCSE2 := GetMV("PM_VLDCCTI",.f.,.t.)
 
    If  cModPgto $ "30/31" .and. Empty(SE2->E2_CODBAR)
 
        MsgStop("Este documento não possui código de barras informado.","Atenção!")
        lRet := .f.
 
    ElseIf  cModPgto $ "01/03/05/41/43"
 
        dbSelectArea("SA2")
        SA2->(dbSetOrder(1))
        SA2->(dbSeek(xFilial("SA2") + SE2->E2_FORNECE + SE2->E2_LOJA ))
 
        If  lVldCCSA2
 
            If  Empty(SA2->A2_BANCO) .or. Empty(SA2->A2_AGENCIA) .or. Empty(SA2->A2_NUMCON)
 
                MsgStop("Para a forma de pagamento informada, é necessário que os dados bancários do fornecedor estejam cadastrados no sistema," +;
                    " verifique os campos Banco/Agência e Conta no cadastro do Fornecedor.","Atenção!")
 
                lRet := .f.
 
            EndIf
 
        EndIf
 
        If  lVldCCSE2
 
            If  Empty(SE2->E2_FORBCO) .or. Empty(SE2->E2_FORAGE) .or. Empty(SE2->E2_FORCTA)
 
                MsgStop("Para a forma de pagamento informada, é necessário que os dados bancários do fornecedor estejam cadastrados no sistema," +;
                    " verifique os campos Banco/Agência e Conta no titulo a pagar.","Atenção!")
 
                lRet := .f.
 
            EndIf
 
        EndIf
 
    EndIf
 
 
Return lRet
