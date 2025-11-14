#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'

//Fonte Para pegar a conta contabil cadastrada na natureza
/*
    
*/

User Function TVCTB002(cFildoc,cDoc,cSerie,cforne,cLoja) 


Local cNatu     :=''
Local cCtaNat   :=''
//Local cFildoc   :=''
Local cQuery    :=''


cQuery    := " SELECT * "
cQuery    += " FROM "+RetSqlName("SE2")
cQuery    += " WHERE E2_FILIAL = '"+cFildoc+"' AND "
cQuery    += " E2_NUM='"+cDoc+"' AND E2_FORNECE='"+cForne+"' AND E2_LOJA='"+cLoja+"'"


TCQUERY cQuery NEW ALIAS "EDCTB"

cNatu:=TRIM(EDCTB->E2_NATUREZ)
EDCTB->(dBCloseArea())

DBSELECTAREA("SED")
DBSETORDER(1)

IF DBSEEK(xFilial("SED")+cNatu)
    cCtaNat := SED->ED_CONTA
END

Return (cCtaNat)
