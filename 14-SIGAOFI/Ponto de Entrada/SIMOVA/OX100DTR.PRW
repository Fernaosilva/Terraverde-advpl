#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OX100DTR
Ponto na Entrada na rotina de Fechamento da OS
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     25/01/2023
/*/
//------------------------------------------------------------------------------------------ 
User Function OX100DTR()
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
