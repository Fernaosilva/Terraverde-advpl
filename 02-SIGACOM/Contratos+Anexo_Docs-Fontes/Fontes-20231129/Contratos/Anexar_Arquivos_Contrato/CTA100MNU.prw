#include "protheus.ch"

/*/{Protheus.doc} User Function CTA100MNU
PE para adicionar opções adicionais no menu da rotina CNTA300
Programa Fonte: CNTA100.PRW - Manutenção de Contratos
@type Function
@author Geeker Company
@since 13/09/2023
@version P12
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com/pages/releaseview.action?pageId=6089605
@return variant, Array com menu
/*/
User Function CTA100MNU()
	local lAnexo := SuperGetMv('ZZ_ANEXCT1',.F.,.T.)    //-Habilita rotina de Anexos na Manut.de Contratos (CNTA300)

	if lAnexo
        AAdd(aRotina,{"(*) Adicionar Anexos ","U_ANEXDOC('CT')",0,8,58,NIL,NIL,NIL})
    endif
Return aRotina
