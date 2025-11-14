#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VX000AIN
Ponto de entrada executado na Entrada por Remessa
>>Aplicacao SIMOVA:
>>Grava campo VV1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function VX000AIN
    //integracao SIMOVA
    if ExistBlock("SIMOVAZT")
        U_SIMOVAZT(PROCNAME())
    endif
    //>>Final Integracao SIMOVA 
Return
