#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM3020TP
Ponto de entrada executado antes da montagem da janela principal da requisição de serviços/peças.
>>Aplicacao SIMOVA:
>>Grava campo VO4_XFGNFS/VO3_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OM3020TP()
	//integracao SIMOVA
	if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME())
	endif
	//>>Final Integracao SIMOVA 
Return
