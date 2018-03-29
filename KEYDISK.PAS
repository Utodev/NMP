UNIT KEYDISK;

{$B-}
{$X+}
{$I-}
{$S-}


INTERFACE

FUNCTION FindDisk(Valor:LongInt):Boolean;


IMPLEMENTATION

CONST ID_STRING:STRING='NMCSG291271';
VAR ID:LongInt;

VAR SECTOR2,SECTOR:ARRAY[0..511] OF char;

PROCEDURE FillWord(VAR A;Count:Word;W:Word); Assembler;
ASM
 CLD
 LES DI,[A]
 MOV CX,Count
 MOV AX,W
 REP STOSW
END;

FUNCTION CMPWord(VAR A,B;Size:Word):Boolean; Assembler;
ASM
 PUSH DS
 CLD
 MOV AX,1
 LDS SI,A
 LES DI,B
 MOV CX,Size
 @BUC:
 CMPSW
 JNE @MAL
 LOOP @BUC
 JMP @FIN
 @MAL:
 XOR AX,AX
 @FIN:
 POP DS
END;

FUNCTION ReadSector(Disco,Pista:Byte):Boolean; Assembler;
ASM
 MOV DL,0       (* DISK 0, UNIDAD A *)
 MOV DH,0       (* CARA 0 *)
 MOV CH,Pista   (* PISTA *)
 ADD CH,20
 MOV CL,1       (* SECTOR *)
 MOV AX,0201h   (* SERVICIO 2, LEER  UN SECTOR *)
 PUSH DS
 POP ES
 MOV BX, OFFSET SECTOR2  (* ES:BX direccion de datos *)
 INT 13h                 (* LLAMA 13h *)
 JNC @OK
 MOV AX, 0
 JMP @FIN
 @OK:
 MOV AX,1
 @FIN:
END;



FUNCTION FindDisk(Valor:LongInt):Boolean;
VAR AUX:Boolean;
BEGIN
 MOVE(Valor,SECTOR[11],4);
 Aux:=ReadSector(0,0) OR ReadSector(0,1) OR ReadSector(0,2) OR
      ReadSector(1,0) OR ReadSector(1,1) OR ReadSector(1,2);
 IF AUX THEN AUX:=CMPWORD(SECTOR,SECTOR2,256);
 FindDisk:=Aux;
END;

BEGIN
 FillWord(SECTOR,256,$FFF7);
 MOVE(ID_STRING[1],SECTOR,11);
END.
