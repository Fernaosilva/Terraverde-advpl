#include "totvs.ch"
#include "protheus.ch"


/*/{Protheus.doc} OX004AFT
Ponto de entrada executado antes do faturamento
@type user function
@author Fernando Silva
@since 04/06/2024
@version 12.1.2310
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function OX004AFT()
Local lRet := .T.
//Verifica se a condição de pagamento selecionada no orçamento é a vista sem analise de credito e envia para o TEF
IF M->VS1_FORPAG == '500'
	cNFCF := '2'
	lRet := .T.
	Alert("Alterado para Cupom Fiscal, pois, a condição de pagamento selecionada no orçamento foi a 500!")
Endif

//Adiconado Valter Ticket de melhoria -- 2024081123 -- 27/08/2024 -- Início
MsgInfo("Não esqueça de solicitar ao cliente que responda nossa Pesquisa de Satisfação. O QRCode está disponível no balcão de peças.","Atenção Consultor Estratégico de Peças!")
// Fim

Return lRet
