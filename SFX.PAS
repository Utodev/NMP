

UNIT SFX;

(* UNIDAD PARA SONIDO DE EFECTOS POR LA SOUND BLASTER *)


INTERFACE

PROCEDURE InstallSFX(Base,IRQ,DMA,SizeBuffer:Word;Status:Pointer);
PROCEDURE ReleaseSFX;
FUNCTION GetBlaster(VAR IRQ,DMA:Word):Boolean;
PROCEDURE PlayBack(Siz : word; SR : Byte);

VAR SBIRQ,BasePort,SBDMA:Word;
    SFXPtr:Pointer;
    SamRat:Word;


IMPLEMENTATION

USES DOS;

PROCEDURE ESPERABARRIDO; Assembler;
ASM
    MOV   DX,3DAh
@@1:
    IN    AL,DX
    AND   AL,08h
    JNZ   @@1
@@2:
    IN    AL,DX
    AND   AL,08h
    JZ    @@2
END;

VAR Quedan,Size:Word;
    TotalSize:Word;
    QuedaPtr:Pointer;
    OldVector:Pointer;
    OldPort21:Byte;
    FlagPtr:^Word;

PROCEDURE WriteDSP(value : Byte);
BEGIN
  WHILE Port[BasePort+$C] AND $80 <> 0 DO;
  Port[BasePort+$C] := Value;
END;

FUNCTION SpeakerOn: Byte;
BEGIN
  WriteDSP($D1);
END;

FUNCTION SpeakerOff: Byte;
BEGIN
  WriteDSP($D3);
END;


FUNCTION ResetDSP(Base : word) : Boolean;
BEGIN
 Port[Base+6] := 1;
 EsperaBarrido;
 Port[Base+6] := 0;
 EsperaBarrido;
 IF (Port[Base+$E] AND $80 = $80) AND
   (Port[Base+$A] = $AA) THEN
    ResetDSP := true
 ELSE
   ResetDSP := false;
END;



{$F+}

PROCEDURE GETIRQ; interrupt;
VAR A:Byte;
    Page:Byte;Offset:Word;
BEGIN
 Dec(Quedan,Size);
 INC(longint(QuedaPtr),Size);
 A:=Port[BasePort+$E];

 Dec(Quedan,Size);
 INC(longint(QuedaPtr),Size);
 IF (Quedan<>0) OR ((Quedan=0) AND (FlagPtr^ AND $0400=$0400)) THEN
  BEGIN
   IF Quedan=0 THEN BEGIN
                     QuedaPtr:=SFXPtr;
                     Quedan:=TotalSize
                    END;
   IF Quedan>16384 THEN Size:=16384
                        ELSE Size:=Quedan;
   (* Setup del DMA chip *)
   Offset := Seg(QuedaPtr^) SHL 4 + Ofs(QuedaPtr^);
   Page := (Seg(QuedaPtr^) + Ofs(QuedaPtr^) SHR 4) SHR 12;
   Port[$0A] := 5;
   Port[$0C] := 0;
   Port[$0B] := $49;
   Port[$02] := Lo(offset);
   Port[$02] := Hi(offset);
   Port[$83] := page;
   Port[$03] := Lo(size);
   Port[$03] := Hi(size);
   Port[$0A] := 1;
{  WriteDSP($40);
  WriteDSP(SamRat);
  (* Set the playback type (8-bit) *)
  WriteDSP($14);
  WriteDSP(Lo(size));
  WriteDSP(Hi(size));}
  END ELSE FlagPtr^:=FlagPtr^ AND $F7FF; (* FX no sonando *)
 Port[$20]:=$20;
END;

{$F-}

PROCEDURE PlayBack(Siz : word; SR : Byte);
var 
     page, offset : word;
BEGIN
  Quedan:=Siz;
  TotalSize:=Siz;
  QuedaPtr:=SFXPtr;
  IF Quedan>16384 THEN Size:=16384
                       ELSE Size:=Quedan;
  FlagPtr^:=FlagPtr^ OR $0800;  (* FX Sonando *)

  Offset := Seg(SFXPtr^) SHL 4 + Ofs(SFXPtr^);
  Page := (Seg(SFXPtr^) + Ofs(SFXPtr^) SHR 4) SHR 12;
  SamRat:=SR;
  Port[$0A] := 5;
  Port[$0C] := 0;
  Port[$0B] := $49;
  Port[$02] := Lo(offset);
  Port[$02] := Hi(offset);
  Port[$83] := page;
  Port[$03] := Lo(size);
  Port[$03] := Hi(size);
  Port[$0A] := 1;

  (* Set the playback frequency *)
  WriteDSP($40);
  WriteDSP(samrat);
  (* Set the playback type (8-bit) *)
  WriteDSP($14);
  WriteDSP(Lo(size));
  WriteDSP(Hi(size));
END;

FUNCTION GetBlaster(VAR IRQ,DMA:Word):Boolean;
VAR S:String;
    S2:String[10];
    Code:Integer;
BEGIN
 GetBlaster:=False;
 S:=GetEnv('BLASTER');
 IF S='' THEN Exit;
 S:=S+' ';
 S2:=Copy(S,Pos('I',S)+1,255);
 S2:=Copy(S2,1,Pos(' ',S2)-1);
 VAL(S2,IRQ,Code);
 S2:=Copy(S,Pos('D',S)+1,255);
 S2:=Copy(S2,1,Pos(' ',S2)-1);
 VAL(S2,DMA,Code);
 GetBlaster:=True;
END;


PROCEDURE InstallSFX(Base,IRQ,DMA,SizeBuffer:Word;Status:Pointer);
BEGIN
 ResetDSP((Base-$200) DIV $10);
 FlagPtr:=Status;
 GetMem(SFXPtr,SizeBuffer);
 SBIRQ:=IRQ;
 SBDMA:=DMA;
 BasePort:=Base;
 ASM
  IN AL,021h
  MOV OldPort21,AL
  MOV CX,SBIRQ
  MOV AH,0FEh
  ROL AH,CL
  AND AL,AH
  OUT 021h,AL
 END;
 GetIntVec(8+SBIRQ,OldVector);
 SetIntVec(8+SBIRQ,@GetIRQ);
 SpeakerOn;
END;

PROCEDURE ReleaseSFX;
BEGIN
 SetIntVec(8+SBIRQ,OldVector);
 ASM
  MOV AL,OldPort21
  OUT 021h,AL
 END;
 SpeakerOff;
END;

END.