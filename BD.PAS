PROGRAM BD;

{$I-}
{$R-}

USES DOS,CRT;

VAR P1,P2:String;
    Drive:Byte;
    S:Searchrec;
    KK:ARRAy[1..32] OF Byte;
    G:File;

PROCEDURE PRUEBA;
VAR F:text;
    S:Searchrec;
BEGIN
 REPEAT
  Assign(F,P1+'PRUEBA');
  Rewrite(F);
  IF IOResult<>0 THEN BEGIN
                       WriteLn('No se puede abrir fichero en unidad ',P1[1],'.');
                       Write('¨Reintentar o Cancelar? ');
                       IF Upcase(ReadKey)='C' THEN Halt(0);
                       WriteLn;
                      END;
  Close(F);
 UNTIL IOResult=0;
 Assign(F,P1+'PRUEBA');
 Erase(F);
END;


PROCEDURE Capitals(VAR S:String);
VAR I:Byte;
BEGIN
 FOR I:=1 TO Length(S) DO S[I]:=UpCase(S[I])
END;

PROCEDURE PedirDisquete;
BEGIN
WriteLn;
WriteLn('El disquete est  lleno. Por favor retirelo e introduzca otro con');
WriteLn('espacio libre. Pulse una tecla cuando lo haya hecho.');
ReadKey;
prueba;
END;


PROCEDURE DiscoLleno;
BEGIN
IF Drive<3 THEN BEGIN
                 PedirDisquete;
                 Exit
                END;
WriteLn;
WriteLn('ERROR: DISCO LLENO.');
Halt;
END;



PROCEDURE CopyAll(Path:String;Especif:String;Texto:String);
VAR S:Searchrec;
    G:File;
    F:File;
    Leidos:Word;
    Buffer:ARRAY[0..10240] OF Byte;

BEGIN
 FindFirst(Path+Especif,ARCHIVE,S);
 IF DosError=0 THEN
  BEGIN
   WriteLn('Duplicando fichero(s) de ',texto,'.');
   WHILE DosError=0 DO
    BEGIN
     Write('.');
     WHILE DiskFree(Drive)=-1 DO;
     WHILE DiskFree(Drive)<S.Size Do DiscoLleno;
     Assign(G,Path+S.Name);
     Reset(G,1);
     Assign(F,p1+path+S.Name);
     Rewrite(F,1);
     WHILE NOT EOF(G) DO
      BEGIN
       BlockRead(G,Buffer,10240,leidos);
       BlockWrite(F,Buffer,leidos);
      END;
     Close(F);
     Close(G);
     FindNext(S)
    END;
   WriteLn;
 END;
END;



PROCEDURE Sintaxis;
BEGIN
 WriteLn('Sintaxis err¢nea.');
 WriteLn;
 WriteLn('Sintaxis correcta:   BD Trayectoria [-g]');
 WriteLn;
 WriteLn('Por ejemplo:  BD C:\DUPLICADO ');
 WriteLn('              BD D:\PARSER\OTRA');
 WriteLn('              BD A:\');
 WriteLn;
 WriteLn('Donde trayectoria es la ruta hasta el directorio donde se guardar  la aventura.');
 WriteLn('No valen trayectorias indirectas como ..\AVENTURAS\AVENTURA2 o MAS\AVENTURAS.');
 WriteLn;
 WriteLn('El par metro -g indica que no se guarden los gr ficos, para una grabaci¢n r pida');
 Halt;
END;


PROCEDURE Error(N:Byte);
BEGIN
 CASE N OF
  1:WriteLn('Especificaci¢n de unidad no v lida.');
  2:Sintaxis;
 END;
Halt(N);
END;





BEGIN (*PRINCIPAL*)
WriteLn('DUPLICADOR DE BASES DE DATOS DE NMP 5.0.');
WriteLn;
IF (ParamCount<>1) AND (ParamCount<>2) THEN Sintaxis;
P1:=ParamStr(1);
IF P1[lengtH(p1)]='\' THEN DEC(byte(p1[0]));
Capitals(P1);
MKDIR(P1);
IF IOResult<>0 THEN BEGIN END;
MKDIR(P1+'\ADV');
IF IOResult<>0 THEN BEGIN END;
Drive:=byte(P1[1])-64;
P1:=P1+'\';
WriteLn('Duplicando base de datos en ',P1,'.');
PRUEBA;
CopyAll('','C.DAT','constantes');
CopyAll('','NOTAS.TXT','anotaciones');
CopyAll('','NMP.CFG','configuraci¢n de NMP');
CopyAll('','*.NMP','procesos (fuente)');
CopyAll('','*.DEF','definiciones (fuente)');
CopyAll('','*.MAC','macros');
CopyAll('','*.MCP','macros compiladas');
CopyAll('','*.CNV','conversaciones (fuente)');
CopyAll('ADV\','*.TLK','conversaciones (compiladas)');
CopyAll('ADV\','*.FNT','font de caracteres');
CopyAll('ADV\','*.dat','datos');
CopyAll('ADV\','m.*','mensajes');
IF ParamStr(2)<>'-g' THEN CopyAll('ADV\','*.ico','iconos');
IF ParamStr(2)<>'-g' THEN CopyAll('ADV\','*.PCX','gr ficos PCX');
IF ParamStr(2)<>'-g' THEN CopyAll('ADV\','*.GIF','gr ficos GIF');
IF ParamStr(2)<>'-g' THEN CopyAll('ADV\','*.TWK','gr ficos TWK');
CopyAll('ADV\','*.PAL','paleta');
CopyAll('ADV\','*.SND','sonido (SND)');
CopyAll('ADV\','*.CMF','sonido (CMF)');
CopyAll('ADV\','*.VOC','sonido (VOC)');
CopyAll('ADV\','*.SBM','sonido (SBM)');
CopyAll('ADV\','*.SFX','sonido (SBM)');
CopyAll('','*.SBP','partitura (SBP)');
WriteLn;
WriteLn('OK. Base de datos duplicada.');
WriteLn('No olvide grabar aparte todo lo relacionado con instrucci¢n EXTERN.');
END.
