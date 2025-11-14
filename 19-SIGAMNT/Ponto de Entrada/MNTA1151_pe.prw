#include 'totvs.ch'
/*/{Protheus.doc} MNTA1151
Ponto de entrada que permite customizar campos da tabela de Bens (ST9) gerado a partir de um Ativo Fixo
Inclusão do campo de classe valor. 
@Rotina Gera bem a partir do ATF.
@author  Rodrigo Machado
@since   04/07/2024
*/
User Function MNTA1151()
    local aAtvNBEM      := PARAMIXB[1]
    local aAreaST9      := GetArea()
    local aAreaSN3      := GetArea()

    //Faz o posicionamento na tabela SN3 para recuperar a classe valor do bem (SN3->N3CLVLCON)
    If Len(aAtvNBEM) > 0
        dbSelectArea("SN3")
        dbSetOrder(1)
        If dbSeek(xFilial("SN3") + Alltrim(ST9->T9_CODBEM))
            //Efetua a gravação do campo T9_ZZCLVL com o valor de N3_CLVLCON (Classe valor)
            Reclock("ST9", .F.)
                ST9->T9_ZZCLVL := Alltrim(SN3->N3_CLVLCON)
            ST9->(MsUnlock())
        Endif
    Endif

    RestArea(aAreaSN3)
    RestArea(aAreaST9)
Return .T.
