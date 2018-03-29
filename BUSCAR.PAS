

UNIT BUSCAR;

{$s-}
{$i-}
{$r-,o+}
INTERFACE


PROCEDURE BUSCAPRIMERO(VAR S:String);
PROCEDURE BUSCASIGUIENTE(VAR S:String);
PROCEDURE ACABaBUSQUEDA;
FUNCTION GetSize:Longint;

IMPLEMENTATION
VAR F:FILE;
    ST:RECORD
        N:String[12];
        A,B:Longint
       END;

FUNCTION GetSize:Longint;
BEGIN
 getSize:=ST.B
END;

 PROCEDURE BUSCAPRIMERO(Var S:String);
 BEGIN
  Assign(F,'NMPDATA.D00');
  System.Reset(F,1);
  BuscaSiguiente(S);
 END;

 PROCEDURE BuscaSiguiente(var S:String);
 BEGIN
  S:=Copy(S,Pos('.',S),255);
  ST.N:='@@*';
  WHILE (NOT System.EOF(F)) AND (Pos(S,ST.N)=0) DO
    System.BlockRead(F,ST,21);
  IF Pos(S,St.N)=0 THEN S:='' ELSE S:=St.N;
  END;

  PROCEDURE ACABABUSQUEDA;
  BEGIN
   System.Close(F)
  END;
END.