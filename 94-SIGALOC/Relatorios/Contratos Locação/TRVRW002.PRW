#INCLUDE "rwmake.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "MSOLE.CH"
// #INCLUDE 'TRYEXCEPTION.CH'

//-------------------------------------------------------------------
/*
+-------------------------------------------------------------------------------------------------------+
¦ Programa responsavel por gerar Contrato de Locaocao
¦ Desenvolvido para TERRA VERDE
¦ @author  Elivelton Canedo elivelton.canedo@totvs.com.br
| @since 01/08/2024
¦ Ultima atualização
¦ Historico :
|
¦
+-------------------------------------------------------------------------------------------------------+
Obs:

ATUALIZAR NA OFICIAL:

campos criados:

/*/
//-------------------------------------------------------------------

USER FUNCTION TRVRW002()
    Local OEXCEPTION
    Local aAreaFP1, aAreaFPA,lContinua
    Local CMSGERROR   := ""
    Local cPerg       := "TRVRW002"

    Private cProjet   := FP0->FP0_PROJET
    Private cFilFP0   := FP0->FP0_FILIAL

    Private _cPathSV  := "\modelos\"       // path padrao dos modelos, pasta deve constar dentro do "Rootpath"
    Private _cPathWin :=  GETTEMPPATH()     // path do diretorio temp do windows C:\WINDOWS\TEMP\

     If !PERGPARAM()
         AVISO("Documento de Contrato", "Operação Cancelada pelo Usuário!", {"Ok"}, 2, "ATENÇÃO")
          Return
      EndIf

       
    cObra := MV_PAR01

    // TRYEXCEPTION   // Tratamento de erro em tempo de execução

        aAreaFP1 := FP1->(getarea())
        aAreaFPA := FPA->(getarea())

        FP1->(dbsetorder(1)) // FP1_FILIAL+FP1_PROJET+FP1_OBRA
        FPA->(dbsetorder(1)) // FPA_FILIAL+FPA_PROJET+FPA_OBRA+FPA_SEQGRU+FPA_CNJ

        lContinua := .t.
        If !FP1->(dbseek(cFilFP0+cProjet+cObra))  // FP1_FILIAL+FP1_PROJET+FP1_OBRA
            AVISO("Documento de Contrato", "Obra: "+cObra+" Não encontrada!", {"Ok"}, 2, "ATENÇÃO")
            lContinua := .f.
        Endif

        If !FPA->(dbseek(cFilFP0+cProjet+cObra)) // FPA_FILIAL+FPA_PROJET+FPA_OBRA+FPA_SEQGRU+FPA_CNJ
            AVISO("Documento de Contrato", "Item da Obra: "+cObra+" Não encontrado!", {"Ok"}, 2, "ATENÇÃO")
            lContinua := .f.
        Endif

        If lContinua
            processa({||PrintCON()},,"Gerando Documento de Contrato ...")
        ENDIF

        FP1->(RestArea(aAreaFP1))
        FPA->(RestArea(aAreaFPA))

    // CATCHEXCEPTION USING OEXCEPTION

    //     IF ( VALTYPE( OEXCEPTION ) == "O" )
    //         CMSGERROR += CAPTUREERROR()
        //     AVISO("ERROR CAPTURED",CMSGERROR,{"OK"},3,"ERROR",,"ENGRENAGEM")
        //     __QUIT()
        // ENDIF

    // ENDEXCEPTION NODELSTACKERROR

RETURN

