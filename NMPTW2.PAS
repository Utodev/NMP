
UNIT NMPTW2;

{$G+}
{$o+}
{$s-}
{$r-}
{$i-}



(* DATOS DE INTERES:

 -Deber¡a hacer las inicializaciones de modos usando tablas, como XLIB, pero
  lo har‚ si no tengo otra cosa que hacer, as¡ funciona y no crecer  en m s
  que unos cuantos bytes respecto a la otra forma.

 -Las variables _width y _widthbytes empiezan por '_' simplemente porque
  NMP ya ten¡a una variable llamada width (y cambi‚ widthbytes ya de paso).

 -Tambi‚n deber¡a cambiar los OUT de byte a dos direcciones seguidas por
  OUT de word, aunque la perdida de velocidad no es cr¡tica tambien ganar¡a
  unos cuantos bytes.

  *)

INTERFACE

USES DOUB386;

VAR ActStart,visStart:Word;
    _width, height, _widthBytes:Integer;

PROCEDURE TWEAK320x200;
(* Pasa al modo VGA320x200x256 unchained y borra la RAM de la VGA *)

PROCEDURE TWEAK320x240;
(* Pasa al modo VGA320x240x256 unchained y borra la RAM de la VGA *)

PROCEDURE TWEAK360x480;
(* Pasa al modo VGA360x480x256 unchained y borra la RAM de la VGA *)

PROCEDURE TWEAK320x400;
(* Pasa al modo VGA320x400x256 unchained y borra la RAM de la VGA *)

PROCEDURE TWEAK376x282;

PROCEDURE TWEAK376x308;


PROCEDURE SetActivePage(Page:Integer);
(* Selecciona la p gina a la que se dirigen las rutinas de dibujo *)

PROCEDURE SetVisiblePage(Page:Integer);
(* Selecciona la p gina que es visualizada, que no tiene por que ser la *)
(* misma que la activa.                                                 *)

PROCEDURE C4_PutImage(X,Y,An,Al:Word;F:Pointer);
PROCEDURE C4_GetImage(X,Y,An,Al:Word;F:Pointer);
PROCEDURE C4_Move(X,Y0,YF,An,Al:Word);
PROCEDURE ClearWindow(X,Y,An,Al:Word;C:Byte);

PROCEDURE PutPixel(X,Y:Word;Color:Byte);
(* Pone pixel en p gina activa *)

FUNCTION GetPixel(X,Y:Word):Byte;
(* Lee pixel en p gina activa *)

PROCEDURE SetVisOffset(B:Word);
(* Da la posici¢n exacta de la p gina activa, £til para scroll *)
PROCEDURE TWEAK640x400;

PROCEDURE SetACtOffset(N:Word);

PROCEDURE CLSTweak(C:Byte); (* Borra todas las p ginas *)

IMPLEMENTATION


VAR TIME:Longint ABSOLUTE $0040:$006C;
    TIMEB:Longint;

PROCEDURE TWEAK640x400;
(* DA POR SUPUESTO QUE SE LE LLAMA CON EL MODO DE 640x400 YA INICIALIZADO *)
BEGIN
 _Width:=640;
 Height:=400;
 _WidthBytes:=640 DIV 4;
 ActStart:=0;
 VisStart:=0;
 ASM
  MOV DX,03C4h
  MOV AL,1
  OUT DX,AL

  INC DX
  IN AL,DX
  OR AL,20h
  OUT DX,AL

  DEC DX
  MOV AX,0604h
  OUT DX,AX

  MOV DX,03D4h
  MOV AX,0E317h
  OUT DX,AX

  MOV AX,0014h
  OUT DX,AX

  MOV DX,03C4h
  MOV AX,0F02h
  OUT DX,AX
 END;
  FillD(Mem[$A000 : 0], 65535, 0);
  Timeb:=Time;
  REPEAT UNTIL Timeb+10<=Time; (* Retraso *)
 ASM
  MOV DX,03C4h
  MOV AL,1
  OUT DX,AL
  INC DX
  IN AL,DX
  AND AL,0DFh
  OUT DX,AL
 END;
END;


PROCEDURE TWEAK320x200;
BEGIN
 _width:=320;
 HEIGHT:=200;
 _widthBytes:=_width DIV 4;
 ActStart:=0;
 VisStart:=0;
