#include "rwmake.ch"

/*/{Protheus.doc} MT110LOK
description
@type function
@version  
@author fernandodasilva
@since 6/29/2024
@return variant, return_description
@history,12/05/2025,Fernando Silva, #34 - add - preenchimento da observação da SC com conteudo do campo STJ->TJ_OBSERVA 
/*/
User Function MT110LOK()

	
Local nPosPro   := aScan(aHeader,{|x| Trim(x[2])=="C1_PRODUTO"	})
Local nCenCus	:= aScan(aHeader,{|x| Trim(x[2])=="C1_CC"		}) //Centro de custo do item da solicitação
Local nPosObs	:= aScan(aHeader,{|x| Trim(x[2])=="C1_OBS"		}) //Origem da gravação função
Local lRet 		:= .T.
Local cFunc		:= If(Type("CPROGRAMA") == "C", CPROGRAMA, "")	

	If Substr((aCols[n,nPosPro]),1,6)=='TVDESP' .and. Empty(aCols[n,nCenCus])
		Msg('Para produtos TVDESP é obrigatório informar Centro de Custo.')
		lRet:=.F.
	Endif

	If Substr((aCols[n,nPosPro]),1,7)=='SERVICO' .and. Empty(aCols[n,nCenCus])
		Msg('Para produtos SERVICO é obrigatório informar Centro de Custo.')
		lRet:=.F.
	Endif

	If Substr((aCols[n,nPosPro]),1,2)=='UC' .and. Empty(aCols[n,nCenCus])
		Msg('Para produtos UC é obrigatório informar Centro de Custo.')
		lRet:=.F.
	Endif
//Preenche o campos OBS da SC quando o campo STJ->TJ_OBSERVA estiver preenchido, caso o campo esteja em branco traz a observação padrão
	IF cFunc=='MNTA410'
		IF !EMPTY(STJ->TJ_OBSERVA)
			If Len(trim(STJ->TJ_OBSERVA)) > 100
    			aCols[n,nPosObs] := Left(STJ->TJ_OBSERVAs, 100)
			Else
    			aCols[n,nPosObs] := TRIM(STJ->TJ_OBSERVA)
			EndIf
		END
	END


Return lRet
