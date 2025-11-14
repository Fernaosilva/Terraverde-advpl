#include 'totvs.ch'


/*/{Protheus.doc} User Function FA040INC
    Ponto de entrada utilizado na validação da TudoOK na inclusão do Contas a Receber
    @type  Function
    @author Rodrigo Machado
    @since 21/08/2024
/*/
User Function FA040INC()
    local lRet      := .T.
    local aParam    := {}
    local cHistE1AS := substr(M->E1_HIST, 9)

    //Função utilizada para incluir classe de valor na tabela SE1 quando chamada através do Rental(SIGALOC)
    If FWIsInCallStack("LOCA001") .OR. FWIsInCallStack("LOCA021") .OR. FWIsInCallStack("LOCA013")
        aParam := {cHistE1AS}
        if existBlock('IncClvlE1')
            lRet := ExecBlock("IncClvlE1",.F.,.F.,aParam)
        Endif
    Endif
Return lRet 
