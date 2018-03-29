
UNIT VESA;

{$I-,R-,S-,X+,G+}

INTERFACE

CONST WindowA=0;
      WindowB=1;

TYPE
VGAInfoBlock = RECORD
                VESASignature:ARRAY[1..4] OF Char;
                VESAVersion:Word;
                OEMStringPtr:Pointer;
                Capabilities:ARRAY[1..4] OF byte;
                VideoModePtr:Pointer;
                TotalMemory:Word;
                Reserved:ARRAY[0..235] OF Byte;
               END;

ModeInfoBlock = RECORD
                 ModeAttributes:Word;
                 WinAAttributes:Byte;
                 WinBAttributes:Byte;
                 WinGranularity:Word;
                 WinSize:Word;
                 WinASegment:Word;
                 WinBSegment:Word;
                 WinFuncPtr:Word;
                 BytesPerScanLine:Word;

                 XResolution:Word;
                 YResolution:Word;
                 XCharSize:Byte;
                 YCharSize:Byte;
                 NumberOfPlanes:Byte;
                 BitsPerPixel:Byte;
                 NumberOfBanks:Byte;
                 MemoryModel:Byte;
                 BankSize:Byte;
                 NumberOfImagePages:Byte;
                 BytesPerScanLine2:Byte;
                 Reserved:Byte;

                 RedmaskSize:Byte;
                 RedFieldPosition:Byte;
                 GreenMaskSize:Byte;
                 GreenFieldPosition:Byte;
                 BlueMaskSize:Byte;
                 BlueFieldPosition:Byte;
                 RsvdMaskSize:Byte;
                 DirectColorModeInfo:Byte;
                 Reserved2:ARRAY[0..215] OF byte;
                END;

VAR IsVESA:Boolean;

    VESAINFO:VGAInfoBlock;


VAR Granularity:Longint;
    ByteGranularity:Longint;
    LogicWidth:Word;
    ActiveBank:Word;
    scrheight:worD;

VAR Color:Byte;
    ColorOutline:Byte;

FUNCTION GetVESAInfo(VAR Info:VGAInfoBlock):Word;

FUNCTION GetOEMString:String;

FUNCTION ValidMode(Mode:Word):Boolean;

FUNCTION VideoRAMSize:Word;

FUNCTION SetLineWidth(Length:Word):Word;

FUNCTION GetModeInfo(mode:word;VAR IB:ModeInfoBlock):Word;

FUNCTION SetVESAMode(Mode:Word;DefaultWidth:Word):Word;

PROCEDURE CloseGraph;

FUNCTION GetVESAMode(VAR Mode:Word):Word;

FUNCTION SetVESAWindow(Bank:Word;Window:Byte):Word;

FUNCTION GetVESAWindow(VAR Bank:Word;Window:Byte):Word;

FUNCTION SetDisplayStart(Line:WorD;Pixel:Word):Word;

FUNCTION GetMaxLine:Word;

PROCEDURE SelectFont(P:Pointer;Altura:Byte;Width:Pointer);

PROCEDURE PutImage(X,Y:longint;Ancho, Alto:Word;VAR Buffer; OffJmp:Word);

PROCEDURE GetImage(X,Y:longint;Ancho, Alto:Word;VAR Buffer);

PROCEDURE Rectangle(X,Y:longint;Ancho, Alto:Word;Color:Byte);

PROCEDURE _TransparentPut(X,Y:longint;Ancho, Alto:Word;VAR Buffer);

PROCEDURE OuttextXY(X,Y:Word;Texto:String;Efecto:Byte);

PROCEDURE PutPixel(X,Y:longint;Color:Byte);
PROCEDURE PutPixel24(X,Y:longint;R,G,B:Byte);

PROCEDURE EsperaBarrido;

IMPLEMENTATION

TYPE WidthType=ARRAy[Byte] OF Byte;

VAR Font:Pointer;
    Fontheigth:Byte;
    FontWidth:^WidthType;


PROCEDURE SelectFont(P:Pointer;Altura:Byte;Width:Pointer);
BEGIN
 Font:=p;
 FontHeigth:=Altura;
 FontWidth:=Width;
END;

