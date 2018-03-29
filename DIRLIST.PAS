UNIT DIRLIST;

INTERFACE

USES DOS,crt;
 FUNCTION SELECTFILE(FileSpec:String;VAR Path:String;X,Y:Byte;Lineas:Byte):String;


IMPLEMENTATION

 CONST MAXFILES=1024; (* n§ m ximo de ficheros que soporta *)

 VAR TABLE:ARRAY[0..MaxFiles-1] OF RECORD
                                    Nombre:String[12];
                                    Attr:Word
                                   END;
     NUMFILE:Word;

{$I CURSOFF.SRC}

 PROCEDURE MAKELIST(PATH,FILESPEC:STRING);
 VAR SR:Searchrec;
     I:Word;
     Spec:String;
     EsRaiz:Boolean;

 PROCEDURE ListaDrive(VAR I:Word);
 VAR D:Byte;
 BEGIN
  FOR D:=3 TO 20 DO
   BEGIN
    IF(DiskFree(D)<>-1) AND NOT(Byte(Path[1]) IN [D+64,D+96]) THEN BEGIN
                             TABLE[I].nombre:=Char(D+64)+':';
                             INC(I)
                            END;


   END;
 END;


 BEGIN
  IF FileSpec[byte(FileSpec[0])]<>';' THEN FileSpec:=FileSpec+';';
  I:=0;
  Esraiz:=True;
  FindFirst(PATH+'\*.*',DIRECTORY,SR);
  WHILE DosError=0 DO
   BEGIN
    IF (SR.NAME<>'.') AND (SR.Attr=DIRECTORY) THEN BEGIN
                          TABLE[I].Nombre:=SR.NAme;
                          TABLE[I].ATTR:=SR.Attr;
                          INC(I);
                         END;
    IF SR.Name='.' THEN EsRaiz:=FalsE;
    FindNext(SR);
   END;
  WHILE POS(';',FileSpec)<>0 DO
  BEGIN
   Spec:=Copy(FileSpec,1,Pos(';',FileSpec)-1);
   FileSpec:=Copy(FileSpec,Pos(';',FileSpec)+1,255);
   FindFirst(PATH+'\'+Spec,ANYFILE,SR);
   WHILE DosError=0 DO
    BEGIN
     TABLE[I].Nombre:=SR.NAme;
     TABLE[I].ATTR:=SR.Attr;
     INC(I);
     FindNext(SR);
    END;
   END;
  IF EsRaiz THEN ListaDrive(I);
  DEC(I);
  NUMFILE:=I
 END;

{$I TOMATEC.SRC}

CONST SPACES='                                                                 ';

FUNCTION NORMAL(S:String;N:Byte):String;
BEGIN
 Normal:=S+Copy(Spaces,1,N-byte(S[0]))
END;



 FUNCTION SELECTFILE(FileSpec:String;VAR Path:String;X,Y:Byte;Lineas:Byte):String;
 VAR BASE:Word;
     PTR:Word;
     Ch:Char;
     Extend:Boolean;
     Explor,Camb:Byte;
     I:Byte;

 PROCEDURE ChangeDIR;
 BEGIN
  IF TABLE[PTR].NOMBRE='..' THEN BEGIN
                                  WHILE PATH[byte(path[0])]<>'\' DO Path:=COpy(Path,1,byte(path[0])-1);
                                  Path:=COpy(Path,1,byte(path[0])-1);
                                  MAKELIST(PATH,FileSpec);
                                  Exit;
                                 END;
  PATH:=PATH+'\'+TABLE[PTR].Nombre;
  MAKELIST(PATH,FileSpec);
 END;

 PROCEDURE ChangeDrive;
 BEGIN
  PATH:=TABLE[PTR].nombre;
  MAKELIST(PATH,FileSpec);
 END;

 VAR S:String[13];

 BEGIN
  CursorOff;
  MAKELIST(PATH,FileSpec);
  BASE:=0;
  PTR:=0;
  REPEAT
   REPEAT
    FOR I:=0 TO Lineas-1 DO
     BEGIN
      GotoXY(X,Y+I);
      IF BASE+I=PTR THEN TextAttr:=$3E
                    ELSE TextAttr:=$30;
      S:=' '+TABLE[BASE+I].Nombre;
      IF TABLE[BASE+I].Attr=DIRECTORY THEN S:=S+'\'
                                      ELSE S:=S+' ';
      IF BASE+I>NUMFILE THEN S:='';
      Write(Normal(S,14));
     END;
     REPEAT UNTIL Tomatecla(Ch,Extend,explor,camb);
     IF EXTEND THEN CASE EXPLOR OF
                     72:BEGIN
                         IF PTR>0 THEN DEC(PTR);
                         IF PTR<BASE THEN DEC(BASE);
                        END;
                     80:BEGIN
                         IF PTR<NUMFILE THEN INC(PTR);
                         IF BASE+Lineas-1<PTR THEN INC(BASE);
                        END;
                     81:BEGIN
                         IF PTR+Lineas<=NUMFILE THEN BEGIN
                                                      INC(PTR,Lineas);
                                                      Base:=PTR;
                                                     END;
                        END;
                     73:BEGIN
                         IF PTR>=Lineas THEN BEGIN
                                              DEC(PTR,LINEAS);
                                              BASE:=PTR
                                             END
                                             ELSE
                                             BEGIN
                                              PTR:=0;
                                              BASE:=0
                                             END;
                       END;
                    END;
   UNTIL CH IN [#27,#13];
   IF CH=#13 THEN IF TABLE[PTR].Nombre[2]=':' THEN BEGIN
                                                    CHANGEDRIVE;
                                                    BASE:=0;
                                                    PTR:=0;
                                                    Ch:=#0;
                                                   END;
   IF CH=#13 THEN IF TABLE[PTR].ATTR=DIRECTORY THEN BEGIN
                                                     CHANGEDIR;
                                                     BASE:=0;
                                                     PTR:=0;
                                                     Ch:=#0
                                                    END;
  UNTIL ((Ch=#13) AND (TABLE[PTR].ATTR<>DIRECTORY)) OR (ch=#27);
  IF Ch=#27 THEN SelectFile:=''
            ELSE SelectFile:=Path+'\'+TABLE[PTR].Nombre;
 END;

 end.