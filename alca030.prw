#include "totvs.ch"
#include "protheus.ch"
#include "rwmake.ch"
#INCLUDE "colors.ch"
#INCLUDE "DBTREE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "rwmake.CH"
#DEFINE MB_ICONASTERISK             64
#DEFINE ENTER		Chr(10)+Chr(13)
//
#DEFINE VERSAO_FONTE "8.0"
/*/{Protheus.doc} ALCA030
Tela de manuten��o cadastral - CRM - SCASE
	
@author S-CASE
@since 22/11/2013
@version 1.1
@version 2.0 - 19/09/2014 - RAFAEL DE PAULA - Na fun��o principal ALCA030 h� o preenchimento do array com os campos para serem trabalhados na BA1, foram retirados desse array os campos BA1_MATANT,BA1_TIPUSU, BA1_GRAUPA, pois no momento da grava��o das altera��es (CA030GRV) o sistema replicava estas informa��es para TODAS AS FAM�LIAS AS QUAIS O USU�RIO PERTENCE, o que n�o deve acontecer, pois s�o informa��es �NICAS DE CADA PLANO.
@version 2.1 - 26/01/2015 - LEANDRO MASSAFERA - Inclus�o do campo BA3_XCLASS.
@version 2.2 - 10/02/2016 - FELIPE VIEIRA - Ajuste para que so valide o banco caso seja trocado em tela.
@version 2.3 - 11/02/2016 - FELIPE VIEIRA - Ajuste para que so valide a data de vencimento caso seja trocado em tela.
@version 2.4 - 04/03/2016 - FELIPE VIEIRA - Ajuste para que valide os restos dos dados bancarios
@version 3.0 - 23/08/2016 - RAFAEL DE PAULA - Por conta da necessidade de edi��o do campo A1_BLEMAIL, foi acrescentada a pasta DADOS DO CLIENTE na tela de altera��o, consequentemente omiti alguns campos para n�o confundir o usu�rio com os dados de endere�o, cep, email (pois j� constam na primeira pasta com dados do benefici�rio). Projeto sem codigo (emiss�o de boletos eletr�nicos)
@version 4.0 - 10/05/2017 - FELIPE VIEIRA - Ajuste devidos para a demanda 16294 RN DE CANCELAMENTO
@version 5.0 - 20/07/2017 - FELIPE VIEIRA - Demandas da melhoria do callcenter (siloe)
@version 6.0 - 15/08/2017 - FELIPE VIEIRA - Ajutes para corre��o dos caracteres especiais, onde estava sendo impressos na tela para o usuario.
@version 7.0 - 21/12/2017 - RAFAEL DE PAULA - Inserido campo BA1_CPFUSR como campo edit�vel, para que passe a ler a valida��o do dicion�rio de dados, que s� permitir� edi��o caso o mesmo esteja VAZIO.				
@version 8.0 - 16/01/2018 - RAFAEL DE PAULA - Na fun��o CA030Grv, ao limitar os campos que ser�o alterados para uma mesma MATVID, faltava um ALLTRIM na compara��o, pois o campo GRAUPA continuava sendo alterado erroneamente.								
@version 9.0 - 22/04/2019 - LAURA PEGHINI - Implementada a atualiza��o da tabela ZC0, para atualiza��o do campo email quando o mesmo for alterado.
@version 10.0 - 06/05/2019 - LAURA PEGHINI - Implementada de valia��o para tipo pagamento n�o ficar vazio chamado SMOI-IM0002550607
@version 10.0 - 10/05/2019 - LAURA PEGHINI - CHAMADO SMOI-IM0002556284 - RETIRADA A VALIZA��O POIS CAMPO N�O EH ALTERAVEL, BLOQUEADA PARA ALTERA��O
@version 11.0 - 01/07/2019 - MARCOS KATO - Incluido uma valida��o antes da grava��o dos dados do usuario que verifica se a posi��o do vetor pertence ao mesmo usuario posicionado  
@param Parametro, Tipo, Descricao
@version 12.0 - 19/07/2019 - TIMOTEO BEGA - Criado as consultas padroes espeficas XSUD - Assuntos e XOCO - Ocorrencias para o modulo SIGATMK com suas respectivas janelas de filtro por descricao

@return ALTERA��ES, Altera��es via CRM com valida��es diversas.

@example
Altera��es de dados banc�rios e valida��es de campos obrigat�rios

@obs


@see (links de referencia)
/*/
/*
����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Funcao    �ALCA030    � Autor �Fab. Software S-Case� Data � 16.11.2011 ���
�������������������������������������������������������������������������Ĵ��
���Descricao �Tela de Manuntecao Cadastral. Utilizado para manutencao na  ���
���          �Ponta                                                       ���
�������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                               ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function ALCA030(lvePop)

Local lRet		 := .T.
Local aArea		 := GetArea()	// Salva a area atual
Local aArSel	 := {}
Local lEmpresa	 := .F.
Local cTitulo	 := "Alteracao cadastral"
Local nOpcA		 := 0
Local oDlgPls	 := Nil
Local aButtons	 := {}

Local oMenuAut	 := {}
Local oMenuCar	 := {}
Local oMenuCrt	 := {}

Local cFilSC := "(BD6->BD6_FASE $ '1,2,3,4' .And. ( ( BD6->BD6_SITUAC = '1' ) .Or. ( BD6->BD6_SITUAC = '3' .And. BD6->BD6_LIBERA = '1' )  )  )"
Local cFilHO := "(BE4->BE4_FASE $ '1,2,3,4' .And. BE4->BE4_SITUAC = '1')"

Local bOk
Local bCancel

Local bBotMn1    := {|| oMenuAut:Activate(C(200,'1'),L(45),oDlgPls)}
Local bBotMn2    := {|| oMenuCar:Activate(C(150,'2'),L(45),oDlgPls)}
Local bBotMn3    := {|| oMenuCrt:Activate(C(350,'3'),L(45),oDlgPls)}
Local nRecBa1    := 0

Local aSlvAcols  := aCols
Local aColsAux	 := {}
Local bVisFam	 := {|| PLSA260Mov("BA1",BA1->(Recno()),2) }

Local bBotCob    := {|| nRecBa1 := BA1->(Recno()),;
						PLSVLRCOB(,,.T.),;
						BA1->(DbGoTo(nRecBa1)) }

Local aPosObj    := {}
Local aPosGet    := {}
Local aObjects   := {}
Local aInfo		 := {}
Local aSize      := MsAdvSize( .F. )

Local cCodCli  	 := ""
Local cLojCli	 := ""
Local cNivCob	 := ""
Local cCodOpe 	 := ""
Local cCodEmp 	 := ""
Local cMatricUsr := ""
Local cTiReg	 := ""
Local cContrato  := ""
Local cVerCon	 := ""
Local cSubCon	 := ""
Local cVerSub	 := ""
Local cMatric	 := ""
LOCAL cMatricBA1 := ""

Local oObsMemo 	 := Nil
Local cObsMemo   := ""
Local oMonoAs  	 := TFont():New( "Courier New",6,0) 			// Fonte para o campo Memo

Local nIndCob 	 := 0
Local nLarCobDef := 0
Local nLarCob 	 := 0

Local nIndCad 	 := 0
Local nLarCadDef := 0
Local nLarCad 	 := 0
Local lPainel	 := .F.
Local lDisableA1 := .F.

LOCAL aCliente := {}
Local oBar
LOCAL oFolder

Local lSelEntF3	:= GetNewPar("MV_TMKF3",.F.)
Local cTimeIni	:= Time()
Local cTimeFim

// Leandro Massafera - 25/07/2013
// Parametros/Variaveis para tratar a edicao do campo Matricula e Orgao do SIAPE
//Local _cAjuMat := GetMv("GA_SIAPEMT")
//Local _cAjuOrg := GetMv("GA_SIAPEOR")
Local nSeg	:= 0
Local nMin	:= 0
LOCAL aRetPto := {}
lOCAL oEncBA1
Local i			:=1
Local aButtonsEn:={}
Local lInibTel :=.T.
Local lHabAbaCob  	:= GetNewPar("MV_PLHBCOB",.T.)
Local lHabAbaVen	:=.T.
Local aBKGets		:= IIf(Type("aGets") == "A", aClone(aGets), {})
Local aBKTela		:= IIf(Type("aTela") == "A", aClone(aTela), {})
//Local aCpoSA1		:= {"A1_COD","A1_NOME","A1_EMAIL","A1_CEP","A1_END","A1_NUM_END","A1_COMPL","A1_BAIRRO","A1_MUN","A1_EST","A1_DDD","A1_TEL","A1_BLEMAIL","NOUSER"}
Local aCpoSA1		:= {"A1_COD","A1_NOME","A1_BLEMAIL","NOUSER"} //omitidos os demais campos da SA1 pois agora a pasta ir� ser apresentada na tela e pode confundir o usu�rio. RAFAEL DE PAULA - 23/08/2016 versionamento 4.0
Local aEditSA1	:= {"A1_BLEMAIL"}
Local aCpoBA3	:= {"BA3_VENCTO","BA3_TIPPAG","BA3_BCOCLI","BA3_XCSCON","BA3_AGECLI","BA3_CTACLI","BA3_AGEDI","BA3_CTADI","BA3_OP","BA3_NOMPRE","BA3_TIPCOB","BA3_TPCON","BA3_AUTCEF","BA3_CADCEF","BA3_CPFPRE","NOUSER","BA3_LOTAC","BA3_XCODSI","BA3_MATEMP","BA3_XMATBE","BA3_XTPSER","BA3_STASIA","BA3_XDESIA","BA3_XLGSIA","BA3_XDTSIA","BA3_XCLASS"}
Local aEditBA3	:= {"BA3_VENCTO","BA3_TIPPAG","BA3_BCOCLI","BA3_XCSCON","BA3_AGECLI","BA3_CTACLI","BA3_AGEDI","BA3_CTADI","BA3_OP","BA3_TPCON","BA3_XCODSI","BA3_XTPSER","BA3_MATEMP","BA3_XMATBE","NOUSER"}
Local nX			:= 0


Local lOnlyVisual	:= Alltrim(M->UC_STATUS) == "3"
Local cAspas := CHR(34)

// Leandro Massafera - 25/07/2013
// Variavel para tratar o Tipo de Pagamento
Private _cTipPag := BA3->BA3_TIPPAG

Private lPrim260 	:= .F.
Private	aVetor	    := {}
Private	aVetorAlt   := {}
Private oGetTmkPls	:= Nil
Private	oLblUsr,oLblCon,oLblInf
Private cCampBA1	:= ""
Private cCampFld1	:= ""
Private aCampBA1	:= {}
Private aEditBA1	:= {}
Private	oNrEnder 	, cNrEnder	:= CriaVar("BA3_NUMERO")
Private aBA3Ori		:= {}

Private oEncSA1
Private aGets[0]
Private aGetsBA1[0]
Private aGetsBA3[0]
Private aGetsSA1[0]
Private aTela[0][0]
Private aTelaBA1[0][0]
Private aTelaBA3[0][0]
Private aTelaSA1[0][0]
Private lBackOffice	:= IsInCallStack("U_ALCA010")



AjustaSX3()
AjustaSXB()

//ALTERACAO EM 19/09/2014 - RAFAEL DE PAULA
//RETIRADO DO PREENCHIMENTO DO ARRAY aCampBA1 os campos BA1_MATANT, BA1_TIPUSU, BA1_GRAUPA. Justificativa no versionamento 2.0 

if lvePop
	cCampBA1 := "BA1_NOMUSR,BA1_DATNAS,BA1_SEXO,BA1_ESTCIV,BA1_MAE,BA1_DRGUSR,BA1_ORGEM,BA1_EXPED,BA1_RGEST,BA1_CPFUSR,BA1_EMAIL,BA1_CEPUSR,BA1_ENDERE,BA1_NR_END,BA1_COMEND,BA1_BAIRRO,BA1_MUNICI,BA1_ESTADO,BA1_DDD,BA1_TELEFO,BA1_DDDCL,BA1_FONECL,BA1_DDDCM,BA1_FONECM,BA1_PISPAS,BA1_DENAVI,BA1_NRCRNA,BA1_NATID,BA1_TPEND,BA1_XRAMAL,BA1_XOCUPA,BA1_MATANT,BA1_TIPUSU, BA1_GRAUPA,BA1_ATUCRX"
Else
	cCampBA1 := "BA1_NOMUSR,BA1_DATNAS,BA1_SEXO,BA1_ESTCIV,BA1_MAE,BA1_DRGUSR,BA1_ORGEM,BA1_EXPED,BA1_RGEST,BA1_CPFUSR,BA1_EMAIL,BA1_CEPUSR,BA1_ENDERE,BA1_NR_END,BA1_COMEND,BA1_BAIRRO,BA1_MUNICI,BA1_ESTADO,BA1_DDD,BA1_TELEFO,BA1_DDDCL,BA1_FONECL,BA1_DDDCM,BA1_FONECM,BA1_PISPAS,BA1_DENAVI,BA1_NRCRNA,BA1_NATID,BA1_TPEND,BA1_XRAMAL,BA1_XOCUPA,BA1_MATANT,BA1_TIPUSU, BA1_GRAUPA"
endif

cCampFld1 := StrTran(cCampBA1,",",'","')
aCampBA1 := &('{"'+cCampFld1+'"}')  // 16



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Campos editaveis  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

For nX:=1 to Len(aCampBA1)
//!lBackOffice .AND. !Alltrim(aCampBA1[nX]) $ //alterado ANTONIO TOTVS
   	
	if lvePop
		If !Alltrim(aCampBA1[nX]) $ "BA1_CPFUSR/BA1_ESTCIV/BA1_EMAIL/BA1_CEPUSR/BA1_NR_END/BA1_COMEND/BA1_DDD/BA1_TELEFO/BA1_DDDCL/BA1_FONECL/BA1_DDDCM/BA1_FONECM/BA1_PISPAS/BA1_DENAVI/BA1_NRCRNA/BA1_TPEND/BA1_XRAMAL/BA1_XOCUPA/BA1_ENDERE/BA1_BAIRRO/BA1_ATUCRX/"
			Loop                                                                                                                                                                                                                     //Acrescentados estes ultimos campos para serem editáveis me
		EndIf  
	else 
		If !Alltrim(aCampBA1[nX]) $ "BA1_CPFUSR/BA1_ESTCIV/BA1_EMAIL/BA1_CEPUSR/BA1_NR_END/BA1_COMEND/BA1_DDD/BA1_TELEFO/BA1_DDDCL/BA1_FONECL/BA1_DDDCM/BA1_FONECM/BA1_PISPAS/BA1_DENAVI/BA1_NRCRNA/BA1_TPEND/BA1_XRAMAL/BA1_XOCUPA/BA1_ENDERE/BA1_BAIRRO/"
			Loop                                                                                                                                                                                                                     //Acrescentados estes ultimos campos para serem editáveis me
		EndIf  
	endif
                                                                                                                                                                                                                      //validacoes no fonte ALCXFUN e no MODO EDICAO do configurador   - RAFAEL DE PAULA 23-01-2013
	
	AAdd(aEditBA1, aCampBA1[nX] )
Next nX
AAdd(aCampBA1, "NOUSER")

For nX:=1 to Len(aCpoSA1)
//!lBackOffice .AND. !Alltrim(aCpoSA1[nX]) $ //alterado ANTONIO TOTVS
	If !Alltrim(aCpoSA1[nX]) $ "A1_BLEMAIL" //"A1_EMAIL/A1_CEP/A1_END/A1_BAIRRO/A1_END/A1_DDD/A1_TEL/A1_FAX/A1_BLEMAIL"
		Loop
	EndIf
	AAdd( aEditSA1, aCpoSA1[nX] )
Next nX



AaDD(aRotina,{ "" , "" , 0 , 4    , 0, Nil})
AaDD(aRotina,{ "" , "" , 0 , 5    , 0, Nil})
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Carrega as variaveis chave³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nFolder == 1 // TeleMarketing, Televendas ou Telecobranca
	If 	lSelEntF3
		BA1->(dbSetOrder(2))
	Else
		BA1->(dbSetOrder(1))
	EndIf
	BA3->(dbSetOrder(1))

	If BA1->( MsSeek( xFilial( "BA1" ) + M->UC_CHAVE ) ) .And.;
	   BA3->( MsSeek( xFilial("BA3") + BA1->(BA1_CODINT + BA1_CODEMP + BA1_MATRIC + BA1_CONEMP + BA1_VERCON + BA1_SUBCON + BA1_VERSUB ) ) )

		aCliente := PLSAVERNIV(BA1->BA1_CODINT,BA1->BA1_CODEMP,BA1->BA1_MATRIC,IF(BA3->BA3_TIPOUS=="1","F","J"),;
					BA1->BA1_CONEMP,BA1->BA1_VERCON,BA1->BA1_SUBCON,BA1->BA1_VERSUB,Val(BA1->BA1_COBNIV),BA1->BA1_TIPREG,.F.)

		If aCliente[1,1] <> "ZZZZZZ"
			cCodCli		:= aCliente[1][1]//BA1->BA1_CODCLI
			cLojCli		:= aCliente[1][2]//BA1->BA1_LOJA
			cCodOpe 	:= BA1->BA1_CODINT
			cCodEmp 	:= BA1->BA1_CODEMP
			cMatricUsr 	:= BA1->BA1_MATRIC
			cMatricBA1  := BA1->(BA1_CODINT+BA1_CODEMP+BA1_MATRIC+BA1_TIPREG+BA1_DIGITO)
			cTipReg	    := BA1->BA1_TIPREG
			cContrato   := BA1->BA1_CONEMP
			cVerCon		:= BA1->BA1_VERCON
			cSubCon		:= BA1->BA1_SUBCON
			cVerSub		:= BA1->BA1_VERSUB
		Else
			MsgAlert("NÃ£o Encontrado Cliente nos nÃ­veis de CobranÃ§a.","AtenÃ§Ã£o")
			RestArea(aArea)
			aGets := aClone(aBKGets)
			aTela := aClone(aBKTela)
			Return(.F.)
		EndIf
	Else
		MsgAlert("UsuÃ¡rio ou Familia nao encontrado","AtenÃ§Ã£o")
		RestArea(aArea)
		aGets := aClone(aBKGets)
		aTela := aClone(aBKTela)
		Return(.F.)

	Endif

Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Chave do PLS³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ
cMatric	:= cCodOpe+cCodEmp+cContrato+cVerCon+cSubCon+cVerSub+cMatricUsr

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica o tipo de Contrato³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lEmpresa := (AllTrim(Posicione("BG9",1,xFilial("BG9")+cCodOpe+cCodEmp+"2","BG9->BG9_TIPO"))=="2")

cTitulo 	:= cTitulo + " - " + cCodOpe + " " + cCodEmp + " " + cMatricUsr

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Carrega as variaveis com informacoes da cobranca³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DBSelectArea("SA1")
SA1->(DBSetOrder(1))
If	SA1->(DBSeek(xFilial("SA1")+cCodCli+cLojCli))

	cBanco 		:= SA1->A1_BCO1
	cA1Email	:= SA1->A1_EMAIL

Else
	MsgAlert("Cliente nÃ£o encontrado.","AtenÃ§Ã£o") //###
	RestArea(aArea)
	aGets := aClone(aBKGets)
	aTela := aClone(aBKTela)
	Return(.F.)
EndIf

RegToMemory( "SA1", .F., .F. )


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Envia para processamento dos Gets³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

aSize:= MsAdvSize( .T.) //, .F., 400)
aInfo:= { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 2 , 2 }
aObjects:= {}
AAdd( aObjects, { 100, 100, .T., .T. } )
AAdd( aObjects, { 100, 100, .T., .T. } )
AAdd( aObjects, { 100, 100, .T., .T. } )

aPosObj:= MsObjSize( aInfo, aObjects)

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

//DEFINE MSDIALOG oDlgPls TITLE cTitulo STYLE DS_SYSMODAL   FROM 000,000 to aSize[6],aSize[5] OF oMainWnd PIXEL //  COLOR CLR_BLACK , CLR_LIGHTGRAY // CLR_HRED
DEFINE MSDIALOG oDlgPls TITLE cTitulo STYLE nOr(WS_VISIBLE, WS_POPUP, WM_CLOSE )  FROM 000,000 to aSize[6],aSize[5] OF oMainWnd PIXEL 


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Blocos de codigo para a EnchoiceBar³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

bOk 		:= {|| CA030FreshMe("BA1",0,.F.,.T.,lvePop),IIf( CA030Obrigatorio(cMatric,lvePop),( nOpcA:=1, oDlgPls:End() ) , ) }


	bOkExclui 	:= {|| nOpcA:=1, oDlgPls:End() }

if !lvePop
	bCancel 	:= {|| nOpcA:=0, oDlgPls:End() }
else
	bCancel 	:= {|| nOpcA:=0, MsgAlert(" � necess�rio confirmar os dados do cliente e marcar o campo "+ cAspas + "Atualizado"+ cAspas +" e confirmar para continuar.")}
endif


//DEFINE BUTTONBAR oBar SIZE 25,25 3D TOP OF oDlgPls

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta botoes ³
// Leandro Massafera - Atender o Novo Layout do Protheus 11
// Foi comentado os oBtn e Criado o aButtons
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
AAdd(aButtons,{"BUDGET"	,{|| nRecBa1:=BA1->(Recno()), PLSVLRCOB(,,.T.), BA1->(DbGoTo(nRecBa1))}, "Cobranca", "Cobranca"})

//oBtn := TBtnBmp():NewBar( "BMPGROUP","BMPGROUP",,,"Familia", bVisFam,.T.,oBar,,,"Consulta Familia")
//oBtn:cTitle := "Familia"

/*oBtn := TBtnBmp():NewBar( "BUDGET","BUDGET",,,"CobranÃ§a", bBotCob,.T.,oBar,,,"CobranÃ§a")
oBtn:cTitle := "CobranÃ§a"

oBtn := TBtnBmp():NewBar( "OK","OK",,,"Ok", bOk,.T.,oBar,,,"Ok" )//OK
oBtn:cTitle := "Ok"

oBtn := TBtnBmp():NewBar( "CANCEL","CANCEL",,,"Sair" , bCancel,.T.,oBar,,,"Sair" )//SAIR //###
oBtn:cTitle := "Sair"*/

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta Dados do Titular e Depedentes... ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

