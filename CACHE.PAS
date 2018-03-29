UNIT CACHE;

{$I-}
{$X+}
{$R-}
{$S-}


{ XMS DISKCACHE                       }
{ CACHE DE DISCO (C) 1995 NM Software }
{ AUTOR: Carlos S nchez Garc¡a        }
{                                     }
{    TODOS LOS DERECHOS RESERVADOS    }
{                                     }
{ Queda estrictamente prohibido todo  }
{ uso de esta unidad sin el permiso   }
{ por escrito del autor. Esta unidad  }
{ est   protegida  por las leyes  de  }
{ propiedad intelectual y el uso sin  }
{ permiso de la misma podr  persegui- }
{ do por via penal o civil.           }
{                                     }

INTERFACE

USES XMS;

CONST MaxHandles=64;

VAR CACHEON:Boolean;
    CACHESIZE:LongInt;
    Numhandles:Byte;
    XMSVERSION:WORD;
    CacheBug:Word;
    AciertosCache,FallosCache:Longint;

VAR FCB:ARRAY[0..MaxHandles-1] OF RECORD
                         Handle:XMShandle;
                         USADA:Boolean;    (* Si este FCB est  usado *)
                         Veces:Byte;       (* Las veces que ha sido abierto *)
                         FILENAME:STRING[12];
                         FILESIZE:LongInt; (* Tama¤o del fichero *)
                         FILEPOS:LongInt;  (* Posici¢n en el fichero *)
                         OPEN:Boolean; (* Si un fichero est  abierto no se le *)
                        END;           (* puede expulsar de cach‚             *)



PROCEDURE BlockRead(VAR F:FILE;VAR Buffer;Size:Word;VAR Leidos:Word);
FUNCTION CACHEFree:LongInt;
PROCEDURE Reset(VAR F:FILE;recsize:Word);
PROCEDURE Close(VAR F:FILE);
FUNCTION EOF(VAR F:FILE):Boolean;
FUNCTION FilePos(VAR F:FILE):Longint;
FUNCTION FileSize(VAR F:FILE):Longint;
FUNCTION IOResult:Word;
PROCEDURE Seek(VAR F:FILE; n:Longint);
PROCEDURE VaciaCache;
FUNCTION ISPACKED:Boolean;


IMPLEMENTATION

USES PACKER;

VAR I:Byte;
    Handle:XMShandle;
    HMAExist:Boolean;
    InternalVersion:Word;
    P:ARRAY[0..1023] OF BYte;       (* Para cargar los ficheros *)
    IO:Word;

FUNCTION ISPACKED:Boolean;
BEGIN
 ISPACKED:=PACKER.Ispacked
END;


FUNCTION IOResult:Word;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      IOResult:=System.IOResult;
                      Exit
                     END;
 IOresult:=IO;
 IO:=0
END;



