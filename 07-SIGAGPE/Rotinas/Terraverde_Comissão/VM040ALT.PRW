#include "Totvs.ch"
#include "TopConn.ch"

User Function VM040ALT()

// Notas deste cliente deverá ser desconsiderados  por são notas de 
// Transferencias de produtos entre filials
Local cRetForTV		:= SuperGetMV("TV_RETCLIT",, "092825")

// deveremos pegar o Numero Chassi deste processo.
// Este numero esta no VV1 -- campo VV1->VV1_CHASSI
Local cChassi := VV1->VV1_CHASSI

// Dados do Pedido de Venda 
Local cNumpV := Space(6)
Local cItemPV:= Space(4)

// VAriavel de filtro 
Local cCmdSc6 := "" 

// deveremos pelo numero do chassi localizar o numero do pedido de venda 
// para este processo deveremos pegar via o SC6 - Item do pedido de venda
// Não existe indice com o campo desejado , iremos efetuar o filtro  via 
// comando Select
cCmdSc6 := " SELECT * "
cCmdSc6 += " FROM " + RetSqlName("SC6")
cCmdSc6 += " WHERE " 
cCmdSc6 += "     C6_CLI   <> '"+cRetForTV+"' "
cCmdSc6 += " AND C6_CHASSI = '"+cChassi+"' "
cCmdSc6 += " AND D_E_L_E_T_ = ' ' 

If Select("QRYCHASSI") <> 0
    dbSelectArea("QRYCHASSI")
    dbCloseArea()
Endif

TcQuery cCmdSc6 Alias "QRYCHASSI" New 

cNumpV 	:= QRYCHASSI->C6_NUM
cItemPV := QRYCHASSI->C6_ITEM

dbSelectArea("QRYCHASSI")
dbCloseArea()

// Localizamos o numero do Pedido de venda deste chassi
// deveremos localizar o numero da nota fiscal que foi gerada
// para este Pedido e Item
dbSelectArea("SD2")
dbSetOrder(8)
IF dbSeek(xFilial("SD2") + cNumpV + cItemPV )
    cNumDoc := SD2->D2_DOC
    cNumSer := SD2->D2_SERIE

    If ExistBlock("xCalComiss")
        __Cc := 1 
        U_xCalComiss(cNumDoc,cNumSer,"",xFilial("SD2"))
        // lRetorno := ExecBlock("xCalComiss()",.F.,.F.,.T.)
        __Cc := 1 
    EndIf
Endif				

Return()   
