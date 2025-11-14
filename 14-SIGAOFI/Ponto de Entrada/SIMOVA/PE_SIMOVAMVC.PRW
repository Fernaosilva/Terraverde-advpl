#include "protheus.ch"
#include "parmtype.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} ITEM()
Ponto de entrada MVC executado na alteração do cadastro de produtos.
>>Aplicacao SIMOVA:
>>Grava campo B1_XFGNFS para posterior sincronizacao com SIMOVA 
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 04/12/2024, Ademar Fernandes Jr., Caso necessário, instancia o Objeto Tracker".
@return variant, True / False
/*/
//------------------------------------------------------------------------------------------  
User Function ITEM()
    Local aParam := PARAMIXB
    Local xRet   := .T.
    Local oObj   := ""
    Local cIdPonto := ""
    Local cIdModel := ""

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        If cIdPonto == "MODELCOMMITTTS" .and. oObj:NOPERATION <> 5
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
                U_SIMOVAZT(PROCNAME(),,@oObj)
            EndIf
            //>>Final Integracao SIMOVA                     
        EndIf
    EndIf
Return xRet


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OMSA060()
Ponto de entrada MVC executado na alteração do cadastro de veículos OMS/TMS Tabela DA3.
>>Aplicacao SIMOVA:
>>Grava campo DA3_XFGNFS para posterior sincronizacao com SIMOVA 
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 04/12/2024, Ademar Fernandes Jr., Caso necessário, instancia o Objeto Tracker".
@return variant, True / False
/*/
//------------------------------------------------------------------------------------------ 
User Function OMSA060()
    Local aParam := PARAMIXB
    Local xRet := .T.
    Local oObj := ""
    Local cIdPonto := ""
    Local cIdModel := ""

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        If cIdPonto == "MODELCOMMITTTS"
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
        EndIf
    EndIf
Return xRet
