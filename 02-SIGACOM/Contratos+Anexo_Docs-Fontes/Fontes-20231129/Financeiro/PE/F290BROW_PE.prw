#include "protheus.ch"

/*/{Protheus.doc} F290BROW
PE para incluir novos botões na tela de Faturas a Pagar.
@type function
@version 1.0
@author Ademar Fernandes Jr
@since 07/11/2023
@link https://gkcmp.com.br (Geeker Company)
@see 
@return variant, Array com os botoes
/*/
User function F290BROW()
	local lAnexo  := SuperGetMv('ZZ_ANEXCP3',.F.,.T.) //-Habilita rotina de Anexos na Faturas a Pagar (FINA290)

	if lAnexo
        AAdd(aRotina,{"(*) Consultar Anexos ","U_ANEXDOC('NFE')",0,4})
    endif
Return aRotina
