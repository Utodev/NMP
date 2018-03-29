

UNIT Params;
{$S-,R-,I-}


(*****************************************************************)
(* UNIDAD PARA TURBO PASCAL QUE IMPLEMENTA RUTINAS ALTERNATIVAS  *)
(* A ParamCount y ParamStr, IMPLEMENTANDO LA POSIBILIDAD DE USAR *)
(* FICHEROS INCLUDE Y AMPLIANDO A 2048 BYTES LOS PARAMETROS.     *)
(*****************************************************************)
(* LA UNIDAD QUEDA PARA EL DOMINIO PUBLICO, AHORA, SED MAJOS     *)
(* Y AL MENOS NOMBRADME EN LOS AGRADECIMIENTOS SI DISTRIBUIS     *)
(* UN PROGRAMA CON MIS RUTINAS.                                  *)
(*****************************************************************)
(* Autor: Carlos S nchez                                         *)
(* Compilador necesario : Turbo Pascal 6.0                       *)
(*                                                               *)
(*****************************************************************)



(* EJEMPLO DE FICHERO INCLUDE:

   MI_EXE.EXE -p /r03 -H @MI_EXE.INI /R /nosound


   En este caso cada l¡nea del fichero MI_EXE.INI ser¡a a¤adida como
   par metros justo en la posici¢n del par metro @MI_EXE.INI. Por tanto
   /R no tiene por que ser el quinto par metro, depender  de cuantos haya
   en el fichero INCLUDE.

   Nota: Se admiten varios includes, pero no se admite anidamiento. Dicho de
   otra forma: si en un fichero include aparece un par metro que comienza por
   '@', ser  tomado como un par metro normal.

*)


(* Otro detalle: En los ficheros include, las l¡neas que comienzan por '#',
   por '|', por '%' o por ';' se consideran comentarios y se ignoran. Adem s,
   los comentarios v lidos deben estar situados en la primera columna, pues
   si hay espacios delante confundir n a las rutinas.
   En los ficheros include se puede poner m s de un par metro por l¡nea, para
   ello hay que separarlos por un £nico espacio *)

{$I-,R-,S-}

INTERFACE

FUNCTION ParamStr(W:Word):String;
FUNCTION ParamCount:Word;

PROCEDURE AddFile(S:String);
(* Permite que se a¤ada manualmente un fichero a los par metros. Cada l¡nea  *)
(* de este se considerar  un par metro, al igual que en los ficheros include *)
(* Es util para a¤adir ficheros .INI y luego leer juntos par metros y lo del *)
(* fichero                                                                   *)

IMPLEMENTATION

CONST SizeParams=2048;

VAR ParamASCIIZ:^char;
    Pos:Word;
    I:Word;
    S:String;


PROCEDURE Error(N:Byte);
BEGIN
 ASM
  MOV AX,3
  INT 10h
 END;
 Write('Error en par metros : ');
 CASE N OF
  1:WriteLn('Demasiados par metros.');
  2:WriteLn('Fichero no se encuentra.');
 END;
 Halt(N)
END;

PROCEDURE AddFile(S:String);
CONST COMENT:SET OF CHAR=['#','|',';','%'];
VAR F:Text;
BEGIN
 Assign(F,S);
 reset(F);
 IF IOResult<>0 THEN Error(2);
 WHILE NOT EOF(F) DO
  BEGIN
   ReadLn(F,S);
   IF NOT (S[1] IN COMENT) AND (S<>'') THEN
    BEGIN
     IF Byte(S[0])+Pos+1>=SizeParams THEN Error(1);
     Move(S[1],pointer(longint(ParamASCIIZ)+Pos)^,byte(S[0]));
     Inc(Pos,byte(S[0]));
     char(pointer(longint(ParamASCIIZ)+Pos)^):=' ';
     Inc(pos);
    END;
  END;
 Close(F);
END;

FUNCTION ParamStr(W:Word):String;
VAR I,J:Word;
    S:String;
    P:^char;
BEGIN
 I:=ParamCount;
 IF (W>I) THEN S:=''
          ELSE IF W=0 THEN S:=System.ParamStr(0)
 ELSE BEGIN
       Pointer(P):=ParamASCIIZ;
       J:=0;
       DEC(W);
       WHILE J<W DO BEGIN
                     IF p^=' ' THEN INC(J);
                     INC(longint(p));
                    END;
       S:='';
       WHILE P^<>' ' DO BEGIN
                         S:=S+P^;
                         INC(longint(p))
                        END;
      END;
 ParamStr:=S;
END;

FUNCTION ParamCount:Word; Assembler;
ASM
 XOR BX,BX
 PUSH DS
 LDS SI,ParamASCIIZ
@BUCLE:
 LODSB
 OR AL,AL
 JZ @ya
 CMP AL,32
 JNZ @BUCLE
 INC BX
 JMP @BUCLE
@YA:
 MOV AX,BX
 POP DS
END;


BEGIN (* StartUp *)
 GetMem(pointer(ParamASCIIZ),SizeParams);
 Pos:=0;
 FOR I:=1 TO System.ParamCount DO
  BEGIN
   S:=System.ParamStr(I);
   IF Copy(S,1,1)='@' THEN AddFile(Copy(S,2,255))
                      ELSE BEGIN
                             IF Byte(S[0])+Pos+1>=SizeParams THEN Error(1);
                             Move(S[1],pointer(longint(ParamASCIIZ)+Pos)^,byte(S[0]));
                             Inc(Pos,byte(S[0]));
                             char(pointer(longint(ParamASCIIZ)+Pos)^):=' ';
                             Inc(pos);
                            END;
  END;
 char(pointer(longint(ParamASCIIZ)+Pos)^):=#0;
END.


