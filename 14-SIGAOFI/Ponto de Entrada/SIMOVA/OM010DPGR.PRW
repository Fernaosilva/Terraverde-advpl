#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM010DPGR
Ponto de entrada executado após a Gravação OS..
>>Aplicacao SIMOVA:
>>Grava campo VO1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
USER FUNCTION OM010DPGR()
	//integracao SIMOVA
	if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME())
	endif
	//>>Final Integracao SIMOVA 
RETURN(.T.)
