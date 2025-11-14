
#include "rwmake.ch"
#include "protheus.ch"
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} CVFL6TDN

	PE utilizado após a criação de todos os niveis do cadastrador

	@type function
    @author TICWAY
    @since 05/12/2022
    @version 1.0
/*/
User Function CVFL6TDN()

	Local aArea 	:= GetArea()
	Local cCodSeq	:= ParamixB[1]
	Local cNomRot	:= GetNomRot(cCodSeq)

	If Alltrim(cNomRot) == "MATA010"
		AtuCodProd(cCodSeq) 
	EndIf
	
	RestArea(aArea)
Return


/*/{Protheus.doc} GetNomRot

	Retorna o nome da rotina do execauto

	@type function
    @author TICWAY
    @since 05/12/2022
    @version 1.0
/*/
Static Function GetNomRot(cCodSeq)

Local aArea 	:= GetArea()
Local cArqTmp	:= GetNextAlias()
Local cRet		:= ""

Default cCodSeq := ""

BEGINSQL Alias cArqTmp
	SELECT DISTINCT PZA_NROTIN FROM %TABLE:PZD% PZD

	INNER JOIN %TABLE:PZA% PZA
	ON PZA.PZA_FILIAL = PZD.PZD_FILIAL
	AND PZA.PZA_COD = PZD.PZD_COD
	AND PZA.%NOTDEL%

	WHERE PZD.PZD_FILIAL = %xFilial:PZD%
	AND PZD.PZD_CODCAD = %Exp:cCodSeq%
	AND PZD.%NOTDEL%
EndSql

If (cArqTmp)->(!Eof())
	cRet := Alltrim((cArqTmp)->PZA_NROTIN)
EndIf

If Select(cArqTmp) > 0
	(cArqTmp)->(DBCloseArea())
Endif
 
RestArea(aArea)
Return cRet


/*/{Protheus.doc} AtuCodProd

	Atualiza o codigo do produto

	@type function
    @author TICWAY
    @since 05/12/2022
    @version 1.0
/*/
Static Function AtuCodProd(cCodSeq)

	Local aArea 	:= GetArea()
	Local cArqTmp	:= GetNextAlias()
	Local cCpoAux	:= ""
	Local cDadosAux	:= ""
   	Local aCpoNiv 	:= {}
	Local cClassProd	:= ""
	Local nX		:= 0
	Local lProc		:= .F.   

	Default cCodSeq := ""

	BEGINSQL ALIAS cArqTmp

		SELECT PZD.R_E_C_N_O_ RECPZD, PZD_NIVEL FROM %TABLE:PZD% PZD 

		WHERE PZD.PZD_FILIAL = %xFilial:PZD%
		AND PZD.PZD_CODCAD = %Exp:cCodSeq%
		AND PZD.%NOTDEL%
		ORDER BY PZD_NIVEL

	ENDSQL

	While (cArqTmp)->(!Eof())

		cCpoAux		:= ""
		cDadosAux	:= ""
   		aCpoNiv 	:= {}

		PZD->(DbGoTo((cArqTmp)->RECPZD))

	   //Campos por nivel
		aCpoNiv 		:=  Separa(Alltrim(PZD->PZD_CAMPO),"|")

		//Preenchimento dos campos
		For nX := 1 To Len(aCpoNiv)
		
			If Empty(cCpoAux).And. Empty(cDadosAux)
				cCpoAux		+= aCpoNiv[nX]

				If Alltrim(aCpoNiv[nX]) == "B1_YCLASSP"
					cClassProd := U_CVXTOCHA( aCpoNiv[nX], M->&(Alltrim(aCpoNiv[nX])))
					cDadosAux	+= U_CVXTOCHA( aCpoNiv[nX], M->&(Alltrim(aCpoNiv[nX])))
				
				ElseIf Alltrim(aCpoNiv[nX]) == "B1_COD" .And. !Empty(cClassProd)
					cDadosAux	+= GetSeqCod(cClassProd)
					lProc := .T.
				Else
					cDadosAux	+= U_CVXTOCHA( aCpoNiv[nX], M->&(Alltrim(aCpoNiv[nX])))
				EndIf
			Else
				cCpoAux		+= "|"+aCpoNiv[nX]

				If Alltrim(aCpoNiv[nX]) == "B1_YCLASSP"
					cClassProd := U_CVXTOCHA( aCpoNiv[nX], M->&(Alltrim(aCpoNiv[nX])))
					cDadosAux	+= "|"+U_CVXTOCHA( aCpoNiv[nX], M->&(Alltrim(aCpoNiv[nX])))

				ElseIf Alltrim(aCpoNiv[nX]) == "B1_COD" .And. !Empty(cClassProd)
					cDadosAux	+= "|"+GetSeqCod(cClassProd)
					lProc := .T.
				Else
					cDadosAux	+= "|"+U_CVXTOCHA( aCpoNiv[nX], M->&(Alltrim(aCpoNiv[nX])))
				EndIf


			EndIf
		
		Next

		If lProc
			Reclock("PZD",.F.)
			PZD->PZD_CAMPO		:= cCpoAux
			PZD->PZD_DADOS		:= cDadosAux
			PZD->(MsUnLock())
			
			Exit
        EndIf

		(cArqTmp)->(DbSkip())
	EndDo


	If Select(cArqTmp) > 0
		(cArqTmp)->(DbCloseArea())
	EndIf

	RestArea(aArea)
Return



Static Function GetSeqCod(cClassProd)

	Local aArea 	:= GetArea()
	Local cRet		:= ""

	Default cClassProd := ""

	If Alltrim(cClassProd) == 'D'
		cRet := U_CV6SEQCD("Z2")
		
	ElseIf Alltrim(cClassProd) == 'P'
		cRet := U_CV6SEQCD("Z3")
	
	ElseIf Alltrim(cClassProd) == 'I'
		cRet := U_CV6SEQCD("Z4")
	
	ElseIf Alltrim(cClassProd) == 'S'
		cRet := U_CV6SEQCD("Z5")
	
	ElseIf Alltrim(cClassProd) == 'R'
		cRet := U_CV6SEQCD("Z6")

	ElseIf Alltrim(cClassProd) == 'T'
		cRet := U_CV6SEQCD("Z7")		

	
	EndIf

	RestArea(aArea)
Return cRet


/*/{Protheus.doc} CV6SEQCD
   
    Sequencia de codigo
	
	@type function
    @author ticway
    @since 29/12/2022
    @version 1.0
