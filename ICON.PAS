PROGRAM ICONOS;

{$X+}
{$I-}
{$R-}

USES DOS,VGA256,RATON13h,CRT;

VAR Color:Byte;
    GetX,GetY:Word;
PROCEDURE SetColor(b:Byte);
BEGIN
 Color:=B
END;



FUNCTION GetColor:Byte;
BEGIN
 GetColor:=Color;
END;

PROCEDURE Moveto(XX,YY:WOrd);
BEGIN
 GetX:=XX;
 GetY:=YY;
END;



TYPE Caracter=PACKED ARRAY[1..8,1..8] OF Byte; (*Rejilla de caracter*)
     CharSett=ARRAY [31..250] OF Caracter; (*Guarda juego de caracteres*)
     Ik=ARRAY[0..31,0..31] OF Byte;
VAR  Sett:CharSett;  (*Juego de caracteres en uso*)
     FAux:FILE;
     Icono:Ik;
     I,J,K,L:Word;
     TamExe:Longint;
     Width: Byte; (*Anchura del font de caracteres*)
     GetColor2:Byte;
     PColor:Byte;
     X,Y:Word;
     Ch:Char;
     Ex:Boolean;
     Explor,camb:byte;
     iz,de,ce:Boolean;
     DosName:String;

FUNCTION GetPixel(X,Y:Word):Byte;
BEGIN
 GetPixel:=Mem[$A000:320*Y+X];
END;


FUNCTION STRS(C:Byte):String;
VAR St:String;
BEGIN
 STR(C,St);
 STRS:=St
END;

PROCEDURE ClearLine;
BEGIN
 FillChar(Mem[$a000:32000],3200,0)
END;

PROCEDURE OuttextH(St:String);
VAR I:Word;
BEGIN
 FOR I:=1 TO length(St) DO
  BEGIN
   FOR J:=1 TO Width DO
    FOR K:=1 TO 8 DO
      IF NOT(Sett[Ord(St[I]),J,K] IN [0]+[2]) THEN
        PutPixel(GetX+J-1,GetY+K-1,GetColor)
         ELSE IF Sett[Ord(St[I]),J,K]=2 THEN
          PutPixel(GetX+J-1,GetY+K-1,GetColor2)
           ELSE IF Sett[Ord(St[I]),J,K]=0 THEN
            PutPixel(GetX+J-1,GetY+K-1,0);
   MoveTo(GetX+width,gety)
  END
END;

PROCEDURE Outtext(St:String);
VAR I:Word;
BEGIN
 FOR I:=1 TO length(St) DO
  BEGIN
   FOR J:=1 TO Width DO
    FOR K:=1 TO 8 DO
      IF NOT(Sett[Ord(St[I]),J,K] IN [0]+[2]) THEN
        PutPixel(GetX+J-1,GetY+K-1,GetColor)
         ELSE IF Sett[Ord(St[I]),J,K]=2 THEN
          PutPixel(GetX+J-1,GetY+K-1,GetColor2);
   MoveTo(GetX+width,gety)
  END
END;

{$I TOMATEC.SRC}
{$I descart.src}

PROCEDURE PPX(X,Y:Word;C:Byte);
VAR R:Registers;
BEGIN
 R.Cx:=X;
 R.Dx:=y;
 R.AH:=$0C;
 R.Al:=C;
 R.BH:=0;
 Intr($10,R)
END;


PROCEDURE LeerSave(Ask:String;VAR St:String);

