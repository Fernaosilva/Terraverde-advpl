#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM150AP
Ponto na rotina de Cancelamento da OS
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     16/01/2023
/*/
//------------------------------------------------------------------------------------------ 
User Function OM150AP()
    //integracao SIMOVA
    Local aItens := ParamIxb[01]
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)

    If SIMOVACOM == "0"
        If VO1->VO1_STATUS == "C"
            aAdd(aOsSimova,{VO1->VO1_FILIAL,VO1->VO1_NUMOSV,.F.})
        Endif
    Endif
    //>>Final Integracao SIMOVA
Return(aItens)
