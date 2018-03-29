

UNIT Errors;

INTERFACE

IMPLEMENTATION

{$F+,s-}

VAR OldExit:Pointer;

FUNCTION ErrorOf(N:Byte):String;
BEGIN
 CASE N OF
    1 :ErrorOf:='N£mero de funci¢n no v lida';
    2 :ErrorOf:='Fichero no se encuentra';
    3 :ErrorOf:='Trayectoria no se encuentra';
    4 :ErrorOf:='Demasiados ficheros abiertos';
    5 :ErrorOf:='Acceso a fichero denegado';
    6 :ErrorOf:='Handle de fichero no v lido';
   12 :ErrorOf:='C¢digo de acceso a fichero no v lido';
   15 :ErrorOf:='N£mero de unidad no v lido';
   16 :ErrorOf:='No se puede borrar el directorio activo';
   17 :ErrorOf:='No se puede renombrar hacia unidades distintas';
   18 :ErrorOf:='No hay m s ficheros';
  100 :ErrorOf:='Error de lectura de disco';
  101 :ErrorOf:='Error de escritura de disco';
  102 :ErrorOf:='Fichero no asignado';
  103 :ErrorOf:='Fichero no abierto';
  104 :ErrorOf:='Fichero no abierto para entrada';
  105 :ErrorOf:='Fichero no abierto para salida';
  106 :ErrorOf:='Formato num‚rico no v lido';
  150 :ErrorOf:='Disco protegido contra escritura';
  151 :ErrorOf:='Bad drive request struct length';
  152 :ErrorOf:='Unidad no preparada';
  154 :ErrorOf:='Error de CRC en datos';
  156 :ErrorOf:='Error de b£squeda en disco';
  157 :ErrorOf:='Tipo de superficie (media type) desconocida';
  158 :ErrorOf:='Sector no encontrado';
  159 :ErrorOf:='Impresora sin papel';
  160 :ErrorOf:='Error de escritura en dispositivo';
  161 :ErrorOf:='Error de lectura en dispositivo';
  162 :ErrorOf:='Fallo del hardware';
  200 :ErrorOf:='Divisi¢n por cero';
  201 :ErrorOf:='Error de rango';
  202 :ErrorOf:='Desbordamiento de pila';
  203 :ErrorOf:='Memoria base insuficiente';
  204 :ErrorOf:='Operaci¢n de puntero no v lida';
  205 :ErrorOf:='Desbordamiento de coma flotante (overflow)';
  206 :ErrorOf:='Desbordamiento de coma flotante (underflow)';
  207 :ErrorOf:='Operaci¢n en coma flotante no v lida';
  208 :ErrorOf:='Manejador de overlays no instalado';
  209 :ErrorOf:='Error al leer fichero de overlay';
  210 :ErrorOf:='Objeto no inicializado';
  211 :ErrorOf:='Llamada a m‚todo abstracto';
  212 :ErrorOf:='Error de registro de flujo (stream)';
  213 :ErrorOf:='Collection index out of range';
  214 :ErrorOf:='Collection overflow error';
  215 :ErrorOf:='Error de desbordamiento aritm‚tico';
  216 :ErrorOf:='Error de protecci¢n general';
 END;
END;

FUNCTION HEX(C:Word):String;
VAR S:String;
    B:Word;
BEGIN
 S:='';
 WHILE C<>0 DO
  BEGIN
   B:=C MOD 16;
   C:=C DIV 16;
   IF B<10 THEN S:=char(B+48)+S
           ELSE S:=char(B+55)+S
  END;
 S:=Copy('0000',1,4-byte(S[0]))+S;
 HEX:=S
END;


PROCEDURE GotoXY(X,Y:Byte); Assembler;
ASM
 MOV AH,2
 SUB BH,BH
 MOV DH,Y
 MOV DL,X
 INT 10h
END;


PROCEDURE NewExitProc;
VAR I:Byte;
BEGIN
 ExitProc:=OldExit;
 IF ErrorAddr<>NIL THEN
                    BEGIN
                     ASM
                      MOV AX,3
                      INT 10h
                     END;
                     FOR I:=1 TO 4 DO BEGIN
                                       GotoXY(79,I);
                                       Write(#186);
                                      END;
                     GotoXY(0,0);
                     Write(#201);
                     For I:=1 TO 78 DO Write(#205);
                     Write(#187);
                     WriteLn(#186' NM Soft Error Handler');
                     WriteLn(#186' Error en tiempo de ejecuci¢n n§',ExitCode);
                     WriteLn(#186' Descripci¢n: ',ErrorOf(ExitCode),'.');
                     WriteLn(#186' Direcci¢n de error: ',HEX(SEG(ErrorAddr^)),':',HEX(Ofs(ErrorAddr^)));
                     Write(#200);
                     For I:=1 TO 78 DO Write(#205);
                     write(#188);
                     ErrorAddr:=NIL;
                    END;
END;



BEGIN
 OldExit:=ExitProc;
 ExitProc:=@NewExitProc;
END.
