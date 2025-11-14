#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"
#include "fwbrowse.ch"
#include 'fwmvcdef.ch'

user function TRVAPV01()
	local oBrowse

	//Cria um Browse Simples instanciando o FWMBrowse
	oBrowse := FWMBrowse():New()
	//Define um alias para o Browse
	oBrowse:SetAlias('ZA1')
	//Adiciona uma descriÃ§Ã£o para o Browse
	oBrowse:SetDescription('Substituto por Aprovador')
	//Ativa o Browse
	oBrowse:Activate()
return NIL

Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' 		ACTION 'VIEWDEF.TRVAPV01' 	OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    		ACTION 'VIEWDEF.TRVAPV01' 	OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    		ACTION 'VIEWDEF.TRVAPV01' 	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    		ACTION 'VIEWDEF.TRVAPV01' 	OPERATION 5 ACCESS 0

Return aRotina

Static Function ModelDef()
	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruZA1 := FWFormStruct( 1, 'ZA1')
	Local oStruZA2 := FWFormStruct( 1, 'ZA2')
	Local oModel
	Local aAux

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('MDLTRVAPV01',/**/ , , /*bCommit*/, /*bCancel*/ )

	aAux := nil
	aAux := FwStruTrigger(										;
		'ZA1_COD'													,;		// DOMINIO
	'ZA1_USER'													,;		// CONTRA DOMINIO
	"POSICIONE('SAK',1,XFILIAL('SAK') + M->ZA1_COD, 'AK_USER')"	,;		// REGRA PREENCHIMENTO
	.F.															,;		// POSICIONA
	,;		// ALIAS
	,;		// ORDEM
	,;		// CHAVE
	,;		// CONDICAO
	"01",;		// SEQUENCIA
	)

	oStruZA1:AddTrigger(	;
		aAux[1],				;				// [01] Id do campo de origem
	aAux[2],				;				// [02] Id do campo de destino
	aAux[3],				;				// [03] Bloco de codigo de validação da execução do gatilho
	aAux[4]					)				// [04] Bloco de codigo de execução do gatilho

	aAux := nil
	aAux := FwStruTrigger(										;
		'ZA1_COD'													,;		// DOMINIO
	'ZA1_NOME'													,;		// CONTRA DOMINIO
	"POSICIONE('SAK',1,XFILIAL('SAK')+M->ZA1_COD,'AK_NOME')"	,;		// REGRA PREENCHIMENTO
	.F.															,;		// POSICIONA
	,;		// ALIAS
	,;		// ORDEM
	,;		// CHAVE
	,;		// CONDICAO
	"02",;		// SEQUENCIA
	)

	oStruZA1:AddTrigger(	;
		aAux[1],				;				// [01] Id do campo de origem
	aAux[2],				;				// [02] Id do campo de destino
	aAux[3],				;				// [03] Bloco de codigo de validação da execução do gatilho
	aAux[4]					)				// [04] Bloco de codigo de execução do gatilho

	aAux := nil
	aAux := FwStruTrigger(										;
		'ZA2_CODSUB'													,;		// DOMINIO
	'ZA2_USERSU'													,;		// CONTRA DOMINIO
	"POSICIONE('SAK',1,XFILIAL('SAK')+fwFldGet('ZA2_CODSUB'), 'AK_USER')"	,;		// REGRA PREENCHIMENTO
	.F.															,;		// POSICIONA
	,;		// ALIAS
	,;		// ORDEM
	,;		// CHAVE
	,;		// CONDICAO
	"01",;		// SEQUENCIA
	)

	oStruZA2:AddTrigger(	;
		aAux[1],				;				// [01] Id do campo de origem
	aAux[2],				;				// [02] Id do campo de destino
	aAux[3],				;				// [03] Bloco de codigo de validação da execução do gatilho
	aAux[4]					)				// [04] Bloco de codigo de execução do gatilho

	aAux := nil
	aAux := FwStruTrigger(										;
		'ZA2_CODSUB'													,;		// DOMINIO
	'ZA2_NOME'													,;		// CONTRA DOMINIO
	"POSICIONE('SAK',1,XFILIAL('SAK')+fwFldGet('ZA2_CODSUB'),'AK_NOME')"	,;		// REGRA PREENCHIMENTO
	.F.															,;		// POSICIONA
	,;		// ALIAS
	,;		// ORDEM
	,;		// CHAVE
	,;		// CONDICAO
	"02",;		// SEQUENCIA
	)

	oStruZA2:AddTrigger(	;
		aAux[1],				;				// [01] Id do campo de origem
	aAux[2],				;				// [02] Id do campo de destino
	aAux[3],				;				// [03] Bloco de codigo de validação da execução do gatilho
	aAux[4]					)				// [04] Bloco de codigo de execução do gatilho

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'ZA1MASTER', /*cOwner*/, oStruZA1, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	oModel:AddGrid( 'ZA2DETAIL', 'ZA1MASTER', oStruZA2, /*< bLinePre >*/, /*< bLinePost >*/								, /*< bPre >*/	, /*< bPost >*/						, /*< bLoad >*/ )

	//Adiciona chave Primária
	oModel:SetPrimaryKey( { "ZA1_FILIAL" , "ZA1_COD" } )

	// Adiciona relação entre cabeçalho e item (relacionamento entre mesma tabela)
	oModel:SetRelation( "ZA2DETAIL" , { { "ZA2_FILIAL" , "xFilial('ZA2')" } , { "ZA2_COD" , "ZA1_COD" } } , ZA2->( IndexKey( 1 ) ) )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Substituto por Aprovador' )

	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'ZA1MASTER' ):SetDescription( 'Cliente' )
	oModel:GetModel( 'ZA2DETAIL' ):SetDescription( 'Perguntas' )

	oStruZA1:SetProperty("ZA1_COD"		, MODEL_FIELD_VALID		, {|| chkFields( "ZA1_COD"		) }	)
	oStruZA1:SetProperty("ZA1_DATADE"	, MODEL_FIELD_VALID		, {|| chkFields( "ZA1_DATADE"	) }	)
	oStruZA1:SetProperty("ZA1_DATAAT"	, MODEL_FIELD_VALID		, {|| chkFields( "ZA1_DATAAT"	) }	)

	oStruZA2:SetProperty("ZA2_FILSUB"	, MODEL_FIELD_VALID		, {|| chkFields( "ZA2_FILSUB"	) }	)
	oStruZA2:SetProperty("ZA2_CODSUB"	, MODEL_FIELD_VALID		, {|| chkFields( "ZA2_CODSUB"	) }	)
