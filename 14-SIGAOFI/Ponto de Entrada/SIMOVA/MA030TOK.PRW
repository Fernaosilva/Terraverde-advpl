#include 'protheus.ch'

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MA030TOK
Ponto de entrada para envio de informações SmartOS do Cadastro de Clientes
>>Aplicacao SIMOVA:
>>Grava campo A1_XFGNFS para posterior sincronizacao com SIMOVA 
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 17/12/2024, Ademar Fernandes Jr., Caso necessário, instancia o Objeto Tracker".
@return variant, Nil
/*/
//------------------------------------------------------------------------------------------ 
User Function MA030TOK()
	//integracao SIMOVA
    If ExistBlock("SIMOVAZT")
		If Type("oTracker") != "O"
			Private oTracker
			Private cParDefaults := ""
			Private cMsgAudit    := ""
			Private aDefaults    := {}
			Private cDirTracker := SuperGetMV("SIMOVATRCD",.T., "\SimovaTracker" )
			oTracker := FWTRACKERSIMOVA():New(PROCNAME())
		EndIf
		//-Chama rotina de Sincronismo
		U_SIMOVAZT(PROCNAME())
	endif
	//>>Final Integracao SIMOVA 	
Return(.T.)
