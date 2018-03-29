USES Errors;

CONST Max=65528;
      Min=2048;

CONST ID:String[24]='SFX File - NM Soft.'+#13+#10+#$1A;

      VAR Header:ARRAy[0..$1F] OF Byte;

          F1,F2:File;


PROCEDURE AYUDA;
BEGIN
 WriteLn('SINTAXIS:  VOC2SFX Entrada[.VOC] [Salida[.SFX]]');
 WriteLn;
 WriteLn('Los datos de Sample del fichero no pueden superar los 65528 bytes.');
 WriteLn('El fichero VOC ha de ser de 8 bits, mono y sin loops ni dem s.');
 Halt
END;

PROCEDURE Error(N:Byte);
BEGIN
 CASE N OF
  1:WriteLn('Fichero no se encuentra');
  2:WriteLn('Versi¢n de fichero VOC no v lida.');
  3:WriteLn('Fichero demasiado largo.');
  4:WriteLn('Encontrado bloque no v lido.');
  5:WriteLn('Los ficheros VOC comprimidos no son v lidos.');
  6:WriteLn('Fichero demasiado corto.');
 END;
 Halt(n);
END;


 VAR N1,N2:String;
     Offset:Word;
     P:Pointer;
     Size:Longint;
     SizeW:Word;


BEGIN
 WriteLn('VOC2SFX 1.1 (C) 1996 NM Software');
 WriteLn;
 IF ParamCount=0 THEN AYUDA;
 N1:=ParamStr(1);IF Pos('.',N1)=0 THEN N1:=N1+'.VOC';
 N2:=ParamStr(2);IF Pos('.',N2)=0 THEN N2:=N2+'.SFX';
 Assign(F1,N1);
 IF ParamCount>1 THEN Assign(F2,N2)
                 ELSE Assign(F2,Copy(n1,1,Pos('.',n1))+'SFX');
 Reset(F1,1);
 IF IOresult<>0 THEN Error(1);
 BlockRead(F1,Header,SizeOf(Header));
 IF (Header[$17]<>1) OR (Header[$16]<>10) THEN Error(2);
 IF Header[$1A]<>1 THEN Error(4); (* BlockType *)
 IF Header[$1F]<>0 THEN Error(5);  (* Compression type *)
 Size:=Header[$1D]*65536 +Header[$1C]*256 +Header[$1B];
 IF Size>Max THEN Error(3);
 IF Size<Min THEN Error(6);
 SizeW:=Size-2;
 GetMem(P,Sizew);
 BlockRead(F1,P^,Sizew);
 Close(F1);
 {$I+}
 Rewrite(F2,1);
 BlockWrite(F2,ID,24);
 BlockWrite(F2,Sizew,2);
 BlockWrite(F2,Header[$1E],1); (* SR *)
 BlockWrite(F2,P^,Sizew);
 Close(F2);
 WriteLn('Ok. Conversi¢n realizada.');
END.