FUNCTION GetGranularity:Word;
VAR IB:ModeInfoBlock;
    Mode:Word;
BEGIN
 getVESAMode(Mode);
 GetModeInfo(Mode,IB);
 GetGranularity:=IB.WinGranularity;
END;



FUNCTION GetVESAInfo(VAR Info:VGAInfoBlock):Word; Assembler;
ASM
 MOV AX,4F00h
 LES DI,[Info]
 INT 10h
END;

FUNCTION GetOEMString:String;
VAR S:String;
    P:^char;
BEGIN
 S:='';
 P:=VESAInfo.OEMStringPtr;
 WHILE p^<>#0 DO BEGIN
                  S:=S+p^;
                  INC(longint(p));
                 END;
 GetOEMString:=S;
END;

FUNCTION VideoRAMSize:Word;
BEGIN
 VideoRamSize:=VESAInfo.TotalMemory*64;
END;


FUNCTION ValidMode(Mode:Word):Boolean;
VAR P:^Word;
BEGIN
 P:=VESAInfo.VideoModePtr;
 ValidMode:=False;
 WHILE P^<>$0FFFF DO BEGIN
                      IF P^=Mode THEN ValidMode:=True;
                      Inc(longint(P),2);
                     END;
END;


FUNCTION GetModeInfo(mode:word;VAR IB:ModeInfoBlock):Word; Assembler;
ASM
 MOV AX,4F01h
 MOV CX,Mode
 LES DI,[IB]
 INT 10h
END;

FUNCTION SetVESAMode(Mode:Word;DefaultWidth:Word):Word;
BEGIN
ASM
 MOV AX,4F02h
 MOV BX,Mode
 INT 10h
END;
 LogicWidth:=DefaultWidth;
 Granularity:=GetGranularity;
 ByteGranularity:=Granularity*1024;
 CASE Mode OF
  $101:scrheight:=480;
  $103:scrheight:=600;
  $105:scrheight:=768;
 END;
END;

PROCEDURE CloseGraph; Assembler;
ASM
 MOV AX,3
 INT 10h
END;


FUNCTION GetVESAMode(VAR Mode:Word):Word; Assembler;
ASM
 MOV AX,4F03h
 INT 10h
 LES DI,[MODE]
 MOV ES:[DI],BX
END;

FUNCTION SetVESAWindow(Bank:Word;Window:Byte):Word; Assembler;
 ASM
{  MOV DX,Activebank
  MOV CX,Bank
  CMP CX,DX
  JZ @FIN} {Anulado para evitar problemas cambio de modo bajo Win y Dosemu}
  MOV ActiveBank,CX
  MOV AX,4F05h
  XOR BH,BH
  MOV BL,Window
  MOV DX,Bank
  INT 10h
  @FIN:
 END;

FUNCTION GetVESAWindow(VAR Bank:Word;Window:Byte):Word; Assembler;
ASM
 MOV AX,4F05h
 MOV BH,1
 MOV BL,Window
 INT 10h
 LES DI,[Bank]
 MOV ES:[DI],DX
END;

FUNCTION SetLineWidth(Length:Word):Word; Assembler;
ASM
 MOV AX,4F06h
 XOR BL,BL
 MOV CX,Length
 INT 10h
 MOV LogicWidth,CX
END;

FUNCTION GetLineWidth(VAR Length:Word):Word; Assembler;
ASM
 MOV AX,4F06h
 MOV BL,1
 INT 10h
 LES DI,[Length]
 MOV ES:[DI],CX
END;

FUNCTION SetDisplayStart(Line:WorD;Pixel:Word):Word; Assembler;
ASM
 XOR BX,BX
 MOV AX,4F07h
 MOV CX,Pixel
 MOV DX,Line
 INT 10h
END;


FUNCTION GetMaxLine:Word; Assembler;
ASM
 MOV AX,4F06h
 MOV BL,1
 INT 10h
 MOV AX,DX
END;

PROCEDURE PutPixel(X,Y:longint;Color:Byte);
VAR Offset:longint;
    Desp:Word;
BEGIN
 Offset:=x+y*logicwidth;
 Desp:=Offset MOD ByteGranularity;
 SetVESAWindow(Offset DIV ByteGranularity,WindowA);
 Mem[$a000:Desp]:=Color;
