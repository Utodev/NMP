
(*****************************)
(*  WARNING  : SEGMENT VIDEO *)
(*****************************)

{$I-,R-,S-,X+}


USES NMPMENU,Crt,Dos,Paracaja;

TYPE Tintas=(normal,letras,cadena,indireccion,numero,entrada,comentario,nombreproc,llave,constante);

CONST INKS:ARRAY[normal..constante] of byte=($1F,$1F,$16,$1C,$1E,$1A,$17,$1D,$12,$15);

CONST Paleta:ARRAY[0..15] OF ARRAY[0..2] OF Byte=
      ((0,0,0),(0,0,40),(0,40,0),(0,40,40),(40,0,0),(40,0,40),(40,40,0),(40,40,40),
       (20,20,20),(0,0,63),(0,63,0),(0,63,63),(63,0,0),(63,0,63),(63,63,0),(63,63,63));

      VAR TAttr:Tintas;
          FileType:(TextoFile,procFile,constFile,defFile);

TYPE VALIDAS=SET OF CHAR;

label sigue,sigue2;

PROCEDURE SETCURSOR(A:Boolean); Assembler;
ASM
  MOV CX,0e0dh
  MOV AL,A
  OR AL,AL
  JZ @SIGUE
  MOV CL,2
 @sigue:
  MOV AH,1
  INT 10h
END;

{$I CURSOFF.SRC}
{$I Pantalla.POO}
{$I BufferRD.POO}

CONST Maxlin=1500;
      MaxLong=256;

TYPE Linea=PACKED ARRAY[1..Maxlong] OF Char;
     String20=String[20];

VAR  Nombre:String[30];
     PosFile:Word;
     AuxBusca,Busca,SaveBusca:String20;
     Modificado:Boolean;
     BF:BufferRD;
     Encontrado:Boolean;
     Size:Word;
     Aux:Integer;
     Lin,Col:integer;
     CX,CY:Integer;
     I,J:Word;
     Ch:Char;
     Extend:Boolean;
     Explor,Camb:Byte;
     TEXTO:ARRAY[1..MaxLin] OF ^Linea;
     HS:string20;
     Pant:Pantalla;
     MARCA1,MARCA2:0..MaxLin;  (* 0 es el valor cuando no hay marca *)


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


PROCEDURE LowCASE(VAR S:String); Assembler;
ASM
 LES DI,[S]
 XOR CX,CX
 MOV CL,ES:[DI]
 INC DI
 @BUCLE:
 MOV AH,ES:[DI]
 CMP AH,65
 JL @nada
 CMP AH,90
 JG @egne
 ADD AH,32
 JMP @NADA
 @egne:
 CMP AH,'¥'
 JNE @cedilla
 MOV AH,'¤'
 @cedilla:
 CMP AH,'€'
 JNE @Nada
 MOV AH,'‡'
 @NADA:
 MOV ES:[DI],AH
 INC DI
 LOOP @Bucle
END;






CONST ModoInsert:Boolean=False;
      AttrInsert:Byte=$70;


{$I TOMATEC.SRC}

PROCEDURE Error(S:String);
BEGIN
 WriteLn(S,'.');
 Halt
END;

FUNCTION LEN(VAR S:Linea):Word; Assembler;
ASM
 PUSH DX
 MOV AX,0
 MOV DX,0
 MOV CX,MaxLong
 LES DI,[S]
 @BUCLE:
 MOV BH,ES:[DI]
 INC DI
 INC DX
 CMP BH,32
 JE @NOMAS
 MOV AX,DX
 @NOMAS:
 LOOP @BUCLE
 INC AX
 POP DX
END;



PROCEDURE ReadLn2(VAR S:String;long:Byte);
VAR C:Char;
    Ex:Boolean;
    Exp,Camb:Byte;
    X,Y:Byte;
    I:Byte;
    Car:Byte;
    SaveColor:Byte;

