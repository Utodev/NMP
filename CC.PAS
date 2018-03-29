USES Crt,BITSET;

CONST TKEOF=#0;
CONST MaxCond=20;
      MaxAcci=20;
      LastCond=6;
      LastAcci=8;
      MaxFrases=10;



VAR BITMAP:ARRAY[0..127] OF Byte;

CONST FILE_ID:ARRAY[0..15] OF CHAR='NM CONVERSACION'+#26;

{$I BUFFERRD.POO}

VAR BR:^BufferRd;
    F,G:FILE;
    G2:FILE OF LongInt;
    Nombre:String;
    TK:Char;
    Linea:Word;
    Str1,Str2:String;
    V1024,Byte1,Byte2:Word;
    I,J:Word;
    code:integer;
    Menu:Byte;
    Pos:LongInt;

PROCEDURE ARREJUNTA;
VAR P:POINTER;
    W:Word;
    F1,F2:FILE;
    N:Byte;
BEGIN
 GetMem(P,64000);
 Assign(F1,'ADV\'+Nombre+'.000');
 Assign(F2,'ADV\'+Nombre+'.TLK');
 Rewrite(F2,1);
 Reset(F1,1);
 N:=FILESIZE(F1) DIV 4;
 BlockWrite(F2,N,1);
 WHILE NOT EOF(F1) DO
  BEGIN
   BlockRead(F1,P^,64000,W);
   BlockWrite(F2,P^,W);
  END;
 Close(F1);
 Erase(F1);
 Assign(F1,'ADV\'+Nombre+'.001');
 Reset(F1,1);
 WHILE NOT EOF(F1) DO
  BEGIN
   BlockRead(F1,P^,64000,W);
   BlockWrite(F2,P^,W);
  END;
 Close(F1);
 Erase(F1);
END;




TYPE INS=PACKED ARRAY[1..2] OF CHAR;

CONST COND:ARRAY [1..LastCond] OF INS=
      ('CR','NC','EX','NX','ZR','NZ');
CONST ACCI:ARRAY [1..LastAcci] OF INS=
      ('ST','CL','GT','DR','AN','CR','MN','WI');


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


PROCEDURE Error(N:String);
 BEGIN
  Write(' Error en linea ',Linea,': ',N);
  Halt(1);
 END;

PROCEDURE Comentario;
BEGIN
 REPEAT br^.Leer(F,TK,1) UNTIL TK=#13
END;


PROCEDURE SCANSP;
BEGIN
 TK:=#13;
 WHILE TK IN [#26,#13,#10] DO
  BEGIN
   IF br^.EOFL(F) THEN TK:=TKEOF
                  ELSE br^.Leer(F,TK,1);
   IF TK=';' THEN Comentario;
   IF TK=#13 THEN INC(Linea);
  END;
END;

PROCEDURE SCANLow;
BEGIN
 TK:=#13;
 WHILE TK IN [#13,#26,#10,#32] DO
  BEGIN
   IF br^.EOFL(F) THEN TK:=TKEOF
                  ELSE br^.Leer(F,TK,1);
   IF TK=';' THEN Comentario;
   IF TK=#13 THEN INC(Linea);
  END;
 LowCase
END;

PROCEDURE NOEOF;
BEGIN
 IF TK=TKEOF THEN Error('Fin de fichero inesperado.')
END;

PROCEDURE GetString(LEN:Byte);
BEGIN
 Str2:='';
 REPEAT
  SCANSP;
  NOEOF;
  IF TK <> '}' THEN Str2:=Str2+TK;
 UNTIL (Length(Str2)=255) OR (TK='}');
 IF Length(Str2)>LEN THEN Error('Texto demasido largo');
 IF (Length(Str2)=LEN) AND (TK<>'}') THEN BEGIN
                                           SCANSP;
                                           IF TK<>'}' THEN Error('Texto demasido largo');
                                          END;
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
 IF Code<>0 THEN Error('Numero Erroneo.');
 IF Byte1>255 THEN Error('Numero demasiado grande.');
 IF Length(Str1)=3 THEN SCANSP;
END;

PROCEDURE Get1024;
BEGIN
 Str1:='';
 REPEAT
  SCANSP;
  NOEOF;
  IF TK IN ['0'..'9'] THEN Str1:=Str1+TK;
 UNTIL (Length(Str1)=4) OR NOT (TK IN ['0'..'9']);
 VAL(Str1,V1024,code);
 IF Code<>0 THEN Error('Numero Erroneo.');
 IF Byte1>=1024 THEN Error('Numero demasiado grande.');
 IF Length(Str1)=4 THEN SCANSP;
END;

PROCEDURE GetCoor;
BEGIN
 Str1:='';
 REPEAT
  SCANSP;
  NOEOF;
  IF TK IN ['0'..'9'] THEN Str1:=Str1+TK;
 UNTIL (Length(Str1)=3) OR NOT (TK IN ['0'..'9']);
 VAL(Str1,Byte1,code);
 IF Code<>0 THEN Error('Numero Erroneo.');
 IF Byte1>319 THEN Error('Numero demasiado grande.');
 IF Length(Str1)=3 THEN SCANSP;
END;


PROCEDURE GetCond;
VAR P:INS;
    I:Byte;
BEGIN
 GetString(7);
 Str2[1]:=Upcase(Str2[1]);
 Str2[2]:=UpCase(Str2[2]);
 IF Length(Str2)<4 THEN Error('Condici¢n incorrecta.');
 MOVE (Str2[1],P,2);
 I:=1;
 WHILE (I<=LastCond) AND (Cond[I]<>P) DO INC(I);
 IF I>LastCond THEN Error('Condici¢n desconocida.')
               ELSE Byte1:=I;
 Str2:=Copy(Str2,4,4);
 Val(Str2,Byte2,code);
 IF Code<>0 THEN Error('Numero Erroneo.');
 IF Byte2>=1024 THEN Error('Numero demasiado grande.');
END;

PROCEDURE GetAcci;
VAR P:INS;
    I:Byte;
BEGIN
 GetString(7);
 Str2[1]:=UpCase(Str2[1]);
 Str2[2]:=UpCase(Str2[2]);
 IF Length(Str2)<4 THEN Error('Acci¢n incorrecta.');
 MOVE (Str2[1],P,2);
 I:=1;
 WHILE (I<=LastAcci) AND (Acci[I]<>P) DO INC(I);
 IF I>LastAcci THEN Error('Acci¢n desconocida.')
               ELSE Byte1:=I;
 Str2:=Copy(Str2,4,4);
 Val(Str2,Byte2,code);
 IF Code<>0 THEN Error('Numero Erroneo.');
 IF Byte2>1204 THEN Error('Numero demasiado grande.');
END;


PROCEDURE XXOR(VAR S:STRING);
VAR I:Byte;
BEGIN
 FOR I:=1 TO Byte(S[0]) DO byte(S[I]):=Byte(S[I]) XOR 71;
END;

(*PRINCIPAL*)
BEGIN
 WriteLn('CC 2.0  Compilador de Conversaciones (C) 1995 NM Software.');
 WriteLn;
 IF ParamCount<>1 THEN BEGIN
                        WriteLn('SINTAXIS :    CC Fichero[.CNV]');
                        Halt;
                       END;
 Nombre:=ParamStr(1); IF system.Pos('.',Nombre)=0 THEN Nombre:=Nombre+'.CNV';
 Assign(F,Nombre);
 {$I-}
 Reset(F,1);
 IF IOResult<>0 THEN BEGIN
                      WriteLn('Error : No se encontr¢ fichero.');
                      Halt
                     END;
 Nombre:=Copy(Nombre,1,system.Pos('.',nombre)-1);
 Assign(G,'ADV\'+Nombre+'.001');
 Assign(G2,'ADV\'+Nombre+'.000');
 Rewrite(G,1);
 BlockWrite(G,FILE_ID,16);
 Rewrite(G2);
 BlockWrite(G,Mem[0:0],112); (* Cabecera reservada, por si acaso *)
 New(BR);
 BR^.Inicializar(F);
 Linea:=1;


 SCANLow;

 IF TK<>'f' THEN Error('Se espera FLAG.');
 SCANLow;
 IF TK<>'l' THEN Error('Se espera FLAG.');
 SCANLow;
 IF TK<>'a' THEN Error('Se espera FLAG.');
 SCANLow;
 IF TK<>'g' THEN Error('Se espera FLAG.');
 SCANLow;
 IF TK<>'=' THEN Error('Se espera signo igual.');
 GetByte;
 BlockWrite(G,Byte1,1); (* Grabo flag *)

 FillChar(BITMAP,128,0);
 IF TK<>'e' THEN Error('Se espera EXIST.');
 SCANLow;
 IF TK<>'x' THEN Error('Se espera EXIST.');
 SCANLow;
 IF TK<>'i' THEN Error('Se espera EXIST.');
 SCANLow;
 IF TK<>'s' THEN Error('Se espera EXIST.');
 SCANLow;
 IF TK<>'t' THEN Error('Se espera EXIST.');
 SCANLow;
 IF TK<>'=' THEN Error('Se espera signo igual.');
 SCANLow;
 IF TK<>'(' THEN Error('Se espera parÇntesis abierto.');
 REPEAT
   Get1024;
   BSET(BITMAP,V1024);
 UNTIL TK<>',';
 IF TK<>')' THEN Error('Se espera parÇntesis cerrado.');
 BlockWrite(G,BITMAP,128);  (* Guarda activos *)


 (* AHORA VIENEN LOS MENUS *)
 Menu:=0;
 SCANLow;
 WHILE TK<>TKEOF DO
  BEGIN
   IF TK<>'_' THEN Error('Se espera _MENU.');
   ScanLow;
   IF TK<>'m' THEN Error('Se espera _MENU.');
   ScanLow;
   IF TK<>'e' THEN Error('Se espera _MENU.');
   ScanLow;
   IF TK<>'n' THEN Error('Se espera _MENU.');
   ScanLow;
   IF TK<>'u' THEN Error('Se espera _MENU.');

   ScanLow;
   IF TK<>'{' THEN Error('Se espera llave abierta.');
   GetByte;
   IF Byte1<>Menu THEN Error('Men£ no en orden.');
   Inc(Menu);
   Pos:=FilePos(G);
   Write(G2,Pos);
   BlockWrite(G,Byte1,1); (* Guardo nß  de menu *)
   IF TK<>'}' THEN Error('Se espera llave cerrada.');

   ScanLow;
   IF TK<>'{' THEN Error('Se espera llave abierta.');
   GetByte;
   BlockWrite(G,Byte1,1); (* Guardo nß  de frases en menu *)
   IF Byte1>MaxFrases THEN Error('Demasiadas frases en el men£.');
   IF TK<>'}' THEN Error('Se espera llave cerrada.');

   FOR I:=1 TO Byte1 DO
    BEGIN
    ScanLow;
    IF TK<>'{' THEN Error('Se espera llave abierta.');
    Get1024;
    BlockWrite(G,V1024,2); (* Guardo nß  de la frase*)
    IF TK<>'}' THEN Error('Se espera llave cerrada.');
    ScanLow;
    IF TK<>'{' THEN Error('Se espera llave abierta.');
    GetString(255);
    XXOR(STR2);
    BlockWrite(G,Byte(STR2[0]),1);
    BlockWrite(G,Str2[1],byte(STR2[0]));
    IF TK<>'}' THEN Error('Se espera llave cerrada.');
    ScanLow;
    IF TK<>'{' THEN Error('Se espera llave abierta.');
    GetString(255);
    XXOR(STR2);
    BlockWrite(G,byte(Str2[0]),1);
    BlockWrite(G,Str2[1],byte(Str2[0]));
    IF TK<>'}' THEN Error('Se espera llave cerrada.');
    ScanLow;
    IF TK<>'{' THEN Error('Se espera llave abierta.');
    getByte;
    IF Byte1>MaxCond THEN Error('Demasiadas condiciones.');
    BlockWrite(G,Byte1,1);  (* Guardo nß de condiciones *)
    IF TK<>'}' THEN Error('Se espera llave cerrada.');
    FOR J:=1 TO Byte1 DO
     BEGIN
      ScanLow;
      IF TK<>'{' THEN Error('Se espera llave abierta.');
      GetCond;
      BlockWrite(G,Byte1,1); (* Nß de instrucci¢n *)
      BlockWrite(G,Byte2,2); (* Par†metro *)
      IF (Byte1<>3) AND (Byte1<>4) AND (Byte2>255) THEN Error('N£mero demasiado grande.');
      IF TK<>'}' THEN Error('Se espera llave cerrada.');
     END;


    ScanLow;
    IF TK<>'{' THEN Error('Se espera llave abierta.');
    getByte;
    IF Byte1>MaxAcci THEN Error('Demasiadas acciones.');
    BlockWrite(G,Byte1,1);  (* Guardo nß de acciones *)
    IF TK<>'}' THEN Error('Se espera llave cerrada.');
    FOR J:=1 TO Byte1 DO
     BEGIN
      ScanLow;
      IF TK<>'{' THEN Error('Se espera llave abierta.');
      GetAcci;
      BlockWrite(G,Byte1,1); (* Nß de instrucci¢n *)
      BlockWrite(G,Byte2,2); (* Par†metro *)
      IF (Byte1<>5) AND (Byte1<>6) AND (Byte2>255) THEN Error('N£mero demasiado grande.');
      IF TK<>'}' THEN Error('Se espera llave cerrada.');
     END;
    END; (* FOR I:=1 TO NumFrases *)
     ScanLow;
     IF TK<>'_' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'e' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'n' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'d' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'m' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'e' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'n' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'u' THEN Error('Se espera _ENDMENU.');
     ScanLow;
     IF TK<>'.' THEN Error('Se espera punto.');
     ScanLow;

  END;  (* WHILE NOT TK=TKEOF *)

  Close(G);
  Close(G2);
  Close(F);
  Arrejunta;
  WriteLn('OK. ',Nombre,' ha sido compilado.');
END.