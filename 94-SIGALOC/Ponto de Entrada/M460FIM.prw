#include 'totvs.ch'


/*/{Protheus.doc} User Function M460FIM
    Ponto de entrada na Gravação dos dados após gerar NF de Saída  
    @type  Function
    @author Rodrigo Mchado
    @since 21/08/2024
    /*/
User Function M460FIM()
    local aArea := getArea()

    //Função utilizada para incluir classe de valor na tabela SE1 quando chamada através do Rental(SIGALOC)
    If FWIsInCallStack("LOCA001") .OR. FWIsInCallStack("LOCA021") .OR. FWIsInCallStack("LOCA013")
        If existblock("IncClvlNFSE1")
            ExecBlock("IncClvlNFSE1", .F., .F., {})
        Endif
    Endif

    RestArea(aArea)    
Return
