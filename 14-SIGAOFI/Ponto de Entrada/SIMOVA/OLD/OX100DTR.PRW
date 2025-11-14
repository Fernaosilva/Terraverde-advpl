#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VA150DPGR
Ponto na Entrada na rotina de gravação de Liberação da OS
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     25/01/2023
/*/
//------------------------------------------------------------------------------------------ 
User Function OX100DTR
Local lRet := .T.
//integracao SIMOVA
    U_SIMOVAZT("U_SYNCVO1")
//integracao SIMOVA
Return(lRet)
