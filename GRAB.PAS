

PROGRAM GRAB;
{$G+}

USES DOUBLE,EMUGRAPH,VGA256,MENUS,CRT,DOS,DIRLIST,PARACAJA,CHIPS,SAVEPCX,GIFUNIT,ILBM256,DEMOINIT;

TYPE SCREEN=ARRAY[0..63999] OF Byte;

{$I DESCART.SRC}

CONST PalS:ARRAY[0..47] OF Byte=
(0,0,0,0,0,48,48,0,0,48,0,48,0,48,0,0,48,48,48,48,0,48,48,48,
 7,7,7,0,0,63,63,0,0,63,0,63,0,63,0,0,63,63,63,63,0,63,63,63);


 PROCEDURE MODE(B:Word); Assembler;
 ASM
  MOV AX,B
  INT 10h
 END;

PROCEDURE RECTANGLE(X0,Y0,XF,YF:Word);
VAR I:Word;
BEGIN
  FillChar(Mem[$a000:320*Y0+X0],XF-X0+1,colors[1]);
  FillChar(Mem[$a000:320*YF+X0],XF-X0+1,colors[1]);
  FOR I:=Y0+1 TO YF-1 DO BEGIN
                          Mem[$a000:320*I+X0]:=colors[1];
                          Mem[$a000:320*I+XF]:=colors[1];
                         END;
END;


PROCEDURE PACKGRF(FileS:String);

VAR F:FILE;
VAR PALETA:ARRAY[0..767] OF Byte;
    An,Al:Word;
    KK:Byte;
    P,Q:Pointer;
    Result:word;


CONST REP1:Byte=$C1;
      TYPE Line=ARRAY[0..639] OF BYte; (* Una linea con mala compresi¢n a lo m s ocupar  el doble *)

PROCEDURE PACKLINE(VAR A,B:LINE;L1:Word;VAR L2:Word);
VAR Ant,Act,Rep:Byte;
    Count:Word;
    PTr:word;
BEGIN
 PTR:=0;
 Count:=0;
 Ant:=A[0] XOR $FF;
 REP:=0;
 WHILE COUNT<L1 DO
  BEGIN
   ACT:=A[Count];
   INC(Count);
   IF (ant=act) THEN BEGIN
                      INC(REP);
                      IF REP=63 THEN BEGIN
                                      B[PTR]:=REP OR $C0;
                                      B[PTR+1]:=Ant;
                                      rep:=0;
                                      INC(PTR,2);
                                     END;
                     END
                 ELSE IF REP>0 THEN
                        IF ((Ant AND $c0)=$C0) OR (REP>1) THEN BEGIN
                                                   B[PTR]:=REP OR $C0;
                                                   B[PTR+1]:=Ant;
                                                   REP:=1;
                                                   Ant:=Act;
                                                   INC(PTR,2);
                                                  END
                                             ELSE BEGIN
                                                   B[PTR]:=Ant;
                                                   Ant:=Act;
                                                   REP:=1;
                                                   INC(PTR)
                                                  END
                         ELSE BEGIN
                               Ant:=Act;
                               rep:=1
                              END;
  END;
 IF Boolean(REP) THEN
  IF ((Ant AND $c0)=$C0) OR (REP>1) THEN BEGIN
                                          B[PTR]:=REP OR $C0;
                                          B[PTR+1]:=Ant;
                                          INC(PTR,2);
                                         END
                                    ELSE BEGIN
                                          B[PTR]:=Ant;
                                          INC(PTR)
                                         END;
 L2:=PTR;
END;


CONST NP:Byte=0;
      SP:Byte=1;

PROCEDURE PACK;
VAR A,B:LINE;
    AR:Word;
    I:Word;

BEGIN
FOR I:=0 TO AL-1 DO
 BEGIN
  MOVE(pointer(longint(p)+an*I)^,A,an);
  PACKLINE(A,B,an,ar);
  IF Ar>=an THEN BEGIN
                  BlockWrite(F,NP,1);
                  BlockWrite(F,A,an);
                 END
            ELSE BEGIN
                  BlockWrite(F,SP,1);
                  BlockWrite(F,B,ar);
                 END;
 END;
END;

FUNCTION Getname(VAR F:FILE):String;
VAR P:^char;
    S:String;
    i:Byte;
BEGIN
 S:='';
 P:=pointer(longint(@F)+48);
 WHILE P^<>#0 DO BEGIN
                  S:=S+P^;
                  Inc(longint(p));
                 END;
 FOR I:=1 TO byte(S[0]) DO S[I]:=UpCase(S[I]);
 GetName:=S;
END;


BEGIN
 Assign(F,FileS);
 Reset(F,1);
 BlockRead(F,KK,1);
 BlockRead(F,an,2);
 BlockRead(F,al,2);
 GetMem(P,An*al);
 BlockRead(F,Paleta,768);
 BlockRead(F,P^,An*Al);
 Close(F);
 Rewrite(F,1);
 KK:=0;
 BlockWrite(F,kk,1);
 BlockWrite(F,an,2);
 BlockWrite(F,al,2);
 BlockWrite(F,Paleta,768);
 PACK;
 Close(F);
