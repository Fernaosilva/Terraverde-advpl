#include 'totvs.ch'

/*/{Protheus.doc} NGALTSC1
Ponto de entrada que permite inclusão de campos na geração de S.C. através da manutençao do ativo.
Ponto de entrada responsável por enviar o conteúdo do campo "T9_ZZCLVL" para
a solicitação de compras 
@author  Rodrigo Machado
@since   04/07/2024
*/
User Function NGALTSC1()
    local aItens := aClone(PARAMIXB[1])
    local aCabec := aClone(PARAMIXB[2])
    local aAreaST9  := getArea()
    
    //Faz o posicionamento na tabela ST9 para recuperar o valor do campo T9_ZZCLVL
    dbSelectArea("ST9")
    dbSetOrder(1)
    If dbSeek(xFilial("ST9")+STJ->TJ_CODBEM)
        //Adiciona ao array de itens da solicitação de compras o campo C1_CLVL com o valor do campo T9_ZZCLVL
        aadd(aItens, { 'C1_CLVL', ST9->T9_ZZCLVL, NIL})
    Endif

    restArea(aAreaST9)
Return { aItens, aCabec }
