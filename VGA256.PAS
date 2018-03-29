

   (*********************************************************************)
   (*                            VGA256.PAS                             *)
   (*********************************************************************)
   (*                                                                   *)
   (*  Nombre:                                   Unidad VGA256          *)
   (*  Versi¢n:                                  1.0                    *)
   (*  Unidades utilizadas:                      Ninguna                *)
   (*  Autor:                                    Carlos S nchez Garc¡a  *)
   (*  Compilador:                               Turbo Pascal 6.0       *)
   (*  Fichero fuente:                           VGA256.PAS             *)
   (*  Fichero objeto:                           VGA256.TPU             *)
   (*  Fecha:                                    Marzo de 1994          *)
   (*  Sistema Operativo:                        DOS                    *)
   (*  Requerimientos:                           Ordenador con tarjeta  *)
   (*                                            VGA o compatible       *)
   (*  Descripci¢n:                              Permite el uso de la   *)
   (*                                            VGA en el modo de 256  *)
   (*                                            colores e incluye      *)
   (*                                            nuevos procedimientos  *)
   (*                                            a¤adidos a la unidad   *)
   (*                                            GRAPH                  *)
   (*********************************************************************)


UNIT VGA256;

{$I-}    (* No control de errores en E/S *)
{$B+}    (* Expresiones l¢gicas cortocircuitadas *)
{$R-}    (* No control de errores de rango *)
{$X+}    (* Sintaxis extendida en funciones *)
{$O+}    (* La unidad puede funcionar como Overlay *)
{$S-}    (* No control de Stack Overflow *)
{$F+}    (* Procedimientos lejanos (FAR), por defecto en una unidad *)
{$G+}    (* Requiere 286 *)

INTERFACE

(* TIPOS Y CONSTANTES EXPORTADAS *)

TYPE AllPaletteType = ARRAY [0..767] OF Byte;

CONST On=True;
      Off=False;   (* Para el parametro de Refresh *)


(* PROCEDIMIENTOS EXPORTADOS *)

PROCEDURE InitVGA256;
(* Inicializa el modo VGA 320x200, 256 colores *)

PROCEDURE GetAllPalette(VAR P:AllPaletteType);
(* Guarda en la variable P, de tipo Paleta, el contenido de la paleta *)
(* actual completa *)

PROCEDURE SetAllPalette(VAR P:AllPaletteType);
(* Produce un cambio global de la paleta de los 256 colores *)

PROCEDURE SetPalette(VAR P:AllPaletteType;I1,I2:Word);

PROCEDURE GetGreyPalette(VAR P:AllPaletteType);
 (* Convierte la paleta actual a 256 tonos de gris y la guarda en  *)
 (* la variable P de tipo paleta *)

PROCEDURE GreyPalette;
 (* Convierte la paleta actual a 256 tonos de gris *)

PROCEDURE SetRGBPalette(C,R,G,B:Byte);
 (* Modifica los valores de intensidades roja, azul y verde del color *)
 (* especificado. Los valores han de estar en el rango 0-63.          *)

PROCEDURE GetRGBPalette(C:Byte;VAR R,G,B:Byte);
 (* Lee los valores de intensidades roja, azul y verde del color *)
 (* especificado.                                                *)

PROCEDURE Refresh(Activo:Boolean);
(* Activa o desactiva el refresco de la RAM de v¡deo *)

PROCEDURE PutPixel(X,Y:Word;C:Byte);
(* Pone un punto (activa un pixel) en al posici¢n (X,Y) del color C *)

FUNCTION GetPixel(X,Y:Word):Byte;
(* Devuelve el color del pixel situado en la posici¢n (X,Y)  *)

Procedure line(a,b,c,d,col:integer);
(* Linea desde A,B a C,D del color col *)

PROCEDURE ClearDevice;
(* Borra la pantalla *)





IMPLEMENTATION

(* Variables no exportadas *)


(* IMPLEMENTACION DE PROCEDIMIENTOS EXPORTADOS *)

PROCEDURE InitVGA256; Assembler;
ASM
 MOV AX, 13h
 INT 10h
END;