CA030TREE( cMatric , oDlgPls , aPosObj, cMatricBA1, aVetor)

If 	Len(aVetor)== 0
	Aviso("atencao","nao foi encontrado as vidas dessa familia.",{"Voltar"},2) //"AtenÃ§Ã£o"######
	RestArea(aArea)
	aGets := aClone(aBKGets)
	aTela := aClone(aBKTela)
	Return()
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Apos posicionar no BA1, preencho as variaveis de momoria.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RegToMemory( "BQC", .F., .F.,.F.)
RegToMemory( "BA1", .F., .F.,.F.)
M->BA1_ATUCRX := .F.

BA3->(DbSetOrder(1))
BA3->(MsSeek(xFilial("BA3")+BA1->(BA1_CODINT+BA1_CODEMP+BA1_MATRIC+BA1_CONEMP+BA1_VERCON+BA1_SUBCON+BA1_VERSUB)))

RegToMemory( "BA3", .F., .F. )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Guarda conteudos originais para comparacoes³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

For nX:=1 to Len(aCpoBA3)
	If aCpoBA3[nX] <> "NOUSER"
		AAdd(aBA3Ori, {aCpoBA3[nX] , &("M->"+aCpoBA3[nX]) })
	EndIf
Next nX


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Dados Cadastrais. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

oFolder := TFolder():New(aPosObj[2,1],aPosObj[2,2],{"Dados &Usuario","Dados de &Cobranca","Dados do cliente"},{"",""},oDlgPls,,,,.T.,.F.,(aPosObj[2,4]-aPosObj[2,2]),aPosObj[2,3]) //###antonio

oEncFld1 := MSMGet():New("BA1",,4,,,,aCampBA1,{1,aPosObj[2,2],(aPosObj[2,3]-105),(aPosObj[2,4]-5)},aEditBA1,,,,,oFolder:aDialogs[01],,,.F.,,.F.,.T.)
oEncFld1:oBox:align := CONTROL_ALIGN_ALLCLIENT
If lOnlyVisual
	oEncFld1:Disable()
EndIf

aGetsBA1 := aclone(oEncFld1:aGets)
aTelaBA1 := aclone(oEncFld1:aTela)
aGets := {}
aTela := {}

CA030FreshMe("BA1")

// ALTERADO SCASE EM 16/03/12

//BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Dados do cliente³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//oEncSA1 := MSMGet():New("SA1",,4,,,,aCpoSA1,{1,1,100,100},aEditSA1,,,,,oFolder:aDialogs[02],,,.F.,,.F.,.T.)
oEncSA1 := MSMGet():New("SA1",,4,,,,aCpoSA1,{1,aPosObj[2,2],(aPosObj[2,3]-105),(aPosObj[2,4]-5)},aEditSA1,,,,,oFolder:aDialogs[03],,,.F.,,.F.,.T.)
oEncSA1:oBox:align := CONTROL_ALIGN_ALLCLIENT
If lOnlyVisual
	oEncSA1:Disable()
EndIf

aGetsSA1 := aclone(oEncSA1:aGets)
aTelaSA1 := aclone(oEncSA1:aTela)
aGets := {}
aTela := {}


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Dados de Cobranca.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//oEncBA3 := MSMGet():New("BA3",,4,,,,aCpoBA3,{1,1,100,100},aEditBA3,,,,,oFolder:aDialogs[02],,,.F.,,.F.,.T.)
oEncBA3 := MSMGet():New("BA3",,4,,,,aCpoBA3,{1,aPosObj[2,2],(aPosObj[2,3]-105),(aPosObj[2,4]-5)},aEditBA3,,,,,oFolder:aDialogs[02],,,.F.,,.F.,.T.)
oEncBA3:oBox:align := CONTROL_ALIGN_ALLCLIENT
If lOnlyVisual
	oEncBA3:Disable()
EndIf

aGetsBA3 := aclone(oEncBA3:aGets)
aTelaBA3 := aclone(oEncBA3:aTela)
aGets := {}
aTela := {}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Observacao das ocorrencias.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

nOpc := IIf(lOnlyVisual,2,4)
//ANTONIO
//oGetTmkPls := MSGetDados():New(aPosObj[3,1],aPosObj[3,2],aPosObj[3,3],aPosObj[3,4],nOpc,"AllwaysTrue","AllwaysTrue","",.T.,,,,,,,,,oDlgPls)

//ACTIVATE MSDIALOG oDlgPls
// Leandro Massafera - Atender o Novo Layout do Protheus 11
	ACTIVATE MSDIALOG oDlgPls ON INIT Eval({ || EnchoiceBar(oDlgPls,bOK,bCancel,.F.,aButtons)})

If ( nOpcA == 1 ) .And. nOpc > 2
	


	lRet := CA030Grava( cCodCli ,;
					cLojCli ,;
					cMatric ,;
					lEmpresa ,;
					cCodOpe ,;
					cCodEmp ,;
					cMatricUsr ,;
					cContrato ,;
					cVerCon ,;
					cSubCon ,;
					cVerSub,;
					cNivCob,;
					cTipReg,;
					aCliente,;
					aCpoBA3, aCpoSA1,lvePop )

// Else

// MsgAlert("Pendencias na atualizaÃ§Ã£o do banco portador! AlteraÃ§Ãµes bancÃ¡rias NÃƒO EFETUADAS.")
 //lRet 	:= .F.
 //Endif
Else


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Caso a tela seja cancelada.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	lRet 	:= .F.

	If nOpca = 0
		aCols 	:= aSlvAcols
	EndIf

EndIf




RestArea(aArea)
aGets := aClone(aBKGets)
aTela := aClone(aBKTela)


Return(lRet)

/*
����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Funcao    �CA030TREE  � Autor �Fab. Software S-Case� Data � 16.11.2011 ���
�������������������������������������������������������������������������Ĵ��
���Descricao �Monta o DBTree.                                             ���
���          �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                               ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

Static Function CA030TREE( cMatric , oDlgPls , aPosObj, cMatricBA1, aVetor )
Local aArea		:= GetArea()
Local aDbTree	:= {}
Local aDbTree2	:= {}
Local aCmpBA1	:= {}
Local aUsuario	:= {}
Local nX		:= 0
Local nY		:= 0
Local nPos		:= 0
Local cQryTRB	:= "" 
Local cArqTRB	:= ""
Local cQryTRB2 	:= ""
Local cArqTRB2 	:= ""
LOCAL cCodPla   := BA3->BA3_CODPLA
LOCAL cVersao   := BA3->BA3_VERSAO
LOCAL cCodPlaBA1:= BA1->BA1_CODPLA
LOCAL cVersaoBA1:= BA1->BA1_VERSAO
Local cChave	:= ""
Local cTipVenc	:= ""
Local cDiaVenc	:= ""
Local cVip		:= ""
Local cCamp		 := ""
Local cUsTit	 :=  SuperGetMV("MV_PLCDTIT")
Local cAliasPesq
Local oTreeCon, oTreeUsr

//================================================================================================================
//Monta o DBTree do Cliente
//================================================================================================================
aDbTree	:= {}
aDbTree2:= {}
//========================================================
//Tabela Operadora
//========================================================
cVip := Alltrim(BA3->BA3_XVIPLI)
DbSelectArea("BG9")
BG9->(DbSetOrder(1))
If BG9->(DbSeek(xFilial("BG9")+BA3->(BA3_CODINT+BA3_CODEMP)))
	//Descricao, Chave e Imagem
	cChave	:= "BG9/"+StrZero(BG9->(Recno()),6)+"/Operadora"
	aAdd(aDbTree,{PADR("Operadora - " + Alltrim(BG9->BG9_CODIGO) + " - " + Alltrim(BG9->BG9_NREDUZ),300),cChave,"EDITABLE"})
EndIf
//========================================================
//Tabela Grupo Empresa
//========================================================
DbSelectArea("BR0")
BR0->(DbSetOrder(1))
If BR0->(DbSeek(xFilial("BR0")+ALLTRIM(BA3->BA3_GRPCOB)))
	cChave	:= "BR0/"+StrZero(BR0->(Recno()),6)+"/Contrato"
	cTipVenc	:= Alltrim("Tipo Venc. -  "+RetX3Combo( "BR0_TIPVNC", BR0->BR0_TIPVNC ))
	cDiaVenc	:= Alltrim("Dias Venc. -  "+BR0->BR0_DIASVE)
		
	aAdd(aDbTree,{PADR("Contrato - " + Alltrim(BR0->BR0_CODIGO) + " - " + Alltrim(BR0->BR0_NCOMPL),300),cChave,"EDITABLE"})
	If !Empty(cTipVenc)
		aAdd(aDbTree2,{cChave,cTipVenc,cChave+"/01","EDITABLE"})
	Endif
	If !Empty(cDiaVenc)
		aAdd(aDbTree2,{cChave,cDiaVenc,cChave+"/02","EDITABLE"})
	Endif
	
EndIf
//========================================================
//Contrato e SubContrato
//========================================================
DbSelectArea("BT5")
BT5->(DBSetOrder(1)) // BT5_FILIAL + BT5_CODINT + BT5_CODIGO + BT5_NUMCON + BT5_VERSAO
If BT5->(MsSeek(xFilial("BT5")+BA3->(BA3_CODINT + BA3_CODEMP + BA3_CONEMP + BA3_VERCON)))
	DBSelectArea("BQC")
	BQC->(DbSetOrder(1)) // BQC_FILIAL + BQC_CODIGO + BQC_NUMCON + BQC_VERCON + BQC_SUBCON + BQC_VERSUB
	If BQC->(MsSeek(xFilial("BQC")+BA3->(BA3_CODINT + BA3_CODEMP + BA3_CONEMP + BA3_VERCON + BA3_SUBCON + BA3_VERSUB)))
		cChave:= "BQC/"+StrZero(BQC->(Recno()),6)+"/SubContr."
		If Alltrim(BQC->BQC_XVIPLI) $ "VL"
			cVip:= Alltrim(BQC->BQC_XVIPLI)
		Endif	
		aAdd(aDbTree,{PADR("Sub-Contrato - "+AllTrim(BQC->BQC_NUMCON)+" - "+AllTrim(BQC->BQC_NREDUZ)+" - "+Alltrim(BQC->BQC_DESCRI),300),cChave,"EDITABLE"})
	EndIf
EndIf
//========================================================
//Tabela Produto
//========================================================
DbSelectArea("BI3")
BI3->(DbSetOrder(1))
If BI3->(MsSeek(xFilial("BI3")+BA3->BA3_CODINT+cCodPla+cVersao))
	cChave	:= "BI3/"+StrZero(BI3->(Recno()),6)+"/Produto"
	aAdd(aDbTree,{"Produto da Familia - "+cCodPla+" Versao - "+cVersao+" - " + Alltrim(BI3->BI3_DESCRI),cChave,"PLNPROP"})
	aAdd(aDbTree2,{cChave,"Acomodacao - "+Posicione("BI4",1,xFilial("BI4")+BI3->BI3_CODACO,"BI4->BI4_DESCRI"),cChave+"/01","PLNPROP"}) 
   	aAdd(aDbTree2,{cChave,"Segmentacao - "+Posicione("BI6",1,xFilial("BI6")+BI3->BI3_CODSEG,"BI6->BI6_DESCRI"),cChave+"/02","PLNPROP"})
   	aAdd(aDbTree2,{cChave,"Abrangencia - "+Posicione("BF7",1,xFilial("BF7")+BI3->BI3_ABRANG,"BF7->BF7_DESORI"),cChave+"/03","PLNPROP"})
Endif

@aPosObj[1,1],aPosObj[1,2] TO aPosObj[1,3] , ((aPosObj[1,4])/2) LABEL "Informacoes Clientes" COLOR CLR_HBLUE  OF oDlgPls PIXEL // LABEL "Legenda"  //
If Len(aDbTree) > 0 
	oTreeCon := DBTree():New ( (@aPosObj[1,1]+7),(aPosObj[1,2]+2) ,(aPosObj[1,3]-2),(((aPosObj[1,4])/2)-2) ,oDlgPls, /*bChange*/,/*bRClick*/, .T., /*lDisable*/,/*oFont*/,/*cHeaders*/ )
	oTreeCon:blDblClick:= {|| M100Edit(oTreeCon:GetCargo())}
	For nX:= 1 To Len(aDbTree)
		oTreeCon:BeginUpdate()
		oTreeCon:AddTree(aDbTree[nX][1],.F.,aDbTree[nX][3],aDbTree[nX][3],,,aDbTree[nX][2] ) 
		//oTreeCon:AddItem(aDbTree[nX][1],aDbTree[nX][2],aDbTree[nX][3],,,,,1)//Descricao/Chave/Imagem
		nPos := aScan(aDbTree2,{ |x| Alltrim(x[1]) == Alltrim(aDbTree[nX][2]) })
		If nPos > 0 
			For nY:= nPos To Len(aDbTree2)
				If Alltrim(aDbTree2[nY][1]) == Alltrim(aDbTree[nX][2])
					If oTreeCon:TreeSeek(aDbTree2[nY][1]) 
						oTreeCon:AddItem(aDbTree2[nY][2],aDbTree2[nY][3],aDbTree2[nY][4],,,,,2)
					Endif	
				Else
					Exit
				Endif	
				//Endif	
			Next
		Endif
		oTreeCon:EndTree()
		oTreeCon:EndUpdate()
	Next
	oTreeCon:EndTree()
	oTreeCon:TreeSeek(aDbTree[1][2])