END;

PROCEDURE PutPixel24(X,Y:longint;R,G,B:Byte);
VAR Offset:longint;
    Desp:Word;
BEGIN
 Offset:=x+y*logicwidth;
 Desp:=Offset MOD ByteGranularity;
 SetVESAWindow(Offset DIV ByteGranularity,WindowA);
 Move(R,Mem[$a000:Desp],3);
END;


FUNCTION IsPixelOff(P:Pointer;X,Y:shortint):Boolean;
BEGIN
 IF (X>7) OR (X<0) OR (Y>15) OR (Y<0) THEN BEGIN
                                            isPixelOff:=true;
                                            exit
                                           end;
 Inc(longint(P),Y);
 isPixelOff:=NOT Boolean( (byte(P^) SHR Y) AND 1);
END;


PROCEDURE WriteCharOutline(X,Y:Word;C:Char);
VAR P:^byte;
    I,J:Byte;
    B:Byte;
    Ant,Post:Byte;
BEGIN
 longint(P):=longint(Font)+(Fontheigth*byte(c));
 FOR I:=0 TO FontHeigth-1 DO
  BEGIN
   IF I=0 THEN Ant:=0 ELSE Ant:=Byte(pointer(longint(p)-1)^);
   IF I=15 THEN Post:=0 ELSE Post:=Byte(pointer(longint(p)+1)^);
   B:=P^;
   FOR J:=0 TO 7 DO
    IF Boolean((B SHR J) AND 1) THEN
     BEGIN
      PutPixel(X+7-J,Y+I,Color);
      IF  (J=7) OR NOT Boolean((B SHR (J+1)) AND 1) THEN PutPixel(X+6-J,Y+I,ColorOutline);
      IF (J=0) OR NOT Boolean((B SHR (J-1)) AND 1) THEN PutPixel(X+8-J,Y+I,ColorOutline);
      IF NOT Boolean((Ant SHR J) AND 1) THEN PutPixel(X+7-J,Y+I-1,ColorOutline);
      IF NOT Boolean((Post SHR J) AND 1) THEN PutPixel(X+7-J,Y+I+1,ColorOutline);
     end;
   INC(longint(p));
  END;
END;

PROCEDURE WriteChar(X,Y:Word;C:Char);
VAR P:^byte;
    I,J:Byte;
    B:Byte;
BEGIN
 longint(P):=longint(Font)+(Fontheigth*byte(c));
 FOR I:=0 TO FontHeigth-1 DO
  BEGIN
   B:=P^;
   FOR J:=0 TO 7 DO
     IF Boolean((B SHR J) AND 1) THEN PutPixel(X+7-J,Y+I,Color);
   INC(longint(p));
  END;
END;

PROCEDURE WriteDouble(X,Y:Word;C:Char);
VAR P:^byte;
    I,J:Byte;
    B:Byte;
BEGIN
 longint(P):=longint(Font)+(Fontheigth*byte(c));
 FOR I:=0 TO FontHeigth-1 DO
  BEGIN
   B:=P^;
   FOR J:=0 TO 7 DO
     IF Boolean((B SHR J) AND 1) THEN BEGIN
                                       PutPixel(X+(7-J)*2,Y+(2*I),Color);
                                       PutPixel(X+(7-J)*2+1,Y+(2*I),Color);
                                       PutPixel(X+(7-J)*2+1,Y+(2*I)+1,Color);
                                       PutPixel(X+(7-J)*2,Y+(2*I)+1,Color);
                                      END;
   INC(longint(p));
  END;
END;


PROCEDURE OuttextXY(X,Y:Word;Texto:String;Efecto:Byte);
VAR I:Byte;
BEGIN
 FOR I:=1 TO Byte(Texto[0]) DO BEGIN
                                CASE EFECTO OF
                                 0:WriteChar(X,Y,texto[I]);
                                 1:WriteCharOutline(X,Y,texto[I]);
                                 2:WriteDouble(X,Y,texto[i]);
                                END;
                                INC(X,FontWidth^[byte(texto[i])]);
                                IF Efecto=2 THEN INC(X,FontWidth^[byte(texto[i])]);
                               END;
END;

