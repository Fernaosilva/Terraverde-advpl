#include "protheus.ch"
#include "topconn.ch"
 
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VA010DPGR
Ponto de Entrada executado apos a Gravacao/Inclusao ou Alteracao no Cadastro de Veiculos
>>Aplicacao SIMOVA:
>>Grava campo VV1_XFGNFS limpando o conteudo para posterior sincronizacao com SIMOVA 
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 04/12/2024, Ademar Fernandes Jr., Caso necessário, instancia o Objeto Tracker".
@return variant, Nil
/*/
//------------------------------------------------------------------------------------------ 
User Function VA010DPGR()
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
        U_SIMOVAZT(PROCNAME(),PARAMIXB)
    EndIf
    //>>Final Integracao SIMOVA    
Return
