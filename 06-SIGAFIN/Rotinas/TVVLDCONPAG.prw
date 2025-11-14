#Include 'Protheus.ch'
#Include "Totvs.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} TVVLDCND
@type user function
@author Fernando Silva
@since 25/03/2024
@version 12.1.2210
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
Validação da condição de pagamento, entrada ou saida
E4_XTIPO = S para saidas e E4_XTIPO = E para entradas

@see (links_or_references)
@history 25/03/2024,Fernando Silva,Criação
/*/
User Function TVVLDCND(cCondPG,cTpRotina)//Paramentros enviados pela chamada da função codigo da condição de pagamento, tipo da rotina (Entrada ou saida)
	local lRet      := .F.
	local cTipocond := ''

	//Abre Tabela de condição de pagamento
	DbSelectArea("SE4")
	DbSetOrder(1)

	//Se a condição digitada existir valida
	if( SE4->( DbSeek(xfilial("SE4")+ PadR( cCondPG, GetSX3Cache("E4_CODIGO", "X3_TAMANHO") ) ) ) )

		cTipocond := SE4->E4_XTIPO //Recebe o tipo da condição E=Entrada e S=Saida
	   
		if( Alltrim( Upper( cTpRotina )) == 'SAIDA' )
		   lRet := VLDSAIDA( cTipocond ) //Chama validação para rotina de saida
		   
		elseif( Alltrim( Upper( cTpRotina=='ENTRADA' ) ))
		   lRet := VLDENTRA( cTipocond ) //chama validação para rotina de entrada
		   
		else
			Alert("Rotina não identificada informar TI - Validação campo X3")//caso o parametro do tipo de rotina não seja enviado retorna alert
		endif
	else
		Alert("Condição de Pagamento não existe para esta filial!")//Caso a condição de pagamento não exista na SE4 para a filial
		
		Return lRet
	endif

	SE4->(DbCloseArea())

return lRet

static function VLDSAIDA(cTipocond)
	//Se a rotina for de saida não permite condição de pagamento
    if( Alltrim( Upper( cTipocond ) ) <> 'S' )
        Alert("Condição de pagamento invalida para operação de saída!")
        lRet := .F.
    else
        lRet := .T.
    endif

return lRet

//Fim da Função VLDSAIDA

user function VLDENTRA(cTipocond)

    if( Alltrim( Upper( cTipocond ) ) <> 'E' )
        Alert("Condição de pagamento invalida para operação de saída!")
	
        lRet:= .F.
    else
        lRet:= .T.
    endif

return lRet
// fim da função vldentra

