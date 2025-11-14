#include "protheus.ch"

/*/{Protheus.doc} MTA140MNU
PE será chamado depois de montar o aRotina e antes de chamar a mBrowse.
Implementado para manipular a variável private aRotina conforme a necessidade.
Programa Fonte: MATA140.PRW
@type function
@version 1.0
@author Ademar Fernandes Jr
@since 06/11/2023
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com.br/pages/releaseview.action?pageId=6085799
@return variant, Nil
/*/
User function MTA140MNU()
	local lAnexo := SuperGetMv('ZZ_ANEXNF1',.F.,.T.)    //-Habilita rotina de Anexos na Pre-Nota (MATA140)

	if lAnexo
        AAdd(aRotina,{"(*) Adicionar Anexos ","U_ANEXDOC('NFE')",0,4,0,.F.})
    endif
Return aRotina
