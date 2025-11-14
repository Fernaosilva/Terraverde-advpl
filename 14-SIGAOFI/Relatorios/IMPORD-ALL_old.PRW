#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE "PROTHEUS.CH"
#include "fileio.ch"
#Include "OFIXDEF.CH"

#DEFINE PECA_GRUITE 		01 			// Grupo do Item
#DEFINE PECA_CODITE 		02 			// Codigo do Item
#DEFINE PECA_TIPTEM 		03 			// Tipo de Tempo
#DEFINE PECA_NUMOSV 		04 			// Numero da Ordem de Servico
#DEFINE PECA_QTDREQ 		05 			// Qtde da Peca Requisitada
#DEFINE PECA_VALVO3 		06 			// Valor do Item Gravado na VO3
#DEFINE PECA_VALDES 		07 			// Valor do Desconto
#DEFINE PECA_PERDES 		08 			// Percentual de Desconto
#DEFINE PECA_VALOR  		09 			// Valor do Item no Fechamento (Pode ser diferente do VO3 dependendo do Tipo de Tempo )
#DEFINE PECA_VALBRU 		10 			// Valor Bruto Total do Item
#DEFINE PECA_DEPINT 		11 			// Departamento Interno
#DEFINE PECA_DEPGAR 		12 			// Departamento Garantia
#DEFINE PECA_DESCRICAO 		13 			// Descricao do Produto
#DEFINE PECA_MOV 			14 			// Matriz com movimentacoes de produto
#DEFINE PECA_MOV_NOSNUM		/*14*/ 01	// Nosso Numero Requisicao (VO2_NOSNUM)
#DEFINE PECA_MOV_DATREQ		/*14*/ 02	// Data da Requisicao
#DEFINE PECA_MOV_REQDEV		/*14*/ 03	// Requisicao/Devolucao (VO2_DEVOLU)
#DEFINE PECA_MOV_QTDREQ		/*14*/ 04	// Quantidade requisitada
#DEFINE PECA_MOV_RECVO3		/*14*/ 05	// Recno da VO3
#DEFINE PECA_MOV_VALPEC		/*14*/ 06	// Valor da Peca
#DEFINE PECA_MOV_FUNREQ		/*14*/ 07	// Funcionario que requisitou
#DEFINE PECA_MOV_PROREQ		/*14*/ 08	// Produtivo que esta utilizando a peca
#DEFINE PECA_CLIENTE 		15 			// Codigo do Cliente // Faturar Para
#DEFINE PECA_LOJA 			16 			// Loja do Cliente // Faturar Para
#DEFINE PECA_DATLIB 		17 			// Data de Liberacao
#DEFINE PECA_DATCAN 		18 			// Data de Cancelamento
#DEFINE PECA_DATFEC 		19 			// Data de Fechamento
#DEFINE PECA_INCONV_GRUPO 	20 			// Inconveniente // Grupo
#DEFINE PECA_INCONV_CODIGO 	21 			// Inconveniente // Codigo
#DEFINE PECA_INCONV_SEQ 	22 			// Inconveniente // Sequencia
#DEFINE PECA_INCONV_DESCR 	23 			// Inconveniente // Descricao
#DEFINE PECA_TES 			24 			// TES
#DEFINE PECA_LIBVOO 		25 			// Numero da Liberacao do Tipo de Tempo (VOO_LIBVOO)
#DEFINE PECA_OPER 			26 			// Tipo de Operacao (TES Inteligente)
#DEFINE PECA_FORMULA 		27 			// Formula
#DEFINE PECA_VALIMP 		28 			// Total de Impostos
#DEFINE PECA_NUMNFI 		29 			// Numero da Nota Fiscal
#DEFINE PECA_SERNFI 		30 			// Serie da Nota Fiscal
#DEFINE PECA_CUSTOT 		31 			// Custo da Mercadoria
#DEFINE PECA_FUNFEC 		32 			// Funcionario que fechou o Tipo de Tempo
#DEFINE PECA_ICMST  		33 			// ICMS ST
#DEFINE PECA_QTDREM  		34			// Saldo de Pecas em remessa para atendimento externo

#DEFINE SRVC_GRUSER 		01 			// Grupo de Servico
#DEFINE SRVC_CODSER 		02 			// Codigo do Servico
#DEFINE SRVC_NUMOSV 		03 			// Numero da Ordem de Servico
#DEFINE SRVC_TIPTEM 		04 			// Tipo de Tempo
#DEFINE SRVC_TIPSER 		05 			// Tipo de Servico
#DEFINE SRVC_INCMOB 		06 			// Tipo de Cobranca (VOK_INCMOB)
#DEFINE SRVC_VALBRU 		07 			// Valor do Servico (Valor Bruto)
#DEFINE SRVC_VALDES 		08 			// Valor do Desconto
#DEFINE SRVC_VALLIQ 		09 			// Valor do Servico (Valor Liquido)
#DEFINE SRVC_TEMPAD 		10 			// Tempo Padrao (MINUTOS CENTESIMAL)
#DEFINE SRVC_TEMTRA 		11 			// Tempo Trabalhado (MINUTOS CENTESIMAL)
#DEFINE SRVC_TEMCOB 		12 			// Tempo Cobranca (MINUTOS CENTESIMAL)
#DEFINE SRVC_TEMVEN 		13 			// Tempo Vendido (MINUTOS CENTESIMAL)
#DEFINE SRVC_APONT 			14 			// Matriz de Apontamentos do Servico
#DEFINE SRVC_APONT_CODIGO	/*14*/ 01	// Codigo do Produtivo
#DEFINE SRVC_APONT_DATINI	/*14*/ 02	// Data Inicial
#DEFINE SRVC_APONT_HORINI	/*14*/ 03	// Hora Inicial
#DEFINE SRVC_APONT_DATFIN	/*14*/ 04	// Data Final
#DEFINE SRVC_APONT_HOTFIN	/*14*/ 05	// Hora Final
#DEFINE SRVC_APONT_TEMTRA	/*14*/ 06	// Tempo Trabalhado (MINUTOS CENTESIMAL)
#DEFINE SRVC_APONT_SEQUEN	/*14*/ 07	// Sequencia (VO4_SEQUEN)
#DEFINE SRVC_APONT_RECVO4	/*14*/ 08	// Recno da VO4
#DEFINE SRVC_APONT_NOSNUM	/*14*/ 09	// Nosso Numero Requisicao (VO4_NOSNUM)
#DEFINE SRVC_APONT_VALLIQ	/*14*/ 10	// Valor Liquido do Servico (Por Apontamento)
#DEFINE SRVC_APONT_RECVSC	/*14*/ 11	// Recno da VSC
#DEFINE SRVC_APONT_NOME		/*14*/ 12	// Nome do Produtivo
#DEFINE SRVC_APONT_TEMCOB	/*14*/ 13	// Tempo cobrado proporcional ao Tempo Trabalhado
#DEFINE SRVC_APONT_FUNREQ	/*14*/ 14	// Funcionario que requisitou
#DEFINE SRVC_APONT_MPAUSA	/*14*/ 15	// Motivo da Pausa
#DEFINE SRVC_APONT_PERRAT	/*14*/ 16	// Departamento Garantia
#DEFINE SRVC_DESCRICAO 		15			// Descricao do Servico
#DEFINE SRVC_DESCRTIPSER 	16			// Descricao do Tipo de Servico
#DEFINE SRVC_PERDES 		17			// Percentual de Desconto
#DEFINE SRVC_CODSEC 		18			// Codigo da Secao
#DEFINE SRVC_KILROD 		19			// Kilometros Rodados (Fechamento por KM)
#DEFINE SRVC_CLIENTE 		20			// Codigo do Cliente - Faturar Para
#DEFINE SRVC_LOJA 			21			// Loja do Cliente - Faturar Para
#DEFINE SRVC_DATLIB			22			// Data de Liberacao
#DEFINE SRVC_DATCAN			23			// Data de Cancelamento
#DEFINE SRVC_DATFEC			24			// Data de Fechamento
#DEFINE SRVC_CODFOR			25			// (Srvc. Terceiros) - Fornecedor
#DEFINE SRVC_FOLOJA			26			// (Srvc. Terceiros) - Loja
#DEFINE SRVC_NUMTIT			27			// (Srvc. Terceiros) - Numero do Titulo (Financeiro)
#DEFINE SRVC_TIPTIT			28			// (Srvc. Terceiros) - Tipo do Titulo (Financeiro)
#DEFINE SRVC_DATPAG			29			// (Srvc. Terceiros) - Data do Pagamento
#DEFINE SRVC_CODPAG			30			// (Srvc. Terceiros) - Cond. de Pagamento
#DEFINE SRVC_NATURE			31			// (Srvc. Terceiros) - Natureza
#DEFINE SRVC_VALCUS			32			// (Srvc. Terceiros) - Valor do Custo
#DEFINE SRVC_INCONV_GRUPO	33			// Inconveniente - Grupo
#DEFINE SRVC_INCONV_CODIGO	34			// Inconveniente - Codigo
#DEFINE SRVC_INCONV_SEQ		35			// Inconveniente - Sequencia
#DEFINE SRVC_INCONV_DESCR	36			// Inconveniente - Descricao
#DEFINE SRVC_SERINT			37			// Codigo Interno do Servico
#DEFINE SRVC_LIBVOO			38			// Numero da Liberacao do Tipo de Tempo (VOO_LIBVOO)
#DEFINE SRVC_VALIMP			39			// Total de Impostos (VEC_TOTIMP)
#DEFINE SRVC_NUMNFI			40			// Numero da Nota Fiscal
#DEFINE SRVC_SERNFI			41			// Serie da Nota Fiscal
#DEFINE SRVC_FUNFEC			42			// Funcionario que fechou o Tipo de Tempo
#DEFINE SRVC_VALHOR			43			// Valor da Hora
#DEFINE SRVC_VALSER			44			// Valor Fixo do Servico (quando gravado do VO4)
#DEFINE SRVC_DEPINT			45			// Departamento Interno
#DEFINE SRVC_DEPGAR			46			// Departamento Garantia

