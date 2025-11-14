#Include "PROTHEUS.CH"
//--------------------------------------------------------------
/*/{Protheus.doc} TlIncDoc
Tela para mostrar o log
                                                                
@param xParam Parameter Description                             
@return xRet Return Description                                 
@author  -                                               
@since 08/05/2024                                                   
/*/                                                             
//--------------------------------------------------------------
user function TlIncDoc( cGDt, cGHora, cGet1 )
    local oBtOk
    local oGDt,oGDt1    
    local oGet1,oGet2    
    local oGHora,oGHora1    
    local oGrp,oGrp1
    local oSDt,oSDt1
    local oSHr,oSHr1
    local oSUsr,oSUsr1
    
    default cGDt      := DtoC( SF1->F1_XDTINC )
    default cGDt1     := Dtoc(SF1->F1_XDTCLAS)
    default cGHora    := SF1->F1_XHRINC
    default cGet1     := SF1->F1_XUSRINC
    default cGet2     := SF1->F1_XHRCLAS
    default cGet3     := SF1->F1_XUSCLAS
    
    static oDlg

    DEFINE MSDIALOG oDlg TITLE "LOG -INCLUSAO / CLASSIFICAÇÃO" FROM 000, 000  TO 400, 355 COLORS 0, 16777215 PIXEL
    //log inclusao
        @ 006, 006 GROUP oGrp TO 072, 168 PROMPT "Log de inclusão" OF oDlg COLOR 0, 16777215 PIXEL

        @ 020, 015 SAY  oSDt PROMPT "Data inclusão:" SIZE 042, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 020, 057 MSGET oGDt VAR cGDt SIZE 060, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL

        @ 036, 018 SAY oSHr PROMPT "Hora inclusão:" SIZE 038, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 036, 057 MSGET oGHora VAR cGHora SIZE 060, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL

        @ 052, 030 SAY oSUsr PROMPT "Usuário:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 051, 057 MSGET oGet1 VAR cGet1 SIZE 094, 010 OF oDlg COLORS 0, 16777215 PIXEL

    //log de classificação    
        @ 078, 006 GROUP oGrp1 TO 144, 168 PROMPT "Log de Classificação" OF oDlg COLOR 0, 16777215 PIXEL

        @ 092, 015 SAY  oSDt1 PROMPT "Data Classif.:" SIZE 042, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 092, 057 MSGET oGDt1 VAR cGDt1 SIZE 060, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL

        @ 108, 018 SAY oSHr1 PROMPT "Hora Classifi.:" SIZE 038, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 108, 057 MSGET oGHora1 VAR cGet2 SIZE 060, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL

        @ 124, 030 SAY oSUsr1 PROMPT "Usuário:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 123, 057 MSGET oGet2 VAR cGet3 SIZE 094, 010 OF oDlg COLORS 0, 16777215 PIXEL
        @ 160, 070 BUTTON oBtOk PROMPT "Confirmar" SIZE 037, 012 OF oDlg PIXEL ACTION ( oDlg:End() )
       
    ACTIVATE MSDIALOG oDlg CENTERED

return
