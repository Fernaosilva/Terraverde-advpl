#include 'protheus.ch'
#include 'topconn.ch'
#include 'tbiconn.ch'
#include 'tbicode.ch'

/*/{Protheus.doc} EXPVMIC
Geração de arquivo csv de vendas 
@autor		Mateus Hengle.
@data		28/11/22
/*/

user function AtuCND()	

	RPCSetType(3)
	PREPARE ENVIRONMENT EMPRESA "01" FILIAL "0101"
	SetModulo("SIGAFAT", "FAT")
	
        X31UPDTABLE("CND")
	
	RESET ENVIRONMENT
    
return	
