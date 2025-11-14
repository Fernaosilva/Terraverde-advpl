#include "TOTVS.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} OM030COR
Ponto de entrada para customizacao de Legendas em Requisicao de Servicos/Apontamentos em conjunto com OM030CLG
>>Aplicacao SIMOVA:
>>Disponibiliza rotinas SIMOVA
@author    WAGNER MONTENEGRO
@since     07/10/2022
/*/
//------------------------------------------------------------------------------------------ 
User Function OM030COR() // COR LEGENDA REQUISICAO DE SERVICOS
	//integracao SIMOVA
    Local aRet := ParamIxb[01]
    Local aLeg := ParamIxb[02]
    Local lLgSimova0 := SuperGetMV("SIMOVALEG0",.T., .F. )
    Local lLgSimova1 := SuperGetMV("SIMOVALEG1",.T., .F. )
    Local cLgSimova  := SuperGetMV("SIMOVALEGC",.T., "VERDE_LARANJA" )
    Local cOSxBol	 := SuperGetMV("SIMOVAOSBO",.T., "0" )
    Local lSyncON	 := SuperGetMV("SIMOVASVO1",.T., .T. )
    Local cBoletim   := "1"
    Local SIMOVACOM := SuperGetMV("SIMOVATPOI",.T., "1" )   //-Tipo de Integracao SmartOS (0=API/1=PDI)
    Local cDtPrd := SuperGetMV("SIMOVADTPD",.T., "" ) 
    Local SIMOVAPDI := SuperGetMV("SIMOVACPDI",.T., .F. )

    If SIMOVACOM == "0"
        If lLgSimova0
            aRet[1][1] += ' .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'( VO1->VO1_DATABE < CTOD("'+cDtPrd+'") .OR. VO1->VO1_DATABE >= CTOD("'+cDtPrd+'")  .AND. (Empty(VO1->VO1_XSIMOT) .AND. Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP) .AND. Empty(VO1->VO1_XFGNFS) .AND. "1"== "'+If(lSyncON,'2','1')+'" ))','(Empty(VO1->VO1_XSIMOT) .AND. Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP) .AND. EMPTY(VO1->VO1_XFGNFS)  .AND. "1"== "'+If(lSyncON,'2','1')+'" )') //+' (Empty(VO1->VO1_XSIMOT) .AND. Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP))'
            AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. ( VO1->VO1_XFGNFS == "2" .AND. Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR)  .AND. Empty(VO1->VO1_XSIMOP) .OR. VO1->VO1_XFGNFS == "2" .AND. !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR)  .AND. Empty(VO1->VO1_XSIMOP) )' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_S_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_S_"+cLgSimova}),02] } )
            AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. !Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP) .AND. VO1->VO1_XFGNFS == "2" .AND. ( "'+cBoletim+'"<>"'+cOSxBol+'" .OR. "'+cBoletim+'"=="'+cOSxBol+'" .AND. VO1->VO1_XSIMOR >= VO1->VO1_XSIMOV )' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_R_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_R_"+cLgSimova}),02] } )
            AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. !Empty(VO1->VO1_XSIMOR) .AND. !Empty(VO1->VO1_XSIMOP) .AND. ( VO1->VO1_XSIMOP >= VO1->VO1_XSIMOR .AND. ( VO1->VO1_XFGNFS == "2" .OR. !Empty(VO1->VO1_XSIMOE) ).AND. "'+cBoletim+'"<>"'+cOSxBol+'" .OR. VO1->VO1_XSIMOR >= VO1->VO1_XSIMOV .AND. VO1->VO1_XSIMOP >= VO1->VO1_XSIMOR .AND. ( VO1->VO1_XFGNFS == "2" .OR. !Empty(VO1->VO1_XSIMOE) ) .AND. "'+cBoletim+'"=="'+cOSxBol+'")', aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_I_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_I_"+cLgSimova}),02] } )
            If lLgSimova1
                AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' ( VO1->VO1_XFGNFS '+If(lSyncON,'<> "2"','== "1"')+' .AND. Empty(VO1->VO1_XSIMOT) .OR. !EMPTY(VO1->VO1_XFGNFS) .AND. Empty(VO1->VO1_XSIMOT) .AND. Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP) .OR. !EMPTY(VO1->VO1_XFGNFS) .AND. Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) )' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_SN_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_SN_"+cLgSimova}),02] } )
                AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. Empty(VO1->VO1_XSIMOV)' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_VN_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_VN_"+cLgSimova}),02] } )
                AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. !Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' ( Empty(VO1->VO1_XSIMOT) .OR. Empty(VO1->VO1_XSIMOV))' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_S_VERMELHO"}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_S_VERMELHO"}),02] } )
                AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. !Empty(VO1->VO1_XSIMOR) .AND. !Empty(VO1->VO1_XSIMOP) .AND. ( VO1->VO1_XSIMOP >= VO1->VO1_XSIMOR .AND. "'+cBoletim+'"<>"'+cOSxBol+'" .OR. VO1->VO1_XSIMOR >= VO1->VO1_XSIMOV .AND. VO1->VO1_XSIMOP >= VO1->VO1_XSIMOR .AND. "'+cBoletim+'"=="'+cOSxBol+'")', aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_SN_PRETO"}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_SN_PRETO"}),02] } )    
                If cOSxBol == "0"
                    AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' (!Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) .OR. Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) )' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_RN_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_RN_"+cLgSimova}),02] } )
                    AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. !Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' ( !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) )' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_R_VERMELHO"}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_R_VERMELHO"}),02] } )
                    AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' (!Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. !Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP)  .OR. Empty(VO1->VO1_XSIMOV) .AND. !Empty(VO1->VO1_XSIMOR))' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_IN_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_IN_"+cLgSimova}),02] } )
                Else
                    AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. Empty(VO1->VO1_XSIMOE) .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. Empty(VO1->VO1_XSIMOR) ' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_RN_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_RN_"+cLgSimova}),02] } )

                    AADD( aRet , { 'VO1->VO1_STATUS == "A" .AND. '+If(!Empty(cDtPrd) .and. !SIMOVAPDI,'VO1->VO1_DATABE >= CTOD("'+cDtPrd+'") .AND.','')+' !Empty(VO1->VO1_XSIMOT) .AND. !Empty(VO1->VO1_XSIMOV) .AND. !Empty(VO1->VO1_XSIMOR) .AND. Empty(VO1->VO1_XSIMOP)' , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_IN_"+cLgSimova}),01] , aLeg[AScan(aLeg, {|x|x[1]=="SIMOVA_IN_"+cLgSimova}),02] } )
                Endif
            Endif
        Endif
    Endif    
	//>>Final Integracao SIMOVA 
Return(aRet)
