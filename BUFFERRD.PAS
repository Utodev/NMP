

UNIT BufferRD; (* Buffer Read *)

INTERFACE

 PROCEDURE BlockRead(VAR F:FILE;VAR Dest;Count:Word);
 FUNCTION BlockRead1(VAR F:FILE):byte;
 PROCEDURE Reset(VAR F:FILE;RecSize:Word);
 PROCEDURE Seek(VAR F:FILE;Pos:Longint);
 FUNCTION EOF(VAR F:FILE):Boolean;
 PROCEDURE XMOVE(VAR FTE,DST;Count:Word);

 CONST BufferSize = 4096;


 VAR  Buffer : ARRAY[0..BufferSize-1] OF Byte;


IMPLEMENTATION


 VAR BuffPtr : Word;
     BuffTam : Word;

 PROCEDURE XMOVE(VAR FTE,DST;Count:Word); Assembler;
 ASM
  CLD
  PUSH DS
  LDS SI,[FTE]
  LES DI,[DST]
  MOV CX, Count
  REP MOVSB
  POP DS
 END;


 PROCEDURE Reset(VAR F:FILE;RecSize:Word);
 BEGIN
  System.Reset(F,RecSize);
  System.BlockRead(F,Buffer,BufferSize,Bufftam);
  BuffPtr:=0
 END;

 PROCEDURE BlockRead(VAR F:FILE;VAR Dest;Count:Word);
 BEGIN
  IF BuffPtr=BuffTam THEN BEGIN
                           System.BlockRead(F,Buffer,BufferSize,Bufftam);
                           Buffptr:=0
                          END;
  XMOVE(Buffer[BuffPtr],Dest,Count);
  INC(BuffPtr,Count);
 END;

 FUNCTION BlockRead1(VAR F:FILE):byte;
 BEGIN
  IF BuffPtr=BuffTam THEN BEGIN
                           System.BlockRead(F,Buffer,BufferSize,Bufftam);
                           Buffptr:=0
                          END;
  BlockRead1:=Buffer[BuffPtr];
  INC(BuffPtr);
 END;

 PROCEDURE Seek(VAR F:FILE;Pos:Longint);
 BEGIN
  System.Seek(F,Pos);
  System.BlockRead(F,Buffer,BufferSize,BuffTam);
  BuffPtr:=0;
 END;

 FUNCTION EOF(VAR F:FILE):Boolean;
 BEGIN
  EOF:=System.EOF(F) AND (BuffPtr=BuffTam);
 END;

END.