Endif	
//================================================================================================================
//Monta o DBTree do Usuario
//================================================================================================================
aDbTree		:= {}
aDbTree2	:= {}
aCmpBA1		:= Separa(cCampBA1,',')//Variavel Private cCampBA1

cQryTRB		:= " SELECT " + CRLF
cQryTRB		+= " 	CLIENTE.*,COALESCE(BLOQUEIO.DESBLO,'') AS DESCBLO " + CRLF
cQryTRB		+= " FROM " + CRLF
cQryTRB		+= " ( " + CRLF
cQryTRB		+= " 	SELECT " + CRLF
cQryTRB		+= " 		DISTINCT " + CRLF
If Len(aCmpBA1) > 0
	For nX:= 1 To Len(aCmpBA1)
		cQryTRB		+="			USUARIO."+Alltrim(aCmpBA1[nX]) + ", "  	
	Next
Endif
cQryTRB		+= " 		USUARIO.BA1_CODINT AS [CODINT], USUARIO.BA1_CODEMP AS [CODEMP], USUARIO.BA1_MATRIC AS [MATRIC], " + CRLF
cQryTRB		+= " 		USUARIO.BA1_CODPLA AS [CODPLA], USUARIO.BA1_VERSAO AS [VERPLA], USUARIO.BA1_TIPREG AS [TIPREG]," + CRLF
cQryTRB		+= " 		USUARIO.BA1_TIPUSU AS [TIPUSU], USUARIO.BA1_NOMUSR AS [NOMUSU], USUARIO.BA1_DATNAS AS [DATNAS]," + CRLF
cQryTRB		+= " 		USUARIO.BA1_DATINC AS [DATINC], USUARIO.BA1_DTASSI AS [DATASS],USUARIO.BA1_DTREC AS [DATREC]," + CRLF
cQryTRB		+= " 		USUARIO.BA1_CARENC AS [CARENC]," + CRLF
cQryTRB		+= " 		CASE WHEN COALESCE(FAMILIA.BA3_DATBLO,'') = '' THEN COALESCE(USUARIO.BA1_DATBLO,'') ELSE COALESCE(FAMILIA.BA3_DATBLO,'') END AS [DATBLO]," + CRLF
cQryTRB		+= " 		CASE " + CRLF
cQryTRB		+= " 			WHEN COALESCE(FAMILIA.BA3_DATBLO,'') <> '' THEN COALESCE(CTRLFAM.BC3_NIVBLQ,'') " + CRLF
cQryTRB		+= " 			WHEN COALESCE(FAMILIA.BA3_DATBLO,'') <> '' THEN COALESCE(CTRLFAM.BC3_NIVBLQ,'') " + CRLF
cQryTRB		+= " 			WHEN COALESCE(FAMILIA.BA3_DATBLO,'') <> '' THEN COALESCE(CTRLFAM.BC3_NIVBLQ,'') " + CRLF
cQryTRB		+= " 			WHEN COALESCE(USUARIO.BA1_DATBLO,'') <> '' THEN COALESCE(LIBUSU.BCA_NIVBLQ,'') " + CRLF
cQryTRB		+= " 			WHEN COALESCE(USUARIO.BA1_DATBLO,'') <> '' THEN COALESCE(LIBUSU.BCA_NIVBLQ,'') " + CRLF
cQryTRB		+= " 			WHEN COALESCE(USUARIO.BA1_DATBLO,'') <> '' THEN COALESCE(LIBUSU.BCA_NIVBLQ,'') " + CRLF
cQryTRB		+= " 			ELSE '' " + CRLF
cQryTRB		+= " 		END AS [NIVBLQ], " + CRLF
cQryTRB		+= " 		CASE WHEN COALESCE(FAMILIA.BA3_DATBLO,'') <> '' THEN BA3_DATBLO ELSE BA1_DATBLO END AS [DTBLQ], " + CRLF 
cQryTRB		+= " 		CASE WHEN COALESCE(FAMILIA.BA3_DATBLO,'') <> '' THEN BA3_MOTBLO ELSE BA1_MOTBLO END AS [MOTBLQ], " + CRLF
cQryTRB		+= " 		USUARIO.R_E_C_N_O_ AS [RECNO] " + CRLF
cQryTRB		+= " 	FROM " + RetSqlName("BA1") +" (NOLOCK) USUARIO " + CRLF
cQryTRB		+= " 	INNER JOIN " + RetSqlName("BA3") +" (NOLOCK) FAMILIA ON " + CRLF 
cQryTRB		+= " 		FAMILIA.BA3_FILIAL = '" + xFilial("BA3") + "' " + CRLF   
cQryTRB		+= " 		AND FAMILIA.BA3_CODINT = USUARIO.BA1_CODINT " + CRLF
cQryTRB		+= " 		AND FAMILIA.BA3_CODEMP = USUARIO.BA1_CODEMP " + CRLF
cQryTRB		+= " 		AND FAMILIA.BA3_CONEMP = USUARIO.BA1_CONEMP " + CRLF	   
cQryTRB		+= " 		AND FAMILIA.BA3_VERCON = USUARIO.BA1_VERCON " + CRLF
cQryTRB		+= " 		AND FAMILIA.BA3_SUBCON = USUARIO.BA1_SUBCON " + CRLF
cQryTRB		+= " 		AND FAMILIA.BA3_VERSUB = USUARIO.BA1_VERSUB " + CRLF
cQryTRB		+= " 		AND FAMILIA.BA3_MATRIC = USUARIO.BA1_MATRIC " + CRLF
cQryTRB		+= " 		AND FAMILIA.D_E_L_E_T_ = '' " + CRLF  
cQryTRB		+= " 	LEFT JOIN " + RetSqlName("BC3") +" (NOLOCK) CTRLFAM ON " + CRLF
cQryTRB		+= " 		CTRLFAM.BC3_FILIAL = USUARIO.BA1_FILIAL " + CRLF
cQryTRB		+= " 		AND CTRLFAM.BC3_MATRIC = USUARIO.BA1_CODINT+USUARIO.BA1_CODEMP+USUARIO.BA1_MATRIC " + CRLF
cQryTRB		+= " 		AND CTRLFAM.BC3_DATA = FAMILIA.BA3_DATBLO " + CRLF
cQryTRB		+= " 		AND CTRLFAM.BC3_TIPO = '0'  " + CRLF
cQryTRB		+= " 		AND CTRLFAM.D_E_L_E_T_='' " + CRLF
cQryTRB		+= " 	LEFT JOIN " + RetSqlName("BCA") +" (NOLOCK) LIBUSU ON  " + CRLF
cQryTRB		+= " 		LIBUSU.BCA_FILIAL = USUARIO.BA1_FILIAL " + CRLF
cQryTRB		+= " 		AND LIBUSU.BCA_MATRIC = USUARIO.BA1_CODINT+USUARIO.BA1_CODEMP+USUARIO.BA1_MATRIC " + CRLF
cQryTRB		+= " 		AND LIBUSU.BCA_DATA = USUARIO.BA1_DATBLO " + CRLF
cQryTRB		+= " 		AND LIBUSU.BCA_TIPO = '0' " + CRLF 
cQryTRB		+= " 		AND LIBUSU.D_E_L_E_T_='' " + CRLF
cQryTRB		+= " 	WHERE  " + CRLF
cQryTRB		+= " 		USUARIO.BA1_FILIAL = '" + xFilial("BA1") + "' " + CRLF
cQryTRB		+= " 		AND USUARIO.BA1_CODINT + USUARIO.BA1_CODEMP + USUARIO.BA1_CONEMP + USUARIO.BA1_VERCON + USUARIO.BA1_SUBCON + USUARIO.BA1_VERSUB + USUARIO.BA1_MATRIC = '" + cMatric + "' " + CRLF
cQryTRB		+= " ) CLIENTE " + CRLF
cQryTRB		+= " LEFT JOIN ( " + CRLF
cQryTRB		+= " 		SELECT  " + CRLF
cQryTRB		+= " 			'S' AS [NIVEL],BQU_CODBLO AS [CODBLO], BQU_DESBLO AS [DESBLO] " + CRLF
cQryTRB		+= " 		FROM " + RetSqlName("BQU") +" (NOLOCK) BQUSUB " + CRLF
cQryTRB		+= " 		WHERE " + CRLF
cQryTRB		+= " 			BQUSUB.BQU_FILIAL = '" + xFilial("BQU") + "' " + CRLF
cQryTRB		+= " 			AND BQUSUB.D_E_L_E_T_='' " + CRLF
cQryTRB		+= " 		UNION " + CRLF
cQryTRB		+= " 		SELECT " + CRLF 
cQryTRB		+= " 			'F' AS [NIVEL],BG1_CODBLO AS [CODBLO], BG1_DESBLO AS [DESBLO] " + CRLF
cQryTRB		+= " 		FROM " + RetSqlName("BG1") +" (NOLOCK) BG1FAM " + CRLF
cQryTRB		+= " 		WHERE " + CRLF
cQryTRB		+= " 			BG1FAM.BG1_FILIAL = '" + xFilial("BG1") + "' " + CRLF
cQryTRB		+= " 			AND BG1FAM.D_E_L_E_T_='' " + CRLF
cQryTRB		+= " 		UNION " + CRLF
cQryTRB		+= " 		SELECT " + CRLF 
cQryTRB		+= " 			'U' AS [NIVEL],BG3_CODBLO AS [CODBLO], BG3_DESBLO AS [DESBLO] " + CRLF
cQryTRB		+= " 		FROM " + RetSqlName("BG3") +" (NOLOCK) BLQUSU " + CRLF
cQryTRB		+= " 		WHERE " + CRLF
cQryTRB		+= " 			BLQUSU.BG3_FILIAL = '" + xFilial("BG3") + "' " + CRLF
cQryTRB		+= " 			AND BLQUSU.D_E_L_E_T_='') BLOQUEIO ON " + CRLF 
cQryTRB		+= " 			BLOQUEIO.NIVEL = CLIENTE.NIVBLQ " + CRLF
cQryTRB		+= " 			AND BLOQUEIO.CODBLO = CLIENTE.MOTBLQ " + CRLF

