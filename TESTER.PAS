PROGRAM TESTER5;

{$M 65000,0,655350}

{$X+,I-,B-,R-,S-,G+,N-,E-}

USES PARAMS, DOS, BITSET, SEGMENT2, DOUB386, NMPTW2, ADLIBLIB, MyCRT, PILACOLA,
     FASTPCX, EMUGRAPH, SFX2buf, CACHE, chips, keydisk, buscar, NMPVESA,
     LONGSTR, CDROM, errorlib;

(* ­­Atenci¢n!!! SEGMENT2 debe estar tras BITSET, tienen procs de igual nombre *)
(* DOS debe estar antes que CACHE, que incluye a PACKER *)

{$I DEBUGTYP.SRC}

VAR fadingFMOut,FadingFMIn:Boolean; (* Fade FM *)
    Savedir:String[128];

CONST
      WaitingMusic:Boolean=False;
      IsLongStr:Boolean=False;
      NumConj = 16;

TYPE ARRAYPANT=ARRAY[1..28006] OF Byte;
     String15=String[15];
     FUNC=ARRAY [1..9] OF String15;
     IK=ARRAY[0..31,0..31] OF Byte;
     Caracter=PACKED ARRAY[1..8,1..8] OF Byte; (*Rejilla de caracter*)
     CharSett=ARRAY [31..250] OF Caracter; (*Guarda juego de caracteres*)
     Conexiones=ARRAY [0..19] OF Byte;(*Almacena s¢lo las conexiones de una localidad*)

TYPE BYTEARRA=ARRAY[0..32000] OF Byte;
     CHARARRA=ARRAY[0..32000] OF char; (* DEbuggin*)


VAR SYSTIME:LongInt;
    GuardaFrase:String;
    AunHayMas:Boolean;  (* True si tras leerfrase a£n hay m s *)
    LowMem:Boolean;
    Clock:LongInt;
    COnections:ARRAY [0..255] OF ^Conexiones;
    TimeOutt:Boolean;
    RetardoPI:Word;
    INFORMACION:Boolean;
    STRINGS:ARRAY[Byte] OF ^String;

CONST NUMSTRING:Word=65535;

TYPE SCRR=ARRAy[0..63999] OF BYTE;

(* VARIABLES SONIDO GENERAL *)

VAR   ExistSB:Boolean;

(* VARIABLES SFX *)

VAR   (* Flag 0, bit 11,  1=SFX sonando; 0=Inactivo *)
      (* Flag 0, bit 10,  1=sample c¡clico, 0=sample normal *)
      (* SFXOFFSET es el flag 30, indica que posici¢n del sample se est  tocando *)
      SizeLastSFX:Word;
CONST LastSFX : Word=65535;

(* VARIABLES RELACIONADAS CON LA MUSICA *)

VAR Time : ARRAY [1..9] OF Word;         (*Retardo siguiente nota en PLAY*)

TYPE Header= RECORD  (* CABECERA FICHERO SBM *)
              ID: ARRAY[0..2] OF Char;
              Inst:ARRAY[1..9] OF Byte;
              Pos:ARRAY[1..9] OF Longint;
             END;

VAR SoundDAT:RECORD  (* Datos de los 9 canales, s¢lo el 1 se usa en modo Speaker *)
               Size:ARRAY[1..9] OF Word;
               Inicial,Actual:ARRAY[1..9] OF Pointer;
              END;
    Head:Header;

(* Flags 0, bit 12, si =1 est  sonando m£sica, si no no *)
CONST BufferMusic:Pointer=NIL;
      SizeLastMusic:Word=0;
      LastMusic:Word=65535;

VAR Doall:RECORD
           Activo:Boolean;
           Condacto:Pointer;
           Contenido,cont2,loc:Byte;
           Bucle:Word;
          END;
    Getico:ARRAY[1..4] OF ^Ik;
    TotalMem:LongInt;

    Recurse:Byte;
    I,J,K:Integer;                              (*Usos varios*)
    BREAK,DDone,Done,Desc,Endd,Desc2,Notdone:Boolean;       (*Variables de control en procesos*)
    PSize:LongInt;                              (*Sirve para calcular la memoria que ocupa la aventura*)
    SaveFrase:String[81];
    leidos:word;
    PRName:String[15];
    PRSRT:String[3];
    FPN:File;
    AUTO:BOOLEAN;
    AuxBool:Boolean;
