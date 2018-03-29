
{$X+}
{$I-}

USES CRT,DOS;


CONST ID:STRING='CONFIGURACION DE SVGA. 1995 (C) NM SOFTWARE'+#10+#13+#26;

FUNCTION TomaTecla(VAR Cha  : Char;
                VAR Extend : Boolean;
                VAR Explor : Byte;
                Var Camb   : Byte) : Boolean;
VAR Listo : Boolean;
BEGIN
  Extend := False;
  Explor := 0;
  ASM
   MOV AH,01h
   INT 16h
   JZ @NOTECLA
   XOR AH,AH
   INT 16h
   LES DI,[CHA]
   MOV ES:[DI],AL
   LES DI,[EXPLOR]
   MOV ES:[DI],AH
   MOV AX,1 (* DEVUELVE TRUE *)
   JMP @FIN
   @NOTECLA:
   XOR AX,AX (* DEVUELVE FALSE *)
   @FIN:
   MOV LISTO,AL
  END;
  Extend := CHA=#0;
  ASM
   MOV AH,02;          { AH=2: Lee estado shift/alt/ctrl }
   INT 16h
   LES DI,[CAMB]
   MOV ES:[DI],AL
  END;
  TomaTecla := Listo
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

PROCEDURE CursorOff; Assembler;
ASM
 MOV AX,100h
 MOV CX,2000h
 INT 10h
END;

var t:FILE;

CONST NumVGAS=40;

CONST Nombres:ARRAY[0..NumVGAS] OF String[80]=('',
'','Acumos','Ahead A','Ahead B','ATI VGA Wonder','ATI VGA Wonder+',
'ATI Ultra 8514A','ATI XL','Chips & technology','Cirrus Logic GD54','Definicon, 16 bit',
'Diamond 24x','Diamond SpeedStar 24','Everex EV-673','Everex 678',
'EVEREX Vision VGA HC','Genoa 5400','Genoa 6400','Genoa 7900 24 bit',
'HeadLand 1024i','Hi Res 512','Maxxon','Chips & technologies MK82452',
'NCR 77C22','Ose','Orchid Fahrenheight 1280','Orchid PRO Designer',
'Paradise VGA Pro','Primus P2000 GA','Compaq QVision','Realtek RTVGA',
'S3 Graphics Accelerator','STB EM 16','Phoebes','Maxxon','Trident 8900',
'Tseng ET-3000','Tseng ET-4000','Video 7 VRAM','Western Digital 90C');

CONST Chips:ARRAY[0..NumVGAS] OF String[80]=(
'VESA 640x400','VESA 640x480','ACUMOS','AHEADA','AHEADB','ATI OLD','ATI NEW','ATI NEW','ATI NEW',
'C&T','VESA','TSENG 4000','PARADISE','TSENG 4000','EVEREX','TRIDENT 8800',
'TSENG 4000','TSENG 3000','GENOA','TSENG 4000','HEADLAND','ZYMOS','TRIDENT 8800',
'C&T','NCR','SGL','S3','TSENG 4000','PARADISE','PRIMUS','QVISION','REALTEK',
'S3','TSENG 4000','TRIDENT 8800CS','TRIDENT 8800CS','TRIDENT 8900','TSENG ET3000',
'TSENG ET4000','VIDEO7','PARADISE');

CONST MODE:ARRAY[0..NUMVGAS] OF WORD=(0,$101,$5E,$60,$60,$61,$61,$61,$61,$78,$100,
$2F,$5E,$2F,$14,$14,$2F,$2E,$2E,$2F,$66,$5C,$5C,$78,$5E,$53,$201,$2F,$5E,$2D,$32,
$25,$201,$78,$5C,$5C,$5C,$2E,$2F,$66,$5E);

CONST MODE2:ARRAY[0..NUMVGAS] OF WORD=(0,$4F02,0,0,0,0,0,0,0,0,$4F02,0,0,0,$70,$70,
0,0,0,0,$6F05,0,0,0,0,0,$4F02,0,0,0,0,0,$4F02,0,0,0,0,0,0,$6F05,0);

PROCEDURE Center(S:String);
BEGIN
 GotoXY(40-length(S) DIV 2,Wherey);
 Write(S);
END;

PROCEDURE SetupSVGA;
VAR ch:char;Extend:boolean;explor,camb:byte;
    I:Byte;
BEGIN
 ClrScr;
 I:=0;
 textAttr:=$1F;
 ClrEol;
 CENTER('CONFIGURACION SVGA');
 GotoXY(1,25);Clreol;CENTER('Use cursor arriba y cursor abajo para seleccionar su SVGA.');
 TextAttr:=$07;
 Ch:=#0;
 WHILE NOT (Ch IN [#13,#27]) DO
  BEGIN
   GotoXY(1,10);
   ClrEol;
   IF I<>NumVGAS THEN Write(#25);
   GotoXY(80,10);
   IF I<>0 THEN Write(#24);
   GotoXY(1,10);
   Center(Nombres[I]+' ['+Chips[I]+']');
   REPEAT UNTIL Tomatecla(Ch,Extend, Explor,Camb);
   IF Extend AND (Explor=72) THEN IF I>0 THEN DEC(I);
   IF Extend AND (Explor=80) THEN IF I<NumVGAS THEN INC(I);
   IF (CH=#13) AND (I<>0) THEN BEGIN
                   Assign(T,'SVGA.CFG');
                   ReWrite(T,1);
                   IF IOResult<>0 THEN BEGIN
                                        WriteLn('Disco protegido o lleno. No se grab¢ la configuraci¢n.');
                                        Halt
                                       END;
                   BlockWrite(T,ID[1],255);
                   BlockWrite(T,Mem[0:0],15);
                   MODE[I]:=MODE[I] XOR $1971;
                   MODE2[I]:=MODE2[I] XOR $1971;
                   Blockwrite(T,Mode[I],2);
                   Blockwrite(T,Mode2[I],2);
                   BlockWrite(T,Mem[0:89],15);
                   Close(T);
                  END;
   IF (I=0) AND (Ch=#13) THEN BEGIN
                Assign(T,'SVGA.CFG');
                Erase(T);
                IF IOResult<>0 THEN BEGIN
                                     WriteLn('Disco protegido o lleno. No se grab¢ la configuraci¢n.');
                                     Halt
                                    END;
               END;
 END;
END;

BEGIN
 CursorOff;
 SetupSVGA;
 CursorOn;
 ClrScr;
END.