#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

/*/{Protheus.doc} OX020PAR
Este Ponto de Entrada tem a finalidade Gravar os valores dos campos Tipo de Operação, Tes de Saída e Tes de Entrada.
@type function
@version  12.1.2410
@author fernandodasilva
@since 10/28/2025
@return variant, Retorna os valores conforme configuração
@history 28/10/2025,fernandodasilva, criação
/*/
User Function  OX020PAR()

// Traz a operação configurada para as transferencias via pedido de transferencia.
    Local cOperacao := GETnewPar( 'TV_OPTRAN' , '52') 

// Traz o TES de saida configurado para as transferencias via pedido de transferencia.
    Local cTesSai   := GETnewPar( 'TV_TSTRAN' , '701') 

// Traz o TES de Entrada configurada para as transferencias via pedido de transferencia este sempre vem em branco
    Local cTesEnt   := GETnewPar( 'TV_TETRAN' , '')

// Traz a FROMULA configurada para as transferencias via pedido de transferencia.
    Local cFormul   := GETnewPar( 'TV_FORTRA' , '000303')
//msginfo("Ponto de Entrada OX020PAR executado com sucesso!")

Return({cOperacao,cTesSai,cTesEnt,cFormul})
