#Include "PROTHEUS.CH"

/*/{Protheus.docn TVSTDCL
r

MSG("PASSOU" + SF1->F1_FILIAL + SF1->F1_DOC)iption)
@type user function
@author user
@since 19/11/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function TVSTDCL()
	Local cMensagem := "Deseja Limpar o Flag para NF JD passar pela Classificação SmartDocs?"

	If SF1->F1_FORNECE == '674782'
		If FwAlertYesNo(cMEnsagem, "Limpar Flag?")
			RecLock('SF1',.F.)
			SF1->F1_XSTVLD := ''
			MsUnLock()
		else
			Alert("A Nota não será classificada pela rotina SmartDocs!")
		EndIf
	else
		Alert("Esta Nota não é da John Deere")
	Endif

Return
