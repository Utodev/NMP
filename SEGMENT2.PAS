UNIT SEGMENT2;
{$G+}
{$I-}
{S-}
{R-}

INTERFACE



USES DOS,SFX2Buf,CACHE,Mycrt,Adliblib,DOUb386,CDROM;


Type
  Win3ModeType = (NoWin, RealStd, Enhanced);
CONST VERSION='5.5';
CONST BuffSize=512;
CONST DEBUG:Boolean=False;
      DEBUG2:Boolean=False;
      KEYDISKOK:boolean=False;
      UNTILRETURN:Boolean=False;
      PROCRETURN:Byte=0;

TYPE MENSAJE=String;
     proctype=procedure;
     Palettetype=ARRAY[0..767] OF Byte;
     PALABRA=sTRING[5];
     WINDOW=RECORD
             X0,Y0,XF,YF:Word;
            END;
TYPE
BufferRd=Object

 Buff:ARRAY[0..BuffSize-1] OF Char;
 BuffPoi:Word;
 BuffTam:Word;

 PROCEDURE Inicializar(VAR F:File);
 PROCEDURE Leer(VAR F:File;VAR A;Tam:Word);
 PROCEDURE LeerUno(VAR F:File;VAR A);
 FUNCTION EOFL(VAR F:File):Boolean;
 PROCEDURE Colocar(VAR F:File;Posic:LongInt);
 FUNCTION PosFich(VAR F:FILE):LongInt;


END;

VAR PalColor0, PalColorF : Byte;


VAR DRVPtr:Pointer;
    VOLUMEFM:ARRAy[1..9] OF Byte;
VAR BR:BufferRd;
    SIZEDRV:Word;
    Pall0:PaletteType;
    FontPtr:Pointer;
    SizelastFont:Word;
    FontHeigth:Word;
    width:ARRAY[31..250] OF Byte; (*Anchura juego de caracteres actual*)
    FONT:Word; (* Guarda el nß de font en uso *)
    VideoMode:Byte;
    Win:ARRAY[0..19] OF Window;
    Refresco:Boolean;
    NotaAct : Array[1..9] OF Boolean;
    Flags:ARRAY[Byte] OF Word;



PROCEDURE NoRefresh;
FUNCTION LoadFont(S:String):Byte;
FUNCTION BTST(B:Word;N:Byte):Boolean;
FUNCTION RealLen(S:String):Word;

PROCEDURE AYUDA;
FUNCTION BitWise(W:Word):String;
PROCEDURE FillWord(VAR DST;Count:Word;Value:Word);
PROCEDURE GetImage(VAR B;X,Y,An,Alto:Word);
PROCEDURE InitCD(VAR F,L:Word);
FUNCTION NopuedesAzar:Word;
FUNCTION UpSt(VAR S0:STRING):String;
Function OS2_GetVersion: Word;
Function CheckForWin3 : Win3ModeType;
PROCEDURE GetAllPalette(VAR P);
PROCEDURE XORST(VAR S:STRING);
PROCEDURE BNEG(VAR B:Word;N:Byte);
FUNCTION SetVESA:Boolean;
PROCEDURE PutImage(VAR B;X,Y,An,Alto:Word);
FUNCTION INITSFX:Boolean;
PROCEDURE INIT256;
PROCEDURE GRAY(O1,O2,O3:Word);
PROCEDURE FADEOUT(O1,O2,O3:Word);
PROCEDURE Fundido(O1,O2:Word);
PROCEDURE RFundido(O1,O2:Word);
PROCEDURE FADETO(Paleta:PaletteType;Cycles:Word;Step:Word);
FUNCTION GetPixelLength(S:STRING;hasta:Byte):Word;
PROCEDURE Paleta(VAR PALETE;A,B:Byte);
PROCEDURE MIX(VAR FTE,DST);
PROCEDURE Refresh;
PROCEDURE ICONOT(VAR FTE,DST);
PROCEDURE ICOXOR(VAR FTE,DST);
PROCEDURE BSET(VAR B:Word;N:Byte);
PROCEDURE InicializaDRV;
PROCEDURE ICOOR(VAR FTE,DST);
PROCEDURE GOTWEAK(VAR FTE,DST;Size:Word);
PROCEDURE ICOAND(VAR FTE,DST);
FUNCTION VALBIN(S:STRING):Word;
FUNCTION ColorOf(VAR ZONE;X,Y:Word):Byte;
PROCEDURE BCLR(VAR B:Word;N:Byte);
PROCEDURE SetRGBPalette(C,R,G,B:Byte);
FUNCTION FUNCTKEY:Byte;
PROCEDURE UNPACK(VAR FTE,DST;Long:Word;VAR USADO:Word);
PROCEDURE ESPERABARRIDO;
FUNCTION XVAL(C:Char):Byte;
FUNCTION VALW(S:string):Word;
FUNCTION SGN(A:Integer):ShortInt;
PROCEDURE SETPAL(VAR PALETA;A,B:Byte);
PROCEDURE Boot;
FUNCTION SHIFT:Byte;
FUNCTION GetKey:Word;
PROCEDURE CursorOn;
PROCEDURE CursorOff;
PROCEDURE PCX256(St:String;Typ:Boolean);
PROCEDURE AllPalette;
PROCEDURE DescarTecla;
FUNCTION STRS(W:LongInt):String;
FUNCTION VALSS(W:palabra):Byte;
FUNCTION Running4DOS : Boolean;
PROCEDURE RobaMemoria;
FUNCTION VALX(S:string):Byte;
FUNCTION GetNormalMessage(N:Word):Mensaje;
FUNCTION HEX(C:Word):String;