/*/
User Function CV6SEQCD(cTabSeq)

Local aArea 	:= GetArea()
Local cSeqRet   := ""

Default cTabSeq	:= "Z2"

DbSelectArea("SX5")
DbSetorder(1)
If SX5->(DbSeek(FWxFilial("SX5") + cTabSeq) )

	cSeqRet := Alltrim(SX5->X5_DESCRI)

	RecLock("SX5",.F.)
	SX5->X5_DESCRI := Soma1(cSeqRet)
	SX5->(MsUnLock())

Endif


RestArea(aArea)
Return cSeqRet


/*/{Protheus.doc} MyNewSX6
   
    Cria e retorna o valor do parametro no SX6
	
	@type function
    @author ticway
    @since 29/12/2022
    @version 1.0
/*/
User Function MyNewSX6( cMvPar, xValor, cTipo, cDescP, cDescS, cDescE, lAlter , lFilial)

	Local aAreaAtu	:= GetArea()
	Local lRecLock	:= .F.
	Local xlReturn

	Default lAlter 	:= .F.
	Default lFilial	:= .F.

	If ( ValType( xValor ) == "D" )
		If " $ xValor
			xValor := Dtoc( xValor, "ddmmyy" )
		Else
			xValor	:= Dtos( xValor )
		Endif
	ElseIf ( ValType( xValor ) == "N" )
		xValor	:= AllTrim( Str( xValor ) )
	ElseIf ( ValType( xValor ) == "L" )
		xValor	:= If ( xValor , ".T.", ".F." )
	EndIf

	DbSelectArea('SX6')
	DbSetOrder(1)

	If lFilial
		lRecLock := !MsSeek( cFilAnt + Padr( cMvPar, Len( X6_VAR ) ) )
	Else
		lRecLock := !MsSeek( Space( Len( X6_FIL ) ) + Padr( cMvPar, Len( X6_VAR ) ) )
	EndIf

	If lRecLock

		RecLock( "SX6", lRecLock )

		If lFilial
			FieldPut( FieldPos( "X6_FIL" ), cFilAnt )
		EndIf

		FieldPut( FieldPos( "X6_VAR" ), cMvPar )

		FieldPut( FieldPos( "X6_TIPO" ), cTipo )

		FieldPut( FieldPos( "X6_PROPRI" ), "U" )

		If !Empty( cDescP )
			FieldPut( FieldPos( "X6_DESCRIC" ), SubStr( cDescP, 1, Len( X6_DESCRIC ) ) )
			FieldPut( FieldPos( "X6_DESC1" ), SubStr( cDescP, Len( X6_DESC1 ) + 1, Len( X6_DESC1 ) ) )
			FieldPut( FieldPos( "X6_DESC2" ), SubStr( cDescP, ( Len( X6_DESC2 ) * 2 ) + 1, Len( X6_DESC2 ) ) )
		EndIf

		If !Empty( cDescS )
			FieldPut( FieldPos( "X6_DSCSPA" ), cDescS )
			FieldPut( FieldPos( "X6_DSCSPA1" ), SubStr( cDescS, Len( X6_DSCSPA1 ) + 1, Len( X6_DSCSPA1 ) ) )
			FieldPut( FieldPos( "X6_DSCSPA2" ), SubStr( cDescS, ( Len( X6_DSCSPA2 ) * 2 ) + 1, Len( X6_DSCSPA2 ) ) )
		EndIf

		If !Empty( cDescE )
			FieldPut( FieldPos( "X6_DSCENG" ), cDescE )
			FieldPut( FieldPos( "X6_DSCENG1" ), SubStr( cDescE, Len( X6_DSCENG1 ) + 1, Len( X6_DSCENG1 ) ) )
			FieldPut( FieldPos( "X6_DSCENG2" ), SubStr( cDescE, ( Len( X6_DSCENG2 ) * 2 ) + 1, Len( X6_DSCENG2 ) ) )
		EndIf

		If lRecLock .Or. lAlter
			FieldPut( FieldPos( "X6_CONTEUD" ), xValor )
			FieldPut( FieldPos( "X6_CONTSPA" ), xValor )
			FieldPut( FieldPos( "X6_CONTENG" ), xValor )
		EndIf

		MsUnlock()

	EndIf

	xlReturn := GetNewPar(cMvPar)

	RestArea( aAreaAtu )


Return(xlReturn)

