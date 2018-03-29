UNIT PACKER;

{$I-}
{$S-}
{$R-}

INTERFACE
VAR iSPACKED:Boolean;
    NoSeek:Boolean;  (* Si se pone a TRUE, al hacer un RESET no se coloca *)
                     (* Lo hace el reset de la cach‚ cuando detecta que el *)
                     (* fichero est  en la misma *)

PROCEDURE COLOCAPRINCIPIO(VAR F:FILE);
FUNCTION HANDLEOF(VAR F:FILE):Word;
PROCEDURE Seek(VAR F:File;Off:Longint);
FUNCTION EOF(VAR F:FILE):Boolean;
FUNCTION Filepos(VAR F:FILE):Longint;
PROCEDURE Reset(VAR F:FILE;recsize:word);
FUNCTION Handle2Name(H:Word):String;
FUNCTION FileSize(VAR F:FILE):Longint;
PROCEDURE Close(VAR F:FILE);

IMPLEMENTATION

CONST MAXFILES=10; (* n§ m ximo de ficheros abiertos simult neamente *)

VAR  PACKEDDATA:ARRAY[0..MaxFiles-1] OF RECORD
                                        FICHERO:String[12];
                                        BASEOFFS:Longint;
                                        TAMANO:Longint;
                                        Handle:Word;
                                       END;
    DataPtr:Byte;
    FAux:FILE;

FUNCTION HANDLEOF(VAR F:FILE):Word;
VAR A:word;
BEGIN
 MOVE(F,A,2);
 HANDLEOF:=A
END;


FUNCTION BuscarFichero(W:Word):Byte;
VAR I:Byte;
BEGIN
 I:=0;
 WHILE (I<MaxFiles) AND (PACKEDDATA[I].handle<>W) DO INC(I);
 BuscarFichero:=I;
END;

FUNCTION BuscarD00(S:String):Byte;
BEGIN
 Assign(Faux,'NMPDATA.D00');
 System.Reset(FAux,1);
 WHILE (PACKEDDATA[DataPtr].Fichero<>S) AND NOT System.EOF(FAux) DO system.BlockRead(Faux,PACKEDDATA[DataPtr],21);
 System.Close(Faux);
 IF (PACKEDDATA[DataPtr].Fichero<>S) THEN BuscarD00:=MaxFiles ELSE BEGIN
                                                            BuscarD00:=DataPtr;
                                                            Inc(DataPtr);
                                                            IF DataPtr=MaxFiles THEN DataPtr:=0
                                                           END;
END;


FUNCTION AbrirFichero(S:STRING):Byte;
VAR I:Byte;
BEGIN
 I:=BuscarD00(s);
 AbrirFichero:=I;
END;



FUNCTION Getname(VAR F:FILE):String;
VAR P:^char;
    S:String;
    i:Byte;
BEGIN
 S:='';
 P:=pointer(longint(@F)+48);
 WHILE P^<>#0 DO BEGIN
                  S:=S+P^;
                  Inc(longint(p));
                 END;
 FOR I:=1 TO byte(S[0]) DO S[I]:=UpCase(S[I]);
 GetName:=S;
END;


PROCEDURE ADDFILE(S:String;A,B:Longint;H:Word);
BEGIN
 WITH PACKEDDATA[DATAPtr] DO
  BEGIN
   FICHERO:=S;
   BaseOffs:=A;
   Tamano:=b;
   handle:=H;
  END;
 Inc(DataPtr);
 IF DataPtr=Maxfiles then DataPtr:=0;
END;


PROCEDURE Reset(VAR F:FILE;recsize:word);
VAR I:Byte;
BEGIN
 IF NOT ISPACKED THEN System.Reset(F,recsize)
 ELSE BEGIN
       I:=AbrirFichero(getname(F));
       IF I=MaxFiles THEN BEGIN     (* Si no est  en mogoll¢n lo busco fuera *)
                          system.Reset(F,1);
                          IF InOutRes=0 THEN AddFile(Getname(F),0,system.Filesize(f),handleof(f));
                          Exit;
                         END;
       Assign(F,'NMPDATA.D01');
       System.Reset(F,1);
       IF NOT NoSeek THEN System.Seek(F,PACKEDDATA[I].BaseOffs);
       Noseek:=False;
       PACKEDDATA[I].handle:=HandleOf(F);
      END;
END;

PROCEDURE COLOCAPRINCIPIO(VAR F:FILE);
VAR I:Byte;
BEGIN
 I:=Buscarfichero(handleof(F));
 System.Seek(F,PACKEDDATA[i].BaseOffs);
END;


FUNCTION Handle2Name(H:Word):String;
VAR I:Byte;
BEGIN
 I:=0;
 WHILE (I<MaxFiles) AND (PACKEDDATA[I].Handle<>H) DO INC(I);
 IF I<MaxFiles THEN Handle2Name:=PACKEDDATA[I].Fichero ELSE handle2name:='';
END;


PROCEDURE Close(VAR F:FILE);
VAR I:Byte;
BEGIN
 IF NOT ISPACKED THEN System.Close(F) ELSE
  BEGIN
   I:=BuscarFichero(HandleOf(f));
   Packeddata[I].handle:=$FFFF;
   System.Close(F);
  END;
END;

PROCEDURE Seek(VAR F:File;Off:Longint);
VAR I:Byte;
BEGIN
 IF NOT ISPACKED THEN System.Seek(F,Off)
 ELSE BEGIN
       I:=BuscarFichero(handleof(f));
       system.Seek(F,PACKEDDATA[i].baseoffs+Off);
      END;
END;

FUNCTION EOF(VAR F:FILE):Boolean;
VAR I:Byte;
BEGIN
 IF NOT ISPACKED THEN EOF:=System.Eof(F) ELSE
  BEGIN
   I:=BuscarFichero(handleof(f));
   EOF:=System.FilePos(F)-PACKEDDATA[I].BaseOffs>=PACKEDDATA[I].tamano;
  END;
END;

FUNCTION Filepos(VAR F:FILE):Longint;
VAR I:Byte;
BEGIN
 IF NOT ISPACKED THEN FilePos:=System.FilePos(F) ELSE
  BEGIN
   I:=BuscarFichero(handleof(f));
   FilePos:=System.FilePos(F)-PACKEDDATA[I].BaseOffs;
  END;
END;

FUNCTION FileSize(VAR F:FILE):Longint;
VAR I:Byte;
BEGIN
 IF NOT ISPACKED THEN FileSize:=System.FileSize(F) ELSE
  BEGIN
   I:=BuscarFichero(handleof(f));
   filesize:=PACKEDDATA[I].Tamano
  END;
END;

BEGIN
 FillChar(PACKEDDATA,SizeOf(PackedData),0);
 Assign(FAux,'NMPDATA.D00');
 System.Reset(Faux,1);
 ISPACKED:=system.IOResult=0;
 IF ISPACKED THEN System.Close(faux);
 DATAPTR:=0;
 NoSeek:=False;
END.