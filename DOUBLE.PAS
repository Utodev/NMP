UNIT DOUBLE;

{$G+} (* 286 permitidas *)
{$F+} (* Far *)
{$I-} (* No i/o check *)
{$S-} (* No stack check *)
{$R-} (* No range check *)



(* NOTA: EL uso de esta unidad es v lido para 286 y 386+, sin embargo
         aunque acelera respecto a sus equivalentes 8086 pierde tiempo
         cada vez que son llamadas comprobando si se est  en modo 286 o
         386+ y luego apilando valores para llamar a la funci¢n que
         corresponde. En una futura versi¢n de NMP que s¢lo soporte 386+
         no ocurrir  esto. *)
INTERFACE

PROCEDURE MOVED(VAR F,D;Size:Word);
(* COMO PROCEDURE MOVE, PERO SIN CONTROL DE SOLAPAMIENTO *)

PROCEDURE FILLD(VAR F;Count:Word;B:Byte);
(* COMO PROCEDURE FILLCHAR *)

PROCEDURE SET286;
(* Hace que se usen s¢lo instrucciones 286 *)

PROCEDURE SET386;
(* Hace que se usen instrucciones 386 *)

IMPLEMENTATION

VAR MODO286:Boolean;
(* True si usamos 286, false si 386 *)

PROCEDURE Fill4(VAR F;Count:Word;B:Byte); (* Para 386 *)
BEGIN
 ASM
  LES DI,[F]
  CLD
  MOV CX,Count
  MOV DX,CX
  SHR CX,2
  MOV AL,B
  MOV AH,AL
  DB 066h     (* TP no permite instrucciones 386, 66 es el prefijo para ellas *)
  SHL AX,16   (* As¡ el SHL AX,16 es en realidad SHL EAX,16 *)
  MOV AL,B
  MOV AH,AL
  REP
  DB 066h
  STOSW       (* STOSD *)
  AND DX,3
  JZ @FIN
  MOV CX,DX
  REP STOSB
  @FIN:
 END;
END;

PROCEDURE MOVE4(VAR F,D;Size:Word);  (* Para 386 *)
BEGIN
 ASM
  PUSH DS
  LDS SI,[F]
  LES DI,[D]
  CLD
  MOV CX,Size
  MOV DX,CX
  SHR CX,2
  REP
  DB 066h
  MOVSW
  AND DX,3
  JZ @FIN
  MOV CX,DX
  REP MOVSB
  @FIN:
  POP DS
 END;
END;



PROCEDURE MOVE2(VAR FTE,DST;Size:Word); Assembler; (* Para 286 *)
ASM
 CLD
 PUSH DS
 LDS SI,[FTE]
 LES DI,[DST]
 MOV CX,SIZE
 MOV DX,CX
 SHR CX,1
 REP MOVSW
 AND DX,1
 JZ @FIN
 MOVSB
 @FIN:
 POP DS
END;

PROCEDURE Fill2(VAR A;Count:Word;Val:Byte); Assembler;  (* Para 286 *)
ASM
 LES DI,[A]
 CLD
 MOV CX,Count
 MOV DX,CX
 SHR CX,1
 MOV AL,Val
 MOV AH,AL
 REP STOSW
 AND DX,1
 JZ @FIN
 STOSB
 @FIN:
END;


PROCEDURE FILLD(VAR F;Count:Word;B:Byte);
BEGIN
 IF Modo286 THEN FILL2(F,Count,b)
            ELSE Fill4(F,Count,b)
END;

PROCEDURE MOVED(VAR F,D;Size:Word);
BEGIN
 IF Modo286 THEN MOVE2(F,D,Size)
            ELSE MOVE4(F,D,Size);
END;

PROCEDURE SET286;
BEGIN
 MODO286:=True;
END;

PROCEDURE SET386;
BEGIN
 Modo286:=False;
END;

BEGIN
 Modo286:=False; (* por defecto modo 386 *)
END.