Return oModel

Static Function ViewDef()

	// Cria a estrutura a ser usada na View
	Local oStruZA1 := FWFormStruct( 2, 'ZA1' ) //,{ |x| ALLTRIM(x) $ 'ZP_CODREG, ZP_DESCREG, ZP_ATIVO' })
	Local oStruZA2 := FWFormStruct( 2, 'ZA2' , { | cCampo | !allTrim( cCampo ) $ "ZA2_COD" } )

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRVAPV01' )
	Local oView

	// Remove o campo Codigo Região do detalhe
	//oStruZA2:RemoveField( "ZA2_CODREG" )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_ZA1', oStruZA1, 'ZA1MASTER' )
	oView:AddGrid( 'VIEW_ZA2', oStruZA2, 'ZA2DETAIL' )

	oView:AddIncrementField( 'VIEW_ZA2', 'ZA2_ITEM' )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR' , 20 )
	oView:CreateHorizontalBox( 'INFERIOR' , 80 )

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_ZA1', 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_ZA2', 'INFERIOR' )

Return oView

static function chkFields( cFieldX )
	local aAreaX		:= fwGetArea()
	local lRet			:= .T.
	local oModel		:= FWModelActive()
	local oModelZA1		:= oModel:GetModel('ZA1MASTER')
	local oModelZA2		:= oModel:GetModel('ZA2DETAIL')
	local nOper			:= oModel:getOperation()
	local aSaveLines	:= FWSaveRows()
	local cQryZA1		:= ""
	local nI			:= 0
	local nLineAtu		:= 0

	if cFieldX == "ZA1_COD"
		if !existCpo( "SAK", oModelZA1:getValue("ZA1_COD") )
			lRet := .F.
		endif

		if lRet
			if nOper == MODEL_OPERATION_INSERT
				cQryZA1 := ""
				cQryZA1 += " SELECT *"														+ CRLF
				cQryZA1 += " FROM	" + retSQLName("ZA1") + " ZA1"							+ CRLF
				cQryZA1 += " WHERE"															+ CRLF
				cQryZA1 += " 		ZA1.ZA1_COD		=	'" + oModelZA1:getValue("ZA1_COD")	+ "'"		+ CRLF
				cQryZA1 += " 	AND ZA1.ZA1_FILIAL	=	'" + xFilial( "ZA1" )	+ "'"		+ CRLF
				cQryZA1 += " 	AND ZA1.D_E_L_E_T_	=	' '"								+ CRLF

				conout( "[TRVAPV01] [chkFields] " + fwTimeStamp() + " " + cQryZA1 )

				tcQuery cQryZA1 new alias "QRYZA1"

				if !QRYZA1->( EOF() )
					lRet := .F.
					help( ,, 'Help',, 'Já incluso. Já existe cadastro de substituto para este Aprovador.', 1, 0 )
				endif

				QRYZA1->( DBCloseArea() )
			endif
		endif
	elseif cFieldX == "ZA1_DATADE"
		if oModelZA1:getValue( "ZA1_DATADE" ) > oModelZA1:getValue( "ZA1_DATAAT" ) .and. !empty( oModelZA1:getValue( "ZA1_DATAAT" ) )
			lRet := .F.
			help( ,, 'Help',, 'Data Até inválida. A Data De deve ser menor que a Data Até.', 1, 0 )
		endif
	elseif cFieldX == "ZA1_DATAAT"
		if oModelZA1:getValue( "ZA1_DATAAT" ) < dDataBase
			lRet := .F.
			help( ,, 'Help',, 'Data Até inválida. A Data Até deve ser maior que a data atual.', 1, 0 )
		else
			if oModelZA1:getValue( "ZA1_DATADE" ) > oModelZA1:getValue( "ZA1_DATAAT" )
				lRet := .F.
				help( ,, 'Help',, 'Data Até inválida. A Data De deve ser menor que a Data Até.', 1, 0 )
			endif
		endif
	elseif cFieldX == "ZA2_FILSUB"
		if allTrim( oModelZA2:getValue( "ZA2_FILSUB" ) ) == "*"
			nLineAtu := oModelZA2:nLine
			for nI := 1 to oModelZA2:length()
				if nLineAtu <> nI
					oModelZA2:GoLine( nI )
					if allTrim( oModelZA2:getValue( "ZA2_FILSUB" ) ) <> "*" .and. !oModelZA2:isDeleted()
						lRet := .F.
						help( ,, 'Help',, 'Já existem filiais adicionadas.', 1, 0 )
						exit
					endif
				endif
			next
		elseif !FWFilExist( cEmpAnt , oModelZA2:getValue("ZA2_FILSUB") )
			lRet := .F.
		endif
	elseif cFieldX == "ZA2_CODSUB"
		if oModelZA2:getValue( "ZA2_CODSUB" ) == oModelZA1:getValue("ZA1_COD")
			lRet := .F.
		endif

		if lRet
			if !existCpo( "SAK", oModelZA2:getValue( "ZA2_CODSUB" ) )
				lRet := .F.
			endif
		endif
	endif

	fwRestRows( aSaveLines )

	fwRestArea( aAreaX )
return lRet
