PROGRAM UNBLOCK;

VAR I,F,G:File;
    Buffer:ARRAY[1..30000] OF Byte;
    A,B:Longint;
    N:String;
    leidos:word;

BEGIN
 Assign(I,'AYUDA.H00');
 Assign(F,'AYUDA.H01');
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      WriteLn('Error, no se encuentra fichero.');
                      Halt;
                     END;
 reset(I,1);
 IF IOResult<>0 THEN BEGIN
                      WriteLn('Error, no se encuentra fichero.');
                      Halt;
                     END;
 WHILE NOT EOF(I) DO
  BEGIN
   BlockRead(I,A,4);
   BlockRead(I,N,9);
   BlockRead(I,B,4);
   BlockRead(F,Buffer,B-A,leidos);
   Assign(G,N+'.HLP');
   WriteLn(N);
   Rewrite(G,1);
   BlockWrite(G,Buffer, leidos);
   Close(G);
  END;
 Close(F);Close(I);
END.