END;



CONST MN1:MenuDef=( NOpciones: 9;
                    Long:14;
                    Exit:1;
                    Opciones: ('Capturar TWK#1','Capturar TWK#0','Grabar PC#X','Capturar #ICO','Capturar #PAL',
                    'Elegir #Fichero', '#Mostrar','Me#zclar Paleta','#Salir','');
                    Activas:($FF,$FF);
                    AttrMenu:$70;
                    AttrBarra:$20;
                    AttrOculto:$78;
                    AttrSombra:$08;
                    AttrAlt:$04
                    );


VAR VIDEO:SCREEN ABSOLUTE $A000:0;
VAR X,Y:Word;
    SCR2:^SCREEN;
    PATH:String;
    Paleta:AllPaletteType;
    Nombre:String;
    NF2:String;
    F:FILE;
    Opcion:Byte;
    PCXCargado:Boolean;
    Code:Integer;
    I,J:Word;
    Key:Char;
    ICO:ARRAY[0..31,0..31] OF Byte;
    POSIC:Boolean;
    Count:Word;
    VGA:Word;


PROCEDURE _PutImage(VAR B;X,Y,An,Alto:Word);Assembler;
ASM
 CLD
 PUSH DS
 MOV  AX,40960    (*A000h*)
 MOV  ES,AX
 MOV  AX,Y      (* voy a multiplicar  por 320 *)
 MOV  DX,AX
 SHL AX,8
 SHL DX,6
 ADD AX,DX
 ADD  AX,X
 MOV  DI,AX
 LDS  SI,[B]      (* DS:SI --> Buffer.   ES:DI ---> Screen *)
 MOV CX,Alto
 @Bucle:
 PUSH CX
 MOV CX,An
 REP MOVSB
 POP CX
 SUB DI,An
 ADD DI,320
 LOOP @Bucle
 POP DS
END;

PROCEDURE _GetImage(VAR B;X,Y,An,Alto:Word);Assembler;
ASM
 PUSH DS
 MOV  AX,40960    (*A000h*)
 MOV  DS,AX
 MOV  CX,Y
 MOV  AX,CX
 SHL CX,8
 SHL AX,6
 ADD AX,CX
 ADD  AX,X
 MOV  SI,AX
 LES DI,[B]      (* ES:DI --> Buffer.   DS:SI ---> Screen *)
 MOV CX,Alto
 @Bucle:
 PUSH CX
 MOV CX,An
 @BUC:
 MOV AL,DS:[SI]
 MOV ES:[DI],AL
 INC DI
 INC SI
 LOOP @BUC
 POP CX
 SUB SI,An
 ADD SI,320
 LOOP @Bucle
 POP DS
END;



PROCEDURE SHOWCoords;
VAR I:Byte;
BEGIN
 IF (Y<10) AND POSIC THEN BEGIN
                         MOVE (SCR2^,VIDEO,3200);
                         POSIC:=NOT Posic;
                        END;
 IF (Y>90) AND NOT POSIC THEN BEGIN
                             MOVE(SCR2^[320*190],Mem[$a000:320*190],3200);
                             Posic:=NOT Posic;
                            END;
 IF Posic THEN GotoXY(1,1) ELSE GotoXY(1,25);
 DirectVideo:=False;
 Write(' X=',X:4,' Y=',Y:4,' ');
 DirectVideo:=True;
END;



{$I TOMATEC.SRC}

FUNCTION UpSt(S:STRING):STRING;
VAR I:Byte;
BEGIN
 FOR I:=1 TO Byte(S[0]) DO IF S[I] IN ['a'..'z'] THEN S[I]:=char(byte(S[I])-32);
 UpSt:=S
END;


FUNCTION GetPos(VAR X,Y:Word;An:Word):Boolean;
VAR Al:Word;
    Q:Pointer;
    Ch:Char;
    Ext:Boolean;
    Expl,Camb:Byte;


