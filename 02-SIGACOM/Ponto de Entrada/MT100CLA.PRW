#include 'TOTVS.ch'
#include 'FWPRINTSETUP.ch'
#include "RPTDEF.ch"
#include "TBICONN.ch"
#include "TOPCONN.ch
#include "COLORS.ch"
 
//--------------------------------------------------------------------------//
/*/{Protheus.doc} MT100CLA
@description : Ponto de entrada na classificacao do Doc de Entrada
@type function
@version  1.0
@author Patini  | Geeker
@since 27/05/2024
/*/     
//---------------------------------------------------------------------------//                                                                 
User Function MT100CLA()
Local _aArea	:= GetArea()
Local _aAreaSF1	:= SF1->( GetArea() )
Local lClass    := l103Class

if lClass
    //u_LgIncDoc()
endif

RestArea(_aAreaSF1)
RestArea(_aArea)
Return lClass  
