PROGRAM SETMAKE;

{$X+}
{$B-}
{$R-}
{$I-}

USES VGA256,CRT,DOS,RATON13h;

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



TYPE CARACTER=PACKED ARRAY[1..8,1..8] OF Byte;
     CHARSET=ARRAY [31..250] OF CARACTER;
VAR  WIDTH:ARRAY[31..250] OF Byte;


VAR Font1,Sett:Charset;
    Salir:Boolean;
    Nombre:String;
    Color2,Fondo:Byte;
    I,J,K:Word;
    X,Y:Word;
    iz,ce,de:Boolean;
    Actual:Byte;
    Car:Caracter;
    BeepOff:Boolean;
    Ch:Char;
    Extend:Boolean;
    Explor,Camb:Byte;



{$I TOMATEC.SRC}
{$I DESCART.SRC}


PROCEDURE Error(N:Byte);
BEGIN
 TextMode(LastMode);
 GotoXY(1,1);
 ClrEOL;
 CASE N OF
  2:WriteLn('No se encuentra rat¢n o es desconocido.');
  4:WriteLn('Fichero n¢ v lido, s¢lo se aceptan fonts de 8 pixels de alto.');
  3:WriteLn('Error en los par metros.La sintaxis es: SETMAKE N§Set');
 END;
 ReadKey;
 Halt(N)
END;

PROCEDURE ReadFont1;
VAR F:File;
    I,J:Word;
BEGIN
 Assign(F,ParamStr(0));
 Reset(F,1);
 BlockRead(F,I,2); (*MZ*)
 BlockRead(F,I,2);
 BlockRead(F,J,2); DEC(J);
 Seek(F,J*512+I);
 BlockRead(F,Font1,SizeOf(Font1));
 Close(F)
END;

FUNCTION Inn(A,B:Word):Boolean;
BEGIN
Inn:= (x>=A) AND (X<=B)
END;

PROCEDURE Line(X0,Y0,XF,YF:Word);
 VAR I:Integer;
 BEGIN
  IF X0=XF THEN FOR I:=Y0 TO YF DO PutPixel(X0,i,GetColor)
           ELSE FOR I:=X0 TO XF DO PutPixel(I,Y0,GetColor)
 END;


PROCEDURE Rectangle(X0,Y0,XF,YF:Word);
VAR I:Word;
BEGIN
 FOR I:=X0 TO XF DO PutPixel(I,Y0,GetColor);
 FOR I:=X0 TO XF DO PutPixel(I,YF,GetColor);
 FOR I:=Y0+1 TO YF-1 DO PutPixel(X0,I,GetCOlor);
 FOR I:=Y0+1 TO YF-1 DO PutPixel(XF,I,GetCOlor);
END;
PROCEDURE WriteLn2(St:String);
VAR I,J,K:Byte;
BEGIN
 FOR I:=1 TO Length(St) DO
  BEGIN
   FOR J:=1 TO 8 DO
    FOR K:=1 TO 6 DO
     IF NOT(Font1[Ord(St[I]),K,J] IN [0]+[2]) THEN PutPixel(GetX+K-1,GetY+J-1,GetColor)
      ELSE IF Font1[Ord(St[I]),K,J]=0 THEN PutPixel(GetX+K-1,GetY+J-1,Fondo)
       ELSE PutPixel(GetX+K-1,GetY+J-1,Color2);
   IF GetX>313 THEN MoveTo(0,Gety+8)
               ELSE MoveTo(GetX+6,GetY);
  END;
END;


PROCEDURE ReadLn2(VAR S:String;Long:Byte);
VAR Ch:Char;
    Extend:Boolean;
    Explor,Camb:Byte;
    X,Y:Word;

