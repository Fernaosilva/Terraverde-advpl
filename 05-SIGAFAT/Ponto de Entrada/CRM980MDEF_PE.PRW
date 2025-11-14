#include "protheus.ch"
#include "parmtype.ch"

#Define SA1Show 	'A1_COD|A1_LOJA|A1_NOME|A1_NREDUZ|A1_XTIPCLI|A1_XSEGTIP|'
#Define SA1Update 	'A1_XTIPCLI|A1_XSEGTIP|'

/*/{Protheus.doc} CRM980MDEF
Ponto de entrada MVC executado na alteração do cadastro de clientes.
Fonte Padrao: CRMA980
@type function
@version 1.0
@author Ademar Fernandes Jr
@since 08/09/2023
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com/pages/releaseview.action?pageId=604230458
@see https://tdn.totvs.com/pages/releaseview.action?pageId=285649735
@see https://centraldeatendimento.totvs.com/hc/pt-br/articles/360000146128-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-ADVPL-Ponto-de-entrada-MVC-CRMA980
@return variant, True
/*/
User Function CRM980MDEF()
    local aRotina     := {}
    // local cLcFilial   := SuperGetMv("ZZ_TVLCFIL",.F.,"0111/") //-Indica quais Filiais utilizarão a funcionalidade
	Public cFiltroVX5 := "" //-Necessaria por causa do fonte OFIOA560

    // if Empty(cLcFilial) .Or. cFilAnt $ cLcFilial
        //----------------------------------------------------------------------------------------------------------
        // [n][1] - Nome da Funcionalidade
        // [n][2] - Função de Usuário
        // [n][3] - Operação (1-Pesquisa; 2-Visualização; 3-Inclusão; 4-Alteração; 5-Exclusão)
        // [n][4] - Acesso relacionado a rotina, se esta posição não for informada nenhum acesso será validado
        //----------------------------------------------------------------------------------------------------------
        // aAdd(aRotina,{"(* Função A *)","ApMsgAlert('Função A')",2,0})
        aAdd(aRotina,{"(* Avaliar Credito do Cliente *)", "U_TlCdPgto()", 4, 0})
        aAdd(aRotina,{"Propriedades Agrícolas", "FWExecView('Propriedades Agrícolas','TvAgricMVC', 4)", 4, 0})
    // endif

Return aRotina