PROCEDURE Rectangle(X,Y:longint;Ancho, Alto:Word;Color:Byte);
VAR Offset:Longint;
    Desp:Word;
    Bank:WorD;
    l_w:word;
    Step:Word;
BEGIN
 Step:=64 DIV Granularity;
 Offset:=Y*logicwidth+X;
 bank:=Offset DIV (ByteGranularity);
 desp:=Offset MOD (ByteGranularity);
 SetVESAWindow(bank,WindowA);
 l_w:=logicwidth;
 ASM
  CLD

  MOV AX,0A000h
  MOV ES,AX
  MOV DI,Desp

  MOV AL, Color
  MOV AH, AL
  MOV BX, AX
{ SHL EAX, 16 }         DB 066h, 0C1h, 0E0h, 10h
  MOV AX, BX

  MOV CX,Alto
  @Bucle:
   PUSH CX
   MOV CX,Ancho

   @BUC:
    MOV BX, DI
    ADD BX, CX
    JC  @SALTOBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD
  { REP STOSD }         DB 66h ; REP STOSW
    AND DX, 3
    JZ @FINFILA
   @NOSD:
    MOV CX, DX
    REP STOSB
    JMP @FINFILA

   @SALTOBANCO:

    MOV DX, DI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
    REP STOSB

    PUSH DX
    PUSH AX
    MOV CX,Bank
    add cx,Step
    mov Bank,cx
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
    REP STOSB

   @FINFILA:

    MOV CX, l_w
    SUB CX, Ancho
    ADD DI, CX
    JNC @no_c_banco

   @c_banco:
    MOV CX,Bank
    add cx,step
    mov bank,cx
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

   @no_c_banco:
   pop cx
   dec cx
   jnz @bucle
  end;
 ActiveBank := Bank ;
end;

PROCEDURE PutImage(X,Y:longint;Ancho, Alto:Word;VAR Buffer; OffJmp:Word);
VAR Offset:Longint;
    Desp:Word;
    Bank:WorD;
    l_w:word;
    Step:Word;
BEGIN
 Step:=64 DIV Granularity;
 Offset:=Y*logicwidth+X;
 bank:=Offset DIV (ByteGranularity);
 desp:=Offset MOD (ByteGranularity);
 SetVESAWindow(bank,WindowA);
 l_w:=logicwidth;
 ASM
  CLD
  PUSH DS

  MOV AX,0A000h
  LDS SI,Buffer
  MOV ES,AX
  MOV DI,Desp

  MOV CX,Alto
  @Bucle:
   PUSH CX
   MOV CX,Ancho

   @BUC:
    MOV BX, DI
    ADD BX, CX
    JC  @SALTOBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD
  { REP MOVSD }         DB 66h ; REP MOVSW
    AND DX, 3
    JZ @FINFILA
   @NOSD:
    MOV CX, DX
    REP MOVSB
    JMP @FINFILA

   @SALTOBANCO:

    MOV DX, DI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
    REP MOVSB

    PUSH DX
    PUSH AX
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    MOV AX, 4F05h
    SUB BX, BX
    MOV DX, CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
    REP MOVSB

   @FINFILA:

    MOV CX, l_w
    SUB CX, Ancho
    ADD DI, CX
    JNC @no_c_banco

   @c_banco:
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

   @no_c_banco:
   ADD SI, OffJmp
   POP CX
   DEC CX
   JNZ @Bucle

   POP DS
  end;
 ActiveBank := Bank ;
end;

PROCEDURE _TransparentPut(X,Y:longint;Ancho, Alto:Word;VAR Buffer);
VAR Offset:Longint;
    Desp:Word;
    Bank:WorD;
    l_w:word;
    Step:Word;
