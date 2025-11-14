#include 'protheus.ch'

/*/{Protheus.doc} MT103FIM
O ponto de entrada MT103FIM encontra-se no final da função A103NFISCAL. 
Após o destravamento de todas as tabelas envolvidas na gravação do documento de entrada, depois de fechar a operação realizada neste, 
 é utilizado para realizar alguma operação após a gravação da NFE

@author 	Fabio Hayama - GEeker
@since 		07/03/2016
@version	1.0
/*/

user function MT103FIM()
	local aArea       := GetArea()
  local aAreaLj7    := Lj7GetArea({"VM0", "SD1", "SA2", "SB1", "SF1"})
	local nOpcao 			:= PARAMIXB[1]    
	local nConfirma 	:= PARAMIXB[2]
	
	if( nConfirma == 1 .AND. nOpcao == 3 )

		u_LgIncDoc()
	
	endIf

    Lj7RestArea(aAreaLj7)
    RestArea(aArea)
return
