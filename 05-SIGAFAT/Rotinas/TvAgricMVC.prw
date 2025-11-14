#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'

#Define SA1Show 	'A1_COD|A1_LOJA|A1_NOME|A1_NREDUZ|A1_XTIPCLI|A1_XSEGTIP|'
#Define SA1Update 	'A1_XTIPCLI|A1_XSEGTIP|'

/*/{Protheus.doc} TvAgricMVC
MVC Propriedades Agricolas - Complemento de Cliente
@type function
@version P12
@author Ademar Fernandes Jr.
@since 22/05/2024
@link https://gkcmp.com.br (Geeker Company)
@return variant, nil
/*/
User Function TvAgricMVC()
	Local oBrowse

	Private cTitulo   := OemToAnsi("Propriedades Agrícolas")
	Public cFiltroVX5 := "" //-Necessaria por causa do fonte OFIOA560

	//Setando o nome da função, para a função customizada
    SetFunName("TVAGRICMVC")

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSelectArea("VMJ")
	DbSetOrder(1)
	DbSelectArea("VMK")
	DbSetOrder(1)

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SA1')
	oBrowse:SetDescription(cTitulo)
	oBrowse:Activate()
Return

/*
    Funçao responsavel pelo Menu
*/
Static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.TVAGRICMVC' OPERATION 4 ACCESS 0	//-Alterar
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.TVAGRICMVC' OPERATION 2 ACCESS 0	//-Visualizar

Return aRotina

