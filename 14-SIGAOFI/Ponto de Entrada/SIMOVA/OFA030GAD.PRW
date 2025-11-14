#include "TOTVS.ch"

//------------------------------------------------------------------------------------------ 
/*/{Protheus.doc} OFA030GAD
Ponto de entrada na rotina de Cadastro de Serviços
>>Aplicacao SIMOVA:
@type function
@version P12
@author Simova Tecnologia
@since 08/04/2025
@return variant, Nil
/*/
//------------------------------------------------------------------------------------------
User Function OFA030GAD()
    //integracao SIMOVA
    Local lRet := .T.
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)

    If SIMOVACOM == "0"
        if ExistBlock("SIMOVAZT")
            U_SIMOVAZT("U_SYNCVO6")
        endif
    Endif
    //integracao SIMOVA
Return(lRet)
