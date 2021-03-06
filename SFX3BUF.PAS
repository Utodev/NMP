

UNIT SFX2buf;

{$s-,r-,i-,o+}

(* UNIDAD PARA SONIDO DE EFECTOS POR LA SOUND BLASTER *)


INTERFACE

CONST MaxBlock=4096;
      WaitingSFX:Boolean=False;
      BufferSize=1024;


PROCEDURE InstallSFX(Base,IRQ,DMA:Word;Stat:Pointer);
PROCEDURE ReleaseSFX;
FUNCTION GetBlaster(VAR IRQ,DMA:Word):Boolean;
PROCEDURE PlayBack(Siz : word; Rate : Byte);
PROCEDURE DMAPause;
PROCEDURE DMAStop;
Function DSPVersion:WorD;
PROCEDURE ADJUSTSFX(VAR A;VOL:Byte);
FUNCTION ResetDSP: Boolean;
FUNCTION SBDetect:String;


VAR SB_IRQ,SB_Port,SB_DMA:Word;
    SFXPtr:Pointer;
    SizeSFX:Word;
    SR:Byte;
    STATUS:^word;
    Buffer:ARRAY[0..1] OF ARRAY[0..BufferSize-1] OF Byte;
    BufferOrder:Byte;
    BufferOffset:Word;
    Tamanio:Word;
    Page,Offset:Word;
    Lo_Offset,Hi_Offset,Lo_Tamanio,Hi_Tamanio:Byte;


IMPLEMENTATION

USES DOS;

VAR OldPort21:Byte;
    OldVector:Pointer;


PROCEDURE ADJUSTSFX(VAR A;VOL:Byte); Assembler;
ASM
 MOV CX,SizeSFX
 PUSH DS
 LDS SI,[A]
 LES DI,[A]
 MOV DL,VOL
 @BUC:
 LODSB
 MOV DH,CL
 MOV CL,DL
 SHR AL,CL
 MOV CL,DH
 STOSB
 DEC CX
 JNZ @BUC
 POP DS
END;


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

PROCEDURE WriteDSP(value : Byte);
BEGIN
  WHILE Port[SB_Port+$C] AND $80 <> 0 DO;
  Port[SB_Port+$C] := Value;
END;

FUNCTION ReadDSP : byte;
BEGIN
  WHILE Port[Sb_Port+$0E] and $80 = 0 do;
  ReadDSP := Port[SB_Port+$0A];
END;


FUNCTION SpeakerOn: Byte;
BEGIN
  WriteDSP($D1);
END;

Function DSPVersion:WorD;
VAR A:Word;
BEGIN
 WriteDSP($E1);
 A:=ReadDSP+ReadDSP SHL 8;
 DSPVersion:=A
END;


FUNCTION SpeakerOff: Byte;
BEGIN
  WriteDSP($D3);
END;

PROCEDURE DMAStop;
BEGIN
 WriteDSP($D0);
END;

PROCEDURE DMAPause;
BEGIN
 WriteDSP($D4);
END;

FUNCTION ResetDSP: Boolean;
BEGIN
 Port[SB_Port+6] := 1;
 EsperaBarrido;
 Port[SB_Port+6] := 0;
 EsperaBarrido;
 IF (Port[SB_Port+$E] AND $80 = $80) AND
   (Port[SB_Port+$A] = $AA) THEN
    ResetDSP := true
 ELSE
   ResetDSP := false;
END;




PROCEDURE GETIRQ; interrupt;
VAR A:Byte;
    ActualPtr:Pointer;
BEGIN

 IF (BufferOffset<>0)  OR ((BufferOffset=0) AND ((STATUS^ AND $0400)=$0400)) THEN
                  BEGIN
                   (* Programemos DMA 1 *)
                   Port[$0A] := 5;
                   Port[$0C] := 0;
                   Port[$0B] := $49;
                   Port[$02] := Lo_offset;
                   Port[$02] := Hi_offset;
                   Port[$83] := Page;
                   Port[$03] := Lo_Tamanio;
                   Port[$03] := Hi_Tamanio;
                   Port[$0A] := 1;

                   (* Programamos DSP *)
                   (* Ponemos el SR en el DSP*)
                   WriteDSP($40);
                   WriteDSP(SR);
                   (* Tipo 8-bit *)
                   WriteDSP($14);
                   (* Tama�o transferencia *)

                   WriteDSP(Lo_Tamanio);
                   WriteDSP(Hi_Tamanio);
                   (* Ahora preparo el siguiente trozo en el buffer *)
                   IF BufferOffset>=0 THEN WaitingSFX:=False;
                   BufferOrder:=BufferOrder XOR 1;
                   INC(BufferOffset, Tamanio+1);
                   IF BufferOffset=SizeSFX THEN BufferOffset:=0;
                   IF longint(BufferSize+BufferOffset)>SizeSFX THEN Tamanio:=SizeSFX-BufferOffset
                                                      ELSE Tamanio:=BufferSize;
                   MOVE(pointer(longint(SFXPtr)+BufferOffset)^,Buffer[BufferOrder],Tamanio);
                   Dec(Tamanio); (*DMA -1 *)
                   Offset := Seg(Buffer[BufferOrder]) SHL 4 + Ofs(Buffer[BufferOrder]);
                   Page := (Seg(Buffer[BufferOrder]) + Ofs(Buffer[BufferOrder]) SHR 4) SHR 12;
                   Lo_Tamanio:=Lo(Tamanio);
                   Hi_Tamanio:=Hi(Tamanio);
                   Lo_Offset:=Lo(Offset);
                   Hi_Offset:=Hi(Offset);
                  END ELSE BEGIN
                            Status^:=Status^ AND $F7FF;
                            WaitingSFX:=False;
                           END;
 A:=Port[SB_Port+$E];
 Port[$20]:=$20;
