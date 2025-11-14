
#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VA150DPGR
Ponto na Entrada na rotina de gravação de Liberação da OS
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     16/01/2023
/*/
//------------------------------------------------------------------------------------------ 
User Function VA140DPGR()
    //integracao SIMOVA
    Local lRet := .T.
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)

    If SIMOVACOM == "0"
        if ExistBlock("SIMOVAZT")
            U_SIMOVAZT("U_SYNCVO1")
        endif
    Endif
    //integracao SIMOVA
Return(lRet)
