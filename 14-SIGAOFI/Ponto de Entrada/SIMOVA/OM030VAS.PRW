#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM030VAS
Ponto de entrada executado na alteração dea Requisição de Serviços.
>>Aplicacao SIMOVA:
>>Grava campo VO4_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
USER FUNCTION OM030VAS()
	//integracao SIMOVA
	if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME(),4)
	endif
	//>>Final Integracao SIMOVA 
Return(.T.)