cArqTRB:=GetNextAlias()
DbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryTRB),cArqTRB,.F.,.T.)

	
DbSelectArea(cArqTRB)
(cArqTRB)->(DbGoTop())
If (cArqTRB)->(!Eof())
	Do While (cArqTRB)->(!Eof())
		cChave:= "BA1/" + StrZero((cArqTRB)->RECNO,10) + "/Usuario"
		
		aAdd(aDbTree, {PADR( AllTrim((cArqTRB)->TIPUSU) + " - " + Capital(AllTrim((cArqTRB)->NOMUSU)) + "(" + AllTrim(Str(DateDiffYear( Date(),DtoC(StoD((cArqTRB)->DATNAS)))))  + ")",300),cChave,IIf((cArqTRB)->TIPUSU=="D","DEPENDENTES","GROUP")})
		aAdd(aDbTree2,{cChave, PADR("Data Bloqueio:" + DtoC(StoD((cArqTRB)->DATBLO)) + "  Motivo: " + AllTrim((cArqTRB)->MOTBLQ) + " "+Capital( AllTrim((cArqTRB)->DESCBLO)),300),cChave+"/01","BMPEMERG"})
		aAdd(aDbTree2,{cChave, PADR("Data Vigencia:" + DtoC(StoD((cArqTRB)->DATINC)) + " Data de Assinatura: " +  DtoC(StoD((cArqTRB)->DATASS)) ,300),cChave,"NOTE"})
		aAdd(aDbTree2,{cChave, PADR("Data Recebimento:" + DtoC(StoD((cArqTRB)->DATREC)) ,300),cChave+"/02","NOTE"})
		aAdd(aDbTree2,{cChave, PADR("Tipo Carencia:  "+RetX3Combo( "BA1_CARENC", (cArqTRB)->CARENC ) ,300),cChave+"/03","NOTE"})
		If !Empty((cArqTRB)->CODPLA)
			aAdd(aDbTree2,{cChave, PADR("Produto do Usu�rio - "+ Alltrim((cArqTRB)->CODPLA) +" Vers�o - " + Alltrim((cArqTRB)->VERPLA),300),cChave,"PLNPROP"})
		EndIf
		//========================================================
		//Monta opcionais do plano para o usuario
		//========================================================
        cQryTRB2 := " SELECT "
        cQryTRB2 += " 	BF4_CODPRO, BF4_VERSAO, BF4_TIPVIN, BF4_MOTBLO, BI3_DESCRI "+ CRLF
        cQryTRB2 += " FROM " + RetSqlName("BF4")+ " (NOLOCK) BF4 "+ CRLF
        cQryTRB2 += " INNER JOIN  " + RetSqlName("BI3") + " (NOLOCK)  BI3 ON "+ CRLF
        cQryTRB2 += " 	BI3_FILIAL = '" + xFilial("BI3") + "' "+ CRLF
        cQryTRB2 += " 	AND BI3_CODINT = BF4_CODINT "+ CRLF
        cQryTRB2 += " 	AND  BI3_CODIGO = BF4_CODPRO "+ CRLF
        cQryTRB2 += " 	AND  BI3_VERSAO = BF4_VERSAO "+ CRLF
		cQryTRB2 += " 	AND  BI3.D_E_L_E_T_ = '' "+ CRLF
        cQryTRB2 += " WHERE "+ CRLF
        cQryTRB2 += " 	BF4_FILIAL = '" + xFilial("BF4") + "' "+ CRLF
        cQryTRB2 += " 	AND BF4_CODINT = '" + Alltrim((cArqTRB)->CODINT) + "' "+ CRLF
        cQryTRB2 += " 	AND BF4_CODEMP = '" + Alltrim((cArqTRB)->CODEMP) + "' "+ CRLF
        cQryTRB2 += " 	AND BF4_MATRIC = '" + Alltrim((cArqTRB)->MATRIC) + "' "+ CRLF
        cQryTRB2 += " 	AND BF4_TIPREG = '" + Alltrim((cArqTRB)->TIPREG) + "' "+ CRLF
        cQryTRB2 += " 	AND BF4_CODPRO <> ''"+ CRLF
        cQryTRB2 += " 	AND BF4_VERSAO <> '' "+ CRLF
        cQryTRB2 += " 	AND BF4.D_E_L_E_T_ = '' "
        
        cArqTRB2:= GetNextAlias()
	    dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQryTRB2),cArqTRB2,.F.,.T.)
	    
		DbSelectArea(cArqTRB2)
		(cArqTRB2)->(DbGoTop())
		If (cArqTRB2)->(!Eof())
			aAdd(aDbTree2,{cChave,PADR("Opcionais",300),cChave+"OPC","PLNPROP"})
			Do While (cArqTRB2)->(!Eof())
				cOpcional:= (cArqTRB2)->BF4_CODPRO+" - "+(cArqTRB2)->BF4_VERSAO+" - "+ Alltrim((cArqTRB2)->BI3_DESCRI)
				cOpcional+= " Vinculado - "+Iif((cArqTRB2)->BF4_TIPVIN <> "1","N�o","Sim") 
	            cOpcional+= " Bloqueado - "+IIf(Empty((cArqTRB2)->BF4_MOTBLO),"N�o","Sim")
				aAdd(aDbTree2,{cChave+"OPC", PADR(Capital(cOpcional),300),cChave+"OPC/01","BMPEMERG"})
				 (cArqTRB2)->(DbSkip())
			End
		Endif
		If Select(cArqTRB2)>0
			DbSelectArea(cArqTRB2)
			(cArqTRB2)->(DbCloseArea())
		Endif
		If	SubStr(AllTrim((cArqTRB)->MOTBLQ),1,1) == "7"
			aAdd(aDbTree2,{cChave,PADR("Status: Bloqueado",300),cChave+"STS","BR_AZUL"})
		ElseIf !Empty((cArqTRB)->MOTBLQ) .AND. SubStr(AllTrim((cArqTRB)->MOTBLQ),1,1) <> "7" .AND. SubStr(AllTrim((cArqTRB)->MOTBLQ),1,1) <> "9"
			aAdd(aDbTree2,{cChave,PADR("Status: Cancelado",300),cChave+"STS","BR_VERMELHO"})
		Else
			If cVip $ "VL"
				aAdd(aDbTree2,{cChave,PADR("Status: Vip/Liminar",300),cChave+"STS","BR_PRETO"})
			Else
				aAdd(aDbTree2,{cChave,PADR("Status: Ativo",300),cChave+"STS","BR_VERDE"})
			Endif
		Endif		
   		//armazena os dados dos campos do usuario que dever�o aparecerno browse
   		aUsuario:={}  
   		If Len(aCmpBA1) > 0
	   		For nX:= 1 To Len(aCmpBA1)
	   			aAdd(aUsuario, (cArqTRB)->&(aCmpBA1[nX]))   	
	   		Next
	   		aAdd(aUsuario, Date())
	   		aAdd(aUsuario,(cArqTRB)->RECNO)
   		Endif
   		aAdd(aVetor,aUsuario)
   		aVetorAlt := aClone(aVetor)
		(cArqTRB)->(DbSkip())
	End
Endif


@aPosObj[1,1],((aPosObj[1,4])/2) TO aPosObj[1,3], aPosObj[1,4] LABEL "Usu�rio(s)"  COLOR CLR_HBLUE OF oDlgPls PIXEL // LABEL   //
If Len(aDbTree) > 0 
	oTreeUsr := DBTree():New ( (@aPosObj[1,1]+7),(((aPosObj[1,4])/2)+2),(aPosObj[1,3]-2),(aPosObj[1,4]-2) ,oDlgPls,{|| CA030Change(oTreeUsr:GetCargo())   },/*bRClick*/, .T., /*lDisable*/,/*oFont*/,/*cHeaders*/ )
	For nX:= 1 To Len(aDbTree)
		oTreeUsr:BeginUpdate()
		oTreeUsr:AddTree(aDbTree[nX][1],.F.,aDbTree[nX][3],aDbTree[nX][3],,,aDbTree[nX][2] ) 
		//oTreeCon:AddItem(aDbTree[nX][1],aDbTree[nX][2],aDbTree[nX][3],,,,,2)//Descricao/Chave/Imagem
		nPos := aScan(aDbTree2,{ |x| Alltrim(x[1]) == Alltrim(aDbTree[nX][2]) })
		If nPos > 0 
			For nY:= nPos To Len(aDbTree2)
				If Alltrim(aDbTree2[nY][1]) == Alltrim(aDbTree[nX][2])
					If oTreeUsr:TreeSeek(aDbTree2[nY][1]) 
						oTreeUsr:AddItem(aDbTree2[nY][2],aDbTree2[nY][3],aDbTree2[nY][4],,,,,2)
					Endif	
				Else
					Exit
				Endif	
			Next
		Endif
		oTreeUsr:EndTree()
		oTreeUsr:EndUpdate()
	Next
	oTreeUsr:EndTree() 
	oTreeUsr:TreeSeek(aDbTree[1][2])
Endif	
RestArea(aArea)
Return 