/*/{Protheus.doc} IMPORD
Impressão de Ordens de Serviços
@type function
@version 12.1.27
@author André Delorme
@since 04/10/2013
@link https://gkcmp.com.br (Geeker Company)
@see https://tdn.totvs.com/display/public/framework/FWMsPrinter
@history 15/09/2023, Ademar Fernandes Jr., Implementado melhoria solicitada
@return variant, Nil
/*/
//Esta rotina utiliza a Classe FMWsPrinter
//Para mais informações a respeito desta Classe,  acesse: http://tdn.totvs.com/display/public/mp/FWMsPrinter;jsessionid=2EF25AFCA53971F6E104D95E82544D8F
//
//Parametros da Classe TFont
//		 1o - cName				caractere	Indica o nome da fonte que será utilizada.
//		 2o - uPar2				numérico	Compatibilidade.
//		 3o - nHeight			numérico	Indica o tamanho da fonte.
//		 4o - uPar4				lógico		Compatibilidade.
//		 5o - lBold				lógico		Indica se habilita(.T.)/desabilita(.F.) o estilo negrito.
//		 6o - uPar6				numérico	Compatibilidade.
//		 7o - uPar7				lógico		Compatibilidade.
//		 8o - uPar8				numérico	Compatibilidade.
//		 9o - uPar9				lógico		Compatibilidade.
//		10o - lUnderline	lógico		Indica se habilita(.T.)/desabilita(.F.) o estilo sublinhado.
//		11o - lItalic			lógico		Indica se habilita(.T.)/desabilita(.F.) o estilo itálico.
User Function IMPORD()
Local nCntFor
Local nY
Local nCont   := 1
Local cFig    := GetSrvProfString("StartPath","")
Local cTIPSRV := SuperGetMV("ZZ_TIPSRV",.F.,"AEIP/AEIS/CIP/CIPR/CIPV/CIS/CISR/CIST/CISV/RISV/SIIS/SIPV/SISV/SIPS/CTIS/CTIV/PISV/CIPP/CIRS/CIPS/CET/ATIV/RGAA/RGAF/CIRP/CISP/CIPV/CISV/RISV/SIPV/SISV/CTIV/PIPV/PISV/GISV/GIPV/PSAS/CSIS/CSIP/FGP/FGS/")
Local nObs    := 0  // Declaração da variável nObs

Private oVerdana9	 := TFont():New( 'Verdana' , 6 , 10 , , .F. , , , , .T. , .F. )
Private oVerdanaBold := TFont():New( 'Verdana' , 6 , 10 , , .T. , , , , .T. , .F. )
Private nIni20 := 0
Private nMaxT  := 0
Private nMax   := 0  
Private aFrame1 := {}
Private aCabec1 := {}
Private nIni5  := 0 
Private cTipTem := ""
Private nSeqPec := 1
Private lOpcResum := .F.
Private nTotResum := 0

//-Chama tela pra imprimir opçao Normal ou com Serviço Resumido
fnOpcResum(@lOpcResum)

if Type("nFormul") != "U" 
	if nFormul == 2 // variavel recebida do ofior010
		if Type("ParamIXB") != "U" 
			cTipTem := ParamIxb[03] 
		Endif
	Endif
Endif

DbSelectArea("VV1")
DbSetOrder(1)
DbSeek(xFilial("VV1")+VO1->VO1_CHAINT)
//
DbSelectArea("VV2")
DbSetOrder(1)
DbSeek(xFilial("VV2")+VV1->VV1_CODMAR+VV1->VV1_MODVEI)
//
DbSelectArea("VVC")
DbSetOrder(1)
DbSeek( xFilial("VVC") + VV1->VV1_CODMAR + VV1->VV1_CORVEI )
//
DbSelectArea("SA1")
DbSetOrder(1)
If ( Empty(VO1->VO1_FATPAR) .Or. !SA1->( DbSeek( xFilial("SA1")+VO1->VO1_FATPAR+VO1->VO1_LOJA ) ) )
	SA1->( DbSeek( xFilial("SA1")+VO1->VO1_PROVEI+VO1->VO1_LOJPRO ) )
EndIf
if Len(Alltrim(SA1->A1_CGC)) == 14
	cCGCCPFC := TRANS(SA1->A1_CGC,"@R 99.999.999/9999-99")
else
	cCGCCPFC := TRANS(SA1->A1_CGC,"@R 999.999.999-99")
endif
//
DbSelectArea("VAI")
DbSetOrder(1)
DbSeek(xFilial("VAI")+VO1->VO1_FUNABE)

//
aOSTTPC := FMX_CALPEC(VO1->VO1_NUMOSV,,,,,.t.,,,,,,,,,.f.)
aOSTTSC := FMX_CALSER(VO1->VO1_NUMOSV,,,,,.t.)
aOSDIRE := {}
aOSSSPC := {}
                                              
dbSelectArea("VST")
dbSetOrder(1)
dbSeek(xFilial("VST")+"2"+VO1->VO1_NUMOSV)
While !Eof() .and. xFilial("VO1") == VO1->VO1_FILIAL .and. VST->VST_TIPO == "2" .and. VO1->VO1_NUMOSV == VST->VST_CODIGO
	aAdd(aOSSSPC,VST->VST_DESINC )
	aAdd(aOSDIRE,VST->VST_INFREP )
	dbSkip()
Enddo

