#include "totvs.ch"
#include "Protheus.ch"

/*/{Protheus.doc} OX004DCP
Ponto de entrada executado depois de montar a tela como pagar
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

User Function OX004DCP()

Local lRet := .F. 

//Verifica se a condição selecionada no orçamento foi a sem analise de credito 
//e não permite a troca por outra 
IF M->VS1_FORPAG == '500'
	cNFCF := '2'
	IF CTIPPAG == M->VS1_FORPAG
		lRet := .T.
	else
		lRet := .F.
		Alert("A condição de Pagamento deve ser igual a escolhida no orçamento!")
	Endif
Endif

//Verifica se a condição de pagamento selecionada foi a 500 e validar se vai para cupom fiscal
IF (CTIPPAG == '500' .and. cNFCF == '1')
	Alert("Para condição de pagamento 500 enviar para TEF | 2 - Cupom Fiscal")
	cNFCF := '2'
	lRet := .F.
	Else
	lRet := .T.
Endif

//Verifica se a condição de pagamento selecionada foi diferente de 500 e validar se vai para Nota fiscal
IF (CTIPPAG <> '500' .and. CNFCF == '2')
	cNFCF := '1'
	Alert("Para condição de pagamento diferente de 500 enviar para NF | 1 - Nota Fiscal")
	lRet := .F.
	Else
	lRet := .T.
Endif

//Adiconado Valter Ticket de melhoria -- 2024081123 -- 27/08/2024 -- Início
MsgInfo("Não esqueça de solicitar ao cliente que responda nossa Pesquisa de Satisfação. O QRCode está disponível no balcão de peças.","Atenção Consultor Estratégico de Peças!")
// Fim

return lRet
