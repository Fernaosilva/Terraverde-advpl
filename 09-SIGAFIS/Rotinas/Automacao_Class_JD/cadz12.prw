#include 'protheus.ch'

User Function AX_Z12
	Local cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
	Local cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
	Private cString := "Z12"

	dbSelectArea("Z12")
	dbSetOrder(1)

	AxCadastro(cString,"Regras de validacao",cVldExc,cVldAlt)

Return
