#include "protheus.ch"
#include "parmtype.ch"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} ITEM()
Ponto de entrada MVC executado na alteração do cadastro de produtos.
>>Aplicacao SIMOVA:
>>Grava campo B1_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------  
User Function ITEM()
    Local aParam := PARAMIXB
    Local xRet := .T.
    Local oObj := ""
    Local cIdPonto := ""
    Local cIdModel := ""
    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        If cIdPonto == "MODELCOMMITTTS" .and. oObj:NOPERATION <> 5
            //integracao SIMOVA
        	if ExistBlock("SIMOVAZT")
                U_SIMOVAZT(PROCNAME(),,@oObj)
            endif
            //>>Final Integracao SIMOVA                     
        EndIf
    EndIf
Return xRet


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OMSA060()
Ponto de entrada MVC executado na alteração do cadastro de veículos OMS/TMS Tabela DA3.
>>Aplicacao SIMOVA:
>>Grava campo DA3_XFGNFS para posterior sincronizacao com SIMOVA 
@author    WAGNER MONTENEGRO
@since     07/10/2022
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
            //integracao SIMOVA
        	if ExistBlock("SIMOVAZT")
                U_SIMOVAZT(PROCNAME())
            endif
            //>>Final Integracao SIMOVA             
        EndIf
    EndIf
Return xRet


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} CRMA980()
Ponto de entrada MVC executado na alteração do cadastro de clientes.
>>Aplicacao SIMOVA:
>>Grava campo SA1_XFGNFS para posterior sincronizacao com SIMOVA 
>>Verificação para gravação do Item Contabil para CLiente Regra: "C"+Cod.Cliente+Loja Cliente
@author    WAGNER MONTENEGRO / 
@since     07/10/2022
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
Local cClasse   := "2"                      //Analítica
Local cBloq     := "2"                      //Não Bloqueado

DbSelectArea("CTD")
DbSetOrder(1)
DbGoTop()
    
//Gravação do Item Contábil na Tabela CTD com a seguinte regra: 2+Cod.Cli+Loja Cli.
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
    //  Alert("O Item Contábil ' "+cCond+cCodCli+cLojCli+" ' já existe!")
     EndIf

    //Realiza a gravação do campo personalizado A1_XITEMCT com a informação do respectivo Item Contábil da tabela CTD. 
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
//Fim da gravação do Item Contabil para cliente
//Inicio da gravação SA1_XFGNFS para posterior sincronizacao com SIMOVA
If aParam <> NIL
    oObj := aParam[1]
    cIdPonto := aParam[2]
    cIdModel := aParam[3]
    lIsGrid := (Len(aParam) > 3)
    If cIdPonto == "MODELCOMMITTTS"
        //integracao SIMOVA
        //If FWCODEMP() == "01"
        	if ExistBlock("SIMOVAZT")
                U_SIMOVAZT(PROCNAME())
            endif
        //Endif
        //>>Final Integracao SIMOVA   
    EndIf
EndIf
//Fim da gravação SA1_XFGNFS para posterior sincronizacao com SIMOVA
Return xRet