ASM
 MOV AX,13h
 INT 10h
 MOV DX,03C4h
 MOV AX,0604h
 OUT DX,AX

 MOV DX,03D4h
 MOV AX,0E317h
 OUT DX,AX

 MOV AX,0014h
 OUT DX,AX

 MOV DX,03C4h
 MOV AX,0F02h
 OUT DX,AX

 MOV AX,0A000h
 MOV ES,AX
 MOV CX,08000h
 MOV AX,0
 REP STOSW
END;
END;


PROCEDURE SetActivePage(Page:Integer);
BEGIN
 ActStart:=page * _widthbytes*height;
END;

PROCEDURE SetVisiblePage(Page :Integer);
BEGIN
 VisStart:=_widthBytes*height*Page;
 ASM
  MOV BX,VisStart
  MOV DX,03D4h
  MOV AL,0Ch
  MOV AH,BH
  OUT DX,AX
  INC AL
  MOV AH,BL
  OUT DX,AX
 END;
END;

PROCEDURE PutPixel(X,Y:Word;COlor:Byte);
BEGIN
ASM
 MOV DX,03C4h
 MOV AL,02h
 OUT DX,AL
 INC DX
 MOV AL,01h
 MOV CX,X
 AND CX,03h
 SHL AL,CL
 OUT DX,AL
END;
Mem[$a000:_widthBytes*Y+X SHR 2+actStart]:=color
END;

FUNCTION GetPixel(X,Y:Word):Byte;
BEGIN
 ASM
  MOV DX,3CEh
  MOV AX,4
  OUT DX,AX
  INC DX
  MOV AX,X
  AND AX,3
  OUT DX,AX
 END;
 getPixel:=Mem[$a000:_widthbytes*y+X SHR 2+actstart];
END;



PROCEDURE TWEAK320x240;
BEGIN
 TWEAK320x200;
 ASM
  MOV DX,03C2h
  MOV AL,0E3h
  OUT DX,AL
  MOV DX,03D4h
  MOV AX,2C11h
  OUT DX,AX
  MOV AX,0D06h
  OUT DX,AX
  MOV AX,3E07h
  OUT DX,AX
  MOV AX,0EA10h
  OUT DX,AX
  MOV AX,0AC11h
  OUT DX,AX
  MOV AX,0DF12h
  OUT DX,AX
  MOV AX,0E715h
  OUT DX,AX
  MOV AX,0616h
  OUT DX,AX
  END;
Height:=240;
END;

PROCEDURE SetVisOffset(B:Word);
BEGIN
 VisStart:=B;
 ASM
  MOV BX,VisStart
  MOV DX,03D4h
  MOV AL,0Ch
  MOV AH,BH
  OUT DX,AX
  INC AL
  MOV AH,BL
  OUT DX,AX
 END;
END;

PROCEDURE SetActOffset(N:Word);
BEGIN
 ActStart:=N
END;

PROCEDURE CLSTweak(C:Byte);
BEGIN
ASM
 MOV DX,3C4h
 MOV AL,02h
 OUT DX,AL
 MOV AL,0Fh
 INC DX
 OUT DX,AL
 MOV CX,0FFFFh
 MOV AX,0A000h
 XOR DI,DI
 MOV ES,AX
 MOV AL,C
 REP STOSB
END;
END;

PROCEDURE TWEAK376x282;
BEGIN
 _Width:=376;
 Height:=282;
 _WidthBytes:=376 DIV 4;
 ACtStart:=0;
 VisStart:=0;
 ASM
  MOV AX,13h
  INT 10h
  MOV DX,03C4h
  MOV AX,0604h
  OUT DX,AX
  MOV AX,0100h
  OUT DX,AX
  MOV DX,03C2h
  MOV AL,0e7h
  OUT DX,AL

  MOV AX,0300h  (* Preparo CRTC *)
  MOV DX,3C4h
  OUT DX,AX
  MOV AL,011h
  MOV DX,03D4h
  OUT DX,AL
  INC DX
  IN AL,DX
  AND AL,07h
  OUT DX,AL

  MOV DX,03D4h
  MOV AX,06e00h
  OUT DX,AX

  MOV AX,05d01h
  OUT DX,AX

  MOV AX,05e02h
  OUT DX,AX

   MOV AX,09103h
   OUT DX,AX

   MOV AX,06204h
   OUT DX,AX

   MOV AX,08f05h
   OUT DX,AX

   MOV AX,06206h
   OUT DX,AX

   MOV AX,0f007h
   OUT DX,AX

   MOV AX,06109h
   OUT DX,AX

   MOV AX,0310fh
   OUT DX,AX

   MOV AX,03710h
   OUT DX,AX

   MOV AX,08911h
   OUT DX,AX
   MOV AX,03312h
   OUT DX,AX
   MOV AX,02f13h
   OUT DX,AX
   MOV AX,00014h
   OUT DX,AX
   MOV AX,03c15h
   OUT DX,AX
   MOV AX,05c16h
   OUT DX,AX
   MOV AX,0e317h
   OUT DX,AX
 END;
