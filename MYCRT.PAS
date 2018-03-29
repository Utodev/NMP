UNIT MyCRT;

{$I-,R-,S-,G+,X+}

INTERFACE

PROCEDURE Sound(Frec:Word);
PROCEDURE NoSound;
PROCEDURE DElay(MS:Word);
PROCEDURE ClrScr;
FUNCTION Keypressed:Boolean;
FUNCTION ReadKey:Char;
PROCEDURE GotoXY(X,Y:Byte);
FUNCTION WhereY : Byte;
FUNCTION WhereX : Byte;

IMPLEMENTATION


PROCEDURE ClrScr; Assembler;
ASM
 MOV AX,3
 INT 10h
END;



FUNCTION ReadKey:Char; Assembler;
ASM
 SUB AH,AH
 INT 16h
END;

PROCEDURE DElay(MS:Word); Assembler;
ASM
 MOV BX,SP
 MOV DX,SS:[BX+6]
 OR DX,DX
 JE @fin
 MOV AX,0040h
 MOV ES,AX
 XOR DI,DI
 MOV AL,ES:[DI]
 MOV BX,[0052h]
 @OTRA:
 MOV CX,BX
 @BUC:
 CMP AL,ES:[DI]
 JNE  @YA
 LOOP @BUC
 @YA:
 DEC DX
 JNE @OTRA
 @fin:
END;


PROCEDURE Sound(Frec:Word); Assembler;
ASM
 mov bx,sp
 mov bx,ss:[bx+6]
 mov ax,34ddh
 mov dx,0012h
 cmp dx,bx
 jnb @l1
 div bx
 mov bx,ax
 in al,61h
 test al,3
 jne @l2
 or al,3
 out 61h,al
 mov al,0b6h
 out 43h,al
 @l2:
 mov al,bl
 out 42h,al
 mov al,bh
 out 42h,al
 @l1:
END;

PROCEDURE NoSound; Assembler;
ASM
 in al,61h
 and al,0fch
 out 61h,al
END;

FUNCTION Keypressed:Boolean; Assembler;
ASM
 MOV AH,1
 INT 16h
 mov al,0 (* no hago un SUB porque me cargo el carry *)
 JnC @fin
 mov al,1
 @fin:
END;

PROCEDURE GotoXY(X,Y:Byte); Assembler;
ASM
 MOV DH,Y
 MOV DL,X
 DEC DL
 DEC DH
 SUB BH,BH
 MOV AH,2
 INT 10h
END;

FUNCTION WhereY : Byte; Assembler;
ASM
 MOV AH,3
 SUB BH,BH
 INT 10h
 MOV AL,DH
 INC AL
END;
FUNCTION WhereX : Byte; Assembler;
ASM
 MOV AH,3
 SUB BH,BH
 INT 10h
 MOV AL,DL
 INC AL
END;


BEGIN
END.

