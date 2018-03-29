USES DOS,crt;

{$I-}
{$M 16384,70000,70000}

VAR F1,F2,G:FILE;
    P:Pointer;
    escritos,Leidos:WorD;
    LONG:Longint;
    OFFS:Longint;
    S:Searchrec;
    L:Longint;


PROCEDURE Error;
BEGIN
 Close(f1);
 close(f2);
 close(g);
 WriteLn;
 WriteLn('Error: Disco lleno.',#7);
 Halt;
end;


PROCEDURE Copia(S:String);
BEGIN
 WriteLn(S);
 Assign(F1,'ADV\'+S);
 Assign(F2,'JUEGO\'+S);
 Reset(F1,1);
 IF Ioresult<>0 THEN Exit;
 Rewrite(F2,1);
 WHILE NOT EOF(F1) DO
  BEGIN
   BlockRead(F1,P^,64000,leidos);
   BlockWrite(F2,P^,leidos,escritos);
   If IOResult<>0 THEN Error;
   if leidos<>escritos then error;
  END;
 Close(f1);
 Close(f2);
END;

PROCEDURE COPYALL(S:String);
VAR R:Searchrec;
BEGIN
 Findfirst(S,Anyfile,r);
 WHILE DOSerror=0 DO
  BEGIN
   Copia(R.Name);
   FindNext(R)
  END;
END;

FUNCTION VALE:Boolean;
BEGIN
 Vale:=True;
 IF Pos('.EXE',S.name)<>0 THEN Vale:=False;
 IF Pos('.EXT',S.name)<>0 THEN Vale:=False;
 IF Pos('.CON',S.name)<>0 THEN Vale:=False;
 IF Pos('.COM',S.name)<>0 THEN Vale:=False;
 IF Pos('.BAT',S.name)<>0 THEN Vale:=False;
 IF Pos('.DRV',S.name)<>0 THEN Vale:=False;
 IF Pos('.CFG',S.name)<>0 THEN Vale:=False;
 IF Pos('.NMS',S.name)<>0 THEN Vale:=False;
 IF (S.Name='.') OR (S.Name='..') THEN vale:=False;
END;


BEGIN
 WriteLn('PACK 1.0 (C) 1995 NM Software');
 WriteLn;
 WriteLn('Se va a crear la aventura empaquetada en el subdirectorio juego. Pulse ESC para');
 WriteLn('cancelar o cualquier otra tecla para seguir.');
 WriteLn;
 IF Readkey=#27 THEN HALT;
 GetMem(P,64000);
 MKDIR('JUEGO');
 IF IOresult<>0 THEN;
 Assign(F1,'JUEGO\NMPDATA.D00');
 Assign(F2,'JUEGO\NMPDATA.D01');
 Rewrite(F1,1);
 Rewrite(F2,1);
 Offs:=0;
 FindFirst('ADV\*.*',ANYFILE,S);
 WHILE DOSError=0 DO
  BEGIN
   IF VALE THEN BEGIN
                 Write('Empaquetando ',S.NAme,'.');
                 BlockWrite(F1,S.Name,SizeOf(S.Name),escritos);
                 IF IOResult<>0 THEN Error;
                 IF escritos<>13 THEN Error;
                 BlockWrite(F1,Offs,4,escritos);
                 IF IOResult<>0 THEN Error;
                 if 4<>escritos then error;
                 Assign(G,'ADV\'+S.Name);
                 Reset(G,1);
                 Long:=FileSize(G);
                 BlockWrite(F1,Long,4,escritos);
                 if 4<>escritos then error;
                 IF IOResult<>0 THEN Error;
                 INC(Offs,long);
                 WHILE NOT EOF(G) DO
                  BEGIN
                   BlockRead(G,P^,64000,leidos);
                   BlockWrite(F2,P^,leidos,escritos);
                   Write('.');
                   IF IOResult<>0 THEN Error;
                   if leidos<>escritos then error;
                  END;
                 Close(G);
                 WriteLn;
                END;
    FindNext(S);
   END;
 Close(f1);
 Close(f2);
 Copia('NMP.CON');
 CopyAll('ADV\*.CFG');
 Copyall('ADV\*.DRV');
 CopyAll('ADV\*.EXE');
 CopyAll('ADV\*.COM');
 CopyAll('ADV\*.EXT');
 Writeln('OK. Juego empaquetado.');
 WriteLn('No olvide copiar aparte todo lo relacionado con EXTERN.');
END.