CLSTWEAK(0);
END;


{PROCEDURE TWEAK400x300;
BEGIN
 _Width:=400;
 Height:=300;
 _WidthBytes:=100;
 ACtStart:=0;
 VisStart:=0;
 ASM
  MOV AX,13h
  INT 10h
  MOV DX,03C4h
  MOV AX,0604h
  OUT DX,AX
  MOV AX,0100h
  OUT DX,AX
  MOV DX,03C2h
  MOV AL,0a7h
  OUT DX,AL

  MOV AX,0300h  (* Preparo CRTC *)
  MOV DX,3C4h
  OUT DX,AX
  MOV AL,011h
  MOV DX,03D4h
  OUT DX,AL
  INC DX
  IN AL,DX
  AND AL,07h
  OUT DX,AL

  MOV DX,03D4h

  MOV AX,07100h
  OUT DX,AX

  MOV AX,06301h
  OUT DX,AX

  MOV AX,06402h
  OUT DX,AX

   MOV AX,09203h
   OUT DX,AX

   MOV AX,06504h
   OUT DX,AX

   MOV AX,08205h
   OUT DX,AX

   MOV AX,04606h
   OUT DX,AX

   MOV AX,01f07h
   OUT DX,AX

   MOV AX,00008h
   OUT DX,AX

   MOV AX,04009h
   OUT DX,AX

   MOV AX,03110h
   OUT DX,AX

   MOV AX,08011h
   OUT DX,AX

   MOV AX,02b12h
   OUT DX,AX

   MOV AX,03213h
   OUT DX,AX

   MOV AX,00014h
   OUT DX,AX

   MOV AX,02f15h
   OUT DX,AX

   MOV AX,04416h
   OUT DX,AX

   MOV AX,0e317h
   OUT DX,AX

 END;
CLSTWEAK(0);
END;}


PROCEDURE TWEAK376x308;
BEGIN
 _Width:=376;
 Height:=308;
 _WidthBytes:=376 DIV 4;
 ACtStart:=0;
 VisStart:=0;
 ASM
  MOV AX,13h
  INT 10h
  MOV DX,03C4h
  MOV AX,0604h
  OUT DX,AX
  MOV AX,0100h
  OUT DX,AX
  MOV DX,03C2h
  MOV AL,0e7h
  OUT DX,AL

  MOV AX,0300h  (* Preparo CRTC *)
  MOV DX,3C4h
  OUT DX,AX
  MOV AL,011h
  MOV DX,03D4h
  OUT DX,AL
  INC DX
  IN AL,DX
  AND AL,07h
  OUT DX,AL

  MOV DX,03D4h
  MOV AX,06e00h
  OUT DX,AX

  MOV AX,05d01h
  OUT DX,AX

  MOV AX,05e02h
  OUT DX,AX

   MOV AX,09103h
   OUT DX,AX

   MOV AX,06204h
   OUT DX,AX

   MOV AX,08f05h
   OUT DX,AX

   MOV AX,06206h
   OUT DX,AX

   MOV AX,00f07h
   OUT DX,AX

   MOV AX,04009h
   OUT DX,AX

   MOV AX,0310fh
   OUT DX,AX

   MOV AX,03710h
   OUT DX,AX

   MOV AX,08911h
   OUT DX,AX
   MOV AX,03312h
   OUT DX,AX
   MOV AX,02f13h
   OUT DX,AX
   MOV AX,00014h
   OUT DX,AX
   MOV AX,03c15h
   OUT DX,AX
   MOV AX,05c16h
   OUT DX,AX
   MOV AX,0e317h
   OUT DX,AX
 END;
 CLSTWEAK(0);
END;



