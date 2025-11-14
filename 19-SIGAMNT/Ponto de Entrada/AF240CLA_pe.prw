#include 'totvs.ch'

/*/{Protheus.doc} AF240CLA
ponto de entrada AF240CLA é executado ao final do processo de Classificação de Bens.
Utilizado para a criaçao da classe valor com o número do chassis
@author  Rodrigo Machado
@since   04/07/2024
*/
User Function AF240CLA()
    local lRet := .T.
    local cChassi := SN1->N1_CHASSIS
    local cDescri := SN1->N1_DESCRIC

    lRet := grvClassVal(cChassi, cDescri)
Return .T.

/*/{Protheus.doc} grvClassVal
Função responsável por rodar a rotina autmática para a criação da classe valor
Utilizado para a criaçao da classe valor com o número do chassis
@author  Rodrigo Machado
@since   04/07/2024
*/
Static Function grvClassVal(cChassi, cDescri)
    local lRet := .F.
    local aClass := {}
    PRIVATE lMsErroAuto := .F.

    //Montagem do array para executar a rotina automática de classe valor
    aadd(aClass,{"CTH_CLVL",cChassi,NIL})
    aadd(aClass,{"CTH_CLASSE","2",NIL})
    aadd(aClass,{"CTH_DESC01", cDescri,NIL})
    aadd(aClass,{"CTH_NORMAL", "0",NIL})
    aadd(aClass,{"CTH_DTEXIST", dDataBase,NIL})

    //Chamada da rotina automática para a criação da classe valor
    CTBA060(aClass,3)

    If !lMsErroAuto
        lRet := .T.
    else
        lRet := .F.
    Endif
Return lRet
