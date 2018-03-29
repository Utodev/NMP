USES adliblib,dos,DSP,CRT,SBMixer;

{$I BufferRd.poo}

VAR BasePort:Word;

    A:Char;

FUNCTION INITSFX:Boolean;
VAR Aux:Boolean;
BEGIN
 InitSFX:=False;
 Aux:=ResetDSP(1);
 IF Aux THEN BEGIN              (* SB en Port 210h *)
              BasePort:=$210;
              InitSFX:=True;
              exit
             END;
 Aux:=ResetDSP(2);
 IF Aux THEN BEGIN              (* SB en Port 220h *)
              BasePort:=$220;
              InitSFX:=True;
              exit
             END;
 Aux:=ResetDSP(3);
 IF Aux THEN BEGIN               (* SB en Port 230h *)
              BasePort:=$230;
              InitSFX:=True;
              exit
             END;
 Aux:=ResetDSP(4);               (* SB en Port 240h *)
 IF Aux THEN BEGIN
              BasePort:=$240;
              InitSFX:=True;
              exit
             END;
 IF NOT Aux THEN BasePort:=1; (* Nada, pues sin sonido *)
 InitSFX:=Aux;
END;

FUNCTION ReadKey:Char; Assembler;
ASM
 XOR AX,AX
 INT 16h
 XOR AH,AH
END;

VAR Key:Char;
    Instrumento:Byte;
    Code:Integer;
TYPE Pnota= ^Nota;
     Nota= RECORD
            dur:Word;
            esc,note:byte;
            sig:pnota
           END;

     Header= RECORD
              ID: ARRAY[0..2] OF Char;
              Inst:ARRAY[1..9] OF Byte;
              Pos:ARRAY[1..9] OF Longint;
             END;

     SBNota = RECORD
               Dur:Word;
               Esc,Note:Byte
              END;



VAR SBMAct, SND : Boolean;
    NotaAct : Array[1..9] OF Boolean;
    SBDAT : RECORD
             Primero:ARRAY [1..9] OF PNota;
             Actual:ARRAY [1..9] OF PNota;
            END;
    TIME : ARRAY [1..9] OF LongInt;
    Head:Header;
    F:File;
    SBN:SBNOTA;
    J:Word;
    K:Word;
    Ini,Fin:Longint;
    channel:BytE;
    TimerIntVec:Procedure;
    BR:BufferRD;

{$F+}

PROCEDURE TimerSBRutine; interrupt;
VAR I:Byte;
BEGIN
 IF SBMAct AND SND THEN
   FOR I:=1 TO 9 DO IF Head.inst[I]<>0 THEN
    BEGIN
     Dec(Time[I]);  (*Decrementa el tiempo que le falta para cambiar de nota*)
     IF (Time[I]=0) THEN
      BEGIN
       IF NotaAct[I] THEN NoteOff(I);
       NoteOn(I,SBDat.actual[I]^.esc,SBDat.actual[I]^.note);
       NotaAct[I]:=True;
       time[I]:=SBDat.actual[I]^.dur DIV 100;
       IF Time[I]=0 THEN Time[1]:=1;
       SBdat.actual[I]:=SBdat.actual[I]^.sig;
    END
  END;
 INLINE ($9C);
 TimerIntVec;  (*Llama a antigua rutina de tratamiento de interrupci¢n*)
END;

{$F-}

PROCEDURE LoadChannel(Can:Byte;ini,fin:longint);
VAR count:longint;
    P:Pnota;
BEGIN
 IF NOT (Channel IN [1..9]) THEN Exit;
 count:=ini;
 WHILE (count<fin) AND NOT BR.EOFL(F) DO
  BEGIN
   IF count=ini THEN BEGIN
                      New(SBDAT.primero[can]);
                      SBDAT.actual[can]:=SBDAT.primero[can];
                      P:=SBDAT.primero[can];
                     END
                ELSE BEGIN
                      New(P^.sig);
                      P:=P^.sig;
                     END;
   BR.Leer(F,SBN,SizeOf(SBNota));
{   P^.Note:=sbn.Note;
   P^.dur:=sbn.dur;
   p^.esc:=sbn.esc;}
   MOVE(SBN,P^,SizeOf(SBN));
   Inc(count,SizeOf(SBNOta));
  END;
 P^.sig:=SBDat.primero[can];