IMPLEMENTATION

FUNCTION HEX(C:Word):String;
VAR S:String;
    B:Word;
BEGIN
 S:='';
 WHILE C<>0 DO
  BEGIN
   B:=C MOD 16;
   C:=C DIV 16;
   IF B<10 THEN S:=char(B+48)+S
           ELSE S:=char(B+55)+S
  END;
 S:=Copy('0000',1,4-byte(S[0]))+S;
 HEX:=S
END;


(* El tama§o del buffer ha de ser mayor o igual que el tama§o *)
(* de la variable m†s grande que se vaya a leer del fichero   *)


PROCEDURE BufferRd.Inicializar(VAR F:File);
BEGIN
 BuffPoi:=0;
 BlockRead(F,Buff,BuffSize,BuffTam);
END;


PROCEDURE BufferRd.Leer( VAR F:File; VAR A; Tam:Word );
VAR Aux:Word;
    Pos:Longint;
BEGIN
 IF Tam>BuffSize THEN BEGIN
                       Pos:=FilePos(F);
                       Seek(F,Pos-BuffTam+BuffPoi);
                       BlockRead(F,A,Tam,BuffTam); (* Bufftam por poner algo *)
                       BlockRead(F,Buff,BuffSize,Bufftam);
                       BuffPoi:=0;
                       Exit
                      END;
 IF BuffPoi>=BuffTam THEN BEGIN
                           BlockRead(F,Buff,BuffSize,BuffTam);
                           BuffPoi:=0
                          END;
 IF Tam+BuffPoi>BuffTam THEN BEGIN
                              Aux:=BuffTam-BuffPoi;
                              Move(Buff[BuffPoi],Buff[0],Aux);
                              BlockRead(F,Buff[Aux],BuffSize-Aux,BuffTam);
                              Inc(BuffTam,Aux);
                              BuffPoi:=0
                             END;
 Move(Buff[BuffPoi],A,Tam);
 Inc(BuffPoi,Tam)
END;

PROCEDURE BufferRd.LeerUno( VAR F:File; VAR A);
VAR Aux:Word;
    Pos:Longint;
BEGIN
 IF BuffPoi>=BuffTam THEN BEGIN
                           BlockRead(F,Buff,BuffSize,BuffTam);
                           BuffPoi:=0
                          END;
 char(a):=Buff[BuffPoi];
 Inc(BuffPoi)
END;

PROCEDURE BufferRd.Colocar(VAR F:FILE;Posic:LongInt);
VAR FP:LongInt;
BEGIN
 FP:=FilePos(F);
 IF (Posic<=FP) AND (Posic>=FP-BuffTam) THEN BuffPoi:=BuffTam-FP+Posic
  ELSE
   BEGIN
    Seek(F,Posic);
    BlockRead(F,Buff,BuffSize,BuffTam);
    BuffPoi:=0
   END;
END;



FUNCTION BufferRd.EOFL(VAR F:File):Boolean;
VAR Aux:Boolean;
BEGIN
 Aux:=(EOF(F) AND (BuffPoi>=BuffTam));
 EOFL:=Aux;
