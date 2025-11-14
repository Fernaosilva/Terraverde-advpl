#include "TOTVS.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OX120ROT
Ponto de entrada para inclusao de rotinas em Funcoes Oficina
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA no Menu Funçoes Oficina
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 03/06/2024, Ademar Fernandes Jr., Implementado a chamada de novas rotinas.
@return variant, Nil
/*/
//------------------------------------------------------------------------------------------ 
User Function OX120ROT()
    //>>>Inicio Integracao SIMOVA
    Local aRotAdic  := {}
    Local cTabZZX   := SuperGetMV("SIMOVAZZX",.T., "ZZX" )
    Local cTabZZW   := SuperGetMV("SIMOVAZZW",.T., "ZZW" )
    Local cTabZZU   := SuperGetMV("SIMOVAZZU",.T., "ZZU" )
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" ) //-Tipo de Integracao SmartOS (0=API/1=PDI)
    Local SIMOVAEXP := SuperGetMV("SIMOVAEXPD",.T., .F. )
    Local SIMOVASMK := SuperGetMV("SIMOVASMRK",.T., .F. )
    Local lPosMigr  := SuperGetMV("SIMOVAMIG1",.T., .F. ) //-Habilita no Menu Rotina Pos Migrar APi
	Local aUserLgn 	:= PswRet()
	Local cUserLgn  := Rtrim(aUserLgn[1][2])
    Local lTracker  := SuperGetMV("SIMOVATRCK",.T., .F.)
	Local cUserTrkr := SuperGetMV("SIMOVATRUS",.T., "Administrador;")
    PUBLIC kSimova  := ""

    If SIMOVACOM == "0"
        (cTabZZU)->(DbSetFilter( { || !(cTabZZU+"->"+cTabZZU+"_LOGSTA" $ ' 1') }, "!("+cTabZZU+"->"+cTabZZU+"_LOGSTA $ ' 1')" ) )
        If Upper(Alltrim(cUsername)) <> "ADMINISTRADOR"
            (cTabZZW)->(DbSetFilter( { || ( AllTrim(cTabZZW+"->"+cTabZZW+"_STATUS") <>'0' .AND. cTabZZW+"->"+cTabZZW+"_MSBLQL" <> '1') }, "(AllTrim("+cTabZZW+"->"+cTabZZW+"_STATUS) <> '0' .AND. "+cTabZZW+"->"+cTabZZW+"_MSBLQL <> '1')" ) )
        Endif

        AADD( aRotAdic , { "OFICINA_SIMOVA"                    ,"OFICINA"               ,"SIMOVA SMARTOS"                   ,"VO1","","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_01_SINCRONIZAR"             ,"OFICINA_SIMOVA"        ,"Enviar OS / Sincronizar"          ,"VO1","U_SIMOVA0T","U_SIMOVA0T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)"   ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_01_RECEBER"                 ,"OFICINA_SIMOVA"        ,"Receber OS Apontamentos"          ,"VO1","U_SIMOVA1T","U_SIMOVA1T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)"   ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_01_INTEGRAR"                ,"OFICINA_SIMOVA"        ,"Integrar OS Apontamentos"         ,"VO1","U_SIMOVA2T","U_SIMOVA2T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)"   ,2 , .f. ,".T.", } )
        If SIMOVASMK
            AADD( aRotAdic , { "SIMOVA_01_SINCRONIZAR_LISTA"       ,"OFICINA_SIMOVA"        ,"Enviar Lote - OS / Sincronizar"   ,"VO1","U_SIMOVA0T","U_SIMOVA0T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV,,.T.)"   ,2 , .f. ,".T.", } )    
            AADD( aRotAdic , { "SIMOVA_01_RECEBER"                 ,"OFICINA_SIMOVA"        ,"Receber Lote - OS Apontamentos"   ,"VO1","U_SIMOVA1T","U_SIMOVA1T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV,.T.)"   ,2 , .f. ,".T.", } )    
            AADD( aRotAdic , { "SIMOVA_01_INTEGRAR"                ,"OFICINA_SIMOVA"        ,"Integrar Lote - OS Apontamentos"  ,"VO1","U_SIMOVA2T","U_SIMOVA2T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV,.T.)"   ,2 , .f. ,".T.", } )
        Endif
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE"                 ,"OFICINA_SIMOVA"        ,"SIMOVA - Suporte"                 ,"VO1","","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_VERSAO"          ,"SIMOVA_03_SUPORTE"     ,"Versao fontes App SIMOVA"         ,"VO1","U_SMV14M01","U_SMV14M01()"                                ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_RPC"             ,"SIMOVA_03_SUPORTE"     ,"Preparar Reintegracao/Estorno OS" ,"VO1","U_SIMOVA6T","U_SIMOVA6T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)" ,2 , .f. ,".T.", } )

        If lTracker .And. Upper(Alltrim(cUserLgn)) $ Upper(Alltrim(cUserTrkr))
            AADD( aRotAdic , { "SIMOVA_03_SUPORTE_PRERECEB"        ,"SIMOVA_03_SUPORTE"     ,"Preparar Novo Recebimento"        ,"VO1","U_SMV14M11","U_SMV14M11(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)" ,2 , .f. ,".T.", } )
            If lPosMigr
                AADD( aRotAdic , { "SIMOVA_03_SUPORTE_POSAPI"          ,"SIMOVA_03_SUPORTE"     ,"Ajustar OS Pos Migrar APi"        ,"VO1","U_SMVPosMigr","U_SMVPosMigr()"                            ,2 , .f. ,".T.", } )
            Endif
            If SIMOVAEXP
                AADD( aRotAdic , { "SIMOVA_03_SUPORTE_CD"              ,"SIMOVA_03_SUPORTE"     ,"Carga de Dados / SIMOVA"          ,"VO1","U_SIMOVACD","U_SIMOVACD()" ,2 , .f. ,".T.", } )
            Endif
            // AADD( aRotAdic , { "SIMOVA_03_SUPORTE_REL001"          ,"SIMOVA_03_SUPORTE"     ,"(*) Relat Pos Integracao Aptos"     ,"VO1","U_SMV14R01","U_SMV14R01()"                                ,2 , .f. ,".T.", } )
        Endif
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS"              ,"OFICINA_SIMOVA"        ,"SIMOVA - Liberacao de OS"         ,cTabZZU,"","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS_LIBERAR"      ,"SIMOVA_04_MONITOR_OS"  ,"Liberar p/ Integracao"            ,cTabZZU,"U_SIMOVA1L","U_SIMOVA1L()"   ,4 , .f. ,".T.", } )

        AADD( aRotAdic , { "SIMOVA_05_MONITOR_API"             ,"OFICINA_SIMOVA"        ,"SIMOVA - Monitor API"             ,cTabZZW,"","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_VISUALIZAR"   ,"SIMOVA_05_MONITOR_API" ,"Visualizar"                       ,cTabZZW,"U_SIMOVAVM","U_SIMOVAVM()"   ,4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_SINCRONIZAR"  ,"SIMOVA_05_MONITOR_API" ,"Reenviar / Sincronizar"           ,cTabZZW,"U_SIMOVA4M","U_SIMOVA4M()"   ,4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_ATUALIZARNFS" ,"SIMOVA_05_MONITOR_API" ,"Atualizar NFS"                    ,cTabZZW,"U_SIMOVA4M","U_SIMOVA4M(.T.)",4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_BLOQUEAR"     ,"SIMOVA_05_MONITOR_API" ,"Bloquear"                         ,cTabZZW,"U_SIMOVA5M","U_SIMOVA5M()"   ,4 , .f. ,".T.", } )
    Else
        (cTabZZU)->(DbSetFilter( { || !(cTabZZU+"->"+cTabZZU+"_LOGSTA" $ ' 1') }, "!("+cTabZZU+"->"+cTabZZU+"_LOGSTA $ ' 1')" ) )
        
        AADD( aRotAdic , { "OFICINA_SIMOVA"                    ,"OFICINA"               ,"SIMOVA SMARTOS"                   ,"VO1","","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_01_INTEGRAR"                ,"OFICINA_SIMOVA"        ,"SIMOVA Integracao/OS"             ,"VO1","U_SIMOVA0I","U_SIMOVA0I" ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE"                 ,"OFICINA_SIMOVA"        ,"SIMOVA - Suporte"                 ,"VO1","","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_RPC"             ,"SIMOVA_03_SUPORTE"     ,"Preparar Reintegracao/Estorno OS" ,"VO1","U_SIMOVA6T","U_SIMOVA6T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)" ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_VERSAO"          ,"SIMOVA_03_SUPORTE"     ,"Versao App SIMOVA"                ,"VO1","U_SMV14M01","U_SMV14M01()"                                ,2 , .f. ,".T.", } )

        // If lTracker .And. Upper(Alltrim(cUserLgn)) $ Upper(Alltrim(cUserTrkr))
            // AADD( aRotAdic , { "SIMOVA_03_SUPORTE_REL001"          ,"SIMOVA_03_SUPORTE"     ,"Relat. Pos Integracao Aptos."     ,"VO1","U_SMV14R01","U_SMV14R01()"                                ,2 , .f. ,".T.", } )
        // EndIf
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS"              ,"OFICINA_SIMOVA"        ,"SIMOVA - Liberacao de OS"         ,cTabZZU,"","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS_LIBERAR"      ,"SIMOVA_04_MONITOR_OS"  ,"Liberar p/ Integracao"            ,cTabZZU,"U_SIMOVA1L","U_SIMOVA1L()"   ,4 , .f. ,".T.", } )
    Endif

    AADD( aRotAdic , { "SIMOVA_06_CONFIG"                  ,"OFICINA_SIMOVA"    ,"SIMOVA - Configuracoes"   ,cTabZZX,"","" ,0 , .f. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_VIS"              ,"SIMOVA_06_CONFIG"  ,"Visualizar"               ,cTabZZX,"U_SIMOVAVV","U_SIMOVAVV()"   ,2 , .f. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_INC"              ,"SIMOVA_06_CONFIG"  ,"Incluir"                  ,cTabZZX,'U_SIMOVAAV',"U_SIMOVAIV()"   ,3 , .T. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_ALT"              ,"SIMOVA_06_CONFIG"  ,"Alterar"                  ,cTabZZX,"U_SIMOVAAV","U_SIMOVAAV()"   ,4 , .f. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_EXC"              ,"SIMOVA_06_CONFIG"  ,"Excluir"                  ,cTabZZX,"U_SIMOVAEV","U_SIMOVAEV()"   ,5 , .f. ,".T.", } )
	//>>Final Integracao SIMOVA 

Return aRotAdic
