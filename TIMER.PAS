
CONST TIMERINTR = 8;
      PIT_FREQ = $1234DD;
      TIMERFreq:Word=19;

VAR BIOSTimerHandler : procedure;
    clock_ticks, counter : longint;
{$F+}

var Canales_acabados:Byte;
    Canales_totales:Byte;

PROCEDURE TimerHandler; interrupt;
VAR W:Word;
    I,VA:Byte;
     SBNota :RECORD
               Dur:Word;
               Esc,Note:Byte
              END;
     PCNota:RECORD
              dur,frec:word;
            end;
BEGIN

 IF ((Flags[0] AND $1220)=$1200) THEN   (* Ficheros SND *)
      BEGIN
       Dec(Time[1]);  (*Decrementa el tiempo que le falta para cambiar de nota*)
       IF (Time[1]=0) THEN
        BEGIN
         MOVE(SoundDat.Actual[1]^,PCNota,4);
         Sound(PCNota.frec);
         time[1]:=PCNota.Dur DIV 100;
         IF Time[1]=0 THEN Time[1]:=1;
         INC(Longint(SoundDAT.Actual[1]),4);
         DEC(Sounddat.Size[2],4);
         IF Sounddat.size[2]=0 THEN
          BEGIN
          WaitingMusic:=False; (* por si acaso *)
          IF (Flags[0] AND $2000)<> $2000 THEN
           BEGIN   (* Este modo de acabar los FPLAY puede que haga ruido al acabar *)
            Flags[0]:=Flags[0] AND $EFFF;
            NoSound;
           END
           ELSE BEGIN
                 SoundDat.Actual[1]:=BufferMusic;
                 SoundDat.Size[2]:=SoundDat.Size[1];
                END;
         END;
        END
      END;

  IF (flags[0] AND $1220)=$1220 THEN  (* Ficheros SBM *)
    BEGIN
       IF fadingFMOut THEN BEGIN
                       fadingFMOut:=False;
                       FOR I:=1 TO 9 DO BEGIN
                                         GetVolume(I,VA);
                                         IF VA<62 THEN fadingFMOut:=True;
                                         INC(VA);
                                         IF VA<64 THEN SetVolume(I,VA);
                                        END;
                        IF NOT fadingFMOut THEN BEGIN
                                            Silence;
                                            Flags[0]:=Flags[0] AND $EFFF;
                                            WaitingMusic:=False;
                                           END;
                      END;
       IF fadingFMIn THEN BEGIN
                       fadingFMIn:=False;
                       FOR I:=1 TO 9 DO BEGIN
                                         GetVolume(I,VA);
                                         IF VA>VolumeFM[I] THEN fadingFMIn:=True;
                                         Dec(VA);
                                         IF (VA>=VolumeFM[I]) AND (VA<>255) THEN SetVolume(I,VA);
                                        END;
                      END;

       FOR I:=1 TO 9 DO
        IF Head.Inst[I]<>0 THEN
         BEGIN
          Dec(Time[I]);  (*Decrementa el tiempo que le falta para cambiar de nota*)
          IF (Time[I]=0) THEN
           BEGIN
            MoveD(SoundDAT.Actual[I]^,SBNOTA,4);
            IF NotaAct[I] THEN NoteOff(I);
            NoteOn(I,Sbnota.esc,Sbnota.note);
            NotaAct[I]:=True;
            time[I]:=sbnota.dur DIV 100;
            IF Time[I]=0 THEN Time[I]:=1;
            INC(longint(SoundDAT.Actual[I]),SizeOf(SBNOTa));
            IF (longint(SouNDDAT.Actual[I])-Longint(SoundDat.Inicial[I])=SouNDDAT.Size[I]) THEN
             IF (Flags[0] AND $2000)<> $2000 THEN
              BEGIN
               DEC(Canales_Acabados);
               Head.Inst[I]:=0;
               IF CAnales_Acabados=0 THEN BEGIN
                                           WaitingMusic:=False; (* por si acaso *)
                                           Flags[0]:=Flags[0] AND $EFFF;
                                           Silence;
                                          END
              END
              ELSE BEGIN
                    DEC(Canales_Acabados);
                    IF Canales_Acabados=0 THEN BEGIN
                                                Canales_Acabados:=Canales_Totales;
                                                WaitingMusic:=False;
                                               END;
                    SoundDat.Actual[I]:=SoundDat.Inicial[I];
                   END;
           END (* IF Time... *)
          END (* IF *)
         END ELSE fadingFMOut:=False;

    Dec(TimerCount);
    IF (TimerCount=0) THEN
     BEGIN
      IF (Flags[11]<>0) THEN Dec(Flags[11]);
      TimerCount:=TimerFreq;
     END;

  clock_ticks := clock_ticks + counter;
  if clock_ticks >= $10000 then
    begin
      Inc(SysTime);
      Inc(RetardoPI);
      clock_ticks := clock_ticks - $10000;
      asm pushf end;
      BIOSTimerHandler;
    end
  else Port[$20] := $20;
END;
{$F-}


procedure SetTimer(TimerHandler : pointer; frequency : word);
begin

  clock_ticks := 0;
  counter := $1234DD div frequency;

  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, TimerHandler);

  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;
  TimerFreq:=Frequency;
  TimerCount:=Frequency;
END;

procedure CleanUpTimer;
begin
  { Restore the normal clock frequency }
  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;

  { Restore the normal ticker handler }
  SetIntVec(TIMERINTR, @BIOSTimerHandler);
end;