BEGIN
X:=WhereX;
Y:=WhereY;
Car:=1;
IF S[length(S)]<>' ' THEN S:=S+' ';
REPEAT
C:='þ';
IF TomaTecla(C,Ex,Exp,Camb) THEN
 BEGIN
  IF (C<>'þ') AND (length(s)<long-1) AND (c>=' ') THEN
    BEGIN
     Insert(C,S,car);
     Inc(car)
    END;
  IF (C=#8) AND (car>1) THEN
                         BEGIN
                          Delete(S,car-1,1);
                          DEC(car)
                         END;
  IF Ex AND (Exp=83) AND (car<>length(s)) THEN
       Delete(S,car,1);
  IF Ex AND (Exp=72) AND (car>76) THEN DEC(Car,76);
  IF Ex AND (Exp=80) AND (length(s)>=car+76) THEN INC(Car,76);
  IF Ex AND (Exp=77) AND (car<>length(s)) THEN INC(car);
  IF Ex AND (Exp=75) AND (car>1) THEN DEC(CAR);
  IF Ex AND (Exp IN [84..93,135,136]) THEN TryKbdMacro(Exp);
 END;
GotoXY(X,Y);
Write(Copy(s,1,car-1));
TextAttr:=$71;
Write(S[Car]);
Textattr:=$70;
Write(Copy(s,car+1,length(s)));
clreol;
UNTIL (C=#13);
S:=Copy(S,1,length(s)-1);
GotoXY(1,Wherey+1);
END;

PROCEDURE SetRGB(n,r,g,b:byte); assembler;
asm
{Mov dx,03c8h;
Mov al,n;
Out dx,al;
Inc dx;
Mov al,r;
Out dx,al;
Mov al,g;
Out dx,al;
Mov al,b;
Out dx,al;}
end;


PROCEDURE Mostrar;
VAR I : Word;
    J:Byte;
    S : String;
    A:Char;
    K:Word;
BEGIN
 Window(1,1,80,25);
 CursorOff;
 GotoXY(4,23); IF Modificado THEN Write(#15);
 GotoXY(6,23);
 Write(' ',CY,':',CX,' ÍÍÍÍÍ');
 GotoXY(25,23);
 Window(3,4,78,21);
 GotoXY(1,1);
 Tattr:=Normal;
 TextAttr:=INKS[Tattr];
 FOR I:=lin TO lin+16 DO
  BEGIN
   TextAttr:=INKS[Normal];
   IF (I<=MARCA2) AND (I>=MARCA1) THEN TextAttr:=$70;
   IF (I<MaxLin) AND (Texto[I]<>NIL) THEN
    BEGIN
     IF Col>MaxLong-75 THEN J:=Maxlong-Col
                       ELSE J:=75;
     TAttr:=Normal;
     FOR K:=1 TO MaxLong DO
      BEGIN
        A:=TEXTO[I]^[K];
        IF FileType=ProcFile THEN
         CASE A OF
          '{':IF TAttr<>Comentario THEN A:='þ';
          '}':IF TAttr=Cadena THEN Tattr:=Normal;
          '\':IF (Tattr<>Comentario) AND (Tattr<>cadena) THEN TAttr:=NombreProc;
          '-':IF (Tattr<>Comentario) AND (Tattr<>cadena) THEN Tattr:=Entrada;
          ';':IF Tattr<>cadena THEN Tattr:=Comentario;
          '#':IF (Tattr<>Comentario) AND (Tattr<>cadena) THEN Tattr:=Constante;
          '@':IF (Tattr<>Comentario) AND (Tattr<>cadena) THEN Tattr:=Indireccion;
          '0'..'9': IF NOT (Tattr IN [Comentario,letras,indireccion,constante,cadena])
                     THEN Tattr:=numero;
          'a'..'z','A'..'Z': IF Tattr=Normal THEN Tattr:=Letras;
          ' ':IF NOT (Tattr IN [comentario,cadena,constante,entrada,nombreproc])
                 THEN Tattr:=Normal
         END;
         IF FileType=ConstFile THEN
          IF A=';' THEN Tattr:=Comentario;

         IF FileType=DefFile THEN
          CASE A OF
          '{','}':
          tattr:=llave
          ELSE tattr:=normal;
          END;

         TextAttr:=INKS[TAttr];

        IF (K>=COl) AND (K<=J-1+COL-1) THEN IF A='þ' THEN BEGIN
                                 Write('{');
                                 TAttr:=Cadena;
                                 TextAttr:=INKS[Tattr]
                                END ELSE Write(a)
                 ELSE IF A='þ' THEN BEGIN
                                     TAttr:=Cadena;
                                     TextAttr:=INKS[Tattr]
                                    END;

       END;
    END;
  ClrEol;
  textAttr:=$1F;
  WriteLn;
 END;
 GotoXY(CX-Col+1,CY-lin+1);
 SetCursor(ModoInsert);
END;

TYPE FILEPOS=RECORD
              CX,CY:Word;
              Lin,Col:Word;
              Name:STRING[13];
             END;
VAR Q:FILE OF FILEPOS;
    FP:FILEPOS;

PROCEDURE GrabarPosicion;
BEGIN
 FP.Lin:=Lin;
 FP.Col:=Col;
 FP.CX:=CX;
 FP.CY:=CY;
 FP.Name:=Nombre;
 Assign(Q,'EDNMP.OVR');
 Reset(Q);
 IF IOResult<>0 THEN Rewrite(Q);
 IF PosFile>0 THEN Seek(Q,PosFile);
 Write(Q,FP);
 Close(Q);
END;


PROCEDURE Cargar;
VAR F:TEXT;
    C:Word;
    S:String;

PROCEDURE GetFILEPOS;
LABEL BACK;
BEGIN
 Back:
 PosFile:=0;
 Assign(Q,'EDNMP.OVR');
 Reset(Q);
 IF IOResult<>0 THEN BEGIN
                      FP.CX:=1;
                      FP.CY:=1;
                      FP.Lin:=1;
                      FP.COl:=1;
                      FP.Name:=Nombre;
                      Exit;
                     END;
 WHILE NOT EOF(Q) DO
  BEGIN
   Read(Q,FP);
   IF IOResult<>0 THEN BEGIN
                        Close(Q);
                        Erase(Q);
                        Goto Back;
                       END;
   IF FP.Name=Nombre THEN BEGIN
                           Close(Q);
                           Exit
                          END;
  INC(PosFile);
  END;
 FP.CX:=1;
 FP.CY:=1;
 FP.Lin:=1;
 FP.COl:=1;
 FP.Name:=Nombre;
 Close(Q);
END;

BEGIN
 GETFILEPOS;
 Lin:=1;
 FillChar(texto,SizeOf(texto),0);
 Assign(F,Nombre);
 Reset(F);
 IF EOF(F) THEN Exit;
 REPEAT
  C:=0;
  New(texto[Lin]);
  FillChar(texto[Lin]^,Sizeof(linea),32);
  ReadLn(F,S);
  Move(S[1],texto[lin]^[1],byte(S[0]));
  INC(LIN);
 UNTIL EOF(F);
 Close(F);
 LIN:=Fp.Lin;
 Col:=FP.Col;
 CX:=FP.CX;
 CY:=FP.CY;
END;

PROCEDURE Beep;
BEGIN
 Sound(100);
 Delay(150);
 Nosound
END;




PROCEDURE PreguntarGrabar; forward;


PROCEDURE BufferCase;
VAR BUFF:ARRAY[1..2] OF Byte;
BEGIN
 BUFF[1]:=Byte(NOT(Extend)); Buff[2]:=Explor;
 IF Extend AND (Explor IN [50,47,38,24,19,120,121,124,23,46,25,63,67,33,17,45,49,104..113,22]) THEN
  BEGIN
   IF NOT(Explor in [63,67]) THEN PreguntarGrabar (* Si no F5 o F9 *)
                             ELSE IF Modificado THEN Explor:=60
                                                ELSE Explor:=103;
   (* Si no hizo cancelar meto en buffer de teclado *)
   IF Extend THEN PutInBuffer(Buff[1],Buff[2]);
  END;
 IF Extend AND (Explor IN [84..93,135,136]) THEN TryKBDMacro(Explor);
END;

FUNCTION Ayuda(VAR S:string20):Boolean;


TYPE Referencia=ARRAY[1..30] OF RECORD
                                 X,Y:Byte;
                                 Item:string20;
                                END;

VAR F:File;
    T:text;
    Name:String[8];
    A,b:LongInt;
    Buffer:ARRAY[1..1500] OF Char;
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
 Reset(f,1);
 Name:='#@|@#ªª';
 Bf.Inicializar(F);
 WHILE NOT Bf.EOFL(F) AND (Name<>S) DO
  BEGIN
   Bf.Leer(F,A,4);
   Bf.Leer(F,Name,9);
   Bf.Leer(F,B,4);
  END;
 Close(F);
 IF Name<>S THEN BEGIN
                  S:=Copy(S,1,length(s)-1);
                  IF S='' THEN BEGIN
                                S:='NOTFOUND';
                                Ayuda:=Ayuda(S);
                               END ELSE Ayuda:=Ayuda(S);
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
                  FOR I:=1 TO 30 DO ref[I].X:=0;
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
                    IF (Buffer[I]='|') AND (Buffer[I+1]='|') THEN BEGIN
                       Write('|');
                       INC(I)
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
                  refi:=0;
                  IF MaxRefi<>0 THEN BEGIN
                                      refi:=1;
                                      GotoXY(Ref[Refi].X,ref[refi].Y);
                                      TextAttr:=$0E;
                                      Write(Ref[Refi].item);
                                      TextAttr:=$3e;
                                     END;
                  REPEAT
                   REPEAT UNTIL Tomatecla(Ch,Extend,Explor,Camb);
                   IF (Ch=#9) AND (Maxrefi<>0) THEN BEGIN
                                  IF refi<>0 THEN BEGIN
                                                   GotoXY(Ref[Refi].X,ref[refi].Y);
                                                   TextAttr:=$3E;
                                                   Write(Ref[refi].Item);
                                                  END;
                                  Inc(refi);
                                  IF (Refi>MaxRefi) OR (ref[Refi].X=0)  THEN
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

                   IF Extend AND (Explor = 15) AND (Maxrefi<>0) THEN BEGIN
                                  IF refi<>0 THEN BEGIN
                                                   GotoXY(Ref[Refi].X,ref[refi].Y);
                                                   TextAttr:=$3E;
                                                   Write(Ref[refi].Item);
                                                  END;
                                  Dec(refi);
                                  IF (Refi IN [0,255]) OR (ref[Refi].X=0)  THEN
                                    Refi:=MaxRefi;
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
Window(3,4,78,21);
END;


{$i DESCART.SRC}

FUNCTION MONOCROMO : Boolean; Assembler;
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

CONST CONFIRMAR:MenuDef=( NOpciones: 3;
                        Long:14;
                        Exit:1;
                        Opciones: ('#Grabar cambios','#Perder Cambios','#Cancelar','','','',
                               '','','','');

                        Activas:($FF,$FF);
                        AttrMenu:$70;
                        AttrBarra:$20;
                        AttrOculto:$78;
                        AttrSombra:$08;
                        AttrAlt:$04
                        );


PROCEDURE PreguntarGrabar;
VAR LX,LY:Byte;
    S:VALIDAS;
BEGIN
 IF Not Modificado THEN BEGIN
                         Extend:=True;
                         Explor:=103;
                         Exit
                        END;
  LX:=WhereX;
  LY:=WhereY;
  Window(1,1,80,25);
  S:=['S','N'];
  CASE MENU(31,10,CONFIRMAR) OF
   1:BEGIN
       Extend:=True;
       Explor:=60;
      END;
   2:BEGIN
       Explor:=103;
       Extend:=True;
      END;
  0,3:BEGIN
       Extend:=False;
       Ch:=#0;
      END;
  END;
 Window(3,4,78,21);
 GotoXY(LX,LY);
END;

PROCEDURE Grabar;
VAR I,J:Word;
    F:TEXT;
    S:String;

BEGIN
Assign(F,Nombre);
Rewrite(F);
I:=1;
WHILE (I<=Maxlin) AND (Texto[I]<>NIL) DO
 BEGIN
  Move(texto[i]^[1],S[1],len(texto[i]^));
  Byte(S[0]):=byte(len(texto[i]^))-1;
  WriteLn(F,S);
  INC(I);
 END;
Close(F);
END;

TYPE String10=String[10];
VAR PN:File OF String10;
    NOMEN:String10;

PROCEDURE SETDAC;
VAR I:Byte;
BEGIN
ASM
 MOV CX,15
 MOV AX,1000h
@D:
 MOV BH,CL
 MOV BL,CL
 INT 10h
 LOOP @D
END;
FOR I:=0 TO 15 DO SetRGB(I,Paleta[I,0],Paleta[I,1],Paleta[I,2]);
END;


BEGIN          (* PRINCIPAL *)
{ Descartecla;}
 IF NOT Monocromo then FillChar(Inks,SizeOf(INKS),$1F);
 Marca1:=0;Marca2:=0;
 Busca:='';
 SaveBusca:='';
 Pant.Inicializar(80,25);
 IF ParamStr(2)<>'CSG' THEN BEGIN
                             WriteLn('NMP Editor V5.0');
                             WriteLn('Por Carlos S nchez.');
                             WriteLn('Este programa necesita del entorno NMP para ejecutarse');
                             WriteLn('y no puede ser llamado desde la l¡nea de comandos.');
                             Halt;
                            END;
 CursorOff;
{ SETDAC;
 SETRGB(1,0,0,020);
 SetRGB(5,63,0,10);
 SetRGB(6,0,63,63);}
 Nombre:=ParamStr(1);
 Cargar;
 IF ParamCount=3 THEN BEGIN
                       VAL(ParamStr(3),Lin,Aux);
                       CY:=Lin;
                       IF Lin>10 THEN DEC(Lin,10) ELSE Lin:=1;
                       CX:=1;
                       Col:=1;
                      END;
 TextAttr:=$1F;
 TAttr:=Normal;
 Window(1,1,80,25);
 IF Pos('.DAT',Nombre)<>0 THEN Filetype:=COnstFile
    ELSE IF Pos('.DEF',Nombre)<>0 THEN Filetype:=DefFile
     ELSE IF Pos('.NMP',Nombre)<>0 THEN Filetype:=ProcFile
      ELSE IF Pos('.MAC',Nombre)<>0 THEN Filetype:=ProcFile
       ELSE IF Pos('.TXT',Nombre)<>0 THEN Filetype:=textoFile;
 IF Pos('.DEF',Nombre)<>0 THEN BEGIN
                                IF Nombre='M.DEF' THEN Nombre:='[MENSAJES]' ELSE
                                IF Nombre='L.DEF' THEN Nombre:='[LOCALIDADES]' ELSE
                                IF Nombre='O.DEF' THEN Nombre:='[OBJETOS]' ELSE
                                IF Nombre='V.DEF' THEN Nombre:='[VOCABULARIO]'
                               END;


 IF Pos('.DAT',Nombre)<>0 THEN Nombre:='[CONSTANTES]';
 IF Pos('.MAC',Nombre)<>0 THEN Nombre:='[MACRO '+Copy(Nombre,1,Pos('.',Nombre)-1)+']';
 IF Pos('.NMP',Nombre)<>0 THEN BEGIN
                                IF NOMBRE='R.NMP' THEN Nombre:='[TABLA DE RESPUESTAS]' ELSE
                                IF NOMBRE='I.NMP' THEN Nombre:='[PROCESO DEL INPUT]' ELSE
                                 BEGIN
                                  Assign(PN,Copy(Nombre,1,Pos('.',Nombre)-1)+'.PN');
                                  InOutRes:=0;
                                  Reset(PN);
                                  IF IOResult=0 THEN BEGIN
                                                       Read(PN,NOMEN);
                                                       Close(PN);
                                                      END ELSE NOMEN:='';
                                  Nombre:='[PROCESO '+Copy(Nombre,1,Pos('.',Nombre)-1);
                                  IF NOMEN<>'' THEN Nombre:=Nombre+' : ';
                                  Nombre:=Nombre+NOMEN+']';
                                 END;
                               END;
 GotoXy(40-(length(Nombre)+2) DIV 2,2);
 Write(' ',Nombre,' ');
 Nombre:=ParamStr(1);
 Window(3,4,78,21);
 Modificado:=False;
 Mostrar;
 REPEAT
 Ch:=#254;
 Extend:=False;Explor:=0;
 IF Tomatecla(Ch,extend,explor,camb) THEN
  BEGIN

  IF (Ch IN [#32..#126,#128..#253]) THEN
   IF CX>=Maxlong-1 THEN Beep
                 ELSE IF ModoInsert THEN BEGIN
                                          Texto[CY]^[CX]:=Ch;
                                          Modificado:=True;
                                          INC(CX);
                                          IF CX-Col=75 THEN Inc(Col);
                                         END
                                     ELSE IF len(texto[CY]^)=Maxlong-1 THEN Beep
                                       ELSE BEGIN
                                             Move(Texto[CY]^[CX],Texto[CY]^[CX+1],Maxlong-CX);
                                             Modificado:=True;
                                             Texto[CY]^[CX]:=Ch;
                                             INC(CX);
                                             IF CX-Col=75 THEN Inc(Col);
                                            END;


   IF (Ch=#8) AND (CX<>1) THEN BEGIN   (* Delete *)
                                Move(texto[Cy]^[CX],texto[Cy]^[Cx-1],Maxlong-cx+1);
                                Modificado:=True;
                                Dec(CX);
                                IF CX<Col THEN Dec(Col);
                                Texto[CY]^[Maxlong]:=#32;
                               END ;

   IF Extend AND (Explor=83) THEN IF CX<>Maxlong THEN BEGIN  (* Supr *)
                                   Move(texto[Cy]^[CX+1],texto[Cy]^[Cx],Maxlong-cx+1);
                                   Modificado:=True;
                                   IF CX<Col THEN Dec(Col);
                                   Texto[CY]^[Maxlong]:=#32;
                                   END ;

  IF Extend AND (Explor=72) THEN BEGIN       (* Cursor arriba *)
                                  IF CY>1 THEN DEC(CY);
                                  IF CY<Lin THEN Lin:=Cy;
                                 END ;

  IF Extend AND (Explor=80) THEN IF (CY<MaxLin) AND (texto[CY+1]<>NIL)
                                  THEN BEGIN   (* Cursor abajo *)
                                        Inc(CY);
                                        IF CY-16>Lin THEN Inc(Lin);
                                       END ;

  IF Extend AND (Explor=77) THEN BEGIN (* Cursor derecha *)
                                  IF CX<Maxlong-1 THEN INC(CX);
                                  IF CX-Col=75 THEN Inc(Col);
                                 END ;


  IF Extend AND (Explor=75) THEN BEGIN (* Cursor izquierda *)
                                  IF CX>1 THEN Dec(CX);
                                  IF CX<Col THEN DEc(Col);
                                 END ;

  IF Extend AND (Explor=81) THEN
                               BEGIN (* Av Pg *)
                                Aux:=CY+10;
                                Dec(CY);
                                REPEAT
                                 INC(CY);
                                UNTIL (CY=Aux) OR (CY=MaxLin) OR (texto[CY+1]=NIL);
                                WHILE (CY-16>Lin) DO Inc(lin);
                               END ;

  IF Extend AND (Explor=73) THEN
                               BEGIN (* Re Pg *)
                                Aux:=CY-10;
                                Inc(CY);
                                REPEAT
                                 DEC(CY);
                                UNTIL (CY=Aux) OR (CY=1) OR (texto[CY-1]=NIL);
                                IF CY<Lin THEN Lin:=CY;
                               END ;

  IF Extend AND (Explor=71) THEN BEGIN (* Inicio *)
                                  Cx:=1;
                                  Col:=1;
                                 END ;
  IF Extend AND (Explor=79) THEN BEGIN (* Fin *)
                                   Cx:=len(texto[CY]^);
                                   Col:=Cx-60;
                                   IF integer(col)<1 THEN Col:=1;
                                  END ;

  IF Extend AND (Explor=82) THEN BEGIN (* Insert *)
                                  ModoInsert:=NOT ModoInsert;
                                  IF ModoInsert THEN AttrInsert:=$60
                                                ELSE AttrInsert:=$70;
                                  SetCursor(ModoInsert);
                                 END ;

  IF (Ch=#13) AND (texto[MaxLin]=NIL) THEN IF CY>=MaxLin-1 THEN Beep
                                            ELSE BEGIN
                                                  IF MaxAvail<Maxlong THEN beep
                                                  ELSE BEGIN
                                                  Inc(CY);
                                                  Move(texto[CY],texto[CY+1],Maxlin-CY+1);
                                                  Modificado:=True;
                                                  New(texto[CY]);
                                                  FillChar(texto[CY]^,Sizeof(linea),32);
                                                  Col:=1;CX:=1;
                                                  IF CY-16>Lin THEN Inc(Lin);
                                                  END;
                                                 END ;

  IF Ch=#9 THEN BEGIN
                 PutInbuffer(32,0);
                 PutInbuffer(32,0);
                 PutInbuffer(32,0);
                 PutInbuffer(32,0);
                END;

  IF (Ch IN [#127,#25]) AND (CY=1) AND (texto[Cy+1]=NIL) THEN BEGIN
                                                      FillChar(Texto[CY]^,SizeOf(Linea),32);
                                                      (* ­­Es la £nica l¡nea!! *)
                                                      Modificado:=True;
                                                      CX:=1;
                                                     END ELSE

  IF (Ch IN [#127,#25]) THEN BEGIN  (* Ctrl-Delete *)
                     Dispose(texto[Cy]);
                     Texto[Cy]:=NIL;
                     IF CY<>MaxLin THEN Move(texto[CY+1],texto[CY],Maxlin-CY+1);
                     Modificado:=True;
                     J:=CY;
                     IF Texto[CY]=NIL THEN Dec(CY);
                     IF Cy<Lin THEN Lin:=Cy;
                    END ;

  IF Extend AND (Explor=94) THEN  (* Ctrl-F1 *)
   BEGIN
    Hs:=texto[CY]^[CX];
    IF NOT (HS[1] IN ['a'..'z','A'..'Z','0'..'9','¥','¤']) THEN hs:='õ';
    J:=CX+1;
    WHILE (Texto[CY]^[J] IN ['a'..'z','A'..'Z','0'..'9','¥','¤']) DO
     BEGIN
      Hs:=Hs+Texto[CY]^[J];
      INC(J)
     END;
    J:=CX-1;
    WHILE (Texto[CY]^[J] IN ['a'..'z','A'..'Z','0'..'9','¥','¤']) AND (J>0) DO
     BEGIN
      Hs:=Texto[CY]^[J]+Hs;
      DEC(J)
     END;
    Pant.Salvar;
    CursorOff;
    REPEAT Pant.Mostrar UNTIL NOT Ayuda(Hs);
    SetCursor(ModoInsert);
    Pant.Recuperar;
   END ;

  IF Extend AND (Explor=59) THEN  (* F1 *)
   BEGIN
    Hs:='Editor';
    Pant.Salvar;
    Cursoroff;
    REPEAT Pant.Mostrar UNTIL NOT Ayuda(Hs);
    Pant.Recuperar;
    SetCursor(ModoInsert);
   END ;

   IF (Ch=#19) OR (Ch=#2) THEN  (*B£squeda Atr s*)
                     BEGIN
                      CursorOff;
                      GotoXY(33,8);
                      TextAttr:=$70;
                      Write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
                      GotoXY(33,9);
                      Write('³ Teclee Texto: ³');
                      GotoXY(33,10);
                      Write('³               ³');
                      GotoXY(33,11);
                      Write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
                      GotoXY(50,10);
                      Write('ÛÛ');
                      GotoXY(50,11);
                      Write('ÛÛ');
                      GotoXy(34,12);
                      GotoXY(50,9);
                      Write('ÛÛ');
                      GotoXy(34,12);
                      Write('ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ');
                      Window(37,13,48,13);
                      Busca:='';
                      ReadLn2(Busca,12);
                      IF Busca='' THEN Busca:=SaveBusca ELSE
                       SaveBusca:=Busca;
                      IF Busca='' THEN Goto sigue;
                      Window(3,4,78,21);
                      Encontrado:=False;
                      I:=CY-1;
                      J:=Maxlong-byte(busca[0])+1;
                      Byte(AuxBusca[0]):=Byte(Busca[0]);
                      LowCase(Busca);
                      GotoXY(34,10);
                      Write(' Buscando ...');
                      TextAttr:=$1F;
                      WHILE (integer(I)>=0) AND NOT Encontrado DO
                       BEGIN
                        IF J=0 THEN BEGIN
                                     Dec(I);
                                     J:=Maxlong-byte(Busca[0])+1;
                                    END;
                        Move(Texto[I]^[J],AuxBusca[1],length(Busca));
                        LowCase(AuxBusca);
                        IF AuxBusca=Busca THEN Encontrado:=True
                                          ELSE Dec(J);
                       END;
                     IF Encontrado THEN BEGIN
                                         CX:=J;
                                         CY:=I;
                                         IF Col>CX THEN Col:=CX;
                                         IF CX-Col>=65 THEN Col:=CX-38;
                                         Lin:=CY-8; IF integer(lin)<1 THEN lin:=1;
                                         Mostrar;
                                        END ELSE Beep;

                     SIGUE:
                     TextAttr:=$1F;
                     SetCursor(ModoInsert);
                    END;

   IF Extend AND (Explor IN [48,31]) THEN (* Alt-S, Alt-B *)
                     BEGIN
                      CursorOff;
                      GotoXY(33,8);
                      TextAttr:=$70;
                      Write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
                      GotoXY(33,9);
                      Write('³ Teclee Texto: ³');
                      GotoXY(33,10);
                      Write('³               ³');
                      GotoXY(33,11);
                      Write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
                      GotoXY(50,10);
                      Write('ÛÛ');
                      GotoXY(50,11);
                      Write('ÛÛ');
                      GotoXy(34,12);
                      GotoXY(50,9);
                      Write('ÛÛ');
                      GotoXy(34,12);
                      Write('ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ');
                      Window(37,13,48,13);
                      Busca:='';
                      ReadLn2(Busca,12);
                      IF Busca='' THEN Busca:=SaveBusca ELSE
                       SaveBusca:=Busca;
                      IF Busca='' THEN Goto Sigue2;
                      Window(3,4,78,21);
                      Encontrado:=False;
                      I:=CY+1;
                      GotoXY(34,10);
                      Write(' Buscando ...');
                      TextAttr:=$1F;
                      J:=1;
                      Byte(AuxBusca[0]):=Byte(Busca[0]);
                      LowCase(Busca);
                      WHILE (I<=MaxLin) AND (Texto[I]<>NIL) AND NOT Encontrado DO
                       BEGIN
                        IF Maxlong-J+1<length(Busca) THEN BEGIN
                                                           Inc(I);
                                                           J:=1;
                                                          END;
                        Move(Texto[I]^[J],AuxBusca[1],length(Busca));
                        LowCase(AuxBusca);
                        IF AuxBusca=Busca THEN Encontrado:=True
                                          ELSE Inc(J);
                       END;
                     IF Encontrado THEN BEGIN
                                         CX:=J;
                                         CY:=I;
                                         IF Col>CX THEN Col:=CX;
                                         IF CX-Col>=65 THEN Col:=CX-38;
                                         Lin:=CY-8; IF integer(lin)<1 THEN lin:=1;
                                         Mostrar;
                                        END ELSE Beep;
                     Sigue2:
                     TextAttr:=$1F;
                     SetCursor(ModoInsert);
                    END;


  IF Extend AND (Explor=116) THEN BEGIN (* Ctrl-Cursor derecha *)
                                  WHILE (Texto[CY]^[CX]<>' ') AND (CX<MaxLong) DO INC(CX);
                                  INC(CX);
                                  IF CX>Maxlong THEN CX:=Maxlong;
                                  WHILE CX-Col>=75 DO Inc(Col);
                                 END ;


  IF Extend AND (Explor=115) THEN BEGIN (* Ctrl-Cursor iquierda *)
                                  DEC(CX);
                                  IF CX<1 THEN CX:=1;
                                  WHILE (Texto[CY]^[CX]=' ') AND (CX>1) DO DEC(CX);
                                  WHILE (Texto[CY]^[CX]<>' ') AND (CX>1) DO DEC(CX);
                                  IF Texto[CY]^[CX]=' ' THEN INC(CX);
                                  WHILE CX<Col DO DEc(Col);
                                 END ;

  IF Extend AND (Explor=119) THEN BEGIN (* Ctrl-Inicio*)
    CY:=1;CX:=1;Col:=1;Lin:=1;
   END;

  IF Extend AND (Explor=117) THEN BEGIN (* Ctrl-Fin*)
    WHILE Texto[CY+1]<>NIL DO INC(CY);
    CX:=1;
    Lin:=CY;Col:=1;
   END;


   Mostrar;
  END;
  BufferCase;
  IF Ch=#27 THEN PreguntarGrabar;
 UNTIL Extend AND (Explor IN [60,103]);
 GrabarPosicion;
 Window(1,1,80,25);
 CursorOff;
 IF Explor=103 THEN Halt(0);
 IF Explor=60 THEN Grabar;
 Halt(0)
END.