BEGIN
 IF An=31 THEN Al:=31 ELSE Al:=99;
 GetMem(Q,28006);
 colors[1]:=15;
 _GetImage(Q^,X,Y,An,Al);
 Rectangle(X,Y,X+An-1,Y+Al-1);
 Descartecla;
 REPEAT
  IF Tomatecla(Ch,ext,expl,camb) THEN BEGIN
                                       _PutImage(Q^,X,Y,an,al);
                                       IF Ext AND (Expl=72) THEN IF Y>0 THEN DEC(Y);
                                       IF Ext AND (Expl=80) THEN IF Y<197-Al THEN INC(Y);
                                       IF Ext AND (Expl=75) THEN IF X>0 THEN DEC(X);
                                       IF Ext AND (Expl=77) THEN IF X<318-An THEN INC(X);
                                       _GetImage(Q^,X,Y,An,Al);
                                       Rectangle(X,Y,X+An-1,Y+Al-1);
                                       SHowCoords;
                                      END;
 UNTIL Ch IN [#13,#27];
 DEscartecla;
 GetPos:=Ch=#13;
 _PutImage(Q^,X,Y,an,al);
 Freemem(Q,28006);
END;

PROCEDURE GetName(VAR S:string);
VAR TIPO:Boolean;
    EXT:String[3];
BEGIN
 EXT:=S;
 WriteLn('Teclee el n§ del fichero resultado de la captura :');
 ReadLn(S);
 VAL(S,I,Code);
 S:='ADV\'+S+'.'+EXT;
 IF Code<>0 THEN S:='';
 IF FSearch(S,'')<>'' THEN BEGIN
                            Write('Fichero Existe. ¨ Sobreescribir ? [ ]');
                            GotoXY(WhereX-2,WhereY);
                            Key:=UpCase(ReadKey);
                            Write(key);
                            IF Key<>'S' THEN S:='';
                           END;
END;


{$I BUFFERS.SRC}

PROCEDURE GetName2(VAR S:string);
BEGIN
 WriteLn('Teclee el nombre del fichero TWK resultado :');
 ReadLn(S);
 IF S='' THEN Exit;
 S:='ADV\'+S; IF Pos('.',S)=0 THEN S:=S+'.TWK';
 IF FSearch(S,'')<>'' THEN BEGIN
                            Write('Fichero Existe. ¨ Sobreescribir ? [ ]');
                            GotoXY(WhereX-2,WhereY);
                            Key:=UpCase(ReadKey);
                            Write(key);
                            IF key<>'S' THEN S:='';
                           END;
END;

PROCEDURE GetName3(VAR S:string);
BEGIN
 WriteLn('Teclee el nombre del fichero PCX resultado :');
 ReadLn(S);
 IF S='' THEN Exit;
 S:='ADV\'+S; IF Pos('.',S)=0 THEN S:=S+'.PCX';
 IF FSearch(S,'')<>'' THEN BEGIN
                            Write('Fichero Existe. ¨ Sobreescribir ? [ ]');
                            GotoXY(WhereX-2,WhereY);
                            Key:=UpCase(ReadKey);
                            Write(key);
                            IF key<>'S' THEN S:='';
                           END;
END;

PROCEDURE CLRLOW;
VAR I:Byte;
BEGIN
 FOR I:=8 TO 25 DO BEGIN
                    GotoXY(1,I);
                    ClrEol
                   END
END;

PROCEDURE TextMode; Assembler;
ASM
 MOV AX,3
 INT 10h
END;


PROCEDURE Beep;
BEGIN
Sound(100);
Delay(200);
NoSound;
END;

PROCEDURE PutImage2(VAR B;X,Y,An,Alto:Word;VAR Screen2);Assembler;
ASM
 PUSH DS
 LES  DI,[SCREEN2]
 MOV  AX,Y
 MOV  CX,AX
 SHL AX,8
 SHL CX,6
 ADD AX,CX
 ADD  AX,X
 ADD  DI,AX
 LDS  SI,[B]      (* DS:SI --> Buffer.   ES:DI ---> Screen *)
 MOV  CX,Alto
 @Bucle:
 PUSH CX
 MOV CX,An
 @BUC:
 MOV AL,DS:[SI]
 MOV ES:[DI],AL
 INC DI
 INC SI
 LOOP @BUC
 POP CX
 SUB DI,An
 ADD DI,320
 LOOP @Bucle
 POP DS
END;

PROCEDURE GO13h(VAR FTE,DST;Size:Word); Assembler;
ASM
 PUSH DS
 XOR BX,BX
 LDS SI,[FTE]
 MOV CX,Size
 SHR CX,1
 SHR CX,1
 @BUC:
 LES DI,[DST]
 ADD DI,BX
 PUSH CX
 @BUC2:
 MOVSB
 ADD DI,3
 LOOP @BUC2;
 POP CX
 INC BX
 CMP BX,4
 JNZ @BUC
 POP DS
END;


PROCEDURE UNPACK(VAR FTE,DST;Long:Word;VAR USADO:Word); Assembler;
ASM
 PUSH DS
 CLD
 XOR CX,CX
 LDS SI,[FTE]
 MOV BX,SI
 LES DI,[DST]
 MOV DX,Long
@BUCLE:
 MOV CL,DS:[SI]
 AND CL,0C0h
 CMP CL,0C0h
 JZ @COMPRESSED
 MOVSB
 DEC DX
 JMP @NEXT
@COMPRESSED:
 MOV CL,DS:[SI]
 AND CL,03Fh
 SUB DX,CX
 INC SI
 LODSB
 REP STOSB
@NEXT:
 OR DX,DX
 JNZ @BUCLE
 LES DI,[USADO]
 MOV AX,SI
 SUB AX,BX
 STOSW
 POP DS
END;

VAR BR:Bufferrd;

PROCEDURE LOADTWK_TYPE1;
VAR F:FILE;
    P,Q:Pointer;
    head:RECORD
            id:byte;
            an,al:Word;
            pal:Array[0..767] oF Byte;
           end;
   Size:Word;
   I:Word;
   P1,Q1:Pointer;
BEGIN
 Assign(F,Nombre);
 reset(F,1);
 BlockRead(F,head,773);
 Size:=Head.an*head.al;
 Move(head.pal,paleta,768);
 GetMem(Q,Size);
 BlockRead(F,Q^,Size);
 Close(F);
 GetMem(P,Size);
 FOR I:=0 TO head.al-1 DO
  Go13h(pointer(longint(q)+head.an*I)^,pointer(longint(p)+head.an*I)^,head.an);
  FillChar(SCR2^,64000,0);
 Putimage2(P^,0,0,head.an,head.al,SCR2^);
 FreeMem(Q,Size);
 FreeMem(P,Size);
END;


PROCEDURE LOADTWK;
VAR F:FILE;
    P,Q,Q1,Q2,P2:Pointer;
    leidos:word;
    Size:WorD;
    HEAD:RECORD
     ID:Byte;
     An,Al:Word;
     pal:ARRAy[0..767] OF byte;
    END;
    B:Byte;
    C:Byte;
    A:Byte;
    D:Word;
    NA:Word;
    KOMPRESS:BYTE;
    FP:LongInt;

VAR YY:Word;

BEGIN
 Assign(F,Nombre);
 Reset(F,1);
 BR.Inicializar(F);
 BR.Leer(F,HEad,Sizeof(head));
 IF (head.An>320) OR (Head.Al>200) THEN
  BEGIN
   TextAttr:=07;
   GotoXY(1,24);
   WriteLn('Tama¤o: ',head.an,'x',head.al);
   Write('Tama¤o demasiado grande. El m ximo aceptado es 320x200. Pulse una tecla...');
   Readkey;
   PCXCargado:=False;
   Close(F);
   Exit
  END;
 IF Head.id=1 THEN BEGIN
                    Close(F);
                    LOADTWK_TYPE1;
                    Exit;
                   END;
 Size:=head.An*head.al;
 GetMem(P,Size);
 getMem(Q,320);
 D:=0;
 NA:=0;
 REPEAT
  BR.Leer(F,KOMPRESS,1);
  IF KOMPRESS=1 THEN BEGIN
                      BR.Leer(F,Q^,320);
                      UNPACK(Q^,pointer(longint(p)+D)^,head.an,NA);
                      FP:=Br.Posfich(F);
                      Br.Colocar(F,FP+NA-320);
                     END
                ELSE
                 BR.leer(F,pointer(longint(p)+D)^,head.an);
  INC(D,head.an);
 UNTIL D=Size;
 FreeMem(Q,320);
 Close(F);
 GetMem(P2,Size);
 Q1:=P;
 Q2:=P2;
 FOR YY:=1 TO head.AL DO
  BEGIN
   Go13h(Q1^,Q2^,head.An);
   Inc(longint(Q1),head.an);
   Inc(longint(Q2),head.an);
  END;
 PutImage2(P2^,0,0,head.an,head.al,SCR2^);
 FreeMem(P,Size);
 FreeMem(P2,Size);
 MOVE(Head.Pal,paleta,768);
END;

PROCEDURE LoadSpectrum;
VAR P:^Screen;
    Leidos:Word;
    X,Y,I:Word;


FUNCTION INK(X,Y:Word):Byte; Assembler;
ASM
 MOV AX,VGA
 MOV ES,AX

 MOV CX,X
 SHR CX,3

 MOV DX,Y
 SHR DX,3
 SHL DX,5

 MOV BX,Count
 ADD BX,6144
 ADD CX,DX
 ADD BX,CX

 MOV AL,ES:[BX]
 AND AL,07h
END;

FUNCTION PAPER(X,Y:Word):Byte; Assembler;
ASM
 MOV AX,VGA
 MOV ES,AX

 MOV CX,X
 SHR CX,3

 MOV DX,Y
 SHR DX,3
 SHL DX,5

 MOV BX,Count
 ADD BX,6144
 ADD CX,DX
 ADD BX,CX

 MOV AL,ES:[BX]
 AND AL,38h
 SHR AL,3
END;

FUNCTION BTST(B:Byte;N:Byte):Boolean; Assembler;
ASM
 MOV CL,N
 MOV AL,B
 SHR AL,CL
 AND AL,1
END;




BEGIN
 New(P);
 VGA:=SEG(P^);
 Count:=0;
 IF POS('.SNA',Nombre)<>0 THEN Count:=27 ELSE
 IF POS('.SP',Nombre)<>0 THEN Count:=38;
 Move(PalS,paleta,48);
 Assign(F,Nombre);
 Reset(F,1);
 BlockRead(F,P^,64000,Leidos);
 Close(F);
 FOR X:=0 TO 255 DO
  FOR Y:=0 TO 191 DO
   IF BTST(P^[Count+X SHR 3+1792*(Y DIV 64)-2016* (Y SHR 3) +256 *Y],7-X AND $07) THEN SCR2^[X+32+(Y+5)*320]:=INK(X,Y)
                                                          ELSE SCR2^[X+32+(Y+5)*320]:=PAPER(X,Y);
 Dispose(P);
END;

VAR PCXan,PCXAl:WorD;

PROCEDURE LoadGif(Nombre:String);
VAR F:FILE;
    VAR Header:RECORD
                ID:ARRAY[1..6] OF Char;
                Ancho,alto:word;
               END;

BEGIN
 Assign(F,Nombre);
 Reset(F,1);
 BlockRead(F,Header,10);
 Close(F);
 IF (Header.Ancho>320) OR (Header.Alto>200) THEN BEGIN
                                     Beep;
                                     TextAttr:=$0F;
                                     GotoXY(1,24);
                                     WriteLn('Tama¤o: ',Header.ancho,'x',header.alto);
                                     Write('Tama¤o demasiado grande. El m ximo aceptado es 320x200. Pulse una tecla...');
                                     Readkey;
                                     PCXCargado:=False;
                                     exit
                                    END;
 ScreenSeg:=Seg(SCR2^);
 ScreenOfs:=Ofs(SCR2^);
 GifSetPal:=False;
 DecodeGif(Nombre);
 MOVE(Gifpalette,paleta,768);
END;

PROCEDURE LoadLBM(nombre:String);
BEGIN
 if NOT LoadPix(pscreen(SCR2),Nombre) THEN BEGIN
                                     Beep;
                                     TextAttr:=$0F;
                                     GotoXY(1,24);
                                     Write('Error leyendo fichero LBM. Pulse una tecla.');
                                     Readkey;
                                     PCXCargado:=False;
                                     exit
                                    END; ;
end;

PROCEDURE LoadPCX;
VAR P,P2,P3:^Screen;
    Leidos:Word;
    I:Word;
    Count:Word;
    ScrPos:Word;
    A,B,C:Byte;
    len:LongInt;
    leg:Longint;
    Ancho:Word;
    X:Word;
    RealPCxAn:Byte;

BEGIN
 FillChar(Scr2^,64000,0);
 Nombre:=UpSt(Nombre);
 IF Pos('.TWK',Nombre)<>0 THEN BEGIN
                                LoadTWK;
                                Exit;
                               END;
 IF Pos('.LBM',Nombre)<>0 THEN BEGIN
                                LoadLBM(Nombre);
                                Exit
                               END;
 IF Pos('.GIF',Nombre)<>0 THEN BEGIN
                                LoadGif(Nombre);
                                Exit
                               END;
 IF Pos('.PCX',Nombre)=0 THEN BEGIN
                               LoadSpectrum;
                               Exit
                              END;

 New(P);
 Assign(F,Nombre);
 Reset(F,1);
 P2:=NIL;
 BlockRead(F,P^,64000,Leidos);
 IF NOT EOF(F) THEN BEGIN
                     New(P2);
                     BlockRead(F,P2^,64000,leidos);
                     len:=leidos;
                     inc(len,64000);
                    END ELSE Len:=leidos;
 Close(F);
 IF P2=NIL THEN Move(P^[leidos-768],Paleta,768)
           ELSE Move(P2^[leidos-768],Paleta,768);
 FOR I:=0 TO 767 DO Paleta[I]:=Paleta[I] SHR 2;
 Count:=128;
 PCXAn:=P^[8] + 256*P^[9] - P^[4] + 256*P^[5]+1;
 PCXal:=P^[10] + 256*P^[11] - P^[6] + 256*P^[7]+1;
 IF (PcxAn>320) OR (PCXAl>200) THEN BEGIN
                                     Beep;
                                     TextAttr:=$0F;
                                     GotoXY(1,24);
                                     WriteLn('Tama¤o: ',PCXan,'x',PCXal);
                                     Write('Tama¤o demasiado grande. El m ximo aceptado es 320x200. Pulse una tecla...');
                                     Readkey;
                                     PCXCargado:=False;
                                     Dispose(p);
                                     IF P2<>NIL THEN Dispose(P2);
                                     exit
                                    END;

 IF ODD(PCXAn) THEN INC(PCXAn);
 ScrPos:=0;
 P3:=P;
 leg:=128;
 Dec(len,768);
 WHILE leg<Len DO
  BEGIN
   A:=P3^[count];
   IF (A AND $c0)>=$C0 THEN BEGIN
                  Inc(Count);
                  IF Count=64000 THEN BEGIN
                                       p3:=P2;
                                       Count:=0;
                                      END;
                  Inc(leg);
                  B:=A AND $3F;
                  A:=P3^[Count];
                 END
            ELSE B:=1;
   FillChar(Scr2^[ScrPos],B,A);
   Inc(ScrPos,B);
   Inc(count);
   inc(leg);
   IF Count=64000 THEN BEGIN
                        p3:=P2;
                        Count:=0;
                       END;
  END;
Dispose(P);
IF P2<>NIL THEN Dispose(P2);
END;

PROCEDURE GOTWEAK(VAR FTE,DST;Size:Word); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 MOV AX,Size
 SHR AX,1
 SHR AX,1         (* AX=Size DIV 4 *)
 XOR DX,DX      (* DX=Desplazamiento*)
 MOV CX,4
 @BUC1:
 LDS SI,[FTE]
 ADD SI,DX
 PUSH CX
 MOV CX,AX
 @BUC2:
 MOVSB
 ADD SI,3
 LOOP @BUC2
 INC DX
 POP CX
 LOOP @BUC1
 POP DS
END;

VAR CONFIGURACION : RECORD
     LINEAParam:STRING[50];
     TIMESEXEC:Byte;
     FONT:STRING[8];
     EDITOR:STRING[128];
     EDITORInterno:Boolean;
    END;
{<<<< CursorOff >>>>}

{ Procedimiento MUY espec¡fico para el IBM PC }

PROCEDURE CursorOff; Assembler;
ASM
 MOV AX,100h
 MOV CX,2000h   { Pone a 1 el bit 5 de CH para suprimir el cursor }
 INT 10h
END;


PROCEDURE CONFIGURAR;
VAR F:FILE;
BEGIN
 Assign(F,'NMP.CFG');
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      CONFIGURACION.LINEAParam:='';
                      CONFIGURACION.TIMESEXEC:=0;
                      CONFIGURACION.FONT:='NORMAL';
                      CONFIGURACION.EDITOR:='EDNMP.EXE';
                      CONFIGURACION.EDitorInterno:=True;
                     END
                ELSE BEGIN
                      BlockRead(F,CONFIGURACION,SizeOf(CONFIGURACION));
                      Close(F)
                     END;
END;


PROCEDURE LoadFont(S:STRING);
(* Carga un font de 16 de SD2 *)
VAR F:FILE;
    P:Pointer;
    H:Word;
BEGIN
 Assign(F,S+'.FNT');
 Reset(F,1);
 H:=IOresult;
 IF (H<>0) AND (S='NORMAL') THEN Exit;
 IF H<>0 THEN BEGIN
               WriteLn('No se encuentra font.');
               Halt
              END;
 Seek(F,16);
 GetMem(P,4096);
 BlockRead(F,P^,4096,H);
 IF (H<>4096) OR NOT EOF(F) THEN BEGIN
                                  Close(F);
                                  FreeMem(P,4096);
                                  Beep;
                                  LoadFont('Normal');
                                  Exit
                                 END;
 Close(F);
 ASM
  push bp
  mov ax,1100h
  mov bh,16
  mov bl,0
  mov cx,256
  mov dx,0
  les bp,p
  int 10h
  pop bp
 END;
 CursorOff;
 FreeMem(P,4096)
END;



PROCEDURE CABECERA;
BEGIN
 GotoXY(1,1);
 TextAttr:=$1F;
 Write('                                    GRAB 2.0                                    ');
 TextAttr:=$4E;
 WriteLn;
 IF PCXCargado THEN Write('GRAFICO CARGADO: ',UpSt(Nombre))
               ELSE Write('GRAFICO CARGADO: NINGUNO');
 ClrEol;
 WriteLn;
 TextAttr:=$07;
END;


PROCEDURE GRABARPCX;
VAR Nom:String;
    A:Word;
BEGIN
 ClrLow;
 GotoXY(1,8);
 GetName3(Nom);
 IF Nom='' THEN BEGIN
               Beep;
               clrlow;
               Exit
              END;
 WriteLn;
 Save_pCX(SEG(SCR2^),Nom,paleta);
 Clrlow;
 cabecera;
END;

PROCEDURE GetTWK2(typ:Byte);
VAR Nom:String;
    P:^Screen;
    Ancho,Alto:Word;
    P2:^Screen;
    PL:ALLPAletteType;
    Ch:Char;
    Ext:boolean;
    Expl,Camb:Byte;
    Compress:Boolean;
    S:String[4];
    Code:Integer;
    An,Al:Word;
    Size:Word;
    q1,q2:pointer;

LABEL Ya;

BEGIN
 ClrLow;
 GotoXY(1,8);
 GetName2(Nom);
 IF Nom='' THEN BEGIN
               Beep;
               clrlow;
               Exit
              END;
 WriteLn;
 Write('Teclee el ancho [Pulse ENTER para pantalla completa] :');
 REPEAT
  ReadLn(S);
  IF S='' THEN BEGIN
                An:=320;
                Al:=200;
                getMem(P,64000);
                Size:=64000;
                Move(SCR2^,P^,64000);
                Goto Ya;
               END;
  VAL(S,An,Code);
  IF An>320 THEN Code:=1;
  IF An MOD 4<>0 THEN Code:=1;
  IF Code<>0 THEN WriteLn('Error: El ancho ha de ser un m£ltiplo de 4 de rango (0-320)');
 UNTIL Code=0;

 WriteLn;
 Write('Teclee el alto :');
 REPEAT
  ReadLn(S);
  VAL(S,Al,Code);
  IF Al>200 THEN Code:=1;
  IF Code<>0 THEN WriteLn('Error: El alto ha de estar en el rango (0-200)');
 UNTIL Code=0;
 Mode($13);
 SetAllPalette(Paleta);
 Move(SCR2^,VIDEO,64000);
 X:=0;
 Y:=0;
 Size:=An*Al;
 Getmem(P,Size);
 colors[1]:=7;
 Ch:=#0;
 DEscartecla;
 _GetImage(P^,X,Y,An,Al);
 Rectangle(X,Y,X+An-1,Y+Al-1);
 REPEAT
  IF Tomatecla(Ch,ext,expl,camb) THEN BEGIN
                                       _PutImage(P^,X,Y,An,Al);
                                       IF Ext AND (Expl=72) THEN IF Y>0 THEN DEC(Y);
                                       IF Ext AND (Expl=80) THEN IF Y<200-Al THEN INC(Y);
                                       IF Ext AND (Expl=75) THEN IF X>0 THEN DEC(X);
                                       IF Ext AND (Expl=77) THEN IF X<320-An THEN INC(X);
                                       _GetImage(P^,X,Y,An,Al);
                                       Rectangle(X,Y,X+An-1,Y+Al-1);
                                      END;
 UNTIL Ch IN [#13,#27];
 DEscartecla;
 IF Ch=#27 THEN BEGIN
                 ASM
                  MOV AX,3
                  INT 10h
                 END;
                 Cabecera;
                 FreeMem(P,Size);
                 Exit
                END;
 Mode(3);
 LoadFont(Configuracion.font);
 CursorOff;
 YA:
 getmem(P2,Size);
 Q1:=P;
 Q2:=P2;
 FOR Al:=1 TO Al DO
  BEGIN
   GOTweak(Q1^,Q2^,An);
   Inc(longint(Q1),an);
   Inc(longint(Q2),an);
  END;
 Assign(F,Nom);
 Rewrite(F,1);
 Byte(Ch):=1;
 BlockWrite(F,Ch,1);
 BlockWrite(F,An,2);
 BlockWrite(F,Al,2);
 BlockWrite(F,Paleta,768);
 BlockWrite(F,P2^,Size);
 Close(F);
 ClrLow;
 Cabecera;
 FreeMem(P,Size);
 FreeMem(P2,Size);
 IF Typ=0 THEN PACKGRF(Nom);
END;

PROCEDURE GetICO;
VAR Nom:String;
BEGIN
 clrlow;
 GotoXY(1,8);
 Nom:='ICO';
 GetName(Nom);
 IF Nom='' THEN BEGIN
               Beep;
               clrlow;
               Exit
              END;
 Mode($13);
 SetAllPalette(Paleta);
 Move(SCR2^,VIDEO,64000);
 X:=140;
 Y:=84;
 Posic:=true;
 IF GETPOS(X,Y,31) THEN
    BEGIN
     Assign(F,Nom);
     Rewrite(F,1);
     FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO ico[J,I]:=Mem[$a000:X+I+320*(Y+J)];
     BlockWrite(F,ico,sizeof(ico));
     Close(F);
    END;
 Mode(3);
 Cabecera;
END;

PROCEDURE MezclarPaleta;
VAR A,B:Byte;
    S:String;
    Code:Integer;
    P:AllPalettetype;
    Q:Byte;
    I:Word;
BEGIN
 ClrLow;
 GotoXY(1,8);
 WRITELN('MEZCLAR PALETA');
 WRITELN;
 Write('Teclee primer color : ');
 ReadLn(S);
 VAL (S,A,code);
 IF Code<>0 THEN BEGIN
                  WriteLn('Valor err¢neo. Pulse una tecla.');
                  ReadKey;
                  ClrLow;
                  Exit
                 END;
 Write('Teclee £ltimo color : ');
 ReadLn(S);
 VAL (S,B,code);
 IF Code<>0 THEN BEGIN
                  WriteLn('Valor err¢neo. Pulse una tecla.');
                  ReadKey;
                  ClrLow;
                  Exit
                 END;
 IF B<A THEN BEGIN
              WriteLn('Rango il¢gico. Pulse una tecla.');
              ReadKey;
              ClrLow;
              Exit
             END;
 Write('Teclee el nombre del fichero de paleta [.PAL] : ');
 ReadLn(S);S:='ADV\'+S; IF Pos('.',S)=0 THEN S:=S+'.PAL';
 Assign(F,S);
 {$I-}
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      WriteLn('Fichero no se encuentra. Pulse una tecla.');
                      ReadKey;
                      ClrLow;
                      Exit
                     END;
 {$I+}
 BlockRead(F,P,768);
 Close(F);
 ClrLow;
 GotoXY(1,8);
 WriteLn('Se van a insertar las tonalidades RGB del fichero ',UpSt(S));
 WriteLn('en el fichero ',UpSt(Nombre),' en el rango [',A,',',b,']');
 Write('¨Son los datos correctos ? [ ]');GotoXY(WhereX-2,Wherey);
 IF Upcase(ReadKey)<>'S' THEN BEGIN
                               ClrLow;
                               Exit
                              END;
 Assign(F,Nombre);
 Reset(F,1);
 Move(P[3*A],Paleta[3*A],3*(B-A+1));
 Seek(F,FileSize(F)-768+3*A);
 FOR I:=0 TO 767 DO P[I]:=P[I] SHL 2;
 BlockWrite(F,P[3*A],3*(B-A+1));
 Close(F);
 ClrLow;
END;


BEGIN (* PRINCIPAL *)
CONFIGURAR;
getdir(0,path);
IF CHIPTYPE<280 THEN Halt;
IF ChipType<380 THEN SET286;
New(SCR2);
Nombre:=ParamStr(1);
IF Pos('.',Nombre)=0 THEN Nombre:=Nombre+'.PCX';
IF FSearch(Nombre,'')='' THEN PCXCargado:=False
                         ELSE BEGIN
                               PCXCargado:=True;
                               LoadPCX
                              END;
TextMode;
ASM
  mov bl,30h
  MOV AX,1802h
  int 10h
END; (* 25 l¡neas *)
LoadFont(CONFIGURACION.FONT);
CABECERA;
REPEAT
 Opcion:=Menu(32,8,MN1);
 CASE Opcion OF
  1:IF PCXCARGADO THEN GETTWK2(1) ELSE BEEP;
  2:IF PCXCARGADO THEN GETTWK2(0) ELSE BEEP;
  3:IF PCXCARGADO THEN GRABARPCX ELSE BEEP;
  4:IF PCXCARGADO THEN GETICO ELSE BEEP;
  5:IF PCXCARGADO THEN
     BEGIN
      ClrLow;
      GotoXY(1,8);
      Write('Teclee n§ de fichero de paleta (0-65535) : ');
      ReadLn(NF2);
      VAL(NF2,I,Code);
      IF Code=0 THEN IF FSearch('ADV\'+NF2+'.PAL','')<>'' THEN
                        BEGIN
                         Write('Fichero existe. ¨ Sobreescribir ? [ ]');
                         GotoXY(Wherex-2,Wherey);
                         Key:=UpCase(ReadKey);
                         IF Key<>'S' THEN Key:='N';
                         Write(Key);
                         IF KEY='S' THEN BEGIN
                                          Assign(F,'ADV\'+NF2+'.PAL');
                                          Rewrite(F,1);
                                          BlockWrite(F,Paleta,768);
                                           Close(F)
                                         END
                        END ELSE BEGIN
                                  Assign(F,'ADV\'+NF2+'.PAL');
                                  Rewrite(F,1);
                                  BlockWrite(F,Paleta,768);
                                  Close(F)
                                 END
                ELSE Beep;
     ClrLow;
    END
   ELSE BEEP;



  6:BEGIN
     ClrLow;
     TextAttr:=$3F;
     HacerCaja(31,5,16,16,CaracGraf);
     GotoXY(32,5);Write(' Fichero ');
     GotoXY(32,6);Write('              ');
     GotoXY(32,19);Write('              ');
     Nombre:=SelectFILE('*.pCX;*.twk;*.gif;*.scr;*.sp;*.jpp;',PATH,32,7,12);
     PCXcargado:=Nombre<>'';
     IF PCXCARGADO THEN LoadPCX;
     textmode;
     CABECERA;
     END;
  7:IF PCXCargado THEN
     BEGIN
      InitVGA256;
      SetAllPalette(Paleta);
      IF Pos('.PCX',Nombre)<>0 THEN _Putimage(SCR2^,0,0,PCXAn,PCXAl)
                               ELSE Move(SCR2^,Mem[$a000:0],64000);
      ReadKey;
      TextMode;
      CABECERA
     END
     ELSE Beep;
  8: IF PCXCargado AND (Pos('.PCX',UpSt(Nombre))<>0) THEN MezclarPaleta ELSE Beep;
 END;
LoadFont(CONFIGURACION.FONT);
UNTIL Opcion IN [0,9];
TextMode;
WriteLn('GRAB 2.0');
END.