PROCEDURE TWEAK360x480;
BEGIN
 _width:=360;
 Height:=480;
 _widthBytes:=360 DIV 4;
 ActStart:=0;
 VisStart:=0;
 ASM
  MOV AX,13h;
  INT 10h
  MOV AL,04
  MOV DX,03C4h
  OUT DX,AL
  INC DX
  MOV AL,6
  OUT DX,AL
  DEC DX
  MOV AL,2
  OUT DX,AL
  INC DX
  MOV AL,0Fh
  OUT DX,AL
 END;
 FillD(Mem[$a000:0], 65535,0);
 ASM
  MOV DX,03C2h
  MOV AL,0E7h
  OUT DX,AL
  MOV DX,03D4h
  MOV AL,11h
  OUT DX,AL
  INC DX
  IN AL,DX
  MOV BL,AL
  AND BL, 07Fh
  DEC DX
  MOV AL,11h
  OUT DX,AL
  INC DX
  MOV AL,BL
  OUT DX,AL

  DEC DX
  XOR AL,AL
  OUT DX,AL
  INC DX
  MOV AL,06Bh
  OUT DX,AL

  DEC DX
  MOV AL,1
  OUT DX,AL
  INC DX
  MOV AL,59h
  OUT DX,AL

  DEC DX
  MOV AL,2
  OUT DX,AL
  INC DX
  MOV AL,5Ah
  OUT DX,AL

  DEC DX
  MOV AL,3
  OUT DX,AL
  INC DX
  MOV AL,8Eh
  OUT DX,AL

  DEC DX
  MOV AL,4
  OUT DX,AL
  INC DX
  MOV AL,5Eh
  OUT DX,AL

  DEC DX
  MOV AL,5
  OUT DX,AL
  INC DX
  MOV AL,8Ah
  OUT DX,AL

  DEC DX
  MOV AL,6
  OUT DX,AL
  INC DX
  MOV AL,0Dh
  OUT DX,AL

  DEC DX
  MOV AL,7
  OUT DX,AL
  INC DX
  MOV AL,3Eh
  OUT DX,AL

  DEC DX
  MOV AL,9
  OUT DX,AL
  INC DX
  MOV AL,40h
  OUT DX,AL

  DEC DX
  MOV AL,10h
  OUT DX,AL
  INC DX
  MOV AL,0EAh
  OUT DX,AL

  DEC DX
  MOV AL,12h
  OUT DX,AL
  INC DX
  MOV AL,0DFh
  OUT DX,AL

  DEC DX
  MOV AL,13h
  OUT DX,AL
  INC DX
  MOV AL,2Dh
  OUT DX,AL

  DEC DX
  MOV AL,14h
  OUT DX,AL
  INC DX
  XOR AL,AL
  OUT DX,AL

  DEC DX
  MOV AL,15h
  OUT DX,AL
  INC DX
  MOV AL,0E7h
  OUT DX,AL

  DEC DX
  MOV AL,16h
  OUT DX,AL
  INC DX
  MOV AL,06h
  OUT DX,AL

  DEC DX
  MOV AL,17h
  OUT DX,AL
  INC DX
  MOV AL,0E3h
  OUT DX,AL

  DEC DX
  MOV AL,11h
  OUT DX,AL
  INC DX
  MOV AL,0ACh
  OUT DX,AL
 END;
END;

PROCEDURE TWEAK320x400;
BEGIN
 _width:=320;
 Height:=400;
 _widthBytes:=320 DIV 4;
 ActStart:=0;
 VisStart:=0;
 ASM
  MOV AX,13h;
  INT 10h
  MOV AL,04
  MOV DX,03C4h
  OUT DX,AL
  INC DX
  MOV AL,6
  OUT DX,AL
  DEC DX
  MOV AL,2
  OUT DX,AL
  INC DX
  MOV AL,0Fh
  OUT DX,AL
 END;
 FillD(Mem[$a000:0], 65535,0);
 ASM
  MOV DX,03C2h
  MOV AL,0E3h
  OUT DX,AL
  MOV DX,03D4h
  MOV AL,11h
  OUT DX,AL
  INC DX
  IN AL,DX
  MOV BL,AL
  AND BL, 7Fh
  DEC DX
  MOV AL,11h
  OUT DX,AL
  INC DX
  MOV AL,BL
  OUT DX,AL

  DEC DX
  MOV AL,9
  OUT DX,AL
  INC DX
  MOV AL,40h
  OUT DX,AL

  DEC DX
  MOV AL,14h
  OUT DX,AL
  INC DX
  XOR AL,AL
  OUT DX,AL

  DEC DX
  MOV AL,17h
  OUT DX,AL
  INC DX
  MOV AL,0E3h
  OUT DX,AL
 END;
