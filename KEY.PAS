USES CRT,dos;

{$I TOMATEC.SRC}
{$I CURSOFF.SRC}
{$I CURSON.SRC}

VAR Ch:Char;
Ex:Boolean;
exp,camb:byte;

BEGIN
TextAttr:=$1F;
Window(3,4,78,21);
Clrscr;
CursorOff;
WriteLn;
Write(' Pulsa una tecla ...');
 REPEAT
  GotoXy(1,1);
  IF Tomatecla(ch,ex,exp,camb) THEN
   BEGIN
    Clrscr;
    WriteLn;
    WriteLn(' CODIGO ASCII : ',Byte(Ch));
    IF Ch=#0 THEN WriteLn(' CODIGO EXTENDIDO : ',exp);
    IF Byte(Ch)>31 THEN WriteLn(' CARACTER ASOCIADO : ',Ch)
   END;
 UNTIL Ch=#27;
CursorOn;
Window(1,1,80,25);
END.