UNIT BitSet;

{$S-R-,I-}

(* Interfaz para el manejo de mapas de bits. Cualquier zona de memoria
   puede ser utilizada como tal.
   El modo de inicializar un buffer poniendo todo a 0 es usar la siguiente
   instrucci¢n : FILLCHAR(Buffer,SizeOf(Buffer),$00), para ponerlos todos a
   1 cambiar el $00 por $FF. Si la zona de memoria se direcciona mediante
   un puntero sin tipo no es v lido SizeOf, y debe ponerse directamente el
   tama¤o en bytes del buffer
   Por ejemplo:

   TYPE ARRAY5=ARRAY[1..5] OF Word;
   VAR A:ARRAY[0..9] OF Char;
       P1:Pointer;
       P2:^Array5;
       B:ARRAY5;

   BEGIN
   GetMem(P1,3000);
   New(P2);
   FillChar(A,SizeOf(A),$00);
   FillChar(B,SizeOf(B),$00);
   FillChar(P2^,SizeOf(P2^),$00);
   FillChar(P^,3000,$FF);
   FillChar(B,SizeOf(ARRAY5),$00);
   ....
   END;

*)

INTERFACE

FUNCTION BTST(VAR Buffer; N:Word):Boolean;
(* Comprueba el valor de un bit, devolviendo true si est  a 1 *)

PROCEDURE BSET(VAR Buffer; N:Word);
(* Pone a 1 el bit especificado *)

PROCEDURE BCLR(VAR Buffer; N:Word);
(* Pone a 0 el bit especificado *)

(* Cualquier zona de memoria de un tama¤o m ximo de 8 K *)
(* puede ser utilizada como buffer para el mapa de bits *)

IMPLEMENTATION

PROCEDURE BCLR(VAR Buffer;N:Word); Assembler;
ASM
 LES DI,[Buffer]
 MOV AX,N
 XOR DX,DX   (* DX:AX=N *)
 MOV CX,8    (* N DIV 8 *)
 DIV CX
 ADD DI,AX   (* AX Contiene el Cociente *)
 MOV CX,7
 SUB CX,DX   (* DX tiene el resto *)
 MOV AL,1
 SHL AL,CL
 NOT AX
 AND ES:[DI],AL
END;

PROCEDURE BSET(VAR Buffer;N:Word); Assembler;
ASM
 LES DI,[Buffer]
 MOV AX,N
 XOR DX,DX   (* DX:AX=N *)
 MOV CX,8    (* N DIV 8 *)
 DIV CX
 ADD DI,AX   (* AX Contiene el Cociente *)
 MOV CX,7
 SUB CX,DX   (* DX tiene el resto *)
 MOV AL,1
 SHL AL,CL
 OR ES:[DI],AL
END;

FUNCTION BTST(VAR Buffer;N:Word):Boolean; Assembler;
ASM
 LES DI,[Buffer]
 MOV AX,N
 MOV CX,8
 MOV DX,0
 DIV CX
 ADD DI,AX
 MOV CX,7
 SUB CX,DX
 MOV AL,1
 SHL AL,CL
 XOR AH,AH
 AND AL,ES:[DI]
 JZ @FIN
 MOV AL,1
 @FIN:
END;

END.
