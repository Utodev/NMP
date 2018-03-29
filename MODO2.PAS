uses mycrt;

TYPE String15=String[15];

{$I OddStr.PAS}

CONST TKEOF=#0;
      BuffSize=4096;  (* tama§o del m†ximo bloque escribible *)
CONST flip:ARRAY[0..3] OF Char=('\','≥','/','ƒ');
CONST fliptoca:byte=0;

(* El tama§o del buffer ha de ser mayor o igual que el tama§o *)
(* de la variable m†s grande que se vaya a leer del fichero   *)

{$I CURSOFF.SRC}

PROCEDURE XORST(VAR S:STRING); Assembler;
ASM
 PUSH DS
 CLD
 XOR CX,CX
 LDS SI,[S]
 LES DI,[S]
 LODSB
 INC DI
 MOV CL,AL
 JCXZ @NADA
 @BUC:
 LODSB
 XOR AL,71
 STOSB
 DEC CX
 JNZ @BUC
 @NADA:
 POP DS
END;


TYPE
BufferRd=Object

 Buff:ARRAY[0..BuffSize-1] OF Char;
 BuffTam,BuffPoi:Word;

 PROCEDURE Inicializar(VAR F:File);
 PROCEDURE Leer(VAR F:File;VAR A;Tam:Word);
 FUNCTION EOFL(VAR F:File):Boolean;
 PROCEDURE Colocar(VAR F:File;Posic:LongInt);

END;

PROCEDURE BufferRd.Inicializar(VAR F:File);
BEGIN
 BuffPoi:=0;
 BlockRead(F,Buff,BuffSize,BuffTam);
END;


PROCEDURE BufferRd.Leer( VAR F:File; VAR A; Tam:Word );
VAR Aux:Word;
BEGIN
 IF BuffPoi>=BuffTam THEN BEGIN
                           BlockRead(F,Buff,BuffSize,BuffTam);
                           BuffPoi:=0
                          END;
 IF Tam+BuffPoi>BuffTam THEN BEGIN
                              Aux:=BuffTam-BuffPoi;
                              Move(Buff[BuffPoi],Buff[0],Aux);
                              BlockRead(F,Buff[Aux],BuffSize-Aux,BuffTam);
                              Inc(BuffTam,Aux);
                              BuffPoi:=0
                             END;
 Move(Buff[BuffPoi],A,Tam);
 Inc(BuffPoi,Tam)
END;

PROCEDURE BufferRd.Colocar(VAR F:FILE;Posic:LongInt);
BEGIN
 Seek(F,Posic);
 BlockRead(F,Buff,BuffSize,BuffTam);
 BuffPoi:=0
END;



FUNCTION BufferRd.EOFL(VAR F:File):Boolean;
VAR Aux:Boolean;
BEGIN
 Aux:=(EOF(F) AND (BuffPoi>=BuffTam));
 EOFL:=Aux;
END;

TYPE
BufferWr=Object

 Buff:ARRAY[0..BuffSize-1] OF Char;
 BuffPoi:Word;

 PROCEDURE Inicializar;
 PROCEDURE Escribir(VAR F:File;VAR A;Tam:Word);
 PROCEDURE Volcar(VAR F:File);

END;

PROCEDURE BufferWr.Inicializar;
BEGIN
 BuffPoi:=0
END;

PROCEDURE BufferWr.Escribir(VAR F:File;VAR A;Tam:Word);
BEGIN
 IF BuffPoi+Tam>BuffSize THEN BEGIN
                               BlockWrite(F,Buff,BuffPoi);
                               BuffPoi:=0
                              END;
 Move(A,Buff[BuffPoi],Tam);
 Inc(BuffPoi,Tam)
END;

PROCEDURE BufferWr.Volcar(VAR F:File);
BEGIN
 BlockWrite(F,Buff,BuffPoi);
 BuffPoi:=0
END;


VAR Filename:String[1];
    F1:FILE;
    F2:FILE;
    BR:BufferRD;
    BW:BufferWr;
    TK:Char;
    Linea:Longint;
    Byte1,Byte2:Word;
    Str1,Str2:String;
    Code:Integer;

PROCEDURE Error(N:String;Lin:Longint);
 VAR F:File;
BEGIN
 Assign(F,'ERROR.TMP');
 Rewrite(F,1);
 BlockWrite(F,N,81);
 BlockWrite(F,Lin,4);
 Close(F);
 Halt(1);
END;


PROCEDURE GetMem(VAR P:Pointer;Size:Word);
 BEGIN
  IF MaxAvail>=Size THEN System.GetMem(P,Size)
                         ELSE Error('No hay memoria suficiente para este modo. Use modo Menu',linea);
 END;


PROCEDURE LowCase;
BEGIN
 CASE TK OF
  'A'..'Z':TK:=Char(Byte(TK)+32);
  '•':TK:='§';
  'Ç':tk:='e';
  '¢':tk:='o';
  '£':tk:='u';
  '†':tk:='a';
  '°':tk:='i';
  'Å':tk:='u';
  'Ä':tk:='á';
  'ö':tk:='u'
 END
END;

PROCEDURE Comentario;
BEGIN
 REPEAT BR.Leer(F1,TK,1) UNTIL TK=#13
END;


PROCEDURE SCAN;
BEGIN
 TK:=#13;
 WHILE TK IN [#13,#10,#32,#26] DO
  BEGIN
   IF BR.EOFL(F1) THEN TK:=TKEOF
                  ELSE BR.Leer(F1,TK,1);
   IF TK=';' THEN Comentario;
   IF TK=#13 THEN INC(Linea);
  END;
 Write(flip[fliptoca]);
 Gotoxy(wherex-1,wherey);
 inc(fliptoca);if fliptoca=4 then fliptoca:=0;
END;

PROCEDURE SCANSP;
BEGIN
 TK:=#13;
 WHILE TK IN [#13,#10] DO
  BEGIN
   IF BR.EOFL(F1) THEN TK:=TKEOF
                  ELSE BR.Leer(F1,TK,1);
   IF TK=';' THEN Comentario;
   IF TK=#13 THEN INC(Linea);
  END;
     Write(flip[fliptoca]);
     Gotoxy(wherex-1,wherey);
     inc(fliptoca);if fliptoca=4 then fliptoca:=0;
END;

PROCEDURE SCANLow;
BEGIN
 TK:=#13;
 WHILE TK IN [#13,#10,#32] DO
  BEGIN
   IF BR.EOFL(F1) THEN TK:=TKEOF
                  ELSE BR.Leer(F1,TK,1);
   IF TK=';' THEN Comentario;
   IF TK=#13 THEN INC(Linea);
  END;
 LowCase;
     Write(flip[fliptoca]);
     Gotoxy(wherex-1,wherey);
     inc(fliptoca);if fliptoca=4 then fliptoca:=0;
END;
PROCEDURE SCANSPLow;
BEGIN
 TK:=#13;
 WHILE TK IN [#13,#10] DO
  BEGIN
   IF BR.EOFL(F1) THEN TK:=TKEOF
                  ELSE BR.Leer(F1,TK,1);
   IF TK=';' THEN Comentario;
   IF TK=#13 THEN INC(Linea);
  END;
Lowcase;
     Write(flip[fliptoca]);
     Gotoxy(wherex-1,wherey);
     inc(fliptoca);if fliptoca=4 then fliptoca:=0;
END;



PROCEDURE NOEOF;
BEGIN
 IF TK=TKEOF THEN Error('Fin de fichero inesperado',linea)
END;

FUNCTION Dosala(N:Byte):Word;
BEGIN
 IF N=0 THEN Dosala:=1
        ELSE Dosala:=2*Dosala(N-1)
END;


FUNCTION Val2(St:String;VAR Valor:Word):Boolean;
VAR I:Byte;
BEGIN
Val2:=False;
Valor:=0;
IF length(st)<16 THEN Exit;
FOR I:=1 TO 16 DO
 IF St[I]='1' THEN Inc(Valor,DOSALA(16-I))
              ELSE IF St[I]<>'0' THEN Exit;
Val2:=True;
END;

FUNCTION STRS(A:Word):String;
VAR S:STRING;
BEGIN
 STR(A,S);
 STRS:=S
END;

PROCEDURE GetBYTE;
BEGIN
 Str1:='';
 REPEAT
  SCANSP;
  NOEOF;
  IF TK IN ['0'..'9'] THEN Str1:=Str1+TK;
 UNTIL (Length(Str1)=3) OR NOT (TK IN ['0'..'9']);
 VAL(Str1,Byte1,code);
 IF Code<>0 THEN Error('Numero Erroneo',Linea);
 IF Byte1>255 THEN Error('Numero demasiado grande',Linea);
 IF Length(Str1)=3 THEN SCANSP;
END;

PROCEDURE GetString(LEN:Byte);
BEGIN
 Str2:='';
 REPEAT
  SCANSP;
  NOEOF;
  IF TK <> '}' THEN Str2:=Str2+TK;
 UNTIL (Length(Str2)=255) OR (TK='}');
 IF Length(Str2)>LEN THEN Error('Texto demasiado largo. M†ximo: '+STRS(LEN),linea);
 IF (Length(Str2)=LEN) AND (TK<>'}') THEN BEGIN
                                           SCANSP;
                                           IF TK<>'}' THEN Error('Texto demasiado largo. M†ximo: '+STRS(LEN),linea);
                                          END;
END;

PROCEDURE GetOddStr(Len:Word);
BEGIN
 ClearOdd;
 REPEAT
  SCANSP;
  NOEOF;
  IF TK <> '}' THEN AddOddStr(TK);
 UNTIL (OddStr.Len=OddSize) OR (TK='}');
 IF OddStr.len>LEN THEN Error('Texto demasiado largo. M†ximo: '+STRS(Len),linea);
 IF (OddStr.Len=LEN) AND (TK<>'}') THEN BEGIN
                                           SCANSP;
                                           IF TK<>'}' THEN Error('Texto demasiado largo. M†ximo: '+STRS(len),linea);
                                          END;
END;

PROCEDURE GetFlags;
BEGIN
 Str2:='';
 REPEAT
  SCAN;
  NOEOF;
  IF NOT (TK IN [' ','}']) THEN Str2:=Str2+TK;
 UNTIL (Length(Str2)=16) OR (TK='}');
 IF Length(Str2)<16 THEN Error('Faltan indicadores',linea);
 IF (Length(Str2)=16) AND (TK<>'}') THEN BEGIN
                                          SCAN;
                                          IF TK<>'}' THEN Error('Sobran indicadores',linea);
                                         END;
 IF Not Val2(Str2,Byte1) THEN Error('Error en indicadores.',linea);
END;

PROCEDURE GetLowString(LEN:Byte);
BEGIN
 Str2:='';
 REPEAT
  SCANSPLow;
  NOEOF;
  IF TK <> '}' THEN Str2:=Str2+TK;
 UNTIL (Length(Str2)=255) OR (TK='}');
 IF Length(Str2)>LEN THEN Error('Texto demasido largo',linea);
 IF (Length(Str2)=LEN) AND (TK<>'}') THEN BEGIN
                                           SCANSP;
                                           IF TK<>'}' THEN Error('Texto demasido largo',linea);
                                          END;
END;



PROCEDURE FIN;
BEGIN
 IF Filename[1]<>'v' THEN BEGIN
                           BW.Volcar(F2);
                           Close(F2)
                          END;
 Close(F1);
 Halt(0);
END;


TYPE UNIONPAL=RECORD
               {$IFDEF ALCACHOFA}
               p:string[16];
               {$ELSE}
               p:string[5];
               {$ENDIF}
               n:Byte
              END;
     PUnion=^Union;
     Union=RECORD
            {$IFDEF ALCACHOFA}
            p:string[16];
            {$ELSE}
            p:string[5];
            {$ENDIF}
            n:byte;
            sig:PUnion;
           END;

TYPE TIpo=ARRAY[0..254] OF PUnion;

PROCEDURE Insertar(VAR V:Tipo;P:UnionPal);
VAR Aux:Punion;
BEGIN
 IF V[P.n]=NIL THEN BEGIN
                     GetMem(pointer(V[P.N]),SizeOf(Union));
                     V[P.n]^.p:=P.p;
                     V[P.n]^.n:=P.n;
                     V[P.n]^.sig:=NIL
                    END
               ELSE BEGIN
                     Getmem(pointer(Aux),SizeOf(Union));
                     Aux^.p:=p.p;
                     Aux^.n:=p.n;
                     Aux^.sig:=V[P.n];
                     V[P.n]:=Aux
                    END;
END;


VAR Nombres,Verbos,Preposic,conj :Tipo;
    P:UnionPal;
    TipoPal:Char;


PROCEDURE Dump(C:String;VAR V:Tipo);
VAR I:Byte;
    Ptr:PUnion;

BEGIN
 Assign(F2,'ADV\'+C+'.DTT');
 Rewrite(F2,1);
 BW.Inicializar;
 FOR I:=0 TO 254 DO
  IF V[I]<>NIL THEN
   BEGIN
    PTR:=V[I];
    WHILE PTR<>NIL DO
     BEGIN
      P.p:=Ptr^.p;
      P.n:=Ptr^.n;
      XorST(P.P);
      BW.Escribir(F2,p,Sizeof(p));
      Ptr:=Ptr^.sig;
     END;
   END;
  BW.Volcar(F2);
  Close(F2);
END;




PROCEDURE VOCABULARIO;
BEGIN
 FillChar(Verbos,Sizeof(Verbos),0);
 FillChar(Nombres,Sizeof(Verbos),0);
 FillChar(Preposic,Sizeof(Verbos),0);
 FillChar(Conj,Sizeof(Verbos),0);
 Linea:=1;
 SCAN;
 NOEOF;
 REPEAT
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetBYTE;
  P.N:=Byte1;
  IF Byte1=255 THEN Error('Numero de palabra err¢neo',linea);
  IF TK <> ',' THEN Error('Se espera ","',Linea);
  SCANLow;
  NOEOF;
  IF NOT (TK IN ['c','v','p','n']) THEN Error('Tipo de palabra incorrecto',Linea);
  TipoPal:=TK;
  SCAN;
  IF TK <> ',' THEN Error('Se espera ","',Linea);
  {$IFDEF ALCACHOFA}
  GetLowString(16);
  {$ELSE}
  GetLowString(5);
  {$ENDIF}
  P.P:=Str2;
  IF TK<>'}' THEN Error('Se espera "{"',linea);
  CASE TipoPal OF
   'p':Insertar(Preposic,P);
   'v':Insertar(Verbos,p);
   'n':Insertar(Nombres,p);
   'c':Insertar(Conj,p);
  END;
  SCAN;
 UNTIL TK=TKEOF;
 Dump('v',Verbos);
 Dump('n',Nombres);
 Dump('p',Preposic);
 DUMP('CONJ',Conj);
 Fin;
END;

PROCEDURE OBJETOS;



TYPE OBJPTR=^OBJ;
     Obj=RECORD
             Num:Byte;
             {$ifdef ALCACHOFA}
             Pal:String[16];
             {$ELSE}
             Pal:string[5];
             {$ENDIF}
             Nombre:string[40];
             Peso:Byte;
             Inicial:Byte;
             Flags:Word;
             sig:objptr;
            END;

VAR PTR:OBJPTR;
    PTR2:OBJPTR;
    OBJAL:OBJ;
    Orden:Integer;


PROCEDURE Insert;
VAR AUX:ObjPtr;
BEGIN
 IF Ptr=NIL THEN BEGIN
                  GetMem(Pointer(PTR),SizeOf(OBJ));
                  PTR^.Num:=OBJAL.Num;
                  PTR^.pal:=OBJAL.pal;
                  PTR^.nombre:=OBJAL.nombre;
                  PTR^.peso:=OBJAL.peso;
                  PTR^.inicial:=OBJAL.inicial;
                  PTR^.flags:=OBJAL.flags;
                  PTR^.sig:=NIL;
                  PTR2:=PTR;
                 END
             ELSE BEGIN
                  GetMem(Pointer(PTR2^.sig),SizeOf(OBJ));
                  PTR2:=PTR2^.sig;
                  PTR2^.Num:=OBJAL.Num;
                  PTR2^.pal:=OBJAL.pal;
                  PTR2^.nombre:=OBJAL.nombre;
                  PTR2^.peso:=OBJAL.peso;
                  PTR2^.inicial:=OBJAL.inicial;
                  PTR2^.flags:=OBJAL.flags;
                  PTR2^.sig:=NIL;
                 END;
END;

BEGIN
 Linea:=1;
 PTR:=NIL;
 Orden:=-1;
 SCAN;
 NOEOF;
 REPEAT
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetBYTE;
  OBJAL.Num:=Byte1;
  IF Byte1<=Orden THEN Error('Objeto repetido',linea);
  IF Byte1>Orden+1 THEN Error('Nß de objeto no consecutivo',linea);
  Inc(Orden);
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetString(40);
  OBJAL.Nombre:=Str2;
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  {$IFDEF ALCACHOFA}
  GetLowString(16);
  {$ELSE}
  GetLowString(5);
  {$ENDIF}
  OBJAL.Pal:=Str2;
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetBYTE;
  OBJAL.Peso:=Byte1;
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetBYTE;
  OBJAL.Inicial:=Byte1;
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetFlags;
  OBJAL.Flags:=Byte1;
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  Insert;
  SCAN;
 UNTIL TK=TKEOF;
 PTR2:=PTR;
 WHILE PTR2<>NIL DO
  BEGIN
   BW.Escribir(F2,Ptr2^.pal,SizeOf(Ptr2^.Pal));
   BW.Escribir(F2,Ptr2^.nombre,41);
   BW.Escribir(F2,Ptr2^.peso,1);
   BW.Escribir(F2,Ptr2^.inicial,1);
   BW.Escribir(F2,Ptr2^.flags,2);
   Ptr2:=Ptr2^.sig
  END;
 PTR2:=PTR;
 Fin;
END;



PROCEDURE MENSAJES;
VAR Orden:Longint;
    J,Num:Word;
    mes:String;
    Offset:Longint;
    Q:File;
CONST C0:Word=0;



BEGIN
 Assign(Q,'ADV\M.IDX');
 Rewrite(Q,1);
 BW.Inicializar;
 Offset:=0;
 Linea:=1;
 Orden:=-1;
 SCAN;
 NOEOF;
 REPEAT
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetBYTE;
  Byte2:=Byte1;
  IF TK <> ',' THEN Error('Se espera ","',Linea);
  GetByte;
  Num:=Byte2*256+Byte1;
  IF Num<=Orden THEN Error('Mensaje repetido o desordenado',linea);
  Inc(orden);
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetOddStr(OddSize);
  XOROddSTr;
  mes:='';
  IF Num>Orden THEN
   FOR J:=Orden TO Num-1 DO BEGIN
                             BW.Escribir(Q,C0,2);
                             BW.Escribir(Q,Offset,4);
                            END;
  BW.Escribir(Q,OddStr.Len,2);
  BW.Escribir(Q,Offset,4);
  BlockWrite(F2,OddStr.TXT,OddStr.Len);
  Inc(Offset,OddStr.Len);
  Orden:=Num;
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
 UNTIL TK=TKEOF;
 BW.Volcar(Q);
 Close(Q);
 Close(F1);
 Close(f2);
 Halt(0);
END;

PROCEDURE LOCALIDADES;
TYPE LOCPTR=^LOC;
     LOC=RECORD
          DEF:RECORD
               LEN:Word;
               TXT:ARRAY[0..1023] OF Char
              END;
          EXIT:String;
         END;
VAR LOCAL:Loc;
    Orden:Integer;


BEGIN
 Linea:=1;
 Orden:=-1;
 SCAN;
 NOEOF;
 REPEAT
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetBYTE;
  IF Byte1<=Orden THEN Error('Localidad repetida',linea);
  IF Byte1>Orden+1 THEN Error('Localidad no consecutiva',linea);
  Inc(Orden);
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetOddStr(1024);
  XorOddStr;
  LOCAL.DEF.LEN:=OddStr.len;
  MOVE(OddStr.TXT,LOCAL.DEF.TXT,OddSTr.len);
  IF TK <> '}' THEN Error('Se espera "}"',Linea);
  SCAN;
  NOEOF;
  IF TK <> '{' THEN Error('Se espera "{"',Linea);
  GetLowString(255);
  Local.Exit:=Str2;XORST(Local.Exit);
  Bw.Escribir(F2,Local,Sizeof(Local));
 SCAN;
 UNTIL TK=TKEOF;
 Fin;
END;


BEGIN (*Principal*)
 IF ParamStr(2)<>'CSG' THEN Halt(12);
 FileName:=ParamStr(1);
 CursorOff;
 Assign(F1,Filename+'.DEF');
 Reset(F1,1);
 BR.Inicializar(F1);
 IF Filename='m' THEN BEGIN
                        Assign(F2,'ADV\'+Filename+'.PAK');
                        Rewrite(F2,1);
                       END ELSE
 IF Filename<>'v' THEN BEGIN
                        Assign(F2,'ADV\'+Filename+'.DAT');
                        Rewrite(F2,1);
                        BW.Inicializar;
                       END;
 CASE Upcase(Filename[1]) OF
 'V':Vocabulario;
 'M':Mensajes;
 'O':Objetos;
 'L':Localidades
 END;
END.