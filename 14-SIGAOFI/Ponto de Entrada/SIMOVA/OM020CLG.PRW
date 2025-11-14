#include "TOTVS.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM020CLG
Ponto de entrada para customizacao de Legendas em Requisicao de Pecas
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OM020CLG()
	//integracao SIMOVA
    Local aLeg := ParamIxb[01]
    Local lLgSimova0 := SuperGetMV("SIMOVALEG0",.T., .F. )
    Local lLgSimova1 := SuperGetMV("SIMOVALEG1",.T., .F. )
    Local cLgSimova  := SuperGetMV("SIMOVALEGC",.T., "VERDE_LARANJA" )
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)

    If SIMOVACOM == "0"
        If lLgSimova0
            aadd(aLeg,{'SIMOVA_S_'+cLgSimova,"Aberta - Sincronizada (SIMOVA)"})
            aadd(aLeg,{'SIMOVA_R_'+cLgSimova,"Aberta - Recebida     (SIMOVA)"})
            aadd(aLeg,{'SIMOVA_I_'+cLgSimova,"Aberta - Integrada    (SIMOVA)"})
            If lLgSimova1
                aadd(aLeg,{'SIMOVA_SN_'+cLgSimova,"Aberta - Pendente/Sincronismo (SIMOVA)"})
                aadd(aLeg,{'SIMOVA_VN_'+cLgSimova,"Aberta - Pendente/Sincronismo Servicos (SIMOVA)"})
                aadd(aLeg,{'SIMOVA_S_VERMELHO',"Aberta - Encerrada/Indisponivel p/Sincronismo(SIMOVA)"})
                aadd(aLeg,{'SIMOVA_SN_PRETO',"Aberta - Pendente/Sincronismo Status no Painel(SIMOVA)"})
                aadd(aLeg,{'SIMOVA_RN_'+cLgSimova,"Aberta - Pendente/Recebimento (SIMOVA)"})
                aadd(aLeg,{'SIMOVA_R_VERMELHO',"Aberta - Encerrada/Indisponivel p/Rececbimento(SIMOVA)"})
                aadd(aLeg,{'SIMOVA_IN_'+cLgSimova,"Aberta - Pendente/Integracao  (SIMOVA)"})
            Endif
        Endif
    Endif
	//>>Final Integracao SIMOVA 
Return aLeg
