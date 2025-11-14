//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*
+-------------------------------------------------------------------------------------------------------+
¦ Programa responsavel por importar o contadores para a tabela STP por CSV
¦ Desenvolvido para Terra verde
¦ @author  Elivelton Canedo elivelton.canedo@totvs.com.br
| @since 23/09/2024
¦ Ultima atualização
¦ Historico :
|
¦
+-------------------------------------------------------------------------------------------------------+
Obs:

ATUALIZAR NA OFICIAL:


/*/
//-------------------------------------------------------------------

User Function EMTCOTCSV() 

    If MSGYESNO( "Deseja importar contadores com arquivo .CSV ?", "Atenção" )
        If !Pergunt()
            AVISO("Documento de Contrato", "Operação Cancelada pelo Usuário!", {"Ok"}, 2, "ATENÇÃO")
            Return
        EndIf
        ImpCSV()
    Endif

Return


Static Function ImpCSV() //Função responsavel por importar o csv retorno de locacao

    Local aArea     := GetArea()
    Private cArqOri := ""

    //Mostra o Prompt para selecionar arquivos
    cArqOri := tFileDialog( "CSV files (*.csv) ", 'Seleção de Arquivos', , , .F., )

    //Se tiver o arquivo de origem
    If ! Empty(cArqOri)
        //Somente se existir o arquivo e for com a extensão CSV
        If File(cArqOri) .And. Upper(SubStr(cArqOri, RAt('.', cArqOri) + 1, 3)) == 'CSV'
            Processa({|| ImportCSV() }, "Importando...")
        Else
            MsgStop("Arquivo e/ou extensão inválida!", "Atenção")
        Endif
    Endif

    RestArea(aArea)
Return

Static Function ImportCSV() //Função que importa os dados csv retorno de locacao
    Local aArea      := GetArea()
    Local cArqLog    := "Log_Contador" + dToS(Date())+".log"
    Local nTotLinhas := 0
    Local cLinAtu    := ""
    Local aLinha     := {}
    Local oArquivo
    Local aLinhas
    //Posição do Array
    Local nPosPlaca        := 1 //Coluna A no Excel
    Local nPosDtAtua       := 6 //Coluna F no Excel
    Local nPosKm           := 14 //Coluna N no Excel
    Local cPula,cPula2,cPula3,cBemcsv,cDtAtuacsv,cContcsv,lpula
    Private cDirLog    := GetTempPath() + "Log_Contador\"
    Private cLog       :=Space(1)
    Private cLogAp,cLogPl
    Private nLinhaAtu  := 0
    Private aRetirar   := {"."}
    Private aAreaST9

    cPula       :=Space(1)
    cPula2      :=Space(1)
    cPula3      :=Space(1)
    cBemcsv     :=Space(1) // Coluna Unidade rastreada
    cDtAtuacsv  :=Space(1) // Coluna Data atualizada csv
    cContcsv    :=Space(1) // Coluna Contador (Hodometro) csv

    //Texto dos logs
    cLogAp      := CRLF+CRLF+ "LISTA DOS ITENS INCLUÍDOS: "+ CRLF
    cLogPl      := CRLF+CRLF+ "LISTA DOS ITENS NÃO INCLUÍDOS: "+ CRLF

    //Se a pasta de log não existircria ela
    If ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    Endif

    //Definindo o arquivo a ser lido
    oArquivo := FWFileReader():New(cArqOri)

    //Se o arquivo pode ser aberto
    If (oArquivo:Open())

        //Se não for fim do arquivo
        If ! (oArquivo:EoF())

            //Definindo o tamanho da régua
            aLinhas := oArquivo:GetAllLines()
            nTotLinhas := Len(aLinhas)
            ProcRegua(nTotLinhas)

            // GoTop não funciona (dependendo da versão da LIB)deve fechar e abrir novamente o arquivo
            oArquivo:Close()
            oArquivo := FWFileReader():New(cArqOri)
            oArquivo:Open()

            aAreaST9 := ST9->(getarea())

            If MV_PAR01 == "01"
                ST9->(dbsetorder(14)) // T9_PLACA+T9_SITBEM

                nPosPlaca        := 9  //Coluna I  no Excel
                nPosDtAtua       := 6  //Coluna F  no Excel
                nPosKm           := 41 //Coluna AO no Excel

            Else
                ST9->(dbsetorder(19)) // T9_CHASSI

                nPosPlaca        := 2 //Coluna B no Excel
                nPosDtAtua       := 7 //Coluna G no Excel
                nPosKm           := 4 //Coluna D no Excel

            Endif
            //Enquanto tiver linhas
            While (oArquivo:HasLine())

                //Incrementa na tela a mensagem
                nLinhaAtu++
                IncProc("Analisando linha " + cValToChar(nLinhaAtu) + " de " + cValToChar(nTotLinhas) + "...")

                //Pegando a linha atual e transformando em array
                cLinAtu := oArquivo:GetLine()
                aLinha  := StrTokArr2(cLinAtu, ";",.T.)
                //Texto que fazendo pular a linha do csv
                cPula   := "resumo"
                cPula2  := "data"
                cPula3  := "descri"
                cPula4  := "localiza"
                cPula5  := "contrato"
                cPula6  := "cnpj"

                //são linhas de cabeçalho que não devem aparecer
                Do Case

                    Case Lower(cPula)  $ Lower(cLinAtu)
                        lPula:= .F.
                    Case Lower(cPula2) $ Lower(cLinAtu)
                        lPula:= .F.
                    Case Lower(cPula3) $ Lower(cLinAtu)
                        lPula:= .F.
                    Case Lower(cPula4) $ Lower(cLinAtu)
                        lPula:= .F.
                    Case Lower(cPula5) $ Lower(cLinAtu)
                        lPula:= .F.
                    Case Lower(cPula6) $ Lower(cLinAtu)
                        lPula:= .F.
                    OTherWise
                        lPula:= .T.
                EndCase


                If lPula
                    //Compara o tipo para sempre traser a variável caracter.
                    cBemcsv     := IIF(TYPE(aLinha[nPosPlaca])         == "N",alltrim(CVALTOCHAR(aLinha[nPosPlaca]))     ,alltrim(aLinha[nPosPlaca]))
                    cDtAtuacsv  := LEFT(IIF(TYPE(aLinha[nPosDtAtua])   == "N",alltrim(CVALTOCHAR(aLinha[nPosDtAtua]))    ,alltrim(aLinha[nPosDtAtua])),10)
                    cHoracsv    := SUBSTR(IIF(TYPE(aLinha[nPosDtAtua]) == "N",alltrim(CVALTOCHAR(aLinha[nPosDtAtua]))    ,alltrim(aLinha[nPosDtAtua])),12,5)
                    cContcsv    := IIF(TYPE(aLinha[nPosKm])            == "N",alltrim(CVALTOCHAR(aLinha[nPosKm]))        ,alltrim(aLinha[nPosKm]))

                    //Verifica que tudo foi preenchido corretamente
                    If ST9->(dbseek(cBemcsv))
                        If Empty(cDtAtuacsv)
                            cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", FALTA Data da atualização"+ CRLF
                        Elseif Empty(cHoracsv)
                            cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", FALTA Hora (Data da atualização)"+ CRLF

                        Elseif Empty(cContcsv)
                            cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", FALTA Hodômetro"+ CRLF
                        Else

                            IncluiSTP(ST9->T9_CODBEM,Dtos(Ctod(cDtAtuacsv)),cHoracsv,Ceiling(GetDToVal(StrDelChr(cContcsv,aRetirar))),ST9->T9_CCUSTO,ST9->T9_POSCONT)

                        Endif
                    Else
                        cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", linha não encontrada no cadastro de veículos: "+cBemcsv + CRLF

                    Endif


                Endif

            EndDo

            cLog := "Processamento finalizado, abaixo as mensagens de log: " + CRLF + cLogAp + cLogPl
            //Se tiver log, mostra ele
            If ! Empty(cLog)
                MemoWrite(cDirLog + cArqLog, cLog)
                ShellExecute("OPEN", cArqLog, "", cDirLog, 1)
            Endif

        Else
            MsgStop("Arquivo não tem conteúdo!", "Atenção")
        Endif

        //Fecha o arquivo
        oArquivo:Close()
    Else
        MsgStop("Arquivo não pode ser aberto!", "Atenção")
    Endif

    ST9->(RestArea(aAreaST9))
    RestArea(aArea)
Return

//Função de tratatica de inclusão na tabela STP
Static Function IncluiSTP(cBem,cDtOri,cHora,cCont,cCusto,cContT9)
    Local aSTP     := {}
    Local aDiaSTP  := {}
    Local x,y
    Local cQuery   := ""
    Local lHrMaior := .T. //Caso não ache data e hora maior
    Local nPor     := SuperGetMv("MV_NGPRVDI",.F.,.F.) // Percentual de variação da variação dia
    Local nDia     := SuperGetMv("MV_VARDIA",.F.,.F.)  //Define quantos registros para trás será obtido no histórico de contador para servir de base para o cálculo da variação dia
    Local nValCont,nVarDia,nDCorrido,nContInc,nContVD
    //Regra de quebra
    cQuery := " SELECT "
    cQuery += " 	STP.TP_FILIAL,STP.TP_ORDEM,STP.TP_CODBEM,STP.TP_DTLEITU,STP.TP_HORA,STP.TP_POSCONT,STP.TP_VARDIA,STP.TP_TIPOLAN"
    cQuery += " FROM "
    cQuery += " "+RETSQLNAME("STP")+" AS STP "
    cQuery += " WHERE "
    cQuery += " 	STP.TP_FILIAL = '"+XFilial("STP")+"'"
    cQuery += " 	AND STP.TP_CODBEM = '"+cBem+"'"
    cQuery += "     AND	STP.D_E_L_E_T_ = ' '"
    cQuery += " ORDER BY "
    cQuery += " 	STP.TP_DTLEITU,STP.TP_HORA,STP.TP_ORDEM"

    IIF(SELECT("TMP") > 0, TMP->(DBCLOSEAREA()), NIL)

    TCQUERY CQUERY NEW ALIAS "TMP"

    DAnt:= space(1) //Dia anterior

    While !TMP->(eof())
        //Array com toda tabela STP
        AADD(aSTP,{;
            (TMP->TP_FILIAL),;              							// 01 Filial
            (TMP->TP_ORDEM),;              								// 02 Ordem
            (TMP->TP_CODBEM),;              							// 03 Cod. Bem
            (TMP->TP_DTLEITU),;              					        // 04 Data origem
            (TMP->TP_HORA),;              								// 05 Hora
            (TMP->TP_POSCONT),;                                         // 06 Km
            (TMP->TP_DTLEITU)+"-"+(TMP->TP_HORA),;                      // 07 Data + hora
            (TMP->TP_VARDIA),;                                          // 08 Variação dia
            (TMP->TP_TIPOLAN)})                                         // 09 Tipo de lançamento
        //Array somente com um registro por dia
        IF DAnt <> TMP->TP_DTLEITU .AND. cDtOri >= TMP->TP_DTLEITU

            AADD(aDiaSTP,{;
                (TMP->TP_FILIAL),;              							// 01 Filial
                (TMP->TP_ORDEM),;              								// 02 Ordem
                (TMP->TP_CODBEM),;              							// 03 Cod. Bem
                (TMP->TP_DTLEITU),;              					        // 04 Data origem
                (TMP->TP_HORA),;              								// 05 Hora
                (TMP->TP_POSCONT),;                                         // 06 Km
                (TMP->TP_DTLEITU)+"-"+(TMP->TP_HORA),;                      // 07 Data + hora
                (TMP->TP_VARDIA),;                                          // 08 Variação dia
                (TMP->TP_TIPOLAN)})                                         // 09 Tipo de lançamento

            DAnt:= TMP->TP_DTLEITU

        Endif

        TMP->(dbskip())

    Enddo

    TMP->(dbclosearea())

    //Vefica se já existe data e hora igual na tabela STP
    If  ASCAN(aSTP, {|x| x[7] == cDtOri+"-"+cHora}) > 0
        cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Data e Hórario já exsite"+ CRLF
        Return
    Endif

    //Verifica se é menor que a primeira inclusão
    //If Len(aSTP) == 1 .and. aSTP[1][7] > cDtOri+"-"+cHora
    //    cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", a primeira inclusão deve ser feita manualmente"+ CRLF
    //    Return
    //Elseif Len(aSTP) == 0
    //    cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", a primeira inclusão deve ser feita manualmente"+ CRLF
    //    Return
    //Endif

    nValCont  := 0  //Valor do contador
    nVarDia   := 0  // Variação Dia
    nDCorrido := 0  // Dias corridos
    nContInc  := 0  // Contador Inicial
    nContVD   := 0  // Contador Variação dia

    //Atribui os ultimos valores de variação dia e Valor do contador
    If !Empty(nPor) .and. !Empty(nDia)

        for y := 1 to len(aDiaSTP)

            for x := 1 to len(aSTP)

                if aDiaSTP[y][4] == aSTP[x][4]

                    if nValCont < aSTP[x][6]
                        nValCont:= aSTP[x][6]
                    Endif

                    if nVarDia < aSTP[x][8]
                        nVarDia:= aSTP[x][8]
                    Endif

                Endif

            next

            aDiaSTP[y][6]:= nValCont
            aDiaSTP[y][8]:= nVarDia

        next

    Endif

    //Organiza as datas do maior para o menor
    aSort(aDiaSTP, , , {|x, y| x[04] > y[04]})

    // Calculo de Variação dia
    if len(aDiaSTP) >= nDia
        nDCorrido:=     DateDiffDay(sToD(cDtOri), sToD(aDiaSTP[nDia][4]))
        nContInc:=    aDiaSTP[nDia][6]
        nContVD:=   (cCont - nContInc ) /  nDCorrido

    Elseif len(aDiaSTP) > 0
        nDCorrido:=   DateDiffDay(sToD(cDtOri),sToD(aDiaSTP[len(aDiaSTP)][4]))
        nContInc:=    aDiaSTP[len(aDiaSTP)][6]
        nContVD:=   (cCont - nContInc ) /  nDCorrido

    Elseif len(aSTP) == 0
        //Primeira inclusao na STP
        nContVD:= cCont
        //Inclusao na STP
        SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
        Return
    Endif


    If (nPos :=ASCAN(aSTP, {|x| x[4] >= cDtOri})) > 0  //Procura o registo mais proximo a data atual

        For x = nPos To len(aSTP)

            If aSTP[x][7] > cDtOri+"-"+cHora //Vefica se existe hora maior que a data e hora atual
                lHrMaior:= .F.

                If aSTP[x][6] <  cCont
                    cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Valor de Contador não pode ser maior que a próxima Data"+ CRLF
                    x:= len(aSTP)
                    Return
                Endif

                If nPos > 1
                    If aSTP[x-1][6] >  cCont
                        cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Valor de Contador não pode ser menor que a Data anterior"+ CRLF
                        x:= len(aSTP)
                        Return
                    Else
                        If ((cCont * 100)/(aSTP[x-1][6])-100) > nPor .and. !Empty(nPor)
                            cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Percentual de variação da variação dia está maior que o permitido, "+cValToChar(nPor)+"%"+ CRLF
                            x:= len(aSTP)
                            Return
                        Else
                            //Inclusao na STP
                            SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
                            x:= len(aSTP)
                            Return
                        Endif
                    Endif

                Elseif nPos == 1
                    //Primeira inclusao na STP
                    nContVD:= cCont
                    //Inclusao na STP
                    SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
                    x:= len(aSTP)
                    Return
                Endif

            Endif
        Next

        If lHrMaior //Caso não exista hora maior que a data atual
            If ((cCont * 100)/(aSTP[len(aSTP)][6])-100) > nPor .and. !Empty(nPor)
                cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Percentual de variação da variação dia está maior que o permitido, "+cValToChar(nPor)+"%"+ CRLF
                Return
            Elseif aSTP[len(aSTP)][6] > cCont
                cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Valor de Contador não pode ser menor que a Data anterior"+ CRLF
                Return
            Elseif aSTP[len(aSTP)][6] > cCont
                cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Valor de Contador não pode ser menor que a Hora anterior"+ CRLF
                Return
            Else
                //Inclusao na STP
                SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
                Return
            Endif
        Endif

    Else

        If (nPos :=ASCAN(aSTP, {|x| x[6] > cCont})) > 0
            cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Valor de Contador não pode ser menor que os anteriores"+ CRLF
            Return
        Else
            If len(aSTP) > 1
                If ((cCont * 100)/(aSTP[len(aSTP)-1][6])-100) > nPor .and. !Empty(nPor)
                    cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Percentual de variação da variação dia está maior que o permitido, "+cValToChar(nPor)+"%"+ CRLF
                    Return
                Else
                    //Inclusao na STP
                    SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
                    Return
                Endif
            Else
                If ((cCont * 100)/(aSTP[len(aSTP)][6])-100) > nPor .and. !Empty(nPor)
                    cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", Percentual de variação da variação dia está maior que o permitido, "+cValToChar(nPor)+"%"+ CRLF
                    Return
                Else
                    //Inclusao na STP
                    SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
                    Return
                Endif
            Endif
        Endif

    Endif

Return

Static Function SalveSTP(cBem,cDtOri,cHora,cCont,cCusto,nContVd,cContT9)
    Local cOrdSTP
    Local aAreaSTP

    aAreaSTP := STP->(getarea())
    // STP->(dbsetorder(2)) //TP_FILIAL+TP_CODBEM+DTOS(TP_DTORIGI)+DTOS(TP_DTLEITU)+TP_HORA

    // IF STP->(dbseek(XFilial("STP")+cBem))

    If RecLock("STP",.T.)
        cOrdSTP:= GetSx8Num("STP", "TP_ORDEM")
        ConfirmSx8()

        STP->TP_FILIAL           := XFilial("STP")
        STP->TP_ORDEM            := cOrdSTP
        STP->TP_PLANO            := "000000"
        STP->TP_CODBEM           := cBem
        STP->TP_DTORIGI          := dDataBase
        STP->TP_POSCONT          := cCont
        STP->TP_DTREAL           := STOD(cDtOri)
        STP->TP_DTLEITU          := STOD(cDtOri)
        STP->TP_SITUACA          := "L"
        STP->TP_TERMINO          := "S"
        STP->TP_USULEI           := UsrRetName(RetCodUsr())
        STP->TP_DTULTAC          := STOD(cDtOri)
        STP->TP_CCUSTO            := cCusto
        STP->TP_VARDIA           := Ceiling(nContVd)
        STP->TP_TEMCONT          := "S"
        STP->TP_ACUMCON          := cCont
        STP->TP_TIPOLAN          := "C"
        STP->TP_HORA             := cHora
        STP->TP_ORIGEM           := "MNTA084"
        STP->(MsUnlock())

        cLogAp+= "+ Lin" + cValToChar(nLinhaAtu) + ", linha incluída"+ CRLF

        //Altera valores do bem da ST9
        RecLock("ST9",.F.)
        IF ST9->T9_POSCONT < cCont
            ST9->T9_POSCONT := cCont
            ST9->T9_CONTACU := cCont
            ST9->T9_VARDIA  := Ceiling(nContVd)
            ST9->T9_DTULTAC := STOD(cDtOri)
        ENDIF
        
        ST9->(MsUnlock())

    ELSE
        cLogPl+= "- Lin" + cValToChar(nLinhaAtu) + ", linha não incluída, erro no update STP"+ CRLF

    ENDIF

    STP->(RestArea(aAreaSTP))
Return


//Cria o parametro de perguntas
Static Function Pergunt()
    LOCAL APERGS    := {} //Array perguntas
    LOCAL ARET      := {} //Array retorno das perguntas
    LOCAL lPerg     := .F.

    AADD( APERGS, {2,"Tipo"     ,1, {"01=Veículos (Placa)","02=Pesados (Chassi)"} ,     090, ".T.", .F.})

    IF PARAMBOX(APERGS , "Informe os parâmetros" , ARET , /*4*/ , /*5*/ , /*6*/ , /*7*/ , /*8*/ , /*9*/ , /*10*/ , .T., .F.)  //"PARAMETROS "
        If ValType(ARET[1]) == "N";  MV_PAR01 := "01";else; MV_PAR01 := ARET[1]; endif  // TIPO         tratativa caso o usuario deixe a resposta em branco
        lPerg := .T.
    ENDIF

Return lPerg
