#include 'protheus.ch'

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MA030TOK
Ponto de entrada para envio de informações SmartOS do Cadastro de Clientes
>>Aplicacao SIMOVA:
>>Grava campo A1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function MA030TOK()
	//integracao SIMOVA
	if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME())
	endif
	//>>Final Integracao SIMOVA 	
Return(.T.)