END;

FUNCTION BufferRd.PosFich(VAR F:FILE):LongInt;
BEGIN
 PosFich:=FilePos(F)-BuffTam+BuffPoi;
END;

PROCEDURE AllPalette; (*CAMBIA PALETA DE GOLPE*)
BEGIN
 IF DEBUG AND DEBUG2 THEN FillChar(Pall0[21],3,48);
 Paleta(Pall0,PalColor0,PalColorF);
END;


PROCEDURE SETPAL(VAR PALETA;A,B:Byte);
VAR N:Word;
BEGIN
   N:=B-A+1;
   EsperaBarrido;
   ASM
    MOV AL,A
    XOR AH,AH
    MOV BX,AX
    ADD AX,AX
    ADD AX,BX
    MOV CX,N
    MOV BX,CX
    ADD CX,BX
    ADD CX,BX
    PUSH DS
    LDS SI,[Paleta]
    ADD SI,AX
    MOV DX,3C8h
    MOV AL,A
    OUT DX,AL
    INC DX
    CLD
    REP OUTSB
    POP DS
   END;
END;


PROCEDURE Paleta(VAR PALETE;A,B:Byte);
(* DIVIDE UN CAMBIO DE PALETA EN TROZOS DE 128 COLORES *)
(* PARA QUE NO HAYA NIEBLA NI EN LOS 286 *)
VAR J:Word;
BEGIN
 J:=B-A+1;
 WHILE J>128 DO
  BEGIN
   SETPAL(PALETE,A,A+127);
   INC(A,128);
   J:=B-A+1
  END;
 IF J<>0 THEN SETPAL(PALETE,A,B);
END;


PROCEDURE PCX256(St:String;Typ:Boolean);
TYPE ARRAY_=ARRAY[0..65534] OF Byte;
VAR H:Byte;
    F:FILE;
    P:^ARRAY_;
    Count:Word;
    X0,Y0,XF:Word;
    X,Y:Word;
    A,B:Byte;
    I:Word;
    Siz:LongInt;
    Size:Word;



    PROCEDURE PCXGOLPE;
    VAR P:Pointer;
        Size:Word;
        I:WOrd;
        WFXF:Word;
        An:Word;
    BEGIN
     GetMem(P,Size);
     An:=Win[flags[25]].XF-Win[Flags[25]].X0+1;
     REPEAT
BR.Leer(F,A,1);
      Inc(count);
      IF A>192 THEN
       BEGIN
        B:=A-192;
        BR.Leer(F,a,1);
        Inc(count);
       END
       ELSE B:=1;
      WHILE B<>0 DO
       BEGIN
        Dec(b);
        IF (X<=WIN[FLAGS[25]].XF) AND (Y<=Win[Flags[25]].YF) THEN
         Byte(pointer(longint(p)+An*(y-y0)+x-X0)^):=a;
        Inc(X);
        IF X>Xf THEN
         BEGIN
          X:=X0;
          Inc(Y);
         END;
       END;
     UNTIL (Siz<768+count) OR (Y>Win[Flags[25]].YF);
     IF typ THEN
      BEGIN
       BR.Colocar(F,Siz-768);
       BR.Leer(F,Pall0,768);
       FOR I:=0 TO 767 DO Pall0[I]:=Pall0[I] SHR 2;
       AllPalette;
      END;
     WITH WIN[Flags[25]] DO Putimage(P^,X0,Y0,XF-X0+1,YF-Y0+1);
     FreeMem(P,Size);
    END;




