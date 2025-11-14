#include "protheus.ch"

/*/{Protheus.doc} FA080BUT
PE para incluir novos botões na tela de baixa.
@type function
@version 1.0
@author Ademar Fernandes Jr
@since 06/11/2023
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com/display/public/PROT/Pontos+de+Entrada+-+Financeiro+-+P12 (generico)
@return variant, Array com os botoes
/*/
User function FA080BUT()
	local lAnexo := SuperGetMv('ZZ_ANEXCP2',.F.,.T.)    //-Habilita rotina de Anexos na Baixas do CP (FINA080)

	if lAnexo
        AAdd(aRotina,{"(*) Consultar Anexos ","U_ANEXDOC('NFE')",0,4})
    endif
Return aRotina
