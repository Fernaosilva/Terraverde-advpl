#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OA180VLD
Ponto de entrada executado na confirmação da Gravação da tabela VAI
>>Aplicacao SIMOVA:
>>Grava campo VA1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OA180VLD()
	//integracao SIMOVA
	if ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME())
	endif
	//>>Final Integracao SIMOVA 	
Return(.T.)