BEGIN
 Flags[13]:=0;
 Assign(F,ST+'.PCX');
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      Assign(F,ST+'.GRF');
                      Reset(F,1);
                      IF IOResult<>0 THEN BEGIN
                                           Flags[13]:=1;
                                           Exit
                                          END;
                     END;
 Siz:=FileSize(F);
 BR.Inicializar(F);
 IF MaxAvail<128 THEN BEGIN
                       Flags[13]:=2;
                       Exit
                      END;
 GetMem(Pointer(p),128);  (*Lectura de cabecera *)
 BR.Leer(F,P^,128);
 X0:=Win[Flags[25]].X0;
 Y0:=Win[Flags[25]].Y0;
 XF:=X0 + P^[8] + 256*P^[9] - P^[4] + 256*P^[5];
 X:=X0; Y:=y0;
 FreeMem(P,128);
 WITH WIN[FLAGS[25]] DO Size:=(XF-X0+1)*(YF-Y0+1);
 Count:=128;
 IF Size<=MaxAvail THEN
  BEGIN
   PCXGOLPE;
   CLose(F);
   Exit
  END;

 IF typ THEN
  BEGIN
   BR.Colocar(F,Siz-769);
   BR.leer(F,I,1);
   BR.Leer(F,Pall0,768);
   FOR I:=0 TO 767 DO Pall0[I]:=Pall0[I] SHR 2;
   AllPalette;
  END;

 BR.Colocar(F,128);
 REPEAT
  BR.Leer(F,A,1);
  Inc(count);
  IF A>192 THEN
   BEGIN
    B:=A-192;
    BR.Leer(F,a,1);
    Inc(count);
   END
   ELSE B:=1;
  WHILE B<>0 DO
   BEGIN
    Dec(b);
    IF (X<=Win[Flags[25]].XF) AND (Y<=Win[Flags[25]].YF) THEN
     mem[$a000:320*y+x]:=a;
    Inc(X);
    IF X>Xf THEN
     BEGIN
      X:=X0;
      Inc(Y);
     END;
   END;
 UNTIL (Siz<768+count) OR (Y>Win[Flags[25]].YF);
 Close(F);
END;


FUNCTION NopuedesAzar:Word;
BEGIN
 CASE RANDOM(4) OF
  0:NopuedesAzar:=5;
  1:NopuedesAzar:=43;
  2:NopuedesAzar:=44;
  3:NopuedesAzar:=45;
 END
END;

FUNCTION GetNormalMessage(N:Word):Mensaje;
TYPE INDICE=RECORD
             L:Word;
             Off:Longint
            END;
VAR F1:FILE;
    I:Indice;
    S:String;
    d:word;
BEGIN
 Assign(F1,'M.IDX');
 Reset(F1,1);
 IF FileSize(F1)<=N*6 THEN BEGIN
                           Close(F1);
                           GetNormalMessage:='';
                           exit
                          end;
 Seek(F1,N*6);
 BlockRead(F1,I,6,d);
 Close(F1);
 Assign(F1,'M.PAK');
 Reset(F1,1);
 Seek(F1,I.Off);
 IF I.L>253 THEN I.L:=253;
 byte(S[0]):=System.Lo(I.L);
 BlockRead(F1,S[1],I.L,d);
 Close(F1);
 XORST(S);
 GetNormalMessage:=S;
END;


PROCEDURE RobaMemoria;
(* Procedimiento que reduce la memoria intencionadamente para observar el
  funcionamiento con un m†ximo de 32K libres *)
VAR P:Pointer;
BEGIN
 WHILE MaxAvail>64000 DO GetMem(P,32000);
 WHILE MaxAvail>20000 DO GetMem(P,10000);
 GetMem(P,MaxAvail-10000);
END;


FUNCTION FUNCTKEY:Byte;
BEGIN
FunctKey:=Hi(GetKey);
END;

PROCEDURE NoRefresh;
     PROCEDURE RFSH; Assembler;
     ASM
      MOV AX,1201h
      MOV BL,36h
      MOV BH,0
      INT 10h
     END;
BEGIN
 IF (Debug AND Debug2) THEN Exit;
 IF VideoMode>1 THEN Exit;
 RFSH;
 Refresco:=False;
END;


PROCEDURE Refresh; Assembler;
ASM
 MOV AL,VideoMode
 CMP AL,1
 JNZ @FIN
 MOV AX,1200h
 MOV BL,36h
 MOV BH,0
 INT 10h
 @FIN:
 MOV REFRESCO,1
END;

PROCEDURE ESPERABARRIDO;
BEGIN
IF REFRESCO THEN
ASM
    MOV   DX,3DAh
@@1:
    IN    AL,DX
    AND   AL,08h
    JNZ   @@1
@@2:
    IN    AL,DX
    AND   AL,08h
    JZ    @@2
END;
END;



FUNCTION VALSS(W:palabra):Byte;
VAR Code:Integer;
    B:byte;
BEGIN
VAL(W,B,code);
Valss:=B
END;

FUNCTION VALW(S:string):Word;
VAR Code:Integer;
    B:word;
BEGIN
VAL(S,B,code);
Valw:=B
END;

FUNCTION LoadFont(S:String):Byte;
VAR F:FILE;
    Code:Integer;
    Len:Word;
    d:word;