END;



PROCEDURE C4_PutImage(X,Y,An,Al:Word;F:Pointer);
VAR B:Byte;
    YY:Word;
    Q,I:Byte;

BEGIN
 Q:=0;
 B:=1 SHL (X AND 3);
 FOR I:=0 TO 3 DO
  BEGIN
   ASM
   MOV DX,03C4h  (* Calculo m scara *)
   MOV AL,02h
   OUT DX,AL
   INC DX
   MOV AL,B
   OUT DX,AL
  END;
  FOR YY:=Y TO Y+Al-1 DO
   BEGIN
    MOVED(F^,Mem[$a000:_widthBytes*YY+X SHR 2+actstart+Q],An SHR 2);
    INC(longint(F),An SHR 2)
   END;
  B:=B SHL 1; IF B>8 THEN BEGIN
                           B:=1;
                           Inc(Q);
                          END;
 END;
END;

PROCEDURE C4_GetImage(X,Y,An,Al:Word;F:Pointer);
VAR YY:Word;
    I:Byte;
    mask:word;
    Q:Byte;
BEGIN
 Q:=0;
 Mask:=X AND 3;
 FOR I:=0 TO 3 DO
  BEGIN
   ASM
    MOV DX,3CEh (* Calculo n§ de plano, atenci¢n la lectur a no se hace con mask *)
    MOV AX,4
    OUT DX,AX
    INC DX
    MOV AX,Mask
    OUT DX,AX
  END;
  FOR YY:=Y TO Y+Al-1 DO
   BEGIN
    MOVED(Mem[$a000:_widthBytes*YY+X SHR 2+actstart+q],F^,An SHR 2);
    INC(longint(F),An SHR 2)
   END;
  Inc(Mask);IF mask=4 THEN BEGIN
                            Mask:=0;
                            Inc(Q);
                           END;
 END;
END;

PROCEDURE ClearWindow(X,Y,An,Al:Word;C:Byte);
VAR B:Byte;
    YY:Word;
    Q,I:Byte;

BEGIN
 Q:=0;
 B:=1 SHL (X AND 3);
 FOR I:=0 TO 3 DO
  BEGIN
   ASM
   MOV DX,03C4h  (* Calculo m scara *)
   MOV AL,02h
   OUT DX,AL
   INC DX
   MOV AL,B
   OUT DX,AL
  END;
  FOR YY:=Y TO Y+Al-1 DO
    FillD(Mem[$a000:_widthBytes*YY+X SHR 2+actstart+Q],An SHR 2,C);
  B:=B SHL 1; IF B>8 THEN BEGIN
                           B:=1;
                           Inc(Q);
                          END;
 END;
END;

PROCEDURE C4_Move(X,Y0,YF,An,Al:Word);
VAR B:Byte;
    YY:Word;
    Q,I:Byte;
    mask:word;
BEGIN
 Q:=0;
 B:=1 SHL (X AND 3);
 Mask:=X AND 3;
 FOR I:=0 TO 3 DO
  BEGIN
   ASM
   MOV DX,03C4h  (* Calculo m scara escritura *)
   MOV AL,02h
   OUT DX,AL
   INC DX
   MOV AL,B
   OUT DX,AL
   MOV DX,3CEh (* Calculo n§ de plano, atenci¢n la lectura no se hace con mask *)
   MOV AX,4
   OUT DX,AX
   INC DX
   MOV AX,Mask
   OUT DX,AX
  END;
  FOR YY:=0 TO Al-1 DO
    MOVEd(Mem[$a000:_widthBytes*(Y0+YY)+X SHR 2+Q],Mem[$a000:_widthbytes*(YF+YY)+X SHR 2+q],AN SHR 2);
  B:=B SHL 1;
  Inc(mask);
  IF B>8 THEN BEGIN
               B:=1;
               Inc(Q);
               Mask:=0;
              END;
 END;
END;

BEGIN
(* NO HAY INICIALIZACIONES *)
END.
