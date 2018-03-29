(* -------------------------------------------------------------- *)
(*     UNIDAD DE INTERFACE CON RATON                              *)
(*     Compilador: Turbo Pascal 6.0 (o superior)                  *)
(*     Autor: Carlos S nchez                                      *)
(*     Ultima revisi¢n 19 / 05 / 94                               *)
(*                                                                *)
(* -------------------------------------------------------------- *)

UNIT RatonAsm;

{$S-}
{$I-}
{$R-}
{$G+}

INTERFACE

VAR
  ContBoton : Byte;          (*  N£mero de botones del rat¢n *)

TYPE CursorGrafico=RECORD
                    ScreenMask,Cursor:ARRAY[0..15] OF Word
                   END;

(* El tipo CursorGrafico sirve para cambiar el cursor en modo gr fico *)
(* Representa un patr¢n de bits de 16x16                              *)
(* Primero se hace un AND con la m scara y luego un XOR con el cursor *)

FUNCTION EsLogitech : Boolean;          (*  Examina el controlador *)

PROCEDURE CambiarPuntero(VAR cursor: CursorGrafico;
                                     X,Y : Integer);
(* Usar con Puntero activo*)

PROCEDURE ResetRaton;                        (*  Llamada a funci¢n 0  *)

PROCEDURE PunteroOn;                                           (*  1  *)

PROCEDURE PunteroOff;                                          (*  2  *)

PROCEDURE LeerRaton(VAR X,Y : Word;
                    VAR Izquierda,Centro,Derecha : Boolean);   (*  3  *)

PROCEDURE PunteroAXY(X,Y : Word);                              (*  4  *)
(* Usar con Puntero activo*)

PROCEDURE RangoColumna(Sup,Inf : Word);                        (*  7  *)
(* Usar con Puntero activo*)

PROCEDURE RangoFila(Sup,Inf : Word);                           (*  8  *)
(* Usar con Puntero activo*)

PROCEDURE InstallHandler(VAR Handler;Mascara:Word);
(* Instala un procedimiento que se llamar  cuando ocurra uno de los
   eventos marcados por la m scara. El procedimiento ha de ser far *)
(* Significado de la m scara :

  N§ Bit                Condici¢n
==================================================
   0                    cambi¢ posici¢n de cursor
   1                    se puls¢ izquierdo
   2                    se solt¢ izquierdo
   3                    se puls¢ derecho
   4                    se solt¢ derecho
   5                    se puls¢ centro
   6                    se solt¢ centro
   7 - 15               no usados
*)

IMPLEMENTATION

PROCEDURE GetInt(IntNo:Byte;VAR Vector:Pointer); Assembler;
ASM
 MOV AL,[IntNo]
 MOV AH,35h
 INT 21h
 PUSH DS
 PUSH ES
 POP DS
 LES DI,[Vector]
 MOV ES:[DI],BX
 INC DI
 INC DI
 MOV ES:[DI],DS
 POP DS
END;

FUNCTION NumeroDeBotones : Byte;
VAR A:Byte;
BEGIN
 ASM
  XOR AX,AX
  INT 33h
  MOV A,BL
 END;
 NumeroDeBotones := A
END;

PROCEDURE InstallHandler(VAR Handler;Mascara:Word); Assembler;
ASM
 LES DX,[Handler]
 MOV AX,12
 MOV CX,mascara
 INT 33h
END;


FUNCTION RatonInstalado : Boolean;
TYPE
  BytePtr = ^Byte;
VAR
  VectorPrueba : BytePtr;
BEGIN
  GetInt(51,POINTER(VectorPrueba));
  (*  $CF es el c¢digo binario de la instrucci¢n IRET;  *)
  (*  en muchos BIOS, el c¢digo de arranque del sistema  *)
  (*  llena con IRETs los vectores no utilizados  *)
  IF (VectorPrueba = NIL) OR (VectorPrueba^ = $CF) THEN
    RatonInstalado := False
  ELSE
    RatonInstalado := True
END;


(* -------------------------------------------------------------- *)
(*     LOS PROCEDIMIENTOS POR ENCIMA DE ESTE PUNTO SON PRIVADOS   *)
(* -------------------------------------------------------------- *)



FUNCTION EsLogitech : Boolean;

TYPE
  Signature = ARRAY[0..13] OF Char;
  SigPtr = ^Signature;

CONST LogitechSig : Signature = 'LOGITECH MOUSE';

VAR
  VectorPrueba : SigPtr;
  L          : LongInt;

BEGIN
  GetInt(51,Pointer(VectorPrueba));
  LongInt(VectorPrueba) := LongInt(VectorPrueba) + 16;
  IF VectorPrueba^ = LogitechSig THEN
    EsLogitech := True
  ELSE
    EsLogitech := False
END;



PROCEDURE ResetRaton; Assembler;
ASM
 XOR AX,AX
 INT 33h
END;

PROCEDURE CambiarPuntero(VAR cursor: CursorGrafico;X,Y:Integer); Assembler;
 ASM
  LES DX, [Cursor]
  MOV CX , Y
  MOV BX,  X
  MOV AX , 9
  INT 33H
 END;

PROCEDURE PunteroOff; Assembler;
ASM
 MOV AX,2
 INT 33h
END;

PROCEDURE PunteroOn;  Assembler;
ASM
 MOV AX,1
 INT 33h
END;


PROCEDURE LeerRaton(VAR X,Y : Word; VAR Izquierda,Centro,Derecha : Boolean); Assembler;
ASM
 MOV AX,3
 INT 33h
 LES DI,[X]
 MOV ES:[DI],CX
 LES DI,[Y]
 MOV ES:[DI],DX
 MOV BH,BL
 AND BH,1
 LES DI,[IZQUIERDA]
 MOV ES:[DI],BH
 MOV BH,BL
 AND BH,2
 SHR BH,1
 LES DI,[DERECHA]
 MOV ES:[DI],BH
 AND BL,4
 SHR BL,2
 LES DI,[CENTRO]
 MOV ES:[DI],BL
END;


PROCEDURE PunteroAXY(X,Y : Word); Assembler;
ASM
  MOV AX,4
  MOV CX,X
  MOV DX,Y
  INT 33h
END;


PROCEDURE RangoColumna(Sup,Inf : Word); Assembler;
ASM
  MOV AX,7
  MOV CX,Inf;
  MOV DX,Sup;
  INT 33h
END;


PROCEDURE RangoFila(Sup,Inf : Word); Assembler;
ASM
 MOV AX,8
 MOV CX,Inf
 MOV DX,Sup
 INT 33h
END;

BEGIN
 IF RatonInstalado THEN ContBoton := NumeroDeBotones
                   ELSE ContBoton :=0;
END.  (* Raton *)
