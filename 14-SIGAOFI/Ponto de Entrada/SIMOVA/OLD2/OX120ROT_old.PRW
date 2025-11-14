#include "TOTVS.ch"
#include "fwmvcdef.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OX120ROT
Ponto de entrada para inclusao de rotinas em Funcoes Oficina
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OX120ROT()

    //integracao SIMOVA
    Local aRotAdic := {}
    Local cTabZZX := SuperGetMV("SIMOVAZZX",.T., "ZZX" )
    Local cTabZZW := SuperGetMV("SIMOVAZZW",.T., "ZZW" )
    Local cTabZZU := SuperGetMV("SIMOVAZZU",.T., "ZZU" )
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)
    Local SIMOVAEXP := SuperGetMV("SIMOVAEXPD",.T., .F. )
    Local SIMOVASMK := SuperGetMV("SIMOVASMRK",.T., .F. )
    PUBLIC kSimova := ""

    If SIMOVACOM == "0"
        (cTabZZU)->(DbSetFilter( { || !(cTabZZU+"->"+cTabZZU+"_LOGSTA" $ ' 1') }, "!("+cTabZZU+"->"+cTabZZU+"_LOGSTA $ ' 1')" ) )
        (cTabZZW)->(DbSetFilter( { || (cTabZZW+"->"+cTabZZW+"_STATUS" <>'0' .AND. cTabZZW+"->"+cTabZZW+"_MSBLQL" <> "1") }, "("+cTabZZW+"->"+cTabZZW+"_STATUS <> '0' .AND. "+cTabZZW+"->"+cTabZZW+"_MSBLQL <> '1')" ) )

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
        //-- AADD( aRotAdic , { "SIMOVA_03_SUPORTE_ENVIAR"          ,"SIMOVA_03_SUPORTE"     ,"Enviar OS / Suporte SIMOVA"       ,"VO1","U_SIMOVA5T","U_SIMOVA5T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)" ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_RPC"             ,"SIMOVA_03_SUPORTE"     ,"Preparar Reintegracao OS / SIMOVA","VO1","U_SIMOVA6T","U_SIMOVA6T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)" ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_VERSAO"          ,"SIMOVA_03_SUPORTE"     ,"Versao App SIMOVA"                ,"VO1","U_SMV14M01","U_SMV14M01()"                                ,2 , .f. ,".T.", } )
        If SIMOVAEXP
            AADD( aRotAdic , { "SIMOVA_03_SUPORTE_CD"              ,"SIMOVA_03_SUPORTE"     ,"Carga de Dados / SIMOVA"          ,"VO1","U_SIMOVACD","U_SIMOVACD()" ,2 , .f. ,".T.", } )
        Endif
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS"              ,"OFICINA_SIMOVA"        ,"SIMOVA - Liberacao de OS"         ,cTabZZU,"","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS_LIBERAR"      ,"SIMOVA_04_MONITOR_OS"  ,"Liberar p/ Integracao"            ,cTabZZU,"U_SIMOVA1L","U_SIMOVA1L()"   ,4 , .f. ,".T.", } )

        AADD( aRotAdic , { "SIMOVA_05_MONITOR_API"             ,"OFICINA_SIMOVA"        ,"SIMOVA - Monitor API"             ,cTabZZW,"","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_VISUALIZAR"   ,"SIMOVA_05_MONITOR_API" ,"Visualizar"                       ,cTabZZW,"U_SIMOVAVM","U_SIMOVAVM()"   ,4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_SINCRONIZAR"  ,"SIMOVA_05_MONITOR_API" ,"Reenviar / Sincronizar"           ,cTabZZW,"U_SIMOVA4M","U_SIMOVA4M()"   ,4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_ATUALIZARNFS" ,"SIMOVA_05_MONITOR_API" ,"Atualizar NFS"                    ,cTabZZW,"U_SIMOVA4M","U_SIMOVA4M(.T.)"   ,4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_BLOQUEAR"     ,"SIMOVA_05_MONITOR_API" ,"Bloquear"                         ,cTabZZW,"U_SIMOVA5M","U_SIMOVA5M()"   ,4 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_05_MANUTENCAO_SUPORTE"      ,"SIMOVA_05_MONITOR_API" ,"Suporte"                          ,cTabZZW,"U_SIMOVA7T","U_SIMOVA7T()"   ,4 , .f. ,".T.", } )
    Else
        (cTabZZU)->(DbSetFilter( { || !(cTabZZU+"->"+cTabZZU+"_LOGSTA" $ ' 1') }, "!("+cTabZZU+"->"+cTabZZU+"_LOGSTA $ ' 1')" ) )
        //AADD( aRotAdic , { "SIMOVASMARTOS"                      ,"OFICINA"              ,"SIMOVA SmartOS"                   ,"VO1","","" ,0 , .f. ,".T.", } )
        //AADD( aRotAdic , { "SIMOVASMARTOS_SMARTINT"             ,"SIMOVASMARTOS"        ,"SIMOVA Integracao/OS"             ,"VO1","U_SIMOVA0I","U_SIMOVA0I" ,2 , .f. ,".T.", } )
        //AADD( aRotAdic , { "SIMOVASMARTOS_SMARTLIB"             ,"SIMOVASMARTOS"        ,"SIMOVA Liberacao/OS"              ,"VO1","U_SIMOVA0L","U_SIMOVA0L" ,2 , .f. ,".T.", } )
        //AADD( aRotAdic , { "SIMOVASMARTOS_SUPORTE"              ,"SIMOVASMARTOS"        ,"SIMOVA OS-Suporte"                ,"VO1","U_SIMOVADS","U_SIMOVADS(VO1->VO1_NUMOSV,0,VO1->VO1_FILIAL)" ,2 , .f. ,".T.", } )
        //AADD( aRotAdic , { "SIMOVASMARTOS_OSRPC"                ,"SIMOVASMARTOS"        ,"SIMOVA RPC-OS"                    ,"VO1","U_SIMOVADS","U_SIMOVADS(VO1->VO1_NUMOSV,1,VO1->VO1_FILIAL)" ,2 , .f. ,".T.", } )
        
        AADD( aRotAdic , { "OFICINA_SIMOVA"                    ,"OFICINA"               ,"SIMOVA SMARTOS"                   ,"VO1","","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_01_INTEGRAR"                ,"OFICINA_SIMOVA"        ,"SIMOVA Integracao/OS"             ,"VO1","U_SIMOVA0I","U_SIMOVA0I" ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE"                 ,"OFICINA_SIMOVA"        ,"SIMOVA - Suporte"                 ,"VO1","","" ,0 , .f. ,".T.", } )
        //-- AADD( aRotAdic , { "SIMOVA_03_SUPORTE_ENVIAR"          ,"SIMOVA_03_SUPORTE"     ,"Enviar OS / Suporte SIMOVA"       ,"VO1","U_SIMOVA5T","U_SIMOVA5T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)"   ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_RPC"             ,"SIMOVA_03_SUPORTE"     ,"Preparar Reintegracao OS / SIMOVA","VO1","U_SIMOVA6T","U_SIMOVA6T(VO1->VO1_FILIAL,VO1->VO1_NUMOSV)" ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_03_SUPORTE_VERSAO"          ,"SIMOVA_03_SUPORTE"     ,"Versao App SIMOVA"                ,"VO1","U_SMV14M01","U_SMV14M01()"                                ,2 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS"              ,"OFICINA_SIMOVA"        ,"SIMOVA - Liberacao de OS"         ,cTabZZU,"","" ,0 , .f. ,".T.", } )
        AADD( aRotAdic , { "SIMOVA_04_MONITOR_OS_LIBERAR"      ,"SIMOVA_04_MONITOR_OS"  ,"Liberar p/ Integracao"            ,cTabZZU,"U_SIMOVA1L","U_SIMOVA1L()"   ,4 , .f. ,".T.", } )
    Endif

    AADD( aRotAdic , { "SIMOVA_06_CONFIG"                  ,"OFICINA_SIMOVA"    ,"SIMOVA - Configuracoes"   ,cTabZZX,"","" ,0 , .f. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_VIS"              ,"SIMOVA_06_CONFIG"  ,"Visualizar"               ,cTabZZX,"U_SIMOVAVV","U_SIMOVAVV()"   ,2 , .f. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_INC"              ,"SIMOVA_06_CONFIG"  ,"Incluir"                  ,cTabZZX,'U_SIMOVAAV',"U_SIMOVAIV()"   ,3 , .T. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_ALT"              ,"SIMOVA_06_CONFIG"  ,"Alterar"                  ,cTabZZX,"U_SIMOVAAV","U_SIMOVAAV()"   ,4 , .f. ,".T.", } )
    AADD( aRotAdic , { "SIMOVA_06_CONFIG_EXC"              ,"SIMOVA_06_CONFIG"  ,"Excluir"                  ,cTabZZX,"U_SIMOVAEV","U_SIMOVAEV()"   ,5 , .f. ,".T.", } )
	//>>Final Integracao SIMOVA 

    //-Rotinas do Status do Faturamento Interno
    aAdd( aRotAdic , { "OFICINA_INTERNO"    , "OFICINA"        , "Status Fat.Interno", "ZS1", ""          , ""          , 0, .F., ".T.",})
    aAdd( aRotAdic , { "OFICINA_FAT_INTERNO", "OFICINA_INTERNO", "Consultar Status"  , "ZS1", "U_FatIntSt", "U_FatIntSt", 2, .F., ".T.",})     

Return aRotAdic

/*/{Protheus.doc} FatIntSt
Apresenta tela de consulta de Status do Fat. Interno
@type function
@version 1.0
@author Ademar Fernandes Jr.
@since 25/07/2023
@link https://gkcmp.com.br (Geeker Company)
@return variant, True
/*/
User function FatIntSt()
	local nRet       := 0
	local cPrograma  := "TVLIB01"
	local cTitulo    := "Status do Faturamento Interno"
	local nOperation := MODEL_OPERATION_VIEW	//-Valores permitidos 1,3,4,5,6
	local aLjArea    := Lj7GetArea({"VO1","ZS1","Z99"})
	local oModel	 := Nil

	dbSelectArea("Z99")
	dbSetOrder(1)		//-Z99_FILIAL+Z99_ORIGEM+Z99_NUMDOC+Z99_TIPTEM+Z99_NIVEL+Z99_USER
	dbSelectArea("ZS1")
	dbSetOrder(1)		//-ZS1_FILIAL+ZS1_ORIGEM+ZS1_NUMDOC+ZS1_TIPTEM

	//-- if FWIsInCallStack("U_FATINTST") .And. !FWIsInCallStack("OXA120EXEC")
	// if !dbSeek(FwxFilial("ZS1")+"OFI"+VO1->VO1_NUMOSV,.F.)
	// 	MsgAlert(OemToAnsi("Documento NÃ£o encontrado para LiberaÃ§Ã£o Interna do Faturamento!"), OemToAnsi("[TerraVerde] AtenÃ§Ã£o!"))
	// else

		//Carrega o modelo de dados
		oModel := FWLoadModel(cPrograma)
		oModel:SetOperation(nOperation )	
		oModel:GetModel('ZS1MASTER'):SetOnlyView(.T.)
		oModel:GetModel('Z99EXTER'):SetOnlyView(.T.)
		oModel:GetModel('Z99EXTER'):SetOnlyQuery(.T.)	//-NÃ£o permite gravar as alteraÃ§Ãµes no SGBD!!

		oModel:Activate(.T.)	//-Ativa o modelo .T. com os dados posicionados .F. sem dados posicionados

		//Executando a visualizaÃ§Ã£o dos dados para manipulaÃ§Ã£o
		nRet := FWExecView( cTitulo,cPrograma,nOperation ,/*oDlg*/,{|| .T.},/*bOk*/,/*nPercReducao*/,/*aEnableButtons*/,/*bCancel*/,/*cOperatId*/,/*cToolBar*/, oModel )

		oModel:DeActivate()
		oModel:Destroy()
		oModel := NIL
	// endif

	Lj7RestArea(aLjArea)

Return .T.