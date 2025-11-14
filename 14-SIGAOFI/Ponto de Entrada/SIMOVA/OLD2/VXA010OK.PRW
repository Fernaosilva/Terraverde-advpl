#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VXA010OK
Ponto de entrada executado na Alteração do Cadastro de Veículos MOD 2
>>Aplicacao SIMOVA:
>>Grava campo VV1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
USER FUNCTION VXA010OK()
	//>>Inicio Integração SIMOVA
    if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME(),ParamIxb)
	endif
	//>>Final Integração SIMOVA
Return(.T.)
