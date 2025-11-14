#INCLUDE "PROTHEUS.CH"

//-------------------------------------------//
// Ponto de entrada                          //
// Inclui a cor de maquina parada no         //
// browse mata103 (documento de entrada)     //
// baseado no campo F1_XALERTA               //
//-------------------------------------------//
User Function MT103COR()
	//Local aCores := aClone(PARAMIXB[1])
	//aAdd(aCores,{'Empty(F1_STATUS) .AND. F1_XALERTA <> "Z"' 	,'ENABLE'})
	//aAdd(aCores,{'Empty(F1_STATUS) .AND. F1_XALERTA  = "Z"' 	,'BR_PRETO'})

	Local aCores    	:= {	{'Empty(F1_STATUS) .AND. F1_XALERTA <> "Z"' 	,'ENABLE'	},;	// NF Nao Classificada
	{'Empty(F1_STATUS) .AND. F1_XALERTA = "Z"' 	,'BR_PRETO'		},;	// Maquina parada
	{'F1_STATUS=="B"'	,'BR_LARANJA'		},;	// NF Bloqueada
	{'F1_STATUS=="C"'	,'BR_VIOLETA'   	},;	// NF Bloqueada s/classf.
	{'F1_STATUS=="D"'	,'BR_BRANCO'	    },;	// Evento desacordo aguardando SEFAZ
	{'F1_STATUS=="E"'	,'BR_AZUL_CLARO'  	},;	// Evento desacordo vinculado
	{'F1_STATUS=="F"'	,'BR_VERDE_ESCURO' 	},;	// Evento desacordo com problemas
	{'F1_TIPO=="N"'		,'DISABLE'   		},;	// NF Normal
	{'F1_TIPO=="P"'		,'BR_AZUL'   		},;	// NF de Compl. IPI
	{'F1_TIPO=="I"'		,'BR_MARROM' 		},;	// NF de Compl. ICMS
	{'F1_TIPO=="C"'		,'BR_PINK'   		},;	// NF de Compl. Preco/Frete
	{'F1_TIPO=="B"'		,'BR_CINZA'  		},;	// NF de Beneficiamento
	{'F1_TIPO=="D"'		,'BR_AMARELO'		} }	// NF de Devolucao

Return(aCores)