END;

VAR P:InstType;

PROCEDURE Load(A , B : Word);
VAR F:FILE;
    C:word;
BEGIN
 Assign(F,'ADV\SBLASTER.DRV');
 Reset(F,1);
 BlockRead(F,mem[$a000:0],1024);
 C:=B;
 WHILE C<>0 DO BEGIN
                BlockRead(F,P,16);
                DEC(C);
               END;
 LoadInstrument(A,P);
 Close(F)
END;

PROCEDURE SINTAXIS;
BEGIN
 WriteLn('SINTAXIS: PLAYSB <fichero[.SBM]>');
 WriteLn;
 WriteLn('No debes especificar el subdirectorio ADV, se supone implicitamente.');
 WriteLn('Por ejemplo: PLAYSB 1 toca el fichero ADV\1.SBM');
 WriteLn;
 Halt;
END;

 (* PRINCIPAL *)
 VAR DA:Boolean;

BEGIN
 {DirectVideo:=false;}
  DA:=ParamStr(2)<>'CSG';
 IF DA THEN WriteLn('PlaySB 5.0. Toca ficheros SBM en SoundBlaster/Adlib');
 IF NOT InitSFX THEN BEGIN
                      IF NOT AdlibPresent THEN BEGIN
                                           IF NOT DA THEN BEGIN
                                                       Textattr:=$4e;
                                                       GotoXy(1,25);
                                                       WriteLn(' No se encuentra tarjeta de sonido.');
                                                       ReadKey;
                                                      END
                                                      ELSE
                                           WriteLn('Error: No se encuentra tarjeta de sonido.');
                                           Halt
                                          END
                                     ELSE BasePort:=$388;
                      END;
 Move(Mem[0:0],Mem[$a000:0],64000);
 FOR J:=1 TO 9 DO Time[J]:=1;
 FillChar(Sbdat,SizeOf(SBDat),0);
 FillChar(NotaAct,9,0);
 IF ParamCount=0 THEN SINTAXIS;
 {$I-}
 Assign(F,'adv\'+ParamStr(1)+'.SBM');
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      WriteLn('Fichero no se encuentra.');
                      Halt
                     END;
 IF DA THEN WriteLn('Cargando...');
 BR.Inicializar(F);
 Br.Leer(F,Head,sizeof(header));
 J:=1;
 WHILE J<10 DO
  BEGIN
   WHILE Head.Inst[J]=0 DO Inc(J);
   Ini:=Head.Pos[J];
   Channel:=J;
   WHILE (J<9) AND (Head.Inst[J+1]=0) DO Inc(J);
   IF J=9 THEN Fin:=MaxLongInt ELSE Fin:=Head.Pos[J+1];
   LoadChannel(Channel,ini,fin);
   IF J=Channel THEN INC(J);
  END;

 FOR J:=1 TO 9 DO IF head.inst[J]<>0 THEN Load(J,head.inst[j]);
 GetIntVec($8,@TimerIntVec);
 SetIntVec($8,@TimerSBRutine);
 SBMACT:=true;
 SND:=True;
 IF DA THEN BEGIN
             WriteLn('[Sonando]');
             WriteLn('Pulse ESC para finalizar. Pulse "+" o "-" para controlar volumen.');
             WriteLn('(s¢lo SB Pro o superior)');
            END;
 MixerPort(BasePort);
 REPEAT
  A:=Readkey;
  CASE A OF
   '+':V_Master(LRChannel,+1);
   '-':V_Master(LRChannel,-1);
  END;
 UNTIL A=#27;
 SetIntVec($8,@TimerIntVec);
 FOR J:=1 TO 9 DO IF NotaAct[J] THEN NoteOff(J);
END.




