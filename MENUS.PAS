UNIT Menus;


INTERFACE
USES RatonASM,BitSet,ParaCaja,Crt,Dos;

CONST maxlong = 20;
      MaxOpciones=10;

TYPE MenuDef = RECORD
                NOpciones:Byte; (* N§ de opciones real *)
                long:Byte;      (*longitud de opcion m s larga *)
                Exit:Byte;      (*  0 --> Salir s¢lo con ENTER (fuerza opcion)
                                    1 --> Salir con enter o ESC (devuelve 0)
                                    2 --> Salir con enter,esc o cursores derecha
                                          o izquierda (devuelve -1 o -2)   *)

                Opciones:ARRAY [1..MaxOpciones] OF String[maxlong];

                Activas:ARRAY [1..MaxOpciones DIV 8+1] OF Byte;

                AttrMenu:Byte;                (*  ^Se usa como BITMAP*)
                AttrBarra:Byte;
                AttrOculto:Byte;
                AttrSombra:Byte;
                AttrAlt:Byte;
               END;

FUNCTION Menu(X,Y:Byte;Info:MenuDef):Shortint;

IMPLEMENTATION

{$I CURSON.SRC}
{$I CURSOFF.SRC}
{$I TOMATEC.SRC}

FUNCTION Menu(X,Y:Byte;Info:MenuDef):Shortint;
VAR Teclas:ARRAY[1..MaxOpciones] OF Char;
    Barra:Byte;
    SaveAttr:Byte;
    Ch:Char;
    Extend:Boolean;
    Explor,Camb:Byte;
    XR,YR:Word;
    i,c,d:Boolean;


FUNCTION Salida:Boolean;
BEGIN
 CASE INFO.EXIT OF
  0:Salida:=Ch=#13;
  1:Salida:=ch IN [#13,#27];
  2:Salida:=(ch IN [#13,#27]) OR (Extend AND ((Explor=75) OR (Explor=77)))
 END;
END;

PROCEDURE Show;
VAR ST,St2:String;
    I:Byte;
BEGIN
 St:='';
 FOR I:=1 TO info.long+1 DO St:=St+' ';
 TextAttr:=Info.AttrMenu;
 Hacercaja(X, Y, info.long+4, Info.NOpciones + 4, CaracGraf);
 FOR I := 1 TO Info.NOpciones DO
  BEGIN
   GotoXY(X+1,Y+1+I);
   St2:=Info.Opciones[I];
   Teclas[I]:=St2[Pos('#',St2)+1];
   Delete(St2,Pos('#',St2),1);
   IF I=Barra THEN TextAttr:=Info.AttrBarra
              ELSE IF Btst(Info.Activas,I) THEN TextAttr:=Info.AttrMenu
                                           ELSE TextAttr:=Info.AttrOculto;
   Write( ' '+Copy ( St2+St, 1, info.long+1 ) );
   IF TextAttr<>Info.AttrOculto THEN
    BEGIN
     GotoXY(X+1+Pos('#',Info.Opciones[I]),Y+1+I);
     TextAttr:=Info.AttrAlt+TextAttr AND $F0;
     Write(Info.Opciones[I,Pos('#',Info.Opciones[I])+1]);
    END;
  END;
 TextAttr:=Info.AttrMenu;
 GotoXY( X+1 , Y+1); Write(St+' ');
 GotoXY( X+1 , Y+2+Info.NOPciones); Write(St+' ');
END;

PROCEDURE Next;
BEGIN
 WHILE NOT BTST(Info.Activas,Barra) DO BEGIN
                                   Inc(Barra);
                                   IF Barra>Info.NOpciones THEN Barra:=1
                                  END;
END;

PROCEDURE Previous;
BEGIN
 WHILE NOT BTST(Info.Activas,Barra) DO BEGIN
                                   dec(Barra);
                                   IF Barra<1 THEN Barra:=Info.NOpciones
                                  END;
END;

BEGIN
 CursorOff;
 SaveAttr:=TextAttr;
 Barra:=1;
 Next;
 Show;
 GotoXY(X+2,Y+Info.NOPciones+4);
 TextAttr:=Info.AttrSombra;
 FOR Explor:=1 TO info.long+4 DO
  Write('±');
 FOR Explor:=1 TO Info.NOpciones+3 DO
  BEGIN
   GotoXY(X+info.long+4,Y+Explor);
   Write('±±')
  END;
 Ch:='¯';
{ PunteroOn;}
 PunteroaXY(1,1);
 REPEAT
 LeerRaton(XR,YR,i,c,d);
 IF i THEN BEGIN
            IF ((XR DIV 8+1) IN [X+1..X+1+info.long]) AND
               ((YR DIV 8+1) IN [Y+1..Y+1+Info.NOpciones])
                THEN Ch:=Teclas[YR DIV 8-Y];
           END;
 Tomatecla(Ch,extend,explor,camb);
    IF Extend AND (Explor=80) THEN BEGIN
                                    Inc(Barra);
                                    IF Barra>Info.NOpciones THEN Barra:=1;
                                    Next;
                                    Show;
                                   END;
    IF Extend AND (Explor=72) THEN BEGIN
                                    Dec(Barra);
                                    IF Barra<1 THEN Barra:=Info.NOpciones;
                                    Previous;
                                    Show;
                                   END;
   IF UpCase(Ch) IN ['A'..'Z'] THEN
    BEGIN
     FOR Explor:=1 To Info.NOpciones DO
      IF (UpCase(Teclas[Explor])=Upcase(Ch)) AND BTST(Info.Activas,Explor) THEN BEGIN
                                         Barra:=Explor;
                                         Ch:=#13;
                                         Show;
                                        END;
    END;

 UNTIL Salida;
 IF CH=#27 THEN Menu:=0
           ELSE IF Ch=#13 THEN Menu:=Barra
            ELSE IF Explor=75 THEN Menu:=-1
                              ELSE Menu:=-2;
 CursorOn;
 TextAttr:=SaveAttr;
 PunteroOff;
END;

END.