UNIT PILACOLA;
{$i-}
{$s-}
{$r-}
{$x+}
{$o+}

INTERFACE

TYPE

 (*Definicion de tipos de la pila*)
 tPuntero = ^tElempila;

 tElemPila = record
              dato:word;
              sig:tPuntero
             end;

 Cabeza = record
           Num:Word;
           Primero:tPuntero
          end;

 tPila = ^Cabeza;

 (*Idem de la COla*)

 tPunt= ^tELemCola;

 tElemCola = record
              dato:word;
              anterior:tPunt
             end;

 tCabeza = record
            num:word;
            cabeza,cola:tPunt
           end;

 tCola = ^tCabeza;


PROCEDURE CREAR(var npila:tPila);
PROCEDURE PUSH(var npila:tPila;elemento:word);
PROCEDURE POP(var npila:tpila;var elemento:word);
PROCEDURE LOOK(var npila:tpila;var elemento:word);
PROCEDURE CREARC(var ncola:tcola);
PROCEDURE PUSHC(var nCola:tCola;elemento:word);
PROCEDURE LOOKC(ncola:tCola;var elemento:word);
PROCEDURE POPC(var ncola:tCola;var elemento:word);
FUNCTION VACIAC(nCola:tCola):Boolean;
FUNCTION VACIA(nPila:tPila):Boolean;


IMPLEMENTATION

PROCEDURE CREAR(var npila:tPila);
BEGIN
 new(npila);
 npila^.num:=0;
 npila^.primero:=nil;
END;

PROCEDURE PUSH(var npila:tPila;elemento:word);
VAR aux:tPuntero;
BEGIN
new (aux);
aux^.dato:=elemento;
aux^.sig:=npila^.primero;
npila^.primero:=aux;
INC(npila^.num)
END;

PROCEDURE POP(var npila:tpila;var elemento:word);
var aux:tPuntero;
begin
if npila^.num > 0 THEN
BEGIN
 elemento:=npila^.primero^.dato;
 aux:=npila^.primero;
 npila^.primero:=npila^.primero^.sig;
 dec(npila^.num);
 dispose(aux)
END
ELSE elemento:=0
END;

PROCEDURE LOOK(var npila:tpila;var elemento:word);
var aux:tPuntero;
begin
if npila^.num > 0 THEN
 elemento:=npila^.primero^.dato
  ELSE elemento:=0
END;


(*Ahora proced de la cola*)

PROCEDURE CREARC(var ncola:tcola);
BEGIN
new(ncola);
ncola^.num:=0;
ncola^.cabeza:=nil;
ncola^.cola:=nil
end;

PROCEDURE PUSHC(var nCola:tCola;elemento:word);
var aux:tPunt;
BEGIN
New(aux);
aux^.dato:=elemento;
aux^.anterior:=nil;
WITH ncola^ DO
 IF num= 0 THEN
            BEGIN
             Cabeza:=aux;
             Cola:=aux;
             num:=1
            END
           ELSE
            BEGIN
             Cabeza^.anterior:=aux;
             cabeza:=aux;
             inc(num)
            END
END;

PROCEDURE LOOKC(ncola:tCola;var elemento:word);
BEGIN
if ncola^.num =0 THEN elemento:=0
                 else elemento:=ncola^.cola^.dato
END;

PROCEDURE POPC(var ncola:tCola;var elemento:word);
var aux:tPunt;
BEGIN
IF nCola^.num = 0 THEN elemento:=0
                  ELSE BEGIN
                        elemento:=ncola^.cola^.dato;
                        aux:=ncola^.cola;
                        ncola^.cola:=ncola^.cola^.anterior;
                        dispose(aux);
                        dec (ncola^.num)
                       END;

END;

FUNCTION VACIAC(nCola:tCola):Boolean;
BEGIN
VACIAC:=nCola^.num=0
END;

FUNCTION VACIA(nPila:tPila):Boolean;
BEGIN
VACIA:=nPila^.num=0
END;


END.