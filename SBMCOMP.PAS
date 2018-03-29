USES CRT,DOS,ParaCaja,adliblib,redirect,RatonASM;
{$M 10000,0,300000,i-,r-,s-}

CONST Maxlin=64;

TYPE NOTE=RECORD
           ESCALA,NOTA:Byte
          END;
TYPE Pattern=ARRAY[1..9,1..Maxlin] OF NOte;

VAR PARTITURA:ARRAY[Byte] OF Byte;
    PATTERNS:ARRAY[Byte] OF ^Pattern;
    ActualPattern:Byte;
    LastPattern:Byte; (* Ultima Pattern v lida *)
    PlayPattern:Byte;
    Mode:Byte;


CONST Spaces:String='                                                           ';

VAR   P:Pattern;

      NotaAct:ARRAy[1..9] OF Boolean;
      CY:Word;
      ADD:Byte;
      LineasB:Word;
      LineaBase:Word;
      Ch:Char;
      Ext:Boolean;
      Exp,Camb:Byte;
      I,CX:Byte;
      Escala:Byte;
      Tempo:Byte;
      Inst:ARRAy[1..9] OF Byte;
      Stri:String[4];
      code:integer;
      StrAux:String;
      Aux:Byte;
      MaxInst:Byte;
      F:FILE;
      J:WorD;
      Bloque:RECORD
              Canal:Byte;
              Inicio,Fin:Word;
              Pattern:Byte;
             END;
     Nota_,Escala_:ShortInt;

{$I TOMATEC.SRC}
{$I CURSOFF.SRC}
{$I CURSON.SRC}

{* * * * * * * * * * * * * * *INICIO DEFINICION CLASE PANTALLA * * * * * * *}

{Esta clase almacena el contenido de una pantalla de un PC en modo texto para
 poder recuperarse m s tarde}

TYPE
PANTALLA = Object

    XPANT,YPANT:Integer;
    SalvaX,SalvaY:Integer;
    SegmenVid:Word;
    TamBufferVideo:Word;
    PtrSalva:^Word;
    PtrVideo:^Word;
    VideoSeg:Word;


FUNCTION MONOCROMO : Boolean;
{Devuelve True si estamos en un monitor monocromo}
PROCEDURE Salvar;
{Salva la pantalla en el Heap}
PROCEDURE Recuperar;
{Recupera la pantalla mostr ndola}
PROCEDURE Mostrar;
{Recupera la pantalla mostr ndola pero no libera memoria}
PROCEDURE Inicializar(X,Y:Integer);
{Inicializa diciendo el n§ de l¡neas y columnas sobre las que se est  traba-}
{jando en el momento.­Debe utilizarse con cualquier Objeto antes de usar nin-}
{guna de las otras funciones de la clase}


END;

FUNCTION Pantalla.MONOCROMO : Boolean; Assembler;
 ASM
  INT 17
  OR AX,30h
  CMP AX,30h
  JZ @CIERTO
  AND AX,AX
  JMP @FIN
  @CIERTO:
  MOV AX,1
  @FIN:
END;

PROCEDURE Pantalla.Salvar;
BEGIN
 SalvaX:=WhereX;
 SalvaY:=Wherey;
 TamBufferVideo:=XPant*YPant*2;
 GetMem(PtrSalva,TamBufferVideo);
 IF Pantalla.Monocromo THEN SegmenVid:=$b800 ELSE
                   SegmenVid:=$b000;
 PtrVideo:=Ptr(SegmenVid,0);
 MOVE(PtrVideo^,PtrSalva^,TamBufferVideo)
END;


PROCEDURE Pantalla.Recuperar;
BEGIN
Move(PtrSalva^,PtrVideo^,TamBufferVideo);
FreeMem(PtrSalva,TamBufferVideo);
GotoXY(SalvaX,SalvaY)
END;

PROCEDURE Pantalla.Mostrar;
BEGIN
Move(PtrSalva^,PtrVideo^,TamBufferVideo);
GotoXY(SalvaX,SalvaY)
END;

PROCEDURE Pantalla.Inicializar(x,y:Integer);
BEGIN
XPANT:=X;
YPANT:=Y;
END;

{* * * * * * * * * * * * * * *FIN DEFINICION CLASE PANTALLA * * * * * * * * *}

PROCEDURE Beep;
(* Un pitido *)
BEGIN
 Sound(100);
 Delay(400);
 NoSound;
END;


FUNCTION ReadLn2(VAR S:String;Long:Byte):Char; (* Rutina de input mejor que la estandar *)
VAR X,Y:Byte;
    Cursor:Byte;
    Ch:Char;
    Extend:Boolean;
    Explor:Byte;
    Camb:Byte;
    S1:String;
    Primero:Boolean;
