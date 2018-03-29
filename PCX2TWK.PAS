
USES BufferRd;


VAR F,G:FILE;
    S:String;
    PCXHead:ARRAY[0..127] OF Byte;
    PCXAn,PCXAl:Word;
    Buffer,Buffer2:ARRAY[0..639] OF Byte;
    Paleta:ARRAY[0..767] OF Byte;
    Escritos:Word;
    Y:WorD;

CONST UNO:Byte=1;

PROCEDURE GOTWEAK(VAR FTE,DST;Size:Word); Assembler;
ASM
 PUSH DS
 LES DI,[DST]
 MOV AX,Size
 SHR AX,1
 SHR AX,1         (* AX=Size DIV 4 *)
 XOR DX,DX      (* DX=Desplazamiento*)
 MOV CX,4
 @BUC1:
 LDS SI,[FTE]
 ADD SI,DX
 PUSH CX
 MOV CX,AX
 @BUC2:
 MOVSB
 ADD SI,3
 LOOP @BUC2
 INC DX
 POP CX
 LOOP @BUC1
 POP DS
END;


PROCEDURE Error(N:Byte);
BEGIN
 IF N<>0 THEN Write('Error: ');
 CASE N OF
  1:WriteLn('Fichero no se encuentra.');
  2:WriteLn('El ancho del gr fico ha de ser m£ltiplo de 4');
  3:WriteLn('Gr fico demasiado grande.');
  4:WriteLn('Disco protegido o lleno.');
 END;
 Halt(n)
END;

PROCEDURE GetLine;
VAR LinePtr:Word;
    A,B:Byte;

BEGIN
 LinePtr:=0;
 REPEAT
  BlockRead(F,A,1);
  IF A>=192 THEN BEGIN
                  B:=A-192;
                  BlockRead(F,A,1);
                 END ELSE B:=1;
  FillChar(Buffer[LinePtr],B,A);
  INC(LinePtr,B);
 UNTIL LinePtr=PCXan;
END;

PROCEDURE HElp;
BEGIN
 WriteLn('SINTAXIS: PCX2TWK <Fichero>[.PCX]');
 WriteLn;
 Halt;
END;


BEGIN
 WriteLn('PCX2TWK (C) 1995 NM Software');
 WriteLn;
 IF ParamCOunt<>1 THEN Help;
 S:=ParamStr(1);
 IF Pos('.',s)=0 THEN S:=S+'.PCX';
 Assign(F,S);
 Assign(G,Copy(S,1,Pos('.',S))+'TWK');
 Reset(F,1);
 IF IOResult<>0 THEN Error(1);
 BlockRead(F,PCXHead,128);
 PCXAn:=PcxHead[8] + 256*PcxHead[9] - PcxHead[4] + 256*PcxHead[5]+1;
 PCXal:=PcxHead[10] + 256*PcxHead[11] - PcxHead[6] + 256*PcxHead[7]+1;
 IF PCXAn MOD 4<>0 THEN Error(2);
 IF (PCXAn>640) OR (PCXAl>400) THEN Error(3);
 Rewrite(G,1);
 IF IOResult<>0 THEN Error(4);
 BlockWrite(G,uno,1);
 BlockWrite(G,PCXAn,2);
 BlockWrite(G,PCXAl,2);
 Seek(F,FileSize(F)-768);
 BlockRead(F,Paleta,768);
 FOR y:=0 TO 767 DO Paleta[y]:=Paleta[y] SHR 2;
 BlockWrite(G,Paleta,768,escritos);
 IF Escritos<>768 THEN Error(4);

 Write('Convirtiendo...');
 Seek(F,128);
 FOR Y:=1 TO PCXal DO
  BEGIN
   GetLine;
   Gotweak(Buffer,Buffer2,PcxAn);
   BlockWrite(G,Buffer2,PcxAn,escritos);
   IF Escritos<>PCXAn THEN Error(4);
  END;
 Close(F);
 Close(G);
 WriteLn('OK.');
END.
