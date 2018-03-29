USES CRT;

CONST ID_STRING:STRING='NMCSG291271';
VAR ID:LongInt;
    MAXSECTOR:Byte;

CONST DATA:ARRAY[1..18*4] OF BYte=(1,9,3,12,1,9,2,12,1,9,1,12,1,9,1,12,
                                   1,9,3,12,1,9,2,12,1,9,1,12,1,9,1,12,
                                   1,9,3,12,1,9,2,12,1,9,1,12,1,9,1,12,
                                   1,9,3,12,1,9,2,12,1,9,1,12,1,9,1,12,
                                   1,9,3,12,1,9,2,12);
VAR SECTOR:ARRAY[0..511] OF char;
    BIEN:Boolean;
    Error:Byte;
    I,J,K:Byte;

PROCEDURE DescarTecla; Assembler;
ASM
  MOV AH,1
  INT 16h
  JZ @NADA
  @BUC:
  MOV AH,0
  INT 16h
  MOV AH,1
  INT 16h
  JNZ @BUC
  @NADA:
END;

PROCEDURE FillWord(VAR A;Count:Word;W:Word); Assembler;
ASM
 CLD
 LES DI,[A]
 MOV CX,Count
 MOV AX,W
 REP STOSW
END;

PROCEDURE FORMAT0; Assembler;
ASM
   MOV DL,0  ; (* DISK 0, UNIDAD A *)
   MOV DH,0  ; (* CARA 0 *)
   MOV CH,0 ; (* PISTA *)
   MOV AX,0501h ; (* SERVICIO 5, FORMATEAR *)
   PUSH DS
   POP ES
   MOV BX, OFFSET DATA ; (* ES:BX direccion de datos *)
   INT 13h               ; (* LLAMA 13h *)
END;

PROCEDURE AYUDA;
BEGIN
 WriteLn;
 WriteLn('SINTAXIS:    MAKEKEY Unidad [-dd] [-5]');
 WriteLn;
 WriteLn('Ejemplo:     MAKEKEY A:');
 WriteLn;
 WriteLn('El par metro -dd indica que el disco es de doble densidad.');
 WriteLn('El par metro -5  indica que el disco de de 5¬ HD');
 WriteLn('Por defecto el disco es de 3« HD');
 Halt
END;

VAR DISK:Byte;
    SR:String;
    Code:Integer;

BEGIN
 Descartecla;
 MAXSECTOR:=18;
 IF ParamStr(2)='-dd' THEN MAXSECTOR:=9;
 IF ParamStr(2)='-5' THEN MAXSECTOR:=15;
 WriteLn('MAKEKEY 1.0');
 WriteLn;
 IF (ParamStr(1)='A:') OR (ParamStr(1)='a:') THEN DISK:=0 ELSE
  IF (ParamStr(1)='B:') OR (ParamStr(1)='b:') THEN DISK:=1 ELSE
   Ayuda;
 FillWord(SECTOR,256,$FFF7);
 Write('Teclea ID:');
 ReadLn(SR);
 VAL(SR,ID,Code);
 IF Code<>0 THEN Halt;
 WriteLn('Creando disco...');
 FOR I:=18 TO 22 DO
 BEGIN
  Write('Espere... ',23-I);GotoXY(1,WhereY);
  FOR J:=1 TO MAXSECTOR DO
   BEGIN
    IF I=20 THEN BEGIN
                  MOVE(ID_STRING[1],SECTOR,11);
                  MOVE(ID,SECTOR[11],4);
                 END;
    FOR K:=0 TO 1 DO
     ASM
       MOV DL,DISK  ;
       MOV DH,K  ; (* CARA 0 *)
       MOV CH,I ; (* PISTA *)
       MOV CL,J  ; (* SECTOR *)
       MOV AX,0301h ; (* SERVICIO 3, ESCRIBIR  UN SECTOR *)
       PUSH DS
       POP ES
       MOV BX, OFFSET SECTOR ; (* ES:BX direccion de datos *)
       INT 13h               ; (* LLAMA 13h *)
       JNC @OK
       MOV ERROR,AH
       MOV Bien,0
       JMP @FIN
       @OK:
       MOV BIEN,1
       @FIN:
      END;
      IF NOT BIEN THEN
                   BEGIN
                    WriteLn('ERROR. No pudo crearse disco.');
                    Halt;
                   END;
  END;
 END;
 FORMAT0;
 WriteLn('OK. DISCO LLAVE CREADO');
END.
