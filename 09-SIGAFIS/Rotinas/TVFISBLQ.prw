#Include "RWMAKE.CH"

User Function TVFISBLQ()

// Definição das variáveis do programa.
Public _mvDatafis := GetMv("MV_DATAFIS")
Public _mvDatafin := GetMv("MV_DATAFIN")
Public _mvDatarec := GetMv("MV_DATAREC")   
Public _mvDblqmov := GetMv("MV_DBLQMOV")
Public _mvUserLib := GetMv("TV_USERLIB")

// Verifica se o usuário é o Administrador do sistema ou usuários autorizados.
If !Alltrim(__cUserID) $ GetMv("TV_USERLIB")
     Alert("Somente o Administrador ou usuários autorizados podem executar esta rotina.")
     Return
EndIf   

// Solicita ao usuário nome do arquivo.
     @ 150, 1 TO 400, 435 DIALOG oMyDlg TITLE OemToAnsi("Bloqueio de Parâmetros")
     @   2, 10 TO 110, 210
     @ 10, 18 Say " Data limite p/operações fiscais?"
     @ 10,115 Get _mvDatafis Size 50,50
     @ 20, 18 Say " Data limite p/operações financeiras?"
     @ 20,115 Get _mvDatafin Size 50,50
     @ 30, 18 Say " Data limite p/reconciliação banc.?"
     @ 30,115 Get _mvDatarec Size 50,50
     @ 40, 18 Say " Bloq. Mov. Estoque/Fiscal?"    
     @ 40,115 Get _mvDblqmov Size 50,50
     @ 50, 18 Say " Último fech.estoque: " + Transform(GETMV("MV_ULMES"),"@D")    
     @ 60, 18 Say ""
     @ 70, 18 Say ""
     @ 80, 18 Say ""
     @ 90, 18 Say ""
     @ 110,150 BMPBUTTON TYPE 01 ACTION (RunProc(), Close(oMyDlg))
     @ 110,180 BMPBUTTON TYPE 02 ACTION Close(oMyDlg)
     Activate Dialog oMyDlg Centered

Return

Static Function RunProc()

// Faz validações e Altera os parâmetros.
     If !Empty(_mvDatafis)
          PutMv("MV_DATAFIS",_mvDatafis)
     EndIf
     
     If !Empty(_mvDatafin)
          PutMv("MV_DATAFIN",_mvDatafin)
     EndIf
     
     If !Empty(_mvDatarec)
          PutMv("MV_DATAREC",_mvDatarec)
     EndIf   
     
     If !Empty(_mvDblqmov)
          PutMv("MV_DBLQMOV",_mvDblqmov)
     EndIf   

Return