CONST Control:Set OF Char=[#27]+[#8]+[#13];

VAR Validas:Set OF Char;

VAR Ch:Char;
    Extend:boolean;
    Explor,Camb:Byte;
    LastL:Byte;
    maxavst:string;

CONST Y0=100;

BEGIN
PunteroOff;
Validas:=['a'..'z']+['A'..'Z']+['á']+['Ä']+['†'..'•']+
         ['0'..'9']+['Ç']+['ö']+['Å']+['"'];
St:='_';
LastL:=1;
Moveto(0,y0);
OuttextH(ask+st);
REPEAT
Ch:='#';
MoveTo(width*length(ask),y0);
OuttextH(St);
IF Length(st)<LastL THEN BEGIN
                          Moveto(Width*length(ask+st),y0);
                          FOR I:=1 TO LastL-length(st) DO
                           BEGIN
                            OuttextH(' ');
                            MoveTo(Getx+width,Y0)
                           END
                         END;
LastL:=length(st);
IF Tomatecla(Ch,Extend,Explor,Camb) THEN
 BEGIN
  IF (Ch<>'#') AND (Ch IN Validas) AND (LENgth(St)<9) THEN
   St:=Copy(St,1,Pos('_',St)-1)+Ch+Copy(St,Pos('_',St),length(st));
  IF Ch=#008 THEN St:=Copy(St,1,Pos('_',ST)-2)+Copy(St,pos('_',St),length(st));
  IF Extend AND (Explor=83) THEN St:=Copy(St,1,Pos('_',ST)) + Copy(St,pos('_',St)+2,length(st));
  IF Extend AND (Explor=75) THEN IF Pos('_',ST)>1 THEN St:=Copy(St,1,Pos('_',ST)-2)+'_'+St[Pos('_',ST)-1]
    +Copy(St,Pos('_',ST)+1,length(st));
  IF Extend AND (Explor=77) THEN IF Pos('_',st)<>length(st) THEN St:=Copy(St,1,Pos('_',ST)-1)+St[Pos('_',ST)+1]
    +'_'+Copy(St,Pos('_',ST)+2,length(st));
  IF Extend AND (Explor=71) THEN St:='_'+Copy(St,1,Pos('_',ST)-1) + Copy(St,pos('_',St)+1,length(st));
  IF Extend AND (Explor=79) THEN St:=Copy(St,1,Pos('_',ST)-1) + Copy(St,pos('_',St)+1,length(st))+'_';

 END;
UNTIL ((Ch=#13) AND (St<>'_'));
 St:=Copy(St,1,pos('_',st)-1)+Copy(St,pos('_',st)+1,length(st));
 MoveTo(width*length(ask),Y0);
 OuttextH(St+' ');
 Descartecla;
 St:=St+'.ICO';
 ClearLine;
 resetRaton;
 PunteroOn;
END;


PROCEDURE SetColor2(B:Byte);
BEGIN
GetColor2:=B
END;

PROCEDURE MostrarPaleta;
VAR C:Byte;
    X,Y:Word;
BEGIN
 FOR C:=0 TO 255 DO
  FOR X:=(C MOD 32) *10 TO (C MOD 32) *10+8 DO
   FOR Y:=(C DIV 32) *10 TO (C DIV 32) *10+8 DO
    PutPixel(X,Y+120,C)
END;

PROCEDURE Init(B:Byte);
VAR Regs:Registers;
BEGIN
 Regs.AX:=B;
 Intr($10,Regs);
END;

PROCEDURE Icon(X,Y:Word;Orden:Word);
 TYPE ICO=ARRAy[0..31,0..31] OF Byte;
  VAR F:File;
      IC:ICO;
      I,J:Word;
      TamEXE:Longint;

 BEGIN
  Assign(F,'ICON.EXE');
  Reset(F,1);
  BlockRead(F,I,2); (* MZ *)
  BlockRead(F,I,2);
  BlockRead(F,J,2);
  Dec(J);
  TamEXE:=I+512*J;
  Seek(F,TamEXE+1024*Orden);
  BlockRead(F,Ic,1024);
  Close(F);
  FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO
   PutPixel(X+I,Y+J,Ic[I,J]);
  END;


PROCEDURE EsperaBarrido; Forward;


PROCEDURE VerIco;
BEGIN
 Esperabarrido;
 PunteroOff;
 FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO
  FOR K:=I*3+1 TO I*3+3 DO FOR L:=J*3+1 TO J*3+3 DO PutPixel(K,L,Icono[I,J]);
 PunteroOn;
END;

PROCEDURE VerSIco;
BEGIN
 Esperabarrido;
 PunteroOff;
 FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO
  PutPixel(150+I,20+J,Icono[I,J]);
 PunteroOn;
END;

PROCEDURE VerIcoE;
BEGIN
 EsperaBarrido;
 PunteroOff;
 FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO
  FOR K:=I*3+1 TO I*3+3 DO FOR L:=J*3+1 TO J*3+3 DO PPx(K,L,Icono[I,J]);
 PunteroOn;
END;

PROCEDURE VerSIcoE;
BEGIN
 EsperaBarrido;
 PunteroOff;
 FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO
  PPX(150+I,20+J,Icono[I,J]);
 PunteroOn;
END;

PROCEDURE FILL(X,Y:Byte;C:Byte);
BEGIN
 IF Icono[X,Y]=C THEN
  BEGIN
   Icono[X,Y]:=PColor;
   IF x<31 THEN Fill(X+1,Y,C);
   IF y<31 THEN Fill(X,Y+1,C);
   IF x>0  THEN Fill(X-1,Y,C);
   IF y>0  THEN Fill(X,Y-1,C)
  END
END;

PROCEDURE ROTAR;
VAR B:ik;
BEGIN
 FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO B[31-I,J]:=Icono[J,I];
 Icono:=B
END;

PROCEDURE MASK;
BEGIN
 FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO IF Icono[I,J]<>255 THEN ICONO[I,J]:=0;
END;

PROCEDURE Scroll(B:Byte);
BEGIN
CASE B OF
 1:FOR I:=0 TO 31 DO FOR J:=1 TO 31 DO Icono[I,J-1]:=Icono[I,J];
 2:FOR I:=0 TO 31 DO FOR J:=30 DOWNTO 0 DO Icono[I,J+1]:=Icono[I,J];
 3:FOR I:=1 TO 31 DO FOR J:=0 TO 31 DO Icono[I-1,J]:=Icono[I,J];
 4:FOR I:=30 DOWNTO 0 DO FOR J:=0 TO 31 DO Icono[I+1,J]:=Icono[I,J];
END;
VerIco;
VerSIco;
END;

PROCEDURE PRESENTA;
BEGIN
InitVGA256;
SetColor2(8);
SetColor(0);
MoveTo(3,110);
Refresh(Off);
RangoColumna(311,0);
RangoFila(191,0);
MostrarPaleta;
FillChar(Mem[$a000:111*320],2240,7);
FillChar(Mem[$a000:110*320],320,15);
FillChar(Mem[$a000:118*320],320,15);
FOR I:=111 TO 117 DO PutPixel(0,I,15);
FOR I:=111 TO 117 DO PutPixel(319,I,15);
Outtext('      Dise§ador de Iconos (C) 1994 NM Software');
FOR I:=0 TO 97 DO PutPixel(0,I,15);
FOR I:=0 TO 97 DO PutPixel(97,I,15);
FOR I:=0 TO 97 DO PutPixel(I,0,15);
FOR I:=0 TO 97 DO PutPixel(I,97,15);
FOR I:=48 TO 58 DO PutPixel(119,I,15);
FOR I:=48 TO 58 DO PutPixel(131,I,15);
FOR I:=120 TO 130 DO PutPixel(I,47,15);
FOR I:=120 TO 130 DO PutPixel(I,59,15);
FOR I:=19 TO 52 DO PutPixel(149,I,15);
FOR I:=19 TO 52 DO PutPixel(182,I,15);
FOR I:=149 TO 182 DO PutPixel(I,19,15);
FOR I:=149 TO 182 DO PutPixel(I,52,15);
Icon(287,66,6);
Icon(287,33,1);
Icon(253,66,7);
Icon(287,0,5);
Setcolor(15);
Icon(219,0,2);
Icon(253,0,4);
Icon(219,33,0);
Icon(219,66,3);

FOR I:=0 TO 10 DO FOR J:=0 TO 10 DO PutPixel(120+I,48+J,PColor);
MoveTo(120,62);
OuttextH(STRS(PColor)+'   ');
VerIco;
VerSIco;
resetraton;
RangoFila(191,0);
RangoColumna(311,0);
SetDesp(-1,-1);
PunteroOn;
END;

VAR Pall: AllPaletteTYpe;

PROCEDURE NEGATE;
 VAR B:IK;
 BEGIN
  FOR i:=0 TO 31 DO FOR J:=0 TO 31 DO B[i,J]:=(Icono[31-I,J]);
  Icono:=B;
  VerIco;
  VerSico
 END;

PROCEDURE ESPERABARRIDO; Assembler;
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


PROCEDURE SueltaRaton; Assembler;
ASM
@@1:
 MOV AX,3
 INT 33h
 OR BL,BL
 JNZ @@1
END;

BEGIN  (*PRINCIPAL*)
DirectVideo:=False;
WriteLn('DISE•ADOR DE ICONOS PARA PARSER NMP v4.1');
WriteLn;
ResetRaton;
IF NOT (ContBoton IN [2..3]) THEN BEGIN
                                   WriteLn('Rat¢n no se encuentra o desconocido.');
                                   Halt(2)
                                  END;
CASE CONTBOTON OF
 2:WriteLn('Microsoft Mouse encontrado.');
 3:WriteLn('Mouse System Mouse encontrado')
END;
(* Primero leo set de caracteres *)
Assign(FAux,'SETMAKE.EXE');
Reset(Faux,1);
BlockRead(Faux,I,2); (* MZ *)
BlockRead(Faux,I,2);
BlockRead(Faux,J,2);
Dec(J);
TamEXE:=I+512*J;
Seek(Faux,TamEXE);
BlockRead(FAux,Sett,SizeOf(Sett));
Close(FAux);
width:=0;
FOR I:=1 to 8 DO IF sett[31,I,1]=1 THEN Inc(width);
FOR i:=0 TO 31 DO FOR J:=0 TO 31 DO Icono[I,J]:=0;
PColor:=1;
Presenta;
GetAllPalette(Pall);
FillChar(Pall[255*3],3,63);
SetAllPalette(Pall);
Refresh(On);
REPEAT
Tomatecla(ch,ex,explor,camb);

Iz:=False;
De:=False;
LeerRaton(X,Y,iz,ce,de);

IF Iz AND (Y>119) THEN BEGIN
                        IF NOT (((Y MOD 32)=9) OR ((X MOD 32)=9)) THEN
                         BEGIN
                          Esperabarrido;
                          PunteroOff;
                          PColor:=GetPixel(X,Y);
                          PunteroOn;
                          FOR I:=0 TO 10 DO FOR J:=0 TO 10 DO PutPixel(120+i,48+j,PColor);
                          MoveTo(120,62);
                          OuttextH(STRS(PColor)+'   ');
                         END;
                       END;

IF IZ AND (Y IN [1..95]) AND (X>0) AND (X<96) THEN
 BEGIN
  Icono[X DIV 3,Y DIV 3]:=PColor;
   EsperaBarrido;
  PunteroOff;
  FOR K:=(X DIV 3) * 3 + 1 TO (X DIV 3)*3+3 DO
   FOR L:=(Y DIV 3)*3+1 TO (Y DIV 3)*3+3 DO
    PutPixel(K,L,Icono[X DIV 3,Y DIV 3]);
    VerSIco;
  PunteroOn;
 END;
IF NOT ((Y IN [1..95]) AND (X>0) AND (X<96)) THEN
  BEGIN
   MoveTo(120,72);
   EsperaBarrido;
   PunteroOff;
   OuttextH('   ');
   PunteroOn;
  END;

IF (Y IN [1..95]) AND (X>0) AND (X<96) THEN
 IF NOT(IZ OR DE) THEN BEGIN
                        MoveTo(120,72);
                        OuttextH(Strs(Icono[X DIV 3,Y DIV 3])+'   ');
                       END;

IF DE AND (Y IN [1..95]) AND (X>0) AND (X<96) THEN
 IF Icono[X DIV 3,Y DIV 3]<>PColor THEN
  BEGIN
   FILL(X DIV 3, Y DIV 3,Icono[X DIV 3,Y DIV 3]);
   VerIco;
   VerSIco;
   SueltaRaton;
  END;

IF IZ AND (Y IN [1..30]) AND (X>286) AND (X<319) THEN
 BEGIN
  LeerSave('Nombre del fichero a cargar:',DosName);
  DosName:='ADV\'+DosName;
  IF FSearCh(DosName,'')<>'' THEN
   BEGIN
    Assign(FAux,DosName);
    Reset(FAux,1);
    FOR I:=0 TO 31 DO For J:=0 TO 31 DO BlockRead(FAux,Icono[J,I],1);
    Close(FAux);
    VerIco;
    VerSIco;
   END
   ELSE BEGIN
         Moveto(0,100);
         EsperaBarrido;
         PunteroOff;
         Outtext('Fichero no se encuentra. Pulse una tecla.');
         ReadKey;
         ClearLine;
         PunteroOn;
        END;
 END;

IF IZ AND (Y IN [66..98]) AND (X>286) AND (X<319) THEN
 BEGIN
  FOR i:=0 TO 31 DO FOR J:=0 TO 31 DO Icono[I,J]:=0;
  VerIco;
  verSIco;
  SueltaRaton;
 END;

IF IZ AND (Y IN [33..62]) AND (X>219) AND (X<250) THEN
 BEGIN
  IF (Y IN [33..40]) AND (X>227) AND (X<277) THEN Scroll(1);
  IF (Y IN [55..62]) AND (X>227) AND (X<277) THEN Scroll(2);
  IF (Y IN [41..54]) AND (X>219) AND (X<234) THEN Scroll(3);
  IF (Y IN [41..54]) AND (X>234) AND (X<250) THEN Scroll(4);
  SueltaRaton;
 END;

IF IZ AND (Y IN [1..30]) AND (X>253) AND (X<284) THEN
 BEGIN
  Mask;
  VerIco;
  VerSIco;
  SueltaRaton;
 END;

IF IZ AND (Y IN [1..30]) AND (X>219) AND (X<250) THEN
 BEGIN
  Rotar;
  VerIco;
  VerSIco;
  SueltaRaton;
 END;
IF IZ AND (Y IN [66..98]) AND (X>219) AND (X<250) THEN
 BEGIN
  NEGATE;
  SueltaRaton;
 END;

IF IZ AND (Y IN [66..98]) AND (X>253) AND (X<284) THEN
 BEGIN
  Ex:=True;
  Explor:=45
 END;

IF IZ AND (Y IN [33..62]) AND (X>286) AND (X<319) THEN
 BEGIN
  LeerSave('Nombre del fichero a grabar:',DosName);
  Dosname:='ADV\'+DosName;
  Assign(FAux,DosName);
  ReWrite(FAux,1);
  FOR I:=0 TO 31 DO For J:=0 TO 31 DO BlockWrite(FAux,Icono[J,I],1);
  Close(FAux);
 END;

UNTIL Ex And (Explor=45);
FinishRaton;
TextMode(LastMode);
WriteLn('1994 (C) NM Software.');
END.

