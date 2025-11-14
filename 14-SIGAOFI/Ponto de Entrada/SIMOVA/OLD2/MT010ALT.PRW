#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MT010ALT
Ponto de entrada executado na alteração do cadastro de produtos.
>>Aplicacao SIMOVA:
>>Grava campo B1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function MT010ALT()
    //integracao SIMOVA
	if ExistBlock("SIMOVAZT")
        U_SIMOVAZT(PROCNAME())
    endif
    //>>Final Integracao SIMOVA 
Return
