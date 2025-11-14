#include "protheus.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "TBICODE.CH"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OX001DEX
Ponto de Entrada executado durante abertura de OS automatica / orcamento por fases
>>Aplicacao SIMOVA:
>>Grava Flag de sincronismo e campos obrigatórios na VO1 e VO4
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OX001DEX()
	//integracao SIMOVA
	Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )	//-Tipo de Integracao SmartOS (0=API/1=PDI)

	If SIMOVACOM == "0" .And. ExistBlock("SIMOVAZT")
		U_SIMOVAZT("U_FMABREOS")
	Endif
	//>>Final Integracao SIMOVA 
Return