PROCEDURE GetAllPalette(VAR P:AllPaletteType); Assembler;
ASM
 XOR BX, BX    (*Semejante a MOV BX,0 pero m s r pido y ocupa 1 byte menos.*)
 MOV CX, 100h
 MOV AX, 1017h
 LES DX, [P]
 INT 10h
END;

PROCEDURE SetPalette(VAR P:AllPaletteType;I1,I2:Word); Assembler;
ASM
 LES DX, [BP+6]
 ADD DX, I1
 ADD DX, I1
 ADD DX, I1
 MOV BX, I1
 MOV CX, I2
 SUB CX, I1
 INC CX
 MOV AX, 1012h
 INT 10h
END;

PROCEDURE SetAllPalette(VAR P:AllPaletteType); Assembler;
ASM
 LES DX, [P]
 XOR BX, BX
 MOV CX, 256
 MOV AX, 1012h
 INT 10h
END;

Procedure Putpixel (X,Y : Word; C : Byte); Assembler;
ASM
 MOV AX,0A000h
 MOV ES,AX
 MOV DX,Y
 MOV BX,DX
 SHL DX,8
 SHL BX,6
 ADD DX,BX
 ADD DX,X
 MOV DI,DX
 MOV Al,C
 STOSB
END;


FUNCTION GetPixel(X,Y:Word):Byte;
BEGIN
 GetPixel:=Mem[$A000:320*Y+X]
END;

PROCEDURE GetGreyPalette(VAR P:AllPaletteType); Assembler;
ASM
 MOV AX, 101Bh
 XOR BX, BX
 MOV CX, 100h
 INT 10h
 MOV AX, 1017h
 XOR BX, BX
 MOV CX, 100h
 LES DX, [BP+6]
 INT 10h
END;

PROCEDURE GreyPalette; Assembler;
ASM
 MOV AX, 101Bh
 XOR BX, BX
 MOV CX,100h
 INT 10h
END;

PROCEDURE SetRGBPalette(C,R,G,B:Byte); Assembler;
ASM
 MOV BL, C
 XOR BH, BH
 MOV AX, 1010h
 MOV DH, R
 MOV CH, G
 MOV CL, B
 INT 10h
END;

PROCEDURE GetRGBPalette(C:Byte;VAR R,G,B:Byte); Assembler;
ASM
 MOV BL, C
 XOR BH, BH
 MOV AX, 1015h
 INT 10h
 LES DI, [BP+14]
 MOV ES:[DI], DH
 LES DI, [BP+10]
 MOV ES:[DI], CH
 LES DI, [BP+6]
 MOV ES:[DI], CL
END;

PROCEDURE ClearDevice;
BEGIN
 FillChar(Mem[$A000:0000],64000,0)
END;

PROCEDURE Refresh(Activo:Boolean); Assembler;
ASM
MOV AL,[BP+6]
XOR AL,1
MOV AH,12h
MOV BX,0036h
INT 10h
END;


Procedure line(a,b,c,d,col:integer);
   Function sgn(a:real):integer;
   BEGIN
        if a>0 then sgn:=+1 else
        if a<0 then sgn:=-1 else sgn:=0;
   END;

var u,s,v,d1x,d1y,d2x,d2y,m,n:real;
    i:integer;

BEGIN
     u:= c - a;
     v:= d - b;
     d1x:= SGN(u);
     d1y:= SGN(v);
     d2x:= SGN(u);
     d2y:= 0;
     m:= ABS(u);
     n := ABS(v);
     IF NOT (M>N) then
     BEGIN
          d2x := 0 ;
          d2y := SGN(v);
          m := ABS(v);
          n := ABS(u);
     END;
     s := INT(m / 2);
     FOR i := 0 TO round(m) DO
     BEGIN
          mem[$a000:a+320*b]:=col;
          s := s + n;
          IF not (s<m) THEN
          BEGIN
               s := s - m;
               a:= a +round(d1x);
               b := b + round(d1y);
          END
          ELSE
          BEGIN
               a := a + round(d2x);
               b := b + round(d2y);
          END;
     END;
END;

END.  (*UNIT VGA256*)