/*
����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Funcao    �CA030Change� Autor �Fab. Software S-Case� Data � 16.11.2011 ���
�������������������������������������������������������������������������Ĵ��
���Descricao �Atualiza informacoes referente ao usuario selecionado no    ���
���          �DBTree.                                                     ���
�������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                               ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function CA030Change(cCargo)

Local cAlias	:= ""
Local nRecno	:= 0
Local nRecOld	:= 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Testa conteudo do parametro...   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If Empty(cCargo)
   Return()
EndIf

cAlias  := Subs(cCargo,1,3)
nRecno  := Val(Subs(cCargo,5,10))
nRecOld := &(cAlias+"->(Recno())")

DBSelectArea(cAlias)
DBGoTo(nRecno)

If cAlias == "BA1"
	CA030FreshMe("BA1",nRecOld)
//	BTS->(DbSetOrder(1))
//	BTS->(DbSeek(xFilial("BTS")+BA1->BA1_MATVID))
EndIf


Return()

/*
�����������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������Ŀ��
���Funcao    �CA030FreshMe� Autor �Fab. Software S-Case� Data � 16.11.2011 ���
��������������������������������������������������������������������������Ĵ��
���Descricao �Carrega os M-> do BA1 posicionado.                           ���
���          �                                                             ���
��������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                                ���
���������������������������������������������������������������������������ٱ�
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Static Function CA030FreshMe(cAlias,nRecOld,lRfresh,lAltVet,lCrm)
Local i,nI,x,nX	:= 0
Local aStruTB	:= &(cAlias+"->(DbStruct())")
Local nPosRec	:= Len(aVetor[1])
Local lRet		:= .T.
Default	nRecOld := 0
Default	lRfresh := .T.
Default lAltVet	:= .F.
Default lCrm	:= .F.


If cAlias == "BA1"

	if !lCrm
		If lRfresh .and. !Obrigatorio(oEncFld1:aGets,oEncFld1:aTela) //.and. aCampBA1[x] <> "BA1_CPFUSR"
			lRet := .F.
		EndIf
	endif


	nI := aScan(aVetor,{ |x| x[nPosRec] = BA1->(Recno()) })
	If nRecOld > 0
		nX 		:= aScan(aVetor,{ |x| x[nPosRec] = nRecOld })
		lAltVet	:= .T.
	Else
		nX := nI
	EndIf

	If nX > 0
	    For x:=1 to Len(aCampBA1)
			If aCampBA1[x] <> "NOUSER"
				If ValType(&("M->"+aCampBA1[x])) == "L"
				 	If Alltrim(aVetor[nI,x]) == "F"
				 		aVetor[nI,x] := .F.
				 	Else
				 		aVetor[nI,x] := .T.
				 	Endif
				ElseIf	ValType(&("M->"+aCampBA1[x])) == "D" .And. ValType(aVetor[nI,x]) == "C"
					aVetor[nI,x] := StoD(aVetor[nI,x])
				ElseIf	ValType(&("M->"+aCampBA1[x])) == "N" .And. ValType(aVetor[nI,x]) == "C"  
					aVetor[nI,x] := Val(aVetor[nI,x])				 					
				Endif
				If lAltVet
					aVetor[nX,x] := &("M->"+aCampBA1[x])
				EndIf
				&("M->"+aCampBA1[x]) :=  aVetor[nI,x]
			Endif
	    Next
	Endif

	If lRfresh
		oEncFld1:Refresh()
   	EndIf

EndIf

Return(lRet)

/*
�����������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������Ŀ��
���Funcao    �CA030Grava  � Autor �Fab. Software S-Case� Data � 16.11.2011 ���
��������������������������������������������������������������������������Ĵ��
���Descricao �Atualiza informacoes referente ao usuario selecionado no     ���
���          �DBTree.                                                      ���
��������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                                ���
���������������������������������������������������������������������������ٱ�
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function CA030Grava( cCodCli , cLojCli , cMatric , lEmpresa , cCodOpe , cCodEmp , cMatricUsr , cContrato , cVerCon , cSubCon , cVerSub, cNivCob, cTipReg, aCliente, aCpoBA3, aCpoSA1, lTrc)
Local 	lRet			:= .T.
Local 	lCart			:= .F.
Local 	cCampo			:= ""
Local 	lInterCambio 	:= .F. 		// Verifica se houve alteracao de municipio.
Local 	aCpoSUD			:= {}
Local 	cLogin 			:= ""
Local 	nL				:= 0
Local 	nI				:= 0
Local	x				:= 0
Local	i				:= 0
Local	cContato		:= ""
Local 	cAlias			:= ""
Local	lAlt			:= .F.
Local	aStruSA1		:= SA1->(DbStruct())
Local	aStruBA1		:= BA1->(DbStruct())
Local	aStruBA3		:= BA3->(DbStruct())
Local	aStruBQC		:= BQC->(DbStruct())
Local	aStruBTS		:= BTS->(DbStruct())
Local	aStruSU5		:= SU5->(DbStruct())
Local   cUsTit			:= SuperGetMV("MV_PLCDTIT")
Local   nOldRecBA1      := 0
LOCAL   aRetPto         := {}
Local	lDadosCobAlt	:=.F.
Local 	aCpos			:= {}
Local 	nX				:= 0
Local 	cFuncCad		:= GetNewPar("AL_FUNCAD","000015") // Codigo de funcao de cadastro (PLS x TMK)
//Local 	cFuncCad		:= GetNewPar("AL_FUNCAD","AL0001") // Codigo de funcao de cadastro (PLS x TMK)
Local 	cNome			:= ""
Local 	cCpf			:= ""
Local 	cBA3Memo		:= ""
Local 	cSA1Memo		:= ""
Local 	cBA1Memo		:= ""
Local 	cMemoAlt		:= ""
Local	cResp			:= ""

Default lTrc 			:= .F.

/***********************************************************************************************/

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Atualiza dados de cobranca - BA3  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	aCpos := {}
	For nX:=1 to Len(aCpoBA3)
		If aCpoBA3[nX] <> "NOUSER"
			AAdd(aCpos, { aCpoBA3[nX], &("M->"+aCpoBA3[nX]) })
		EndIf

	Next nX
	U_CA030Grv("BA3",1,xFilial("BA3")+cCodOpe+cCodEmp+cMatricUsr+cContrato+cVerCon+cSubCon+cVerSub,aCpos,@cBA3Memo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Atualiza dados do cliente - SA1   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	aCpos := {}
	For nX:=1 to Len(aCpoSA1)
		If aCpoSA1[nX] <> "NOUSER"
			AAdd(aCpos, { aCpoSA1[nX], &("M->"+aCpoSA1[nX]) })
		EndIf
	Next nX
	U_CA030Grv("SA1",1,xFilial("SA1")+cCodCli+cLojCli,aCpos,@cSA1Memo)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Atualiza dados dos usuarios ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	For x:=1 To Len(aVetor)
		cNome	:= ""
		cCpf	:= "" 
		BA1->(DbGoTo(aVetor[x,Len(aVetor[x])]))
		CA030FreshMe("BA1",0,.F.,.F.,lTrc)


		aCpos := {}
		For nX:=1 to Len(aCampBA1)
			If Alltrim(aCampBA1[nX]) == "BA1_NOMUSR"
				cNome:= Alltrim(&("M->"+aCampBA1[nX]))
			Endif
			If Alltrim(aCampBA1[nX]) == "BA1_CPFUSR"
				cCpf:= Alltrim(&("M->"+aCampBA1[nX]))
			Endif
			If aCampBA1[nX] <> "NOUSER"
				AAdd(aCpos, { aCampBA1[nX], &("M->"+aCampBA1[nX]) })
			EndIf
		Next nX
		//====================================================================
		//Atualiza apenas se os dados forem do mesmo usuario
		//====================================================================
		//Obs.A posi��o dos campos do vetor est� relacionado aos campos informado na variavel 'cCampBA1', ou seja, analisar se deve alterar ou n�o  
		//a posi��o fixa do Nome e do Cpf informado abaixo caso seja acrescentado mais campos da BA1.
		If cNome == Alltrim(aVetor[x][1]) .And. cCpf == Alltrim(aVetor[x][10])  
			U_CA030Grv("BA1",2,BA1->(BA1_FILIAL+BA1_CODINT+BA1_CODEMP+BA1_MATRIC+BA1_TIPREG+BA1_DIGITO),aCpos,@cBA1Memo)
		Endif

	Next x

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Gera ocorrencia de alteraÃ§Ã£o no TMK³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If !Empty(cBA3Memo) .OR. !Empty(cSA1Memo) .OR. !Empty(cBA1Memo)

	  	cMemoAlt := Replicate("=",100) + ENTER
	   	
	  	IF lTrc
			cMemoAlt += "Em "+DtoC(dDataBase)+" as "+Time()+" o usuario "+Alltrim(cUserName)+"  CONFIRMOU os dados do cliente e efetuou as seguintes alteracoes " + ENTER
		
		ELSE
			cMemoAlt += "Em "+DtoC(dDataBase)+" as "+Time()+" o usuario "+Alltrim(cUserName)+" efetuou as seguintes alteracoes " + ENTER
		ENDIF
	  	cMemoAlt += IIf(!Empty(cBA3Memo),cBA3Memo,"")
	  	cMemoAlt += IIf(!Empty(cSA1Memo),cSA1Memo,"")
	   	cMemoAlt += IIf(!Empty(cBA1Memo),cBA1Memo,"")

	
		IF lTrc 
			cFuncCad := GetNewPar("CC_CODATE","000041") 
			U_CA030PlsTmkOco(cFuncCad,cMemoAlt)
		ELSE
			U_CA030PlsTmkOco(cFuncCad,cMemoAlt)
		ENDIF	
	
	ELSE
		IF lTrc
			cFuncCad := GetNewPar("CC_CODATX","000042") 
			cMemoAlt := Replicate("=",100) + ENTER
			cMemoAlt += "Em "+DtoC(dDataBase)+" as "+Time()+" o usuario "+Alltrim(cUserName)+"  CONFIRMOU os dados do cliente e NAO efetuou alteracoes " + ENTER
			U_CA030PlsTmkOco(cFuncCad,cMemoAlt)
		ENDIF
	EndIf

Return(lRet)

/*
�����������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������Ŀ��
���Funcao    �CA030Obrig  � Autor �Fab. Software S-Case� Data � 16.11.2011 ���
��������������������������������������������������������������������������Ĵ��
���Descricao �Verifica o preenchimento obrigatorio dos campos.             ���
���          �                                                             ���
��������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                                ���
���������������������������������������������������������������������������ٱ�
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
//27/11/2013 - Adib Dias: Retirado o fechamento do alias BA3, pois est� desfazendo o filtro DbSeek do inicio da rotina

Static Function CA030Obrigatorio(cMatric,lverif)

Local nCpo,i	:= 0
Local cMsg		:= "Existem campos obrigatÃ³rios nÃ£o preenchidos."
Local nPosMae	:= 0
Local nPosNom	:= 0
Local cTpDebCta	:= GetNewPar("AL_TPDEBCT","1") // Tipo que identifica debito em conta
Local nPTipo 	:= 0
Local nPTipo2 	:= 0
Local cMsg		:= ""
Local cEOL := CHR(13)+CHR(10)
Local cAspas := CHR(34)

/*//Chamado SMOI-IM0002550607
If Empty(M->BA3_TIPPAG)  .OR. Empty(_cTipPag)
	MsgAlert("N�o � permitido alterar o Tipo de Pagamento para vazio!")
	Return(.F.)
EndIf*/

	// Leandro Massafera - 24/07/2013
	// Permitir apenas os dias de vencimento disponiveis no Grupo de Cobranca/Convenio (BR0)    
	// FELIPE VIEIRA 11/02/2016 ALTERACAO PARA VALIDAR APENAS SE FOR TROCADO.  
	IF M->BA3_VENCTO <> BA3->BA3_VENCTO                
		If !U_GaBA3Venc()
			Return(.F.)
		EndIf
	ENDIF
	// Permitir apenas os tipos de pagamento disponiveis no Grupo de Cobranca/Convenio (BR0)                      
	If !U_GaBA3TP()
		Return(.F.)
	EndIf
	
	//FELIPESM
	IF lverif
	  
		IF ! M->BA1_ATUCRX
			MsgAlert(" � necess�rio confirmar os dados do cliente e marcar o campo "+ cAspas + "Atualizado"+ cAspas +" para prosseguir.")
			lRet := .F.
			Return(.F.)
		ENDIF
	
	ENDIF
	
	
	
	    //////////////////////////////////////////////////////////////////////////////
	    //VALIDACAO DE CONSIGNACAO TRANSFERIDO PARA O FONTE GAAXFUN NA FUNCAO ValCons
	    //ANTONIO NASCIMENTO - 05/2013
	    //////////////////////////////////////////////////////////////////////////////
	
	IF lRet := U_ValCons(AllTrim(BQC->BQC_XTPORG),AllTrim(BA3->BA3_TIPPAG),'2')
	   	lRet := .T.
	ELSE
	  	lRet := .F.
		Return(lRet)
	ENDIF
	
	/*
	// Validacao para Consignacao em Folha - Leandro Massafera 14/05/2013
		If AllTrim(BQC->BQC_XTPORG) = "3" .AND. AllTrim(BA3->BA3_TIPPAG) = "2"
			_cMat := AllTrim(BA3->BA3_MATEMP)
			_cMatBen := AllTrim(BA3->BA3_XMATBE)
			If AllTrim(M->BA3_MATEMP) = ""
				MsgAlert("Matricula do Servidor em Branco."+cEOL+"Preencha o campo [Matríc. Empr.] na aba [Dados de Cobrança/Cobrança].", "Consignação")
				Return(.F.)
			ElseIf Len(AllTrim(M->BA3_MATEMP)) <> 7
				MsgAlert("Matricula do Servidor com Quantidade de Digitos Incorreta."+cEOL+"Valide o campo [Matríc. Empr.] na aba [Dados de Cobrança/Cobrança].", "Consignação")
				Return(.F.)
			ElseIf AllTrim(M->BA3_XTPSER) = ""
				MsgAlert("Tipo do Servidor em Branco."+cEOL+"Preencha o campo [Tp Servidor] na aba [Dados de Cobrança/Cobrança].", "Consignação")
				Return(.F.)
			ElseIf AllTrim(M->BA3_XTPSER) = "3" .AND. AllTrim(M->BA3_XMATBE) = ""
				MsgAlert("Matricula do Pensionista em Branco."+cEOL+"Preencha o campo [Mat Pension] na aba [Dados de Cobrança/Cobrança].", "Consignação")
				Return(.F.)
			ElseIf AllTrim(M->BA3_XTPSER) = "3" .AND. Len(AllTrim(M->BA3_XMATBE)) <> 8
				MsgAlert("Matricula do Pensionista com Quantidade de Digitos Incorreta."+cEOL+"Valide o campo [Mat Pension] na aba [Dados de Cobrança/Cobrança].", "Consignação")
				Return(.F.)
			ElseIf AllTrim(M->BA3_XTPSER) $ "1/2" .AND. !Empty(AllTrim(M->BA3_XMATBE))
				MsgAlert("Para o Servidor Ativo/Inativo, a Matrícula do Pensionista deve estar em Branco.", "Consignação")
				Return(.F.)
			ElseIf Len(AllTrim(M->BA3_XMATBE)) = 8 .AND. AllTrim(M->BA3_XTPSER) <> "3"
				MsgAlert("Tipo do Servidor Incorreto."+cEOL+"Valide o campo [Tp Servidor] na aba [Dados de Cobrança/Cobrança].", "Consignação")
				Return(.F.)
			ElseIf AllTrim(M->BA3_STASIA) = "A" .AND. _cMat <> AllTrim(M->BA3_MATEMP)
				MsgAlert("Não é possível alterar a Matrícula do Servidor,"+cEOL+"quando o Status SIAPE estiver ACEITO(A).", "Consignação")
				Return(.F.)
			ElseIf AllTrim(M->BA3_STASIA) = "A" .AND. AllTrim(M->BA3_XTPSER) = "3" .AND. _cMatBen <> AllTrim(M->BA3_XMATBE)
				MsgAlert("Não é possível alterar a Matrícula do Pensionista,"+cEOL+"quando o Status SIAPE estiver ACEITO(A).", "Consignação")
				Return(.F.)
			Else
				lRet := .T.
			EndIf
		EndIf
	*/
	// FIM da Validação de Consignação
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Campos obrigatorios dos usuarios  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	For i:=1 to Len(aVetor)
		BA1->(DbGoTo(aVetor[i,Len(aVetor[i])]))
		CA030FreshMe("BA1",0,.F.,.F.,lverif)
		If !Obrigatorio(oEncFld1:aGets,oEncFld1:aTela) .and. !lverif 
			lRet := .F.
			Exit
		EndIf
	Next
	
	/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Campos obrigatorios do cliente  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lRet .AND. !Obrigatorio(oEncSA1:aGets,oEncSA1:aTela)
		lRet := .F.
	EndIf
	*/
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida dados de cobranca                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄœ¿
	//³Esta parte teve uma area comentada porque a funão ValPort() esta fazendo esta validação juntamente com algumas novas solicitadas pelo financeiro³
	//³RAFAEL DE PAULA 03/08/2012                                                                                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄœÙ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Invertida a ordem de chamada das funções de validação                                                                                 ³
	//³das informações bancárias.                                                                                                            ³
	//³Primeiro: Sistema valida tamanhos de campos, obrigatoriedade de informações etc. baseado na comparação de informações com a tabela ZAC³
	//³Segundo: Sistema valida informações para gravação do banco portador e regras especificas da Caixa Econômica Federal                   ³
	//³                                                                                                                                      ³
	//³RAFAEL DE PAULA - 31/10/2012                                                                                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	
	dbSelectArea("BA3")
	dbSetOrder(7)
	dbSeek(xFilial() + cMatric)
	
	If BA3->BA3_COBNIV == "1" //So faz as validacoes de dados bancarios e formas de pagamento se a cobranca for no nivel de familia
	
		//	If lRet .AND. cTpDebCta == Alltrim(M->BA3_TIPPAG) //ValidaÃ§Ãµes para forma de pagamento DEBITO
		If Alltrim(M->BA3_TIPPAG) = "1" .OR. Alltrim(M->BA3_TIPPAG) = "2" .OR. AllTrim(M->BA3_BCOCLI) = "104" 	//Validações para a forma de pagamento DEBITO, CONSIGNAÇÃO ou BANCO CAIXA
			////felipe vieira 10/02/2016 if adicionado para validar trecho do crm, so valida esses dados se trocar no cadastro
			// felipe vieira 04/03/2016 if ajustado para validar restos dos campos das contas
			if BA3->BA3_AGECLI <> M->BA3_AGECLI .or. BA3->BA3_CTACLI <> M->BA3_CTACLI .or. M->BA3_BCOCLI <> BA3->BA3_BCOCLI .or. M->BA3_XCSCON <> BA3->BA3_XCSCON .or. M->BA3_AGEDI <> BA3->BA3_AGEDI .or. M->BA3_CTADI <> BA3->BA3_CTADI
			     //ALTERADO POR ANTONIO PARA TRATAR OS BANCOS NÃO CONVENIADOS (BA3_XCSCON)--05/2013
				If U_GAVLDBCO(M->BA3_BCOCLI,M->BA3_XCSCON,M->BA3_AGECLI,M->BA3_AGEDI,M->BA3_CTACLI,M->BA3_CTADI)         	//A justificativa para utilizar o cod.banco caixa se da porque a caixa possui a validacao do portador
			  	   	lRet := U_ValPort(cMatric,M->BA3_GRPCOB) //funcao resposÃ¡vel por atualizar os dados de banco portador - RAFAEL DE PAULA - 03/08/2012
			  	Else
			  	   lRet := .F.
			  	Endif
		  	endif
		Else
			lRet := U_ValPort(cMatric,M->BA3_GRPCOB) //funcao resposÃ¡vel por atualizar os dados de banco portador - RAFAEL DE PAULA - 03/08/2012
		Endif
		
		
		//27/11/2013 - Adib Dias: Retirado o fechamento do alias BA3, pois est� desfazendo o filtro DbSeek do inicio da rotina
		//dbSelectArea("BA3")
		//dbCloseArea()
	
		Return(lRet)
	
	Else
		//27/11/2013 - Adib Dias: Retirado o fechamento do alias BA3, pois est� desfazendo o filtro DbSeek do inicio da rotina
		//dbSelectArea("BA3")
		//dbCloseArea()
		
		Return(lRet)
	
	Endif

Return lRet
/*
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
������������������������������������������������������������������������������Ŀ��
���Funcao    �CA030PlsTmkOco  � Autor �                    � Data �            ���
������������������������������������������������������������������������������Ĵ��
���Descricao �Grava Ocorrencias de cada Funccao acessada via Tela de           ���
���          �integracao CALL X PLS                                            ���
������������������������������������������������������������������������������Ĵ��
���Uso       �Grupo Alianca                                                    ���
�������������������������������������������������������������������������������ٱ�
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
*/
User Function CA030PlsTmkOco( cFunc , cMemoAlt )

Local nInd			:= 0
Local nLinA			:= 0
Local cAssunto 		:= ""
Local cDesAssu		:= ""
Local cOcorre		:= ""
Local cDesOco		:= ""
Local cStatus   	:= "1"
Local aColAux  		:= aClone(aCols)
Local cAcao 		:= ""
Local nLCols 		:= 0
Default cFunc 		:= ''
DEFAULT cMemoAlt	:= ""

DbSelectArea("B20")
B20->(DbSetOrder(1))
If !Empty( cFunc ) .and. MsSeek( xFilial("B20") + cFunc )

	If aScan(_aOkAlianca, cFunc) == 0
		nLinA := Len(aCols)

		If !Empty( aCols[ 1 , PLRETPOS( "UD_ASSUNTO" , aHeader ) ] )

			aadd(aCols,{})
			nLinA++

			For nInd :=  1 To Len(aHeader)+1

			    If nInd <= Len(aHeader)
			       If     aHeader[nInd,8] == "C"
			              aadd(aCols[Len(aCols)],Space(aHeader[nInd,4]))
			       ElseIf aHeader[nInd,8] == "D"
			              aadd(aCols[Len(aCols)],ctod(""))
			       ElseIf aHeader[nInd,8] == "N"
			              aadd(aCols[Len(aCols)],0)
			       ElseIf aHeader[nInd,8] == "L"
			              aadd(aCols[Len(aCols)],.T.)
			       ElseIf aHeader[nInd,8] == "M"
			              aadd(aCols[Len(aCols)],"")
			       Endif
			    Else
			       aadd(aCols[Len(aCols)],.F.)
			    Endif

			Next

	 	EndIf

		DbSelectarea("SX5")
		DbSetorder( 1 )
		If DbSeek( xFilial("SX5")+"T1"+B20->B20_ASSUNT )
			cAssunto 	:= SX5->X5_CHAVE
			cDesAssu	:= X5DESCRI()
		Else
			Help(" ",1,"ASSUNTO" )
			lRet := .F.
		Endif

		DbSelectarea("SU9")
		DbSetorder( 1 )
		If DbSeek( xFilial("SU9")+B20->B20_ASSUNT+B20->B20_OCORRE )
			cOcorre	:= SU9->U9_CODIGO
			cDesOco	:= SU9->U9_DESC
		Else
			Help(" ",1,"OCORRENCIA")
			lRet := .F.
		Endif

		If B20->B20_XENCER == "S" .AND. !Empty(B20->B20_XACAO)
			cStatus := "2"
			aCols[nLinA,PLRETPOS("UD_SOLUCAO",aHeader)] 	:= B20->B20_XACAO
			aCols[nLinA,PLRETPOS("UD_DESCSOL",aHeader)] 	:= Posicione("SUQ",1,xFilial("SUQ") + B20->B20_XACAO,"UQ_DESC")
		EndIf

		aCols[nLinA,PLRETPOS("UD_ASSUNTO",aHeader)]		:= cAssunto
		aCols[nLinA,PLRETPOS("UD_DESCASS",aHeader)]		:= cDesAssu
		aCols[nLinA,PLRETPOS("UD_OCORREN",aHeader)] 	:= cOcorre
		aCols[nLinA,PLRETPOS("UD_DESCOCO",aHeader)] 	:= cDesOco
		aCols[nLinA,PLRETPOS("UD_STATUS",aHeader)]		:= cStatus
	  	aCols[nLinA,PLRETPOS("UD_XIOBSRE",aHeader)]		:= cMemoAlt // Alterado novo campo memo ANTONIO TOTVS

		aCols[nLinA,1] := LoaDbitmap(GetResources(),IIf(cStatus == "2","BR_VERDE","BR_VERMELHO")) // Trata legenda do status

		//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
	  	//Â³Executa os gatilhos dos campos e as validacoes necessariasÂ³
	 	//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
		nBkp 		:= n
		n 			:= nLinA
		xBkpReadVar := 	__ReadVar
	  	If ExistTrigger("UD_OCORREN")
	  		M->UD_OCORREN	:= cOcorre
			__ReadVar		:= "UD_OCORREN"
	    	RunTrigger(2,n,Nil,,"UD_OCORREN")
	  	EndIf
	  	If !Empty(B20->B20_XACAO) .AND. ExistTrigger("UD_SOLUCAO")
	  		M->UD_SOLUCAO	:= B20->B20_XACAO
			__ReadVar		:= "UD_SOLUCAO"
	    	RunTrigger(2,n,Nil,,"UD_SOLUCAO")
		EndIf
		If cStatus == "2" .AND. ExistTrigger("UD_STATUS ")
	  		M->UD_STATUS	:= cStatus
			__ReadVar		:= "UD_STATUS "
	    	RunTrigger(2,n,Nil,,"UD_STATUS ")
		EndIf
		__ReadVar 	:= xBkpReadVar
		n 			:= nBkp


		//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
		//Â³Inclui funcao para identificar que item automatico ja foi gerado            Â³
		//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
		AAdd(_aOkAlianca, cFunc )

	Else
		//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
		//Â³Se a ocorrencia ja foi incluida anteriormente, significa que esta alterando mais de uma vez no mesmo atendimento  Â³
		//Â³Atualizaremos o memo                                                                                              Â³
		//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
		If !Empty(cMemoAlt)
			//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
			//Â³Pesquisa linha no acols                              Â³
			//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
			DbSelectarea("SX5")
			DbSetorder( 1 )
			If DbSeek( xFilial("SX5")+"T1"+B20->B20_ASSUNT )
				cAssunto 	:= SX5->X5_CHAVE
				DbSelectarea("SU9")
				DbSetorder( 1 )
				If DbSeek( xFilial("SU9")+B20->B20_ASSUNT+B20->B20_OCORRE )
					cOcorre	:= SU9->U9_CODIGO
					If B20->B20_XENCER == "S" .AND. !Empty(B20->B20_XACAO)
						cAcao := B20->B20_XACAO
					EndIf
					If !Empty(cAssunto) .AND. !Empty(cOcorre)
						nLCols := aScan(aCols, {|x| x[PLRETPOS("UD_ASSUNTO",aHeader)] == cAssunto .AND. x[PLRETPOS("UD_OCORREN",aHeader)] == cOcorre .AND. IIf(Empty(cAcao),.T., x[PLRETPOS("UD_SOLUCAO",aHeader)] == cAcao) })
						If nLCols > 0
							aCols[nLCols,PLRETPOS("UD_XIOBSRE",aHeader)]		+= ENTER + cMemoAlt //alterado novo campo memo Antonio TOTVS
						EndIf
					EndIF
				EndIf
			EndIf
        EndIf
	EndIf
Else
	aCols 	:= aClone(aColAux)
//	MsgAlert("!!PLS x TMK nÃ£o encotrada!!") //
EndIf

N	:= Len(aCols)

If	Type("oGetTmkPls:oBrowse") <> "O"
	oGetTmk:SetArray(aCols)
    oGetTmk:ForceRefresh()
Else
	oGetTmkPls:SetArray(aCols)
	oGetTmkPls:ForceRefresh()
EndIf

Return


Static Function AjustaSX3()


DbSelectarea("SX3")
SX3->(dbSetOrder(2))

If SX3->(MsSeek("BEA_TIPSAI")) .and. SX3->X3_RESERV <> "Ã¾A"
	RecLock("SX3",.F.)
	SX3->X3_RESERV := "Ã¾A"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BEA_REGEXE")) .and. SX3->X3_RESERV <> "Ã¾A"
	RecLock("SX3",.F.)
	SX3->X3_RESERV := "Ã¾A"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BEA_ATDTMK")) .and. (SX3->X3_FOLDER <> "2" .OR. !Empty(SX3->X3_RELACAO))
	RecLock("SX3",.F.)
	SX3->X3_FOLDER := "2"
	SX3->X3_RELACAO := "IF(inclui, PlGrAtTMK('BEA'),BEA->BEA_ATDTMK)"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BE1_ATDTMK")) .and. SX3->X3_FOLDER <> "2"
	RecLock("SX3",.F.)
	SX3->X3_FOLDER := "2"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BE4_ATDTMK")) .and. SX3->X3_FOLDER <> "2"
	RecLock("SX3",.F.)
	SX3->X3_FOLDER := "2"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BE2_CODPAD")) .and. SX3->X3_ORDEM <> "24"
	RecLock("SX3",.F.)
	SX3->X3_ORDEM := "24"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BE1_USUARI")) .and. SX3->X3_WHEN <> "Empty(M->BE1_NUMLIB) .AND. Empty(M->BE1_NOMUSR)"
	RecLock("SX3",.F.)
	SX3->X3_WHEN := "Empty(M->BE1_NUMLIB) .AND. Empty(M->BE1_NOMUSR)"
	SX3->(MsUnlock())
End

If SX3->(MsSeek("BE4_USUARI")) .and. SX3->X3_WHEN <> "Empty(M->BE4_NOMUSR)"
	RecLock("SX3",.F.)
	SX3->X3_WHEN := "Empty(M->BE4_NOMUSR)"
	SX3->(MsUnlock())
End

Return

Static Function AjustaSXB()


DbSelectarea("SXB")
SXB->(dbSetOrder(1))

If SXB->(MsSeek("BBVPLS"))

	While !SXB->(Eof()) .AND. SXB->XB_ALIAS = "BBVPLS"
		If AllTrim(SXB->XB_CONTEM) == 'BAU_CODIGO'
			RecLock("SXB",.F.)
			SXB->(DbDelete())
			SXB->(MsUnlock())
		EndIf
		SXB->(DbSkip())
	EndDo

End

Return

/*ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿Â±Â±
Â±Â±Â³Programa   Â³   C()   Â³ Autores Â³ Norbert/Ernani/Mansano Â³ Data Â³10/05/2005Â³Â±Â±
Â±Â±ÃƒÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã…Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â´Â±Â±
Â±Â±Â³Descricao  Â³ Funcao responsavel por manter o Layout independente da       Â³Â±Â±
Â±Â±Â³           Â³ resolucao horizontal do Monitor do Usuario.                  Â³Â±Â±
Â±Â±Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ*/
Static Function C(nTam,cObj)

If ((Alltrim(GetTheme()) == "CLASSIC") .OR. (Alltrim(GetTheme()) == "OCEAN")) .and. !SetMdiChild()
	Do Case
		Case cObj == '1'
			nTam := 100
		Case cObj == '2'
			nTam := 70
		Case cObj == '3'
			nTam := 170
	EndCase
EndIf

Return Int(nTam)

/*ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã‚Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿Â±Â±
Â±Â±Â³Programa   Â³   C()   Â³ Autores Â³ Norbert/Ernani/Mansano Â³ Data Â³10/05/2005Â³Â±Â±
Â±Â±ÃƒÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã…Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â´Â±Â±
Â±Â±Â³Descricao  Â³ Funcao responsavel por manter o Layout independente da       Â³Â±Â±
Â±Â±Â³           Â³ resolucao horizontal do Monitor do Usuario.                  Â³Â±Â±
Â±Â±Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã�Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ*/

Static Function L(nTam)

If ((Alltrim(GetTheme()) == "CLASSIC") .OR. (Alltrim(GetTheme()) == "OCEAN")) .and. !SetMdiChild()
	nTam := 25
EndIf

Return Int(nTam)

/*
ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±Ã‰Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â»Â±Â±
Â±Â±ÂºPrograma  Â³CA030Grv  ÂºAutor  Â³Jonas L. Souza Jr   Âº Data Â³  12/22/11   ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºDesc.     Â³Funcao de gracao generica para atualizacao de dados do PLS  ÂºÂ±Â±
Â±Â±Âº          Â³integrado com o Portal                                      ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºUso       Â³ Alianca                                                    ÂºÂ±Â±
Â±Â±ÃˆÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¼Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ
*/

User Function CA030Grv(cAlias,nIndex,cKey,aCpos,cMEMO)

Local lRet		:= .T.
Local aArea		:= GetArea()
Local nX		:= 0
Local aStruBTS	:= BTS->(DbStruct())
Local nY		:= 0
Local aBA1Area	:= {}
Local lAlterou 	:= .F.
Local cMemoAux	:= ""
Local lBackOffice := .F.

DEFAULT cAlias	:= ""
DEFAULT nIndex	:= 1
DEFAULT cKey	:= ""
DEFAULT aCpos	:= {}
DEFAULT cMEMO	:= ""		// Memo com os campos alterados

//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
//Â³Atualiza somente se passou campos a serem alterados          Â³
//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
If Len(aCpos) == 0
	RestArea(aArea)
	Return .F.
EndIf

DbSelectArea(cAlias)
DbSetOrder(nIndex)
If DbSeek(cKey)

	//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
	//Â³Verifica se teve alteracao de dados                     Â³
	//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
	For nX:=1 to Len(aCpos)
		If Alltrim(&(cAlias+"->"+Alltrim(aCpos[nX,1]))) <> Alltrim(aCpos[nX,2]) .and. Alltrim(aCpos[nX,1]) <> "BA1_ATUCRX"
			lAlterou := .T.
			cMemoAux += "Tabela "+cAlias+": "+Alltrim(Posicione("SX2",1,cAlias,"X2NOME()"))
			If cAlias == "BA1"
				cMemoAux += " - Usuario: "+Alltrim(BA1->BA1_NOMUSR)
			EndIf
			cMemoAux += " - Campo "+Alltrim(aCpos[nX,1])+" ["+Alltrim(Posicione("SX3",2,Alltrim(aCpos[nX,1]),"X3_TITULO"))+"] de "
			cMemoAux += " [ "+ CA030Text(&(cAlias+"->"+Alltrim(aCpos[nX,1]))) +" ] "
			cMemoAux += " para "
			cMemoAux += " [ "+ CA030Text(aCpos[nX,2]) +" ] "
			cMemoAux += ENTER
		EndIf
	Next nX

	If lAlterou
		cMEMO += cMemoAux

		RegToMemory( cAlias, .F., .F. )

		//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
		//Â³Atualiza memorias com os campos enviados                   Â³
		//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
		For nX:=1 to Len(aCpos)
			&("M->"+aCpos[nX,1]) := aCpos[nX,2]
		Next nX
		PLUPTENC(cAlias,4)


		//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
		//Â³Atualiza cadastro de vida e usarios relacionados a mesma vida             Â³
		//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
		If cAlias == "BA1"
			BTS->(DbSetOrder(1))
			BTS->(DbSeek(xFilial("BTS")+BA1->BA1_MATVID))
			RegToMemory( "BTS", .F., .F. )

			//For nY:=1 to Len(aStruBTS)
			//msgbox(aCpos[nY,1])
			//Next nY

			For nY:=1 to Len(aStruBTS)
				If aStruBTS[nY,1] == "BTS_RAMAL"
					&("M->BTS_"+SubStr(aStruBTS[nY,1],5,6)) := BA1->BA1_XRAMAL
				ElseIf aStruBTS[nY,1] == "BTS_OCUPAC"
					&("M->BTS_"+SubStr(aStruBTS[nY,1],5,6)) := BA1->BA1_XOCUPA
				Else
					nPCpo := aScan(aCpos,{ |x| SubStr(x[1],5,6) = SubStr(aStruBTS[nY,1],5,6) })
					If nPCpo > 0
						&("M->BTS_"+SubStr(aStruBTS[nY,1],5,6)) := aCpos[nPCpo,2]
					EndIf
				EndIf
			Next nY
		 	PLUPTENC("BTS",4)



			//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
			//Â³Atualiza cliente da entidade BA1                    Â³
			//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
            DbSelectArea("SA1")
            If Found() .AND. BA1->BA1_TIPUSU == "T"
				RecLock("SA1",.F.)
				Replace A1_EMAIL	With	BA1->BA1_EMAIL
				Replace A1_CEP		With	BA1->BA1_CEPUSR
				Replace A1_END		With	BA1->BA1_ENDERE
				Replace A1_NUM_END	With	BA1->BA1_NR_END
				Replace A1_COMPL	With	BA1->BA1_COMEND
				Replace A1_BAIRRO	With	BA1->BA1_BAIRRO
				Replace A1_MUN		With	BA1->BA1_MUNICI
				Replace A1_EST		With	BA1->BA1_ESTADO
				Replace A1_DDD		With	BA1->BA1_DDD
				Replace A1_TEL		With	BA1->BA1_TELEFO
				MsUnLock()
            EndIf

			//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
			//Â³Atualiza familia BA3                        Â³
			//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
			If BA1->BA1_TIPUSU == "T"
				BA3->(DbSetOrder(1))
				If BA3->(MsSeek(xFilial("BA3")+BA1->(BA1_CODINT+BA1_CODEMP+BA1_MATRIC+BA1_CONEMP+BA1_VERCON+BA1_SUBCON+BA1_VERSUB)))
					RecLock("BA3",.F.)
					Replace BA3_CEP		With	BA1->BA1_CEPUSR
					Replace BA3_END		With	BA1->BA1_ENDERE
					Replace BA3_NUMERO	With	BA1->BA1_NR_END
					Replace BA3_COMPLE	With	BA1->BA1_COMEND
					Replace BA3_BAIRRO	With	BA1->BA1_BAIRRO
					Replace BA3_MUN		With	BA1->BA1_MUNICI
					Replace BA3_ESTADO	With	BA1->BA1_ESTADO
					Replace BA3_TPEND 	With	BA1->BA1_TPEND
//					Replace BA3_MATEMP 	With	BA1->BA1_MATEMP

					MsUnLock()
				EndIf
			EndIf

			//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
			//Â³Atualiza contato da entidade BA1                    Â³
			//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
			DbSelectArea("SU5")
			DbSetOrder(1)
			If DbSeek(xFilial("SU5")+U_CXRetContat("BA1",2,BA1->(BA1_CODINT+BA1_CODEMP+BA1_MATRIC+BA1_TIPREG+BA1_DIGITO)))
				RecLock("SU5",.F.)
				Replace U5_EMAIL	With	BA1->BA1_EMAIL
				Replace U5_CEP		With	BA1->BA1_CEPUSR
				Replace U5_END		With	BA1->BA1_ENDERE
				Replace U5_NR_END	With	BA1->BA1_NR_END
				Replace U5_COMEND	With	BA1->BA1_COMEND
				Replace U5_BAIRRO	With	BA1->BA1_BAIRRO
				Replace U5_MUN		With	BA1->BA1_MUNICI
				Replace U5_EST		With	BA1->BA1_ESTADO
				Replace U5_DDD		With	BA1->BA1_DDD
				Replace U5_FONE		With	BA1->BA1_TELEFO
				Replace U5_DDDCL	With	BA1->BA1_DDDCL
				Replace U5_CELULAR	With	BA1->BA1_FONECL
				Replace U5_DDDCM	With	BA1->BA1_DDDCM
				Replace U5_FCOM1	With	BA1->BA1_FONECM
				Replace U5_CIVIL	With	BA1->BA1_ESTCIV

				//Campos alteraveis somente pelo BackOffice
				If lBackOffice
					Replace U5_CONTAT	With	BA1->BA1_NOMUSR
					Replace U5_NIVER	With	BA1->BA1_DATNAS
					Replace U5_SEXO		With	BA1->BA1_SEXO
					Replace U5_MAE		With	BA1->BA1_MAE
					Replace U5_DRGUSR	With	BA1->BA1_DRGUSR
					Replace U5_ORGEM	With	BA1->BA1_ORGEM
					Replace U5_CPF		With	BA1->BA1_CPFUSR
				EndIf
				MsUnLock()
			EndIf

			//ÃšÃ„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Â¿
			//Â³Atualiza contato da entidade ZCO                    Â³
			//Ã€Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã„Ã™
			DbSelectArea("ZC0")
			DbSetOrder(3)
			If DbSeek(xFilial("ZC0")+BA1->BA1_CPFUSR)
				RecLock("ZC0",.F.)
					Replace ZC0_EMAIL	With	BA1->BA1_EMAIL
				MsUnLock()
			EndIf
			//��������������������������������������������������������������������������Ŀ
			//� Verifica outros usuarios que possuem a mesma Matricula Vida              �
			//����������������������������������������������������������������������������
			aBA1Area := BA1->(GetArea())
			DbSelectArea("BA1")
			DbSetOrder(7)
			DbSeek(xFilial("BA1")+BTS->BTS_MATVID)
			While !BA1->(EOF()) .AND. xFilial("BA1")+BTS->BTS_MATVID == BA1->(BA1_FILIAL+BA1_MATVID)
				//��������������������������������������Ŀ
				//� Ignora usuario original              �
				//����������������������������������������
				If BA1->(BA1_FILIAL+BA1_CODINT+BA1_CODEMP+BA1_MATRIC+BA1_TIPREG+BA1_DIGITO) == cKey
					BA1->(DbSkip())
					Loop
				EndIf

				RegToMemory( "BA1", .F., .F. )

			//�������������������������������������������������������Ŀ
			//� Atualiza memorias com os campos enviados              �
			//���������������������������������������������������������
				For nX:=1 to Len(aCpos)
					//Exce��o, estes campos N�O podem ser atualizados
					If !Alltrim(aCpos[nX,1]) $ "BA1_MATANT|BA1_TIPUSU|BA1_GRAUPA"
						&("M->"+aCpos[nX,1]) := aCpos[nX,2]
					EndIf
				Next nX
				PLUPTENC("BA1",4)

				BA1->(DbSkip())
			EndDo
			BA1->(RestArea(aBA1Area))
		EndIf
	EndIf
Else
	lRet := .F.
EndIf

RestArea(aArea)

Return lRet

/*
ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±Ã‰Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â»Â±Â±
Â±Â±ÂºPrograma  Â³CA030Func ÂºAutor  Â³Jonas L. Souza Jr   Âº Data Â³  12/22/11   ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºDesc.     Â³Inclui ocorrencias especificas na tabela BJ                 ÂºÂ±Â±
Â±Â±Âº          Â³                                                            ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºUso       Â³ Grupo Alianca.                                             ÂºÂ±Â±
Â±Â±ÃˆÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¼Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ
*/

User Function CA030Func()

Local aArea	:= GetArea()

DbSelectArea("SX5")
DbSetOrder(1)

If !DbSeek(xFilial("SX5")+"BJ"+"AL0001")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0001"
	Replace X5_DESCRI	With	"ALTERACAO CADASTRAL - ALIANCA"
	Replace X5_DESCSPA	With	"ALTERACAO CADASTRAL - ALIANCA"
	Replace X5_DESCENG	With	"ALTERACAO CADASTRAL - ALIANCA"
	MsUnLock()
EndIf

If !DbSeek(xFilial("SX5")+"BJ"+"AL0002")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0002"
	Replace X5_DESCRI	With	"GERACAO DE BOLETO - ALIANCA"
	Replace X5_DESCSPA	With	"GERACAO DE BOLETO - ALIANCA"
	Replace X5_DESCENG	With	"GERACAO DE BOLETO - ALIANCA"
	MsUnLock()
EndIf

/*If !DbSeek(xFilial("SX5")+"BJ"+"AL0003")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0003"
	Replace X5_DESCRI	With	"ALTERACAO CADASTRAL WEB - ALIANCA"
	Replace X5_DESCSPA	With	"ALTERACAO CADASTRAL WEB - ALIANCA"
	Replace X5_DESCENG	With	"ALTERACAO CADASTRAL WEB - ALIANCA"
	MsUnLock()
EndIf
*/
If !DbSeek(xFilial("SX5")+"BJ"+"000015")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"000015"
	Replace X5_DESCRI	With	"ALTERACAO CADASTRAL WEB - ALIANCA"
	Replace X5_DESCSPA	With	"ALTERACAO CADASTRAL WEB - ALIANCA"
	Replace X5_DESCENG	With	"ALTERACAO CADASTRAL WEB - ALIANCA"
	MsUnLock()
EndIf
If !DbSeek(xFilial("SX5")+"BJ"+"AL0004")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0004"
	Replace X5_DESCRI	With	"EMISSAO DE DEMONSTRATIVO DE I.R. - ALIANCA"
	Replace X5_DESCSPA	With	"EMISSAO DE DEMONSTRATIVO DE I.R. - ALIANCA"
	Replace X5_DESCENG	With	"EMISSAO DE DEMONSTRATIVO DE I.R. - ALIANCA"
	MsUnLock()
EndIf

If !DbSeek(xFilial("SX5")+"BJ"+"AL0005")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0005"
	Replace X5_DESCRI	With	"EMISSAO DE CARTA DE QUITACAO- ALIANCA"
	Replace X5_DESCSPA	With	"EMISSAO DE CARTA DE QUITACAO- ALIANCA"
	Replace X5_DESCENG	With	"EMISSAO DE CARTA DE QUITACAO- ALIANCA"
	MsUnLock()
EndIf

If !DbSeek(xFilial("SX5")+"BJ"+"AL0006")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0006"
	Replace X5_DESCRI	With	"EMISSAO DE DEBITO/CONSIGNACAO - ALIANCA"
	Replace X5_DESCSPA	With	"EMISSAO DE DEBITO/CONSIGNACAO - ALIANCA"
	Replace X5_DESCENG	With	"EMISSAO DE DEBITO/CONSIGNACAO - ALIANCA"
	MsUnLock()
EndIf


If !DbSeek(xFilial("SX5")+"BJ"+"AL0007")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0007"
	Replace X5_DESCRI	With	"EMISSAO DE LINHA DIGITAVEL VIA SMS - ALIANCA"
	Replace X5_DESCSPA	With	"EMISSAO DE LINHA DIGITAVEL VIA SMS - ALIANCA"
	Replace X5_DESCENG	With	"EMISSAO DE LINHA DIGITAVEL VIA SMS - ALIANCA"
	MsUnLock()
EndIf

If !DbSeek(xFilial("SX5")+"BJ"+"AL0008")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0008"
	Replace X5_DESCRI	With	"GERACAO DE BOLETO WEB - ALIANCA"
	Replace X5_DESCSPA	With	"GERACAO DE BOLETO WEB - ALIANCA"
	Replace X5_DESCENG	With	"GERACAO DE BOLETO WEB - ALIANCA"
	MsUnLock()
EndIf

If !DbSeek(xFilial("SX5")+"BJ"+"AL0009")
	RecLock("SX5",.T.)
	Replace X5_FILIAL	With	xFilial("SX5")
	Replace X5_TABELA	With	"BJ"
	Replace X5_CHAVE	With	"AL0009"
	Replace X5_DESCRI	With	"EMISSAO DE LINHA DIGITAVEL VIA SMS WEB - ALIANCA"
	Replace X5_DESCSPA	With	"EMISSAO DE LINHA DIGITAVEL VIA SMS WEB - ALIANCA"
	Replace X5_DESCENG	With	"EMISSAO DE LINHA DIGITAVEL VIA SMS WEB - ALIANCA"
	MsUnLock()
EndIf


RestArea(aArea)

Return()

/*
ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±Ã‰Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â»Â±Â±
Â±Â±ÂºPrograma  Â³RetX3Combo ÂºAutor Â³Jonas L. Souza Jr   Âº Data Â³ 09/29/2008  ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºDesc.     Â³Verifica o conteudo no X3_COMBO referente ao valor passado. ÂºÂ±Â±
Â±Â±Âº          Â³                                                            ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºUso       Â³ Grupo Alianca.                                             ÂºÂ±Â±
Â±Â±ÃˆÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¼Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ
*/

Static Function RetX3Combo( cCampo , cConteudo )

Local cCaption	:= ""
Local aSx3Box   := RetSx3Box( Posicione("SX3", 2, cCampo, "X3CBox()" ),,, 1 )
Local nPos		:= Ascan( aSx3Box, { |aBox| aBox[2] = Alltrim(cConteudo) } )

If	nPos > 0
	cCaption := AllTrim( aSx3Box[nPos][3] )
EndIf

Return(cCaption)

/*
ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±Ã‰Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã‹Ã�Ã�Ã�Ã�Ã�Ã�Ã‘Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â»Â±Â±
Â±Â±ÂºPrograma  Â³CA030Text ÂºAutor  Â³Jonas L. Souza Jr   Âº Data Â³  01/06/12   ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�ÃŠÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºDesc.     Â³Converte conteudo para texto                                ÂºÂ±Â±
Â±Â±Âº          Â³                                                            ÂºÂ±Â±
Â±Â±ÃŒÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã˜Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¹Â±Â±
Â±Â±ÂºUso       Â³ Grupo Alianca.                                             ÂºÂ±Â±
Â±Â±ÃˆÃ�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Ã�Â¼Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ
*/

Static Function CA030Text(xValor)

Do Case
	Case ValType(xValor) == "C"
		xValor := xValor

	Case ValType(xValor) == "N"
		xValor := Alltrim(Str(xValor))

	Case ValType(xValor) == "D"
		xValor := DtoC(xValor)

	Case ValType(xValor) == "L"
		xValor := IIF(xValor,"Verdadeiro","Falso")

	OtherWise
		xValor := ""

EndCase

Return Alltrim(xValor)

/*---------------------------------------------------------------------------------------------------
Titulo						F3SUR
Descricao					Consulta F3
Autor						Marcos Kato
Data cria��o				03/07/2019
Altera��es   				
Empresa						QUALICORP
Modulo               		PLS
Observa��o					Chamada via SXB
---------------------------------------------------------------------------------------------------*/
User Function F3SUR()
Local aLista	:= {}
Local lRet		:= .F.
Local nPos		:= 0
Local nCodAss	:= 0
Local nCodOcor	:= 0
Local nCodResp	:= 0
Local cBtnCss	:= "QPushButton{"+ Alltrim(SuperGetMv("ES_BRWBTN1",.F.,"background-image:url(rpo:backgroundblue.png); color: white;")) + "border-radius: 5px; margin: 2px  }"
Local cBtnCss2	:= "QPushButton{"+ Alltrim(SuperGetMv("ES_BRWBTN2",.F.,"background-color:lightgrey; color: white;")) + " border-radius: 5px; margin: 2px  }"
Local cAssunto	:= ""
Local cOcorr	:= ""
Local cGrpResp 	:= ""
Local cTexto	:= Space(100)
Local oDlg, oLista, oTexto, oSearch, oConfirma, oExit

nCodAss	:= aScan(aHeader, {|x| Alltrim(x[2]) == "UD_ASSUNTO"})
nCodOcor:= aScan(aHeader, {|x| Alltrim(x[2]) == "UD_OCORREN"})
//nCodSol	:= aScan(aHeader, {|x| Alltrim(x[2]) == "UD_SOLUCAO"})	Space(TamSx3("UD_SOLUCAO")[1])
nCodResp:= aScan(aHeader, {|x| Alltrim(x[2]) == "UD_XGRRESP"})

If nCodAss > 0 .And. nCodOcor > 0
	cAssunto	:= aCols[n][nCodAss]
	cOcorr		:= aCols[n][nCodOcor]

	If nCodResp > 0	
		cGrpResp 	:= aCols[n][nCodResp]
	Endif
	If Empty(cAssunto) 
		MessageBox("Codigo do assunto deve ser informado","Atendimento",MB_ICONASTERISK)
	ElseIf Empty(cOcorr) 
		MessageBox("Codigo da ocorrencia deve ser informado","Atendimento",MB_ICONASTERISK)
	Else
		aLista	:= SURBusca(cAssunto, cOcorr)
		If Len(aLista) > 0
			DEFINE DIALOG oDlg TITLE "A��o x Ocorrencia" FROM 180,180 TO 550,900 PIXEL STYLE DS_MODALFRAME   
			
			oTexto := TGet():New( 012,010,{|u| if( Pcount( )>0, cTexto:= u,cTexto ) },oDlg,300,009,"@!",{|| .T. /*Validacao*/},0,,,.F.,,.T.,,.F.,;
			{|| .T./*bWhen*/},.F.,.F.,{|| .T./*bChange*/},.F./*ReadOnly*/,.F.,,"cTexto",,,,.F.,,,,,,,"Filtro",,.T.)
			oSearch:= TButton():New( 010, 300, "Pesquisar" , oDlg,{|| ( aLista	:= SURBusca(cAssunto, cOcorr, cTexto), oLista:aArray:= aLista, oLista:Refresh()) },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
			oSearch:SetCss(cBtnCss)
			
			oLista := TCBrowse():New( 030, 010,340,125,,{"Codigo","Descricao","Grupo Responsavel"},{40,100,100},oDlg,,,,,{|| },,,,,,,.F.,,.T.,,.F.,,.T.,.T.)        
			oLista:SetArray(aLista)
			oLista:bLine          := {|| {;
			aLista[oLista:nAt][1],;     
			aLista[oLista:nAt][2],;
			aLista[oLista:nAt][4]}}   
			oLista:bLDblClick   := {|| (nPos:= oLista:nAt,oDlg:End() )}
			
			oConfirma:= TButton():New( 160, 250, "Confirma" , oDlg,{|| (nPos:= oLista:nAt,oDlg:End()) },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
			oConfirma:SetCss(cBtnCss)
			
			oExit	:= TButton():New( 160, 300, "Cancela"  , oDlg,{||  oDlg:End() },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
			oExit:SetCss(cBtnCss)
			
			oDlg:lEscClose:= .F.
			   
			ACTIVATE DIALOG oDlg CENTERED
		
			If nPos>0 .And. Len(aLista) > 0
				DbSelectArea("SUR")
				SUR->(DbSetOrder(1))
				If SUR->(DbSeek(xFilial("SUR") + AvKey(cOcorr,"UR_CODREC") + AvKey(aLista[nPos][5] ,"UR_IDTREE") + AvKey(aLista[nPos][6], "UR_IDCODE")))
					lRet:= .T.
				Endif
			Endif
		Else	
			MessageBox("Solucao n�o cadastrada","Atendimento",MB_ICONASTERISK)
		Endif
	Endif
Else
	MessageBox("Busca Solucao nao tratada para esta rotina","Atendimento",MB_ICONASTERISK)	
Endif
Return lRet
/*---------------------------------------------------------------------------------------------------
Titulo						SURBusca
Descricao					Filtrar a acao de acordo a solucao e a ocorrencia informada no atendimento
Autor						Marcos Kato
Data cria��o				03/07/2019
Altera��es   				
Empresa						QUALICORP
Modulo               		PLS
Observa��o					
---------------------------------------------------------------------------------------------------*/

Static Function SURBusca(cPar01, cPar02, cPar03)
Local aRet		:= {}	
Local cQryTRB 	:= "" 
Local cArqTRB 	:= ""
Local cCodigo	:= ""
Local cDescr	:= ""
Default cPar01	:= ""//Assunto
Default cPar02	:= ""//Ocorrencia
Default cPar03	:= ""//Filtro

cQryTRB:= " SELECT " + CRLF
cQryTRB+= " 	DISTINCT SOLUCAO.UR_CODSOL AS [CODIGO], SOLUCAO.UR_DESC AS [DESCRICAO]," + CRLF
cQryTRB+= " 	COALESCE((SELECT UQ_GRPATEN+U0_NOME  "+ CRLF
cQryTRB+= " 	FROM "+ RetSqlName("SUQ") +" (NOLOCK) SUQ  "+ CRLF
cQryTRB+= " 	INNER JOIN "+ RetSqlName("SU0") +" (NOLOCK) SU0 ON  "+ CRLF
cQryTRB+= " 		SU0.U0_FILIAL = '" + xFilial("SU0") + "'"+ CRLF
cQryTRB+= " 		AND SU0.U0_CODIGO = SUQ.UQ_GRPATEN  "+ CRLF
cQryTRB+= " 		AND SU0.D_E_L_E_T_=''  "+ CRLF
cQryTRB+= " 	WHERE  "+ CRLF
cQryTRB+= " 		SUQ.UQ_FILIAL = '" + xFilial("SUQ") + "'"+ CRLF
cQryTRB+= " 		AND SUQ.UQ_SOLUCAO=SOLUCAO.UR_CODSOL  "+ CRLF
cQryTRB+= " 		AND SUQ.UQ_GRPATEN<>''  "+ CRLF
cQryTRB+= " 		AND SUQ.D_E_L_E_T_=''),'') AS [GRPRESP],  "+ CRLF
cQryTRB+= " 	OCORRENCIA.U9_XGRPRES+GRPRESP.U0_NOME  AS [GRPRESP2],  "+ CRLF
cQryTRB+= " 	UR_IDTREE AS [IDTREE], UR_IDCODE AS [IDCODE]  "+ CRLF
cQryTRB+= " FROM "+ RetSqlName("SU9") +" (NOLOCK) OCORRENCIA "+ CRLF
cQryTRB+= " INNER JOIN "+ RetSqlName("SX5") +" (NOLOCK) ASSUNTO ON "+ CRLF
cQryTRB+= " 	ASSUNTO.X5_FILIAL = '" + xFilial("SX5") + "'"+ CRLF
cQryTRB+= " 	AND ASSUNTO.X5_TABELA='T1'"+ CRLF
cQryTRB+= " 	AND ASSUNTO.X5_CHAVE=OCORRENCIA.U9_ASSUNTO"+ CRLF
cQryTRB+= " 	AND ASSUNTO.D_E_L_E_T_ = '' "+ CRLF
cQryTRB+= " INNER JOIN "+ RetSqlName("SUR") +"  (NOLOCK) SOLUCAO ON " + CRLF
cQryTRB+= " 	SOLUCAO.UR_FILIAL = '" + xFilial("SUR") + "'"+ CRLF
cQryTRB+= " 	AND SOLUCAO.UR_CODSOL <> '' " + CRLF
cQryTRB+= " 	AND SOLUCAO.UR_CODREC = OCORRENCIA.U9_CODIGO " + CRLF
If !Empty(cPar03)
	cQryTRB+= " 	AND (" + CRLF
	cQryTRB+= " 		SOLUCAO.UR_CODREC LIKE '%"+ Alltrim(cPar03)+"%' " + CRLF
	cQryTRB+= " 	OR
	cQryTRB+= " 		SOLUCAO.UR_DESC LIKE '%"+ Alltrim(cPar03)+"%' " + CRLF
	cQryTRB+= " 	)" + CRLF
Endif
cQryTRB+= " 	AND SOLUCAO.D_E_L_E_T_ = '' " + CRLF
cQryTRB+= " LEFT JOIN "+ RetSqlName("SU0") +" (NOLOCK) GRPRESP ON " + CRLF 
cQryTRB+= " 	GRPRESP.U0_FILIAL =  '" + xFilial("SU0") + "' " + CRLF
cQryTRB+= " 	AND GRPRESP.U0_CODIGO= OCORRENCIA.U9_XGRPRES " + CRLF
cQryTRB+= " 	AND GRPRESP.D_E_L_E_T_ = '' " + CRLF 
cQryTRB+= " WHERE " + CRLF
cQryTRB+= " 	OCORRENCIA.U9_FILIAL = '" + xFilial("SU9") + "' " + CRLF
cQryTRB+= " 	AND OCORRENCIA.U9_ASSUNTO = '" + cPar01 + "' " + CRLF
cQryTRB+= " 	AND OCORRENCIA.U9_CODIGO = '" + cPar02 + "' " + CRLF
cQryTRB+= " 	AND OCORRENCIA.U9_VALIDO = '1' " + CRLF
cQryTRB+= " 	AND OCORRENCIA.D_E_L_E_T_ = '' "+ CRLF
cQryTRB+= " ORDER BY " + CRLF
cQryTRB+= " 	SOLUCAO.UR_CODSOL, SOLUCAO.UR_DESC  " + CRLF


cArqTRB:=GetNextAlias()
DbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryTRB),cArqTRB,.F.,.T.)

	
DbSelectArea(cArqTRB)
(cArqTRB)->(DbGoTop())
If (cArqTRB)->(!Eof())
	Do While (cArqTRB)->(!Eof())
		cCodigo:= ""
		cDescr:= ""
		If !Empty((cArqTRB)->GRPRESP)
			cCodigo	:= Alltrim(SUBSTR((cArqTRB)->GRPRESP,1,2))
			cDescr	:= Alltrim(SUBSTR((cArqTRB)->GRPRESP,3,TAMSX3("U0_NOME")[1]))
		Else
			cCodigo	:= Alltrim(SUBSTR((cArqTRB)->GRPRESP2,1,2))
			cDescr	:= Alltrim(SUBSTR((cArqTRB)->GRPRESP2,3,TAMSX3("U0_NOME")[1]))		
		Endif
	 	aAdd(aRet,{ Alltrim((cArqTRB)->CODIGO),Alltrim((cArqTRB)->DESCRICAO), cCodigo, cDescr, (cArqTRB)->IDTREE,(cArqTRB)->IDCODE})
		(cArqTRB)->(DbSKip())
	End
Endif
If Select(cArqTRB) >  0
	DbSelectArea(cArqTRB)
	(cArqTRB)->(DbCloseArea())
Endif
Return aRet

/*User Function SUDF3()
	Local oDlgSu9														// Tela
	Local oLbx1                                                         // Listbox
	Local nPosLbx  := 0                                                 // Posicao do List
	Local aItems   := {}                                                // Array com os itens
	Local nPos     := 0                                                 // Posicao no array
	Local nPAssunto:= 0													// Assunto
	Local cAssunto := ""                                                // Descricao do Assunto
	Local lRet     := .F.                                               // Retorno da funcao
	Local lTkSU9FIL:= ExistBlock("TKSU9FIL")							// Ponto de Entrada para filtrar as ocorr?cias
	Local aRetSU9Filt 													// Retorno do Ponto de Entrada

	CursorWait()     

	If Type("aHeader") == "U"
		cAssunto := M->UD_ASSUNTO
	Else
		nPAssunto := Ascan(aHeader,{|x| AllTrim(x[2])=="UD_ASSUNTO"})

		If (nPAssunto == 0)
			cAssunto := M->ADE_ASSUNT
		Else
			cAssunto := Acols[n][nPAssunto]	
		Endif
	EndIf

	aItems := RetornaSUDF3()

	CursorArrow()
			
	If Len(aItems) <= 0
	Help(" ",1,"FALTA_OCOR")
	Return(lRet)
	Endif	
		
	DEFINE MSDIALOG oDlgSu9 FROM  50,003 TO 260,500 TITLE "Assuntos" PIXEL  //"Ocorrencias Relacionadas" 

		@ 03,10 LISTBOX oLbx1 VAR nPosLbx FIELDS HEADER ;
				"Codigo",;
				"Descricao",;
				SIZE 233,80 OF oDlgSu9 PIXEL NOSCROLL
		oLbx1:SetArray(aItems)
		oLbx1:bLine:={||{aItems[oLbx1:nAt,1],;
						aItems[oLbx1:nAt,2] }}

		oLbx1:BlDblClick := {||(lRet:= .T.,nPos:= oLbx1:nAt, oDlgSu9:End())}
		oLbx1:Refresh()
		
		DEFINE SBUTTON FROM 88,175 TYPE 1 ENABLE OF oDlgSu9 ACTION (lRet:= .T.,nPos := oLbx1:nAt,oDlgSu9:End())
		DEFINE SBUTTON FROM 88,210 TYPE 2 ENABLE OF oDlgSu9 ACTION (lRet:= .F.,oDlgSu9:End())

	ACTIVATE MSDIALOG oDlgSu9 CENTERED

	If lRet
	DbSelectarea("SU5")
	DbSetorder(1)
	IF SX5->(DbSeek(xFilial("SU5")+"T1"+aItems[nPos][1]))
		M->UD_ASSUNTO := SX5->X5_CHAVE
	ENDIF
	Endif

Return lRet*/

/*
	timoteo.bega
	19-07-2019
	Janela de filtro para a consulta padrao especifica XSUD de assuntos do SIGATMK
*/
User Function F3SUD()
	Local aLista	:= {}
	Local lRet		:= .F.
	Local nPos		:= 0
	Local nCodAss	:= 0
	Local nCodOcor	:= 0
	Local nCodResp	:= 0
	Local cBtnCss	:= "QPushButton{"+ Alltrim(SuperGetMv("ES_BRWBTN1",.F.,"background-image:url(rpo:backgroundblue.png); color: white;")) + "border-radius: 5px; margin: 2px  }"
	Local cBtnCss2	:= "QPushButton{"+ Alltrim(SuperGetMv("ES_BRWBTN2",.F.,"background-color:lightgrey; color: white;")) + " border-radius: 5px; margin: 2px  }"
	Local cAssunto	:= ""
	Local cOcorr	:= ""
	Local cGrpResp 	:= ""
	Local cTexto	:= Space(100)
	Local oDlg, oLista, oTexto, oSearch, oConfirma, oExit

	aLista	:= RetornaSUDF3()
	If Len(aLista) > 0
		DEFINE DIALOG oDlg TITLE "Assunto" FROM 180,180 TO 550,900 PIXEL STYLE DS_MODALFRAME   
		
		oTexto := TGet():New( 012,010,{|u| if( Pcount( )>0, cTexto:= u,cTexto ) },oDlg,300,009,"@!",{|| .T. /*Validacao*/},0,,,.F.,,.T.,,.F.,;
		{|| .T./*bWhen*/},.F.,.F.,{|| .T./*bChange*/},.F./*ReadOnly*/,.F.,,"cTexto",,,,.F.,,,,,,,"Filtro",,.T.)
		oSearch:= TButton():New( 010, 300, "Pesquisar" , oDlg,{|| ( aLista	:= RetornaSUDF3(cTexto), oLista:aArray:= aLista, oLista:Refresh()) },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
		oSearch:SetCss(cBtnCss)
		
		oLista := TCBrowse():New( 030, 010,340,125,,{"Codigo","Descricao"},{40,100},oDlg,,,,,{|| },,,,,,,.F.,,.T.,,.F.,,.T.,.T.)        
		oLista:SetArray(aLista)
		oLista:bLine          := {|| {;
		aLista[oLista:nAt][1],;     
		aLista[oLista:nAt][2]}}
		oLista:bLDblClick   := {|| (nPos:= oLista:nAt,oDlg:End() )}
		
		oConfirma:= TButton():New( 160, 250, "Confirma" , oDlg,{|| (nPos:= oLista:nAt,oDlg:End()) },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
		oConfirma:SetCss(cBtnCss)
		
		oExit	:= TButton():New( 160, 300, "Cancela"  , oDlg,{||  oDlg:End() },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
		oExit:SetCss(cBtnCss)
		
		oDlg:lEscClose:= .F.
		
		ACTIVATE DIALOG oDlg CENTERED
	
		If nPos>0 .And. Len(aLista) > 0
			DbSelectArea("SX5")
			SX5->(DbSetOrder(1))
			If SX5->( DbSeek(xFilial("SX5")+"T1"+aLista[nPos][1] ))
				lRet:= .T.
			Endif
		Endif
	Else	
		MessageBox("Solucao não cadastrada","Atendimento",MB_ICONASTERISK)
	Endif

Return lRet

/*
	timoteo.bega
	19-07-2019
	Busca dados para a consulta padrao especifica XSUD de assuntos do SIGATMK
*/
Static Function RetornaSUDF3(cDescri)
	Local csql		:= ""
	Local cAliTrb	:= GetNextAlias()
	Local aAssunto	:= {}
	Default cDescri	:= ""

	cSql := "SELECT X5_CHAVE, X5_DESCRI FROM " + RetSqlName("SX5") + " WHERE X5_FILIAL = '" + xFilial("SX5") + "' AND X5_TABELA = 'T1' AND X5_CHAVE >= '000011' AND D_E_L_E_T_ = ''"
	If !Empty(cDescri)
		cSql += " AND X5_DESCRI LIKE '%" + AllTrim(cDescri) + "%' "
	EndIf
	cSql := ChangeQuery(csql)
	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cSQL),cAliTrb,.F.,.T.)

	If (cAliTrb)->(!Eof())

		While (cAliTrb)->(!Eof())

			aAdd(aAssunto,{(cAliTrb)->X5_CHAVE,(cAliTrb)->X5_DESCRI})
			(cAliTrb)->(DbSkip())

		EndDo

	Else
		aAdd(aAssunto,{"",""})
	EndIf

	(cAliTrb)->(dbCloseArea())

Return aAssunto//{x5_chave,x5_descri}

/*
	timoteo.bega
	22-07-2019
	Janela de filtro para a consulta padrao especifica XOCO de ocorrencias do SIGATMK
*/
User Function F3OCO()
	Local aLista	:= {}
	Local lRet		:= .F.
	Local nPos		:= 0
	Local nCodAss	:= 0
	Local nCodOcor	:= 0
	Local nCodResp	:= 0
	Local cBtnCss	:= "QPushButton{"+ Alltrim(SuperGetMv("ES_BRWBTN1",.F.,"background-image:url(rpo:backgroundblue.png); color: white;")) + "border-radius: 5px; margin: 2px  }"
	Local cBtnCss2	:= "QPushButton{"+ Alltrim(SuperGetMv("ES_BRWBTN2",.F.,"background-color:lightgrey; color: white;")) + " border-radius: 5px; margin: 2px  }"
	Local cAssunto	:= ""
	Local cOcorr	:= ""
	Local cGrpResp 	:= ""
	Local cTexto	:= Space(100)
	Local oDlg, oLista, oTexto, oSearch, oConfirma, oExit

	aLista	:= RetornaOCOF3("",@cAssunto)
	If Len(aLista) > 0
		DEFINE DIALOG oDlg TITLE "Ocorrencia x Assunto" FROM 180,180 TO 550,900 PIXEL STYLE DS_MODALFRAME   
		
		oTexto := TGet():New( 012,010,{|u| if( Pcount( )>0, cTexto:= u,cTexto ) },oDlg,300,009,"@!",{|| .T. /*Validacao*/},0,,,.F.,,.T.,,.F.,;
		{|| .T./*bWhen*/},.F.,.F.,{|| .T./*bChange*/},.F./*ReadOnly*/,.F.,,"cTexto",,,,.F.,,,,,,,"Filtro",,.T.)
		oSearch:= TButton():New( 010, 300, "Pesquisar" , oDlg,{|| ( aLista	:= RetornaOCOF3(cTexto,@cAssunto), oLista:aArray:= aLista, oLista:Refresh()) },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
		oSearch:SetCss(cBtnCss)
		
		oLista := TCBrowse():New( 030, 010,340,125,,{"Codigo","Descricao","Prazo"},{40,100},oDlg,,,,,{|| },,,,,,,.F.,,.T.,,.F.,,.T.,.T.)        
		oLista:SetArray(aLista)
		oLista:bLine          := {|| {;
		aLista[oLista:nAt][1],;     
		aLista[oLista:nAt][2]}}
		oLista:bLDblClick   := {|| (nPos:= oLista:nAt,oDlg:End() )}
		
		oConfirma:= TButton():New( 160, 250, "Confirma" , oDlg,{|| (nPos:= oLista:nAt,oDlg:End()) },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
		oConfirma:SetCss(cBtnCss)
		
		oExit	:= TButton():New( 160, 300, "Cancela"  , oDlg,{||  oDlg:End() },050,015,,,.F.,.T.,.F.,,.F.,,,.F. )
		oExit:SetCss(cBtnCss)
		
		oDlg:lEscClose:= .F.
		
		ACTIVATE DIALOG oDlg CENTERED
	
		If nPos>0 .And. Len(aLista) > 0
			DbSelectArea("SU9")
			SU9->(DbSetOrder(1))//Filial+Assunto+Codigo
			If SU9->( DbSeek(xFilial("SU9")+cAssunto+aLista[nPos][1] ))
				lRet:= .T.
			Endif
		Endif
	Else	
		MessageBox("Solucao não cadastrada","Atendimento",MB_ICONASTERISK)
	Endif

Return lRet

/*
	timoteo.bega
	22-07-2019
	Busca dados para a consulta padrao especifica XOCO de ocorrencias do SIGATMK
*/
Static Function RetornaOCOF3(cDescri,cAssunto)
	Local csql		:= ""
	Local cAliTrb	:= GetNextAlias()
	Local aOcorren	:= {}
	Local nPos		:= 0
	Default cDescri	:= ""
	Default cAssunto:= ""

	If ValType( aHeader) == "A" .And. Len( aHeader[1]) >= 2 
		nPos := AScan(aHeader,{|x| AllTrim(x[2])=="UD_ASSUNTO"})
		cAssunto := aCols[Len(aCols),nPos]
	EndIf

	cSql := "SELECT U9_CODIGO, U9_DESC, U9_PRAZO FROM " + RetSqlName("SU9") + " WHERE U9_FILIAL = '" + xFilial("SU9") + "' AND U9_CODIGO <> '' "
	If !Empty(cAssunto)
		cSql += " AND U9_ASSUNTO = '" + AllTrim(cAssunto) + "' "
	EndIf
	If !Empty(cDescri)
		cSql += " AND U9_DESC LIKE '%" + AllTrim(cDescri) + "%' "
	EndIf
	cSql += " AND U9_VALIDO = '1' AND D_E_L_E_T_ = ''"
	cSql := ChangeQuery(csql)
	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cSQL),cAliTrb,.F.,.T.)

	If (cAliTrb)->(!Eof())

		While (cAliTrb)->(!Eof())

			aAdd(aOcorren,{(cAliTrb)->U9_CODIGO,(cAliTrb)->U9_DESC,(cAliTrb)->U9_PRAZO})
			(cAliTrb)->(DbSkip())

		EndDo

	Else
		aAdd(aOcorren,{"","",""})
	EndIf

	(cAliTrb)->(dbCloseArea())

Return aOcorren//{U9_CODIGO, U9_DESC, U9_PRAZO}