BEGIN
 Assign(F,S+'.FNT');
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      LoadFont:=2;
                      Exit
                     END;
 IF FontPtr<>NIL THEN BEGIN
                       FreeMem(FontPtr,SizeLastFont);
                       SizeLastFont:=0;
                       FontPtr:=NIL;
                      END;
 Len:=FileSize(F);
 SizelastFont:=Len-220;
 IF len=14080 THEN BEGIN
                    LoadFont:=1;
                    Exit;
                   END;
 GetMem(FontPtr,SizeLastFont);
 BlockRead(F,FontPtr^,len-220,d);
 BlockRead(F,width,220,d);
 Close(F);
 VAL(S,FONT,CODE);
 Fontheigth:=(len-220) SHR 3 DIV 220;
 LoadFont:=0;
END;



FUNCTION XVAL(C:Char):Byte;
BEGIN
 CASE C OF
  'a'..'f':XVAL:=Ord(C)-87;
  'A'..'F':XVAl:=Ord(c)-55;
  '0'..'9':XVAl:=Ord(c)-48
  ELSE XVal:=0
 END;
END;

FUNCTION SGN(A:Integer):ShortInt;
BEGIN
 IF A<0 THEN SGN:=-1 ELSE
 IF A>0 THEN SGN:=1 ELSE SGN:=0
END;

FUNCTION VALX(S:string):Byte;
VAR Code:Integer;
    B:byte;
BEGIN
VAL(S,B,code);
Valx:=B
END;

FUNCTION STRS(W:LongInt):String;
VAR D:String;
BEGIN
 STR(W,D);
 STRS:=D
END;

PROCEDURE Boot;
VAR Chuf:Procedure;
BEGIN
 @Chuf:=Ptr($FFFF,0);
 MemW[$40:$72]:=$1234;
 Chuf
END;


PROCEDURE DescarTecla; Assembler;
ASM
  MOV AH,1
  INT 16h
  JZ @NADA
  @BUC:
  MOV AH,0
  INT 16h
  MOV AH,1
  INT 16h
  JNZ @BUC
  @NADA:
END;

PROCEDURE CursorOff; Assembler;
ASM
 MOV AX,100h
 MOV CX,2000h   { Pone a 1 el bit 5 de CH para suprimir el cursor }
 INT 10h
END;

PROCEDURE CursorOn; Assembler;
LABEL L1,L2;
ASM
   MOV AH,0Fh
   INT 10h
   CMP AL,7
   JE L1
   MOV CX,0607h
   JMP L2
L1:MOV CX,0B0Ch
L2:MOV AH,01
   INT 10h
END;

PROCEDURE AYUDA;
VAR S:String;
    I:Byte;