BEGIN
 DescarTecla;
 X:=GetX;
 Y:=GetY;
 REPEAT
  Ch:=#0;
  Tomatecla(Ch,Extend,Explor,Camb);
  IF (Ch IN [#32..#255]) AND (Length(S)<Long) THEN S:=S+Ch;
  IF (Ch=#8) AND (S<>'') THEN S:=Copy(S,1,length(s)-1);
  MoveTo(X,Y);
  WriteLn2(S+' ');
 UNTIL Ch=#13;
  MoveTo(0,Y+8);
END;

PROCEDURE Icon(X,Y:Word;Orden:Word);
 TYPE ICO=ARRAy[0..31,0..31] OF Byte;
  VAR F:File;
      IC:ICO;
      I,J:Word;
      TamEXE:Longint;

 BEGIN
  Assign(F,'SETMAKE.EXE');
  Reset(F,1);
  BlockRead(F,I,2); (* MZ *)
  BlockRead(F,I,2);
  BlockRead(F,J,2);
  Dec(J);
  TamEXE:=I+512*J+14080;
  Seek(F,TamEXE+1024*Orden);
  BlockRead(F,Ic,1024);
  Close(F);
  FOR I:=0 TO 31 DO FOR J:=0 TO 31 DO
   PutPixel(X+I,Y+J,Ic[I,J]);
END;

Procedure MostrarCaracter(X0,Y0:Word;C:Byte);
VAR X,Y:Byte;
    Ink1,Ink2:Byte;
BEGIN
  INK1:=15;
  INK2:=8;
  FOR X:=1 TO 8 DO
   BEGIN
    IF x>Width[C] THEN BEGIN
                        INK1:=0;
                        INK2:=0;
                        Fondo:=0;
                       END;
    FOR Y:=1 TO 8 DO
     IF NOT (Sett[C,X,y] IN [0]+[2]) THEN Putpixel(X0+x-1,y0+y-1,ink1)
      ELSE IF Sett[C,X,y]=2 THEN Putpixel(X0+x-1,y0+y-1,ink2)
       ELSE IF Sett[C,X,y]=0 THEN Putpixel(X0+x-1,y0+y-1,Fondo)
  END;
END;

PROCEDURE CargarFont(Nombre:String);
VAR F:File;
    I:Byte;

PROCEDURE LOADSD2;
VAR J:Byte;
    I:Word;
    L,M:Byte;
    F:FILE;
BEGIN
 Assign(F,'ADV\'+Nombre+'.FNT');
 Reset(F,1);
 FOR J:=1 TO 16 DO
  BlockRead(F,I,1); (* Pasa de cabecera *)
 FOR I:=1 TO 32*8 DO
  BlockRead(F,J,1); (* Paso de 32 caracteres *)
 FOR I:=32 TO 250 DO
   FOR J:=1 TO 8 DO
    BEGIN
     BlockRead(F,L,1);
     FOR K:=1 TO 8 DO
      BEGIN
       Boolean(SETT[I,9-K,J]):=ODD(L);
       L:=L SHR 1;
      END;
   END;
FillChar(WIDTH,SizeOf(Width),8);
CLOSE(F);
END;

BEGIN
 Assign(F,'ADV\'+Nombre+'.FNT');
 Reset(F,1);
 IF FileSize(F)=2064 THEN BEGIN
                           Close(F);
                           LoadSD2;
                           Exit
                          END;
 BlockRead(F,Sett,SizeOf(Sett));
 IF EOF(F) THEN BEGIN
                 Width[31]:=0;
                 FOR I:=1 TO 8 DO IF Sett[31,I,1]=1 THEN INC(Width[31]);
                 FillChar(width,SizeOf(Width),width[31]);
                END
           ELSE BEGIN
                 BlockRead(F,width,Sizeof(Width));
                 IF FileSize(F)<>14300 THEN Error(4);
                END;
 Close(F);
END;

PROCEDURE GrabarFont;
    PROCEDURE FileSaved;
    VAR X0,Y0:Word;
        P:Pointer;
        SaveCOlor:Byte;


    BEGIN
    PunteroOff;
    GetMem(P,64000);
    Move(Mem[$a000:0000],P^,64000);
    SaveColor:=GetColor;
    FOR I:=141 TO 159 DO FillChar(Mem[$A000:320*I+71],178,7);
    SetColor(15);
    Rectangle(70,140,249,160);
    SetColor(8);
    Line(70,141,70,160);
    Line(71,160,250,160);
    SetColor(8);
    Fondo:=7;
    Color2:=7;
    MoveTo(83,146);
    WriteLn2(' Fichero ha sido grabado');
    REPEAT
     LeerRaton(X,Y,IZ,ce,de);
    UNTIL IZ;
    Move(P^,Mem[$a000:0000],64000);
    FreeMem(P,64000);
    SetColor(SaveColor);
    REPEAT
     LeerRaton(X,Y,IZ,ce,de);
    UNTIL NOT IZ;
    PunteroOn;
    END;


VAR F:File;
    I:Byte;
BEGIN
 Assign(F,'ADV\'+Nombre+'.FNT');
 ReWrite(F,1);
 BlockWrite(F,Sett,SizeOf(Sett));
 BlockWrite(F,Width,SizeOf(Width));
 Close(F);
 FileSaved;
END;

PROCEDURE CrearFont;
VAR J:Byte;
    Wst:String;
    Code:Integer;

BEGIN
 FillChar(Sett,14080,0);
 (* FOR I:=31 TO 250 DO
  FOR J:=1 TO 8 DO
   FOR K:=1 TO 8 DO Sett[I,J,K]:=0; *)
 SetColor(32);
 WriteLn2('  SETMAKE V5.0 (C) 1995 NM Sofware.');
 MoveTo(0,Gety+8);
 MoveTo(0,Gety+8);
 SetColor(4);
 MoveTo(0,Gety+8);MoveTo(0,Gety+8);
 WriteLn2('Juego de Caracteres nuevo.');
 SetColor(15);
 REPEAT
  Moveto(0,80);
  WriteLn2('Teclee el Ancho en pixels (4-8):');
  Wst:='';
  ReadLn2(WSt,1);
  Val(WSt,Width[31],Code);
  IF NOT (Width[31] IN [1..8]) THEN BEGIN
                                 MoveTo(0,Gety+8);
                                 WriteLn2('ERROR: El ancho debe estar entre 1 y 8 pixels.');
                                 ReadKey;
                                END;
  FillChar(Mem[$A000:80*320],320*119,0);
 UNTIL Width[31] IN [1..8];
 FillChar(WIDTH,SizeOf(Width),width[31]);
END;

PROCEDURE MostrarFont;
VAR I:BYTE;
BEGIN
Fondo:=0;
FOR I:=32 TO 250 DO
 MostrarCaracter((((I-32)*8 DIV 8)*16) MOD 320,(I-32) DIV 20*8+12,i);
END;

FUNCTION SEGURO:Boolean;
VAR P:Pointer;
    sv2,savecol:Byte;
    Ch:Char;
BEGIN
 PunteroOff;
 SaveCol:=Getcolor;
 sv2:=color2;
 SetColor(7);
 getMem(P,64000);
 Move(Mem[$a000:0000],P^,64000);
 FOR I:=91 TO 108 DO FillChar(Mem[$a000:320*I+111],98,getcolor);
 SetColor(8);
 Rectangle(110,90,209,109);
 SetColor(15);
 Line(110,90,209,90);
 Line(209,90,209,109);
 Moveto(120,95);
 Color2:=7;
 Setcolor(8);
 Fondo:=7;
 WriteLn2('¨Seguro? (S/N)');
 Descartecla;
 Ch:=ReadKey;
 Seguro:=(Ch='s') OR (Ch='S');
 Move(P^,Mem[$a000:0000],64000);
 FreeMem(P,64000);
 PunteroOn;
 SetColor(SaveCol);
 Color2:=sv2;
END;

PROCEDURE SueltaRaton;
VAR X,Y:Word;
    iz,ce,de:Boolean;
BEGIN
REPEAT
 LeerRaton(X,Y,iz,ce,de);
UNTIL NOT(iz OR ce OR de);
END;

Procedure Beep;
BEGIN
 IF BeepOff THEN Exit;
 Sound(2000);
 Delay(3);
 Nosound
END;

Procedure Beep2;
BEGIN
 Sound(2000);
 Delay(3);
 Nosound
END;


PROCEDURE MostrarAmpliado;
VAR i,j,k,l:word;
    X,Y,X0,Y0:Word;
    INK1,INK2:Byte;
BEGIN
 PunteroOff;
 INK1:=15;
 INK2:=8;
 FOR I:=1 TO 8 DO
  BEGIN
   IF I>width[actual] THEN BEGIN
                            INK1:=0;
                            INK2:=0;
                           END;
   FOR J:=1 TO 8 DO
   FOR L:=0 TO 7 DO
     IF NOT( Car[i,j] IN [0]+[2]) THEN FillChar(Mem[$a000:201+(i-1)*9+(119+(j-1)*9+l)*320],8,INK1)
      ELSE IF Car[i,j]=2 THEN FillChar(Mem[$a000:201+(i-1)*9+(119+(j-1)*9+l)*320],8,INK2)
                         ELSE FillChar(Mem[$a000:201+(i-1)*9+(119+(j-1)*9+l)*320],8,0);
  END;

  INK1:=15;
  INK2:=8;
  X0:=190;Y0:=120;
  FOR X:=1 TO 8 DO
  BEGIN
   INK1:=15;
   INK2:=8;
   IF X>width[Actual] THEN BEGIN
                            INK1:=0;
                            INK2:=0
                           END;
   FOR Y:=1 TO 8 DO
    IF NOT (Car[X,y] IN [0]+[2]) THEN Putpixel(X0+x-1,y0+y-1,ink1)
     ELSE IF Car[X,y]=2 THEN Putpixel(X0+x-1,y0+y-1,ink2)
      ELSE IF Car[X,y]=0 THEN Putpixel(X0+x-1,y0+y-1,0);
  END;
 PunteroOn;
END;


FUNCTION Strs(B:Byte):String;
VAR S:String;
BEGIN
 STR(B,S);
 Strs:=S
END;

PROCEDURE Barra;
BEGIN
 Moveto(0,102);
 Setcolor(8);
 Fondo:=7;
 WriteLn2(' Font:'+Copy(Nombre+'     ',1,5)
 +' ASCII:'+Copy(Strs(Actual)+'   ',1,3)
 +' Anchos: Font:'+Strs(width[31])+' Caracter:'+Strs(Width[Actual]));
END;


BEGIN   (* PROGRAMA PRINCIPAL *)

(* Inicializaciones *)
DescarTecla;
BeepOff:=False;
ReadFont1;
IF ParamCount<>1 THEN Error(3);
ResetRaton;
IF NOT (ContBoton IN [2..3]) THEN Error(2);
InitVGA256;
Fondo:=0;
Color2:=7;
Nombre:=ParamStr(1);
IF FSearch('ADV\'+Nombre+'.FNT','')='' THEN CrearFont
                                ELSE CargarFont(Nombre);

Actual:=32;
Car:=Sett[32];

(* Crear menu *)
InitVGA256;
Refresh(Off);
Icon(303,118,6);
Icon(303,150,1);
Icon(0,118,2);
Icon(0,150,7);
Icon(16,150,8);
Icon(0,182,0);
Fondo:=7;
Color2:=7;
SetColor(8);
FillChar(Mem[$a000:0],320,15);
FillChar(Mem[$a000:320],2560,7);
FillChar(Mem[$A000:2880],320,15);
MoveTo(1,1);
WriteLn2('         SetMake v5.0 (C) 1995 NM SoftWare.');
SetColor(15);
Fondo:=0;
MostrarFont;
FillChar(Mem[$a000:320*100],320,15);
FillChar(Mem[$a000:320*101],3200,7);
FillChar(Mem[$A000:320*111],320,15);
FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,118,4);
FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,190,4);
FOR I:=119 TO 189 DO PutPixel(200,I,4);
FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,4);
Fondo:=4;
MostrarCaracter((((Actual-32)*8 DIV 8)*16) MOD 320,(Actual-32) DIV 20*8+12,Actual);
Barra;
Refresh(On);
PunteroOn;
RangoColumna(311,0);
RangoFila(191,0);
(* Bloque principal *)
Salir:=False;
MostrarAmpliado;
REPEAT
 LeerRaton(X,Y,iz,ce,de);
 (* TECLADO *)
 IF TOMATECLA(Ch,Extend,Explor,Camb) THEN
  BEGIN
   IF CH='+' THEN IF Width[Actual]<8 THEN BEGIN
                                           PunteroOff;
                                           FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,0);
                                           INC(Width[actual]);
                                           FOR I:=1 TO 8 DO BEGIN
                                                             CAR[Width[Actual],I]:=0;
                                                             SETT[Actual,Width[Actual],I]:=0;
                                                            END;
                                           FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,118,4);
                                           FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,190,4);
                                           FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,4);
                                           MostrarAmpliado;
                                           Barra;
                                           Punteroon;
                                          END;
   IF CH='-' THEN IF Width[ACtual]>1 THEN BEGIN
                                           Punterooff;
                                           FOR I:=200+(width[actual]-1)*9 TO 200+9*width[actual] DO PutPixel(I,118,0);
                                           FOR I:=200+(width[actual]-1)*9 TO 200+9*width[actual] DO PutPixel(I,190,0);
                                           FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,0);
                                           DEC(Width[Actual]);
                                           FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,118,4);
                                           FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,190,4);
                                           FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,4);
                                           Barra;
                                           MostrarAmpliado;
                                           punteroon;
                                          END;
  END;

 (* BOTON DERECHO *)

 IF DE THEN BEGIN
             IF Inn(1,15) AND (Y IN [135..149]) THEN
              BEGIN
               Beep;
               FOR J:=1 TO 8 DO
                FOR K:=1 TO width[actual]-1 DO
                 IF (Car[K,J]=1) AND (Car[K+1,J]=0) THEN Car[K+1,J]:=2;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(1,15) AND (Y IN [183..199]) THEN
              BEGIN
               Beep;
               FOR J:=1 TO 8 DO
                BEGIN
                 FOR K:=1 TO width[actual]-1 DO
                  IF (Car[K,J]=1) AND (Car[K+1,J]=0) THEN Car[K+1,J]:=3;
                 FOR K:=1 TO width[actual]-1 DO
                  IF (Car[K,J]=3) THEN Car[K,J]:=1;
               END;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(17,31) AND (Y IN [183..199]) THEN
              BEGIN
               Beep;
                 FOR J:=1 TO 3 DO
                  BEGIN
                   FOR K:=width[actual]-1 DOWNTO 1 DO Car[K+1,J]:=Car[K,J];
                   Car[1,J]:=0;
                  END;
                 FOR J:=6 TO 8 DO
                  BEGIN
                   FOR K:=2 TO width[actual] DO Car[K-1,J]:=Car[K,J];
                   Car[width[actual],J]:=0;
                  END;
               MostrarAmpliado;
               SueltaRaton;
              END;


             IF Inn(201,200+width[actual]*9-1) AND (Y IN [119..189]) THEN
              BEGIN
               IF Car[(X-201) DIV 9+1,(y-119) DIV 9+1]=0 THEN
                   Car[(X-201) DIV 9+1,(y-119) DIV 9+1]:=2 ELSE
                   Car[(X-201) DIV 9+1,(y-119) DIV 9+1]:=0;
               Beep;
               MostrarAmpliado;
               SueltaRaton;
              END;
             IF Y IN [12..94] THEN
              BEGIN
               IF (((Y-12) DIV 8*20 + X DIV 16+32) IN [32..250]) AND
                 (X MOD 16<8) THEN
                BEGIN
                 PunteroOff;
                 Car:=Sett[(Y-12) DIV 8*20 + X DIV 16+32];
                 MostrarAmpliado;
                 Beep;
                 SueltaRaton;
                 PunteroOn;
                END;
              END;

             END;

 (* BOTON IZQUIERDO *)



 IF IZ THEN BEGIN
             IF Inn(17,31) AND (Y IN [183..199]) THEN
              BEGIN
               Beep;
                 FOR J:=6 TO 8 DO
                  BEGIN
                   FOR K:=width[actual]-1 DOWNTO 1 DO Car[K+1,J]:=Car[K,J];
                   Car[1,J]:=0;
                  END;
                 FOR J:=1 TO 3 DO
                  BEGIN
                   FOR K:=2 TO width[actual] DO Car[K-1,J]:=Car[K,J];
                   Car[width[actual],J]:=0;
                  END;
               MostrarAmpliado;
               SueltaRaton;
              END;
             IF Inn(304,319) AND (Y IN [119..133]) THEN IF SEGURO THEN Salir:=True;
             IF Inn(304,319) AND (Y IN [151..165]) THEN BEGIN
                                                         BeepOff:=NOT BeepOff;
                                                         Beep2;
                                                         SueltaRaton;
                                                        END;
             IF Inn(304,319) AND (Y IN [135..149]) THEN BEGIN
                                                         Beep;
                                                         GrabarFont
                                                        END;
             IF Inn(17,31) AND (Y IN [119..133]) THEN
              BEGIN
                Beep;
                FOR I:=1 TO 8 DO
                 FOR J:=1 TO 8 DO
                  Car[I,J]:=0;
               MostrarAmpliado;
               SueltaRaton;
              END;
             IF Inn(1,15) AND (Y IN [119..133]) THEN
              BEGIN
               Sett[Actual]:=Car;
               Fondo:=4;
               MostrarCaracter((((Actual-32)*8 DIV 8)*16) MOD 320,(Actual-32) DIV 20*8+12,Actual);
               Beep;
               SueltaRaton;
              END;

             IF Inn(1,15) AND (Y IN [135..149]) THEN
              BEGIN
               Beep;
                FOR J:=1 TO 8 DO
                 FOR K:=2 TO width[actual] DO
                  IF (Car[K,J]=1) AND (Car[K-1,J]=0) THEN Car[K-1,J]:=2;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(1,15) AND (Y IN [183..199]) THEN
              BEGIN
               Beep;
                FOR J:=1 TO 8 DO
                 BEGIN
                  FOR K:=2 TO width[actual] DO
                   IF (Car[K,J]=1) AND (Car[K-1,J]=0) THEN Car[K-1,J]:=3;
                  FOR K:=2 TO width[actual] DO IF (Car[J,K]=3) THEN Car[J,K]:=1;
                 END;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(17,31) AND (Y IN [135..149]) THEN
              BEGIN
               Beep;
                FOR I:=1 TO 8 DO
                 FOR J:=1 TO 8 DO
                  Car[I,J]:=1;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(1,15) AND (Y IN [151..165]) THEN
              BEGIN
               Beep;
               FOR I:=1 TO width[actual] DO FOR J:=1 TO 7 DO Car[I,J]:=Car[I,J+1];
               FOR I:=1 TO width[actual] DO Car[I,8]:=0;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(17,31) AND (Y IN [151..165]) THEN
              BEGIN
               Beep;
               FOR I:=1 TO width[actual] DO FOR J:=8 DOWNTO 2 DO Car[I,J]:=Car[I,J-1];
               FOR I:=1 TO width[actual] DO Car[I,1]:=0;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(1,15) AND (Y IN [167..181]) THEN
              BEGIN
               Beep;
               FOR I:=1 TO width[actual]-1 DO FOR J:=1 TO 8 DO Car[I,J]:=Car[I+1,J];
               FOR I:=1 TO 8 Do Car[width[actual],I]:=0;
               MostrarAmpliado;
               SueltaRaton;
              END;

             IF Inn(17,31) AND (Y IN [167..181]) THEN
              BEGIN
               Beep;
               FOR I:=width[actual] DOWNTO 2 DO FOR J:=1 TO 8 DO Car[I,J]:=Car[I-1,J];
               FOR I:=1 TO 8 Do Car[1,I]:=0;
               MostrarAmpliado;
               SueltaRaton;
              END;


             IF Inn(201,200+width[actual]*9-1) AND (Y IN [119..189]) THEN
              BEGIN
               IF Car[(X-201) DIV 9+1,(y-119) DIV 9+1]=0 THEN
                   Car[(X-201) DIV 9+1,(y-119) DIV 9+1]:=1 ELSE
                    Car[(X-201) DIV 9+1,(y-119) DIV 9+1]:=0;
               MostrarAmpliado;
               Beep;
               SueltaRaton;
              END;

             IF Y IN [12..94] THEN
              BEGIN
               IF (((Y-12) DIV 8*20 + X DIV 16+32) IN [32..250]) AND
                 (X MOD 16<8) THEN
                BEGIN
                 PunteroOff;
                 Fondo:=0;
                 FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,118,0);
                 FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,190,0);
                 FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,0);
                 MostrarCaracter((((Actual-32)*8 DIV 8)*16) MOD 320,(Actual-32) DIV 20*8+12,Actual);
                 Actual:=(Y-12) DIV 8*20 + X DIV 16+32;
                 FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,118,4);
                 FOR I:=200 TO 200+9*width[actual] DO PutPixel(I,190,4);
                 FOR I:=119 TO 189 DO PutPixel(200+9*width[actual],I,4);
                 Car:=Sett[Actual];
                 Fondo:=4;
                 MostrarCaracter((((Actual-32)*8 DIV 8)*16) MOD 320,(Actual-32) DIV 20*8+12,Actual);
                 MostrarAmpliado;
                 Beep;
                 Barra;
                 SueltaRaton;
                 PunteroOn;
                END;
              END;

            END;
UNTIL Salir;
FinishRaton;
TextMode(LastMode);
WriteLn('SetMake 5.0 (C) 1995 NM Software.');
END.