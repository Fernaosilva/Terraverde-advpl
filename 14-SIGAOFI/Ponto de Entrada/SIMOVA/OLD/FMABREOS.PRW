#include "protheus.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "TBICODE.CH"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FMABREOS
Ponto de Entrada executado durante abertura de OS automatica / orcamento por fases
>>Aplicacao SIMOVA:
>>Grava Flag de sincronismo e campos obrigatórios na VO1 e VO4
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function FMABREOS
//integracao SIMOVA
	U_SIMOVAZT(PROCNAME())
//>>Final Integracao SIMOVA 
Return