PROCEDURE ErrorCache(N:Byte);
BEGIN
 ASM
  MOV AX,3
  INT 10h
 END;
 IF N<>6 THEN
 Write('CACHE ERROR ##',N,' : ');
 CASE N OF
 1:Write('Fichero doblemente abierto.');
 2:Write('Error al liberar.');
 3:Write('Error al mover.');
 4:Write('Error al mover.');
 5:Write('Error al reservar XMS.');
 6:BEGIN END; (* Error al salir, lo ignoramos, si se cuelga luego :-( *)
 END;
 IF N<>6 THEN ASM
  MOV AX,0
  INT 16h
 END;
 IF N<>6 THEN Halt(N)
         ELSE Halt;
END;

FUNCTION CaCHEFREE:Longint;
BEGIN
 IF CACHEON THEN CacheFree:=MaxXMSAvail
            ELSE CacheFree:=0
END;



FUNCTION Getname(VAR F:FILE):String;
VAR P:^char;
    S:String;
    i:Byte;
BEGIN
 IF ISPACKED THEN getName:=Handle2name(Handleof(f)) ELSE
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
END;




FUNCTION BuscarVacio:Byte;
VAR I:Byte;
BEGIN
 I:=0;
 WHILE (I<NumHandles) AND FCB[I].Usada DO Inc(I);
 BuscarVacio:=I;
END;

FUNCTION HacerHueco(L:LongInt):Byte;
VAR Vez:Byte;
    I:Byte;
    MaxVeces:Byte;
BEGIN
 MaxVeces:=0;
 I:=0;
 WHILE (I<NumHandles) DO BEGIN
                  IF (FCB[I].Usada) AND (FCB[I].Veces>MaxVeces) THEN MaxVeces:=FCB[I].Veces;
                  INC(I);
                 END;
 (* ahora tengo en MaxVeces la cantidad de veces que ha sido usado el fichero
    m s usado *)

 Vez:=1;
 REPEAT
  I:=0;
  WHILE (I<NumHandles) AND (CacheFree*1024<L) DO
   BEGIN
    IF (FCB[I].Veces=Vez) AND NOT(FCB[I].Open) AND FCB[I].USada THEN
     BEGIN
      CacheBUG:=FreeXMSMem(FCB[I].Handle);
      IF CacheBug<>1 THEN ErrorCache(2);
      FCB[I].Usada:=False;
     END;
    Inc(I);
   END;
  IF CacheFree*1024>=L THEN BEGIN
                               HacerHueco:=I-1;
                               Exit
                              END;
   INC(Vez);
   IF Vez>MaxVeces THEN BEGIN
                         HacerHueco:=NumHandles;         (* Nada, que no hay manera *)
                         Exit
                        END;
   UNTIL FALSE;
END;

FUNCTION LiberarHandle:Byte;
VAR I:Byte;
    Maxveces:Byte;
    Vez:Byte;
BEGIN
 MaxVeces:=0;
 I:=0;
 WHILE (I<NumHandles) DO BEGIN
                  IF (FCB[I].Usada) AND (FCB[I].Veces>MaxVeces) THEN MaxVeces:=FCB[I].Veces;
                  INC(I);
                 END;
 (* ahora tengo en MaxVeces la cantidad de veces que ha sido usado el fichero
    m s usado *)
 I:=0;
 Vez:=1;
 REPEAT
  WHILE (I<NumHandles) AND NOT ((FCB[I].Usada) AND (FCB[I].Veces=Vez)) DO INC(I);
  Inc(Vez);
 UNTIL (I<>NumHandles) OR ((I=NumHandles) AND (Vez>MaxVeces));
 IF I<NumHandles THEN BEGIN
                       CacheBug:=FreeXMSMem(FCB[I].Handle);
                       IF CacheBug<>1 THEN ErrorCache(2);
                       FCB[I].Usada:=False
                      END;
 LiberarHandle:=I
END;


FUNCTION BuscarEspacio(L:Longint):Byte;
VAR AUX:Byte;
BEGIN
 Aux:=NumHandles;
 IF CacheFree*1024>=L THEN AUX:=BuscarVacio;
 IF AUX<>NumHandles THEN BEGIN
                  BuscarEspacio:=Aux;
                  Exit
                 END;
 IF CacheFree*1024>=L THEN BEGIN      (* Si hay memoria pero no hay vacio *)
                              BuscarEspacio:=LiberarHandle;
                              Exit
                             END;
 AUX:=HacerHueco(L);
 BuscarEspacio:=Aux;
END;


PROCEDURE AbrirFichero(VAR F:FILE);
VAR Size:LongInt;
    FCB_N:Byte;
    Size2:Word;
    Offset:LongInt;
    leidos:word;

BEGIN
 Inc(FallosCache);
 Size:=packer.FileSize(F);
 IF Size>CacheSize*1024 THEN Exit;
 FCB_N:=BuscarEspacio(Size);
 IF FCB_N=NumHandles THEN Exit;   (* No hay XMS suficiente para el fichero entero *)
 WITH FCB[FCB_N] DO
  BEGIN
   CacheBug:=GetXMSMem(Handle,(Size DIV 1024)+1);
   IF CacheBug<>1 THEN ErrorCache(5);
   Filename:=GetName(F);
   Usada:=True;
   Veces:=1;
   Open:=True;
   FileSize:=Size;
   FilePos:=0;
   Offset:=0;
   WHILE NOT packer.EOF(F) DO
    BEGIN
     system.BlockRead(F,P,1024,leidos);
     IF Odd(Leidos) THEN INC(Leidos);
     CacheBug:=XMSMove(0,longint(@p),Handle,Offset,Leidos);
     IF CacheBug<>1 THEN ErrorCache(3);
     INC(Offset,leidos);
    END;
 END; (* WITH *)
END;



FUNCTION BuscarFichero(S:String):Byte;
VAR I:Byte;
BEGIN
 I:=0;
 WHILE (i<NumHandles) AND NOT ((FCB[I].Usada) AND (FCB[I].FileName=S)) DO Inc(I);
 BuscarFichero:=I
END;

PROCEDURE Reset(VAR F:FILE;recsize:Word);
VAR FCB_N:Byte;
BEGIN
 IF CacheON THEN
  BEGIN
   NoSeek:=true;
   packer.Reset(F,recsize);
   IO:=system.IOresult;
   IF IO<>0 THEN Exit;
   FCB_N:=BuscarFichero(GetName(F));
   IF FCB_N =NumHandles THEN BEGIN
                              ColocaPrincipio(F);
                              AbrirFichero(F);
                             END
                ELSE BEGIN
                      Inc(AciertosCache);
                      CacheBug:=0;
                      IF FCB[FCB_N].Open THEN ErrorCache(1);
                      INC(FCB[FCB_N].Veces);
                      IF FCB[FCB_N].Veces>50 THEN FCB[FCB_N].Veces:=50;
                        (* Si se repite m s de 50 veces ya no le subo m s el privilegio *)
                      FCB[FCB_N].Open:=True;
                      FCB[FCB_N].FilePos:=0;
                     END;
  END
 ELSE packer.Reset(F,recsize);
END;

PROCEDURE Close(VAR F:FILE);
VAR FCB_N:Byte;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      packer.Close(F);
                      exit
                     END;
 FCB_N:=BuscarFichero(GetName(F));
 IF FCB_N<>NumHandles THEN FCB[FCB_N].Open:=False;
 packer.Close(F);
END;


FUNCTION EOF(VAR F:FILE):Boolean;
VAR FCB_N:Byte;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      EOF:=packer.EOF(F);
                      Exit
                     END;
 FCB_N:=BuscarFichero(GetName(F));
 IF FCB_N=NumHandles THEN EOF:=packer.EOF(F)
                     ELSE EOF:=FCB[FCB_N].FileSize=FCB[FCB_N].FilePos;
END;

FUNCTION FIlePos(VAR F:FILE):LongInt;
VAR FCB_N:Byte;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      FilePos:=packer.FilePos(F);
                      Exit
                     END;
 FCB_N:=BuscarFichero(GetName(F));
 IF FCB_N=NumHandles THEN FilePos:=packer.FilePos(F)
                     ELSE FilePos:=FCB[FCB_N].FilePos;
END;

FUNCTION FileSize(VAR F:FILE):Longint;
VAR FCB_N:Byte;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      FileSize:=packer.FileSize(F);
                      Exit
                     END;
 FCB_N:=BuscarFichero(GetName(F));
 IF FCB_N=NumHandles THEN FileSize:=packer.FileSize(F)
                     ELSE FileSize:=FCB[FCB_N].FileSize;
END;



PROCEDURE Seek(VAR F:FILE; n:Longint);
VAR FCB_N:Byte;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      packer.Seek(F,N);
                      Exit
                     END;
 FCB_N:=BuscarFichero(GetName(F));
 IF FCB_N=NumHandles THEN packer.Seek(F,N)
                     ELSE IF N<FCB[FCB_N].FileSize THEN FCB[FCB_N].FilePos:=N
                                                   ELSE FCB[FCB_N].FilePos:=FCB[FCB_N].FileSize
END;

PROCEDURE VaciaCache;
BEGIN
 IF NOT CACHEON THEN Exit;
 FOR I:=0 TO NumHandles-1 DO IF
  FCB[I].Usada THEN BEGIN
                     IF FCB[I].Usada THEN
                      BEGIN
                       CacheBug:=FreeXMSMem(FCB[I].Handle);
                       IF CacheBug<>1 THEN ErrorCache(6);
                      END;
                     FCB[I].Usada:=False;
                     FCB[I].FileName:='@@VACIA@@';
                    END;
END;


PROCEDURE BlockRead(VAR F:FILE;VAR Buffer;Size:Word;VAR Leidos:Word);
VAR FCB_N : Byte;
    W:Word;
    Odd:Boolean;
BEGIN
 IF NOT CACHEON THEN BEGIN
                      system.BlockRead(F,Buffer,Size,leidos);
                      Exit
                     END;
 FCB_N:=BuscarFichero(GetName(F));
 IF FCB_N=NumHandles THEN system.BlockRead(F,Buffer,Size,Leidos)
             ELSE WITH FCB[FCB_N] DO
                   BEGIN
                    IF FilePos+Size>=FileSize THEN BEGIN
                                                    Leidos:=FileSize-FilePos;
                                                    Size:=Leidos
                                                   END ELSE Leidos:=Size;
                    Odd:=system.Odd(Size);
                    IF Odd THEN Dec(Size);
                    CacheBug:=1;
                    IF Size>0 THEN CacheBug:=XMSMOVE(Handle,FilePos,0,longint(@Buffer),Size);
                    IF CacheBug<>1 THEN ErrorCache(3);
                    Inc(FilePos,Size);
                    IF Odd THEN BEGIN
                                 Cachebug:=XMSMove(handle,filepos,0,longint(@W),2);
                                 IF CacheBug<>1 THEN ErrorCache(4);
                                 Move(W,pointer(longint(@buffer)+size)^,1);
                                 Inc(FilePos);
                                END
                   END;
END;



VAR Code:Integer;
    Size2:LongInt;
    handles2:Byte;
BEGIN
 FillChar(FCB,SizeOf(FCB),0);
 AciertosCache:=0;
 FallosCache:=0;
 IF EXISTXMS THEN
  BEGIN
   GetXMSVersionNumber(XMSVersion,internalversion,HMAExist);
   XMSVersion:=(XMSVERSION AND $FF00) OR ((Lo(XMSVERSION) DIV 16) *10 + Lo(XMSVERSION) MOD 16);
   getXMSMem(Handle,1);
   NumHandles:=GetNumHandles(Handle);
   FreeXmsMem(Handle);
   IF NumHandles>MaxHandles THEN NumHandles:=MaxHandles;
   CacheSize:=MaxXMSAvail;
   CACHEON:=(NumHandles>2);
  END ELSE CACHEON:=False;
END.