/*
    Funçao responsavel pelo Model
*/
Static Function ModelDef()
	Local nI as numeric
	Local oModel
	Local oStruSA1   := FWFormStruct(1,"SA1", {| cCampo |  AllTrim( cCampo )  + '|' $ SA1Show })
	Local oStruVMJ   := FWFormStruct(1,"VMJ")
	Local oStruVMK   := FWFormStruct(1,"VMK")
	// Local aFieldsSA1 :={"A1_FILIAL" , "A1_COD"    , "A1_NREDUZ", "A1_LOJA"   , "A1_NOME"   , "A1_PESSOA" , "A1_END"    , "A1_BAIRRO", "A1_TIPO"  , "A1_EST"    , "A1_ESTADO" , "A1_COD_MUN", "A1_CEP"    , "A1_MUN"    , "A1_REGIAO" , "A1_DSCREG" , "A1_NATUREZ", "A1_IBGE"   , "A1_ENDCOB" , "A1_DDI"    , "A1_ENDENT", "A1_DDD", "A1_ENDREC", "A1_TRIBFAV", "A1_TEL", "A1_COMPENT", "A1_FAX", "A1_CGC", "A1_CONTATO", "A1_INSCR", "A1_TELEX", "A1_PFISICA", "A1_PAIS", "A1_INSCRM", "A1_VEND", "A1_PAISDES", "A1_COMIS", "A1_CONTA", "A1_BCO1", "A1_BCO2", "A1_BCO3", "A1_BCO4", "A1_BCO5", "A1_TRANSP", "A1_TPFRET", "A1_COND", "A1_DESC", "A1_PRIOR", "A1_RISCO", "A1_LC", "A1_VENCLC", "A1_CLASSE", "A1_LCFIN", "A1_MOEDALC", "A1_MSALDO", "A1_MCOMPRA", "A1_METR", "A1_PRICOM", "A1_ULTCOM", "A1_NROCOM", "A1_FORMVIS", "A1_TEMVIS", "A1_ULTVIS", "A1_TMPVIS", "A1_CLASVEN", "A1_TMPSTD", "A1_MENSAGE", "A1_SALDUP", "A1_RECISS", "A1_SALPEDL", "A1_NROPAG", "A1_TRANSF", "A1_SUFRAMA", "A1_ATR", "A1_VACUM", "A1_SALPED", "A1_TITPROT", "A1_DTULTIT", "A1_CHQDEVO", "A1_MATR", "A1_DTULCHQ", "A1_MAIDUPL", "A1_TABELA", "A1_INCISS", "A1_SALDUPM", "A1_PAGATR", "A1_CXPOSTA", "A1_ATIVIDA", "A1_CARGO1", "A1_CARGO2", "A1_CARGO3", "A1_SUPER", "A1_RTEC", "A1_ALIQIR", "A1_RG", "A1_OBSERV", "A1_CALCSUF", "A1_DTNASC", "A1_CLIFAT", "A1_GRPTRIB", "A1_BAIRROC", "A1_CEPC", "A1_MUNC", "A1_ESTC", "A1_CEPE", "A1_BAIRROE", "A1_MUNE", "A1_ESTE", "A1_SATIV1", "A1_DSATIV1", "A1_SATIV2", "A1_CODPAIS", "A1_TPESSOA", "A1_TPISSRS", "A1_DSATIV2", "A1_SATIV3", "A1_DSATIV3", "A1_SATIV4", "A1_DSATIV4", "A1_SATIV5", "A1_DSATIV5", "A1_SATIV6", "A1_DSATIV6", "A1_SATIV7", "A1_DSATIV7", "A1_SATIV8", "A1_DSATIV8", "A1_CODMARC", "A1_VM_MARC", "A1_CODAGE", "A1_COMAGE", "A1_TIPCLI", "A1_DEST_1", "A1_EMAIL", "A1_DEST_2", "A1_CODMUN", "A1_DEST_3", "A1_HPAGE", "A1_CBO", "A1_CNAE", "A1_CONDPAG", "A1_DIASPAG", "A1_DESCPAG", "A1_OBS", "A1_VM_OBS", "A1_AGREG", "A1_RECINSS", "A1_RECCOFI", "A1_RECCSLL", "A1_RECPIS", "A1_TIPPER", "A1_SALFIN", "A1_SALFINM", "A1_CONTAB", "A1_B2B", "A1_GRPVEN", "A1_CLICNV", "A1_INSCRUR", "A1_MSBLQL", "A1_COMPLEM", "A1_HRCAD", "A1_DTCAD", "A1_CLIPRI", "A1_LOJPRI", "A1_CODSEG", "A1_DESSEG", "A1_SUBCOD", "A1_CDRDES", "A1_REGDES", "A1_FILDEB", "A1_CODFOR", "A1_ABICS", "A1_BLEMAIL", "A1_TIPOCLI", "A1_VINCULO", "A1_DTINIV", "A1_DTFIMV", "A1_CODMUNE", "A1_PERFIL", "A1_HRTRANS", "A1_UNIDVEN", "A1_TIPPRFL", "A1_PRF_VLD", "A1_PRF_OBS", "A1_REGPB", "A1_USADDA", "A1_SIMPLES", "A1_CEINSS", "A1_IDHIST", "A1_ORIGEM", "A1_CTARE", "A1_ENDNOT", "A1_IRBAX", "A1_REGESIM", "A1_MSEXP", "A1_PERCATM", "A1_FRETISS", "A1_INDRET", "A1_NIF", "A1_CODSIAF", "A1_ABATIMP", "A1_PERFECP", "A1_IENCONT", "A1_ENTID", "A1_OUTRMUN", "A1_CONTRIB", "A1_RECFMD", "A1_RFASEMT", "A1_RIMAMT", "A1_INCLTMG", "A1_DESCAM", "A1_FILTRF", "A1_TPNFSE", "A1_SIMPNAC", "A1_PRSTSER", "A1_RFACS", "A1_RFABOV", "A1_TPDP", "A1_DSCMEMB", "A1_TIMEKEE", "A1_CRDMA", "A1_CODFID", "A1_ENTORI", "A1_ALIFIXA", "A1_TPMEMB", "A1_NOMTER", "A1_CODTER", "A1_CHVCAM", "A1_CODMEMB", "A1_INOVAUT", "A1_RESFAT", "A1_TPJ", "A1_NVESTN", "A1_IMGUMOV", "A1_HREXPO", "A1_USERLGA", "A1_USERLGI", "A1_TDA", "A1_RECIRRF", "A1_MINIRF", "A1_ISSRSLC", "A1_RECFET", "A1_FOMEZER", "A1_IDESTN", "A1_TPCAMP", "A1_INCULT", "A1_ORIGCT"}
	Local aFieldsVMK :={"VMK_FILIAL", "VMK_CODCLI", "VMK_XLOJA", "VMK_PAISEQ", "VMK_CODSEQ", "VMK_CODCUL", "VMK_DESCUL", "VMK_ANO"  , "VMK_SAFRA", "VMK_INIPLA", "VMK_FIMPLA", "VMK_UNIDAD", "VMK_PRODUC", "VMK_INICOL", "VMK_FIMCOL", "VMK_ESTOQU", "VMK_CUSPRV", "VMK_VUNIVD", "VMK_LOGALT", "VMK_XAREPR", "VMK_XAREAR"}
	Local aFldShow   	:= StrToKArr2( SA1Show, '|')
	Local aFldUpdate 	:= StrToKArr2( SA1Update, '|')
	Local nTamArray2  	:= Len( aFldUpdate )
	Local nTamArray1  	:= Len( aFldShow )
	// Local nI        	:= 0

	cTitulo := OemToAnsi("Propriedades Agrícolas")

	oModel := MPFormModel():New("MD_PROP_AGR")
	oModel:SetDescription(cTitulo)

	// for nI := 1 to Len(aFieldsSA1)
	// 	oStruSA1:SetProperty( aFieldsSA1[nI], MODEL_FIELD_WHEN,{|| .F.}) 
	// 	oStruSA1:SetProperty( aFieldsSA1[nI], MODEL_FIELD_OBRIGAT, .F.) 
	// next

	//Campos que só podem ser exibidos
	For nI := 1 To nTamArray1
		oStruSA1:SetProperty( aFldShow[ nI ], MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN , ".F.") )
	Next

	//Campos que podem ser alterados.
	For nI := 1 To nTamArray2
		oStruSA1:SetProperty( aFldUpdate[ nI ], MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN , ".T.") )
	Next

	for nI := 1 to Len(aFieldsVMK)
		oStruVMK:SetProperty( aFieldsVMK[nI], MODEL_FIELD_OBRIGAT, .F.) 
	next

	// oModel := MPFormModel():New("MD_PROP_AGR")
	// oModel:SetDescription("Propriedades Agrícolas")

	oModel:addFields('MASTERSA1', ,oStruSA1)
	oModel:addGrid('DETAILVMJ','MASTERSA1',oStruVMJ)
	oModel:addGrid('DETAILVMK','DETAILVMJ',oStruVMK)

	oModel:SetRelation("DETAILVMJ", ;
		{ {"VMJ_FILIAL", 'xFilial("VMJ")'},;
		  {"VMJ_CODCLI", "A1_COD"},;
		  {"VMJ_XLOJA" , "A1_LOJA"} }, VMJ->(IndexKey(1)))
        	
    oModel:SetRelation("DETAILVMK",;
		{ {"VMK_FILIAL","VMJ_FILIAL"},;
		  {"VMK_CODCLI","VMJ_CODCLI"},;
		  {"VMK_XLOJA" ,"VMJ_XLOJA"},;
		  {"VMK_PAISEQ","VMJ_CODSEQ"}}, VMK->(IndexKey(1)))

	oModel:SetPrimaryKey( { 'A1_FILIAL', 'A1_COD', 'A1_LOJA' } )

