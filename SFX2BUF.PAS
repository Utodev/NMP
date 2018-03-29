

UNIT SFX2buf;

{$s-,r-,i-,o+}

(* UNIDAD PARA SONIDO DE EFECTOS POR LA SOUND BLASTER *)


INTERFACE

uses crt;

{$f+}
CONST MaxBlock=4096;
      SFXWait:Boolean=False;
      BufferSize=2048;

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

TYPE Buffers=ARRAY[0..1] OF ARRAY[0..BufferSize-1] OF Byte;

VAR SB_IRQ,SB_Port,SB_DMA:Word;
    SFXPtr:Pointer;
    SizeSFX:Word;
    SR:Byte;
    STATUS:^word;
    Buffer:^Buffers;
    BufferOrder:Byte;
    BufferOffset:Word;
    Page,Offset:Word;
    ActiveSample:Boolean;


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
BEGIN
 IF ActiveSample THEN
  BEGIN
{    (* Lanzo el bloque que ten¡a preparado *)
  WriteDSP($14);
  (* Tama¤o transferencia *)
  WriteDSP(Lo(BufferSize-1));
  WriteDSP(Hi(BufferSize-1));
  WriteDSP($D4);}
    (******** Preparo el siguiente bloque *********)
    (* Primero compruebo si con este bloque se acaba el sample *)
    IF BufferOffset>=SizeSFX-BufferSize THEN
      BEGIN (* pues s¡ *)
         (* si se acaba el sample pueden ocurrir dos cosas, que estemos en modo
            c¡clico o no, si estamos en modo c¡clico pues rellenamos lo que queda
            con el principio del sample y punto, si no es as¡ pues rellenamos de
            ceros el resto y desactivamos la variable de que se est  tocando un
            SFX *)
          IF (STATUS^ AND $0400)=$0400 THEN
           BEGIN (* es c¡clico *)
            MOVE(pointer(longint(sfxPtr)+bufferoffset)^,Buffer^[BufferOrder],SizeSFX-BufferOffset);
            MOVE(sfxPtr^,Buffer^[BufferOrder][SizeSFX-BufferOffset],BufferSize-SizeSFX+BufferOffset);
            BufferOffset:=BufferSize-SizeSFX+BufferOffset;
            SFXWait:=False;
           END
           ELSE
           BEGIN (* no lo es *)
            MOVE(pointer(longint(sfxPtr)+bufferoffset)^,Buffer^[BufferOrder],SizeSFX-BufferOffset);
            FillChar(Buffer^[BufferOrder][SizeSFX-BufferOffset],BufferSize-SizeSFX+BufferOffset,0);
            ActiveSample:=False;
            SFXWait:=False;
           END;
     END
     ELSE
      BEGIN
       MOVE(pointer(longint(sfxPtr)+bufferoffset)^,Buffer^[BufferOrder],BufferSize);
       INC(BufferOffset,BufferSize);
      END

   END
    ELSE
     BEGIN
      FillChar(Buffer^,SizeOf(Buffers),0);
      STATUS^:=STATUS^ AND $F7FF;
     END;   (* IF ACTIVESAMPLE *)

 (* Paso al siguiente bloque *)
 BufferOrder:=BufferOrder XOR 1;
 A:=Port[SB_Port+$E];
 Port[$20]:=$20;
END;

PROCEDURE PlayBack(Siz : word; Rate : Byte);
BEGIN
  SR:=Rate;
  SizeSFX:=Siz;
  BufferOrder:=0;
  MOVE(SFXPTR^,Buffer^,BufferSize*2); (* lleno los dos buffers *)
  BufferOffset:=BufferSize*2;
  Port[$0A] := 5;
  Port[$0C] := 0;
  Port[$0B] := $59;
  Port[$02] := Lo(offset);
  Port[$02] := Hi(offset);
  Port[$83] := page;
  Port[$03] := Lo(2*BufferSize-1);
  Port[$03] := Hi(2*BufferSize-1);
  Port[$0A] := 1;

  (* Escribo sampling rate *)
  WriteDSP($40);
  WriteDSP(SR);
  Status^:=Status^ OR $0800;  (* SFX Sonando *)
  ActiveSample:=True;
  WriteDSP($1C);  (* 8 bit - DAC *)
  (* Tama¤o transferencia *)
  WriteDSP(Lo(BufferSize-1));
  WriteDSP(Hi(BufferSize-1));
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

PROCEDURE GetPageMem(VAR P:Pointer;Size:Word);
(* Obtiene una zona de memoria que este dentro de una misma pagina *)
VAR Offset:Word;
    Aux:Pointer;
BEGIN
 GetMem(P,Size);
 Offset := Seg(P^) SHL 4 + Ofs(Buffer);
 IF Offset+Size>65535 THEN BEGIN
                            GetMem(Aux,Size);
                            FreeMem(P,Size);
                            P:=Aux
                           END;
END;


BEGIN
 GetPageMem(pointer(Buffer),SizeOf(Buffers));
 Offset := Seg(Buffer^) SHL 4 + Ofs(Buffer^);
 Page := (Seg(Buffer^) + Ofs(Buffer^) SHR 4) SHR 12;
END.