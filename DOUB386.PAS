UNIT DOUB386;

{$G+} (* 286 permitidas *)
{$F+} (* Far *)
{$I-} (* No i/o check *)
{$S-} (* No stack check *)
{$R-} (* No range check *)


INTERFACE

PROCEDURE MOVED(VAR F,D;Size:Word);
(* COMO PROCEDURE MOVE, PERO SIN CONTROL DE SOLAPAMIENTO *)

PROCEDURE FILLD(VAR F;Count:Word;B:Byte);
(* COMO PROCEDURE FILLCHAR *)

PROCEDURE MOVEDTransParent(VAR F,D;Size:Word);

IMPLEMENTATION

PROCEDURE FillD(VAR F;Count:Word;B:Byte); (* Para 386 *)
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

PROCEDURE MOVED(VAR F,D;Size:Word);  (* Para 386 *)
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


PROCEDURE MOVEDTransParent(VAR F,D;Size:Word); Assembler;
ASM
 PUSH DS
 LDS SI,[F]
 LES DI,[D]
 CLD
 MOV CX, Size
 SHR CX, 2
@PUNTO_4:
  { LODSD }             DB 66h ; LODSW
  OR AL, AL
  JZ @PUNTO_4_A
  MOV [ES:DI], AL
@PUNTO_4_A:
  OR AH, AH
  JZ @PUNTO_4_B
  MOV [ES:DI+1], AH
@PUNTO_4_B:
{ SHR EAX, 16 }       DB 66h, 0C1h, 0E8h, 10h
  OR AL, AL
  JZ @PUNTO_4_C
  MOV [ES:DI+2], AL
@PUNTO_4_C:
  OR AH, AH
  JZ @PUNTO_4_D
  MOV [ES:DI+3], AH
@PUNTO_4_D:
  ADD DI, 4
  DEC CX
  JNZ @PUNTO_4
 POP DS
END;


END.


