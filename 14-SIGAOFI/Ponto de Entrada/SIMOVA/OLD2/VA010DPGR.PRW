#include "protheus.ch"
#include "topconn.ch"
 
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VA010DPGR
Ponto de Entrada executado apos a Gravacao/Inclusao ou Alteracao no Cadastro de Veiculos
>>Aplicacao SIMOVA:
>>Grava campo VV1_XFGNFS limpando o conteudo para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function VA010DPGR()
    //>>Inicio Integracao SIMOVA
    if ExistBlock("SIMOVAZT")
        U_SIMOVAZT(PROCNAME(),PARAMIXB)
    endif
    //>>Final Integracao SIMOVA    
Return
