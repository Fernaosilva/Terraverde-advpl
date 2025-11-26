#include "protheus.ch"
#include "rwmake.ch"

User Function MT100LOK()

Local nPosPro   := aScan(aHeader,{|x| Trim(x[2])=="D1_COD"})
Local nPosCC    := aScan(aHeader,{|x| Trim(x[2])=="D1_CC"}) //Centro de custo do item da solicitação
Local nPosFor   := aScan(aHeader,{|x| Trim(x[2])=="D1_FORNECE"})
LOCAL lRet      := .T.    

IF SUBSTR((aCols[ n , nPosPro ]),1,7)=='UCFRETE' .OR. aCols[n, nPosFor]=='674782'
    lRet:= .T.
ELSE
    IF EMPTY(aCols[ n , nPosCC ]) .AND.(SUBSTR((aCols[ n , nPosPro ]),1,6)=='TVDESP' .OR. SUBSTR((aCols[ n , nPosPro ]),1,2)=='UC'.OR. SUBSTR((aCols[ n , nPosPro ]),1,7)=='SERVICO' ) 
        lRet:=.F.
        FWAlertWarning('Para produtos TVDESP, UC e SERVICO é obrigatório informar Centro de Custo.',"Centro de Custo Obrigatório")
    ENDIF
ENDIF

Return(lRet)
