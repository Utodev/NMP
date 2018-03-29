PROGRAM BLOCK;

USES DOS;

VAR F:File;
    G,H:File;
    Buffer:ARRAY[1..20000] OF Byte;
    S:Searchrec;
    Leidos:Word;
    A:LongInt;
    St:String;

BEGIN
 Assign(G,'AYUDA.H01');
 Assign(H,'AYUDA.H00');
 Rewrite(G,1);
 Rewrite(H,1);
 FindFirst('*.HLP',ARCHIVE,S);
 WHILE DosError=0 DO
  BEGIN
   Assign(F,S.Name);
   WriteLn(S.Name);
   Reset(F,1);
   BlockRead(F,Buffer,20000,leidos);
   A:=FilePos(G);
   BlockWrite(H,A,4);
   St:=Copy(S.Name,1,Pos('.',S.Name)-1);
   BlockWrite(H,St,9);
   BlockWrite(G,Buffer,leidos);
   A:=FilePos(G);
   BlockWrite(H,A,4);
   Close(F);
   FindNext(S)
  END;
 Close(H);
 Close(G);
 WriteLn('Ok.');
END.