//
CSTARTPATH := GETPVPROFSTRING(GETENVSERVER(),"StartPath","ERROR",GETADV97())
CSTARTPATH += IIF(RIGHT(CSTARTPATH,1) <> "\","\","")
CSTARTPATH = __RELDIR

nPag := 1

oPrinter := FWMSPrinter():New("OS"+STRZERO(VAL(VO1->VO1_NUMOSV),9)+"_2", IMP_PDF, .f.,CSTARTPATH , .t.)
oPrinter:SetPortrait()
oPrinter:SetPaperSize(DMPAPER_A4)
oPrinter:SetMargin(0,0,0,0)
oPrinter:cPathPDF := CSTARTPATH

aVetTTLoc := {}
for nCntFor := 1 to Len(aOSTTPC)
	nPos := ascan(aVetTTLoc,aOSTTPC[nCntFor,PECA_TIPTEM])
	if nPos == 0
		aAdd(aVetTTLoc,aOSTTPC[nCntFor,PECA_TIPTEM])
	endif
next
for nCntFor := 1 to Len(aOSTTSC)
	nPos := ascan(aVetTTLoc,aOSTTSC[nCntFor,SRVC_TIPTEM])
	if nPos == 0
		aAdd(aVetTTLoc,aOSTTSC[nCntFor,SRVC_TIPTEM])
	endif
next
cTxtTT := ""
for nCntFor := 1 to Len(aVetTTLoc)
	cTxtTT += Alltrim(aVetTTLoc[nCntFor])+IIF(nCntFor !=Len(aVetTTLoc),",","")
next

SM0->(dbSetOrder(1))
SM0->(dbSeek(cEmpAnt+VO1->VO1_FILIAL))

aFrame1 := { { 1 , 0 ,  0 ,  4 , 4 , "C" , "@!" , "" },; 
             { 2 , 0 ,  4 , 24 , 4 , "C" , "@!" , "" },;
			 { 3 , 0 , 28 ,  8 , 4 , "C" , "@!" , "" } }
aCabec1 :=   { ;
             { 1 , 0 ,  4 , 24 , 1 , "C" , "@!" , Alltrim(SM0->M0_NOMECOM),                                     0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 2 , 0 , 28 ,  8 , 1 , "C" , "@!" , "ORDEM DE SERVIÇO",                                           0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 ,  4 , 24 , 1 , "C" , "@!" , Alltrim(SM0->M0_ENDENT),                                      0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 2 , 1 , 28 ,  8 , 1 , "C" , "@!" , Alltrim(VO1->VO1_NUMOSV),                                     0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 ,  4 , 24 , 1 , "C" , "@!" , Alltrim(SM0->M0_TEL) + " " + Alltrim(SM0->M0_FAX),            0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 28 ,  4 , 1 , "C" , "@!" , "Dt.Emissão:",                                                 0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 2 , 2 , 32 ,  4 , 1 , "C" , "@!" , Transform(VO1->VO1_DATABE,"@D"),                              0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 ,  4 , 24 , 1 , "C" , "@!" , Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"),               0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 28 ,  4 , 1 , "C" , "@!" , "Prev.Entrega:",                                              0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 2 , 3 , 32 ,  4 , 1 , "C" , "@!" , Transform(VO1->VO1_DATENT,"@D"),                              0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } } }

aFrame2 := { { 1 , 0 ,  0 , 36 , 1 , "C" , "@!" , "" } }
aCabec2 := { { 1 , 0 ,  0 ,  4 , 1 , "C" , "@!" , "Atendente:",                                                 0,            , { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
             { 1 , 0 ,  4 ,  8 , 1 , "C" , "@!" , LEFT(ALLTRIM(VAI->VAI_NOMTEC),30),                            0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 0 , 12 ,  4 , 1 , "C" , "@!" , "Tipo:",                                                      0,            , { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
             { 1 , 0 , 16 ,  8 , 1 , "C" , "@!" , cTxtTT,                                                       0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 0 , 24 ,  4 , 1 , "C" , "@!" , "Cor Módulo:",                                                0,            , { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
             { 1 , 0 , 28 ,  8 , 1 , "C" , "@!" , " ",                                                          0,            , { .f. , .f. , .f. , .f. } , { 0 , 2 } } }  /* TODO <<COR MODULO>> */

aCabec3 := { { 1 , 0 ,  0 , 36 , 1 , "C" , "@!" , "DADOS DO CLIENTE",                                           0,,             { .t. , .t. , .t. , .t. } , { 2 , 2 } },;
             { 1 , 1 ,  0 ,  4 , 1 , "C" , "@!" , "Cliente:",                                                   0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 ,  4 , 20 , 1 , "C" , "@!" , Alltrim(SA1->A1_COD)+" "+LEFT(ALLTRIM(SA1->A1_NOME),30),      0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 , 24 ,  4 , 1 , "C" , "@!" , "CGC/CPF:",                                                   0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 , 28 ,  8 , 1 , "C" , "@!" , cCGCCPFC ,                                                    0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 ,  4 , 32 , 1 , "C" , "@!" , "[] Usuario           [] Condutor           [] Proprietário", 0,,             { .f. , .f. , .f. , .f. } , { 2 , 2 } },;
             { 1 , 3 ,  0 ,  4 , 1 , "C" , "@!" , "Endereço:",                                                  0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 ,  4 , 20 , 1 , "C" , "@!" , LEFT(SA1->A1_END,37) ,                                        0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 24 ,  4 , 1 , "C" , "@!" , "CEP:",                                                       0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 28 ,  8 , 1 , "C" , "@!" , Transform(SA1->A1_CEP,"@R 99999-999") ,                       0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 4 ,  0 ,  4 , 1 , "C" , "@!" , "Bairro:",                                                    0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 4 ,  4 ,  8 , 1 , "C" , "@!" , LEFT(SA1->A1_BAIRRO,37),                                      0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 4 , 12 ,  4 , 1 , "C" , "@!" , "Cidade:",                                                    0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 4 , 16 ,  8 , 1 , "C" , "@!" , LEFT(SA1->A1_MUN,37),                                         0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 4 , 24 ,  4 , 1 , "C" , "@!" , "UF:",                                                        0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 4 , 28 ,  8 , 1 , "C" , "@!" , SA1->A1_EST,                                                  0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 5 ,  0 ,  4 , 1 , "C" , "@!" , "Fone Res.:",                                                 0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 5 ,  4 ,  8 , 1 , "C" , "@!" , "("+SA1->A1_DDD+")"+SA1->A1_TEL,                              0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 5 , 12 ,  4 , 1 , "C" , "@!" , "Fone Coml.:",                                                0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 5 , 16 ,  8 , 1 , "C" , "@!" , " " ,                                                         0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 5 , 24 ,  4 , 1 , "C" , "@!" , "Fone Cel.:",                                                 0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 5 , 28 ,  8 , 1 , "C" , "@!" , " ",                                                          0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 6 ,  0 ,  4 , 1 , "C" , "@!" , "Email:",                                                     0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 6 ,  4 , 32 , 1 , "C" , "@!" , Alltrim(SA1->A1_EMAIL),                                       0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } } }

aCabec4 := { { 1 , 0 ,  0 , 36 , 1 , "C" , "@!" , "DADOS DO VEICULO",                                           0,,             { .t. , .t. , .t. , .t. } , { 2 , 2 } },;
             { 1 , 1 ,  0 ,  4 , 1 , "C" , "@!" , "Veículo:",                                                   0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 ,  4 ,  8 , 1 , "C" , "@!" , VV2->VV2_DESMOD,                                              0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 , 12 ,  4 , 1 , "C" , "@!" , "Chassi:",                                                    0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 , 16 ,  8 , 1 , "C" , "@!" , VV1->VV1_CHASSI,                                              0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 , 24 ,  4 , 1 , "C" , "@!" , "Motor:",                                                     0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 1 , 28 ,  8 , 1 , "C" , "@!" , VV1->VV1_NUMMOT,                                              0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 ,  0 ,  4 , 1 , "C" , "@!" , "Frota:",                                                     0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 ,  4 ,  8 , 1 , "C" , "@!" , VV1->VV1_CODFRO,                                              0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 12 ,  4 , 1 , "C" , "@!" , "Cor:",                                                       0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 16 ,  8 , 1 , "C" , "@!" , VVC->VVC_DESCRI,                                              0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 24 ,  4 , 1 , "C" , "@!" , "Nível Comb.:",                                               0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 28 ,  2 , 1 , "C" , "@!" , " " ,                                                         0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 30 ,  3 , 1 , "C" , "@!" , "Km:" ,                                                       0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 2 , 33 ,  3 , 1 , "C" , "@!" , Alltrim(STR(VO1->VO1_KILOME)),                                0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 ,  0 ,  4 , 1 , "C" , "@!" , "Ano/Modelo:" ,                                               0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 ,  4 ,  8 , 1 , "C" , "@!" , Transform(VV1->VV1_FABMOD,"@R 9999/9999"),                    0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 12 ,  4 , 1 , "C" , "@!" , "Dt.Vend.:",                                                  0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 16 ,  8 , 1 , "C" , "@!" , DTOC(VO1->VO1_DATATE),                                        0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 24 ,  4 , 1 , "C" , "@!" , "Conc.Vend.:",                                                 0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
             { 1 , 3 , 28 ,  8 , 1 , "C" , "@!" , Alltrim(SM0->M0_NOMECOM),                                     0,,             { .f. , .f. , .f. , .f. } , { 0 , 2 } } }

nTotPec := 0
nDesPec := 0
nTotSer := 0
nDesSer := 0
//while nIni20 <= Len(aOSTTPC) .or. nIni20 <= Len(aOSTTSC) .or. nIni5 <= Len(aOSSSPC) .or. nIni5 <= Len(aOSDIRE)

aCabec5 := { { 1 , 0 ,  0 , 36 , 1 , "C" , "@!" , "SERVIÇOS SOLICITADOS PELO CLIENTE" }, ;
             { 1 , 1 ,  0 ,  4 , 1 , "C" , "@!" , "Cód." },;
             { 1 , 1 ,  4 , 32 , 1 , "C" , "@!" , "Descrição" } }

nIni5 += 5

aFrame3 := { { 1 , 0 ,  0 , 36 , 6 , "C" , "@!" , "" }}
aFrame4 := { { 1 , 0 ,  0 , 36 , 6 , "C" , "@!" , "" }}
	
oPrinter:StartPage()
	
oPrinter:SayBitmap ( 12,8, cFig+"logo.bmp" , 64, 40 )
	
nMax := FS_MntTab(oPrinter, aFrame1, 12, 8)
nMaxT := FS_MntTab(oPrinter, aCabec1, 12, 8)
QuebraPag()
nMaxT+=2
nMax := FS_MntTab(oPrinter, aFrame2, nMaxT, 8)
nMaxT := FS_MntTab(oPrinter, aCabec2, nMaxT, 8)
QuebraPag()
nMaxT+=2
nMaxT := FS_MntTab(oPrinter, aCabec3, nMaxT, 8)
QuebraPag()
nMaxT+=2
nMaxT := FS_MntTab(oPrinter, aCabec4, nMaxT, 8)
	//	nMaxT+=2
	//	nMaxT := FS_MntTab(oPrinter, aCabec5, nMaxT, 8)
nMaxT+=2
QuebraPag()
	//	nMaxT := FS_MntTab(oPrinter, aCabec6, nMaxT, 8)
	//	nMaxT+=2
	
if Len(aOSTTSC) > 0 
	aResum7 := {}
	aCabec7 := { { 1 , 0 ,  0 ,  36 , 1 , "C" , "@!" , "Fechamento" },;
	             { 1 , 1 ,  0 ,   4 , 1 , "C" , "@!" , "Cód."       },;
	             { 1 , 1 ,  4 ,  20 , 1 , "C" , "@!" , "Serviço"    },;
	             { 1 , 1 , 24 ,   4 , 1 , "C" , "@!" , "Val.Unit."  },;
	             { 1 , 1 , 28 ,   4 , 1 , "C" , "@!" , "Qtde."      },;
	             { 1 , 1 , 32 ,   4 , 1 , "C" , "@!" , "Total"      } }

	nMaxT := FS_MntTab(oPrinter, aCabec7, nMaxT, 8)
	QuebraPag()
	For nCntFor := 1 to Len(aOSTTSC)
		aCabec7 := {}
		// Ajuste no tamanho da descrição do serviço para evitar truncamento
		cDescServ := Alltrim(aOSTTSC[nIni20 + nCntFor,SRVC_GRUSER]) + " " + ;
		             Alltrim(aOSTTSC[nIni20 + nCntFor,SRVC_CODSER]) + " - " + ;
		             Alltrim(aOSTTSC[nIni20 + nCntFor,SRVC_DESCRICAO])
		
		// Limita o tamanho da descrição para caber na coluna
		If Len(cDescServ) > 40
			cDescServ := Substr(cDescServ, 1, 37) + "..."
		EndIf
		
		aAdd(aCabec7, { 1 ,0, 0 ,  4 , 1 , "C" , "@!" , STRZERO(nIni20 + nCntFor,3), 0 ,, { .f. , .f. , .f. , .f. } , { 2 , 2 } } )
		aAdd(aCabec7, { 1 ,0, 4 , 20 , 1 , "C" , "@!" , cDescServ, 0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } } )
		
		// Formatação dos valores monetários com 2 casas decimais
		If aOSTTSC[nIni20 + nCntFor,SRVC_INCMOB] $ "5" // KM 
			nValUnit := Round(aOSTTSC[nIni20 + nCntFor,SRVC_VALLIQ] / aOSTTSC[nIni20 + nCntFor,SRVC_KILROD], 2)
			aAdd(aCabec7,{ 1 , 0 , 24 , 4 , 1 , "C" , "@!" , Transform(nValUnit,"@E 9,999,999.99"), 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
			aAdd(aCabec7,{ 1 , 0 , 28 , 4 , 1 , "C" , "@!" , Transform(aOSTTSC[nIni20 + nCntFor,SRVC_KILROD],"@E 99,999,999"), 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
		ElseIf aOSTTSC[nIni20 + nCntFor,SRVC_INCMOB] <> "2" // Serviço não terceirizado
			nValUnit := Round(aOSTTSC[nIni20 + nCntFor,SRVC_VALLIQ] / (aOSTTSC[nIni20 + nCntFor,SRVC_TEMCOB] / 100), 2)
			aAdd(aCabec7,{ 1 , 0 , 24 , 4 , 1 , "C" , "@!" , Transform(nValUnit,"@E 9,999,999.99"), 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
			aAdd(aCabec7,{ 1 , 0 , 28 , 4 , 1 , "C" , "@!" , Transform(aOSTTSC[nIni20 + nCntFor,SRVC_TEMCOB],"@R 999:99"), 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
		EndIf

		// Total do serviço
		aAdd(aCabec7,{ 1 , 0 , 32 , 4 , 1 , "C" , "@!" , Transform(aOSTTSC[nIni20 + nCntFor,SRVC_VALLIQ],"@E 9,999,999.99"), 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
		
		// Acumula totais
		nTotSer += Round(aOSTTSC[nIni20 + nCntFor,SRVC_VALBRU], 2)
		nDesSer += Round(aOSTTSC[nIni20 + nCntFor,SRVC_VALDES], 2)

		// Verifica se deve resumir os serviços
		if lOpcResum
			if !(Alltrim(aOSTTSC[nCntFor,SRVC_TIPTEM]) $ cTIPSRV)
				nTotResum += aOSTTSC[nIni20 + nCntFor,SRVC_VALBRU]
				aAdd(aResum7, aCabec7)
			endif
		else
			nMaxT := FS_MntTab(oPrinter, aCabec7, nMaxT, 8)
			QuebraPag()
		endif
	next     

	//-Aglutina os Serviços (diferente de fat.interno), conforme o Tipo de Tempo do Parametro, somando as siglas que não estao no Parametro "ZZ_TIPSRV"
	if Len(aResum7) > 0
		For nY := 1 To Len(aResum7)
			if nY == 1
				aResum7[nY,02,08] := "SO - MAO DE OBRA - DIVERSOS"
				While Len(aResum7[nY]) > 3
					nAux := Len(aResum7[nY])-1
					aDel(aResum7[nY],03)
					aSize(aResum7[nY],nAux)
				Enddo
				aResum7[nY,03,06] := "N"
				aResum7[nY,03,07] := "@E 9,999,999.99"
				aResum7[nY,03,08] := nTotResum
			else
				if Len(aResum7) >= nY
					aDel(aResum7,nY)
					aSize(aResum7,01)
				endif
			endif
		Next nY

		nMaxT := FS_MntTab(oPrinter, aResum7[01], nMaxT, 8)
		QuebraPag()
	endif

	aCabec7 := {}
	aAdd(aCabec7,{1,2,32,4,1,"C","@!", "" ,0,,{.f.,.f.,.f.,.f.}, {1,2} } )
	nMaxT := FS_MntTab(oPrinter, aCabec7, nMaxT, 8)
	QuebraPag()
Endif  

// Cabeçalho dos Itens de Peças
aCabec8 :=  {;
			{1, 00, 00, 03, 1, "C", "@!", "Cód." 	 	},;
			{1, 00, 03, 13, 1, "C", "@!", "Itens" 	 	},;
			{1, 00, 16, 04, 1, "C", "@!", "Val.Unit." 	},;
			{1, 00, 20, 04, 1, "C", "@!", "Qtde."	 	},;
			{1, 00, 24, 04, 1, "C", "@!", "ICMS" 	 	},;
			{1, 00, 28, 04, 1, "C", "@!", "NCM" 		},; 
			{1, 00, 32, 04, 1, "C", "@!", "Total" 	 	}}  

nMaxT := FS_MntTab(oPrinter, aCabec8, nMaxT, 8)
QuebraPag()
if Len(aOSTTPC) > 0 
	For nCntFor := 1 to Len(aOSTTPC)
		if aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ] == 0
			Loop
		Endif  			

		DbSelectArea("SA1")
		SA1->(DbSeek(xFilial("SA1")+aOSTTPC[nIni20 + nCntFor,PECA_CLIENTE]+aOSTTPC[nIni20 + nCntFor,PECA_LOJA]))
		//Tipo Cliente
		cTipoCli := SA1->A1_TIPO
		
		DbSelectArea("SB1")
		SB1->(DbSeek(xFilial("SB1")+aOSTTPC[nIni20 + nCntFor,PECA_CODITE]))
		//NCM
		cNCM := SB1->B1_POSIPI

		//Inicializa a função fiscal para poder simular os valores dos impostos
		aArea := GetArea() 
		MaFisIni(aOSTTPC[nIni20 + nCntFor,PECA_CLIENTE], aOSTTPC[nIni20 + nCntFor,PECA_LOJA], "C", "N", cTipoCli,,, .F., "SB1")
		MaFisAdd(aOSTTPC[nIni20 + nCntFor,PECA_CODITE], aOSTTPC[nIni20 + nCntFor,PECA_TES] /*SF4->F4_CODIGO*/, aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ],(aOSTTPC[nIni20 + nCntFor,PECA_VALBRU]-aOSTTPC[nIni20 + nCntFor,PECA_VALDES])/aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ], 0, "", "",, 0, 0, 0, 0, aOSTTPC[nIni20 + nCntFor,PECA_VALBRU], 0, SB1->(Recno()))
		nIcms := MaFisRet(1,"IT_ALIQICM")
		MaFisEnd()
		RestArea( aArea ) 

		//Alert(MaFisRet(nCont,"IT_ALIQICM"))
		//aOSTTPC[nIni20 + nCntFor,PECA_ICMST] := MaFisRet(1,'IT_ALIQICM')

		aCabec8 := {}
		
		/*
		aAdd(aCabec8,{ 1 , 0 ,  0 ,  4 , 1 , "C" , "@!" , STRZERO(nIni20 + nSeqPec++,3),0,,{.f.,.f.,.f.,.f.}, {2,2} } )
		aAdd(aCabec8,{ 1 , 0 ,  4 , 20 , 1 , "C" , "@!" , aOSTTPC[nIni20 + nCntFor,PECA_GRUITE] +" "+aOSTTPC[nIni20 + nCntFor,PECA_CODITE]+" "+aOSTTPC[nIni20 + nCntFor,PECA_DESCRICAO],                    0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } } )
		aAdd(aCabec8,{ 1 , 0 , 24 ,  4 , 1 , "C" , "@!" , Transform((aOSTTPC[nIni20 + nCntFor,PECA_VALBRU]-aOSTTPC[nIni20 + nCntFor,PECA_VALDES])/aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ],"@E 9,999,999.99"), 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
		aAdd(aCabec8,{ 1 , 0 , 28 ,  4 , 1 , "C" , "@!" , Transform(aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ],"@E 99999999"),                                                                                   0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
		aAdd(aCabec8,{ 1 , 0 , 32 ,  4 , 1 , "C" , "@!" , Transform(aOSTTPC[nIni20 + nCntFor,PECA_VALBRU]-aOSTTPC[nIni20 + nCntFor,PECA_VALDES],"@E 9,999,999.99"),                                         0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
		*/
		aAdd(aCabec8,{ 1 , 0 , 00 , 03 , 1 , "C" , "@!" , STRZERO(nIni20 + nSeqPec++,3),0,,{.f.,.f.,.f.,.f.}, {2,2} } )
		aAdd(aCabec8,{ 1 , 0 , 03 , 13 , 1 , "C" , "@!" , aOSTTPC[nIni20 + nCntFor,PECA_GRUITE] +" "+ SUBSTR(aOSTTPC[nIni20 + nCntFor,PECA_CODITE],1,12) + "  "+aOSTTPC[nIni20 + nCntFor,PECA_DESCRICAO] ,0,,{.f.,.f.,.f.,.f.}, {0,2} } )
		aAdd(aCabec8,{ 1 , 0 , 16 , 04 , 1 , "C" , "@!" , Transform(Round((aOSTTPC[nIni20 + nCntFor,PECA_VALBRU]-aOSTTPC[nIni20 + nCntFor,PECA_VALDES])/aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ],2),"@E 9,999,999.99") ,0,,{.f.,.f.,.f.,.f.}, {1,2} } )
		aAdd(aCabec8,{ 1 , 0 , 20 , 04 , 1 , "C" , "@!" , Transform(aOSTTPC[nIni20 + nCntFor,PECA_QTDREQ],"@E 99999999"),0,,{.f.,.f.,.f.,.f.}, {1,2} } )
		aAdd(aCabec8,{ 1 , 0 , 24 , 04 , 1 , "C" , "@!" , cValtoChar(nIcms)/*aOSTTPC[nIni20 + nCntFor,PECA_ICMST]*/,0,,{.f.,.f.,.f.,.f.}, {1,2} } )
		aAdd(aCabec8,{ 1 , 0 , 28 , 04 , 1 , "C" , "@!" , cValtoChar(cNCM) ,0,,{.f.,.f.,.f.,.f.}, {1,2} } )
		aAdd(aCabec8,{ 1 , 0 , 32 , 04 , 1 , "C" , "@!" , Transform(aOSTTPC[nIni20 + nCntFor,PECA_VALBRU]-aOSTTPC[nIni20 + nCntFor,PECA_VALDES],"@E 9,999,999.99") ,0,,{.f.,.f.,.f.,.f.}, {1,2} } )

		nTotPec += Round( aOSTTPC[nIni20 + nCntFor,PECA_VALBRU], 2 )
		nDesPec += Round( aOSTTPC[nIni20 + nCntFor,PECA_VALDES], 2 )
		nMaxT := FS_MntTab(oPrinter, aCabec8, nMaxT, 8)
		QuebraPag()
	next
	aCabec8 := {}
	aAdd(aCabec8,{ 1 , 2 , 32 , 4 , 1 , "C" , "@! ", "" , 0,, { .f. , .f. , .f. , .f. } , { 1 , 2 } } )
	nMaxT := FS_MntTab(oPrinter, aCabec8, nMaxT, 8)
	nMaxT+=2                            
	QuebraPag()
Endif

aCabec9 := { ;
           { 1 , 1 ,  0 , 8 , 1 , "C" , "@!" , "Serviços"  , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 1 ,  8 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 1 , 12 , 8 , 1 , "C" , "@!" , "Peças"     , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 1 , 20 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 1 , 24 , 8 , 1 , "C" , "@!" , "Ser+Pec"   , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 1 , 32 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 2 ,  0 , 8 , 1 , "C" , "@!" , "Descontos" , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 2 ,  8 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 2 , 12 , 8 , 1 , "C" , "@!" , "Descontos" , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 2 , 20 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 2 , 24 , 8 , 1 , "C" , "@!" , "Descontos" , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 2 , 32 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 3 ,  0 , 8 , 1 , "C" , "@!" , "Total"     , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 3 ,  8 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .t. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 3 , 12 , 8 , 1 , "C" , "@!" , "Total"     , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 3 , 20 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .t. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 3 , 24 , 8 , 1 , "C" , "@!" , "Total"     , 0 ,, { .f. , .f. , .f. , .f. } , { 1 , 2 } },;
           { 1 , 3 , 32 , 4 , 1 , "C" , "@!" , " "         , 0 ,, { .f. , .t. , .f. , .f. } , { 1 , 2 } } }

if lOpcResum
	aCabec9[2,8] := Transform(nTotResum,"@E 9999,999.99")
	aCabec9[4,8] := Transform(nTotPec,"@E 9999,999.99")
	aCabec9[6,8] := Transform(nTotPec + nTotResum ,"@E 9999,999.99")
	aCabec9[8,8] := Transform(nDesSer,"@E 9999,999.99")
	aCabec9[10,8] := Transform(nDesPec,"@E 9999,999.99")
	aCabec9[12,8] := Transform(nDesSer + nDesPec,"@E 9999,999.99")
	aCabec9[14,8] := Transform(nTotResum - nDesSer,"@E 9999,999.99")
	aCabec9[16,8] := Transform(nTotPec - nDesPec,"@E 9999,999.99")
	aCabec9[18,8] := Transform(nTotPec + nTotResum - (nDesSer + nDesPec) ,"@E 9999,999.99")
else
	aCabec9[2,8] := Transform(nTotSer,"@E 9999,999.99")
	aCabec9[4,8] := Transform(nTotPec,"@E 9999,999.99")
	aCabec9[6,8] := Transform(nTotPec + nTotSer ,"@E 9999,999.99")
	aCabec9[8,8] := Transform(nDesSer,"@E 9999,999.99")
	aCabec9[10,8] := Transform(nDesPec,"@E 9999,999.99")
	aCabec9[12,8] := Transform(nDesSer + nDesPec,"@E 9999,999.99")
	aCabec9[14,8] := Transform(nTotSer - nDesSer,"@E 9999,999.99")
	aCabec9[16,8] := Transform(nTotPec - nDesPec,"@E 9999,999.99")
	aCabec9[18,8] := Transform(nTotPec + nTotSer - (nDesSer + nDesPec) ,"@E 9999,999.99")
endif

aCabec10 := { { 1,  0 ,  0 , 36 , 1 , "C" , "@!" , "Pagamento : [] a Vista       [] Cartão de Crédito        [] Parcelado", 0 ,, { .f. , .f. , .f. , .f. } , { 2 ,2  } } }

aCabec12 := { { 1,  0 ,  0 , 20 , 1 , "C" , "@!" , "Autorizo a execução dos serviços acima relacionados:",                  0 ,, { .f. , .f. , .f. , .f. } , { 0 ,2  } },;
              { 1 , 0 , 20 ,  4 , 1 , "C" , "@! ", Transform(VO1->VO1_DATABE,"@D"),                                         0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 4 ,  0 ,  4 , 1 , "C" , "@! ", "Cliente:",                                                              0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 4 ,  4 , 32 , 1 , "C" , "@! ", SA1->A1_NOME,                                                            0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 5 ,  0 ,  4 , 1 , "C" , "@! ", "Pessoa Autorizada:",                                                    0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 5 , 20 , 16 , 1 , "C" , "@! ", "Assinatura do Cliente ou Pessoa Autorizada",                            0 ,, { .f. , .t. , .f. , .f. } , { 2 , 2 } } }

aCabec13 := { { 1 , 0 ,  0 , 20 , 1 , "C" , "@!" , "Veículo retirado em:",                                                  0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 0 , 20 ,  4 , 1 , "C" , "@!" , Transform(VO1->VO1_DATSAI,"@D"),                                         0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 4 ,  0 ,  4 , 1 , "C" , "@!" , "Cliente:",                                                              0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 4 ,  4 , 32 , 1 , "C" , "@!" , SA1->A1_NOME,                                                            0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 5 ,  0 ,  4 , 1 , "C" , "@!" , "Pessoa Autorizada:",                                                    0 ,, { .f. , .f. , .f. , .f. } , { 0 , 2 } },;
              { 1 , 5 , 20 , 16 , 1 , "C" , "@!" , "Assinatura do Cliente ou Pessoa Autorizada",                            0 ,, { .f. , .t. , .f. , .f. } , { 2 , 2 } } }
nMaxT := FS_MntTab(oPrinter, aCabec9, nMaxT, 8)
nMaxT+=6
QuebraPag()
nMaxT := FS_MntTab(oPrinter, aCabec10, nMaxT, 8)
nMaxT+=6
QuebraPag()
aCabec11 := {}
nCont := 0
cTextoCompleto := ""
///////////////////////////////////////////////////////////////////////////
//Patini: Tratamento para que sai os dados da observação do VO4 e VO1
///////////////////////////////////////////////////////////////////////////
// Busca observações do VO4 primeiro
if !Empty(VO4->VO4_OBSMEM)
    DbSelectArea("SYP")
    DbSetOrder(1)
    DbSeek(xFilial("SYP") + VO4->VO4_OBSMEM)
    
    While !Eof() .and. xFilial("SYP") == SYP->YP_FILIAL .and. SYP->YP_CHAVE == VO4->VO4_OBSMEM
        cTextoCompleto += AllTrim(SYP->YP_TEXTO)
        DbSelectArea("SYP")
        DbSkip()
    EndDo
EndIf

// Busca observações do VO1 em seguida
if !Empty(VO1->VO1_OBSMEM)
    DbSelectArea("SYP")
    DbSetOrder(1)
    DbSeek(xFilial("SYP") + VO1->VO1_OBSMEM)
    
    if !Empty(cTextoCompleto)
        cTextoCompleto += Chr(10) + Chr(10) // Adiciona duas quebras de linha entre as observações
    EndIf
    
    While !Eof() .and. xFilial("SYP") == SYP->YP_FILIAL .and. SYP->YP_CHAVE == VO1->VO1_OBSMEM
        cTextoCompleto += AllTrim(SYP->YP_TEXTO)
        DbSelectArea("SYP")
        DbSkip()
    EndDo
EndIf

if !Empty(cTextoCompleto)

	aLinhasObs 	:= {}
	aFinal		:= {}

	Q_MemoArray(cTextoCompleto, @aLinhasObs, 100)

	For nLinhas:= 1 to len(aLinhasObs)
		If Alltrim(aLinhasObs[1]) == Alltrim(aLinhasObs[nLinhas]) .And. nLinhas > 1 .And. !Empty(Alltrim(aLinhasObs[nLinhas]))
			Exit
		Else
			aLinhasObs[nLinhas]:= Alltrim(StrTran(aLinhasObs[nLinhas],"\13\10",""))
			aAdd(aFinal,aLinhasObs[nLinhas])
		EndIf
	Next
    //aLinhasObs := FormatObs(cTextoCompleto)
    
    // Adiciona "Obs:" na primeira linha
    aAdd(aCabec11, {1, nObs, 0, 4, 1, "C", "@!", "Obs:", 0,, {.f.,.f.,.f.,.f.}, {0,2}})
    nMaxT := FS_MntTab(oPrinter, aCabec11, nMaxT, 8)
    aCabec11 := {}
    
    // Adiciona as linhas com recuo
    For nI := 1 to Len(aFinal)
        aAdd(aCabec11, {1, nObs, 0, 50, 1, "C", "@!", aFinal[nI], 0,, {.f.,.f.,.f.,.f.}, {0,2}})
        nMaxT := FS_MntTab(oPrinter, aCabec11, nMaxT, 8)
        nMaxT += 1
        QuebraPag()
        aCabec11 := {}
    Next nI
EndIf

aAdd(aCabec11,{1,nObs,8,32,1,"C","@!", "" ,0,,{.f.,.f.,.f.,.f.}, {0,2} })
nMaxT := FS_MntTab(oPrinter, aCabec11, nMaxT, 8)
nMaxT+=2 
QuebraPag() 			
nMax := FS_MntTab(oPrinter, aFrame3, nMaxT, 8)
nMaxT := FS_MntTab(oPrinter, aCabec12, nMaxT, 8)
nMaxT+=2
nMax := FS_MntTab(oPrinter, aFrame4, nMaxT, 8)
nMaxT := FS_MntTab(oPrinter, aCabec13, nMaxT, 8)
oPrinter:EndPage()
oPrinter:Setup()
if oPrinter:nModalResult == PD_OK
	oPrinter:Preview()
else
	oPrinter:Deactivate()
EndIf

FreeObj(oPrinter)
oPrinter := Nil
return


/*/{Protheus.doc} FS_MntTab
Impressão
@author André Delorme
@since  17/04/2013
@param 1o - _oPrinter		- Objeto principal da FWMsPrinter
@param 2o - _aData			- Array com coordenadas de Impressão
@param                  -  1o elem - interno
@param                  -  2o elem - Indica a coordenada vertical em pixels
@param                  -  3o elem - Indica a coordenada horizontal em pixels
@param                  -  4o elem - Indica a posição do Objeto ao Rodapé
@param                  -  5o elem - Indica a posição do Objeto à Direita
@param                  -  6o elem - Tipo do Conteúdo da linha: Caracter ou Numérico
@param                  -  7o elem - Picture 
@param                  -  8o elem - Conteúdo da Linha
@param                  -  9o elem - Ângulo de rotação do texto
@param                  - 10o elem - Objeto do tipo TFont utilizado para definir as características da fonte 
@param                  - 11o elem - Array com liga e desliga para montagem da caixa
@param                  -     1o elem - Lateral esquerda
@param                  -     2o elem - Topo
@param                  -     3o elem - Lateral direita
@param                  -     4o elem - Rodapé
@param                  - 12o elem - Array com Alinhamento 
@param                  -     1o elem - Alinhamento Horizontal
@param                  -     2o elem - Alinhamento Vertical
@param 3o - _marTop			- Margem Superior
@param 4o - _marLeft		- Margem Esquerda
@param 5o - _aInfo			- Array com o Conteúdo da Linha -> Se não for passado, o conteúdo da linha é 8o Elemento do 2o Parâmetro (_aData)
@param 6o - nLarg				- Largura da Linha -> Default 16
@param 7o - nComp				- Comprimento da Linha -> Default 10
@param 8o - oFontPM			- Fonte -> Default é Verdana
@return posição da Linha
/*/
Static Function FS_MntTab(_oPrinter, _aData, _marTop, _marLeft,_aInfo,nLarg,nComp, oFontPM)
Local nCntFor
Default _aInfo  := {}
Default nLarg   := 16
Default nComp   := 10
Default oFontPM := oVerdana9
nMax := 0
for nCntFor := 1 to Len(_aData)
	oFontPMF := oFontPM
	nAngle := 0
	if (Len(_aData[nCntFor]) > 8)
		nAngle := _aData[nCntFor,9]
	endif
	nLinhaLin = _aData[nCntfor,2] * nComp + _marTop
	nColunLin = _aData[nCntfor,3] * nLarg + _marLeft
	nComprLin = _aData[nCntfor,5] * nComp
	nLargLin  = _aData[nCntfor,4] * nLarg
	if Len(_aData[nCntfor]) > 9 .and. _aData[nCntfor,10] != nil
		oFontPMF := _aData[nCntfor,10]
	endif
	//
	if Len(_aData[nCntfor]) > 10 .and. _aData[nCntfor,11] != nil
		if _aData[nCntfor,11,1]
			_oPrinter:Line(nLinhaLin,nColunLin,nLinhaLin + nComprLin, nColunLin,,"-2") // 5o Parâmetro  é a lar
		endif
		if _aData[nCntfor,11,2]
			_oPrinter:Line(nLinhaLin,nColunLin,nLinhaLin, nColunLin + nLargLin,,"-2")
		endif
		if _aData[nCntfor,11,3]
			_oPrinter:Line(nLinhaLin,nColunLin+nLargLin, nLinhaLin + nComprLin ,nColunLin + nLargLin,,"-2")
		endif
		if _aData[nCntfor,11,4]
			_oPrinter:Line(nLinhaLin+nComprLin,nColunLin, nLinhaLin + nComprLin ,nColunLin + nLargLin,,"-2")
		endif
	else
		_oPrinter:Line(nLinhaLin,nColunLin,nLinhaLin + nComprLin, nColunLin,,"-2")
		_oPrinter:Line(nLinhaLin,nColunLin,nLinhaLin, nColunLin + nLargLin,,"-2")
		_oPrinter:Line(nLinhaLin,nColunLin+nLargLin, nLinhaLin + nComprLin ,nColunLin + nLargLin,,"-2")
		_oPrinter:Line(nLinhaLin+nComprLin,nColunLin, nLinhaLin + nComprLin ,nColunLin + nLargLin,,"-2")
	endif
	// Parametros do Line
	// 	nTop		Numérico	Indica a coordenada vertical em pixels.	X	 
	// 	nLeft		Numérico	Indica a coordenada horizontal em pixels.	X	 
	// 	nBottom	Numérico	Indica a posição do objeto ao rodapé.	X	 
	// 	nRight	Numérico	Indica a posição do objeto à direita.	X	 
	// 	nColor	Numérico	Cor da linha. Default é 0	 	 
	// 	cPixel	Caracter	Expessura da linha em pixels. Default é "-2"	

	xValor := iif(Len(_aInfo)>0 .and. Len(_aInfo) >= nCntfor  .and. _aData[nCntfor,8] == "",_aInfo[nCntfor],_aData[nCntfor,8])
	if _aData[nCntfor,6] == "N"
		cInfo := Transform(xValor,_aData[nCntfor,7])
	else
		cInfo := xValor
	endif

	if nAngle == 0
		if Len(_aData[nCntfor]) > 11 .and. _aData[nCntfor,12] != nil
			//-FWMsPrinter():SayAlign(<nRow>,<nCol>,<cText>,[oFont],[nWidth],[nHeigth],[nClrText],[nAlignHorz],[nAlignVert])
			_oPrinter:SayAlign(nLinhaLin, nColunLin,cInfo,oFontPMF,nLargLin,nComprLin,CLR_BLACK,_aData[nCntfor,12,1],_aData[nCntfor,12,2])
		else
			_oPrinter:SayAlign(nLinhaLin, nColunLin,cInfo,oFontPMF,nLargLin,nComprLin,CLR_BLACK,2,0)
		endif
		// Parametros do SayAlign
		// 	nRow				Numérico	Indica a coordenada vertical em pixels ou caracteres.	X	 
		// 	nCol				Numérico	Indica a coordenada horizontal em pixels ou caracteres.	X	 
		// 	cText				Caracter	Indica o texto que será impresso.	X	 
		// 	oFont				Objeto		Indica o objeto do tipo TFont utilizado para definir as características da fonte aplicada na exibição do conteúdo do controle visual.	 	 
		// 	nWidth			Numérico	Indica a largura em pixels do objeto.	 	 
		// 	nHeigth			Numérico	Indica a altura em pixels do objeto.	 	 
		// 	nClrText		Numérico	Indica a cor do texto do objeto.	 	 
		// 	nAlignHorz	Numérico	Alinhamento Horizontal. Para mais informações sobre os alinhamentos disponíveis, consulte a área Observações.	 	 
		// 			0 - Alinhamento à esquerda;
		// 			1 - Alinhamento à direita;
		// 			2 - Alinhamento centralizado
		// 	nAlignVert	Numérico	Alinhamento Vertical. Para mais informações sobre os alinhamentos disponíveis, consulte a área Observações.	 	 
		//		 	0 - Alinhamento centralizado;
		// 			1 - Alinhamento superior;
		// 			2 - Alinhamento inferior
	else
		nWidth = _oPrinter:GetTextWidth(cInfo,oFontPMF) * 0.3
		_oPrinter:Say(nLinhaLin + (nComprLin/2) +(nWidth/2) , nColunLin + (nLargLin / 2) + 2 ,cInfo, oFontPMF, , , 270 )
		// Parametros do SayAlign
		// 	Nome	Tipo	Descrição	Obrigatório	Referência
		// 	nRow	Numérico	Indica a coordenada vertical em pixels ou caracteres.	X	 
		// 	nCol	Numérico	Indica a coordenada horizontal em pixels ou caracteres.	X	 
		// 	cText	Caracter	Texto a ser impresso.	X	 
		// 	oFont	Objeto	Indica o objeto do tipo TFont utilizado para definir as características da fonte aplicada na exibição do conteúdo do controle visual.	 	 
		// 	nWidth	Nulo	Indica a largura em pixels do objeto.	 	 
		// 	nClrText	Numérico	Indica a cor do texto do objeto.	 	 
		// 	nAngle	Numérico	Ângulo de rotação do texto.	 	 
		//
		// 	Observações
		// 	A imagem é ajustada para preencher todo o espaço definido entre a altura e largura do objeto.
	endif
	if nLinhaLin + nComprLin > nMax
		nMax := nLinhaLin+ nComprLin
	endif
next
return nMax


Static Function QuebraPag()
	Local cFig := GetSrvProfString("StartPath","")

	if nMaxT > 716     
		nMaxT:=1
		oPrinter:EndPage()
		oPrinter:StartPage()
		oPrinter:SayBitmap ( 12,8, cFig+"logo.bmp" , 64, 40 )
		nMax  := FS_MntTab(oPrinter, aFrame1, 12, 8)
		nMaxT := FS_MntTab(oPrinter, aCabec1, 12, 8)
	Endif			
Return

//-Chama tela pra imprimir opçao Normal ou com Serviço Resumido
Static function fnOpcResum(lOpcResum)
	local aLjArea   := Lj7GetArea({"SA1","VV1","VV2","VVC"})
	local aParamBox := {}
	local cTitle	:= OemToAnsi("Tipo de impressão de Serviços -")
	local aRetBox   := {}
	local bOk       := {|| (.T.)}
	local aButtons  := {}
	local lCentered := .T.
	local nPosX     := 0
	local nPosY     := 0
	local cLoad     := "" //--ProcName(1)
	local lCanSave  := .F.
	local lUserSave := .F.

	local nRisco	:= 1
	local aRisco	:= StrTokArr("1-Serviços Normal;2-Serviços Resumido",";")

// Parametros da função Parambox()
	// -------------------------------
	// 1 - < aParametros > - Vetor com as configurações
	// 2 - < cTitle >      - Título da janela
	// 3 - < aRet >        - Vetor passador por referencia que contém o retorno dos parâmetros
	// 4 - < bOk >         - Code block para validar o botão Ok
	// 5 - < aButtons >    - Vetor com mais botões além dos botões de Ok e Cancel
	// 6 - < lCentered >   - Centralizar a janela
	// 7 - < nPosX >       - Se não centralizar janela coordenada X para início
	// 8 - < nPosY >       - Se não centralizar janela coordenada Y para início
	// 9 - < oDlgWizard >  - Utiliza o objeto da janela ativa
	//10 - < cLoad >       - Nome do perfil se caso for carregar
	//11 - < lCanSave >    - Salvar os dados informados nos parâmetros por perfil
	//12 - < lUserSave >   - Configuração por usuário

	// Tipo 1 -> MsGet()
	//			[2]-Descricao
	//          [3]-String contendo o inicializador do campo
	//          [4]-String contendo a Picture do campo
	//          [5]-String contendo a validacao
	//          [6]-Consulta F3
	//          [7]-String contendo a validacao When
	//          [8]-Tamanho do MsGet
	//          [9]-Flag .T./.F. Parametro Obrigatorio ?
	// Tipo 2 -> Combo
	//           [2]-Descricao
	//           [3]-Numerico contendo a opcao inicial do combo
	//           [4]-Array contendo as opcoes do Combo
	//           [5]-Tamanho do Combo
	//           [6]-Validacao
	//           [7]-Flag .T./.F. Parametro Obrigatorio ?
	aadd(aParamBox, {2 , "Tipo de Relatório "    , nRisco, aRisco, 100, "", .T.})

    //-ParamBox(aParametros,cTitle,aRet,bOk,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave)
    if ParamBox(aParamBox,cTitle,aRetBox,bOk,aButtons,lCentered,nPosX,nPosY,,cLoad,lCanSave,lUserSave)
		if Valtype(aRetBox[1]) == "N" .And. aRetBox[1] == 2
			lOpcResum := .T.
		elseif Valtype(aRetBox[1]) <> "N" .And. Substr(aRetBox[1],1,1) == "2"
			lOpcResum := .T.
    	endIf
    endIf
	
	Lj7RestArea(aLjArea)
Return

//-----------------------------------------------------------------------------
/*/{Protheus.doc} FormatObs
Formata texto para impressão mantendo formatação original
@type function
@author Patini
@since  24/03/2025
@param cTexto - Texto a ser formatado
@return array - Array com as linhas formatadas
/*/
//-----------------------------------------------------------------------------
Static Function FormatObs(cTexto)
Local aLinhas := {}
Local cLinha  := ""
Local nTamLinha := 80
Local nTamDesc := 0
Local cDescri := ""
Local nPos    := 0
Local cPalavra := ""
Local cLinhaTemp := ""

// Se encontrar \13\10 no texto, trata as quebras
If AT("\13\10", cTexto) > 0
    cDescri := cTexto
    nTamDesc := AT("\13\10", cDescri)
    
    While nTamDesc > 0
        // Remove os caracteres \13\10
        cLinha := AllTrim(SubStr(cDescri, 1, nTamDesc - 1))
        
        // Remove "10" do início da linha se existir
        If Left(cLinha, 2) == "10"
            cLinha := SubStr(cLinha, 3)
        EndIf
        
        // Processa a linha palavra por palavra
        cLinhaTemp := ""
        For nW := 1 to Len(StrTokArr(cLinha, " "))
            cPalavra := StrTokArr(cLinha, " ")[nW]
            
            // Se a palavra couber na linha atual
            If Len(cLinhaTemp + " " + cPalavra) <= nTamLinha
                cLinhaTemp += If(Empty(cLinhaTemp), "", " ") + cPalavra
            Else
                // Se não couber, adiciona a linha atual e começa uma nova
                If !Empty(cLinhaTemp)
                    aAdd(aLinhas, cLinhaTemp)
                EndIf
                cLinhaTemp := cPalavra
            EndIf
        Next
        
        // Adiciona a última linha se houver conteúdo
        If !Empty(cLinhaTemp)
            aAdd(aLinhas, cLinhaTemp)
        EndIf
        
        // Remove a parte processada e os caracteres \13\10
        cDescri := AllTrim(SubStr(cDescri, nTamDesc + 4))
        nTamDesc := AT("\13\10", cDescri)
    EndDo
    
    // Processa o restante do texto, se houver
    If !Empty(cDescri)
        cLinha := AllTrim(cDescri)
        // Remove "10" do início da linha se existir
        If Left(cLinha, 2) == "10"
            cLinha := SubStr(cLinha, 3)
        EndIf
        
        // Processa a linha palavra por palavra
        cLinhaTemp := ""
        For nW := 1 to Len(StrTokArr(cLinha, " "))
            cPalavra := StrTokArr(cLinha, " ")[nW]
            
            // Se a palavra couber na linha atual
            If Len(cLinhaTemp + " " + cPalavra) <= nTamLinha
                cLinhaTemp += If(Empty(cLinhaTemp), "", " ") + cPalavra
            Else
                // Se não couber, adiciona a linha atual e começa uma nova
                If !Empty(cLinhaTemp)
                    aAdd(aLinhas, cLinhaTemp)
                EndIf
                cLinhaTemp := cPalavra
            EndIf
        Next
        
        // Adiciona a última linha se houver conteúdo
        If !Empty(cLinhaTemp)
            aAdd(aLinhas, cLinhaTemp)
        EndIf
    EndIf
Else
    // Se não encontrar \13\10, mantém a formatação original
    cTexto := StrTran(cTexto, Chr(13), "")
    aTexto := StrTokArr(cTexto, Chr(10))
    
    For nL := 1 to Len(aTexto)
        cLinha := aTexto[nL]
        
        // Se a linha estiver vazia, mantém a quebra
        If Empty(AllTrim(cLinha))
            aAdd(aLinhas, "")
            Loop
        EndIf
        
        // Processa a linha palavra por palavra
        cLinhaTemp := ""
        For nW := 1 to Len(StrTokArr(cLinha, " "))
            cPalavra := StrTokArr(cLinha, " ")[nW]
            
            // Se a palavra couber na linha atual
            If Len(cLinhaTemp + " " + cPalavra) <= nTamLinha
                cLinhaTemp += If(Empty(cLinhaTemp), "", " ") + cPalavra
            Else
                // Se não couber, adiciona a linha atual e começa uma nova
                If !Empty(cLinhaTemp)
                    aAdd(aLinhas, cLinhaTemp)
                EndIf
                cLinhaTemp := cPalavra
            EndIf
        Next
        
        // Adiciona a última linha se houver conteúdo
        If !Empty(cLinhaTemp)
            aAdd(aLinhas, cLinhaTemp)
        EndIf
    Next
EndIf

Return aLinhas
