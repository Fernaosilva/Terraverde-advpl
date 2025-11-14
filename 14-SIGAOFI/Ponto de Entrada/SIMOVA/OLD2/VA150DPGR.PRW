#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VA150DPGR
Ponto na rotina de Cancelamento do Fechamento da OS
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     16/01/2023
/*/
//------------------------------------------------------------------------------------------ 
User Function VA150DPGR()
    //integracao SIMOVA
    Local lRet:=.T.
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)
    Local nI := 0

    If SIMOVACOM == "0"
        For nI := 1 to Len(aOsSimova)
            If VO1->(DbSeek(aOsSimova[nI][1]+aOsSimova[nI][2]))
                if ExistBlock("SIMOVAZT")
                    U_SIMOVAZT("U_SYNCVO1")
                endif
            Endif
        Next
        aOsSimova := {}
    Endif
    //integracao SIMOVA
Return(lRet)
