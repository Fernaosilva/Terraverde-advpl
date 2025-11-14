#include 'protheus.ch'

//--------------------------------------------------------------//
/*/{Protheus.doc} LgIncDoc
Log para gravacao dos usuarios

@author 	Fabio Hayama - GEeker
@since 		07/03/2016
@version	1.0
/*/
//---------------------------------------------------------------//
user function LgIncDoc()
    local cStAndCf  := GetNewPar( "ZZ_STDFCF", "E" )
    local cStConfis := GetNewPar( "ZZ_STCFFR", "3|" )
    local cStNaoCf  := GetNewPar( "ZZ_STNFCF", "N" )
    local cConfis   := ""
    local cGrupo1   := GETMV("TV_GRSCON1") 	// Grupos de produtos que não passa por conferencia configurados no sistema
	local cGrupo2   := GETMV("TV_GRSCON2") 	// Grupos de produtos que não passa por conferencia configurados no sistema
    local cD1grupo  := ''
    local lContinua := .T.
    
    
    if( Empty( SF1->F1_XDTINC ) ) 
        
        SA2->( DbSetOrder( 1 ) )
        if( SA2->( DbSeek( xFilial("SA1") + PadR( SF1->F1_FORNECE   , GetSX3Cache("A2_COD","X3_TAMANHO" ) ) +;
                                            PadR( SF1->F1_LOJA      , GetSX3Cache("A2_LOJA","X3_TAMANHO") ) ) ) )
            
            cConfis := SA2->A2_CONFFIS

            if( Empty( cConfis ) .OR. Alltrim( cConfis ) $ cStConfis )
                cConfis := cStNaoCf //Nao precisa conferir
            else

                SD1->(DbSelectArea("SD1"))
                SD1->(DbSetOrder(1))
                SD1->(DbSeek(xFilial("SD1") + SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA))
                While lContinua .And. !SD1->(EoF()) .And. SD1->D1_DOC == SF1->F1_DOC
                    // Trata os parâmetros
                        cGrupo1 := StrTran( StrTran( Upper( AllTrim( GetMv("TV_GRSCON1") ) ), "'", "" ), ",", "|" )
                        cGrupo2 := StrTran( StrTran( Upper( AllTrim( GetMv("TV_GRSCON2") ) ), "'", "" ), ",", "|" )
                    // Grupo do item atual
                        cD1grupo := Upper( AllTrim( SD1->D1_GRUPO ) )// validação por item

                    If ("|" + cD1grupo + "|") $ ( "|" + cGrupo1 + "|" + cGrupo2 + "|" )
                        cConfis := cStNaoCf
                    else
                        cConfis := cStAndCf
                        lContinua := .F.
                    endIf
                    SD1->(DbSkip())
                EndDo
            
                ///cConfis := cStAndCf //Conferencia em andamento
            endIf
    
            SF1->( RecLock( "SF1", .F. ) )
                SF1->F1_XDTINC 	:= dDataBase
                SF1->F1_XHRINC 	:= SubStr( Time(), 1, 5 )
                SF1->F1_XUSRINC	:= cUserName                 
                SF1->F1_XCONF   := cConfis    
            SF1->( MsUnlock() )
        endIf
    endIf
    //Patini: Grava campos customizados na Classificação..
        If (FwIsincallstack("U_MTA103OK") .AND. L103CLASS) .or. (FWISINCALLSTACK("MATA103")	.and. Inclui) .AND. (!(FWIsInCallStack("U_TV_SIB04")) .AND. !(FWIsInCallStack("U_TV_SIB03")))
            Reclock("SF1",.F.)
                SF1->F1_XHRCLAS := SubStr( Time(), 1, 5 )
                SF1->F1_XUSCLAS := cUserName     
                SF1->F1_XDTCLAS := dDataBase      
            SF1->(MsUnlock())
	    endif
return
