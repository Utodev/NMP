PROGRAM NMC;

USES CRT,DOS;

{$R-}
{$B-}
{$I-}
{$M 65000, 0, 655350}

{$I ODDSTR.PAS}

procedure RemoveSpaces(VAR S:String);
begin
 while Pos(' ',S) > 0 do S:=Copy(S,1,Pos(' ',S)-1)+ Copy(S,Pos(' ',S)+1,255);
end;


PROCEDURE XORST(VAR S:STRING);
VAR I:Byte;
BEGIN
  FOR I:=1 TO Byte(S[0]) DO byte(S[I]):=byte(S[I]) XOR 71;
END;

VAR FIDX:FILE OF LONGINT;
    FPAK:FILE;
    NumWrites:Longint;
    ActualOffset:Longint;

CONST flip:ARRAY[0..3] OF Char=('\','≥','/','ƒ');
CONST fliptoca:byte=0;
      byte00:byte=0;

CONST NumConj=16;

TYPE CONMD=SET OF Byte;

CONST UsanFichero:CONMD=[98]+[79]+[175]+[172]+[174]+[66]+[171]+[200];
      Saltos:CONMD=[108]+[107]+[133..154]+[189..190];
      REP:Word=212;
      WRITE_:Word=276;

VAR BUCLE:Word;
    DATOSLEIDOS:Boolean;
    MaxError:Word;
    NumError:Word;

LABEL NEXT;

VAR TMP:Text;
    NumFiles:Word;
    ActualFile:String[12];


FUNCTION INN(X:Word;Q:CONMD):Boolean;
VAR A:Byte;
BEGIN
 a:=X AND $FF;
 INN:=A IN Q
END;

LABEL NExtLine,FIN,MACROLABEL,FIN2,Repe;
TYPE Labelitos=(lab,jmp);

VAR Sinon:Boolean; (* Indica si se est†n buscando synonim *)

CONST BuffSize=32768;

TYPE
BufferWr=Object

 Buff:ARRAY[0..BuffSize-1] OF Char;
 BuffPoi:Word;

 PROCEDURE Inicializar;
 PROCEDURE Escribir(VAR F:File;VAR A;Tam:Word);
 PROCEDURE Volcar(VAR F:File);

END;

PROCEDURE BufferWr.Inicializar;
BEGIN
 BuffPoi:=0
END;

PROCEDURE BufferWr.Escribir(VAR F:File;VAR A;Tam:Word);
BEGIN
 IF BuffPoi+Tam>BuffSize THEN BEGIN
                               BlockWrite(F,Buff,BuffPoi);
                               BuffPoi:=0
                              END;
 Move(A,Buff[BuffPoi],Tam);
 Inc(BuffPoi,Tam)
END;

PROCEDURE BufferWr.Volcar(VAR F:File);
BEGIN
 BlockWrite(F,Buff,BuffPoi);
 BuffPoi:=0
END;

TYPE
BufferRd=Object

 Buff:ARRAY[0..BuffSize-1] OF Char;
 BuffTam,BuffPoi:Word;

 PROCEDURE Inicializar(VAR F:File);
 PROCEDURE Leer(VAR F:File;VAR A;Tam:Word);
 FUNCTION EOFL(VAR F:File):Boolean;

END;

PROCEDURE BufferRd.Inicializar(VAR F:File);
BEGIN
 BuffPoi:=0;
 BlockRead(F,Buff,BuffSize,BuffTam);
END;

PROCEDURE BufferRd.Leer( VAR F:File; VAR A; Tam:Word );
VAR Aux:Word;
BEGIN
 IF Tam+BuffPoi>BuffTam THEN BEGIN
                              Aux:=BuffTam-BuffPoi;
                              Move(Buff[BuffPoi],Buff[0],Aux);
                              BlockRead(F,Buff[Aux],BuffSize-Aux,BuffTam);
                              Inc(BuffTam,Aux);
                              BuffPoi:=0
                             END;
 IF BuffPoi>=BuffTam THEN BEGIN
                           BlockRead(F,Buff,BuffSize,BuffTam);
                           BuffPoi:=0
                          END;
 Move(Buff[BuffPoi],A,Tam);
 Inc(BuffPoi,Tam)
END;

FUNCTION BufferRd.EOFL(VAR F:File):Boolean;
VAR Aux:Boolean;
BEGIN
 Aux:=(EOF(F) AND (BuffPoi>=BuffTam));
 EOFL:=Aux;
END;



FUNCTION LowCase(C:Char):Char;forward;


{ LOS TIPOS DE PARAMETRO SON:

  1:  0-255
  2:  0-254
  3:  0-65535
  4:  palabra
  5:  0-7
  6:  0-99
  7:  1-4
  8:  0-15
  9:  0-1
  }

  (* El tercer par†metro siempre es de tipo byte y siempre admite indirecci¢n *)


TYPE Voc=^Pal;
     String10=String[10];
     {$IFDEF ALCACHOFA}
     Palabra=String[16];
     {$else}
     Palabra=String[5];
     {$endif}
     Palabra2=String[4];
     Pal=RECORD
          izq,der:Voc;
          P:Palabra;
          N:Byte;
         END;
     UnionPal=RECORD
               P:Palabra;
               N:Byte;
              END;

     ConstLoc=RECORD
               C:String[15];
               W:Word
              END;

     LabelLoc= RECORD
                L:palabra;
                FoundL,FoundJ:Boolean;
                Line:Word;
               END;

     HashTable=ARRAY [Byte] OF LABELLOC;
     HASHTable2=ARRAY [0..2047] OF ConstLoc;

     Enlace=^Condacto;
     Condacto=record
               word:String10;
               Code:Word;
               Pa:Palabra;
               izq,der:Enlace
              end;
VAR LOCALS:ARRAY[byte] OF Record
                           id:String[15];
                           value:word
                          END;
PROCEDURE NewLocals;
BEGIN
 FillChar(LOCALS,SizeOf(Locals),0);
END;




CONST CondLet : SET OF Char = ['a'..'z']+['A'..'Z'];
      LabelLet : SET OF Char = ['a'..'z']+['A'..'Z']+['§']+['•']+['á']+['Ä']+['0'..'9'];
      Numeros : SET OF Char =  ['0'..'9'];

VAR F:FILE;
    EndMacro:Word;
    Q:FILE ; (*PARA NOMBRE DE PROCEDIMIENTO*)
    Macro:Pointer;
    T:TEXT;
    Nombrado:Boolean;
    S:String;
    ST:String10;
    Done:Boolean;
    Esta:Boolean;
    C:Char;
    V,N,P:Voc;
    VC:FILE;
    IND0:Byte;
    MaxM:Word;
    MaxL,MaxO:Byte;
    Arbol:Enlace;
    Union:UnionPal;
    TipoParam:Char;
    I,J:Word;
    VV,NN,VV2:Palabra;
    parametro:String[16];(*15+1 por si hay un @ *)
    CC:String[10];
    FF:Byte;
    K,M:Byte;
    Flags:Palabra;
    Code:Word;
    Labels:HashTable;
    Consts:HashTable2;
    XVAL:LongInt;
    ErrorCode:Integer;
    L:Word;
    BW:^BufferWr;
    BR:^BufferRd;

{$I CURSOFF.SRC}

TYPE TError=RECORD
             Fichero:String[12];
             Info:String[80];
             Line:LongInt;
            END;
VAR FError:File OF TError;


PROCEDURE Error(FICH:String;N:String;Lin:Word);
VAR E:TError;
BEGIN
 E.Fichero:=Fich;
 E.Info:=N;
 E.Line:=Lin;
 Write(FError,E);
 INC(NumError);
 Close(FError);
 Close(TMP);
 Halt;
END;

PROCEDURE NewConst(S:String);
VAR S1,S2:String;
    code:integer;
    valor:word;
    I:Word;
BEGIN
 RemoveSpaces(S);
 IF Pos(';',s)<>0 THEN S:=Copy(S,1,Pos(';',S)-1);
 IF Pos('=',s)=0 THEN Error(ActualFile,'Definici¢n incorrecta',L);
 S1:=Copy(S,1,Pos('=',S)-1);
 S2:=Copy(S,Pos('=',S)+1,255);
 WHILE (byte(S1[0])<>0) AND (S1[1]=' ') DO S1:=Copy(S1,2,255);
 WHILE (byte(S2[0])<>0) AND (S2[1]=' ') DO S2:=Copy(S2,2,255);
 WHILE (byte(S2[0])<>0) AND (S2[byte(S2[0])]=' ') DO DEC(byte(S2[0]));
 WHILE (byte(S1[0])<>0) AND (S1[byte(S1[0])]=' ') DO DEC(byte(S1[0]));
 IF (S1='') OR (S2='') THEN Error(ActualFile,'Definici¢n incorrecta',L);
 VAL (S2,Valor,code);
 IF Code<>0 THEN Error(Actualfile,'Entero fuera de rango',l);
 I:=0;
 WHILE (I<256) AND (LOCALS[I].ID<>'') DO INC(I);
 IF I=256 THEN Error(Actualfile,'Demasiadas constantes locales',l);
 WITH LOCALS[I] DO
 BEGIN
  Value:=valor;
  id:=S1
 END;
END;

FUNCTION IsLocal(S:String;VAR valor:Word):Boolean;
VAR I:Word;
BEGIN
 I:=0;
 WHILE (i<256) AND (LOCALS[I].id<>Copy(s,1,15)) AND (locals[i].id<>'') DO
  INC(I);
 IF (i=256) THEN IsLocal:=False
          ELSE IF LOCALS[I].id='' THEN IsLocal:=False
               ELSE BEGIN
                     Valor:=locals[i].value;
                     Islocal:=True
                    END
END;


PROCEDURE GetString(S:String);
VAR I:Byte;
LABEL OK;
BEGIN
 IF NumWrites=65535 THEN Error(ActualFile,'Demasiados textos en proceso',L);
 ClearOdd;
 I:=1;
 WHILE (I<=byte(S[0])) AND (S[I]<>'{') DO INC(I);
 IF I>byte(S[0]) THEN Error(ACtualFile,'El texto debe seguir a instrucci¢n WRITE entre llaves',L);
 INC(I);
 S:=Copy(S,I,255);
 WHILE S<>'' DO BEGIN
                 IF S[1]='}' THEN Goto OK;
                 AddOddStr(S[1]);
                 S:=COpy(S,2,255);
                END;
 Error(Actualfile,'Se espera ''}''.',L);
 OK:
 XOROddStr;
 Write(FIDX,ActualOffset);
 BlockWrite(FPAK,OddStr.len,2);
 BlockWrite(FPAK,OddStr.txt,OddStr.len);
 Inc(ActualOffset,OddStr.len+2);
 BW^.Escribir(F,Byte00,1); (* indirecci¢n *)
 BW^.Escribir(F,NumWrites,2);
 Inc(NumWrites);
END;

FUNCTION HASH(P:Palabra):Byte;
 BEGIN
  Hash:=Ord(P[1])*10 MOD 256
 END;

 FUNCTION HASH2(P:Palabra):Byte;
 BEGIN
  Hash2:=Ord(P[1])*10 MOD 2048
 END;

PROCEDURE INITHASH;
VAR I:Byte;
BEGIN
 FOR I:=0 TO 255 DO BEGIN
                     Labels[I].L:='';
                     Labels[I].FoundL:=False;
                     Labels[I].FoundJ:=False;
                    END;
END;

PROCEDURE INITHASH2;
VAR I:Word;
BEGIN
 FOR I:=0 TO 2047 DO BEGIN
                     Consts[I].C:='';
                     Consts[I].W:=0;
                    END;
END;



PROCEDURE InsertHash(P:Palabra;La:Labelitos);
VAR Inicial,Svae:Byte;
BEGIN
 Svae:=Hash(p);
 Inicial:=Svae+1;
 WHILE (Inicial<>Svae) AND (Labels[Inicial].L<>'') AND (Labels[Inicial].L<>P)
  DO Inicial:=(Inicial+1) MOD 256;

 IF (Labels[Inicial].L=P) AND Labels[Inicial].FoundL AND (La=Lab) THEN BEGIN
                                                                        Error(ActualFile,'Etiqueta duplicada',L);
                                                                        Exit
                                                                       END;

 IF (Labels[Inicial].L=P) AND (La=Lab) THEN BEGIN
                                          Labels[Inicial].FoundL:=True;
                                          Exit
                                         END;
 IF (Labels[Inicial].L=P) AND (La=JMP) THEN BEGIN
                                          Labels[Inicial].FoundJ:=True;
                                          Exit
                                         END;
 IF Labels[Inicial].L='' THEN BEGIN
                               Labels[Inicial].L:=P;
                               Labels[Inicial].Line:=L;
                               Labels[Inicial].FoundL:=La=Lab;
                               Labels[Inicial].FoundJ:=La=Jmp;
                               Exit
                              END;
 IF Svae=Inicial THEN BEGIN
                       Error(ActualFile,'Demasiadas etiquetas',L);
                       Exit
                      END;
END;

FUNCTION InsertHash2(P:String;W:Word):Boolean;
VAR Inicial,INi0:Byte;
BEGIN
 InsertHash2:=False;
 Ini0:=Hash2(p);
 Inicial:=Ini0+1;
 WHILE (Consts[Inicial].C<>'') AND (Consts[Inicial].C<>P) AND (Inicial<>Ini0)
  DO Inicial:=(Inicial+1) MOD 2047;
 IF (Inicial=Ini0) OR (Consts[Inicial].C=P) THEN BEGIN
                                InsertHash2:=True; (* llena o repetida *)
                                Exit;
                               END;
 IF Consts[Inicial].C='' THEN BEGIN
                               Consts[Inicial].C:=P;
                               Consts[Inicial].W:=W;
                               Exit
                              END;
END;

FUNCTION EsPalabra(A:Voc; P:Palabra; VAR N:Byte):Boolean; forward;


FUNCTION LookFor(PS:String;VAR B:Boolean):Word;
VAR Inicial,Svae:Byte;
    P2:palabra;
    W:Byte;
    Valor:word;
BEGIN
 B:=True;
 IF IsLocal(PS,Valor) THEN BEGIN
                            LookFor:=valor;
                            Exit
                           END;
 Svae:=Hash2(pS);
 Inicial:=Svae+1;
 WHILE (Inicial<>Svae) AND (Consts[Inicial].C<>'') AND (Consts[Inicial].C<>PS)
  DO Inicial:=(Inicial+1) MOD 2048;
 IF (Consts[Inicial].C=PS) THEN BEGIN
                                LookFor:=Consts[Inicial].W;
                                Exit
                               END;
 P2:=PS;
 IF Espalabra(v,P2,W) THEN BEGIN
                             LookFor:=W;
                             Exit
                            END;
 IF Espalabra(n,P2,W) THEN BEGIN
                             LookFor:=W;
                             Exit
                            END;
 IF Espalabra(p,P2,W) THEN BEGIN
                             LookFor:=W;
                             Exit
                            END;
 B:=False;
END;

FUNCTION GetMaxObj:Word;
VAR F:FILE;
BEGIN
 Assign(F,'ADV\O.DAT');
 Reset(F,1);
 GetMaxObj:=FileSize(F) DIV 51-1;
 Close(F);
END;

FUNCTION GetMaxLoc:Word;
VAR F:FILE;
BEGIN
 Assign(F,'ADV\L.DAT');
 Reset(F,1);
 GetMaxLoc:=FileSize(F) DIV (2+1024+256)-1;
 Close(F);
END;

PROCEDURE LeerConst;
VAR T:Text;
    S:string;
    p1,p2:String;
    w:Word;
    I:Byte;
    Code:Integer;
    L:Word;
LABEL SIGUE;
BEGIN
 Assign(T,'C.DAT');
 Reset(T);
 L:=0;
 ExitCode:=1;
 WHILE NOT EOF(T) DO
  BEGIN
   ReadLn(T,P1);
   RemoveSpaces(P1);
   FOR I:=1 TO Length(P1) DO P1[I]:=LowCase(p1[I]);
   Inc(L);
   IF Pos(';',P1)<>0 THEN P1:=Copy(p1,1,Pos(';',P1)-1);
   WHILE (byte(P1[0])>0) AND (P1[1]=' ') DO P1:=Copy(P1,2,255);
   WHILE (byte(P1[0])>0) AND (P1[byte(P1[0])]=' ') DO DEC(byte(P1[0]));
   IF p1<>'' THEN BEGIN
                   IF (Pos('=',P1)=0) THEN BEGIN
                                            Error('C.DAT','Constante err¢nea',L);
                                            Goto sigue;
                                           END;

                   P2:=Copy(P1,Pos('=',P1)+1,255);
                   IF P2='' THEN Error('C.DAT','Valor de constante omitido',L);
                   WHILE (byte(P2[0])>0) AND (P2[1]=' ') DO P2:=Copy(P2,2,255);
                   IF P2='' THEN Error('C.DAT',' Valor de constante omitido',L);
                   VAL(P2,W,Code);
                   IF Code<>0 THEN Error('C.DAT','Entero fuera de rango',L);
                   P1:=Copy(P1,1,Pos('=',P1)-1);
                   IF P1='' THEN Error('C.DAT','Nombre de constante omitido',L);
                   WHILE (byte(P1[0])>0) AND (P1[1]=' ') DO P1:=Copy(P2,2,255);
                   IF P1='' THEN Error('C.DAT',' Nombre de constante omitido',L);
                   IF InsertHash2(P1,W) THEN Error('C.DAT','Demasiadas constantes o constante repetida',L);
                  END;
  Sigue:
  END;
Close(T);
InsertHash2('max_obj',getmaxObj);
InsertHash2('max_loc',getmaxloc);
ExitCode:=0;
END;

PROCEDURE Insertar (VAR P:Enlace;
                   W:String10;
                   C:Word;Pa:Palabra);
BEGIN
 IF P=NIL THEN BEGIN
                New(P);
                P^.Word:=W;
                P^.Code:=C;
                P^.Pa:=Pa;
                P^.der:=NIL;
                P^.izq:=NIL
               END
 ELSE IF P^.Word>W THEN Insertar(P^.izq,W,C,pa) ELSE
      IF P^.Word<W THEN Insertar(P^.der,W,C,pa)
END;

FUNCTION EsCondacto(P:Enlace;S:String10;VAR Code:Word;VAR N:Palabra):Boolean;
BEGIN
IF P=NIL THEN Escondacto:=False
         ELSE
         IF S=P^.Word THEN BEGIN
                            Escondacto:=True;
                            Code:=P^.Code;
                            n:=p^.pa
                           END ELSE
         IF S>P^.Word THEN Escondacto:=escondacto(P^.der,s,code,n)
                      ELSE Escondacto:=escondacto(P^.izq,s,code,n)
END;

PROCEDURE LeerCondactos;
VAR I:Word;
    S:String10;
    Pa:Palabra;
    T:text;

BEGIN
 I:=0;
 Assign(T,'ADV\NMP.CON');
 reset(T);
 Arbol:=NIL;
 WHILE NOT EOF(T) DO
  BEGIN
   ReadLn(T,S);
   ReadLn(T,Pa);
   Insertar(Arbol,S,I,Pa);
   Inc(I)
  END;
 Close(T)
END;


PROCEDURE INCLUIR(VAR A:Voc; P:Palabra; N:Byte);
 BEGIN
  IF A=NIL THEN BEGIN
                 new(A);
                 A^.izq:=NIL;
                 A^.Der:=NIL;
                 A^.P:=P;
                 A^.N:=N
                END
            ELSE IF P>A^.P THEN Incluir(A^.der,p,n)
                           ELSE Incluir(A^.izq,p,n)
 END;

FUNCTION EsPalabra(A:Voc; P:Palabra; VAR N:Byte):Boolean;
 BEGIN
  IF A=NIL THEN EsPalabra:=FALSE
           ELSE IF A^.P=P THEN BEGIN
                                EsPalabra:=TRUE;
                                N:=A^.N;
                               END
           ELSE IF A^.P>P THEN EsPalabra:=EsPalabra(A^.izq,P,N)
                          ELSE EsPalabra:=EsPalabra(A^.der,P,N)
 END;


FUNCTION LowCase(C:Char):Char;
 BEGIN
  Case C OF
   'A'..'Z':LowCase:=CHR(Ord(C)+32);
   '•':Lowcase:='§';
   'Ä':Lowcase:='á';
   '°':Lowcase:='i';
   'Ç':Lowcase:='e';
   '†':Lowcase:='a';
   '¢':Lowcase:='o';
   '£':Lowcase:='u';
   'Å':Lowcase:='u';
   'ö':Lowcase:='u';
   'ê':Lowcase:='e';
   ELSE LowCase:=C
  END;
 END;

PROCEDURE SINTAXIS;
BEGIN
 WriteLn('NM Compiler Pro, por Carlos S†nchez.');
 WriteLn('Este fichero forma parte del entorno de');
 WriteLn('NMP y no debe ser utilizado desde la l°nea');
 WriteLn('de comandos.');
 Halt;
END;

VAR VOCXORED:Boolean;

BEGIN (*PRINCIPAL*)
 DatosLeidos:=False;
 IF ParamStr(2)<>'CSG' THEN SINTAXIS;
 NumError:=0;
 GetMem(BR,SizeOf(BufferRd));
 GetMem(BW,SizeOf(BufferWr));
 ExitCode:=0;
 CheckBreak:=False;
 EndMacro:=184;
 Nombrado:=False;
 VAL(ParamStr(1),NumFiles,Integer(code));
 Assign(FError,'ERROR.TMP');
 Rewrite(FError);
 Assign(TMP,'NMC.TMP');
 Reset(TMP);
 FOR BUCLE:=1 TO NumFiles DO
 BEGIN
 ReadLn(TMP,ActualFile);
 IF NOT DatosLeidos THEN LeerCondactos;
 InitHash;
 IF NOT DATOSLEIDOS THEN BEGIN
                          InitHash2;
                          LeerConst;
                         END;
 FF:=$FF;
 CurSorOff;
 IF NOT DATOSLEIDOS THEN
  BEGIN
   V:=NIL;
   N:=NIL;
   P:=NIL;
   (*PROCEDO A LA LECTURA DE VOCABULARIO*)
   VocXored:=False;
   Assign(VC,'ADV\V.DAT');
   Reset(VC,1);
   IF IOresult<>0 THEN BEGIN
                        Assign(VC,'ADV\V.DTT');
                        Reset(VC,1);
                        VocXored:=True;
                       END;
   br^.Inicializar(VC);
   WHILE NOT br^.EOFL(VC) DO BEGIN
                              br^.Leer(VC,Union,SizeOf(Union));
                              Write(flip[fliptoca]);Gotoxy(wherex-1,wherey);inc(fliptoca);if fliptoca=4 then fliptoca:=0;
                              IF VOCXORED THEN XORST(Union.P);
                              Incluir(V,Union.P,Union.N)
                             END;
   Close(VC);
   Assign(VC,'ADV\N.DAT');
   Reset(VC,1);
   IF IOresult<>0 THEN BEGIN
                        Assign(VC,'ADV\N.DTT');
                        Reset(VC,1);
                       END;
   br^.Inicializar(VC);
   WHILE NOT br^.EOFL(VC) DO BEGIN
                             br^.Leer(VC,Union,SizeOf(Union));
                             Write(flip[fliptoca]);Gotoxy(wherex-1,wherey);inc(fliptoca);if fliptoca=4 then fliptoca:=0;
                             IF VOCXORED THEN XORST(Union.P);
                             Incluir(N,Union.P,Union.N)
                            END;
   Close(VC);


   Assign(VC,'ADV\P.DAT');
   Reset(VC,1);
   IF IOresult<>0 THEN BEGIN
                        Assign(VC,'ADV\P.DTT');
                        Reset(VC,1);
                       END;
   br^.Inicializar(VC);
   WHILE NOT br^.EOFL(VC) DO BEGIN
                             br^.Leer(VC,Union,SizeOf(Union));
                             IF VOCXORED THEN XORST(Union.P);
                             Write(flip[fliptoca]);Gotoxy(wherex-1,wherey);inc(fliptoca);if fliptoca=4 then fliptoca:=0;
                             Incluir(P,Union.P,Union.N)
                            END;
   Close(VC);
  END;

 (* Y A COMPILAR *)
 DatosLeidos:=True;
 Assign(T,ActualFile);
 Reset(T);
 IF EOF(T) THEN BEGIN      (* Si el fichero est† vac°o lo borro *)
                 Close(T);
                 Erase(T);
                 Goto Next;
                END;
 IF Pos('.MAC',ActualFile)=0 THEN Assign(F,'ADV\'+Copy(ActualFile,1,Pos('.',ActualFile)-1)+'.XMP')
                              ELSE BEGIN
                                    Assign(F,Copy(ActualFile,1,Pos('.',ActualFile)-1)+'.MCP');
                                    Rewrite(F,1);
                                    bw^.Inicializar;
                                    L:=0;
                                    GOTO MAcroLabel;
                                   END;


 (* Control de ficheros de WRITE *)
 ClearOdd;
 ActualOffset:=0;
 NumWrites:=0;
 IF ActualFile='R.NMP' THEN Assign(FIDX,'ADV\0.IDX') ELSE
  IF ActualFile='I.NMP' THEN Assign(FIDX,'ADV\64.IDX') ELSE
   Assign(FIDX,'ADV\'+Copy(ActualFile,1,Pos('.',Actualfile)-1)+'.IDX');
 ReWrite(FIDX);
 IF ActualFile='R.NMP' THEN Assign(FPAK,'ADV\0.PAK') ELSE
  IF ActualFile='I.NMP' THEN Assign(FPAK,'ADV\64.PAK') ELSE
   Assign(FPAK,'ADV\'+Copy(ActualFile,1,Pos('.',Actualfile)-1)+'.PAK');
 Rewrite(FPAK,1);


 NewLocals;
 Rewrite(F,1);
 bw^.Inicializar;
 Nombrado:=False;
 L:=0;
 WHILE NOT EOF(T) DO
  BEGIN
   NextLine:
   S:='';
   WHILE (S='') AND NOT EOF(T) DO
    BEGIN
     ReadLn(T,S);
     INC(L);
     S:=S+';';
     S:=Copy(S,1,Pos(';',S)-1);
        IF S<>'' THEN WHILE Pos(' ',S)=1 DO S:=Copy(S,2,length(S)-1);
    END;
    IF EOF(T) THEN Goto FIn;

    FOR I:=1 TO Length(S) DO S[I]:=LowCase(S[I]);
    IF (S[1]<>'-') AND (S[1]<>'\') AND (S[1]<>'#') THEN Error(ActualFile,'Se espera gui¢n o ''\''',L);
    IF (S[1]='#') THEN BEGIN
                        NewConst(Copy(S,2,255));
                        Goto NextLine
                       END;
    IF (S[1]='\') AND Nombrado THEN Error(ActualFile,'Un proceso no puede tener m†s de un nombre',L);
    IF s[1]='\' THEN BEGIN
                      ST:=Copy(s,2,10);
                      IF ST='' THEN Error(ActualFile,'Nombre de proceso incorrecto',L);
                      FOR I:=1 TO length(st) do st[i]:=UPCASE(ST[i]);
                      Assign(Q, Copy(ActualFile,1,Pos('.',ActualFile))+'PN');
                      Rewrite(Q,1);
                      BlockWrite(Q,St,11);
                      Close(Q);
                      Nombrado:=True;
                      GOTO NextLine;
                     END;

    REPE:
    Write(flip[fliptoca]);Gotoxy(wherex-1,wherey);inc(fliptoca);if fliptoca=4 then fliptoca:=0;
    IF Pos(' ',S)=0 THEN Error(ActualFile,'Debe especificar verbo y nombre',L);
    VV:=Copy(S,2,Pos(' ',S)-1);
    NN:=Copy(S,Pos(' ',S)+1,length(s));
    IF Pos(' ',NN)<>0 THEN NN:=Copy(NN,1,Pos(' ',NN)-1);   (*Por si hay espacios al final*)
    IF Pos(' ',VV)<>0 THEN VV:=Copy(VV,1,Pos(' ',VV)-1);   (*Por si hay espacios al final*)

    IF VV='*' THEN bw^.Escribir(F,FF,1)
              ELSE IF EsPalabra(V,VV,K) THEN bw^.Escribir(F,K,1)
                                        ELSE Error(ActualFile,'Verbo desconocido',L);
    IF NN='*' THEN bw^.Escribir(F,FF,1)
              ELSE IF EsPalabra(N,NN,K) THEN bw^.Escribir(F,K,1)
                                        ELSE Error(ActualFile,'Nombre desconocido',L);


    DONE:=False;
    SINON:=True;
    WHILE NOT DONE DO
     BEGIN
      S:='';
      WHILE (S='') AND NOT EOF(T) DO
       BEGIN
        ReadLn(T,S);
        S := S + ';';
        S := Copy(S,1,Pos(';',S)-1);
        IF S<>'' THEN WHILE Pos(' ',S)=1 DO S:=Copy(S,2,length(S)-1);
        INC(L);
       END;
      Write(flip[fliptoca]);Gotoxy(wherex-1,wherey);inc(fliptoca);if fliptoca=4 then fliptoca:=0;
      FOR I:=1 TO 5 DO IF Byte(S[0])>=I THEN S[I]:=LowCase(S[I]);
      IF Copy(S,1,5)<>'write' THEN
       FOR I:=6 TO byte(S[0]) DO S[I]:=LowCase(S[I]);
      S:=S+' ';
      IF (S[1]='-') AND Sinon THEN BEGIN
                                    bw^.Escribir(F,Rep,2);
                                    GOTO REPE
                                   END
                              ELSE Sinon:=False;
      IF (S[1]='-') AND NOT Sinon THEN Error(ActualFile,'Se espera comando',L);
      CC:=Copy(S,1,Pos(' ',S)-1);
      IF Pos(' ',S)>11 THEN Error(ActualFile,'Comando desconocido:'+CC,L);
      IF NOT EsCondacto(Arbol,CC,Code,flags)
         THEN Error(ActualFile,'Comando desconocido:'+CC,L);
      IF Code=184 THEN Error(ActualFile,'Comando desconocido:'+CC,L);
      bw^.Escribir(F,Code,2);
      S:=Copy(S,Pos(' ',S)+1,length(s));
      IF INN(Code,[58..59,172,174,183,233]) THEN S:=S+'0 ';
      IF Code=WRITE_ THEN GetString(S) ELSE
      FOR I:=1 TO ORD(Flags[1])-48 DO       (*VAMOS CON LOS PARAMETROS*)
       BEGIN
        IND0:=0;
        WHILE Pos(' ',S)=1 DO S:=Copy(S,2,length(S));
        IF S='' THEN Error(ActualFile,'Falta par†metro requerido',L);
        IF S[length(s)]<>' ' THEN S:=S+' ';
        Parametro:=Copy(S,1,Pos(' ',S)-1);
        IF I=1 THEN VV2:=Parametro;
        S:=Copy(S,Pos(' ',S),length(S));
        IF Parametro[1]='@' THEN BEGIN
                                  IF (i<=2) AND (Flags[3+I]='d') THEN
                                   Error(ActualFile,'La instrucci¢n no admite indirecci¢n en par†metro '+CHR(I+48),L);
                                   Parametro:=Copy(Parametro,2,255);
                                   IND0:=1;
                                  END;
        VAL(parametro,Xval,ErrorCode);
        bw^.Escribir(F,Ind0,1);

        IF (ErrorCode<>0) AND (Flags[1+i]<>'4') THEN XVal:=LookFor(parametro,Esta);
        IF Esta AND (Flags[1+i]<>'4') THEN ErrorCode:=0;
        IF (ErrorCode<>0) AND (Flags[1+i]<>'4') THEN Error(ActualFile,'Constante desconocida: '+Parametro,L);

        IF I=3 THEN TipoParam:='1' ELSE TipoParam:=Flags[I+1];
        CASE TipoParam OF
         '1':BEGIN
              IF (Ind0=1) AND (XVal>255) THEN Error(ActualFile,'N£mero de flag fuera de rango',L);
              IF (Ind0=0) AND (XVal>255) THEN Error(ActualFile,'Par†metro fuera de rango',L);
              bw^.Escribir(F,Xval,1);
             END;

         '2':BEGIN
              IF (Ind0=1) AND (XVal>255) THEN Error(ActualFile,'N£mero de flag fuera de rango',L);
              IF (Ind0=0) AND (XVal>254) THEN Error(ActualFile,'Par†metro fuera de rango',L);
              bw^.Escribir(F,Xval,1);
             END;

         '3':BEGIN
              IF (Ind0=1) AND (XVal>255) THEN Error(ActualFile,'N£mero de flag fuera de rango',L);
              IF (Ind0=0) AND (XVal>65535) THEN Error(ActualFile,'Par†metro fuera de rango',L);
              bw^.Escribir(F,Xval,2);
             END;
         '4':BEGIN
              IF INN(Code,saltos) THEN IF Code=108 THEN inserthash(VV2,Lab)
                                                   ELSE InsertHash(VV2,Jmp);
              bw^.Escribir(F,Parametro,6);
             END;
         '5':IF Xval>15 THEN Error(ActualFile,'N£mero de bit fuera de rango',l)
                       ELSE bw^.Escribir(F,Xval,1);
         '6':IF Xval>99 THEN Error(ActualFile,'Porcentaje fuera de rango',l)
                        ELSE bw^.Escribir(F,Xval,1);
         '7':IF NOT INN(Xval,[1..NumConj]) THEN BEGIN
                              IF INN(Code,[199..200]+[76]) THEN Error(ActualFile,'Buffer de icono err¢neo',l) ELSE
                              IF Code <51 THEN Error(ActualFile,'N£mero de pila err¢neo',l) ELSE
                              IF INN(Code,[56..57]) THEN
                              Error(ActualFile,'Numero de slot SAVEAT/BACKAT err¢neo',l) ELSE
                              IF Code >54 THEN Error(ActualFile,'N£mero de conjunto err¢neo',l)
                                          ELSE Error(ActualFile,'N£mero de cola err¢neo',l);
                             END
                        ELSE bw^.Escribir(F,Xval,1);
         '8':IF Xval>15 THEN Error(ActualFile,'N£mero de indicador fuera de rango',l)
                        ELSE bw^.Escribir(F,Xval,1);
         '9':IF Xval>1 THEN Error(ActualFile,'S¢lo se permite 0 ¢ 1 como par†metro',l)
                        ELSE bw^.Escribir(F,Xval,1);
        END;

     END; (*FOR I*)

     IF (Code=183) THEN BEGIN
                       Assign(Q,VV2+'.MCP');
                       Reset(Q,1);
                       IF IOResult<>0 THEN Error (ActualFile,'No se encuentra macro '+VV2,l);
                       GetMem(Macro,FileSize(Q));
                       BlockRead(Q,Macro^,FileSize(q));
                       bw^.Escribir(F,Macro^,FileSize(q));
                       bw^.Escribir(F,EndMacro,2);
                       FreeMem(Macro,FileSize(Q));
                       Close(q)
                      END;

     IF INN(Code,[93..97]) THEN Done:=True;
     IF EOF(T) AND NOT(Done) THEN Error(ActualFile,'Fin de Fichero Inesperado',L);

   END; {WHILE NOT DONE}

  END; {WHILE NOT EOF}
 FIN:
 CLOSE(T);
 bw^.Volcar(F);
 CLOSE(F);

 FOR I:=0 TO 255 DO
  IF (labels[I].L<>'') AND (labels[i].foundL<>Labels[i].FoundJ) THEN
   Error (ActualFile,'Etiqueta no definida o no utilizada:'+labels[i].L,Labels[i].Line);

 Close(FIDX);
 Close(FPAK);

 IF NumWrites=0 THEN BEGIN
                      Erase(FIDX);
                      Erase(FPAK);
                     END;
 Goto Next;

 MACROLABEL:

 WHILE NOT EOF(T) DO
     BEGIN
      S:='';
      WHILE (S='') AND NOT EOF(T) DO
       BEGIN
        ReadLn(T,S);
        S:=S+';';
        S:=Copy(S,1,Pos(';',S)-1);
        IF S<>'' THEN WHILE Pos(' ',S)=1 DO S:=Copy(S,2,length(S)-1);
        INC(L);
       END;
      IF EOF(T) AND (S='') THEN GOTO FIn2;
      FOR I:=1 TO Length(S) DO S[I]:=LowCase(S[I]);
      S:=S+' ';
      CC:=Copy(S,1,Pos(' ',S)-1);
      IF Pos(' ',S)>11 THEN Error(ActualFile,'Comando desconocido:'+Copy(S,1,Pos(' ',S)-1),L);
      IF NOT EsCondacto(Arbol,CC,Code,flags)
         THEN Error(ActualFile,'Comando desconocido:'+Copy(S,1,Pos(' ',S)-1),L);
      IF INN(Code,[93..97,183]) OR (Code=276) THEN Error(ActualFile,'Instrucci¢n no permitida en una macro',l);
      bw^.Escribir(F,Code,2);
      S:=Copy(S,Pos(' ',S)+1,length(s));
      IF INN(Code,[58..59,172,174,233]) THEN S:=S+'0 ';
      (*VAMOS CON LOS PARAMETROS*)
      FOR I:=1 TO ORD(Flags[1])-48 DO
       BEGIN
        IND0:=0;
        WHILE Pos(' ',S)=1 DO S:=Copy(S,2,length(S));
        IF S='' THEN Error(ActualFile,'Falta par†metro requerido',L);
        IF S[length(s)]<>' ' THEN S:=S+' ';
        Parametro:=Copy(S,1,Pos(' ',S)-1);
        S:=Copy(S,Pos(' ',S),255);
        IF I=1 THEN VV2:=Parametro;
        IF Parametro[1]='@' THEN BEGIN
                           IF (i<3) AND (Flags[3+I]='d') THEN
                            Error(ActualFile,'La instrucci¢n no admite indirecci¢n en par†metro '+CHR(I+48),L);
                           Parametro:=Copy(Parametro,2,255);
                           IND0:=1;
                          END;
        VAL(parametro,Xval,ErrorCode);

        bw^.Escribir(F,Ind0,1);
        IF (ErrorCode<>0) AND (Flags[1+i]<>'4') THEN XVal:=LookFor(Parametro,Esta);
        IF Esta AND (Flags[1+i]<>'4') THEN ErrorCode:=0;
        IF (ErrorCode<>0) AND (Flags[1+i]<>'4') THEN Error(ActualFile,'Constante desconocida: '+Parametro,L);
        IF I=3 THEN TipoParam:='1' ELSE TipoParam:=Flags[I+1];
        CASE TipoParam OF
         '1':BEGIN
              IF (Ind0=1) AND (XVal>255) THEN Error(ActualFile,'N£mero de flag fuera de rango',L);
              IF (Ind0=0) AND (XVal>255) THEN Error(ActualFile,'Par†metro fuera de rango',L);
              bw^.Escribir(F,Xval,1);
             END;

         '2':BEGIN
              IF (Ind0=1) AND (XVal>255) THEN Error(ActualFile,'N£mero de flag fuera de rango',L);
              IF (Ind0=0) AND (XVal>254) THEN Error(ActualFile,'Par†metro fuera de rango',L);
              bw^.Escribir(F,Xval,1);
             END;

         '3':BEGIN
              IF (Ind0=1) AND (XVal>255) THEN Error(ActualFile,'N£mero de flag fuera de rango',L);
              IF (Ind0=0) AND (XVal>65535) THEN Error(ActualFile,'Par†metro fuera de rango',L);
              bw^.Escribir(F,Xval,2);
             END;
         '4':BEGIN
              IF INN(Code,Saltos) THEN
              IF Code=108 THEN inserthash(VV2,Lab)
                          ELSE InsertHash(VV2,Jmp);
              bw^.Escribir(F,Parametro,6);
             END;
         '5':IF Xval>15 THEN Error(ActualFile,'N£mero de bit fuera de rango',l)
                       ELSE bw^.Escribir(F,Xval,1);
         '6':IF Xval>99 THEN Error(ActualFile,'Porcentaje fuera de rango',l)
                        ELSE bw^.Escribir(F,Xval,1);
         '7':IF NOT (Xval IN [1..4]) THEN BEGIN
                              IF INN(Code,[199..200]+[76]) THEN Error(ActualFile,'Buffer de icono err¢neo',l) ELSE
                              IF Code <51 THEN Error(ActualFile,'N£mero de pila err¢neo',l) ELSE
                              IF INN(Code,[56..57]) THEN
                              Error(ActualFile,'SAVEAT/BACKAT,par†metro ha de estar en rango 0-4',l) ELSE
                              IF Code >54 THEN Error(ActualFile,'N£mero de conjunto err¢neo',l)
                                          ELSE Error(ActualFile,'N£mero de cola err¢neo',l)
                             END
                        ELSE bw^.Escribir(F,Xval,1);
         '8':IF Xval>15 THEN Error(ActualFile,'N£mero de indicador fuera de rango',l)
                        ELSE bw^.Escribir(F,Xval,1);
         '9':IF Xval>1 THEN Error(ActualFile,'S¢lo pueden tener 0 ¢ 1 como par†metro',l)
                        ELSE bw^.Escribir(F,Xval,1);
        END;

     END; (*FOR I*)

   END; {WHILE NOT EOF}

 FOR I:=0 TO 255 DO
  IF (labels[I].L<>'') AND (labels[i].foundL<>Labels[i].FoundJ) THEN
   Error (ActualFile,'Etiqueta no definida o no utilizada:'+labels[i].L,Labels[i].Line);

FIN2:
Close(T);
bw^.Volcar(F);
Close(F);


NEXT:

END; (* FOR BUCLE *)
Close(Ferror);
Erase(FError); (* Si lleg¢ hasta aqu° no hubo error *)
END.