Return oModel

/*
    Funçao responsavel pelo View
*/
Static Function ViewDef()
	// Local nI as numeric
	Local oView
	Local oModel     := ModelDef()
	Local oStruSA1   := FWFormStruct(2,"SA1", {| cCampo |  AllTrim( cCampo )  + '|' $ SA1Show })
	Local oStruVMJ   := FWFormStruct(2,"VMJ")
	Local oStruVMK   := FWFormStruct(2,"VMK")
	// Local aFieldsSA1 :={"A1_FILIAL", "A1_BAIRRO", "A1_PESSOA", "A1_END", "A1_TIPO", "A1_EST", "A1_ESTADO", "A1_COD_MUN", "A1_CEP", "A1_MUN", "A1_REGIAO", "A1_DSCREG", "A1_NATUREZ", "A1_IBGE", "A1_ENDCOB", "A1_DDI", "A1_ENDENT", "A1_DDD", "A1_ENDREC", "A1_TRIBFAV", "A1_TEL", "A1_COMPENT", "A1_FAX", "A1_CGC", "A1_CONTATO", "A1_INSCR", "A1_TELEX", "A1_PFISICA", "A1_PAIS", "A1_INSCRM", "A1_VEND", "A1_PAISDES", "A1_COMIS", "A1_CONTA", "A1_BCO1", "A1_BCO2", "A1_BCO3", "A1_BCO4", "A1_BCO5", "A1_TRANSP", "A1_TPFRET", "A1_COND", "A1_DESC", "A1_PRIOR", "A1_RISCO", "A1_LC", "A1_VENCLC", "A1_CLASSE", "A1_LCFIN", "A1_MOEDALC", "A1_MSALDO", "A1_MCOMPRA", "A1_METR", "A1_PRICOM", "A1_ULTCOM", "A1_NROCOM", "A1_FORMVIS", "A1_TEMVIS", "A1_ULTVIS", "A1_TMPVIS", "A1_CLASVEN", "A1_TMPSTD", "A1_MENSAGE", "A1_SALDUP", "A1_RECISS", "A1_SALPEDL", "A1_NROPAG", "A1_TRANSF", "A1_SUFRAMA", "A1_ATR", "A1_VACUM", "A1_SALPED", "A1_TITPROT", "A1_DTULTIT", "A1_CHQDEVO", "A1_MATR", "A1_DTULCHQ", "A1_MAIDUPL", "A1_TABELA", "A1_INCISS", "A1_SALDUPM", "A1_PAGATR", "A1_CXPOSTA", "A1_ATIVIDA", "A1_CARGO1", "A1_CARGO2", "A1_CARGO3", "A1_SUPER", "A1_RTEC", "A1_ALIQIR", "A1_RG", "A1_OBSERV", "A1_CALCSUF", "A1_DTNASC", "A1_CLIFAT", "A1_GRPTRIB", "A1_BAIRROC", "A1_CEPC", "A1_MUNC", "A1_ESTC", "A1_CEPE", "A1_BAIRROE", "A1_MUNE", "A1_ESTE", "A1_SATIV1", "A1_DSATIV1", "A1_SATIV2", "A1_CODPAIS", "A1_TPESSOA", "A1_TPISSRS", "A1_DSATIV2", "A1_SATIV3", "A1_DSATIV3", "A1_SATIV4", "A1_DSATIV4", "A1_SATIV5", "A1_DSATIV5", "A1_SATIV6", "A1_DSATIV6", "A1_SATIV7", "A1_DSATIV7", "A1_SATIV8", "A1_DSATIV8", "A1_CODMARC", "A1_VM_MARC", "A1_CODAGE", "A1_COMAGE", "A1_TIPCLI", "A1_DEST_1", "A1_EMAIL", "A1_DEST_2", "A1_CODMUN", "A1_DEST_3", "A1_HPAGE", "A1_CBO", "A1_CNAE", "A1_CONDPAG", "A1_DIASPAG", "A1_DESCPAG", "A1_OBS", "A1_VM_OBS", "A1_AGREG", "A1_RECINSS", "A1_RECCOFI", "A1_RECCSLL", "A1_RECPIS", "A1_TIPPER", "A1_SALFIN", "A1_SALFINM", "A1_CONTAB", "A1_B2B", "A1_GRPVEN", "A1_CLICNV", "A1_INSCRUR", "A1_MSBLQL", "A1_COMPLEM", "A1_HRCAD", "A1_DTCAD", "A1_CLIPRI", "A1_LOJPRI", "A1_CODSEG", "A1_DESSEG", "A1_SUBCOD", "A1_CDRDES", "A1_REGDES", "A1_FILDEB", "A1_CODFOR", "A1_ABICS", "A1_BLEMAIL", "A1_TIPOCLI", "A1_VINCULO", "A1_DTINIV", "A1_DTFIMV", "A1_LOCCONS", "A1_CODMUNE", "A1_PERFIL", "A1_HRTRANS", "A1_UNIDVEN", "A1_TIPPRFL", "A1_PRF_VLD", "A1_PRF_OBS", "A1_REGPB", "A1_USADDA", "A1_SIMPLES", "A1_CEINSS", "A1_IDHIST", "A1_ORIGEM", "A1_CTARE", "A1_ENDNOT", "A1_IRBAX", "A1_REGESIM", "A1_MSEXP", "A1_PERCATM", "A1_FRETISS", "A1_INDRET", "A1_NIF", "A1_CODSIAF", "A1_ABATIMP", "A1_PERFECP", "A1_IENCONT", "A1_ENTID", "A1_OUTRMUN", "A1_CONTRIB", "A1_RECFMD", "A1_RFASEMT", "A1_RIMAMT", "A1_INCLTMG", "A1_DESCAM", "A1_FILTRF", "A1_TPNFSE", "A1_SIMPNAC", "A1_PRSTSER", "A1_RFACS", "A1_RFABOV", "A1_TPDP", "A1_DSCMEMB", "A1_TIMEKEE", "A1_CRDMA", "A1_CODFID", "A1_ENTORI", "A1_ALIFIXA", "A1_TPMEMB", "A1_NOMTER", "A1_CODTER", "A1_CHVCAM", "A1_CODMEMB", "A1_INOVAUT", "A1_RESFAT", "A1_TPJ", "A1_NVESTN", "A1_IMGUMOV", "A1_HREXPO", "A1_USERLGA", "A1_USERLGI", "A1_TDA", "A1_RECIRRF", "A1_MINIRF", "A1_ISSRSLC", "A1_RECFET", "A1_FOMEZER", "A1_IDESTN", "A1_TPCAMP", "A1_INCULT", "A1_ORIGCT"}

	//--->>>> Trecho utilizando durante o Desenvolvimento e Testes da rotina <<<<---// <<< TESTE_ADEMAR >>>
	// if GetTempPath() <> "C:\Users\adema\AppData\Local\Temp\"
	// 	MsgAlert(OemToAnsi("TAKE EASY... Rotina ainda em construção !!!"),FunDesc())
	// 	//Return
	// endif

	// for nI := 1 to Len(aFieldsSA1)
	//     oStruSA1:RemoveField(aFieldsSA1[nI])
	// next

	oStruSA1:SetNoFolder()
	oStruSA1:SetNoGroups()

    oStruVMJ:RemoveField("VMJ_CODCLI")
    oStruVMJ:RemoveField("VMJ_XLOJA")

    oStruVMK:RemoveField("VMK_CODCLI")
    oStruVMK:RemoveField("VMK_XLOJA")

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('FORM_SA1', oStruSA1,'MASTERSA1' )
	oView:AddGrid('GRID_VMJ' , oStruVMJ,'DETAILVMJ')
	oView:AddGrid('GRID_VMK' , oStruVMK,'DETAILVMK')
	
	oView:AddIncrementField( 'GRID_VMJ', 'VMJ_CODSEQ' )
	oView:AddIncrementField( 'GRID_VMK', 'VMK_CODSEQ' )

	oView:EnableTitleView("FORM_SA1", "Dados do Cliente")
	oView:EnableTitleView("GRID_VMJ", "Propriedades Agrícolas")
	oView:EnableTitleView("GRID_VMK", "Culturas")

	oView:CreateHorizontalBox( 'BOX_FORM_SA1', 25)
	oView:CreateHorizontalBox( 'BOX_GRID1', 37)
	oView:CreateHorizontalBox( 'BOX_GRID2', 38)
	
	oView:SetOwnerView('FORM_SA1','BOX_FORM_SA1')
	oView:SetOwnerView('GRID_VMJ','BOX_GRID1')
	oView:SetOwnerView('GRID_VMK','BOX_GRID2')

Return oView
