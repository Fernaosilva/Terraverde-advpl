#include "protheus.ch"
#include "parmtype.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} CRMA980()
Ponto de entrada MVC executado na alteraÁ„o do cadastro de clientes.
>>Aplicacao SIMOVA:
>>Grava campo SA1_XFGNFS para posterior sincronizacao com SIMOVA 
@type function
@version P12
@author Simova Tec. (WAGNER MONTENEGRO)
@since 07/10/2022
@link https://www.simova.com.br/blog
@history 17/12/2024, Ademar Fernandes Jr., Caso necess·rio, instancia o Objeto Tracker".
@return variant, True / False
/*/
//------------------------------------------------------------------------------------------ 
User Function CRMA980()
Local aParam := PARAMIXB
Local xRet := .T.
Local oObj := ""
Local cIdPonto := ""
Local cIdModel := ""
Local lIsGrid := .F.
// variaveis locais para cadastro de Item Contail
Local aArea     := GetArea()
Local aAreaCTD  := CTD->(GetArea())
Local aAreaSA1  := SA1->(GetArea())
Local cCond     := "C"                      //Se Cliente "C", se Forncedor "F".
Local cCodCli   := Alltrim(SA1->A1_COD)
Local cLojCli   := Alltrim(SA1->A1_LOJA)
Local cNomeCli  := Alltrim(SA1->A1_NOME)
Local cClasse   := "2"                      //Analùtica
Local cBloq     := "2"                      //Nùo Bloqueado

DbSelectArea("CTD")
DbSetOrder(1)
DbGoTop()
    
//Gravaùùo do Item Contùbil na Tabela CTD com a seguinte regra: 2+Cod.Cli+Loja Cli.
    If !CTD->(DbSeek(xFilial("SA1")+cCond+cCodCli+cLojCli))
        
        RecLock("CTD", .T.)
            CTD->CTD_FILIAL := xFilial("CTD")
            CTD->CTD_ITEM   := cCond+cCodCli+cLojCli
            CTD->CTD_CLASSE := cClasse  
            CTD->CTD_NORMAL := "0"
            CTD->CTD_DESC01 := cNomeCli  
            CTD->CTD_BLOQ   := cBloq
            CTD->CTD_DTEXIS := dDatabase
        MsUnlock()    
     Else
    //  Alert("O Item Contùbil ' "+cCond+cCodCli+cLojCli+" ' jù existe!")
     EndIf

    //Realiza a gravaùùo do campo personalizado A1_XITEMCT com a informaùùo do respectivo Item Contùbil da tabela CTD. 
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbGoTop()

    If SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))
        
        RecLock("SA1", .F.)
        SA1->A1_XITEMCT := CTD->CTD_ITEM
        SA1->(MsUnlock())
        
    EndIF    


    RestArea(aArea)
    RestArea(aAreaCTD)
    RestArea(aAreaSA1)
//Fim da gravaùùo do Item Contabil para cliente
//Inicio da gravaùùo SA1_XFGNFS para posterior sincronizacao com SIMOVA
If aParam <> NIL
    oObj := aParam[1]
    cIdPonto := aParam[2]
    cIdModel := aParam[3]
    lIsGrid := (Len(aParam) > 3)
    If cIdPonto == "MODELCOMMITTTS"
        //>>>Inicio Integracao SIMOVA
        //If FWCODEMP() == "01"
        	if ExistBlock("SIMOVAZT")
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
        //Endif
        //>>Final Integracao SIMOVA   
    EndIf
EndIf
Return xRet
