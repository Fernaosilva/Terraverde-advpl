#INCLUDE "rwmake.ch"
#INCLUDE "Topconn.ch"
#INCLUDE "PROTHEUS.ch"

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//  Função:    F050BUT  								 Módulo: SIGAFIN          //
//                                                                                //
//  Autor:    Debus Guedes			  					 Data: 25/04/2023   	  //
//                                                                                //
//  Descrição: Ponto de Entrada para inclusão de botão no browse de títulos       //
//             a pagar												              //
//                                                                                //
//  Uso:       Específico da Terra Verde							              //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////

User Function F050ROT

Local aArea   := GetArea()
Local aRotina := Paramixb // Array contendo os botoes padrões da rotina.


    Aadd(aRotina, { "Codigo de Barras", "U_TV06A05", 0, 8, 0,.F.})
     
    RestArea(aArea)
 
Return aRotina

User Function TV06A05

    Local lOk     := .F.
	Local oBtnLib := Array(02)
	Local oCampos := Array(10)
	Local cCodBar := SE2->E2_CODBAR
	
		
		DEFINE MSDIALOG oDlgLib TITLE "Alteração de título a pagar: " + SE2->E2_PREFIXO + "/" + SE2->E2_NUM FROM 0,0 TO 180,500  OF oMainWnd PIXEL
		
			@ 017,005 Say "Codigo Barra:" of oDlgLib PIXEL
			@ 015,060 msGet oCampos[01] Var @cCodBar of oDlgLib PIXEL SIZE 170,10 Valid VldE2CODBAR(@cCodBar)
		
        	@ 060,030   BUTTON oBtnLib[01] PROMPT "Confirma"     of oDlgLib   SIZE 88,13 PIXEL ACTION (lOk := .T. , oDlgLib:End())
			@ 060,129   BUTTON oBtnLib[02] PROMPT "Cancela"      of oDlgLib   SIZE 88,13 PIXEL ACTION (lOk := .F. , oDlgLib:End())
		
		ACTIVATE MSDIALOG oDlgLib CENTERED
		
		If lOk
			If msgYesNo("Confirma alteração do título: " + SE2->E2_PREFIXO + "/" + SE2->E2_NUM + " ?")
				RecLock("SE2", .f.)

					SE2->E2_CODBAR  := cCodBar
				

				SE2->( msUnLock() )
				msgInfo("Título: " + SE2->E2_PREFIXO + "/" + SE2->E2_NUM + " alterado com sucesso!")
			EndIf
		Endif
		
Return

/*/{Protheus.doc} Static Function CBOSX3
	Carregar Valores de Combo Box do Tipo Imposto
	@author Fernando Macieira
    @since 20/08/2019
	@version 01
/*/


/*/{Protheus.doc} Static Function VldE2CODBAR(cCodBar)
	Validação do Campo de Codigo de Barras do titulo do Contas a Pagar
	@author Fernando Macieira
    @since 20/08/2019
	@version 01
/*/

Static Function VldE2CODBAR(cCodBar)

	Local lRet := .f.
	
	// Variaveis de memoria
	M->E2_CODBAR  := AllTrim(cCodBar)
	M->E2_SALDO   := SE2->E2_SALDO
	M->E2_ACRESC  := SE2->E2_ACRESC
	M->E2_DECRESC := SE2->E2_DECRESC

	IF ALLTRIM(cCodBar) <> ''
	
		cCodBar := U_CONVLD()
		M->E2_CODBAR := cCodBar
		
		cCodBar := ChkVlBol()
		M->E2_CODBAR := cCodBar                                                                 
		
		lRet := VldCodBar(cCodBar)
		
		If lRet
			lRet := EXECBLOCK('CODBAR',.T.)
		EndIf
	
	ELSE

		lRet := .T.


	ENDIF

Return lRet

Static Function ChkVlBol() 
        barra := ""
        valor := ""
        barra := LTRIM(RTRIM(M->E2_CODBAR))
        valor := val(SubStr(barra,10,8)+"."+SubStr(barra,18,2))
        sld := E2_SALDO +E2_ACRESC - E2_DECRESC
		
		        IF valor > 0
	        IF  sld <> valor
	               IF !MsgBox('O valor do boleto é diferente do saldo à pagar do título. Deseja continuar ?', " ALERTA " , "YESNO")
	                  M->E2_CODBAR := ""
	               END IF
	        END IF
	    END IF    
Return M->E2_CODBAR