BEGIN
 ASM
 MOV AX,3
 INT 10h
 END;
 WriteLn('TEST DE NMP ',version);
 WriteLn;
 S:=ParamStr(0);
 if pOS('\',S)<>0 THEN
  BEGIN
   WHILE (S<>'') AND (Pos('\',S)<>0) DO S:=Copy(S,Pos('\',S)+1,255);
  END;
 S:=Copy(S,1,Pos('.',S)-1);
 WriteLn('SINTAXIS:');
 WriteLn;
 WriteLn('         ',S,' [-info] [-sfx] [-mus] [-pc] [-s] [-cachÇ] [-?]');
 WriteLn;
 WriteLn('OPCIONES:');
 WriteLn('         -info      Muestra informaci¢n general sobre el juego.');
 WriteLn('         -sfx       Anula efectos de sonido (si los hay).');
 WriteLn('         -mus       Anula m£sica de fondo (si la hay).');
 WriteLn('         -s         Anula sonido en general.');
 WriteLn('         -pc        Fuerza a usar el altavoz del PC aunque haya Sound Blaster.');
 WriteLn('         -cachÇ     Obliga a no usar la XMS como cachÇ de disco.');
 WriteLn('         -dir=x     Indica el directorio para grabar/cargar partidas.');
 WriteLn('         -?         Muestra este mensaje.');
 WriteLn;
END;

FUNCTION INITSFX:Boolean;
VAR Aux:Boolean;
BEGIN
 InitSFX:=False;
 SB_Port:=$210;
 Aux:=ResetDSP;
 IF Aux THEN BEGIN              (* SB en Port 210h *)
              InitSFX:=True;
              exit
             END;
 SB_Port:=$220;
 Aux:=ResetDSP;
 IF Aux THEN BEGIN              (* SB en Port 220h *)
              InitSFX:=True;
              exit
             END;
 SB_Port:=$230;
 Aux:=ResetDSP;
 IF Aux THEN BEGIN               (* SB en Port 230h *)
              InitSFX:=True;
              exit
             END;
 SB_Port:=$240;
 Aux:=ResetDSP;               (* SB en Port 240h *)
 IF Aux THEN BEGIN
              InitSFX:=True;
              exit
             END;
 IF NOT Aux THEN SB_Port:=1; (* Nada, pues sin sonido *)
 InitSFX:=Aux;
END;

FUNCTION SHIFT:Byte; Assembler;
ASM
 MOV AH,02;
 INT 16h
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

PROCEDURE SetRGBPalette(C,R,G,B:Byte);
BEGIN
 Port[$3c8]:=C;
 Port[$3c9]:=R;
 Port[$3c9]:=G;
 Port[$3c9]:=B;
END;


PROCEDURE GetImage(VAR B;X,Y,An,Alto:Word);Assembler; (* Modo 13h *)
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
 REP MOVSB
 POP CX
 SUB SI,An
 ADD SI,320
 LOOP @Bucle
 POP DS
END;

PROCEDURE PutImage(VAR B;X,Y,An,Alto:Word);Assembler; (* Modo 13h *)
ASM
 CLD
 PUSH DS
 MOV  AX,40960    (*A000h*)
 MOV  ES,AX
 MOV  AX,Y      (* voy a multiplicar  por 320 *)
 MOV  DX,AX
 SHL AX,8
 SHL DX,5
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



PROCEDURE ICOAND(VAR FTE,DST); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 LDS SI,[FTE]
 MOV CX,1024
 CLD
@BUCLE:
 MOV BL,ES:[DI]
 LODSB
 AND AL,BL
 STOSB
 LOOP @BUCLE
 POP DS
END;

PROCEDURE ICOOR(VAR FTE,DST); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 LDS SI,[FTE]
 MOV CX,1024
 CLD
@BUCLE:
 MOV BL,ES:[DI]
 LODSB
 OR AL,BL
 STOSB
 LOOP @BUCLE
 POP DS
END;

PROCEDURE ICOXOR(VAR FTE,DST); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 LDS SI,[FTE]
 MOV CX,1024
 CLD
@BUCLE:
 MOV BL,ES:[DI]
 LODSB
 XOR AL,BL
 STOSB
 LOOP @BUCLE
 POP DS
END;

PROCEDURE ICONOT(VAR FTE,DST); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 LDS SI,[FTE]
 MOV CX,1024
 CLD
@BUCLE:
 LODSB
 NOT AL
 STOSB
 LOOP @BUCLE
 POP DS
END;


PROCEDURE MIX(VAR FTE,DST); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 LDS SI,[FTE]
 MOV CX,1024
 CLD
@BUCLE:
 LODSB
 CMP AL,255
 JZ @NADA
 STOSB
 DEC DI
 @NADA:
 INC DI
 LOOP @BUCLE
 POP DS
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


PROCEDURE BCLR(VAR B:Word;N:Byte); Assembler;
ASM
 LES DI,[B]
 MOV CL, N
 MOV DX, 1
 SHL DX, CL
 NOT DX
 AND WORD PTR ES:[DI], DX
END;



PROCEDURE XORST(VAR S:STRING);
VAR I:Byte;
BEGIN
  FOR I:=1 TO Byte(S[0]) DO byte(S[I]):=byte(S[I]) XOR 71;
END;

FUNCTION UpSt(VAR S0:STRING):String;
VAR I:BYTE;
    S:STRING;
BEGIN
 S:=S0;
 FOR I:=1 TO byte(S[0]) DO
  CASE S[I] OF
   '§':S[I]:='•';
   'á':S[I]:='Ä';
   '†':S[I]:='A';
   'Ç':S[I]:='E';
   '°':S[I]:='I';
   '¢':S[I]:='O';
   '£':S[I]:='U';
   'Å':S[I]:='ö'
   ELSE S[I]:=UpCase(S[I]);
  END;
 UpSt:=S;
END;


PROCEDURE GetAllPalette(VAR P); Assembler;
ASM
 CLD
 LES DI,[P]
 MOV CX,768
 MOV DX,03C7h
 MOV AL,0
 OUT DX,AL
 INC DX
 INC DX
 REP INSB
END;


PROCEDURE FillWord(VAR DST;Count:Word;Value:Word);Assembler;
ASM
 LES DI,[DST]
 MOV CX,Count
 MOV AX,Value
 CLD
 REP STOSW
END;


FUNCTION BTST(B:Word;N:Byte):Boolean; Assembler;
ASM
 MOV CL,N
 MOV AX,B
 SHR AX,CL
 AND AX,1
END;

PROCEDURE BSET(VAR B:Word;N:Byte); Assembler;
ASM
 LES DI,[B]
 MOV CL,N
 MOV DX, 1
 SHL DX, CL
 OR WORD PTR ES:[DI], DX
END;

PROCEDURE BNEG(VAR B:Word;N:Byte); Assembler;
ASM
 LES DI,[B]
 MOV CL,N
 MOV DX, 1
 SHL DX, CL
 XOR WORD PTR ES:[DI], DX
END;

FUNCTION SetVESA:Boolean; Assembler;
ASM
  MOV AX,4F02h;
  MOV BX,0100h
  INT 10h
  OR AH,AH
  JZ @FIN
  MOV AX,4F02h
  MOV BX,0101h
  INT 10h
@FIN:
  XOR AH,1
  MOV AL,AH
END;



PROCEDURE INIT256; Assembler;
ASM
 MOV AX,13h
 INT 10h
END;


PROCEDURE InicializaDRV;
VAR F:File;
    leidos:word;
    dir, des_dir, seg_dir:longint;

BEGIN
 Assign(F,'NMP.DRV');
 System.Reset(F,1);
 IF System.IOResult<>0 THEN BEGIN
                             DRVPtr:=NIL;
                             Exit;
                            END;
 SizeDRV:=system.FileSize(F)+20;
 getmem(DRVPtr,SizeDRV);
 dir:=longint(DRVPtr);
 des_dir:=dir AND $0000FFFF;
 seg_dir:=dir AND $FFFF0000;
 des_dir:=(des_dir+16) SHR 4;
 DrvPtr:=pointer(seg_dir+(des_dir SHL 16));
 system.BlockRead(F,DRVPTR^,SizeDRV-20,leidos);
 system.Close(F);
END;


FUNCTION ColorOf(VAR ZONE;X,Y:Word):Byte; Assembler;
ASM
 LES DI,[ZONE]
 MOV CX,X
 DEC CX
 JZ @SIG
 @BUC:
 ADD DI,fontHeigth
 LOOP @BUC
 @SIG:
 ADD DI,Y
 DEC DI
 MOV AL,ES:[DI]
END;


{PROCEDURE PTrack(Track:Byte;Error:Word);
BEGIN
 IF (CDReady<>0) THEN Error:=3 ELSE Error:=PlayTrack(Track)
END;

PROCEDURE CDStop;
BEGIN
 CDROM.StopCD
END;

FUNCTION ISMSCDEX:Boolean;
BEGIN
 ISMSCDEX:=CDROM.ISMSCDEX
END;

FUNCTION CDReady:Byte;
BEGIN
 CDReady:=CDROM.CDReady;
END;}


FUNCTION GetPixelLength(S:STRING;hasta:Byte):Word;
VAR I:Byte;
    C:Word;
BEGIN
 C:=0;
 FOR I:=1 TO hasta DO C:=C+Width[byte(S[i])];
 GetPixelLength:=C
END;

PROCEDURE FADETO(Paleta:PaletteType;Cycles:Word;Step:Word);

VAR Q:ShortInt;
    Modi:Boolean;
    D:Byte;
    I,j:Word;
BEGIN
 IF Step=0 THEN Exit;
 I:=0;
 WHILE I<=Cycles DO
  BEGIN
   Modi:=False;
   FOR J:=0 TO 767 DO
    BEGIN
     Q:=SGN(Paleta[J]-Pall0[J]);
     FOR D:=1 TO Step DO IF Pall0[J]<>Paleta[J] THEN INC(Pall0[J],Q);
     IF Q<>0 THEN Modi:=True;
    END;
   AllPalette;
   INC(I);
   IF NOT Modi THEN I:=Cycles+1;
  END;
END;


PROCEDURE RFundido(O1,O2:Word);
VAR P:PaletteType;
BEGIN
 FillChar(P,768,63);
 FADETO(P,O1,O2)
END;

PROCEDURE GRAY(O1,O2,O3:Word);
VAR P:PaletteTYpe;
    I:Word;
BEGIN
 MOVED(Pall0,P,768);
 FOR I:=O1 TO O2 DO FillChar(P[I*3],3,(11*Pall0[I*3]+50*Pall0[I*3+1]+30*Pall0[I*3+2]) DIV 100);
 FADETO(P,63,O3);
END;

PROCEDURE FADEOUT(O1,O2,O3:Word);
VAR P:PaletteTYpe;
BEGIN
 MoveD(Pall0,P,768);
 FillChar(P[3*O1],3*(O2-O1+1),0);
 FadeTo(P,O3,1);
END;


PROCEDURE Fundido(O1,O2:Word);
VAR P:PaletteType;
BEGIN
 FillChar(P,768,0);
 FADETO(P,O1,O2)
END;

FUNCTION RealLen(S:String):Word;
VAR Len:Word;
    I:Byte;
BEGIN
 Len:=0;
 FOR I:=1 TO Byte(S[0]) DO
   CASE S[I] OF
    '#','_','*','^':BEGIN END;
    '\','/','‡','|','™':Inc(I,2);
    '@':INC(i,4)
    else inc(len,width[byte(S[I])])
   END;
RealLen:=Len;
END;

Function CheckForWin3 : Win3ModeType;  Assembler;
Asm
  mov    ax,1600h
  int    2Fh
  cmp    al,1
  jbe    @@CheckRealStd
  cmp    al,80h
  jae    @@CheckRealStd
  mov    al,2
  jmp    @@ExitPoint
@@CheckRealStd:
  mov    ax,4680h
  int    2Fh
  or     ax,ax
  jnz    @@notWin
  mov    al,1
  jmp    @@ExitPoint
@@notWin:
  xor    al,al
@@ExitPoint:
end;


FUNCTION Running4DOS : Boolean; Assembler;
 ASM
  MOV AX,0D44Dh
  SUB BX,BX
  INT 2Fh
  CMP AX,44DDh
  JZ @OK
  SUB AL,AL
  JMP @FIN
 @OK: MOV AL,1
 @FIN:
END;

PROCEDURE InitCD(VAR F,L:Word);
BEGIN
 Flags[13]:=0;
 CDInitInfo;
 IF CDInf.NumCD=0 THEN Flags[13]:=1 ELSE
 IF CDInf.Hitrack=0 THEN Flags[13]:=2;
 F:=CDInf.Lotrack;L:=CDInf.Hitrack
END;

Function OS2_GetVersion: Word; Assembler;
Asm
  MOV    AH, 30h  { Dos Get Version Call }
  INT    21h      { AL = major version * 10, AH = minor version }
  MOV    BH, AH   { save minor version }
  xor    AH, AH
  MOV    CL, 10
  div    CL       { divide by 10 to get the major version }
  MOV    AH, BH   { restore minor version }
  XCHG   AH, AL   { AH = major, AL = minor }
end;

FUNCTION GetKey:Word; Assembler;
(* Devuelve C¢digo de teclado:

            Si Getkey   <256    -> C¢digo ASCII estandar
                        >256    -> C¢digo extendido ->Hi(GetKey)= C¢digo
                        =0      -> No hay tecla pulsada *)
ASM
 MOV AH,1
 INT 16h
 MOV AX,0
 JNZ @LeerKey
@Leerkey:
 SUB AH,AH
 INT 16h
 OR AL,AL
 JZ @FIN
 SUB AH,AH
@FIN:
END;

FUNCTION BitWise(W:Word):String;
VAR A:String;
    B:Word;
BEGIN
 A:='';
 WHILE W<>0 DO
  BEGIN
   B:=W MOD 2;
   W:=W SHR 1;
   A:=char(b+48)+A;
  END;
 BitWise:=Copy('0000000000000000',1,16-byte(A[0]))+A;
END;

FUNCTION VALBIN(S:STRING):Word;
VAR I:Byte;
    Total:Word;
BEGIN
 Total:=0;
 FOR I:=1 TO 16 DO
  BEGIN
   TOTAL :=TOTAL SHL 1;
   Inc(Total,byte(S[I])-48);
  END;
 VALBIN:=Total
END;

BEGIN
 FontPtr:=NIL;
END.