END;

PROCEDURE PlayBack(Siz : word; Rate : Byte);
BEGIN
  SR:=Rate;
  SizeSFX:=Siz;

  BufferOrder:=0;
  BufferOffset:=0;
  IF SizeSFX<BufferSize THEN Tamanio:=SizeSFX
                        ELSE Tamanio:=Buffersize;
  MOVE(SFXPTR^,Buffer[BufferOrder],Tamanio);
  DEC(Tamanio);

  Offset := Seg(Buffer[BufferOrder]) SHL 4 + Ofs(Buffer[BufferOrder]);
  Page := (Seg(Buffer[BufferOrder]) + Ofs(Buffer[BufferOrder]) SHR 4) SHR 12;
  Lo_Tamanio:=Lo(Tamanio);
  Hi_Tamanio:=Hi(Tamanio);
  Lo_Offset:=Lo(Offset);
  Hi_Offset:=Hi(Offset);

  WriteDSP($40);
  WriteDSP(SR);
  (* Programemos DMA 1 *)
  Port[$0A] := 5;
  Port[$0C] := 0;
  Port[$0B] := $49;
  Port[$02] := Lo_offset;
  Port[$02] := Hi_offset;
  Port[$83] := page;
  Port[$03] := Lo_Tamanio;
  Port[$03] := Hi_Tamanio;
  Port[$0A] := 1;

  (* Programamos DSP *)
  (* Ponemos el SR en el DSP*)
  (* Tipo 8-bit *)
  WriteDSP($14);
  (* Tama�o transferencia *)
  Status^:=Status^ OR $0800;  (* SFX Sonando *)
  WriteDSP(Lo_Tamanio);
  WriteDSP(Hi_Tamanio);

  (* Ahora preparo el siguiente trozo en el buffer *)
  BufferOrder:=BufferOrder XOR 1;
  INC(BufferOffset, Tamanio+1);
  IF BufferOffset>=SizeSFX THEN BufferOffset:=0;
  IF longint(BufferSize+BufferOffset)>SizeSFX THEN Tamanio:=SizeSFX-BufferOffset
                                              ELSE Tamanio:=BufferSize;
  MOVE(pointer(longint(SFXPtr)+BufferOffset)^,Buffer[BufferOrder],Tamanio);
  Offset := Seg(Buffer[BufferOrder]) SHL 4 + Ofs(Buffer[BufferOrder]);
  Page := (Seg(Buffer[BufferOrder]) + Ofs(Buffer[BufferOrder]) SHR 4) SHR 12;
  Lo_Tamanio:=Lo(Tamanio);
  Hi_Tamanio:=Hi(Tamanio);
  Lo_Offset:=Lo(Offset);
  Hi_Offset:=Hi(Offset);
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


PROCEDURE InstallSFX(Base,IRQ,DMA:Word;Stat:Pointer);
BEGIN
 Status:=Stat;
 SFXPtr:=NIL;
 SB_IRQ:=IRQ;
 SB_DMA:=DMA;
 SB_Port:=Base;
 ASM
  IN AL,021h
  MOV OldPort21,AL
  MOV CX,SB_IRQ
  MOV AH,0FEh
  ROL AH,CL
  AND AL,AH
  OUT 021h,AL
 END;
 GetIntVec(8+SB_IRQ,OldVector);
 SetIntVec(8+SB_IRQ,@GetIRQ);
 ResetDSP;
 SpeakerOn;
END;

PROCEDURE ReleaseSFX;
BEGIN
 DMAStop;
 SetIntVec(8+SB_IRQ,OldVector);
 ASM
  MOV AL,OldPort21
  OUT 021h,AL
 END;
 SpeakerOff;
END;

FUNCTION SBDetect:String;
VAR S:String;
    H,L:Byte;
BEGIN
 L:=DSPVersion AND $F;
 H:=DSPVERSION SHL 8;
 IF (H=1) OR ((H=2) AND (L=0)) THEN S:='' ELSE
    IF (H=2) AND (L>0) THEN S:='2.0' ELSE
     IF H=3 THEN S:='Pro' ELSE
      S:='16 o superior';
 SBDETECT:=S;
END;


END.