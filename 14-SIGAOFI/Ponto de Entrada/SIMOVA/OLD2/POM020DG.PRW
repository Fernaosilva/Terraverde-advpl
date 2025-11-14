#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} POM020DG
Ponto de entrada executado na requisição de peças.>>Aplicacao SIMOVA:
>>Grava campo VO3_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     23/01/2023
/*/
//------------------------------------------------------------------------------------------ 
User Function POM020DG()
	//integracao SIMOVA
	Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )	//-Tipo de Integracao SmartOS (0=API/1=PDI)

	If SIMOVACOM == "0" .and. ExistBlock("SIMOVAZT")
		U_SIMOVAZT(PROCNAME())
	Endif
	//>>Final Integracao SIMOVA 
Return(.T.)
