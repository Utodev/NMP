

UNIT RATON13h;

{$S-,I-,R-,G+}  (* ­requiere 286 ! *)

INTERFACE

CONST DIMENSION=9;
(* Tama¤o del puntero del rat¢n: 9 x 9 *)

TYPE CursorGrafico=ARRAY[1..DIMENSION*DIMENSION] OF Byte;

VAR ContBoton : Byte;
(*  N£mero de botones del rat¢n *)
PunteroActivo:Boolean;
(* Ser  TRUE si el puntero del rat¢n est  visible     *)



PROCEDURE ResetRaton;
(* Inicializa el driver y handler de rat¢n, debe llamarse al principio del *)
(* programa.                                                               *)

PROCEDURE PunteroOn;
(* Enciende puntero *)

PROCEDURE FinishRaton;
(* Quita el handler del rat¢n, es necesario usarlo antes de salir al DOS *)

PROCEDURE PunteroOff;
(* Apaga Puntero *)

PROCEDURE LeerRaton(VAR X,Y : Word;VAR Izquierda,Centro,Derecha : Boolean);   (*  3  *)
(* Lee las coordenadas y el valor de pulsaci¢n de los botones *)
(* Devuelve directamente coordenadas del modo 13h, no hay que *)
(* dividir X por 2                                            *)

PROCEDURE PunteroAXY(X,Y : Word);
(* Coloca el puntero en la posici¢n indicada, debe hacerse con el puntero *)
(* no visible.                                                            *)

PROCEDURE RangoColumna(Sup,Inf : Word);
(* Indica el rango de columnas en que se mueve el rat¢n, se aconseja que *)
(* se use (320-DIMENSION,0) para pantalla completa y cursor por defecto. *)

PROCEDURE RangoFila(Sup,Inf : Word);
(* Idem para las filas, (200-DIMENSION,0) recomendado.                   *)

PROCEDURE CambiarPuntero(VAR cursor: CursorGrafico;X,Y:Integer);
(* Cambia el puntero de rat¢n y situa su "punto caliente" a una distancia *)
(* X e Y de su esquina superior izquierda.                                *)

PROCEDURE SETDesp(X,Y:Integer);
(* Cambia el "punto caliente" del puntero de rat¢n *)



(* Este ARRAY representa el puntero del rat¢n, en caso de modificar la   *)
(* constante DIMENSION deber  ser modificado. Si se quiere modificar     *)
(* el puntero por defecto deber  as¡ mismo de modificarse este.          *)
(* Los valores representan una tabla de DIMENSION x DIMENSION, que forma *)
(* un cuadrado. Los n£meros en cada posici¢n son los colores que forman  *)
(* el puntero.                                                           *)
CONST CursorRaton:CursorGrafico=
                        (09,09,00,00,00,00,00,00,00,
                         09,01,09,00,00,00,00,00,00,
                         09,01,01,09,00,00,00,00,00,
                         09,01,01,01,09,00,00,00,00,
                         09,01,01,01,01,09,00,00,00,
                         09,01,01,01,01,01,09,00,00,
                         09,01,01,09,09,09,09,00,00,
                         09,01,09,00,00,00,00,00,00,
                         09,09,00,00,00,00,00,00,00);



IMPLEMENTATION

VAR

Background:CursorGrafico;
(* Almacena el contenido de la pantalla bajo el rat¢n *)


LastX,Lasty:Word;
(* Almacenan las £ltimas coordenadas donde estuvo situado el rat¢n *)

DespX,DespY:Integer;
(* Indica el "punto caliente" del puntero del rat¢n, respecto a su *)
(* esquina superior izquierda.                                     *)

PROCEDURE GetInt(IntNo:Byte;VAR Vector:Pointer);
(* Esta funci¢n es similar a GetIntVec de la unidad DOS *)
BEGIN
 longint(vector):=MemL[0:IntNo*4];
END;

PROCEDURE SETDesp(X,Y:Integer);
BEGIN
 DespX:=X;
 DespY:=Y
END;

FUNCTION NumeroDeBotones : Byte; Assembler;
ASM
 XOR AX,AX
 INT 33h
 MOV AL,BL
END;

PROCEDURE InstallHandler(Handler:Pointer;Mascara:Word); Assembler;
(* Esta funci¢n servir  para instalar el handler que mover  el puntero *)
ASM
 LES DX,[Handler]
 MOV AX,12
 MOV CX,mascara
 INT 33h
END;


FUNCTION RatonInstalado:Boolean;
TYPE
  BytePtr = ^Byte;
VAR
  VectorPrueba : BytePtr;
BEGIN
  GetInt(51,Pointer(VectorPrueba));
  RatonInstalado:=NOT((VectorPrueba = NIL) OR (VectorPrueba^ = $CF))
END;

PROCEDURE GetImage13h(X,Y:Word);Assembler;
ASM
 CLD
 PUSH DS
 MOV  AX,0A000h
 MOV  DS,AX
 MOV  CX,Y
 MOV  AX,CX
 SHL  CX,8
 SHL  AX,6
 ADD  AX,CX
 ADD  AX,X
 MOV  SI,AX
 MOV  AX,SEG BackGround
 MOV  ES,AX
 MOV  DI, OFFSET BackGround
 MOV  CX,DIMENSION
 @Bucle:
  PUSH CX
  MOV  CX,DIMENSION
  REP MOVSB
  POP  CX
  SUB  SI,DIMENSION
  ADD  SI,320
 LOOP @Bucle
 POP  DS
END;

