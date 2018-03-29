

{$M $3000,0,14000}  (* 3k pila, 14K Heap *)
{$I-}               (* No I/O fail check *)
{$X+}               (* Extended sintax, puede ignorarse el resultado de una funci¢n *)
{$G+}               (* Usar instrucciones 286 *)
{$S-}               (* No stack check *)
{$R-}               (* No chequeo de rango *)
PROGRAM NMP5;

USES Errors,CRT,DOS,PARACAJA,NMPMENU,Chips,redirect;

(* Las librer°as:
 PARACAJA: Funciones para hacer cajas con los caracteres Õ y dem†s.
 NMPMENU: Para hacer los men£s.
 CHIPS: Una funci¢n que me dice sobre que procesador funciono (diferencia
        hasta el 486, el pentium no pero da igual, lo £nico que quiero
        saber es si es un 8086 porque ese no vale *)

Function InfoBox(S:STRING):Char; Forward;

PROCEDURE PutInBuffer(A,B:Byte);
VAR OffBuf:Word;
BEGIN
 OffBuf:=MemW[$40:$1C];
 Mem[$40:OffBuf]:=a;
 mem[$40:OffBuf+1]:=b;
 INC(MemW[$40:$1C],2);
 IF MemW[$40:$1C]>=memW[$40:$82] THEN MemW[$40:$1C]:=MemW[$40:$80];
END;

PROCEDURE TryKbdMacro(A:Byte);
VAR F:FILE;
    S:String;
    Buffer:ARRAy[1..32] OF Byte;
    Num,I:Byte;
BEGIN
 STR(A,S);
 Assign(F,S+'.KBD');
 Reset(F,1);
 IF IOResult<>0 THEN Exit;
 BlockRead(F,num,1);
 BlockRead(F,buffer,32);
 FOR I:=1 TO Num DO BEGIN
                     Putinbuffer(Buffer[I],Buffer[I+1]);
                     INC(I)
                    END;
 Close(F);
END;



PROCEDURE Barra2; Forward;

{$I PANTALLA.POO} (* Esto es un include, lleva funciones para guardar y
                     recuperar la pantalla en modo texto *)

{$i NMPBuf.SRC} (* Este incluye un buffer de lectura de ficheros, para
                   acelerar la lectura *)

CONST DEF_COLOR=$1f;
      DEF_SHORTCUT=$74;
      DEF_BAR=$70;
      DEF_BOX=$4E;
      DEF_SELEC=$2F;
      FechaRevision:Packed Array[1..10] OF Char=' 4-3-1998';
      Autor:PACKED ARRAY[1..14] OF Char='Carlos S†nchez';
      VERSION='5.5';
      Anno=1996;

CONST MNSETUP:MenuDef=( NOpciones: 7;
                        Long:14;
                        Exit:3;
                        Opciones: ('#Memoria','#Font','#Editor Externo','#Cambiar Editor','#SVGA','#Teclado','#Acerca de',
                               '','','');

                        Activas:($FF,$FF);
                        AttrMenu:$70;
                        AttrBarra:$20;
                        AttrOculto:$78;
                        AttrSombra:$08;
                        AttrAlt:$04
                        );

CONST MNUTIL:MenuDef=( NOpciones: 9;
                        Long:13;
                        exit:3;
                        Opciones: ('#Ejecutar','#Caracteres','#Icon','#Key',
                               '#SBMComp','#FLI Break','#Hex','#Grab','#Notas (Alt-N)','');
                        Activas:($FF,$FF);
                        AttrMenu:$70;
                        AttrBarra:$20;
                        AttrOculto:$78;
                        AttrSombra:$08;
                        AttrAlt:$04
                        );

CONST MNCOMP:MenuDef=( NOpciones: 4;
                        Long:19;
                        exit:3;
                        Opciones: ('#Abrir Proyecto','#Nuevo Proyecto','#Compilar      (F9)','Compilar #Todo','','','',
                               '','','');
                        Activas:($FF,$FF);
                        AttrMenu:$70;
                        AttrBarra:$20;
                        AttrOculto:$78;
                        AttrSombra:$08;
                        AttrAlt:$04
                        );

CONST MNPROC:MenuDef=( NOpciones: 10;
                        Long:19;
                        exit:3;
                        Opciones: ('#Respuestas  (Alt-R)','Proceso #1   (Alt-1)','Proceso #2   (Alt-2)',
                        'Proceso 25#5 (Alt-5)','Proc. #Input (Alt-I)','#Procesos    (Alt-P)','#Crear Proceso',
                        '#Macro','#Nueva Macro','#Ultimo      (Alt-U)');
                        Activas:($FF,$FF);
                        AttrMenu:$70;
                        AttrBarra:$20;
                        AttrOculto:$78;
                        AttrSombra:$08;
                        AttrAlt:$04
                        );


CONST MNDEF:MenuDef=( NOpciones: 7;
                        Long:19;
                        exit:3;
                        Opciones: ('#Localidades (Alt-L)','#Objetos     (Alt-O)','#Vocabulario (Alt-V)','#Mensajes    (Alt-M)',
                        '#Windows     (Alt-W)','#Funci¢n     (Alt-F)','#Constantes  (Alt-C)','','','');
                        Activas:($FF,$FF);
                        AttrMenu:$70;
                        AttrBarra:$20;
                        AttrOculto:$78;
                        AttrSombra:$08;
                        AttrAlt:$04
                        );


CONST MNTEST:MenuDef=( NOpciones: 4;
                       Long:17;
                       exit:3;
                       Opciones: ('#Diagn¢sticos (F5)','#Normal   ','#Paso a Paso','#L°nea de comandos','',
                              '','','','','');
                       Activas:($FF,$FF);
                       AttrMenu:$70;
                       AttrBarra:$20;
                       AttrOculto:$78;
                       AttrSombra:$08;
                       AttrAlt:$04
                       );

TYPE String20=String[20];
TYPE Referencia=ARRAY[1..30] OF RECORD
                                 X,Y:Byte;
                                 Item:String20;
                                END;
(* Estos tipos son para la ayuda en l°nea, al contrario que tu, to limitÇ a
   30 el n£mero de "temas clave" por cada pantalla de ayuda *)

VAR SPACES:STRING;  (* Una cadena que se rellena de espacios *)
    InsertMode:Boolean;
    TEMP:STRING[128];
    Free:LongInt;
    F:FILE;
    CURSOR:ShortInt;
    P:PANTALLA;  (* definido en PANTALLA.POO *)
    ULTIMO:STRING[12]; (* Ultimo proceso editado *)
    ErrorFound:Boolean;
    ErrorFile:String[12];
    ErrorLine:Longint;
VAR CONFIGURACION : RECORD
     LINEAParam:STRING[50];
     TIMESEXEC:Byte;
     FONT:STRING[8];
     EDITOR:STRING[128];
     EDITORInterno:Boolean;
    END;


const MaxRow=25;MaxColumn=80;

var Buffer:array[1..MaxRow] of byte;
    XTable:array[1..MaxRow] of shortint;

procedure Init_XTable;
var cnt:byte;
begin for cnt:=0 to MaxRow-1 do XTable[cnt+1]:=-cnt; end;

FUNCTION TomaTecla(VAR Cha  : Char;
                VAR Extend : Boolean;
                VAR Explor : Byte;
                Var Camb   : Byte) : Boolean;
(* lectura completa del teclado *)
VAR Listo : Boolean;
BEGIN
  Extend := False;
  Explor := 0;
  ASM
   MOV AH,01h
   INT 16h
   JZ @NOTECLA
   XOR AH,AH
   INT 16h
   LES DI,[CHA]
   MOV ES:[DI],AL
   LES DI,[EXPLOR]
   MOV ES:[DI],AH
   MOV AX,1 (* DEVUELVE TRUE *)
   JMP @FIN
   @NOTECLA:
   XOR AX,AX (* DEVUELVE FALSE *)
   @FIN:
   MOV LISTO,AL
  END;
  Extend := CHA=#0;
  ASM
   MOV AH,02
   INT 16h
   LES DI,[CAMB]
   MOV ES:[DI],AL
  END;
  TomaTecla := Listo
END;


FuNCTION Shine(sx,sy,ex,ey:integer;c:byte):Boolean;
var x,y:integer;
    num,cnt:word;
    ch:char;
    ext:boolean;
    explor,camb:byte;
begin
 Shine:=False;
 cnt:=0;
 for x:=sx to ex+ey-sy do
 begin
  for y:=sy to ey do
   if (XTable[y-sy+1]+x > sx-1) and (XTable[y-sy+1]+x < ex+1) then
   begin
    num:=(y-1)*160+(XTable[y-sy+1]+(x-1))*2+1;
    Buffer[y]:=mem[$b800:num];                    {save background attr.}
    mem[$b800:num]:=c+Buffer[y] and 240;          {highlight the spot}
    if tomatecla(ch,ext,explor,camb) THEN BEGIN
                                        Shine:=True;
                                        exit
                                       END;
   end;
  asm                                             {retrace}
   mov dx,3dah;
   @r1: in al,dx; test al,8; jnz @r1
   @r2: in al,dx; test al,8; jz @r2
  end;
 for y:=sy to ey do
  if (XTable[y-sy+1]+x > sx-1) and (XTable[y-sy+1]+x < ex+1) then
  begin                                           {restore background attr.}
   mem[$b800:(y-1)*160+(XTable[y-sy+1]+(x-1))*2+1]:=Buffer[y];
  end;
 end;
end;


PROCEDURE SetRGB(n,r,g,b:byte);assembler;
asm
Mov dx,03c8h;
Mov al,n;
Out dx,al;
Inc dx;
Mov al,r;
Out dx,al;
Mov al,g;
Out dx,al;
Mov al,b;
Out dx,al;
end;


PROCEDURE LoadFont(S:String); Forward;

PROCEDURE Error(N:Byte);
BEGIN
 Window(1,1,80,25);
 TextAttr:=$07;
 ClrScr;
 LoadFont('NORMAL');
 Write('Error: ');
 CASE N OF
  1:WriteLn('Imposible grabar fichero de configuraci¢n. ®Disco lleno?');
  2:WriteLn('No se encuentra juego de caracteres.');
  3:WriteLn('Se requiere 386 o superior.');
 END;
 Halt(n);
END;


PROCEDURE LOWST(VAR S:STRING);
VAR I:BYTE;
BEGIN
 FOR I:=1 TO byte(S[0]) DO
  CASE S[I] OF
  'A'..'Z':S[I]:=Char(byte(S[I])+32);
  '•':S[I]:='§';
  'Ä':S[I]:='á';
  'ö':S[I]:='Å';
 END;
END;

PROCEDURE UpSt(VAR S:STRING);
VAR I:BYTE;
BEGIN
 FOR I:=1 TO byte(S[0]) DO
  CASE S[I] OF
   '§':S[I]:='•';
   'á':S[I]:='Ä';
   '†':S[I]:='A';
   'Ç':S[I]:='E';
   '°':S[I]:='I';
   '¢':S[I]:='O';
   '£':S[I]:='U';
   'Å':S[I]:='ö'
   ELSE S[I]:=UpCase(S[I]);
  END;
END;


PROCEDURE Escribe(S:String);
(* Escribe la cadena S poniendo en rojo la letra que sigue a ‚ *)
BEGIN
 TextAttr:=DEF_Bar;
 Write(Copy(S,1,Pos('~',S)-1));
 TextAttr:=DEF_SHORTCUT;
 Write(Copy(S,Pos('~',S)+1,Pos('‚',S)-Pos('~',S)-1));
 TextAttr:=DEF_Bar;
 Write(Copy(S,Pos('‚',S)+1,255));
 TextAttr:=DEF_COLOR;
END;


PROCEDURE Beep;
(* Un pitido *)
BEGIN
 Sound(100);
 Delay(400);
 NoSound;
END;

PROCEDURE CursorOn; Assembler;
(* Hace reaparecer el cursor *)
ASM
   MOV AH,0Fh
   INT 10h
   CMP AL,7
   JE @@1
   MOV CX,0607h
   JMP @@2
@@1:MOV CX,0B0Ch
@@2:MOV AH,01
   INT 10h
END;


PROCEDURE DescarTecla; Assembler;
(* vac°a el buffer de teclado *)
ASM
  MOV AH,1
  INT 16h
  JZ @NADA
  @BUC:
  MOV AH,0
  INT 16h
  MOV AH,1
  INT 16h
  JNZ @BUC
  @NADA:
END;

PROCEDURE CursorOff; Assembler;
(* apaga el cursor *)
ASM
 MOV AX,100h
 MOV CX,2000h
 INT 10h
END;

PROCEDURE STDColors;
BEGIN
 SetRGB(1,0,0,20);
 setrgb(3,0,30,40);
END;


PROCEDURE SP; Far;
(* Salvapantallas *)
VAR PT:Pantalla;
    OFFS:Word;
    Col:Byte;
BEGIN
 PT.Inicializar(80,25);
 PT.Salvar;
 COL:=Random(3);
 CASE COL OF
  0:EXEC('Saver1.sav','');
  1:EXEC('Saver2.sav','');
  2:EXEC('Saver3.sav','');
 END;
 ASM
 MOV AX,3
 INT 10h
 END;
 STDColors;
 CursorOff;
 PT.Recuperar;
 LoadFont(COnfiguracion.font);
 TimerCOunt:=Timer; (* Reinicio cuenta de tics para que salte de nuevo el
                       salvapantallas *)
END;



PROCEDURE BETA;
(* Saca el mensaje de que es versi¢n beta si encuentra el fichero BETA.FIL *)
VAR T:TEXT;
    Betatester:String;
BEGIN
Assign(T,'BETA.FIL');
reset(T);
ReadLn(T,Betatester);
ReadLn(T,Betatester);
CLose(t);
betatester:=' '+BetaTester+' ';
TextAttr:=$1f;
clrscr;
 write ('€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€    NMP ·5.0   €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€');
 Textattr:=$0F;
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                      ATENCION                    ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ Se encuentra en sus manos una versi¢n en pruebas ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ del parser NMP.  Esta versi¢n  no ha sido por el ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ momento suficientemente probada para asegurar la ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ ausencia de  errores.  Si localizara alguno haga ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ el favor de comunicarlo al autor.                ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ Esta versi¢n es para su uso personal y no es de  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ dominio p£blico ni shareware.                    ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫            NO DISTRIBUYA ESTA VERSION            ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 GotoXY(40-byte(Betatester[0]) DIV 2,wherey-1); WriteLn(BetaTester);
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 textAttr:=$07;
 WriteLn;
 Clreol;
 Readkey;
 GotoXY(1,Wherey-1);
END;

PROCEDURE DISCOLLENO;
BEGIN
TextAttr:=$1f;
clrscr;
 write ('€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€    NMP 5.0   €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€');
 Textattr:=$0F;
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                      ATENCION                    ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ Su sistema parece disponer de poco espacio libre ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ en el disco duro. Esto podr°a  llegar a  suponer ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ un mal funcionamiento de NMP. Usted puede  ahora ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ continuar y atenerse a las consecuencias o  bien ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ retornar al DOS y liberar espacio en el disco.   ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫         ® CONTINUAR O SALIR AL DOS ? (C/D)       ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 IF Upcase(ReadKey)<>'C' THEN BEGIN
                               TextAttr:=$07;
                               Clrscr;
                               CursorOn;
                               WriteLn('OK. NMP abortado.');
                               Halt;
                              END;
END;

PROCEDURE DOUBLESPACE;
BEGIN
TextAttr:=$1f;
clrscr;
 write ('€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€    NMP 5.0   €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€');
 Textattr:=$0F;
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                      ATENCION                    ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ Su sistema parece tener instalado un doblador de ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ disco duro, y el espacio disponible en disco  es ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ o podr°a ser insuficiente para  el correcto  uso ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ de NMP teniendo en cuenta esta caracter°stica.   ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ Usted puede retornar  ahora al DOS  para liberar ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ espacio o bien continuar ateniendose a cualquier ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ posible consecuencia.                            ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫         ® CONTINUAR O SALIR AL DOS ? (C/D)       ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 IF Upcase(ReadKey)<>'C' THEN BEGIN
                               TextAttr:=$07;
                               ClrScr;
                               CursorOn;
                               WriteLn('OK. NMP abortado.');
                               Halt;
                              END;
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
   IF TimerCount+540<Timer THEN SP;
  UNTIL TomaTecla(Ch,Extend,Explor,Camb);
  TimerCount:=Timer;
  CursorOff;
  S1:=UpCase(Ch);
  IF Extend AND (Explor=79) THEN Cursor:=byte(S[0]);
  IF Extend AND (Explor=71) THEN Cursor:=0;
  IF Extend AND (Explor=77) THEN
   IF (Cursor<byte(S[0])) THEN Inc(Cursor) ELSE Beep;
  IF Extend AND (Explor=75) THEN
   IF (Cursor>0) THEN Dec(Cursor) ELSE Beep ;
  IF Extend AND (Explor=82) THEN InsertMode:=NOT InsertMode;
  IF Extend AND (Explor=83) THEN IF PRIMERO THEN S:=''
                                            ELSE IF Cursor<byte(S[0])
                                             THEN Delete(S,Cursor+1,1)
                                             ELSE Beep;
  IF Extend AND (Explor IN [84..93,135,136]) THEN TryKbdMacro(Explor);
  IF (Ch IN [#32..#255]) AND InsertMode THEN
   IF length(S)<Long THEN BEGIN
                           Insert(S1,S,Cursor+1);
                           Inc(Cursor)
                          END ELSE Beep;
  IF (Ch IN [#32..#255]) AND NOT InsertMode THEN
   IF Cursor<>Long THEN BEGIN
                          Inc(Cursor);
                          IF byte(S[0])<Cursor THEN S:=Copy(S+Copy(Spaces,1,long),1,long);
                          S[Cursor]:=Ch;
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

PROCEDURE LoadFont(S:STRING);
(* Carga un font de 16 de SD2 *)
VAR F:FILE;
    P:Pointer;
    H:Word;
BEGIN
 Assign(F,S+'.FNT');
 Reset(F,1);
 H:=IOresult;
 IF (H<>0) AND (S='NORMAL') THEN Exit;
 IF H<>0 THEN Error(2);
 Seek(F,16);
 GetMem(P,4096);
 BlockRead(F,P^,4096,H);
 IF (H<>4096) OR NOT EOF(F) THEN BEGIN
                                  Close(F);
                                  FreeMem(P,4096);
                                  Beep;
                                  LoadFont('Normal');
                                  Exit
                                 END;
 Close(F);
 ASM
  push bp
  mov ax,1100h
  mov bh,16
  mov bl,0
  mov cx,256
  mov dx,0
  les bp,p
  int 10h
  pop bp
 END;
 CursorOff;
 FreeMem(P,4096)
END;

FUNCTION NORMAL(S:String;N:Byte):String;
(* Saca el texto normalizado a la derecha, con un ancho de N *)
BEGIN
 Normal:=S+Copy(Spaces,1,N-byte(S[0]))
END;

VAR DIR:ARRAY[Byte] OF RECORD
                        Nombre:String[10];
                        Fichero:String[8];
                       END;

FUNCTION SELECCIONAR(SPEC:String):String;
(* Selecci¢n de proceso/macro *)
VAR S:SearchRec;
    I,J,K:Byte;
    F:FILE;
    Base:Byte;
    Puntero:Byte;
    Ch:Char;
    Ext:boolean;
    Explor,Camb:Byte;

BEGIN
 I:=0;
 FindFirst('*.'+SPEC,ANYFILE,S);
 WHILE DosError=0 DO
  BEGIN
   IF (S.Name<>'R.NMP') AND (S.Name<>'1.NMP') AND (S.Name<>'2.NMP')
    AND (S.Name<>'255.NMP') AND (S.Name<>'I.NMP') THEN
    BEGIN
     DIR[I].Fichero:=Copy(S.NAME,1,Pos('.',S.NAME)-1);
     Assign(F,DIR[I].Fichero+'.PN');
     Reset(F,1);
     IF IOResult<>0 THEN DIR[I].Nombre:='-----------'
                    ELSE BEGIN
                          BlockRead(F,DIR[I].Nombre,11);
                          Close(F)
                         END;
     INC(I);
    END;
   FindNext(S);
  END;
  IF I=0 THEN BEGIN
               Seleccionar:='##';
               Exit
              END;
  DEC(I);
  Base:=0;
  Puntero:=0;
  TextAttr:=DEF_Bar;
  HacerCaja(30,6,20,15,caracGraf);
  GotoXY(35,6);
  IF SPEC='NMP' THEN Write(' PROCESOS ')
                ELSE Write('ƒ MACROS ƒ');
  REPEAT
   J:=BASE;
   WHILE (J<=I) AND (J<BASE+13) DO
    BEGIN
     IF J=Puntero THEN TextAttr:=DEF_SELEC
                  ELSE TextAttr:=DEF_Bar;
     GotoXY(31,7+J-BASE);
      Write(Normal(DIR[J].NOMBRE,11),'  ',Normal(DIr[J].FICHERO,5));
     INC(J);
    END;
   TextAttr:=DEF_Bar;
   FOR J:=J TO BASE+12 DO
    BEGIN
     GotoXY(31,7+J-BASE);
     Write('                  ');
    END;
   Ch:=#0;
   REPEAT UNTIL Tomatecla(Ch,Ext,Explor,Camb);
   IF Ext THEN CASE Explor OF
    72:BEGIN
        IF Puntero>0 THEN Dec(Puntero);
        IF Puntero<Base THEN DEC(Base);
       END;
    80:BEGIN
        IF Puntero<I THEN Inc(Puntero);
        IF Puntero>Base+12 THEN Inc(Base);
       END;
    ELSE Beep
   END;
  UNTIL Ch IN [#27,#13];
 IF Ch=#13 THEN Seleccionar:=DIR[Puntero].Fichero+'.'+SPEC ELSE Seleccionar:='';
 Barra2;
END;


FUNCTION GETPROJECT:String;
VAR S:SearchRec;
    I,J,K:Byte;
    F:FILE;
    Base:Byte;
    Puntero:Byte;
    Ch:Char;
    Ext:boolean;
    Explor,Camb:Byte;

BEGIN
 I:=0;
 FindFirst('*.PRJ',DIRECTORY,S);
 WHILE DosError=0 DO
  BEGIN
   IF S.Attr AND Directory=Directory THEN
    BEGIN
     DIR[I].Fichero:=Copy(S.NAME,1,Pos('.',S.NAME)-1);
     INC(I);
    END;
   FindNext(S);
  END;
  IF I=0 THEN BEGIN
               getProject:='##';
               InfoBox('NO HAY NINGUN PROYECTO');
               Exit
              END;
  DEC(I);
  Base:=0;
  Puntero:=0;
  TextAttr:=DEF_Bar;
  HacerCaja(34,6,16,15,caracGraf);
  GotoXY(35,6);
  WRITE(' PROYECTOS');
  REPEAT
   J:=BASE;
   WHILE (J<=I) AND (J<BASE+13) DO
    BEGIN
     IF J=Puntero THEN TextAttr:=DEF_SELEC
                  ELSE TextAttr:=DEF_Bar;
     GotoXY(35,7+J-BASE);
      Write(Normal(DIr[J].FICHERO,8),'      ');
     INC(J);
    END;
   TextAttr:=DEF_Bar;
   FOR J:=J TO BASE+12 DO
    BEGIN
     GotoXY(35,7+J-BASE);
     Write('              ');
    END;
   Ch:=#0;
   REPEAT UNTIL Tomatecla(Ch,Ext,Explor,Camb);
   IF Ext THEN CASE Explor OF
    72:BEGIN
        IF Puntero>0 THEN Dec(Puntero);
        IF Puntero<Base THEN DEC(Base);
       END;
    80:BEGIN
        IF Puntero<I THEN Inc(Puntero);
        IF Puntero>Base+12 THEN Inc(Base);
       END;
    ELSE Beep
   END;
  UNTIL Ch IN [#27,#13];
 IF Ch=#13 THEN getProject:=DIR[Puntero].Fichero+'.PRJ' ELSE GetProject:='';
 Barra2;
END;

PROCEDURE FUNCION;


TYPE String15=String[15];
     FUNC=ARRAY [1..9] OF String15;


VAR A:FUNC;
    Ch:Char;
    Extend:Boolean;
    Explor,Camb:Byte;
    F:File OF Func;
    I:Byte;
    St:String;


Procedure MostrarF;
VAR I:Byte;

BEGIN
TextAttr:=DEF_COLOR;
WriteLn(' Tecla       Texto asociado  ');
TextAttr:=DEF_Bar;
WriteLn('ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ');
FOR I:=1 TO 9 DO WriteLn('   ',I,'         ',Copy(A[I]+'                 ',1,15),'  ');
WriteLn('ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ');
TextAttr:=DEF_COLOR;
END;

BEGIN
Textattr:=DEF_COLOR;
IF Fsearch('ADV\F.DAT','')='' THEN BEGIN
                                FOR I:=1 TO 9 DO
                                  A[I]:='';
                                Assign(F,'ADV\F.DAT');
                                Rewrite(F);
                                Write(F,a);
                                Close(F)
                                END;
Window(3,4,78,21);
ClrScr;
Assign(F,'ADV\F.DAT');
Reset(F);
Read(F,a);
Close(F);
REPEAT
 MostrarF;
 WriteLn;
 WriteLn('Pulse una tecla de funci¢n o ENTER para terminar.');
 REPEAT
  IF TimerCount+540<Timer THEN SP;
 UNTIL Tomatecla(ch,extend,explor,camb);
 TimerCount:=Timer;
 IF (Ch<>#13) AND (Extend AND (Explor IN [59..67])) THEN
  BEGIN
   Dec(Explor,58);
   TextAttr:=DEF_Bar;
   HacerCaja(2,16,17,3,CaracGraf);
   GotoXY(3,16);
   Write(' TEXTO PARA F',EXPLOR,' ');
   GotoXY(3,17);
   ReadLn2(A[Explor],15);
   TextAttr:=DEF_COLOR;
   GotoXY(1,18);ClrEol;
   GotoXY(1,16);ClrEol;
   GotoXY(1,17);ClrEol;
   Inc(Explor,58);
  END;
GotoXy(1,1);
UNTIL Ch=#13;
Assign(F,'ADV\F.DAT');
Rewrite(F);
Write(F,a);
Close(F);
Window(1,1,80,25);
Barra2;
END;


PROCEDURE WIN;

TYPE Windo=ARRAy[0..19] OF RECORD
                            X0,Y0,XF,YF:Word;
                           END;


VAR Wind:Windo;
    F:File;
    Ch:Char;
    Extend:Boolean;
    Explor,Camb:Byte;
    I:Byte;
    St:String[6];
    code:integer;
    leidos:word;
    Num:String[4];
    Numm:Byte;
    X,Y:Byte;

Procedure MostrarW;
VAR I:Byte;

BEGIN
TextAttr:=DEF_COLOR;
Write(' Window         X0  Y0   XF  YF');
WriteLn('  Window         X0   Y0   XF  YF');
TextAttr:=DEF_Bar;
WriteLn('ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ');
FOR I:=0 TO 9 DO BEGIN
                  Write('   ',I,'         ',Wind[I].X0:5,Wind[I].Y0:4,Wind[I].XF:5,Wind[I].YF:4,'≥');
                  WriteLn('   ',I+10,'         ',Wind[I+10].X0:5,Wind[I+10].Y0:4,Wind[I+10].XF:5,Wind[10+I].YF:4,' ');
                 END;
WriteLn('ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ');
TextAttr:=DEF_COLOR;
END;

BEGIN
 FOR I:=0 TO 19 DO
  BEGIN
   Wind[I].X0:=0;
   Wind[I].Y0:=0;
   Wind[I].XF:=319;
   Wind[I].YF:=199
  END;
IF Fsearch('ADV\W.DAT','')='' THEN BEGIN
                                Assign(F,'ADV\W.DAT');
                                Rewrite(F,1);
                                BlockWrite(F,wind,SizeOf(Wind));
                                Close(F)
                                END;

Window(3,4,78,21);
TextAttr:=DEF_COLOR;
ClrScr;
Assign(F,'ADV\W.DAT');
Reset(F,1);
BlockRead(F,wind,sizeof(windo),leidos);
Close(F);
Ch:='@';
REPEAT
Barra2;
Window(3,4,78,21);
GotoXY(1,1);
MostrarW;
WriteLn('Teclee el nß de ventana a');
WriteLn('modificar o pulse ENTER para');
WriteLn('terminar.');
X:=WhereX;Y:=WhereY;
REPEAT
 Code:=1;
 Num:='';
 ReadLn2(Num,4);
 FOR I:=1 TO length(Num) DO IF NOT (NUm[I] IN ['0'..'9']) THEN Code:=-1;
 Numm:=0;
 FOR I:=1 TO length(Num) DO Numm:=Numm*10+Byte(Num[I])-48;
 IF NOT (Numm IN [0..19]) THEN code:=-1;
 GotoXy(X,Y);Clreol;
UNTIL (Code>0) OR (Num='');
IF Num<>'' THEN
 BEGIN
    Barra2;
    Window(1,1,80,25);
    Hacercaja(22,5,37,18,caracgraf);
    Window(23,6,57,21);
    I:=Numm;
    WriteLn('Window:',I);
    WriteLn;
    WriteLn('(',Wind[i].X0,',',Wind[i].Y0,',',Wind[i].XF,',',Wind[I].YF,')');
    WriteLn;
    WriteLn('Introduzca coordenadas:');

   REPEAT
    Write('X0:');
    ReadLn(St);Val(St,Wind[I].x0,code);IF Code<>0 THEN wind[I].X0:=2000;
    IF Wind[i].X0>1023 THEN
     WriteLn('Error: Debe estar en el rango 0-1023');
   UNTIL (Wind[I].X0<=1023);
   REPEAT
    Write('Y0:');
    ReadLn(St);Val(St,Wind[I].Y0,code);IF Code<>0 THEN wind[I].Y0:=2000;
    IF Wind[i].Y0>767 THEN
     WriteLn('Error: Debe estar en el rango 0-767');
   UNTIL (Wind[I].Y0<=767);
   REPEAT
    Write('XF:');
    ReadLn(St);Val(St,Wind[I].XF,code);IF Code<>0 THEN wind[I].XF:=2000;
    IF (Wind[i].XF>1023) OR (Wind[i].XF<Wind[i].X0) THEN
     WriteLn('Error:Debe estar en rango ',Wind[i].X0,'-1023');
   UNTIL (Wind[I].XF<=1023) AND (Wind[i].XF>=Wind[i].X0);

   REPEAT
    Write('YF:');
    ReadLn(St);Val(St,Wind[I].YF,code);IF Code<>0 THEN wind[I].YF:=2000;
    IF (Wind[i].YF>767) OR (Wind[i].YF<Wind[i].Y0) THEN
     WriteLn('Error:Debe estar en rango ',Wind[i].Y0,'-767');
   UNTIL (Wind[I].YF<=767) AND (Wind[i].YF>=Wind[i].Y0);
   ClrScr;
   Window(3,4,78,21);
 END;
UNTIL Num='';
Assign(F,'ADV\W.DAT');
Rewrite(F,1);
BlockWrite(F,wind,SizeoF(wind));
Close(F);
Window(1,1,80,25);
Barra2;
TimerCount:=Timer;
END;

PROCEDURE CONFIGURAR;
VAR F:FILE;
BEGIN
 Assign(F,'NMP.CFG');
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      CONFIGURACION.LINEAParam:='';
                      CONFIGURACION.TIMESEXEC:=0;
                      CONFIGURACION.FONT:='NORMAL';
                      CONFIGURACION.EDITOR:='EDNMP.EXE';
                      CONFIGURACION.EDitorInterno:=True;
                     END
                ELSE BEGIN
                      BlockRead(F,CONFIGURACION,SizeOf(CONFIGURACION));
                      Close(F)
                     END;
END;

PROCEDURE GRABAR_CONFIGURACION;
VAR F:FILE;
BEGIN
 Assign(F,'NMP.CFG');
 Rewrite(F,1);
 IF IOResult<>0 THEN Error(1);
 BlockWrite(F,CONFIGURACION,SizeOf(CONFIGURACION));
 Close(F)
END;

PROCEDURE Center(S:String);
BEGIN
 GotoXY(40-byte(S[0]) DIV 2,Wherey);
 Write(S)
END;

PROCEDURE Barra;
BEGIN
 TextAttr:=DEF_COLOR;
 ClrScr;
 HacerCaja(1,2,80,22,CaracGraf);
 textAttr:=DEF_BAR;
 GotoXY(1,1);
 ClrEol;
 Escribe(' ~P‚rocesos  ');
 Escribe(' ~D‚efiniciones  ');
 Escribe(' ~C‚ompilar  ');
 Escribe(' ~T‚est  ');
 Escribe(' ~U‚tilidades  ');
 Escribe(' ~S‚etup  ');
 GotoXY(1,24);
 TextAttr:=DEF_Bar;
 ClrEol;
 Escribe(' ~Alt-X‚ Salir  '); Escribe('~F1‚ Ayuda');
 GotoXY(1,25);
 TextAttr:=0;
 ClrEol;
 P.Inicializar(80,25);
 P.Salvar;
END;


FUNCTION STRS(W:Word):String;
VAR Aux:String;
BEGIN
 STR(W,Aux);
 STRS:=Aux
END;



PROCEDURE Barra2;
VAR T:text;
    S:String;
    Att:Byte;
BEGIN
 Window(1,1,80,25);
 P.Mostrar;
 Assign(T,'PROJECT.DAT');
 Reset(T);
 Att:=textAttr;
 IF IOresult=0 THEN BEGIN
                     ReadLn(T,S);
                     S:=Copy(S,1,Pos('.',S)-1);
                     GotoXY(68,24);
                     TextAttr:=$71;
                     Write('[',S,']');
                     Close(T);
                    END;
 TextAttr:=Att;
END;

Procedure About1;
VAR I:Byte;
BEGIN
 Init_Xtable;
 TextAttr:=$70;
 HacerCaja(28,9,24,7,CaracGraf);
 GotoXY(29,10);
 Write('      NM  PARSER      ');
 GotoXY(29,11);
 Write('                      ');
 GotoXY(29,12);
 Write('     Versi¢n  ',Version,'     ');
 GotoXY(29,13);
 Write('                      ');
 GotoXY(29,14);
 Write('   ',anno,' (C) NM Soft   ');
 TextAttr:=$08;
 FOR I:=10 TO 15 DO BEGIN
                     SetAttr(52,I,8);
                     SetAttr(53,I,8);
                    END;
 FOR I:=30 TO 53 DO SetAttr(I,16,8);
 if not shine(28,9,28+24,16,15) then readkey;
END;

Procedure About2;
VAR I:Byte;
BEGIN
 TextAttr:=$70;
 HacerCaja(28,8,24,9,CaracGraf);
 GotoXY(29,9);
 Write('    NM  PARSER ',version,'    ');
 GotoXY(29,10);
 Write('                      ');
 GotoXY(29,11);
 Write('  Por ',Autor,'  ');
 GotoXY(29,12);
 Write('                      ');
 GotoXY(29,13);
 Write('   ',anno,' (C) NM Soft   ');
 GotoXY(29,14);
 Write('                      ');
 GOTOXY(29,15);
 Write(' Revisi¢n: ',FechaRevision,' ');
 TextAttr:=$08;
 FOR I:=9 TO 16 DO BEGIN
                     SetAttr(52,I,8);
                     SetAttr(53,I,8);
                    END;
 FOR I:=30 TO 53 DO SetAttr(I,17,8);
 shine(28,9,28+24,17,15);
END;

FUNCTION Ayuda(VAR S:String20):Boolean;
VAR F:File;
    T:text;
    Name:String[8];
    A,B:LongInt;
    Buffer:PACKED ARRAY[1..1500] OF Char;
    Leidos:Word;
    Lineas:Byte;
    Longl,MaxLong:Byte;
    St:String;
    I,I2,MinDist:Word;
    Ref:referencia;
    RefI,maxrefi:Byte;
    Ch:Char;
    Extend:Boolean;
    Explor,Camb:Byte;
    Old,OldRef:Byte;

BEGIN
 Window(1,1,80,25);
 FOR I:=1 TO Length(S) DO S[I]:=UpCase(S[I]);
 Assign(F,'AYUDA.H00');
 Name:='#@|@#{a{';
 Reset(f,1);
 WHILE NOT EOF(F) AND (Name<>S) DO
  BEGIN
   BlockRead(F,A,4);
   BlockRead(F,Name,9);
   BlockRead(F,B,4);
  END;
 Close(F);
 IF Name<>S THEN BEGIN
                  S:=Copy(S,1,length(s)-1);
                  IF S='' THEN S:='NOTFOUND';
                  Ayuda:=True;
                  Exit;
                 END
            ELSE BEGIN
                  Assign(F,'AYUDA.H01');
                  Reset(F,1);
                  Seek(F,A);
                  BlockRead(F,Buffer,B-a,leidos);
                  Close(F);
                  Lineas:=1;
                  LongL:=0;
                  MaxLong:=0;
                  FOR I:=1 TO 20 DO ref[I].X:=0;
                  FOR I:=1 TO leidos-1 DO
                   BEGIN
                    INC(LongL);
                    IF Buffer[I]=#10 THEN BEGIN
                                          IF LongL>MaxLong THEN MaxLong:=LongL;
                                          Inc(Lineas);
                                          LongL:=0;
                                         END;
                   END;
                  textAttr:=$3F;
                  Inc(Lineas);
                  HacerCaja(40-MaxLong DIV 2,12-Lineas DIV 2,Maxlong+2,Lineas,CaracGraf);
                  FOR I:=40-Maxlong DIV 2+2 TO 40-MaxLong DIV 2+maxlong+1 DO SetAttr(I,12-Lineas DIV 2+Lineas,8);
                  FOR I:=13-Lineas DIV 2 TO 12-Lineas DIV 2+Lineas DO BEGIN
                      SetAttr(40-Maxlong DIV 2 + Maxlong +2,I,8);
                      SetAttr(40-Maxlong DIV 2 + Maxlong +3,I,8);
                     END;

                  GotoXY(37,12-Lineas DIV 2);
                  Write(' Ayuda ');
                  textAttr:=$30;
                  Window(40-Maxlong DIV 2+1,12-Lineas DIV 2+1,40-Maxlong DIV 2+Maxlong,10-Lineas DIV 2+Lineas);
                  ClrScr;
                  Window(40-Maxlong DIV 2+2,11-Lineas DIV 2+2,40-Maxlong DIV 2+Maxlong,11-Lineas DIV 2+Lineas);
                  Refi:=1;
                  FOR I:=1 TO leidos-1 DO
                    IF (Buffer[I]='|') AND (Buffer[I+1]='|') THEN
                     BEGIN
                      Write(Buffer[I]);
                      Inc(I)
                     END ELSE
                    IF (Buffer[I]='|') THEN BEGIN
                                             TextAttr:=$3E;
                                             ref[refi].X:=WhereX;
                                             Ref[refi].Y:=Wherey;
                                             Inc(i);
                                             Ref[Refi].Item:='';
                                             WHILE Buffer[I]<>'|' DO
                                              BEGIN
                                               Ref[Refi].Item:=ref[refi].Item+Buffer[i];
                                               Write(Buffer[I]);
                                               Inc(i);
                                               END;
                                             Inc(refi);
                                             textAttr:=$30;
                                            END
                      ELSE Write(Buffer[I]);
                  maxrefi:=refi-1;
                  Refi:=0;
                  IF MaxRefi<>0 THEN BEGIN
                                      refi:=1;
                                      GotoXY(Ref[Refi].X,ref[refi].Y);
                                      TextAttr:=$0E;
                                      Write(Ref[Refi].item);
                                      TextAttr:=$3e;
                                     END;
                  REPEAT
                   REPEAT UNTIL Tomatecla(CH,Extend,Explor,Camb);
                   IF (Ch=#9) AND (Maxrefi<>0) THEN BEGIN
                                  IF refi<>0 THEN BEGIN
                                                   GotoXY(Ref[Refi].X,ref[refi].Y);
                                                   TextAttr:=$3E;
                                                   Write(Ref[refi].Item);
                                                  END;
                                  Inc(refi);
                                  IF (Refi>MaxRefi) OR (ref[Refi].X=0) THEN
                                    Refi:=1;
                                  textAttr:=$0E;
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                  Write(Ref[refi].Item);
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                 END;
                   IF  (Extend AND (Explor=77)) AND (Maxrefi<>0) THEN BEGIN
                                  IF refi<>0 THEN BEGIN
                                                   GotoXY(Ref[Refi].X,ref[refi].Y);
                                                   TextAttr:=$3E;
                                                   Write(Ref[refi].Item);
                                                  END;
                                  Inc(refi);
                                  IF (Refi>MaxRefi) OR (ref[Refi].X=0) THEN
                                    Refi:=MaxRefi;
                                  textAttr:=$0E;
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                  Write(Ref[refi].Item);
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                 END;
                   IF Extend AND  (eXplor = 15) AND (Maxrefi<>0) THEN BEGIN
                                  IF refi<>0 THEN BEGIN
                                                   GotoXY(Ref[Refi].X,ref[refi].Y);
                                                   TextAttr:=$3E;
                                                   Write(Ref[refi].Item);
                                                  END;
                                  Dec(refi);
                                  IF (Refi IN [0,255]) OR (ref[Refi].X=0) THEN
                                    Refi:=Maxrefi;
                                  textAttr:=$0E;
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                  Write(Ref[refi].Item);
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                 END;
                   IF Extend AND  (eXplor = 75) AND (Maxrefi<>0) THEN BEGIN
                                  IF refi<>0 THEN BEGIN
                                                   GotoXY(Ref[Refi].X,ref[refi].Y);
                                                   TextAttr:=$3E;
                                                   Write(Ref[refi].Item);
                                                  END;
                                  Dec(refi);
                                  IF (Refi =0) OR (ref[Refi].X=0) THEN
                                    Refi:=1;
                                  textAttr:=$0E;
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                  Write(Ref[refi].Item);
                                  GotoXY(ref[Refi].X,Ref[refi].Y);
                                 END;

                   IF Extend AND (Explor=80) THEN (* Cursor abajo *)
                    BEGIN
                     I:=REF[Refi].Y;
                     I2:=REF[Refi].X;
                     OldRef:=Refi;
                     Old:=refi;
                     WHILE (OldRef<=MaxRefi) AND (REF[OldRef].Y=I) DO Inc(OldRef);
                     IF (OldRef<>Refi) AND (oldRef<=MaxRefi) THEN (*Ya estoy colocado en el primero de la fila siguiente *)
                      BEGIN
                       MinDist:=100;
                       refi:=OldRef;
                       WHILE (OldRef<=MaxRefi) AND (REF[OldRef].Y=Ref[Refi].Y) DO
                        IF ABS(Ref[OldRef].X-I2)<MinDist THEN BEGIN
                                                          Refi:=OldRef;
                                                          MinDist:=ABS(Ref[OldRef].X-I2);
                                                          INC(OldRef)
                                                         END ELSE INC(OldRef);
                         GotoXY(Ref[old].X,ref[old].Y);
                         TextAttr:=$3E;
                         Write(Ref[old].Item);
                         textAttr:=$0E;
                         GotoXY(ref[Refi].X,Ref[refi].Y);
                         Write(Ref[refi].Item);
                         GotoXY(ref[Refi].X,Ref[refi].Y);
                      END;
                    END;

                  IF Extend AND (Explor=72) THEN (* Cursor arriba *)
                   BEGIN
                    I:=REF[Refi].Y;
                    I2:=REF[Refi].X;
                    OldRef:=Refi;
                    Old:=refi;
                    WHILE (OldRef>0) AND (REF[OldRef].Y=I) DO Dec(OldRef);
                    IF (OldRef<>Refi) AND (OldRef<>0) THEN (*Ya estoy colocado en el primero de la fila siguiente *)
                     BEGIN
                      MinDist:=100;
                      refi:=OldRef;
                      WHILE (OldRef>0) AND (REF[OldRef].Y=Ref[Refi].Y) DO
                       IF ABS(Ref[OldRef].X-I2)<MinDist THEN BEGIN
                                                         Refi:=OldRef;
                                                         MinDist:=ABS(Ref[OldRef].X-I2);
                                                         DEC(OldRef)
                                                        END ELSE DEC(OldRef);
                      GotoXY(Ref[old].X,ref[old].Y);
                      TextAttr:=$3E;
                      Write(Ref[old].Item);
                       textAttr:=$0E;
                        GotoXY(ref[refi].X,Ref[refi].Y);
                        Write(Ref[refi].Item);
                        GotoXY(ref[Refi].X,Ref[refi].Y);
                     END;
                   END;

                  UNTIL (Ch=#27) OR ((Ch=#13) AND (Refi<>0)) OR (Ch=' ');
                  Window(1,1,80,25);
                  textAttr:=$1F;
                  IF (Ch=#13) AND (Refi<>0) THEN S:=Copy(ref[refi].item,1,8);
                  Ayuda:=NOT ((Ch=#27) OR (Ch=' '));
                END;
END;

PROCEDURE Help(S:String20);
VAR Pant:Pantalla;
    St:String20;
BEGIN
 Pant.Inicializar(80,25);
 Pant.Salvar;
 St:=S;
 REPEAT
  Pant.Mostrar;
  TimerCount:=Timer;
 UNTIL NOT Ayuda(St);
 TimerCount:=Timer;
 Pant.Recuperar
END;


Function InfoBox(S:STRING):Char;
(* Caja con mensaje, devuelve la tecla pulsada al salir *)
VAR Save:Byte;
    X,An:Byte;
    Ch:Char;
    NOWait:Boolean;
BEGIN
 NOWait:=S[1]=#255;
 IF Nowait THEN S:=Copy(S,1,255);
 Save:=TextAttr;
 X:=40-(byte(s[0])+2) DIV 2;
 An:=byte(S[0])+4;
 Window(X,10,X+An-1,10+5-1);
 TextAttr:=DEF_BOX;
 ClrScr;
 Window(1,1,80,25);
 HacerCaja(X,10,An,5,CaracGraf);
 GotoXY(X+2,10+2);Write(S);
 TextAttr:=Save;
 Descartecla;
 IF NOT Nowait THEN Infobox:=ReadKey;
 Descartecla;
 if not nowait then Barra2;
END;


PROCEDURE EDIT(S:STRING);
(* Edita el fichero S, usando el editor seleccionado o el interno *)
BEGIN
 IF Fsearch('PROJECT.DAT','.')='' THEN BEGIN
                                        INFOBOX('NO HAY PROYECTO');
                                        Exit
                                       END;
 IF (Pos('.NMP',S)<>0) OR (Pos('.MAC',S)<>0) THEN Ultimo:=S;
 IF CONFIGURACION.EDITORInterno THEN EXEC('EDNMP.EXE',S+' CSG')
                                ELSE EXEC(CONFIGURACION.EDITOR,S);
 Timercount:=Timer;
 CursorOff;
 Barra2;
END;

PROCEDURE EDITERROR;
VAR F:FILE;
BEGIN
 ErrorFound:=False;
 IF (Pos('.NMP',ErrorFile)<>0) OR (Pos('.MAC',ErrorFile)<>0) THEN Ultimo:=ErrorFile;
 IF CONFIGURACION.EDITORInterno THEN EXEC('EDNMP.EXE',ErrorFile+' CSG '+STRS(ErrorLine))
                                ELSE EXEC(CONFIGURACION.EDITOR,ErrorFile);
 Timercount:=Timer;
 Barra2;
END;

PROCEDURE FILE_BOX(S:String);
VAR S0:String[12];
BEGIN
 S0:=Seleccionar(S);
 IF (S0<>'') AND (S0<>'##') THEN EDIT(S0);
 IF S0='##' THEN InfoBox('NO HAY MAS PROCESOS');
END;

PROCEDURE NUEVOPROC;
VAR S:String;
    B:Byte;
    Code:Integer;
    T:TEXT;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,12,3,Caracgraf);
 GotoXY(6,5);
 Write(' PROCESO ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,10);
 VAL (S,B,Code);
 IF (Code<>0) THEN BEGIN
                    Barra2;
                    InfoBox('NUMERO DE PROCESO INCORRECTO');
                    Barra2;
                    Exit
                   END;
 IF (B=0) THEN BEGIN
                Barra2;
                InfoBox('RESERVADO TABLA DE RESPUESTAS');
                Barra2;
                Exit
               END;
 IF (B=64) THEN BEGIN
                 Barra2;
                 InfoBox('RESERVADO PROCESO DEL INPUT');
                 Barra2;
                 Exit
                END;
 Assign(T,S+'.NMP');
 Reset(T);
 IF IOResult=0 THEN BEGIN
                     Close(T);
                     Barra2;
                     InfoBox('PROCESO EXISTE');
                     Barra2;
                     Exit
                    END;
 Rewrite(T);
 WriteLn(T);
 WriteLn(T,'; PROCESO PARSER NMP ',version);
 WriteLn(T);
 WriteLn(T,'\PROC ',S);
 WriteLn(T);
 WriteLn(T,'-* *');
 WriteLn(T,'NOTDONE');
 WriteLn(T);
 Close(T);
 Barra2;
END;

PROCEDURE NUEVAMACRO;
VAR S:String;
    B:Byte;
    Code:Integer;
    T:TEXT;

BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,9,3,Caracgraf);
 GotoXY(6,5);Write(' MACRO ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,7);
 Barra2;
 Assign(T,Copy(S,1,5)+'.MAC');
 Reset(T);
 IF IOResult=0 THEN BEGIN
                     Close(T);
                     Barra2;
                     InfoBox('MACRO EXISTE');
                     Barra2;
                     Exit
                    END;
 Rewrite(T);
 IF IoResult<>0 THEN BEGIN
                      Barra2;
                      InfoBox('IMPOSIBLE CREAR MACRO');
                      Barra2;
                      Exit
                     END;
 WriteLn(T);
 WriteLn(T,'; MACRO PARSER NMP ',version);
 WriteLn(T);
 WriteLn(T,';MACRO: ',S);
 WriteLn(T);
 WriteLn(T,'LET 1 @1  ; Instrucci¢n in£til que evita que la macro estÇ vac°a');
 WriteLn(T);
 Close(T);
END;


PROCEDURE PROCESOS;
(* Control de men£ procesos *)
BEGIN
 IF Ultimo<>'' THEN MNPROC.Activas[2]:=$FF ELSE MNPROC.Activas[2]:=$DF;
 REPEAT
  Cursor:=MENU(2,2,MNPROC);
  CursorOff;IF cursor=-3 THEN Help('MENUPROC');
 UNTIL Cursor<>-3;
 if cursor>0 THEN Barra2;
 CursorOff;
 CASE Cursor OF
  -2..0:Exit;
  1:EDIT('R.NMP');
  2:EDIT('1.NMP');
  3:EDIT('2.NMP');
  4:EDIT('255.NMP');
  5:EDIT('I.NMP');
  6:FILE_BOX('NMP');
  7:NUEVOPROC;
  8:FILE_BOX('MAC');
  9:NUEVAMACRO;
 10:EDIT(ULTIMO);
 END;
END;

PROCEDURE IDENTIFICADORES;
BEGIN
 REPEAT
  EDIT('C.DAT');
 UNTIL TRUE
END;

PROCEDURE DEFINICIONES;
BEGIN
 REPEAT
  Cursor:=MENU(13,2,MNDEF);
  CursorOff;IF cursor=-3 THEN Help('MENUDEFI');
 UNTIL Cursor<>-3;
 if cursor>0 THEN Barra2;
 CursorOff;
 CASE Cursor OF
  -2..0:Exit;
  1:EDIT('L.DEF');
  2:EDIT('O.DEF');
  3:EDIT('V.DEF');
  4:EDIT('M.DEF');
  5:WIN;
  6:FUNCION;
  7:IDENTIFICADORES;
 END;
END;

PROCEDURE EJECUTAR;
VAR S:String;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,62,3,Caracgraf);
 GotoXY(6,5);
 Write(' EJECUTAR ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,60);
 TextAttr:=07;
 IF S<>'' THEN
  BEGIN
   ClrScr;
   EXEC(GetEnv('COMSPEC'),'/c '+S);
   Timercount:=Timer;
   StdCOlors;
   WriteLn('Pulse una tecla para volver a NMP...');
   Descartecla;
   ReadKey;
   Descartecla;
   Barra2;
  END ELSE BARRA2;
END;

FUNCTION DECHEX(A:Word):String;
VAR S:String;
    B:Word;
BEGIN
 S:='';
 WHILE A<>0 DO
  BEGIN
   B:=A MOD 16;
   A:=A DIV 16;
   CASE B OF
    0..9:S:=char(B+48)+S;
    10..15:S:=char(B+55)+S;
   END;
  END;
 IF Byte(S[0]) MOD 2=1 THEN S:='0'+S;
 IF S='' THEN S:='00';
 DECHEX:=S
END;

PROCEDURE HEX;
VAR S:String;
    A:Word;
    Code:Integer;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,8,3,Caracgraf);
 GotoXY(6,5);
 Write(' HEX ');
 REPEAT
 GotoXY(6,6);
 Write('      ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,5);
 TextAttr:=07;
 VAL (S,A,Code);
 IF Code<>0 THEN BEGIN
                  Beep;
                  Barra2;
                  Exit
                 END;
 GotoXY(6,6);
 textAttr:=DEF_BAR;
 Write(Copy(DECHEX(A)+'     ',1,5));
 Until ReadKey=#27;
 Barra2;
END;

PROCEDURE SETMAKE;
VAR S:String;
    W:Word;
    Code:Integer;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,12,3,Caracgraf);
 GotoXY(6,5);Write(' SET ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,10);
 EXEC('SETMAKE.EXE',S);
 IF Lo(DOsEXitCode)<>0 THEN InfoBox('ERROR CARGANDO SET');
 StdCOlors;
 Timercount:=Timer;
 LoadFont(CONFIGURACION.FONT);
 Barra2;
END;


PROCEDURE FLIBREAK;
VAR S:String;
    F:FILE;
    L:LongInt;
    W:Word;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,12,3,Caracgraf);
 GotoXY(6,5);Write(' N# FLI ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,10);
 IF FSearch('ADV\'+S+'.FLI','')<>'' THEN BEGIN
                                          TEXTATTR:=DEF_COLOR;
                                          GotoXY(6,9);
                                          Write('FICHERO ',S,'.FLI VA A SER CORROMPIDO. ®ESTA SEGURO? [ ]');
                                          CursorOn;
                                          GotoXY(Wherex-2,Wherey);
                                          IF UpCase(readKey)='S' THEN
                                           BEGIN
                                            Assign(F,'ADV\'+S+'.FLI');
                                            Reset(F,1);
                                            W:=$7119;
                                            BlockRead(F,L,4);
                                            BlockWrite(F,W,2);
                                            Close(F);
                                           END;
                                         END ELSE BEGIN
                                                   Barra2;
                                                   InfoBox(' FICHERO NO SE ENCUENTRA ');
                                                  END;

 Barra2;
END;


PROCEDURE ICON;
BEGIN
 EXEC('ICON.EXE','');
 StdCOlors;
 Timercount:=Timer;
 LoadFont(CONFIGURACION.FONT);
 IF DosExitCode<>0 THEN ReadKey;
 Barra2
END;

PROCEDURE KEY;
BEGIN
 EXEC('KEY.EXE','');
 Timercount:=Timer;
 Barra2
END;

PROCEDURE SBMCOMP;
BEGIN
 EXEC('SBMCOMP.EXE','');
 LoadFont(Configuracion.font);
 StdCOlors;
 cursoroff;
 Timercount:=Timer;
 Barra2
END;

PROCEDURE GRAB;
BEGIN
 EXEC('GRAB.EXE','');
 StdCOlors;
 Timercount:=Timer;
 LoadFont(CONFIGURACION.FONT);
 IF DosExitCode<>0 THEN ReadKey;
 Barra2
END;

PROCEDURE SVGA;
BEGIN
 CHDIR('ADV');
 EXEC('SVGASET.EXE','');
 Timercount:=Timer;
 CHDIR('..');
 Barra2
END;


PROCEDURE UTILIDADES;
BEGIN
 REPEAT
 Cursor:=MENU(46,2,MNUTIL);
  CursorOff;IF cursor=-3 THEN Help('MENUUTIL');
 UNTIL cursor<>-3;
 if cursor>0 THEN Barra2;
 CursorOff;
 CASE Cursor OF
  -2..0:Exit;
  1:EJECUTAR;
  2:SETMAKE;
  3:ICON;
  4:KEY;
  5:SBMCOMP;
  6:FLIBREAK;
  7:Hex;
  8:Grab;
  9:EDIT('NOTAS.TXT');
 END;
END;

PROCEDURE FONT;
VAR S:String;
    F:FILE;

BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,20,3,Caracgraf);
 GotoXY(6,5);
 Write(' FICHERO ');
 GotoXY(6,6);
 S:=CONFIGURACION.FONT;
 ReadLn2(S,18);
 IF Pos('.',S)=0 THEN S:=S+'.FNT';
 Assign(F,S);
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      Barra2;
                      BEEP;
                      INFOBOX('NO SE ENCUENTRA FICHERO');
                     END
                ELSE BEGIN
                      Close(F);
                      S:=Copy(S,1,Pos('.',S)-1);
                      CONFIGURACION.FONT:=S;
                      LoadFont(S);
                     END;
 Grabar_Configuracion;
 Barra2;
END;

PROCEDURE EDIT_CONF;
VAR S:String;
    F:FILE;

BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,60,3,Caracgraf);
 GotoXY(6,5);Write(' EDITOR ');
 GotoXY(6,6);
 S:=CONFIGURACION.EDITOR;
 ReadLn2(S,58);
 IF Pos('.',S)=0 THEN S:=S+'.EXE';
 CONFIGURACION.EDITOR:=S;
 Assign(F,S);
 reset(F,1);
 IF IOresult<>0 THEN BEGIN
                      Barra2;
                      Configuracion.EditorInterno:=true;
                      InfoBox('NO SE ENCUENTRA EDITOR');
                     END
                 ELSE Close(F);
 Barra2;
END;

PROCEDURE MEMORIA;
VAR F:FILE;
    S:String;
    W:Word;
    A1,A2:Byte;
    Code:Integer;
    HEAD:ARRAY[1..12] OF Byte;
BEGIN
 TEXTATTR:=DEF_BAR;
 Assign(F,'ADV\TESTER.EXE');
 Reset(F,1);
 BlockRead(F,HEAD,12);
 BlockRead(F,A2,1);
 BlockRead(F,A1,1);
 Close(f);
 W:=A1*256+A2;
 STR(W,S);
 HacerCaja(5,5,12,3,Caracgraf);
 GotoXY(6,5);
 Write(' PARRAFOS ');
 GotoXY(6,6);
 ReadLn2(S,10);
 VAL(S,W,Code);
 IF Code<>0 THEN BEGIN
                  Barra2;
                  InfoBox('VALOR INVALIDO');
                  Barra2;
                  Exit
                 END;
 Assign(F,'ADV\TESTER.EXE');
 Reset(F,1);
 BlockRead(F,HEAD,12);
 A1:=(W AND $FF00) SHR 8;
 A2:=(W AND $FF);
 BlockWrite(F,A2,1);
 BlockWrite(F,A1,1);
 Close(F);
 Barra2;
END;



PROCEDURE DEFMACRO;
var ch:char;
ext:boolean;
explor,exp2,camb:byte;
f:file;
s:string;
Buffer:ARRAY[0..31] OF Byte;
BPTR:Byte;

Procedure PutinBuffer(A,B:Byte);
BEGIN
 IF BPTR>31 THEN Beep
            ELSE BEGIN
                  Buffer[BPTR]:=A;
                  Buffer[BPTR+1]:=B;
                  INC(BPTR,2);
                 END;
END;

BEGIN
 BPTR:=0;
 Barra2;
 TextAttr:=Def_Color;
 GotoXY(3,4);
 WriteLn('Pulse la combinaci¢n Ctrl+Tecla deseada, pulse Ctrl+F10 para abortar');
 REPEAT
 UNTIL Tomatecla(ch,ext,explor,camb);
 IF NOT (EXT AND (EXPLOR IN [84..93,135,136])) THEN BEGIN
                          Beep;
                          Barra2;
                          Exit;
                         END;
 GotoXY(3,4);
 Write('Pulse las teclas que forman la macro, pulse de nuevo la tecla para terminar.');
 exp2:=explor;
 Explor:=0;
 REPEAT
  REPEAT UNTIL TomaTecla(ch,ext,explor,camb);
  IF BPTR<=29 THEN BEGIN
                    Sound(1000);
                    Delay(100);
                    Nosound;
                   END
              ELSE IF NOT (Ext AND (eXplor=exp2)) THEN BEGIN
                    Sound(100);
                    Delay(100);
                    Nosound;
                   END;


  IF Ext AND (Explor<>Exp2) THEN PutInBuffer(0,Explor);
  IF NOT Ext THEN PutinBuffer(Byte(ch),0);

 UNTIL Ext AND (Explor=Exp2);
 TimerCount:=Timer;
 STR(Exp2,S);
 Assign(F,S+'.KBD');
 Rewrite(F,1);
 BlockWrite(F,BPTR,1);
 BlockWrite(F,Buffer,32);
 Close(F);
 Barra2;
END;


PROCEDURE SETUP;
BEGIN
 IF Fsearch(CONFIGURACION.EDITOR,'')='' THEN MNSETUP.Activas[1]:=$F7
                                        ELSE MNSETUP.Activas[1]:=$FF;
 REPEAT
 Cursor:=MENU(59,2,MNSETUP);
  CursorOff;IF cursor=-3 THEN Help('MENUSETU');
 UNTIL cursor<>-3;
 CursorOff;
 if cursor>0 THEN Barra2;
 CASE Cursor OF
  -2..0:Exit;
  1:MEMORIA;
  2:FONT;
  3:EDIT_CONF;
  4:CONFIGURACION.EditorInterno:=NOT CONFIGURACION.EditorInterno;
  5:SVGA;
  6:DEFMACRO;
  7:BEGIN
     About2;
     Descartecla;
     ReadKey;
     Descartecla;
     Barra2;
     TimerCount:=Timer;
    END;
 END;
END;


PROCEDURE ValidateTo(S:String);
VAR TMP:Text;
    L:String;
    F:FILE;

LABEL ACABA;
BEGIN
 Assign(TMP,'NMC.TMP');
 Reset(TMP);
 WHILE NOT EOF(TMP) DO
  BEGIN
   ReadLn(TMP,L);
   IF L=S THEN GOTO ACABA;
   Assign(F,L);
   SetFAttr(F,0);
  END;
 ACABA:
 Close(TMP);
END;


PROCEDURE ReadError;
VAR TMP:Text;
    S:String;
    F:FILE;
BEGIN
 ErrorFound:=True;
 Assign(F,'ERROR.TMP');
 Reset(F,1);
 BlockRead(F,S,81);
 BlockRead(F,ErrorLine,4);
 Close(F);
 Erase(F);
 TextAttr:=$4E;
 Window(1,1,80,25);
 GotoXY(1,24);
 Write('Error en l°nea ',ErrorLine,' : ',S);Clreol;
 textAttr:=$1f;
END;

PROCEDURE StoreError(W:Word);
VAR TMP:Text;
    S:String;
    F:FILE;
BEGIN
 ErrorFound:=True;
 Assign(F,'ERROR.TMP');
 Reset(F,1);
 BlockRead(F,ErrorFile,13);
 BlockRead(F,S,81);
 BlockRead(F,ErrorLine,4);
 Close(F);
 Erase(F);
 IF ErrorFile<>'C.DAT' THEN ValidateTo(ErrorFile);
 (* Coge todos los ficheros en NMC.TMP antes del especificado y los valida *)
 Window(1,1,80,25);
 TextAttr:=$4E;
 GotoXY(1,24);
 Write('Error en l°nea ',ErrorLine,' : ',S);Clreol;
 textAttr:=$1f;
 {Readkey;}
END;

PROCEDURE NoError;
BEGIN
 ErrorFound:=False;
 ValidateTo('TODOS');
END;


PROCEDURE COMP(St:String;W:Byte);
VAR S:SearchRec;
    F:FILE;
    TMP:text;
    Count:WorD;
BEGIN
 Count:=0;
 Assign(TMP,'NMC.TMP');
 Rewrite(TMP);
 FindFirst(St,W,S);
 WHILE NOT ((DosError<>0) OR (S.Attr AND W = W)) DO FindNext(S);
 WHILE DOSError=0 DO
  BEGIN
   Inc(COunt);
   WriteLn(TMP,S.Name);
   Findnext(S);
   WHILE NOT ((DosError<>0) OR (S.Attr AND W = W)) DO FindNext(S);
  END;
  Close(TMP);
  EXEC('NMC.EXE',STRS(COunt)+' CSG');
  Timercount:=Timer;
  IF FSearch('ERROR.TMP','')<>'' THEN STOREError(W)
                                 ELSE NoError;
END;

PROCEDURE MAKEV(W:Byte);
VAR S:SearchRec;
    F:FILE;
BEGIN
 FindFirst('V.DEF',W,S);
 WHILE NOT ((DosError<>0) OR (S.Attr AND W = W)) DO FindNext(S);
 WHILE DOSError=0 DO
  BEGIN
   IF S.Name[1] IN ['A'..'Z'] THEN INC(byte(S.Name[1]),32);
   IF True THEN BEGIN
                       EXEC('MODO2.OVR',S.NAME[1]+' CSG');
                       Timercount:=Timer;
                       IF FSearch('ERROR.TMP','')<>'' THEN BEGIN
                                        ErrorFile:=S.NAME;
                                        S.Name[1]:=UpCASE(S.Name[1]);
                                        Assign(F,S.NAME);
                                        SetFAttr(F,W);
                                        ErrorFound:=True;
                                        ReadError;
                                        Exit
                                       END
                                  ELSE BEGIN
                                        Assign(F,S.Name);
                                        SetFAttr(F,0);
                                       END;
                      END;
   WHILE NOT ((DosError<>0) OR (S.Attr AND W = W)) DO FindNext(S);
   Findnext(S);
  END;
END;
PROCEDURE MAKE(W:Byte);
VAR S:SearchRec;
    F:FILE;
BEGIN
 FindFirst('*.DEF',W,S);
 WHILE NOT ((DosError<>0) OR (S.Attr AND W = W)) DO FindNext(S);
 WHILE DOSError=0 DO
  BEGIN
   IF S.Name[1] IN ['A'..'Z'] THEN INC(byte(S.Name[1]),32);
   IF S.Name<>'v' THEN BEGIN
                       EXEC('MODO2.OVR',S.NAME[1]+' CSG');
                       Timercount:=Timer;
                       IF FSearch('ERROR.TMP','')<>'' THEN BEGIN
                                        ErrorFile:=S.NAME;
                                        S.Name[1]:=UpCASE(S.Name[1]);
                                        Assign(F,S.NAME);
                                        SetFAttr(F,W);
                                        ErrorFound:=True;
                                        ReadError;
                                        Exit
                                       END
                                  ELSE BEGIN
                                        Assign(F,S.Name);
                                        SetFAttr(F,0);
                                       END;
                      END;
   WHILE NOT ((DosError<>0) OR (S.Attr AND W = W)) DO FindNext(S);
   Findnext(S);
  END;
END;


PROCEDURE COMPILE(W:Byte;WaitKey:Boolean);
VAR I:Byte;
BEGIN
 IF Fsearch('PROJECT.DAT','.')='' THEN BEGIN
                                        INFOBOX('NO HAY PROYECTO');
                                        Exit
                                       END;
 ErrorFound:=False;
 TextAttr:=DEF_BAR;
 HacerCaja(30,8,20,7,Caracgraf);
 GotoXY(35,8);
 Write(' COMPILAR ');
 Window(31,9,48,13);
 FOR I:=1 TO 5 DO BEGIN
                   GotoXY(1,I);
                   ClrEol;
                  END;
 GotoXY(1,1);
 Write('Vocabulario....');
 MAKEV(W);
 IF ErrorFound THEN BEGIN
                     Window(1,1,80,25);
                     EDITERROR;
                     Exit
                    END;
 WriteLn('OK.');
 Write('Macros.........');
 COMP('*.MAC',W);
 WriteLn('OK.');
 Write('Definiciones...');
 MAKE(W);
 IF ErrorFound THEN BEGIN
                     Window(1,1,80,25);
                     EDITERROR;
                     Exit
                    END;
 WriteLn('OK.');
 Write('Procesos.......');
 COMP('*.NMP',W);
 IF ErrorFound THEN BEGIN
                     Window(1,1,80,25);
                     EDITERROR;
                     Exit
                    END;
 WriteLn('OK.');
 WriteLn;
 WriteLn('     FICHEROS ');
 WriteLn('    COMPILADOS');
 Descartecla;
 IF Waitkey THEN ReadKey; (* Si se compila debido a una orden "RUN" no se
                             espera tecla *)
 Descartecla;
 Barra2;
 Window(1,1,80,25);
END;

PROCEDURE NEWPROJECT;
VAR S:String;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,12,3,Caracgraf);
 GotoXY(6,5);Write(' PROYECTO ');
 GotoXY(6,6);Write('          ');
 GotoXY(6,6);
 S:='';
 ReadLn2(S,8);
 IF S='' THEN BEGIN
               Barra2;
               EXIT;
              END;
 MKDIR(S+'.PRJ');
 IF IOResult<>0 THEN BEGIN
                      Barra2;
                      Infobox('NOMBRE NO VALIDO O REPETIDO');
                      barra2;
                      exit;
                     END;
 CHDIR(S+'.PRJ');
 Barra2;
 InfoBox(#255+'CREANDO NUEVO PROYECTO');
 SetOutPut('NUL');
 EXEC('..\INITDATA.DTA','');
 CancelOutput;
 CHDIR('..');
 Timercount:=Timer;
 Barra2;
END;

PROCEDURE EraseDir(D:String);
VAR S:Searchrec;
    F:FILE;
    Q:Byte;
BEGIN
 FindFirst(D,Anyfile,S);
 WHILE DosError=0 DO
  BEGIN
   IF (S.Name<>'.') AND (S.Name<>'..') THEN BEGIN
                                             Assign(F,S.name);
                                             Erase(F);
                                             Q:=IOresult;
                                            END;
   FindNext(S);
  END;
END;

PROCEDURE Mover(Spec:String;Dest:String);
VAR S:Searchrec;
    F,g:FILE;
    dir,name,ext:String;
BEGIN
 Fsplit(Spec,dir,name,ext);
 FindFirst(Spec,Anyfile,S);
 WHILE DosError=0 DO
  BEGIN
   Assign(F,Dir+S.Name);
   Rename(F,Dest+'\'+S.name);
   IF IOResult=5 THEN BEGIN
                       Assign(G,Dest+'\'+S.Name);
                       Erase(G);
                       Rename(F,Dest+'\'+S.name);
                      END;
   FindNext(S);
  END;
END;

PROCEDURE SAVEPROJECT(Proj:String);
VAR S:SearchRec;
BEGIN
 INFOBOX(#255+'GRABANDO PROYECTO ACTIVO');
 EraseDir(Proj+'\*.*');
 Mover('*.NMP',Proj);
 Mover('*.PN',Proj);
 Mover('*.DEF',Proj);
 Mover('*.MAC',Proj);
 Mover('*.MCP',Proj);
 Mover('*.CNV',Proj);
 Mover('*.SBP',Proj);
 Mover('C.DAT',Proj);
 Mover('NOTAS.TXT',Proj);
 Mover('ADV\*.EXE',Proj);
 Mover('ADV\*.FNT',Proj);
 Mover('ADV\*.IDX',Proj);
 Mover('ADV\*.PAK',Proj);
 Mover('ADV\*.DAT',Proj);
 Mover('ADV\*.DTT',Proj);
 Mover('ADV\*.XMP',Proj);
 Mover('ADV\*.TLK',Proj);
 Mover('ADV\*.ICO',Proj);
 Mover('ADV\*.PCX',Proj);
 Mover('ADV\*.TWK',Proj);
 Mover('ADV\*.SND',Proj);
 Mover('ADV\*.SBM',Proj);
 Mover('ADV\*.SFX',Proj);
 Mover('ADV\*.PAL',Proj);
 Mover('ADV\*.DRV',Proj);
 Mover('ADV\*.CON',Proj);
 barra2;
END;

PROCEDURE RESTOREPROJECT(proj:String);
VAR S:Searchrec;
    F:FILE;
BEGIN
 INFOBOX(#255+'CARGANDO PROYECTO');
 EraseDir('ADV\*.PCX');
 EraseDir('ADV\*.TWK');
 EraseDir('ADV\*.IDX');
 EraseDir('ADV\*.PAK');
 EraseDir('ADV\*.DAT');
 EraseDir('ADV\*.DTT');
 EraseDir('ADV\*.XMP');
 EraseDir('ADV\*.ico');
 EraseDir('ADV\*.sbm');
 EraseDir('ADV\*.snd');
 EraseDir('ADV\*.sfx');
 EraseDir('ADV\*.tlk');
 EraseDir('ADV\*.fnt');
 EraseDir('ADV\*.drv');
 EraseDir('ADV\*.pal');
 EraseDir('*.DEF');
 EraseDir('*.NMP');
 EraseDir('*.PN');
 EraseDir('*.MAC');
 EraseDir('*.MCP');
 EraseDir('*.CNV');
 EraseDir('*.SBP');
 Mover(Proj+'\*.NMP','.');
 Mover(Proj+'\*.PN','.');
 Mover(Proj+'\*.MAC','.');
 Mover(Proj+'\*.MCP','.');
 Mover(Proj+'\*.CNV','.');
 Mover(Proj+'\*.DEF','.');
 Mover(Proj+'\C.DAT','.');  {Atenci¢n, C.DAT es el £nico que ha de ir al base de NMP }
 Mover(Proj+'\NOTAS.TXT','.');
 Mover(Proj+'\*.SBP','.');
 Mover(Proj+'\*.FNT','ADV');
 Mover(Proj+'\*.CON','ADV');
 Mover(Proj+'\*.EXE','ADV');
 Mover(Proj+'\*.IDX','ADV');
 Mover(Proj+'\*.PAK','ADV');
 Mover(Proj+'\*.DAT','ADV');
 Mover(Proj+'\*.DTT','ADV');
 Mover(Proj+'\*.XMP','ADV');
 Mover(Proj+'\*.TLK','ADV');
 Mover(Proj+'\*.DRV','ADV');
 Mover(Proj+'\*.PAL','ADV');
 Mover(Proj+'\*.SFX','ADV');
 Mover(Proj+'\*.SBM','ADV');
 Mover(Proj+'\*.SND','ADV');
 Mover(Proj+'\*.TWK','ADV');
 Mover(Proj+'\*.PCX','ADV');
 Mover(Proj+'\*.ICO','ADV');
 Barra2;
END;

PROCEDURE OPENPROJECT;
VAR S,OldProject:String;
    T:Text;
    F:FILE;
BEGIN
 OLdProject:='';
 S:=GetProject;
 IF Pos('.PRJ',S)=0 THEN Exit;
 INFOBOX(#255+'CARGANDO PROYECTO');
 Assign(F,'EDNMP.OVR');
 Erase(F);
 IF IOResult<>0 THEN;
 Assign(T,'PROJECT.DAT');
 reset(T);
 IF IOResult=0 THEN BEGIN
                      ReadLn(T,OldProject);
                      IF OldProject<>S THEN SAVEPROJECT(Oldproject);
                      Close(T);
                     END;
 Rewrite(T);
 WriteLn(T,S);
 Close(T);
 IF OldProject<>S THEN RestoreProject(S);
 barra2;
END;

PROCEDURE COMPILAR;
BEGIN
 REPEAT
  Cursor:=MENU(28,2,MNCOMP);
  CursorOff;IF cursor=-3 THEN Help('MENUCOMP');
 UNTIL cursor<>-3;
 if cursor>0 then Barra2;
 CursorOff;
 CASE Cursor OF
  -2..0:Exit;
  1:OPENPROJECT;
  2:NEWPROJECT;
  3:COMPILE(32,true);
  4:COMPILE(0,true);
 END;
END;

PROCEDURE LINEACOMANDOS;
VAR S:String;
    F:FILE;
BEGIN
 TEXTATTR:=DEF_BAR;
 HacerCaja(5,5,42,3,Caracgraf);
 GotoXY(6,5);
 Write(' LINEA COMANDOS ');
 GotoXY(6,6);
 S:=CONFIGURACION.LINEAParam;
 UpSt(S);
 ReadLn2(S,40);
 LowSt(S);
 CONFIGURACION.LineaParam:=S;
 Barra2;
END;


FUNCTION FindArchive:Boolean;
VAR S:Searchrec;
BEGIN
 FindArchive:=True;
 FindFirst('*.NMP',ARCHIVE,S);
 WHILE NOT ((DosError<>0) OR (S.Attr=32)) DO FindNext(S);
 IF DosError=0 THEN Exit;
 FindFirst('*.DEF',ARCHIVE,S);
 WHILE NOT ((DosError<>0) OR (S.Attr=32)) DO FindNext(S);
 IF DosError=0 THEN Exit;
 FindFirst('*.MAC',ARCHIVE,S);
 WHILE NOT ((DosError<>0) OR (S.Attr=32)) DO FindNext(S);
 IF DosError=0 THEN Exit;
 FindArchive:=False;
END;

PROCEDURE TESTER(S:STRING);
VAR CH:Char;
BEGIN
 Ch:='S';
 IF FindArchive THEN (* Si hay alguno con atributo ARCHIVE *)
                 BEGIN
                  Compile(32,false);
                  IF FindArchive thEN BEGIN
                                       Barra2;
                                       Exit
                                      END;
                 END;
 CHDIR('ADV');
 TextAttr:=$7;
 ClrScr;
 EXEC('TESTER.EXE',CONFIGURACION.LINEAParam+S);
 StdCOlors;
 Timercount:=Timer;
 IF DosExitCode<>0 THEN ReadKey;
 CHDIR('..');
 LoadFont(CONFIGURACION.FONT);
 Barra2;
END;


PROCEDURE TEST;
BEGIN
 REPEAT
  Cursor:=MENU(39,2,MNTEST);
  CursorOff;IF cursor=-3 THEN Help('MENUTEST');
 UNTIL cursor<>-3;
 CursorOff;
 if cursor>0 THEN Barra2;
 CASE Cursor OF
  -2..0:Exit;
  1:TESTER(' C'+'S'+'G');
  2:TESTER('');
  3:TESTER(' G'+'S'+'C');
  4:LINEACOMANDOS;
 END;
END;


PROCEDURE IFEDIT(N:Byte); (* Edita si existe *)
VAR S:String;
    F:FILE;
BEGIN
 IF N=0 THEN N:=10;
 STR(N,S);
 S:=S+'.NMP';
 Assign(F,S);
 Reset(F,1);
 IF IOResult=0 THEN Close(F)
               ELSE Exit;
 EDIT(S)
END;


PROCEDURE MAINMENU;
VAR Ch:Char;
    Ext:Boolean;
    Explor,Camb:Byte;
BEGIN
 Barra;
 About1;
 TimerCount:=Timer;
 Descartecla;
 Barra2;
 Ch:=#0;
 REPEAT
  REPEAT
   TextAttr:=$70;
   IF TimerCount+540<Timer THEN SP;
  UNTIL TomaTecla(Ch,Ext,Explor,Camb);
  TimerCount:=Timer;
  REPEAT
   Cursor:=0;
   CASE UpCase(Ch) OF
    'P':PROCESOS;
    'D':DEFINICIONES;
    'S':SETUP;
    'C':COMPILAR;
    'T':TEST;
    'U':UTILIDADES;
   END;
  IF Cursor<0 THEN IF Cursor=-2 THEN
                    CASE UpCase(Ch) OF
                     'P':Ch:='D';
                     'D':Ch:='C';
                     'C':Ch:='T';
                     'T':Ch:='U';
                     'U':Ch:='S';
                     'S':Ch:='P'
                    END
              ELSE CASE UpCase(Ch) OF
                     'P':Ch:='S';
                     'D':Ch:='P';
                     'C':Ch:='D';
                     'T':Ch:='C';
                     'U':Ch:='T';
                     'S':Ch:='U'
                    END;
  IF Cursor=0 THEN Barra2;
  UNTIL Cursor>=0;
 IF Ext THEN CASE Explor OF
                   50:EDIT('M.DEF');
                   47:EDIT('V.DEF');
                   49:EDIT('NOTAS.TXT');
                   38:EDIT('L.DEF');
                   24:EDIT('O.DEF');
                   19:EDIT('R.NMP');
                   23:EDIT('I.NMP');
                   59:Help('PRINCIPAL');
                   33:FUNCION;
                   17:WIN;
                   46:EDIT('C.DAT');
                   22:IF Ultimo<>'' THEN EDIT(ULTIMO) ELSE Beep;
                   25:FILE_BOX('NMP');
                   63:TESTER(' C'+'S'+'G');
                   67:Compile(32,true);
                   104..113:IFEDIT(Explor-103);
                   120:EDIT('1.NMP');
                   121:EDIT('2.NMP');
                   124:EDIT('255.NMP');
                   84..93,135,136:TRYKBDMACRO(Explor);
                  END;
 UNTIL Ext AND (Explor=45); (* Alt-X *)
END;

PROCEDURE SET_TEMP;
VAR F:FILE;
BEGIN
 TEMP:=GetEnv('TEMP');
 IF TEMP[byte(TEMP[0])]<>'\' THEN TEMP:=TEMP+'\';
 Assign(F,TEMP+'NMP.$$$');
 Rewrite(F,1);
 IF IOresult<>0 THEN BEGIN
                      TEMP:='';
                      Exit
                     END;
 Close(F);
 Erase(F)
END;

PROCEDURE CHECKCDROM;
VAR F:FILE;
BEGIN
 Assign(F,'NMP.TMP');
 Rewrite(F,1);
 IF IOResult<>0 THEN
 BEGIN
 cursoroff;
 TextAttr:=$1f;
 clrscr;
 write ('€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€    NMP ·5.0   €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€');
 Textattr:=$0F;
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                      ATENCION                    ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ NMP encontr¢ imposible escribir en el disco duro ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ lo cual puede desembocar  en  un  comportamiento ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ err¢neo. El problema  puede  estar  causado  por ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫ tratar de ejecutar NMP desde un CD-ROM.          ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±∫                                                  ∫∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 write ('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
 textAttr:=$07;
 WriteLn;
 Clreol;
 Readkey;
 END ELSE BEGIN
           Close(F);
           Erase(F);
          END;
 GotoXY(1,Wherey-1);
END;

BEGIN (* PRINCIPAL *)
 CheckCDROM;
 MKDIR('ADV');
 IF IOresult<>0 THEN;
 IF ChipType<380 then Error(3); (* 386 o superior!! *)
 InstalarSalvaPantallas(SP);
 (* INICIALIZACIONES *)
 Ultimo:='';
 CheckBreak:=False;
 SET_TEMP;
 ASM
  mov bl,30h
  MOV AX,1802h
  int 10h
  MOV AX,3
  INT 10h
 END;
 StdCOlors;
 CursorOff;
 TextAttr:=$07;
 FillChar(SPACES[1],255,32);
 SPACES[0]:=Char($FF);
 CONFIGURAR;
 InsertMode:=True;
 IF FSearch('BETA.FIL','')<>'' THEN BETA;
 Free:=DiskFree(0);
 IF Free<1000000 THEN DISCOLLENO;
 Assign(F,TEMP+'NMP.$$$');
 Rewrite(F,1);
 FillChar(Mem[$a000:0],40960,0);
 BlockWrite(F,Mem[$a000:0],40960);
 Close(F);
 IF (Free-DiskFree(0)<35000) AND (DiskFree(0)<1500000) THEN DOUBLESPACE;
 (* Sistema cutre para detectar un doblador de disco, aunque el caso es
    que me ha funcionado con SSTOR, Stacker y Doublespace *)
 Assign(F,TEMP+'NMP.$$$');
 Erase(F);
 IF IOResult<>0 THEN BEGIN END; (* Borro flag error interno *)
 LoadFont(CONFIGURACION.FONT);
 MAINMENU;
 (* SALIDA *)
 INC(COnfiguracion.TimesExec);
 GRABAR_CONFIGURACION;
 LoadFont('NORMAL');
 CursorOn;
 TextAttr:=$07;
 ClrScr;
 ASM
  mov ax,3
  int 10h
 end;
 TextAttr:=$1F;
 Write('     ',anno,'  Creador de Aventuras Conversacionales de NM Software  Versi¢n ',version,'   ');
 TextAttr:=$07;
 IF (CONFIGURACION.TimesExec MOD 15)=0 THEN BEGIN
                                             WriteLn;
                                             WriteLn('NO OLVIDE GRABAR LA BASE DE DATOS EN DISQUETE PERIODICAMENTE.');
                                            END;
END.
