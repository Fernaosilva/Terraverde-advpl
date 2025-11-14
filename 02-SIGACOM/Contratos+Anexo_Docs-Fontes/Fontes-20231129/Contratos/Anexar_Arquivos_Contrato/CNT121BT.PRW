#include "protheus.ch"

/*/{Protheus.doc} CNT121BT
Ponto de entrada tem por objetivo permitir adicionar botões do usuário ao menu principal da rotina de medições. 
A variável aRotina é private neste momento, possibilitando adicionar mais botões a rotina
@type  Function
@author Geeker Company
@since 14/09/2023
@version P12
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com/pages/releaseview.action?pageId=271385893
@return variant, Nil
/*/
User Function CNT121BT()
Local lAnexo := SuperGetMv('ZZ_ANEXNF1',.F.,.T.)//patini:habilita ou desabilita rotina de anexos.

	AAdd(aRotina,{"(*) Reenviar E-mail ","U_EnvioCTR()",0,4})
	
	if lAnexo
		AAdd(aRotina,{"(*) Adicionar Anexos ","U_ANEXDOC('CT')",0,4,0,.F.})
	endif

Return aRotina
