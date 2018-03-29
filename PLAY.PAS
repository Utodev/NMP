PROGRAM PLAAY;

{$M 2000,0,250000}
{$X+}
{$I-}
{$R-}
{$S-}

USES MyCrt,Dos;

VAR BIOSTIMERHANDLER:Procedure;

{$I CURSON.SRC}
{$I CURSOFF.SRC}
CONST Title:Packed ARRAY[1..33] OF CHAR='SND Player V2.0 (C) 1995 NM Soft.';

TYPE ligadura=^nota;
     NOTA=record
           dur,frec:word;
           sig:ligadura
          end;

     String5=String[5];
VAR PLAYDAT:Record
             Nombre:String5;
             Primero:ligadura;
             Actual:ligadura
            END;
    TimerIntVec:Procedure;  (*Almacena el vector de interrupci¢n del timer del PC*)
    Time:Word;         (*Retardo siguiente nota en PLAY*)

{$I BufferRD.POO}

VAR B:BufferRd;

{$F+}

PROCEDURE TimerRutine; interrupt;
BEGIN
   Dec(Time);  (*Decrementa el tiempo que le falta para cambiar de nota*)
   IF (Time=0) THEN
    BEGIN
     Sound(Playdat.actual^.frec);
     time:=playdat.actual^.dur DIV 100;
     IF Time=0 THEN Time:=1;
     Playdat.actual:=playdat.actual^.sig;
    END;
   INLINE ($9C);
   BIOSTimerHandler;  (*Llama a antigua rutina de tratamiento de interrupci¢n*)
END;

PROCEDURE PLAY(TEMA:string5);
VAR F:FILE;
    L,L1:Ligadura;

BEGIN
  Assign(F,'ADV\'+Tema+'.SND');
  Reset(F,1);
  Write('Cargando...');
  B.Inicializar(F);
  New(Playdat.primero);
  L:=Playdat.primero;
  WHILE NOT B.EOFL(F) DO
   BEGIN
    B.Leer(F,L^.dur,2);
    B.Leer(F,L^.frec,2);
    IF NOT B.EOFL(F) THEN IF L^.dur<>0 THEN BEGIN
                                             New(L^.sig);
                                             L:=L^.sig
                                            END;
    IF B.EOFL(F) AND (L^.dur=0) THEN BEGIN
                                      L1:=Playdat.primero;
                                      WHILE L1^.sig<>L DO L1:=L1^.sig;
                                      Dispose(L1^.sig);
                                      L:=L1;
                                     END;
        END;
L^.sig:=Playdat.primero;
PlayDat.actual:=playdat.primero;
PlayDat.nombre:=tema;
getIntVec($8,@BIOSTimerHandler);
SetIntVec($8,@TimerRutine);
END;

VAR KEY:char;
CONST Freq:Word=19;

PROCEDURE A;
BEGIN
 WriteLn('Sintaxis correcta:  PLAY Nombre_de_Fichero_sin_Extensi¢n.')
END;

BEGIN
 FillChar(Mem[$a000:0],64000,0);  (* para que no se use como extern *)
 IF Title[1]<>'S' THEN Exit;
 IF Title[3]<>'D' THEN Exit;
 IF Title[12]<>'V' THEN Exit;
 IF Title[26]<>'N' THEN Exit;
 WriteLn(Title);
 WriteLn;
 IF (ParamCount=0) OR (length(ParamStr(1))>5) THEN
  BEGIN
   WriteLn('Error en par metros.');A;
   Halt(1)
  END;
 IF FSearch('ADV\'+ParamStr(1)+'.SND','')='' THEN
  BEGIN
   WriteLn('Fichero no se encuentra.');A;
   Halt(1)
  END;
 Time:=1;
 Play(ParamStr(1));
 CursorOff;
 REPEAT
  Key:=ReadKey;
 UNTIL Key=#27;
 SetIntVec($8,@BIOSTimerHandler);
 Nosound;
 CursorOn;
END.