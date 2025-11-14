#INCLUDE "PROTHEUS.CH"
//-------------------------------------------//
// Ponto de entrada                          //
// Inclui a legenda de maquina parada no     //
// browse mata103 (documento de entrada)     //
//-------------------------------------------//

User Function MT103LEG()
Local aNewCores := aClone(PARAMIXB[1])
aAdd(aNewCores,{"BR_PRETO",'Maquina parada nao classificada'}) 
Return( aNewCores )

