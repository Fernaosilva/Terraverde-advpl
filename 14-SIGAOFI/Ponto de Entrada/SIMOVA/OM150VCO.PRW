#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM150VCO
Ponto na rotina de Fechamento do Tipo de Tempo
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     16/01/2023
@Obs       03/2025 - Roda em conjunto com os PEs: OM150AP, OM150VCO e VA150DPGR.
/*/
//------------------------------------------------------------------------------------------ 
User function OM150VCO()
    //integracao SIMOVA
    Local lRet := .T.
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)

    If SIMOVACOM == "0"
        Public aOsSimova := {}
    Endif
    //>>Final Integracao SIMOVA
Return(lRet)
