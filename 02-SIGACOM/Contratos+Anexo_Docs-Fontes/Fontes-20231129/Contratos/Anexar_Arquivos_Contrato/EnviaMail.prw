#include "totvs.ch"
#include "ap5mail.ch"

/**
 * Classe generica de envio de e-mail Walsywa
 *
 * @author Fabio Hayama
 * @since 10/03/2015
 */

class EnviaMail

	method New() CONSTRUCTOR
	method enviaEmail(cHtml,cAssunto,cToMail)
endClass

method new() class EnviaMail
return

method enviaEmail(cHtml,cAssunto,cToMail,cFile,cFrom,cMailServer,cBCC) class EnviaMail
	
	local lOk         		:= .F.
	local lAutOk      		:= .F.
	locaL lSmtpAuth   		:= GetMv("MV_RELAUTH",,.F.)
	local nSleepErr			:= 180000	//3 min.
	local nI				:= 1

	private cSubject    	:= Alltrim(cAssunto)
	private cMailConta  	:= GetMV("MV_EMCONTA")
	private cMailSenha  	:= GetMV("MV_RELPSW")
	private cMailCtaAut 	:= GetMV("MV_RELACNT")
	private cMailSenaAut 	:= GetMV("MV_RELPSW")
	private cError      	:= ""
	private lSendOK     	:= .F.

	default cFile 			:= ""
	default cFrom			:= cMailConta
	default cMailServer		:= GetMV("MV_RELSERV")
	default cBCC			:= ""

	if !Empty(cMailServer) .And. !Empty(cMailConta) .And. !Empty(cMailSenha) .And. !Empty(cMailCtaAut)
	   	if !lOk
			CONNECT SMTP SERVER cMailServer ACCOUNT cMailConta PASSWORD cMailSenha RESULT lOk
	   	endIf

	   	if !lAutOk
			if ( lSmtpAuth )
 				lAutOk := MailAuth(cMailCtaAut, cMailSenaAut)
      		else
 	 			lAutOk := .T.
  			endIf
	   	endIf

	   	if lOk .And. lAutOk
	      	ConOut('Initializing automatic e-mail process...' + DtoC(Date()) + " as " + Time()+' Rotina: '+FUNNAME()+' - Emails: '+cToMail)
			for nI := 1 to 3
				if(Empty(cFile) .AND. Empty(cBCC))
					SEND MAIL FROM cFrom TO cToMail SUBJECT cSubject BODY cHtml RESULT lSendOk

				elseif(!Empty(cFile) .AND. Empty(cBCC))
					SEND MAIL FROM cFrom TO cToMail SUBJECT cSubject BODY cHtml ATTACHMENT cFile RESULT lSendOk

				elseif(Empty(cFile) .AND. !Empty(cBCC))
					SEND MAIL FROM cFrom TO cToMail BCC cBCC SUBJECT cSubject BODY cHtml RESULT lSendOk

				elseif(!Empty(cFile) .AND. !Empty(cBCC))
					SEND MAIL FROM cFrom TO cToMail BCC cBCC SUBJECT cSubject BODY cHtml ATTACHMENT cFile RESULT lSendOk

		      	endIf

				if lSendOk
					cAuxStat := "E"
					Exit
				else
				   cAuxStat := "R"
				   GET MAIL ERROR cError
				   cError := "ERRO-" + Alltrim(cError)
				   ConOut('Erro no envio do email! ' + cError)
				   ConOut('Erro no envio Data: '+ DtoC(Date()) + " as " + Time()+' Rotina: '+FUNNAME()+' - Emails: '+cToMail)
				   if "no response" $ Alltrim(cError)
				   		Sleep(nSleepErr)
				   		ConOut(cValtoChar(nI)+" Tentativa(s) de envio do email! ")
				   else
				   		Exit
				   endIf
				endIf
			next
			ConOut('Finalizing automatic e-mail process...'+ DtoC(Date()) + " as " + Time()+' Rotina: '+FUNNAME()+' - Emails: '+cToMail)
		else
		  GET MAIL ERROR cError
		  cError := "ERRO-" + Alltrim(cError)
		  ConOut('Automatic e-mail process error: ' + cError)
		  ConOut('Automatic erro no envio Data: '+ DtoC(Date()) + " as " + Time()+' Rotina: '+FUNNAME()+' - Emails: '+cToMail)
	   endIf
	else
		cError := "ERRO-Variaveis de e-mail vazias."
		ConOut(cError)
	endIf
return cError
