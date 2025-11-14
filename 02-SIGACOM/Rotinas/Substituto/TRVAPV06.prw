#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} TRVAPV06
Manter a Aprovação

@type function
@version 1.0
@author Gustavo
@since 18/04/2023
@link https://gkcmp.com.br (Geeker Company)
@return variant, Nil
/*/
user function TRVAPV06()
	local aAreaX		:= fwGetArea()
	local aAreaSAK		:= SAK->( fwGetArea() )
	local aMvPar		:= {}
	local nX			:= 0
	local cAprovador	:= ""
	local cAprovOrig	:= ""
	local cUsuarOrig	:= ""
	local cCodigoOri	:= ""

	for nX := 1 to 60
		aadd( aMvPar, &( "MV_PAR" + strZero( nX, 2, 0 ) ) )
	next nX

	cAprovador := posicione( 'SAK' , 1 ,xFilial( 'SAK' ) + SCR->CR_APROV , 'AK_NOME' )

	if SCR->CR_ZMANTER <> "S"
		if empty( SCR->CR_ZAPRORI )

			if msgYesNo( "Deseja manter este documento com o Aprovador " + cAprovador , "[TerraVerde] Atenção!" )
				recLock( "SCR" , .F. )
				SCR->CR_ZMANTER := "S"
				SCR->( msUnlock() )
			endif
		else
			if SCR->CR_STATUS $ '01,02,04'
				cAprovOrig := posicione( 'SAK' , 1 ,xFilial( 'SAK' ) + SCR->CR_ZAPRORI	, 'AK_NOME' )
				cUsuarOrig := posicione( 'SAK' , 1 ,xFilial( 'SAK' ) + SCR->CR_ZAPRORI	, 'AK_USER' )
				cCodigoOri := posicione( 'SAK' , 1 ,xFilial( 'SAK' ) + SCR->CR_ZAPRORI	, 'AK_COD' )
				cAprovador := posicione( 'SAK' , 1 ,xFilial( 'SAK' ) + SCR->CR_APROV	, 'AK_NOME' )

				if msgYesNo(	"O Aprovador deste documento foi alterado, conforme abaixo:"	+ CRLF +	;
						"Aprovador original: " + cAprovOrig								+ CRLF +	;
						"Aprovador atual: " + cAprovador								+ CRLF +	;
						"Deseja retornar para o Aprovador Original e mante-lo como Aprovador?" , "[TerraVerde] Atenção!" )

					recLock( "SCR" , .F. )
					SCR->CR_ZAPRORI := space( getSX3Cache( "CR_APROV", "X3_TAMANHO" ) )
					SCR->CR_USER	:= cUsuarOrig
					SCR->CR_APROV	:= cCodigoOri
					SCR->CR_ZMANTER := "S"
					SCR->( msUnlock() )
				endif
			endif
		endif
	else
		if msgYesNo(	"Usuário Aprovador " + cAprovador + " está mantido atualmente." + CRLF + ;
						"Deseja que este Aprovador seja substituído ?" , "[TerraVerde] Atenção!" )

				recLock( "SCR" , .F. )
					SCR->CR_ZMANTER := " "
				SCR->( msUnlock() )
		endif
	endif

	for nX := 1 to len( aMvPar )
		&( "MV_PAR" + strZero( nX, 2, 0 ) ) := aMvPar[ nX ]
	next nX

	fwRestArea( aAreaSAK )
	fwRestArea( aAreaX )
return
