#include 'totvs.ch'



/*/{Protheus.doc} User Function IncClvlE1
    Função utilizada na chamada do Ponto de entrada FA040INC.
    Função responsável por incluir no registro de contas a pagar (SE1) a classe valor do Bem (E1_CLVLDB).
    Função chamada apenas a partir do módulo Rental (SIGALOC)
    @type  Function
    @author Rodrigo Machado
    @since 21/08/2024
    @version 1.0
    /*/
User Function IncClvlE1()
    local lRet      := .T.
    local aArea     := getArea()
    local cHistE1AS := PARAMIXB[1]

    dbSelectArea("FPA")
    FPA->(dbSetOrder(3))

    dbSelectArea("SD2")
    SD2->(dbSetOrder(2))

    If FPA->(DbSeek(xFilial("FPA") + Alltrim(cHistE1AS)))
        M->E1_CLVLDB := FPA->FPA_ZZCLVL
    Endif

    RestArea(aArea)
Return lRet
