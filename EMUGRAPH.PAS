UNIT EMUGRAPH;

{$s-,r-,i-,x+}


INTERFACE

VAR GETX,GETY:Word;
    Colors:ARRAy[0..3] OF Byte;

PROCEDURE Moveto(XX,YY:WOrd);

IMPLEMENTATION

PROCEDURE Moveto(XX,YY:WOrd);
BEGIN
 GetX:=XX;
 getY:=YY
END;


BEGIN
 GetX:=0;
 gety:=0;
 Colors[0]:=0;
 Colors[1]:=7;
 Colors[2]:=0;
END.





