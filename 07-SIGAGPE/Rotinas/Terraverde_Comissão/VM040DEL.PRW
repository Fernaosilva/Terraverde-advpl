#include "Totvs.ch"
#include "TopConn.ch"

User Function VM040DEL()

    If ExistBlock("VM040ALT")
        ExecBlock("VM040ALT",.F.,.F.,.T.)
    EndIf

Return()   
