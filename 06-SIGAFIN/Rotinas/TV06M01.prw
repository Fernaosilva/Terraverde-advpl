#include "Totvs.ch"
#INCLUDE "TBICONN.CH"

//-------------------------------------------------------------------------------------
/*/{Protheus.doc} TV06M01
Rotina para realizar o envio de email de cobrança através de job

Uso: Financeiro

@author    	Denis Guedes
@version   	1.0
@since      Março/2023
/*/
//-------------------------------------------------------------------------------------




User Function TV06M01(aParam)
	Local oProcess
	Private oObj   := TVCLCOB():New()
	Private lJob   := IsBlind() 
	
	
	If lJob
		RpcSetType(3)
		lSetEnv  := RpcSetEnv(aParam[1],aParam[2],,,"")
		czEMP    := aParam[1]   
		czFIL    := aParam[2]   
		
		PREPARE ENVIRONMENT EMPRESA czEMP FILIAL czFIL MODULO "FIN"
		    
		//oProcess := Executa()
		oProcess := oObj:execute()
	Else
		FwMsgRun(NIL, {|| oObj:execute() }, "Processando", "Enviando email com titulos em atraso...")
	Endif
	
	//

	

Return