Static Function PrintCON()
    Local _cArqcli, _cPathDot, cNomArqDot, hWord, _cArqFinal
    Local aAreaSA1,aAreaSUS
    Local cNomecli,cEndcli,cBaircli,cCepcli,cMuncli,cEstcli,cCGCcli,cInsccli,cEmaicli,cTelcli,cDDDcli,cPessoa,cComple
    Local nTotal,dDtin,dDten,cHrfra,cItens,cLocAt,nValPro,cObs,cHrAd,cIda,cVolta,cFinali
    Local cEstEx
    Local aDadosEmp     := FwSM0Util():GetSM0Data(cEmpAnt,cFilAnt,{"M0_NOMECOM","M0_ENDENT","M0_BAIRENT","M0_CEPENT","M0_CIDENT","M0_ESTENT","M0_CGC","M0_INSC","M0_TEL"})

    aAreaSA1 := SA1->(getarea())
    aAreaSUS := SUS->(getarea())

    SA1->(dbsetorder(1))  // A1_FILIAL+A1_COD+A1_LOJA
    SUS->(dbsetorder(1)) // US_FILIAL + US_COD+US_LOJA

    //Documento de Contrato
    
    If FP1->FP1_FINALI == '4' //Veículos
        cNomArqDot := "TRVRW102"
    Else
        cNomArqDot := "TRVRW101"
    Endif

    _cArqcli   := _cPathWin + cNomArqDot + ".dot"
    _cPathDot  := _cPathSV  + cNomArqDot + ".dot"

    // Verifica se ja existe o arquivo de trabalho na pasta do usuÃ¡rio
    if(!File(_cPathDot))
        Alert("Arquivo modelo não existe!")
        return
    Else
        If file(_cArqCli)
            Ferase(_cArqCli)
        Endif
    Endif

    // Copia o arquivo .dot para area temporaria da maquina
    cpyS2T( _cPathDot , _cPathWin , .T. )  // Copia arquivo modelo para o client

    If !file(_cArqCli)
        Alert("cpyS2T Falhou!")
        return
    Endif
    hWord	:= OLE_CreateLink('TMSOLEWORD97')      // Conecta ao word

    OLE_NewFile(hWord, _cArqCli )                  // Abre arquivo copiado no Client
    OLE_SetProperty( hWord, oleWdVisible,   .f. )  // Exibir o arquivo para o usuario
    OLE_SetProperty( hWord, oleWdPrintBack, .t. )

    SA1->(dbseek(xfilial("SA1")+FP0->FP0_CLI+FP0->FP0_LOJA)) // A1_FILIAL+A1_COD+A1_LOJA
    SUS->(dbseek(xfilial("SUS")+FP0->FP0_PROSPE+FP0->FP0_LOJAP)) //US_FILIAL+US_COD+US_LOJA

    //Informacoes do cliente
    cNomecli:= SPACE(1)
    cEndcli:=  SPACE(1)
    cBaircli:= SPACE(1)
    cCepcli:=  SPACE(1)
    cMuncli:=  SPACE(1)
    cEstcli:=  SPACE(1)
    cCGCcli:=  SPACE(1)
    cInsccli:= SPACE(1)
    cEmaicli:= SPACE(1)
    cTelcli:=  SPACE(1)
    cDDDcli:=  SPACE(1)
    cPessoa:=  SPACE(1)
    cComple:=  SPACE(1)

    IF !EMPTY(FP0->FP0_CLI)
        cNomecli:= SA1->A1_NOME
        cEndcli:=  SA1->A1_END
        cBaircli:= SA1->A1_BAIRRO
        cCepcli:=  SA1->A1_CEP
        cMuncli:=  SA1->A1_MUN
        cEstcli:=  SA1->A1_EST
        cCGCcli:=  SA1->A1_CGC
        cInsccli:= SA1->A1_INSCR
        cEmaicli:= SA1->A1_EMAIL
        cTelcli:=  SA1->A1_TEL
        cDDDcli:=  SA1->A1_DDD
        cPessoa:=  SA1->A1_PESSOA
        cComple:=  SA1->A1_COMPLEM

        crlNome   := SA1->A1_XRLNOME
        crlCPF    := SA1->A1_XRLCPF
        crlEnd    := SA1->A1_XRLEND
        crlCompl  := SA1->A1_XRLCOMP
        crlBairro := SA1->A1_XRLBAIR
        crlMun    := SA1->A1_XRLMUN
        crlEst    := SA1->A1_XRLEST
        crlCep    := SA1->A1_XRLCEP

    ELSE //Caso seja prospect
        cNomecli:= SUS->US_NOME
        cEndcli:=  SUS->US_END
        cBaircli:= SUS->US_BAIRRO
        cCepcli:=  SUS->US_CEP
        cMuncli:=  SUS->US_MUN
        cEstcli:=  SUS->US_EST
        cCGCcli:=  SUS->US_CGC
        cInsccli:= SUS->US_INSCR
        cEmaicli:= SUS->US_EMAIL
        cTelcli:=  SUS->US_TEL
        cDDDcli:=  SUS->US_DDD
        cPessoa:=  SUS->US_PESSOA
    ENDIF

    if len(alltrim(cCGCcli)) > 11
        cCGCcli:= transf(alltrim(cCGCcli),"@R 99.999.999/9999-99")
    else
        cCGCcli:= transf(alltrim(cCGCcli),"@R 999.999.999-99")
    endif
    if len(alltrim(cTelcli)) > 8
        cTelcli:=  "("+alltrim(cDDDcli)+") "+alltrim(transf(cTelcli,"@R 99999-9999"))
    else
        cTelcli:=  "("+alltrim(cDDDcli)+") "+alltrim(transf(cTelcli,"@R 9999-9999"))
    endif

    cLocAt  := alltrim(FP1->FP1_MUNORI) +" - "+ alltrim(FP1->FP1_ESTORI)
    nValSeg := alltrim(transf((FP1->FP1_XVMSEG),X3Picture("FP1_XVMSEG")))
    
    
    // nValPro := alltrim(transf((FP0->FP0_VALPRO),X3Picture("FP0_VALPRO")))
    cObs    := FP0->FP0_OBS

    // Informações da Empresa                                                  //
    //{"M0_FULNAME","M0_ENDENT","M0_BAIRENT","M0_CEPENT","M0_CIDENT","M0_ESTENT","M0_CGC","M0_INSC","M0_TEL"}
    OLE_SetDocumentVar(hWord,"M0_FULNAME"   ,Alltrim(aDadosEmp[1][2]))
    OLE_SetDocumentVar(hWord,"M0_ENDENT"    ,Alltrim(aDadosEmp[2][2]))
    OLE_SetDocumentVar(hWord,"M0_BAIRENT"   ,Alltrim(aDadosEmp[3][2]))
    OLE_SetDocumentVar(hWord,"M0_CEPENT"    ,Subs(Alltrim(aDadosEmp[4][2]),1,5)+"-"+Subs(Alltrim(aDadosEmp[4][2]),6,3))
    OLE_SetDocumentVar(hWord,"M0_CIDENT"    ,Alltrim(aDadosEmp[5][2]))
    OLE_SetDocumentVar(hWord,"M0_ESTENT"    ,Alltrim(aDadosEmp[6][2]))
    OLE_SetDocumentVar(hWord,"M0_CGC"       ,Alltrim(aDadosEmp[7][2]))
    OLE_SetDocumentVar(hWord,"M0_INSC"      ,Alltrim(aDadosEmp[8][2]))
    OLE_SetDocumentVar(hWord,"M0_TEL"       ,Alltrim(aDadosEmp[9][2]))

    //Cliente
    OLE_SetDocumentVar(hWord, 'projeto' , alltrim(cProjet  ))
    OLE_SetDocumentVar(hWord, 'Nomecli' , alltrim(cNomecli ))
    OLE_SetDocumentVar(hWord, 'Endcli'  , alltrim(cEndcli  ))
    OLE_SetDocumentVar(hWord, 'Baircli' , alltrim(cBaircli ))
    OLE_SetDocumentVar(hWord, 'Cepcli'  , transf(alltrim(cCepcli),"@R 99999-999"))
    OLE_SetDocumentVar(hWord, 'Muncli'  , alltrim(cMuncli  ))
    OLE_SetDocumentVar(hWord, 'Estcli'  , alltrim(cEstcli  ))
    cEstEx:= Posicione("SX5",1,xFilial("SX5")+"12"+ cEstcli,"X5_DESCRI") // Pegar o nome do estado por extenso
    OLE_SetDocumentVar(hWord, 'EstEx'   , alltrim(cEstEx  ))
    OLE_SetDocumentVar(hWord, 'CGCcli'  , alltrim(cCGCcli  ))
    OLE_SetDocumentVar(hWord, 'Insccli' , alltrim(FP0->FP0_CLIINS))
    OLE_SetDocumentVar(hWord, 'Emaicli' , alltrim(cEmaicli ))
    OLE_SetDocumentVar(hWord, 'Telcli'  , alltrim(cTelcli  ))
    OLE_SetDocumentVar(hWord, 'DDDcli'  , alltrim(cDDDcli  ))
    OLE_SetDocumentVar(hWord, 'Pessoa'  , alltrim(cPessoa  ))
    OLE_SetDocumentVar(hWord, 'Comple'  , alltrim(cComple  ))
    OLE_SetDocumentVar(hWord, 'LocAt'   , alltrim(cLocAt  ))
    OLE_SetDocumentVar(hWord, 'Obs'     , alltrim(cObs  ))

    OLE_SetDocumentVar(hWord, 'rlNome'   , alltrim(crlNome ))
    OLE_SetDocumentVar(hWord, 'rlCPF'    , alltrim(crlCPF))
    OLE_SetDocumentVar(hWord, 'rlEnd'    , alltrim(crlEnd))
    OLE_SetDocumentVar(hWord, 'rlCompl'  , alltrim(crlCompl))
    OLE_SetDocumentVar(hWord, 'rlBairro' , alltrim(crlBairro ))
    OLE_SetDocumentVar(hWord, 'rlCep'    , transf(alltrim(crlCep),"@R 99999-999"))
    OLE_SetDocumentVar(hWord, 'rlMun'    , alltrim(crlMun))
    OLE_SetDocumentVar(hWord, 'rlEst'    , alltrim(crlEst))


    dDtin   := CtoD(space(1))
    dDten   := CtoD(space(1))
    cHrfra   := Space(1)
    dDtfm   := CtoD(space(1))
    nTotal  := 0
    cItens  :=space(1)
    cHrAd   :=space(1)  
    cIda    :=space(1)
    cVolta  :=space(1)
    cFinali :=space(1)
    lEquip   := .f.

    cCRLF := CRLF
    cVeicItens := ''

    nVlrTotal := 0

    While !FPA->(eof()) .and. FPA->FPA_PROJET == cProjet .and. FPA->FPA_OBRA == cObra .and. cFilFP0 == FPA->FPA_FILIAL

        IF FPA->FPA_TIPOSE $("S")
            FPA->(dbskip())
            loop
        Endif

        lEquip := !EMPTY(FPA->FPA_GRUA)

        ST9->(dbseek(cFilFP0+FPA->FPA_GRUA))   // T9_FILIAL+T9_CODBEM

        SB1->( dbsetorder(1))
        SB1->( dbSeek(FwxFilial("SB1")+FPA->FPA_PRODUT))

        if EMPTY(dDtin)
            dDtin:= (DTOC(FPA->FPA_DTINI))
        endif
        if EMPTY(dDten)
            dDten:= (DTOC(FPA->FPA_DTENRE))
        endif
        if EMPTY(cHrfra)
            cHrfra:= CVALTOCHAR(FPA->FPA_HRFRAQ) + " horas"
        endif
        if EMPTY(cIda)
            cIda:= FPA->FPA_TPGUIM
        endif
        if EMPTY(cVolta)
            cVolta:= FPA->FPA_TPGUID
        endif
        if EMPTY(dDtfm)
            dDtfm:= FPA->FPA_DTFIM
        endif
           
        // If lEquip
            cHrAd+=  alltrim(FPA->FPA_DESGRU)+": R$ "+ alltrim(transf((FPA->FPA_VLHREX),X3Picture("FPA_VLHREX")))+" / "
            cItens+=  alltrim(FPA->FPA_GRUA)+" - "+alltrim(FPA->FPA_DESGRU)+" - "+alltrim(ST9->T9_CHASSI)+" / "
        // Else
        //     cHrAd+=  alltrim(SB1->B1_DESC)+": R$ "+ alltrim(transf((FPA->FPA_VLHREX),X3Picture("FPA_VLHREX")))+" / "
        //     cItens+=  alltrim(FPA->FPA_PRODUT)+" - "+alltrim(SB1->B1_DESC)
        // Endif

        cVeicItens += alltrim(FPA->FPA_GRUA)+" - "+alltrim(FPA->FPA_DESGRU)+" - "+alltrim(ST9->T9_CHASSI) + ": R$ "+ alltrim(transf((FPA->FPA_PRCUNI),X3Picture("FPA_PRCUNI"))) + cCRLF

        nTotal+= FPA->FPA_VRHOR

        // nMeses    := DateDiffMonth(dDtin,dDten)
        nMeses    := round(DateDiffDay(ctod(dDtin),ctod(dDten))/30,0)
        nVlrTotal += (nMeses * FPA->FPA_VLBRUT)

        FPA->(dbskip())
    End

    nValPro := alltrim(transf((nVlrTotal),X3Picture("FP0_VALPRO")))

    cHrAd:=  alltrim(subs(cHrAd,1,len(cHrAd)-2))
    cItens:=  alltrim(subs(cItens,1,len(cItens)-2))

    // cMeses:= DateDiffMonth(dDtin,dDten)//diferença de Meses
    cMeses:= round(DateDiffDay(ctod(dDtin),ctod(dDten))/30,0)
    cDiaFM:= alltrim(subs(DTOC(dDtfm),1,2))

    Do Case
        Case Val(cDiaFM) <= 19
            cDiaFM:= "10"
        OTherWise
            cDiaFM:= "20"
    EndCase

    Do Case
        Case FP1->FP1_FINALI == "1"
            cFinali:= "FLORESTAL"
        Case FP1->FP1_FINALI == "2"
            cFinali:= "AGRÍCOLA"
        Case FP1->FP1_FINALI == "4"
            cFinali:= "VEÍCULOS"
        OTherWise
            cFinali:= "DIVERSOS"
    EndCase
    // cFinali:= "DIVERSOS"

    OLE_SetDocumentVar(hWord, 'dDtin'       , (dDtin))
    OLE_SetDocumentVar(hWord, 'dDten'       , (dDten))
    OLE_SetDocumentVar(hWord, 'dDtfm'       , DTOC(dDtfm))
    OLE_SetDocumentVar(hWord, 'Meses'       , PadL(cValToChar(cMeses), 2, '0'))
    OLE_SetDocumentVar(hWord, 'ExtMeses'     , Alltrim( extenso(cMeses, .T.) ) )
    OLE_SetDocumentVar(hWord, 'Total'       , alltrim(transf((nTotal),X3Picture("FPA_VRHOR"))))
    OLE_SetDocumentVar(hWord, 'Itens'       , alltrim(cItens))
    OLE_SetDocumentVar(hWord, 'Finali'      , alltrim(cFinali))
    OLE_SetDocumentVar(hWord, 'ValPro'      , alltrim(nValPro))
    OLE_SetDocumentVar(hWord, 'ValSeg'      , alltrim(nValSeg))
    OLE_SetDocumentVar(hWord, 'DiaFM'       , alltrim(cDiaFM))
    OLE_SetDocumentVar(hWord, 'Hrfra'       , alltrim(cHrfra))
    OLE_SetDocumentVar(hWord, 'HrAd'        , alltrim(cHrAd))
                                   
    
    If FP1->FP1_FINALI == "4"
        OLE_SetDocumentVar(hWord, 'veic_itens'        , alltrim(cVeicItens))
    Endif


    OLE_SetDocumentVar(hWord, 'HrAd'        , alltrim(cHrAd))

    cDtAss:= ("em, "+STRZERO(Day(dDataBase),2)+" de "+MesExtenso(dDataBase)+" de "+StrZero(Year(dDataBase),4))
    OLE_SetDocumentVar(hWord, 'DtAss'    , alltrim(cDtAss))

    Do Case
        Case cIda == "L"
            OLE_SetDocumentVar(hWord, 'IdaNAME' , alltrim(aDadosEmp[1][2]))
        Case cIda == "C"
            OLE_SetDocumentVar(hWord, 'IdaNAME' , alltrim(cNomecli ))
        OTherWise
            OLE_SetDocumentVar(hWord, 'IdaNAME' , space(1))
    EndCase 

    Do Case
        Case cVolta == "L"
            OLE_SetDocumentVar(hWord, 'VolNAME' , alltrim(aDadosEmp[1][2]))
        Case cVolta == "C"
            OLE_SetDocumentVar(hWord, 'VolNAME' , alltrim(cNomecli ))
        OTherWise
            OLE_SetDocumentVar(hWord, 'VolNAME' , space(1))
    EndCase


    // Atualizando as variaveis do documento do Word
    OLE_UpdateFields(hWord)
    //Macros
    //Documento de Contrato
    //   OLE_ExecuteMacro( hWord , "Macro1" )

    _cArqFinal := _cPathWin + "Cont_"+StrTran(alltrim(cProjet),'/','-')+"_"+alltrim(cObra)+"_"+DTOS(DDATABASE)+"_"+STRTRAN(LEFT(TIME(),5), ":", "")+".doc"
    // Grava o Arquivo com outro nome
    If File ( _cArqFinal )
        FErase( _cArqFinal )
    EndIf
    OLE_SaveAsFile( hWord, _cArqFinal )

    //Abre o Arquivo já salvo
    ShellExecute( "Open", _cArqFinal, " ", _cPathWin, 3 )

    // Fecha o Word e Corta o Link
    OLE_CloseFile( hWord )
    OLE_CloseLink( hWord )

    SUS->(RestArea(aAreaSUS))
    SA1->(RestArea(aAreaSA1))

Return



STATIC FUNCTION PERGPARAM(CPERG)
LOCAL APERGS   := {}
LOCAL _cObra   := "001" //Criavar("FP1_OBRA")
LOCAL lRet     := .F.   

AADD(APERGS ,{1,"Obra",_cObra,"@!",".T.",  ,".T.", 50,.F.})

If ParamBox(APERGS, "Informe os parâmetros")
	lRet := .T.
ENDIF

RETURN (lRet)
