#INCLUDE "totvs.ch"
#INCLUDE "protheus.ch"

/*/{Protheus.doc} PN80GRBH
Ponto de entrada chamado após a gravação dos dados na SPB (Resultados do período), antes de dar baixa nos registros da SPI.
@type function
@author Cristiano Pedroni
@since 08/10/2024
@version 1.0
@return Nil
/*/

User Function PN80GRBH()

	Local cParPeriodo := Alltrim(GetNewPar("ZZ_PONBA06","0920")) // Informar o Periodo para atualizacao do Resultado
	Local cParSaldo   := MV_PAR33                                // Parametro define se gera somente 1 registro na SPB.
	Local cPeriodo    := SUBSTR(DTOS(SPB->PB_DATA),5,4)

	// Funcao para atualizar o Evento de debito do Resultado do Banco de Horas (Tabela SPB).
	If ExistBlock("TERPON03") .and. cParSaldo == 1 .and. (cPeriodo == cParPeriodo)
		ExecBlock("TERPON03")
	EndIf

Return

