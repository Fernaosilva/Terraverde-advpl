#Include "Protheus.ch"

/*/{Protheus.doc} OM390STA
Ponto de entrada após a alteração do status da VM0
@type function
@version 1.0
@author Fabio Hayama - Geeker Company
@since 30/04/2024
@return variant, True / False
/*/
user function OM390STA()
	local aArea         := GetArea()
    local aAreaLj7      := Lj7GetArea({"VM0", "SD1", "SA2", "SB1", "SF1"})
    local cConferencia  := ParamIxb[01] //codigo da conferencia VM0_CODIGO
    local cStatus       := ParamIxb[02] // Status da Conferencia VM0_STATUS
    local cTpOrigem     := ParamIxb[03]
    local cStConf       := GetNewPar( "ZZ_STCFDM", "4" ) //Parcial | Conferido

    VM0->( DbSetOrder( 1 ) )
    SF1->( DbSetOrder( 1 ) )

    if( cStatus $ cStConf )
    
        if( VM0->( DbSeek( xFilial("VM0") + PadR( cConferencia, GetSX3Cache( "VM0_CODIGO", "X3_TAMANHO" ) ) ) ) )

            if( SF1->( DbSeek( xFilial("SF1") + PadR( VM0->VM0_DOC      , GetSX3Cache( "F1_DOC"     , "X3_TAMANHO" ) ) +;
                                                PadR( VM0->VM0_SERIE    , GetSX3Cache( "F1_SERIE"   , "X3_TAMANHO" ) ) +;
                                                PadR( VM0->VM0_FORNEC   , GetSX3Cache( "F1_FORNECE" , "X3_TAMANHO" ) ) +;
                                                PadR( VM0->VM0_LOJA     , GetSX3Cache( "F1_LOJA"    , "X3_TAMANHO" ) ) ) ) )

                SF1->( RecLock( "SF1", .F. ) )
                    SF1->F1_XCONF := "S"
                    SF1->F1_XHRCONF := SubStr( Time(), 1, 5 )
                    SF1->F1_XDTCONF := dDataBase      //SF1->F1_DOCISEN := "S" CAMPO PARA TESTE NO MOMENTO DO DESENVOLVIMENTO

                SF1->( MsUnlock() )
            endIf            
        endIf
    endIf

    Lj7RestArea(aAreaLj7)
    RestArea(aArea)
return
