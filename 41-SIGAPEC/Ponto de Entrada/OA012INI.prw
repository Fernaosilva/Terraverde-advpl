#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"

/*/OA012INI
Descrição: PE executado na rotina Pedido de Venda (Orçamento Fases)
Tipo: user function
@author valterbetiol
@since 03/09/2024
(OFIXA012) para validações antes da abertura da tela para inclusão de Pedido de Venda
/*/
User Function OA012INI()

Local lRet := .T.

MsgAlert("Verifique o saldo do cliente no programa de Fidelidade (Seedz)", "Atenção!")

Return lRet