BEGIN
 Step:=64 DIV Granularity;
 Offset:=Y*logicwidth+X;
 bank:=Offset DIV (ByteGranularity);
 desp:=Offset MOD (ByteGranularity);
 SetVESAWindow(bank,WindowA);
 l_w:=logicwidth;
 ASM
  CLD
  PUSH DS

  MOV AX,0A000h
  LDS SI,Buffer
  MOV ES,AX
  MOV DI,Desp

  MOV CX,Alto
  @Bucle:
   PUSH CX
   MOV CX,Ancho


   @BUC:
    MOV BX, DI
    ADD BX, CX
    JC  @SALTOBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD

  @PUNTO_4:
  { LODSD }             DB 66h ; LODSW
    OR AL, AL
    JZ @PUNTO_4_A
    MOV [ES:DI], AL
  @PUNTO_4_A:
    OR AH, AH
    JZ @PUNTO_4_B
    MOV [ES:DI+1], AH
  @PUNTO_4_B:
  { SHR EAX, 16 }       DB 66h, 0C1h, 0E8h, 10h
    OR AL, AL
    JZ @PUNTO_4_C
    MOV [ES:DI+2], AL
  @PUNTO_4_C:
    OR AH, AH
    JZ @PUNTO_4_D
    MOV [ES:DI+3], AH
  @PUNTO_4_D:
    ADD DI, 4
    DEC CX
    JNZ @PUNTO_4

    AND DX, 3
    JZ @FINFILA
   @NOSD:
    MOV CX, DX
   @PUNTO_1:
    MOV AL, [SI]
    OR AL, AL
    JZ @PUNTO_1_A
    MOV [ES:DI], AL
   @PUNTO_1_A:
    INC DI
    INC SI
    DEC CX
    JNZ @PUNTO_1
    JMP @FINFILA

   @SALTOBANCO:

    MOV DX, DI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
   @PUNTO_B1:
    MOV AL, [SI]
    OR AL, AL
    JZ @PUNTO_B1_A
    MOV [ES:DI], AL
   @PUNTO_B1_A:
    INC DI
    INC SI
    DEC CX
    JNZ @PUNTO_B1

    PUSH DX
    PUSH AX
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    MOV AX, 4F05h
    SUB BX, BX
    MOV DX, CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
   @PUNTO_C1:
    MOV AL, [SI]
    OR AL, AL
    JZ @PUNTO_C1_A
    MOV [ES:DI], AL
   @PUNTO_C1_A:
    INC DI
    INC SI
    DEC CX
    JNZ @PUNTO_C1

   @FINFILA:

    MOV CX, l_w
    SUB CX, Ancho
    ADD DI, CX
    JNC @no_c_banco

   @c_banco:
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

   @no_c_banco:
   POP CX
   DEC CX
   JNZ @Bucle

   POP DS
  end;
 ActiveBank := Bank ;
end;

PROCEDURE GetImage(X,Y:longint;Ancho, Alto:Word;VAR Buffer);
VAR Offset:Longint;
    Desp:Word;
    Bank:WorD;
    l_w:word;
    Step:Word;
BEGIN
 Step:=64 DIV Granularity;
 Offset:=Y*logicwidth+X;
 bank:=Offset DIV (ByteGranularity);
 desp:=Offset MOD (ByteGranularity);
 SetVESAWindow(bank,WindowA);
 l_w:=logicwidth;
 ASM
  CLD
  PUSH DS

  MOV AX,0A000h
  LES DI,Buffer
  MOV DS,AX
  MOV SI,Desp

  MOV CX,Alto
  @Bucle:
   PUSH CX
   MOV CX,Ancho


   @BUC:
    MOV BX, SI
    ADD BX, CX
    JC  @SALTOBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD
  { REP MOVSD }         DB 66h ; REP MOVSW
    AND DX, 3
    JZ @FINFILA
   @NOSD:
    MOV CX, DX
    REP MOVSB
    JMP @FINFILA

   @SALTOBANCO:

    MOV DX, SI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
    REP MOVSB

    PUSH DX
    PUSH AX
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    MOV AX, 4F05h
    SUB BX, BX
    MOV DX, CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
    REP MOVSB

   @FINFILA:

    MOV CX, l_w
    SUB CX, Ancho
    ADD SI, CX
    JNC @no_c_banco

   @c_banco:
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

   @no_c_banco:
   POP CX
   DEC CX
   JNZ @Bucle

   POP DS
  end;
 ActiveBank := Bank ;
end;

PROCEDURE EsperaBarrido ; Assembler;
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

BEGIN
 IsVesa:=GetVESAInfo(VesaInfo)=$004F;
 Color:=15;
 ColorOutline:=8;
END.