CONST ModoTest:Boolean=False; (*Si estamos en modo TEST*)
VAR FL:Byte;   (*Apunta al flag activo en debugger*)
    Macro:Boolean;     (*Si debug activo*)
VAR MacroId:Word;
    Salvar:Pointer; (*ExitProc*) (*Resguarda el puntero de salida para procedimiento de salida*)
    FNT:Func;
    TimerCount:Word; (*Usada para decrementar el flag 11*)
    Conex:Conexiones;                 (*Guarda conexiones de loc. actual*)
    SaveXY:ARRAY[1..NumConj] OF RECORD
                                 X:Word;
                                 Y:Word;
                                END;(*Para Saveat y backat*)
    Timeout:longint;  (*Para retardo TimeOut*)
    (*  CharSet:Word;  (*N§ de juego de caracteres en curso*)
    Sett:CharSett;  (*Juego de caracteres en uso*)
    SP1:String[10];
    Cde:Integer;
    FAUX:FILE;

var Conj:ARRAY[1..NumConj] OF SET OF Byte;
    Pila:ARRAY[1..NumConj] OF TPila;
    Cola:ARRAY[1..NumConj] OF TCola;


PROCEDURE BlockRead(VAR F:FILE;VAR Buffer;Count:Word);
VAR Leidos:Word;
BEGIN
 Cache.BlockRead(F,Buffer,count,leidos);
 IF leidos<>count THEN Error(3);
END;

PROCEDURE NewText;
BEGIN
 GuardaFrase:='';
 AunhayMas:=False;
END;


FUNCTION SETSVGA:Boolean;
VAR T:FILE;
    AX_,BX_:Word;
    S:STRING;
BEGIN
 SETSVGA:=False;
 system.Assign(T,'SVGA.CFG');
 system.Reset(T,1);
 IF system.IOResult<>0 THEN BEGIN
                             SETVESAMODE($100,640);
                             Exit;
                            END;
 system.BlockRead(T,S,255);
 system.BlockRead(T,S,15);
 system.BlockRead(T,AX_,2);
 system.BlockRead(T,BX_,2);
 system.Close(T);
 BX_:=BX_ XOR $1971;
 AX_:=AX_ XOR $1971;
 IF BX_=0 THEN ASM
                MOV AX,AX_
                INT 10h
               END
          ELSE ASM
                MOV AX,BX_
                MOV BX,AX_
                INT 10h
               END;
 SETSVGA:=True;
END;

CONST MAXMODE=11;

VAR OffsJmp:WorD;
PROCEDURE VESAMODE(M:Word);
BEGIN
IF NOT IsVESA THEN Error(18)
                  ELSE IF NOT ValidMode(m) THEN Error(8)
                  ELSE CASE m of
                        $101:SETVESAMode($101,640);
                        $103:SETVESAMode($103,800);
                        $105:SETVESAMode($105,1024);
                       END;

END;

PROCEDURE SetMode(N:Byte);
VAR A,B:WorD;
BEGIN
 IF NOT (N IN [1..MaxMode]) THEN Exit;
 INIT256;
 GetAllPalette(Pall0);
 VideoMode:=1; (* para que funcione refresh *)
 Refresh;
 VideoMode:=N;
 Flags[27]:=N;
 CASE N OF
  2:Tweak320x200;
  3:TWEAK320x240;
  4:TWEAK320x400;
  5:TWEAK360x480;
  6:TWEAK376x282;
  7:TWEAK376x308;
  8:BEGIN
     SETSVGA;
     TWEAK640x400;
    END;
   9:VESAMODE($101);
  10:VESAMODE($103);
  11:VESAMODE($105);
 END;
END;

PROCEDURE BlockWrite(VAR F:FILE;VAR Buffer;Count:Word);
VAR Escritos:Word;
BEGIN
 System.BlockWrite(F,Buffer,Count,escritos);
 IF escritos<>count THEN Error(7);
END;

PROCEDURE GetMem(VAR P:Pointer;Size:Word);
 BEGIN
  IF MaxAvail>=Size THEN System.GetMem(P,Size)
                         ELSE
                         Error(2);
 END;

PROCEDURE PR_INPUT; Forward;



FUNCTION FUNCKEY:Byte;
VAR W:Word;

BEGIN
REPEAT
 IF BTST(Flags[0],4) THEN PR_INPUT;
 W:=GetKey
UNTIL W<>0;
FUNCKEY:=Hi(W);
END;

PROCEDURE HOTKEY;
(*Controla pulsaci¢n de tecla F10 para salida*)
BEGIN
IF Port[$60]=68 THEN Error(0);
END;

{$I DRV.SRC}
{$I PALABRAS.SRC}
{$I COMANDOS.SRC}


{$I TIMER}

{$F+}

PROCEDURE DeSalida;
(*Esto lo hace al salir del programa, sea por el final, Halt, o error de*)
(*ejecuci¢n*)
VAR J:Byte;
    F:FILE;
BEGIN
 ExitProc:=Salvar;
 IF BTST(Flags[10],1) THEN CDStop;
 CleanUpTimer;
 IF ExistSB THEN ReleaseSFX;
 IF BTST(Flags[0],5) THEN BEGIN
                           BCLR(Flags[0],12);
                           BCLR(Flags[0],11);
                           Silence;
                          END
                     ELSE BEGIN
                           BCLR(Flags[0],12);
                           Nosound;
                          END;
{ IF ISMSCDEX THEN PTrack(0,Flags[13]); (* Por si las moscas *)}
 IF NOT ErrorLocalizado THEN BEGIN
                              Refresh;
                              ASM
                               MOV AX,3
                               INT 10h
                              END;
                              IF ErrorAddr<>NIL THEN
                               BEGIN
                                WriteLn('NMP ',version,' : ERROR FATAL');
                                Write('Error ',ExitCode,' Direcci¢n de error:');
                                WriteLn(HEX(SEG(ErrorAddr^)),':',HEX(Ofs(ErrorAddr^)));
                                ErrorADdr:=NIL;
                               END;
                 IF ExitCode=255 THEN WriteLn('Se puls¢ Ctrl-Break.')
                                 ELSE BEGIN
                                       WriteLn('E/S :', IOResult,' DOS :', DosError);
                                       Write('SBMode : ',BTST(Flags[0],5),' ','ExistSB: ',EXistSB,' ');

                                       IF ExistSB THEN WriteLn('[',Hex(SB_Port),',',SB_IRQ,',',SB_DMA,']') ELSE WriteLn;
                                       WriteLn('DRIVER USUARIO : ',DRVPtr<>NIL,' CACHE:',CACHEON,' TAMA¥O: ',CACHESIZE);
                                       WriteLn('CACHE_ERROR:',CACHEBUG,' HANDLES:',NUMHANDLES,' CACHEFREE: ',CACHEFREE);
                                       WriteLn;
                                       FOR I:=0 TO NUMHANDLES-1 DO
                                        BEGIN
                                         Write(I:2,' ');
                                         IF FCB[I].Usada THEN Write('U') ELSE Write('N');
                                         Write(' ',FCB[I].FILENAME:13,'  ');
                                        END;
                                        IF WHereX<>1 THEN WriteLn;
                                        WriteLn('Por favor, informe de este error.');
                                       END;
                              ReadKey;
                             END;

 Assign(F,'NMSAVE.TMP');
 Erase(F);
 Nosound;
 VaciaCache;
END;


{$F-}

VAR Ver2,Nom2,Nom,Ver,pre,lo:Palabra;


PROCEDURE CLS;
BEGIN
 CASE VideoMode OF
  1:FillWord(Mem[$a000:0],32000,(Colors[0] SHL 8) OR Colors[0]);
  2..8:CLSTWeak(Colors[0]);
  9..11:Rectangle(0,0,logicwidth-1,scrheight,Colors[0]);
 END;
END;

{$I TABLAS.SRC} (*Tipo Proceso Procedimiento de Lectura de disco de Procesos *)
{$I OBJETOS.SRC} (*Tipo Objeto y Procedimiento de Lectura de disco de Objetos*)

{$I INT1.SRC}
{$I FLI.SRC}
{$I INT2.SRC} (*Bloques principales, ver el propio bloque*)




PROCEDURE NoPuedesHacerEso;
BEGIN
 NewText;
 Message(Nopuedesazar);
END;

PROCEDURE AYUDA;
BEGIN
 segment2.ayuda;
 Error(24);
END;

FUNCTION FINDMAX(N:String):LongInt;
VAR S:SearchRec;
    Max:LongInt;
    ST:String[12];
BEGIN
 Max:=0;
 St:='*.'+N;
 IF ISPACKED THEN BuscaPrimero(st);
 FindFirst('*.'+N,ANYFILE,S);
 WHILE ((DosError=0) AND NOT ISPACKED) OR ((St<>'') AND ISPACKED) DO
  BEGIN
   IF ISPACKED THEN S.Size:=buscar.getSize;
   IF S.Size>Max THEN Max:=S.Size;
   IF (S.Size>65535) AND (N<>'PCX') AND (N<>'TWK') THEN Error(14);
   IF ISPACKED THEN BuscaSiguiente(st) ELSE FindNext(S)
  END;
 FindMax:=Max;
 IF ISPACKED THEN ACABABUSQUEDA;
END;



PROCEDURE SoundCFG;
BEGIN
 ExistSB:=INITSFX;
 IF ExistSB THEN BEGIN
                  BSET(Flags[0],5);  (* SB SI *)
                  BSET(Flags[0],6);  (* SFX SI *)
                  BSET(Flags[0],9);  (* MUSICA SI *)
                  BCLR(Flags[0],14); (* NO ES ADLIB *)
                  IF NOT GetBlaster(SB_IRQ,SB_DMA) THEN Error(41);
                  InstallSFX(SB_Port,SB_IRQ,SB_DMA,@Flags[0]);
                 END ELSE
                 IF AdlibPresent THEN BEGIN
                                     BSET(Flags[0],5);  (* SB SI *)
                                     BCLR(Flags[0],6);  (* SFX NO *)
                                     BSET(Flags[0],9);  (* MUSICA SI *)
                                     BSET(Flags[0],14); (* ADLIB *)
                                    END ELSE
                 BEGIN
                  BSET(Flags[0],9); (* MUSICA SI *)
                  BCLR(Flags[0],5); (* NO SB *)
                 END;
 (* Detectada SOUNDBLASTER *)
END;


PROCEDURE PARAMETROS;
VAR I:Byte;
    S:String[1];
    J,K:Word;
    F:FILE;
BEGIN
 FOR I:=1 TO ParamCount DO
  IF ParamStr(I)='-lowmem' THEN LowMem:=True ELSE
  IF ParamStr(I)='-h' THEN KeyDiskOk:=true ELSE
  IF ParamStr(I)='-sfx' THEN BCLR(Flags[0],6) ELSE
  IF ParamStr(I)='-mus' THEN BCLR(Flags[0],9)
  ELSE IF ParamStr(I)='-s' THEN BEGIN
                                 BCLR(Flags[0],6);
                                 BCLR(Flags[0],9);
                                END
  ELSE IF ParamStr(I)='-pc' THEN BEGIN
                                  BCLR(Flags[0],6); (* NO SFX EN MODO PC *)
                                  BCLR(Flags[0],5);
                                 END
  {$IFDEF DEBUG_ON}
  ELSE IF paramStr(I)='CSG' THEN ModoTest:=True
  ELSE IF ParamStr(I)='GSC' THEN BEGIN
                                  ModoTest:=True;
                                  Debug:=true;
                                  Debug2:=true
                                 END
  {$ENDIF}
  ELSE IF Copy(ParamStr(I),1,5)='-dir=' THEN BEGIN
                                               Savedir:=Copy(ParamStr(i),6,255);
                                               IF Copy(Savedir,byte(Savedir[0]),1)<>'\' THEN Error(35);
                                               J:=0;
                                               FOR K:=1 TO Byte(Savedir[0]) DO IF Savedir[K]='\' THEN INC(J);
                                               IF J>2 THEN Error(35);
                                               IF Savedir[2]<>':' THEN Error(35);
                                               MakeSaveDir(Savedir);
                                               Assign(F,Savedir+'SAVEDIR.NMP');
                                               Rewrite(F);
                                               IF System.IOResult<>0 THEN Error(35)
                                                                     ELSE System.Close(F);
                                              END
  ELSE IF ParamStr(I)='-info' THEN INFORMACION:=True
  ELSE IF (ParamStr(I)='-cache') OR (ParamStr(I)='-cach‚') THEN cacheon:=false
                                  ELSE Ayuda;
END;


BEGIN  (*Principal*)
  PalColor0:=0;
  PalColorF:=255;
  GetDir(0,SaveDir);
  SaveDir:=SaveDir+'\';
  (* SETUP SEGUN CHIP *)
  IF CHIPTYPE<380 THEN Error(27);
  TotalMem:=MaxAvail;
  AunHayMas:=False;
  LowMem:=False;
  Informacion:=False;
  InitTalk;
  FillD(Flags,512,0);
  FillChar(Flags[18],5,255);
  Flags[29]:=1; (* VOLUMEN SFX *)
  Flags[0]:=$02FA;   (* Inicializo flags, el 0 con valores por defecto *)
  Flags[10]:=$0002; (* Iden para bitwise de flag 10 *)
  BSET(Flags[0],13);  (* melod¡as c¡clicas por defecto *)
  SOUNDCFG;
  FillChar(NotaAct,9,0);
  PARAMETROS;
  MakeSaveDir(SaveDir);
  SYSTime:=0;
  Refresco:=True;
  GuardaFrase:='';
  Doall.Activo:=False;
  Doall.Condacto:=NIL;
  FillD(STRINGS,SizeOf(STRINGS),0); (* NIL *)
  Assign(FAux,'F.DAT');
  Reset(Faux,1);
  IF IOResult<>0 THEN Error(4);
  BlockRead(FAux,Fnt,SizeOf(FNT));
  Close(FAux);
  InicializaDRV;
  FillD(GetIco, SizeOf(GetIco), 0);
  Recurse:=0;
  Macro:=False;
  SaveFrase:='';
  FL:=1;
  font:=1;
  CASE LoadFont('1') OF
   1:Error(22);
   2:Error(5);
  END;
  Assign(FAuX,'W.DAT');
  Reset(FAux,1);
  IF IOResult<>0 THEN Error(6);
  BlockRead(FAux,Win,Sizeof(Win));
  Close(FAux);
  FillWord(Time,9,1);
  Salvar:=ExitProc;           (*Guarda puntero de salida*)
  ExitProc:=@DeSalida;        (*Cambia puntero de salida*)
  TimerCount:=19;             (*Inicializa contador para decremento de flag 11*)
  TimerFreq:=19;
  SetTimer(@TimerHandler,19);
  ClrScr;
  CursorOff;
  LeerComandos;
  PSize:=MaxAvail;  (* Guarda memoria libre al empezar, sin contar comandos de DEBUG *)
  LeerFichero('V.DTT',Verbos);    (* Lee verbos *)
  LeerFichero('N.DTT',Nombres);  (* Lee nombres *)
  LeerFichero('P.DTT',Preposic);  (* Lee preposiciones *)
  LeerFichero('CONJ.DTT',Conju); (* conjunciones *)
  LeerFicheroObjetos;
  GetMem(pointer(PuntObj[255]),SizeOf(Objeto));
  PuntObj[255]^.nombre:='';
  PuntObj[255]^.pal:=255;
  PuntObj[255]^.num:=255;
  PuntObj[255]^.flags:=0;
  FillD(Procesos,1024,0);
  Leerprocesos;
  LeerConex;
  ClrScr;
  CursorOff;
  PSize:=PSize-MaxAvail;
  PSize:=PSize DIV 1024; (*Calcula lo que ha ocupado la base de datos*)
  IF LowMem THEN ROBAMEMORIA;
  IF INFORMACION THEN
   BEGIN
    WriteLn;
    WriteLn('NMP ',Version);
    WriteLn;
    Write('CPU:              : ',QUECHIP);
    if AMDCPUID<>'' THEN WriteLn(' ',AMDCPUID)
                    ELSE WriteLn;
    Write('SO:               : ');
    CASE CheckForWin3 OF
     RealStd,Enhanced:IF System.lo(Dosversion)<7 THEN Write(system.Lo(DosVersion),'.',Hi(Dosversion),' [Windows Box]') ELSE
                       IF Dosversion=$0A07 THEN Write('Windows 95 OSR2') else
                        IF Dosversion=$0007 THEN Write('Windows 95') else
                         Write(' Windows 98')
     else if System.Lo(DosVersion)<10 then Write(system.Lo(DosVersion),'.',Hi(Dosversion));
    END;
    IF System.Lo(DosVersion) MOD 10=0 THEN
     Write('OS/2 v',System.Lo(DosVersion) DIV 10,'.x');
    IF Running4DOS THEN Write(' [4DOS]');
    WriteLn;
    WriteLn;
    WriteLn('TAMA¥O DEL CODIGO : ',psize,'K');
    WriteLn('MEMORIA LIBRE     : ',MemAvail DIV 1024,'K');
    WriteLn;
    IF BTST(Flags[0],5) THEN IF ExistSB THEN WriteLn('SONIDO            : Sound Blaster '+SBDetect)
                                        ELSE WriteLn('SONIDO            : Adlib')
                        ELSE WriteLn('SONIDO            : PC SPEAKER');
    IF ExistSB AND BTST(Flags[0],5) THEN
     BEGIN
      WriteLn('SB PARAMETROS     : ',Hex(SB_Port),'h IRQ ',SB_IRQ,' DMA ',SB_DMA);
      Write  ('SFX               : ');
      IF BTST(Flags[0],6) THEN WriteLn('SI') ELSE WriteLn('NO');
     END;
     Write  ('MUSICA            : ');
     IF BTST(Flags[0],9) THEN WriteLn('SI') ELSE WriteLn('NO');
    CDInitInfo;
    Write('CD ROM            : ');
    IF CDInf.NumCD>0 THEN WriteLn('SI')
                     ELSE WriteLn('NO');
     WriteLn;
     Write  ('DRIVER DE USUARIO : ');
     IF DrvPtr<>NIL THEN WriteLn('INSTALADO (',SIZEDRV DIV 1024,'K USADOS)')
                    ELSE WriteLn('NO INSTALADO');
     Write  ('CACHE DE DISCO    : ');
     IF CACHEON THEN WriteLn('SI (',CACHESIZE,'K)')
                ELSE WriteLn('NO');
     Write  ('EMPAQUETADO       : ');
     IF ISPACKED THEN WriteLn('SI') ELSE WriteLn('NO');
     ReadKey;
   END;
 Colors[0]:=0;
 Colors[1]:=7;
 Colors[2]:=0;
 Setmode(1);
 FOR I:=1 TO NumConj DO BEGIN
                   Crear(Pila[I]);
                   CrearC(Cola[I]);
                   Conj[I]:=[]
                  END;

 Lo:='ß';
 Ver:='*';
 Nom:='*';
 GetAllPalette(Pall0);

 (*AQUI COMIENZA EL ROLLO*)

 Flags[9]:=255;
 Flags[23]:=255;
 Done:=False;
 Endd:=False;  (*Se usa ENDD y no END pues ‚sta es palabra reservada*)
 Notdone:=False;
 Break:=false;
 Desc:=False;
 Desc2:=False;
 Ddone:=False;
 WHILE NOT ENDD DO
  BEGIN
   Describe(Flags[1]);  (*Describe localidad*)
   IfParse(1);            (*Interpreta proceso 1*)
   IF (Objat[flags[1]]>0) AND NOT BTST(Flags[0],8) THEN
    BEGIN
     Mes(1);
     Listat(Flags[1],False)
    END;
   WHILE (NOT ENDD) AND (NOT DESC) DO
    BEGIN
     Input(ver,nom,pre,nom2,ver2,lo,true); (*Pide frase*)
     INC(Flags[3]);        (*Flag de TURNS*)
     FOR I:=5 TO 7 DO IF Flags[I]<>0 THEN Dec(Flags[I]);
     (*Flags autodecremento*)
     Flags[8]:=Objat[254];

     Ddone:=False;

     IF Timeout<>0 THEN ifParse(0)                (*Si no ha salido por timeout ejecuta response*)
      ELSE BEGIN
            Message(19);   (*El tiempo pasa...*)
            DDone:=True
           END;

     IF NOT DDone AND NOT DESC AND (Flags[18]<20) THEN Direcciones; (*Intenta moverse por las conexiones*)
     IF NOT DDONE AND NOT DESC AND NOT ENDD THEN NoPuedesHacerEso; (*No puedes hacer eso*)
     DDone:=False;
     IF NOT DESC AND NOT ENDD THEN ifParse(2);  (*Interpreta proceso 2*)
    END;
    DESC:=False;
  END;
 Refresh;
 ASM
  MOV AX,3
  INT 10h
 END;
 END.