BEGIN
 Primero:=TRUE;
 X:=WhereX;
 Y:=WhereY;
 Cursor:=0;
 CursorOff;
 REPEAT
  GotoXY(X,Y);
  Write(Copy(S,1,Long),Copy(Spaces,1,Long-byte(S[0])));
  GotoXY(X+Cursor,Y);
  CursorOn;
  REPEAT
  UNTIL TomaTecla(Ch,Extend,Explor,Camb);
  CursorOff;
  S1:=UpCase(Ch);
  IF Extend AND (Explor=79) THEN Cursor:=byte(S[0]);
  IF Extend AND (Explor=71) THEN Cursor:=0;
  IF Extend AND (Explor=77) THEN
   IF (Cursor<byte(S[0])) THEN Inc(Cursor) ELSE Beep;
  IF Extend AND (Explor=75) THEN
   IF (Cursor>0) THEN Dec(Cursor) ELSE Beep ;
  IF Extend AND (Explor=83) THEN IF PRIMERO THEN S:=''
                                            ELSE IF Cursor<byte(S[0])
                                             THEN Delete(S,Cursor+1,1)
                                             ELSE Beep;
  IF (Ch IN [#32..#255]) THEN
   IF length(S)<Long THEN BEGIN
                           Insert(S1,S,Cursor+1);
                           Inc(Cursor)
                          END ELSE Beep;
  IF Ch=#8 THEN IF Cursor<>0 THEN BEGIN
                                   Delete(S,Cursor,1);
                                   Dec(Cursor)
                                  END ELSE Beep;
 Primero:=False;
 UNTIL (Ch IN [#9,#13,#27]) OR (EXtend AND (Explor=15));
 GotoXY(X,Y);
 Write(Copy(S,1,Long),Copy(SPACES,1,Long-byte(S[0])));
 GotoXY(X+Cursor,Y);
 IF Extend AND (Explor=15) THEN Ch:=#15;
 ReadLn2:=Ch;
END;


VAR Pant:Pantalla;


FUNCTION NotaDe(B:Byte):String;
BEGIN
 IF B>=100 THEN DEC(B,100); (* Por si es la nota de fin de fichero *)
 CASE B OF
  1:NotaDe:='C#';
  2:NotaDe:='D ';
  3:NotaDe:='D#';
  4:NotaDe:='E ';
  5:NotaDe:='F ';
  6:NotaDe:='F#';
  7:NotaDe:='G ';
  8:NotaDe:='G#';
  9:NotaDe:='A ';
 10:NotaDe:='A#';
 11:NotaDe:='B ';
 12:NotaDe:='C ';
 13:NotaDe:='--';
 14:NotaDe:='þþ';
 15:NotaDe:='XX';
 END
END;

PROCEDURE Centre(S:String);
BEGIN
 Gotoxy(41-length(S) DIV 2,Wherey);
 Write(' ',S,' ');
END;

FUNCTION EscalaDe(B:Note):String;
VAR Stri:String;
BEGIN
 IF B.Nota>=100 THEN DEC(B.Nota,100);
 IF B.Nota=13 THEN EscalaDe:='--'
 ELSE
 IF B.Nota=14 THEN EscalaDe:='þþ'
 ELSE
 IF B.Nota=15 THEN EscalaDe:='XX'
  ELSE BEGIN
        STR(B.Escala,Stri);
        EscalaDe:=' '+Stri;
       END;
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


PROCEDURE Mostrar;
VAR I,J:Byte;
    Q:Word;
BEGIN
 Q:=Bloque.Fin; IF Q=0 THEN Q:=Bloque.Inicio;
 GotoXY(1,3);
 TextAttr:=$70;
 Esperabarrido;
 Punterooff;
 Write('    ');
 FOR I:=1 TO 9 DO Write('  ',I,'-',Inst[I]:2,'  ');Clreol;
 WriteLn;
 FOR I:=0 TO 19+25 DO
  BEGIN
   IF (I+LineaBase-1) MOD 4=0 THEN TextAttr:=$74
                              ELSE TextAttr:=$70;
   Write(' ',(I+LineaBase-1):4,' ');
   FOR J:=1 TO 9 DO
    BEGIN
    IF (I+LineaBase-1) MOD 4=0 THEN TextAttr:=$74
                               ELSE TextAttr:=$70;
     IF (J=CX) AND (LineaBase+I=CY) THEN TextAttr:=$1E;
     IF (J=Bloque.Canal) AND (Partitura[ActualPattern]=Bloque.Pattern) THEN IF ((LineaBase+I>=Bloque.Inicio)
      AND (LineaBase+I<=Q)) THEN
       IF (TextAttr=$70) OR (TextAttr=$74) THEN TextAttr:=$30
                                           ELSE TextAttr:=$43;
     Write(NotaDe(Patterns[partitura[actualpattern]]^[J,LineaBase+I].Nota),
      EscalaDe(patterns[partitura[actualpattern]]^[J,LineaBase+I]));
     TextAttr:=$70;
     IF patterns[partitura[actualpattern]]^[J,LineaBase+I].Nota>=100 THEN Write(#27,'   ')
                                   ELSE Write('    ');
    END;
   ClrEol;
   WriteLn;clreol;
  END;
 EsperaBarrido;
 GotoXY(1,50);
 TextAttr:=$1E;
 Write(' ³ Escala : ',Escala,'³ Tempo :',Tempo:2,'³ Incremento : ',
 ADD:2,' ³ P gina:',Actualpattern:3,#32#31#30'³Pattern:',
  Partitura[ActualPattern]:3,#32#31#30#32'³[',LastPattern:3,']');
 ClrEol;
 TextAttr:=$70;
 Punteroon;
END;

PROCEDURE Help;
BEGIN
 punterooff;
 Pant.Salvar;
 TextAttr:=$30;
 HacerCaja(1,3,80,47,CaracGraf);
 GotoXy(1,3);
 Centre('Ayuda');
 Window(2,4,79,48);
 ClrScr;
 Window(2,4,79,48);
 WriteLn;
 WriteLn('Z /  .     --> Teclado (piano), escala activa.');
 WriteLn('A /  ¥     --> Teclado (piano), escala activa, sostenidos.');
 WriteLn('Q / P     --> Teclado (piano), escala siguiente.');
 WriteLn('1 / 0     --> teclado (piano), escala siguiente, sostenidos.');
 WriteLn;
 WriteLn('Alt+I    --> Indicar instrumento de canal bajo el cursor');
 WriteLn('+ -      --> Cambia escala por defecto');
 WriteLn('* /      --> Cambia incremento (lo que avanza el cursor)');
 WriteLn('[ ]      --> Baja/sube tempo (cuanto m s alto m s lento)');
 WriteLn('ESPACIO  --> Silencio');
 WriteLn('Alt+X    --> Ruptura de pattern: quitar/poner.');
 WriteLn('CTRL+DEL --> Elimina l¡nea en los 9 canales');
 WriteLn('Insert   --> Insertar espacio para nota');
 WriteLn('F10      --> Inserta espacio para nota en los 9 canales');
 WriteLn('Supr     --> Elimina nota y sube las anteriores');
 WriteLn('Ctrl-AvPg--> Pasar p gina adelante');
 WriteLn('Ctrl-RePg--> Pasar p gina atr s');
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLn('Ordenes de Bloque:');
 WriteLn;
 WriteLn('Alt-B   --> Marca bloque, usar dos veces sobre el mismo canal');
 WriteLn('Alt-C   --> Copia bloque, machaca lo que haya debajo de destino');
 WriteLn('Alt-D   --> Borra bloque');
 WriteLn('Alt-U   --> Quita marca');
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLn('Use cursores, AvPg/RePg, Inicio y Fin para moverse');
 WriteLn;
 WriteLn;
 WriteLn('Bajo la l¡nea roja est n los n£meros de canal seguidos, tras el ');
 WriteLn('gui¢n, del instrumento usado para ese canal.');
 WriteLn('En cada nota la letra indica el tono, ''#'' indica sostenido, y el');
 WriteLn('n£mero indica la escala en que se tocar .');
 WriteLn('No podr  tocar notas en un canal si no hay definido un instrumento');
 WriteLn('para ‚l. No DEBE dejar canales vacios (sin instrumento) intermedios.');
 ReadKey;
 TextAttr:=$70;
 Window(1,1,80,50);
 Pant.Recuperar;
 punteroon;
END;

PROCEDURE GRABAR;
VAR S:String;
    F:FILE;
    I:Word;
BEGIN
 punterooff;
 Pant.Salvar;
 TextAttr:=$1f;
 HacerCaja(1,11,80,8,CaracGraf);
 GotoXY(1,11);
 Centre('Grabar');
 Window(2,12,79,17);
 ClrScr;
 WriteLn;
 Write(' Teclee el nombre del fichero [.SBP] :');
 ReadLn(S);IF Pos('.',S)=0 THEN S:=S+'.SBP';
 Assign(F,S);
 {$I-}
 Reset(F,1);
 {$I+}
 IF IOResult=0 THEN BEGIN
                     Close(F);
                     WriteLn(' Atenci¢n : Fichero existe. ¨ Sobreescribir ?');
                     IF UpCase(ReadKey)<>'S' THEN
                      BEGIN
                       Window(1,1,80,50);
                       TextAttr:=$70;
                       Pant.Recuperar;
                       Punteroon;
                       Exit;
                      END;
                    END;
 {$I-}
 Rewrite(F,1);
 {$I+}
 IF IOResult<>0 THEN BEGIN
                      WriteLn(' Imposible crear fichero. Pulse una tecla.');
                      ReadKey;
                      Window(1,1,80,50);
                      TextAttr:=$70;
                      Pant.Recuperar;
                      punteroon;
                      Exit;
                     END;
 WriteLn(' Grabando...');
 BlockWrite(F,Partitura,SizeOf(partitura));
 BlockWrite(F,Inst,SizeOf(Inst));
 BlockWrite(F,Tempo,1);
 BlockWrite(F,Escala,1);
 BlockWrite(F,LastPattern,1);
 FOR I:=1 TO 255 DO IF Patterns[I]<>NIL THEN BlockWrite(F,Patterns[I]^,SizeOf(pattern));
 Close(F);
 ActualPattern:=0;
 TextAttr:=$70;
 Window(1,1,80,50);
 Pant.Recuperar;
 punteroon;
END;

PROCEDURE CARGAR;
VAR S:String;
    F:FILE;
    I:WorD;
BEGIN
 Punterooff;
 Pant.Salvar;
 TextAttr:=$1f;
 HacerCaja(1,11,80,8,CaracGraf);
 GotoXY(1,11);
 Centre('Cargar');
 Window(2,12,79,17);
 ClrScr;
 WriteLn;
 Write(' Teclee el nombre del fichero [.SBP] :');
 ReadLn(S);IF Pos('.',S)=0 THEN S:=S+'.SBP';
 {$I-}
 Assign(F,S);
 Reset(F,1);
 {$I+}
 IF IOResult<>0 THEN BEGIN
                      WriteLn(' Imposible abrir fichero. Pulse una tecla.');
                      ReadKey;
                      Window(1,1,80,50);
                      TextAttr:=$70;
                      Pant.Recuperar;
                      Punteroon;
                      Exit;
                     END;
 WriteLn(' Cargando...');
 Blockread(F,Partitura,SizeOf(partitura));
 BlockRead(F,Inst,SizeOf(Inst));
 BlockRead(F,Tempo,1);
 BlockRead(F,Escala,1);
 BlockRead(F,LastPattern,1);
 I:=1;
 WHILE NOT EOF(F) DO
  BEGIN
   IF Patterns[I]=NIL THEN GetMem(Patterns[I],SizeOf(pattern));
   BlockRead(F,Patterns[I]^,Sizeof(Pattern));
   INC(I);
  END;
 Close(F);
 WHILE I<256 DO BEGIN
                 IF Patterns[I]<>NIL THEN BEGIN
                                           FreeMem(Patterns[I],SizeOf(Patterns));
                                           Patterns[I]:=NIL;
                                          END;
                 INC(I);
                END;
 TextAttr:=$70;
 ActualPattern:=0;
 CX:=1;
 CY:=1;
 Window(1,1,80,50);
 Pant.Recuperar;
 punteroon;
END;

PROCEDURE Salir;
BEGIN
 Punterooff;
 Pant.Salvar;
 TextAttr:=$1f;
 HacerCaja(1,11,80,8,CaracGraf);
 GotoXY(1,11);
 Centre('Salir al DOS ');
 Window(2,12,79,17);
 ClrScr;
 WriteLn;
 WriteLn;
 Write('              ¨ Esta seguro de querer salir al DOS ? (S/N)');
 IF Upcase(ReadKey)='S' THEN BEGIN
                              TextAttr:=$07;
                              Window(1,1,80,50);
                              Clrscr;
                              CursorOn;
                              IF AdlibPresent THEN FOR I:=1 TO 9 DO NoteOff(I);
                              TextMode(mode);
                              Halt
                             END;
 TextAttr:=$70;
 Window(1,1,80,50);
 Pant.Recuperar;
 Punteroon;
END;

FUNCTION SAVESBM(S:String):Boolean;
TYPE HEADER = RECORD
               Identificador:ARRAy[0..2] OF Char;
               Instrumento:ARRAy[1..9] OF Byte;
               Posicion:ARRAY[1..9] OF LongInt;
              END;

CONST H:Header=(Identificador:('S','B','M'));
VAR F:FILE;
    I,J:Word;
    NO:Note;
    Dur:LongInt;
    Duracion:Word;

PROCEDURE WriteNote;
VAR MaxDur:Word;
BEGIN
 IF NO.Nota=12 THEN DEC(NO.Escala);
 MaxDur:=(65500 DIV (100*TEMPO))*100*TEMPO;
 WHILE Dur>=MaxDur DO
  BEGIN
   Duracion:=MaxDur;
   BlockWrite(F,Duracion,2);
   BlockWrite(F,NO,2);
   Dec(Dur,MaxDur);
  END;
 IF Dur>0 THEN BEGIN
                Duracion:=Dur;
                BlockWrite(F,Duracion,2);
                BlockWrite(F,NO,2)
               END;
END;


VAR ActPat:Word;
    AcabadoCanal:Boolean;
    P0:Byte;
    LastPat:Byte;

BEGIN
 P0:=0;
 lastPat:=LastPattern;
 IF PlayPattern IN [1,2] THEN P0:=ActualPattern;
 IF PlayPattern=1 THEN LastPat:=ActualPattern;
 SaveSBM:=True;
 Assign(F,S);
 Rewrite(F,1);
 Move(Inst,H.Instrumento,9);
 H.Identificador[0]:='S';
 H.Identificador[1]:='B';
 H.Identificador[2]:='M';
 BlockWrite(F,H,SizeOf(H));
 FOR J:=1 TO 9 DO
  IF H.Instrumento[J]<>0 THEN
  BEGIN
   Dur:=tempo*100;
   NO:=patterns[partitura[P0]]^[J,1];
   IF NO.NOta=13 THEN BEGIN
                       NO.Nota:=0;
                       NO.Escala:=128
                      END;
   H.Posicion[J]:=FilePos(F);
   ActPat:=P0;
   I:=2;
   AcabadoCanal:=False;
   WHILE NOT AcabadoCAnal DO
    BEGIN
     IF patterns[partitura[actpat]]^[J,I].Nota=13 THEN INC(Dur,100*tempo)
                  ELSE BEGIN
                        WriteNote;
                        No:=patterns[partitura[actpat]]^[J,I];
                        Dur:=100*Tempo;
                       END;
     INC(I);
     IF (patterns[partitura[actpat]]^[1,I].Nota>=100) OR (I=65) THEN
      BEGIN
       INC(ActPat);
       I:=1;
      END;
     IF ActPat>lastPat THEN AcabadoCAnal:=true;
    END;
   WriteNote;
  END;
 Close(F);
 Reset(F,1);
 BlockWrite(F,H,SizeOf(H));
 Close(F);
END;

FUNCTION DOSALA(N:Word):Word;
BEGIN
 IF N=0 THEN DOSALA:=1
        ELSE DOSALA:=2*DOSALA(N-1)
END;

FUNCTION SB2PC(No:Note):Word;
CONST FREQTABLE:ARRAY[1..14] OF Word=
 (69,73,78,82,87,93,98,104,110,117,124,65,00,65535);
VAR D:Word;
BEGIN
D:=FREQTABLE[No.Nota];
IF No.Nota<12 THEN D:=D*DOSALA(No.ESCALA-1);
IF No.nota=12 THEN D:=D*DOSALA(No.Escala-1);

SB2PC:=D
END;



FUNCTION SAVESND(S:String):Boolean;
VAR F:FILE;
    I,J:Word;
    NO:Note;
    Dur:LongInt;
    Duracion:Word;

PROCEDURE WriteNoteSND;
VAR MaxDur:Word;
    Freq:Word;
BEGIN
 MaxDur:=(65500 DIV (100*TEMPO))*100*TEMPO;
 WHILE Dur>=MaxDur DO
  BEGIN
   Duracion:=MaxDur;
   BlockWrite(F,Duracion,2);
   Freq:=SB2PC(NO);
   BlockWrite(F,Freq,2);
   Dec(Dur,MaxDur);
  END;
 IF Dur>0 THEN BEGIN
                Duracion:=Dur;
                BlockWrite(F,Duracion,2);
                Freq:=SB2PC(NO);
                BlockWrite(F,Freq,2)
               END;
END;


var acabado:boolean;
    actpat:word;

BEGIN
 SaveSND:=True;
 Assign(F,S);
 Rewrite(F,1);
 Dur:=tempo*100;
 NO:=patterns[partitura[0]]^[1,1];
 I:=2;
 actpat:=0;
 Acabado:=False;
 WHILE NOT Acabado DO
   BEGIN
    IF patterns[partitura[actpat]]^[1,I].Nota=13 THEN INC(Dur,100*tempo)
                 ELSE BEGIN
                       WriteNoteSND;
                       No:=patterns[partitura[actpat]]^[1,I];
                       Dur:=100*Tempo;
                      END;
     INC(I);
     IF (patterns[partitura[actpat]]^[1,I].Nota>=100) OR (I=65) THEN
      BEGIN
       INC(ActPat);
       I:=1;
      END;
     IF ActPat>lastPattern THEN Acabado:=true;
   END;
  WriteNoteSND;
 Close(F);
END;


PROCEDURE TOCAR;
VAR F:File;
    I:Byte;
           Instr:InstType;
BEGIN
 PlayPattern:=2;
 Pant.Salvar;
 IF SaveSBM('ADV\STEMP.SBM') THEN BEGIN
                                   SetOutPut('NUL');
                                   FOR I:=1 TO 9 DO IF AdlibPresent
                                    THEN IF NotaAct[I] THEN NoteOff(I);
                                   FillChar(NotaAct,9,0);
                                   GotoXY(1,50);
                                   TExtattr:=$1F;
                                   Write(' Tocando melod¡a. Pulse una tecla para interrumpir.');Clreol;
                                   EXEC('PLAYSB.EXE','STEMP CSG');
                                   textAttr:=$70;
                                   CursorOff;
                                   Assign(F,'ADV\STEMP.SBM');
                                   Erase(F);
                                   CancelOutput;
                                   Assign(F,'ADV\SBLASTER.DRV');
                                   Reset(F,1);
                                   Silence;
                                   FOR I:=1 TO 9 DO IF Inst[I]<>0
                                    THEN BEGIN
                                          Seek(F,1024+(Inst[I]-1)*16);
                                          BlockRead(F,Instr,16);
                                          Noteoff(I);
                                          LoadInstrument(I,Instr);
                                         END;
                                   Close(F);
                                  END;
 Pant.Recuperar;
END;

PROCEDURE TOCARPattern;
VAR F:File;
    I:Byte;
           Instr:InstType;
BEGIN
 PlayPattern:=1;
 Pant.Salvar;
 IF SaveSBM('ADV\STEMP.SBM') THEN BEGIN
                                   SetOutPut('NUL');
                                   FOR I:=1 TO 9 DO IF AdlibPresent
                                    THEN IF NotaAct[I] THEN NoteOff(I);
                                   FillChar(NotaAct,9,0);
                                   TExtattr:=$1F;
                                   GotoXY(1,50);
                                   Write(' Tocando pattern. Pulse una tecla para interrumpir.');Clreol;
                                   EXEC('PLAYSB.EXE','STEMP CSG');
                                   textAttr:=$70;
                                   CursorOff;
                                   Assign(F,'ADV\STEMP.SBM');
                                   Erase(F);
                                   CancelOutput;
                                   Assign(F,'ADV\SBLASTER.DRV');
                                   Reset(F,1);
                                   Silence;
                                   FOR I:=1 TO 9 DO IF Inst[I]<>0
                                    THEN BEGIN
                                          Seek(F,1024+(Inst[I]-1)*16);
                                          BlockRead(F,Instr,16);
                                          Noteoff(I);
                                          LoadInstrument(I,Instr);
                                         END;
                                   Close(F);
                                  END;
 Pant.Recuperar;
END;


PROCEDURE TOCARPC;
VAR F:File;
BEGIN
 Pant.Salvar;
 IF SaveSND('ADV\STEMP.SND') THEN BEGIN
                                   SetOutPut('NUL');
                                   FOR I:=1 TO 9 DO IF AdlibPresent
                                    THEN IF NotaAct[I] THEN NoteOff(I);
                                   FillChar(NotaAct,9,0);
                                   EXEC('PLAY.EXE','STEMP');
                                   CursorOff;
                                   Assign(F,'ADV\STEMP.SND');
                                   Erase(F);
                                   CancelOutput;
                                  END;
 Pant.Recuperar;
END;

PROCEDURE GRABARSBM;
VAR S:String;
    F:File;
BEGIN
 PlayPattern:=0;
 PunteroOff;
 Pant.Salvar;
 TextAttr:=$1f;
 HacerCaja(1,11,80,8,CaracGraf);
 GotoXY(1,11);
 Centre('Grabar SBM');
 Window(2,12,79,17);
 ClrScr;
 WriteLn;
 Write(' Teclee el nombre del fichero [.SBM] :');
 ReadLn(S);IF Pos('.',S)=0 THEN S:='adv\'+S+'.SBM';
 Assign(F,S);
 {$I-}
 Reset(F,1);
 {$I+}
 IF IOResult=0 THEN BEGIN
                     Close(F);
                     WriteLn(' Atenci¢n : Fichero existe. ¨ Sobreescribir ?');
                     IF UpCase(ReadKey)<>'S' THEN
                      BEGIN
                       Window(1,1,80,50);
                       TextAttr:=$70;
                       Pant.Recuperar;
                       Exit;
                      END;
                    END;
 {$I-}
 Rewrite(F,1);
 {$I+}
 IF IOResult<>0 THEN BEGIN
                      WriteLn(' Imposible crear fichero. Pulse una tecla.');
                      ReadKey;
                      Window(1,1,80,50);
                      TextAttr:=$70;
                      Pant.Recuperar;
                      Exit;
                     END;
 WriteLn(' Grabando...');
 Close(F);
 SaveSBM(S);
 TextAttr:=$70;
 Window(1,1,80,50);
 Pant.Recuperar;
 Punteroon;
END;


PROCEDURE GRABARSND;
VAR S:String;
    F:File;
BEGIN
 Punterooff;
 Pant.Salvar;
 TextAttr:=$1f;
 HacerCaja(1,11,80,8,CaracGraf);
 GotoXY(1,11);
 Centre('Grabar SND');
 Window(2,12,79,17);
 ClrScr;
 WriteLn;
 Write(' Teclee el nombre del fichero [.SND] :');
 ReadLn(S);IF Pos('.',S)=0 THEN S:='adv\'+S+'.SND';
 Assign(F,S);
 {$I-}
 Reset(F,1);
 {$I+}
 IF IOResult=0 THEN BEGIN
                     Close(F);
                     WriteLn(' Atenci¢n : Fichero existe. ¨ Sobreescribir ?');
                     IF UpCase(ReadKey)<>'S' THEN
                      BEGIN
                       Window(1,1,80,50);
                       TextAttr:=$70;
                       Pant.Recuperar;
                       Exit;
                      END;
                    END;
 {$I-}
 Rewrite(F,1);
 {$I+}
 IF IOResult<>0 THEN BEGIN
                      WriteLn(' Imposible crear fichero. Pulse una tecla.');
                      ReadKey;
                      Window(1,1,80,50);
                      TextAttr:=$70;
                      Pant.Recuperar;
                      Exit;
                     END;
 WriteLn(' Grabando...');
 Close(F);
 SaveSND(S);
 TextAttr:=$70;
 Window(1,1,80,50);
 Pant.Recuperar;
 Punteroon;
END;



PROCEDURE INSTRUMENTO;
VAR S:String;
    F:FILE;
    Instr:InstType;
BEGIN
 PunteroOff;
 Pant.Salvar;
 TextAttr:=$1f;
 HacerCaja(1,11,80,8,CaracGraf);
 GotoXY(1,11);
 Centre('Cambiar Instrumento');
 Window(2,12,79,17);
 ClrScr;
 WriteLn;
 WriteLn;
      REPEAT
       GotoXY(1,2);
       Write(' Teclee instrumento para canal ',CX,' : ');ClrEol;
       ReadLn(Stri);
       VAL(Stri,Inst[CX],code);
      UNTIL (Code=0) AND (Inst[CX]<=MaxInst);
 TextAttr:=$70;
 Window(1,1,80,50);
 Pant.Recuperar;mostrar;
 Assign(F,'ADV\SBLASTER.DRV');
 Reset(F,1);
 Seek(F,1024+(Inst[CX]-1)*16);
 BlockRead(F,Instr,16);
 Close(F);
 IF AdlibPresent THEN LoadInstrument(CX,Instr);
 PunteroOn;
END;

PROCEDURE Swap(VAR A,B:Word);
VAR Aux:Word;
BEGIN
 Aux:=A;
 A:=B;
 B:=Aux
END;

PROCEDURE Note_(C:Char;VAR Nota,Escala:ShortInt);
BEGIN
 CASE C OF
  'Z':BEGIN
       Escala:=-1;
       Nota:=12;
      END;
  'S':BEGIN
       Escala:=0;
       Nota:=1;
      END;
  'X':BEGIN
       Escala:=0;
       Nota:=2;
      END;
  'D':BEGIN
       Escala:=0;
       Nota:=3;
      END;
  'C':BEGIN
       Escala:=0;
       Nota:=4;
      END;
  'V':BEGIN
       Escala:=0;
       Nota:=5;
      END;
  'G':BEGIN
       Escala:=0;
       Nota:=6;
      END;
  'B':BEGIN
       Escala:=0;
       Nota:=7;
      END;
  'H':BEGIN
       Escala:=0;
       Nota:=8;
      END;
  'N':BEGIN
       Escala:=0;
       Nota:=9;
      END;
  'J':BEGIN
       Escala:=0;
       Nota:=10;
      END;
  'M':BEGIN
       Escala:=0;
       Nota:=11;
      END;
  ',':BEGIN
       Escala:=0;
       Nota:=12;
      END;
  'L':BEGIN
       Escala:=1;
       Nota:=1;
      END;
  '.':BEGIN
       Escala:=1;
       Nota:=2;
      END;
  '¥','¤':BEGIN
       Escala:=1;
       Nota:=3;
      END;
  'Q':BEGIN
       Escala:=0;
       Nota:=12;
      END;
  '2':BEGIN
       Escala:=1;
       Nota:=1;
      END;
  'W':BEGIN
       Escala:=1;
       Nota:=2;
      END;
  '3':BEGIN
       Escala:=1;
       Nota:=3;
      END;
  'E':BEGIN
       Escala:=1;
       Nota:=4;
      END;
  'R':BEGIN
       Escala:=1;
       Nota:=5;
      END;
  '5':BEGIN
       Escala:=1;
       Nota:=6;
      END;
  'T':BEGIN
       Escala:=1;
       Nota:=7;
      END;
  '6':BEGIN
       Escala:=1;
       Nota:=8;
      END;
  'Y':BEGIN
       Escala:=1;
       Nota:=9;
      END;
  '7':BEGIN
       Escala:=1;
       Nota:=10;
      END;
  'U':BEGIN
       Escala:=1;
       Nota:=11;
      END;
  'I':BEGIN
       Escala:=1;
       Nota:=12;
      END;
  '9':BEGIN
       Escala:=2;
       Nota:=1;
      END;
  'O':BEGIN
       Escala:=2;
       Nota:=2;
      END;
  '0':BEGIN
       Escala:=2;
       Nota:=3;
      END;
  'P':BEGIN
       Escala:=2;
       Nota:=4;
      END
  ELSE NOTA:=110;
 END;
END;




PROCEDURE PasaLinea;
BEGIN
 INC(CY,Add);
 IF CY>MaxLin THEN CY:=MaxLin;
 IF CY-LineaBase>19+25 THEN LineaBase:=CY-19-25
END;

PROCEDURE SueltaRaton;
VAR X,Y:Word;
    I,D,c:Boolean;
BEGIN
 REPEAT
  Leerraton(X,Y,I,c,D)
 UNTIL NOT (I OR D);
END;

PROCEDURE Esc(S1,S2:String);
BEGIN
 TextAttr:=$4f;
 IF S1[1]<>'1' THEN Write('³');
 TextAttr:=$4e;
 IF S1[1] IN ['0'..'9'] THEN Write('F',S1)
                        ELSE Write(S1);

 TextAttr:=$4f;
 Write(S2)
END;

var x,y:word;iz,ce,de:boolean;
label sigue;
BEGIN (*PRINCIPAL*)
FillChar(NotaAct,9,0);
ASM
  mov bl,30h
  MOV AX,1802h
  int 10h
END; (* 25 l¡neas *)
 FillChar(Patterns,SizeOf(Patterns),0); (* NILs *)
 ActualPattern:=0;
 Partitura[0]:=1;
 GetMem(Patterns[1],SizeOf(Pattern));
 FillChar(Patterns[1]^,SizeoF(pattern),13);
 (* BUSQUEDA DEL ULTIMO INSTRUMENTO *)
 Assign(F,'ADV\SBLASTER.DRV');
 Reset(F,1);
 MaxInst:=(Filesize(F)-1024) DIV 16;
 Close(F);
 (* HASTA AQUI BUSQUEDA *)
 TextAttr:=0;
 FillChar(Inst,9,0);
 Pant.Inicializar(80,50);
 Tempo:=1;
 Add:=1;
 FillChar(P,SizeOf(P),13);
 LineaBase:=1;
 FillChar(Bloque,SizeOf(Bloque),0);
 CY:=1;
 CX:=1;
 ClrScr;
 mode:=lastmode;
 TextMode(C80+Font8x8);
 ResetRaton;
 RangoFila(399,1);
 TextAttr:=$1F;
 Write('                       COMPOSITOR DE FICHEROS SBM   (C) 1994 v2.0');ClrEol;WriteLn;
 TextAttr:=$4E;
 Esc('1','Ayuda');
 Esc('2','Grabar');
 Esc('3','Cargar');
 Esc('4','Tocar');
 Esc('Alt-F4','Pattern');
 Esc('5','Gr. SBM');
 Esc('6','Gr. SND');
 Esc('9','Tocar SND ');
 TextAttr:=$70;
 WriteLn;
 Escala:=1;
 CursorOff;
 Mostrar;
 PunteroOn;
 REPEAT
  iz:=False;
  LeerRaton(X,Y,iz,ce,de);
  X:=X DIV 8;
  Y:=Y DIV 8;
  IF Tomatecla(Ch,Ext,Exp,Camb)  OR iz THEN
   BEGIN
    IF iz THEN BeGIN
                Exp:=0;
                Ext:=False;
                Ch:=#0;
                IF Y=1 THEN BEGIN
                             Ext:=true;
                             CASE X OF
                              0..6:Exp:=59;
                              8..15:Exp:=60;
                              17..24:Exp:=61;
                              26..32:Exp:=62;
                              34..46:Exp:=107;
                              48..56:Exp:=63;
                              58..66:exp:=64;
                              68..78:exp:=67;
                             END
                            END;
                IF (Y>=3) AND (Y<49) THEN BEGIN
                                            CY:=LineaBase+Y-3;
                                            CX:=(X-6) DIV 8+1;
                                            IF CX=0 THEN CX:=1;
                                            IF CX>9 THEN CX:=9;
                                           END;
                IF (X=55) AND (y=49) THEN BEGIN
                                           Ext:=True;
                                           Exp:=118;
                                           CX:=1;
                                           CY:=1;
                                           SueltaRaton;
                                          END;
                IF (X=56) AND (y=49) THEN BEGIN
                                           CX:=1;
                                           CY:=1;
                                           Ext:=True;
                                           Exp:=132;
                                           SueltaRaton;
                                          END;
                IF (X=70) AND (y=49) THEN IF Partitura[ActualPattern]<>255 THEN
                                            BEGIN
                                             INC(Partitura[ActualPattern]);
                                           IF Patterns[Partitura[ActualPattern]]=NIL THEN
                                            BEGIN
                                             GetMem(Patterns[Partitura[ActualPattern]],SizeOf(pattern));
                                             FillChar(Patterns[Partitura[ActualPattern]]^,SizeOf(pattern),13);
                                            END;
                                           CX:=1;
                                           CY:=1;
                                           SueltaRaton;
                                          END;

                IF (X=71) AND (y=49) THEN
                 IF Partitura[ActualPattern]<>1 THEN
                 BEGIN
                  DEC(Partitura[ActualPattern]);
                  CX:=1;
                  CY:=1;
                  SueltaRaton;
                 END;
                IF (X>=75) AND (x<=77) AND (y=49) THEN
                 BEGIN
                  PunteroOff;
                  GotoXY(76,50);
                  TextAttr:=$1e;
                  StrAux:='';
                  ReadLn2(StrAux,3);
                  VAL(StrAux,Aux,Code);
                  CursorOff;
                  IF (Code=0) AND (Partitura[Aux]<>0) THEN LastPattern:=Aux
                                                       ELSE Beep;
                  TextAttr:=$70;
                  Punteroon;
                 END;

                 if (x=0) and (y=0) then begin
                                          sueltaraton;
                                          salir
                                         end;




               END;

    IF (Ext AND (Exp=118)) AND (ActualPattern<>255) THEN BEGIN
                               Inc(ActualPattern);
                               IF Partitura[ActualPattern]=0 THEN
                                 Partitura[ActualPattern]:=Partitura[ActualPattern-1];
                               IF LastPattern<ActualPattern THEN LastPattern:=ActualPattern;
                             END;

    IF (Ext AND (Exp=132)) AND (ActualPattern<>0) THEN DEC(ActualPattern);

    IF Ext AND (Exp=77) THEN IF CX<9 THEN INC(CX);
    IF Ext AND (Exp=75) THEN IF CX>1 THEN DEC(CX);
    IF Ext AND (Exp=72) THEN IF CY>1 THEN BEGIN
                                           DEC(CY);
                                           IF CY<LineaBase THEN LineaBase:=CY
                                          END;
    IF Ext AND (Exp=80) THEN IF CY<Maxlin THEN BEGIN
                                              INC(CY);
                                              IF CY>LineaBase+19+25 THEN Inc(LineaBase)
                                              END;
    IF Ext AND (Exp=59) THEN Help;
    IF Ext AND (Exp=60) THEN Grabar;
    IF Ext AND (Exp=61) THEN Cargar;
    IF Ext AND (Exp=62) THEN Tocar;
    IF Ext AND (Exp=107) THEN IF AdlibPresent THEN TocarPattern
                                              ELSE Beep;
    IF Ext AND (Exp=63) THEN GrabarSBM;
    IF Ext AND (Exp=64) THEN GrabarSND;
    IF Ext AND (Exp=67) THEN TocarPC;
    IF Ext AND (Exp=23) THEN INSTRUMENTO;
    IF (Ch=#27) THEN Salir;
    IF (Upcase(Ch) IN  ['Z','X','C','V','B','N','M',',','.','S','D','G',
                        'H','J','L','¥','¤','Q','W','E','R','T','Y','U',
                        'I','O','P','2','3','5','6','7','9','0']) AND
                         (Inst[CX]<>0) THEN
                         BEGIN
                              Note_(Upcase(ch),nota_,escala_);
                              NotaAct[CX]:=False;
                              IF AdlibPresent THEN Noteoff(CX);
                              IF AdlibPresent THEN NoteOn(CX,escala+escala_,nota_);
                              IF Nota_=12 THEN INC(escala_);
                              IF patterns[partitura[actualpattern]]^[CX,CY].Nota>=100 THEN Inc(Nota_,100);
                              patterns[partitura[actualpattern]]^[CX,CY].Escala:=Escala+escala_;
                              patterns[partitura[actualpattern]]^[CX,CY].Nota:=Nota_;
                              PasaLinea;
                              Sigue:
                             END;
    If Ch=' ' THEN IF Inst[CX]<>0 THEN BEGIN
                    IF patterns[partitura[actualpattern]]^[CX,CY].Nota>=100 THEN
                     patterns[partitura[actualpattern]]^[CX,CY].Nota:=114
                                          ELSE patterns[partitura[actualpattern]]^[CX,CY].Nota:=14;
                    IF NotaAct[CX] THEN IF AdlibPresent  THEN NoteOff(CX);
                    NotaAct[CX]:=False;
                    PasaLinea
                   END;
    IF Ext AND (Exp=83) THEN BEGIN
                              IF patterns[partitura[actualpattern]]^[CX,CY].nota<100 THEN
                                patterns[partitura[actualpattern]]^[CX,CY].Nota:=13
                                              ELSE patterns[partitura[actualpattern]]^[CX,CY].Nota:=113;
                              IF NotaAct[CX] THEN IF AdlibPresent  THEN NoteOff(CX);
                              NotaAct[CX]:=False;
                              PasaLinea
                             END;
    IF (Ch='[') AND (Tempo>1) THEN DEC(tempo);
    IF (Ch=']') THEN IF Tempo<99 THEN INC(tempo);
    IF (Ch='+') THEN IF (Escala<5) THEN Inc(Escala);
    IF (Ch='-') THEN IF (Escala>0) THEN Dec(Escala);
    IF (Ch='*') THEN IF (add<12) THEN Inc(add);
    IF (Ch='/') THEN IF (add>1) THEN Dec(add);
    IF (Ch='§') OR (Ext AND (Exp=45)) AND (cx=1) THEN
     IF patterns[partitura[actualpattern]]^[1,cy].Nota<100 THEN
     INC(patterns[partitura[actualpattern]]^[1,CY].Nota,100)
      ELSE  DEC(patterns[partitura[actualpattern]]^[1,CY].Nota,100);
    IF Ch=#127 THEN FOR J:=1 TO 9 DO
                     BEGIN
                      Move(patterns[partitura[actualpattern]]^[J,CY+1],
                       patterns[partitura[actualpattern]]^[J,CY],2*(MaxLin-CY));
                      FillChar(patterns[partitura[actualpattern]]^[J,MaxLin],2,13);
                     END;
    IF Ch=#8 THEN BEGIN
                   Move(patterns[partitura[actualpattern]]^[CX,CY+1],patterns[partitura[actualpattern]]^[CX,CY],2*(MaxLin-CY));
                   FillChar(patterns[partitura[actualpattern]]^[CX,MaxLin],2,13);
                  END;
    IF Ext AND (Exp=82) THEN
                             BEGIN
                              Move(patterns[partitura[actualpattern]]^[CX,CY],
                               patterns[partitura[actualpattern]]^[CX,CY+1],2*(MaxLin-CY));
                              FillChar(patterns[partitura[actualpattern]]^[CX,CY],2,13);
                              PasaLinea;
                             END;
   IF ext AND (Exp=68) THEN
                        FOR J:=1 TO 9 DO
                         BEGIN
                          Move(patterns[partitura[actualpattern]]^[J,CY],
                           patterns[partitura[actualpattern]]^[J,CY+1],2*(MaxLin-CY));
                          FillChar(patterns[partitura[actualpattern]]^[J,CY],2,13);
                         END;
    IF Ext AND (Exp=79) THEN CX:=9;
    IF Ext AND (Exp=71) THEN CX:=1;
    IF Ext AND (Exp=81) THEN BEGIN
                              INC(CY,20);
                              IF CY>MaxLin THEN CY:=MaxLin;
                              IF CY-LineaBase>19+25 THEN LineaBase:=CY-19-25
                             END;
    IF Ext AND (Exp=73) THEN BEGIN
                              IF CY>20 THEN DEC(CY,20) ELSE CY:=1;
                              IF CY<LineaBase THEN LineaBase:=CY
                             END;
    IF Ext AND (Exp=48) THEN BEGIN
                              IF Bloque.Inicio=0 THEN BEGIN
                                                       Bloque.Inicio:=CY;
                                                       Bloque.Canal:=CX;
                                                       Bloque.Pattern:=Partitura[ActualPattern];
                                                      END
                                                 ELSE IF CX=Bloque.Canal THEN BEGIN
                                                                          Bloque.Fin:=CY;
                                                                          IF Bloque.Fin<Bloque.Inicio THEN
                                                                           Swap(Bloque.Inicio,Bloque.Fin);
                                                                         END


                             END;
   IF Ext AND (Exp=22) THEN FillChar(Bloque,SizeOf(bloque),0);

   IF Ext AND (Exp=46) AND (Bloque.FIn<>0) THEN (* Copy Block *)
    BEGIN
     LineasB:=Bloque.Fin-Bloque.Inicio+1;
     IF CY+LineasB-1<=MaxLin THEN Move(patterns[bloque.pattern]^[Bloque.Canal,Bloque.Inicio],
      patterns[partitura[actualpattern]]^[CX,CY],2*LineasB);
    END;

   IF Ext AND (Exp=32) AND (Bloque.FIn<>0) THEN (* Del Block *)
    BEGIN
     LineasB:=Bloque.Fin-Bloque.Inicio+1;
     FillChar(patterns[partitura[actualpattern]]^[Bloque.Canal,Bloque.Inicio],LineasB*2,13);
     Bloque.inicio:=0;
     Bloque.fin:=0;
    END;

   Mostrar;
  END;
 UNTIL FALSE
END.