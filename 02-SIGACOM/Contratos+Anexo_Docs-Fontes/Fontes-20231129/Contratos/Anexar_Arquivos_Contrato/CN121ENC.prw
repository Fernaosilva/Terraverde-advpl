#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} CN121ENC
Localizado na função cn120GrvPed, responsável pelo Encerramento da Medição do Contrato. 
Este ponto de entrada é executado após gerar a rotina automática do Pedido de Vendas ou Pedido de Compras.
@type function
@version P12
@author Geeker Company
@since 14/09/2023
@link https://gkcmp.com.br (Geeker Company)
@return variant, True / False
/*/
User Function CN121ENC()
	Local ExpL1 := PARAMIXB[1]
	Local ExpL2 := PARAMIXB[2]

	If(ExpL1 = .F. .AND. ExpL2 = .T.)
		U_EnvioCTR()
	ENDIF

	//cChavearquivo := CND->CND_FILIAL +"|"+ CND_CONTRA +"|"+CND_REVISA +"|"+ CND_COMPET
Return ExpL1
