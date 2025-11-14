#include "protheus.ch"

/*/{Protheus.doc} F750BROW
PE será chamado depois de montar o aRotina e antes de chamar a mBrowse.
Implementado para manipular a variável private aRotina conforme a necessidade.
@type function
@version 1.0
@author Ademar Fernandes Jr
@since 06/11/2023
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com.br/pages/releaseview.action?pageId=6071090
@return variant, Nil
/*/
User function F750BROW()
	local lAnexo := SuperGetMv('ZZ_ANEXCP1',.F.,.T.)    //-Habilita rotina de Anexos na Funçoes do CP (FINA750)

	if lAnexo
        AAdd(aRotina,{"(*) Consultar Anexos ","U_ANEXDOC('NFE')",0,4})
    endif
Return aRotina