PROCEDURE PutImage13h(X,Y:Word);Assembler;
ASM
 CLD
 PUSH DS
 MOV  AX,0A000h
 MOV  ES,AX
 MOV  AX,Y
 MOV  DX,AX
 SHL AX,8
 SHL DX,6
 ADD AX,DX
 ADD  AX,X
 MOV  DI,AX
 MOV AX,SEG BackGround
 MOV DS,AX
 MOV SI, OFFSET BackGround
 MOV CX,DIMENSION
 @Bucle:
 PUSH CX
 MOV CX,DIMENSION
 REP MOVSB
 POP CX
 SUB DI,DIMENSION
 ADD DI,320
 LOOP @Bucle
 POP DS
END;

PROCEDURE Mezcla13h(X,Y:Word); Assembler;
ASM
 CLD
 PUSH DS
 MOV  AX,0A000h
 MOV  ES,AX
 MOV  AX,Y
 MOV  DX,AX
 SHL AX,8
 SHL DX,6
 ADD AX,DX
 ADD  AX,X
 MOV  DI,AX
 MOV AX,SEG Cursorraton
 MOV DS,AX
 MOV SI, OFFSET Cursorraton
 MOV CX,DIMENSION
@Bucle:
 PUSH CX
 MOV CX,DIMENSION
@Buc2:
 LODSB
 OR AL,AL
 JZ @sigue
 STOSB
 DEC DI
@sigue:
 INC DI
 LOOP @BUC2
 POP CX
 SUB DI,DIMENSION
 ADD DI,320
 LOOP @Bucle
 POP DS
END;

PROCEDURE MoveHandler; Far;
(* Este es el handler que se encarga de realizar los movimientos del puntero *)
VAR SX,SY:Word;
    PA:Boolean;
    LX,LY:Word;
BEGIN
 ASM
  PUSH DS
  SHR CX,1
  MOV SX,CX
  MOV SY,DX
  MOV AX,SEG PunteroActivo
  MOV DS,AX
  MOV SI,OFFSET PunteroActivo
  LODSB
  MOV PA,AL
  MOV SI,Offset LASTX
  LODSW
  MOV LX,AX
  MOV AX,SX
  MOV SI,Offset LASTX
  MOV DS:[SI],AX
  MOV SI,Offset LASTY
  LODSW
  MOV LY,AX
  MOV AX,SY
  MOV SI,Offset LASTY
  MOV DS:[SI],AX
  POP DS
 END;
 IF NOT PA THEN Exit;
 PutImage13h(LX,LY);
 GetImage13h(SX,SY);
 Mezcla13h(SX,SY);
END;




PROCEDURE ResetRaton;
BEGIN
 ASM
  XOR AX,AX
  INT 33h
 END;
 InstallHandler(@MOVEHANDLER,1);
END;


PROCEDURE CambiarPuntero(VAR cursor:CursorGrafico;X,Y:Integer);
BEGIN
 Move(Cursor,CursorRaton,Dimension*Dimension);
 DespX:=X;
 DespY:=Y;
END;

PROCEDURE PunteroOff;
BEGIN
 IF NOT PunteroACtivo THEN Exit;
 PunteroActivo:=False;
 PutImage13h(LastX,LastY);
END;

PROCEDURE PunteroOn;
VAR X,Y:Word;
    I,C,D:Boolean;
BEGIN
 IF PunteroActivo THEN Exit;
 LeerRaton(X,Y,I,C,D);
 DEC(X,DespX);
 DEC(Y,DespY);
 GetImage13h(X,Y);
 Mezcla13h(X,Y);
 LastX:=X;
 lastY:=Y;
 PunteroActivo:=True;
END;

PROCEDURE LeerRaton(VAR X,Y : Word; VAR Izquierda,Centro,Derecha : Boolean); Assembler;
ASM
 MOV AX,3
 INT 33h
 SHR CX,1       (* En modo 13h la X viene multiplicada por 2, la divido *)
 ADD CX,DespX   (* Le sumo el desplazamiento en X del puntero *)
 ADD DX,DespY   (* Le sumo el desplazamiento en Y del puntero *)
 LES DI,[X]
 MOV ES:[DI],CX
 LES DI,[Y]
 MOV ES:[DI],DX
 MOV AL,BL
 AND AL,1
 LES DI,[IZQUIERDA]
 STOSB
 MOV AL,BL
 AND AL,2
 SHR AL,1
 LES DI,[DERECHA]
 STOSB
 AND BL,4
 SHR BL,2
 LES DI,[CENTRO]
 MOV ES:[DI],BL
END;


PROCEDURE PunteroAXY(X,Y : Word); Assembler;
 ASM
  MOV AX,4
  MOV CX,X
  SHL CX,1
  MOV DX,Y
  INT 33h
 END;


PROCEDURE RangoColumna(Sup,Inf: Word); Assembler;
ASM
  MOV AX,7
  MOV CX,Inf;
  MOV DX,Sup;
  SHL cx,1
  SHL DX,1      (* Multiplico x 2, para que las coord. 13h  pasen a las *)
  INT 33h       (* que calcula el driver del rat¢n                      *)
END;


PROCEDURE RangoFila(Sup,Inf : Word); Assembler;
ASM
 MOV AX,8
 MOV CX,Inf
 MOV DX,Sup
 INT 33h
END;


PROCEDURE FinishRaton; Assembler;
ASM
 XOR AX,AX
 INT 33h
END;



BEGIN
 IF RatonInstalado THEN ContBoton := NumeroDeBotones
                   ELSE ContBoton :=0;
 (* Podemos chequear si hay o no rat¢n mirando el n§ de botones *)
 (* Si resulta ser 0 es que no hay rat¢n.                       *)
 PunteroActivo:=False;
 DespX:=0;
 DespY:=0;
END.


