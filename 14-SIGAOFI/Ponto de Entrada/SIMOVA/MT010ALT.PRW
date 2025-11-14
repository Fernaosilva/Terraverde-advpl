#include "protheus.ch"
#include "topconn.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MT010ALT
Ponto de entrada executado na alteração do cadastro de produtos.
>>Aplicacao SIMOVA:
>>Grava campo B1_XFGNFS para posterior sincronizacao com SIMOVA 
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 04/12/2024, Ademar Fernandes Jr., Caso necessário, instancia o Objeto Tracker".
@return variant, Nil
/*/
//------------------------------------------------------------------------------------------ 
User Function MT010ALT()
    //>>>Inicio Integracao SIMOVA
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
    EndIf
    //>>Final Integracao SIMOVA 
Return
