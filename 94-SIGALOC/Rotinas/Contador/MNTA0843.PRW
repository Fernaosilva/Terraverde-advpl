#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} MNTA0843
O ponto de entrada MNTA0843 foi desenvolvido para adicionar itens no
menu da mBrowse Rental. Retorna array com os novas opções e manda como
parâmetro o array com as opções padrão.

@author Elivelton Canedo            elivelton.canedo@totvs.com.br
@since 23/09/2024
/*/
//-------------------------------------------------------------------
User Function MNTA0843()

      Local aRotina 	:= ParamixB[1]

      aAdd(aRotina, {'@Import. Contadores'  ,"u_EMTCOTCSV"               ,   		0 	,8   })

Return(aRotina)

