#include "totvs.ch"
#include "protheus.ch"
#include "tbiconn.ch"

//-------------------------------------------------------------------------------------------
/*/ {Protheus.doc} INTF200
Rotina utilizada para processar o arquivo de retorno do cnab de forma automática.

@author 	Charlles Reis
@version   	1.0
@since  	03/2022

/*/
//-------------------------------------------------------------------------------------------

User Function SINTF200()

	Local aParam := {"01", "0101"}

	RPCSetType(3)

	PREPARE ENVIRONMENT EMPRESA "01" FILIAL "0101" USER "jesseandrade" FUNNAME "U_SINTF200" TABLES "SE1","SM0","SEA" MODULO "FIN"

		FinA205(aParam)
		
	RESET ENVIRONMENT

Return
