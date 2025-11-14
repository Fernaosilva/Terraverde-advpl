#include 'totvs.ch'

/*/{Protheus.doc} FA050INC()
 
    A finalidade do ponto de entrada FA050INC é permitir validações de usuário
    na inclusão do Contas a Pagar (FINA050), localizado no TudoOK da rotina.
 
    @return lRet - lógico, .T. valida a inclusão e continua o processo,
        caso contrário .F. e interrompe o processo.
/*/

User Function FA050INC()
	Local lRet := .T.

	// Validações de usuário

	If M->E2_PREFIXO='MAN' .AND. EMPTY(M->E2_CCUSTO)
	lRet := .F.
		// Mensagem de Help para esclarescer o motivo de interromper a inclusão
		Help( ,, 'Help',, "Campo Centro de Custo não pode ser em branco.", 1, 0 )

		// Alterando lMsErroAuto para .T. (verdadeiro), devido aos casos de integrações ou ExecAuto
		lMsErroAuto := .T.
	EndIf
	

Return lRet
