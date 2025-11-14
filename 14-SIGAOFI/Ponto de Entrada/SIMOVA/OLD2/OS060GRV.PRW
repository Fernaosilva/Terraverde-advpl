#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OS060GRV
Ponto de entrada executado na gravação da DA3 Veiculos OMS/TMS
>>Aplicacao SIMOVA:
>>Grava campo DA3_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OS060GRV()
	//integracao SIMOVA
	if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME())
	endif
	//>>Final Integracao SIMOVA 
Return
