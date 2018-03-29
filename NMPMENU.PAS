UNIT NMPMenu;


INTERFACE
USES BitSet,ParaCaja,Crt,Dos;

CONST SingleCaracGraf:regGraf=(
      VerticeSI  : #218;
      VerticeSD  : #191;
      VerticeII  : #192;
      VerticeID  : #217;
      BarraH     : #196;
      BarraV     : #179;
      Cruz       : #197;
      TAbajo     : #193;
      TArriba    : #194;
      TDerecha   : #180;
      TIzquierda : #195
     );

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


TYPE SAVESCREEN=PROCEDURE;

FUNCTION Menu(X,Y:Byte;Info:MenuDef):Shortint;

PROCEDURE InstalarSalvaPantallas(P:SAVESCREEN);

Procedure SetAttr(X,Y,Attr:Byte);

VAR TimerCount:Longint;
    Timer:Longint ABSOLUTE $0040:$006C;

IMPLEMENTATION

VAR SalvaPantallas:SAVESCREEN;


PROCEDURE InstalarSalvaPantallas(P:SAVESCREEN);
BEGIN
 TimerCount:=Timer;
 SalvaPantallas:=P
END;


{$I CURSON.SRC}
{$I CURSOFF.SRC}
{$I TOMATEC.SRC}
{$I Pantalla.Poo}
VAR P:Pantalla;


FUNCTION MONOCROMO : Boolean; Assembler;
 ASM
  INT 17
  OR AX,30h
  CMP AX,30h
  JZ @CIERTO
  AND AX,AX
  JMP @FIN
  @CIERTO:
  MOV AX,1
  @FIN:
END;


Procedure SetAttr(X,Y,Attr:Byte);
VAR SegmenVideo:Word;
BEGIN
 DEC(X);DEC(Y);
 IF Monocromo THEN SegmenVideo:=$B800 ELSE SegmenVideo:=$B000;
 Mem[SegMenVideo:(80*Y+X)*2+1]:=Attr
END;



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
  2:Salida:=(ch IN [#13,#27]) OR (Extend AND ((Explor=75) OR (Explor=77)));
  3:Salida:=(ch IN [#13,#27]) OR (Extend AND ((Explor=75) OR (Explor=77) OR (Explor=59)))
 END;
END;


PROCEDURE Show;
VAR ST,St2:String;
    I:Byte;
BEGIN
 St:='';
 FOR I:=1 TO info.long+1 DO St:=St+' ';
 TextAttr:=Info.AttrMenu;
 CaracGraf:=Singlecaracgraf;
 Hacercaja(X, Y, info.long+4, Info.NOpciones + 2, CaracGraf);
 FOR I := 1 TO Info.NOpciones DO
  BEGIN
   GotoXY(X+1,Y+I);
   St2:=Info.Opciones[I];
   Teclas[I]:=St2[Pos('#',St2)+1];
   Delete(St2,Pos('#',St2),1);
   IF I=Barra THEN TextAttr:=Info.AttrBarra
              ELSE IF Btst(Info.Activas,I) THEN TextAttr:=Info.AttrMenu
                                           ELSE TextAttr:=Info.AttrOculto;
   Write( ' '+Copy ( St2+St, 1, info.long+1 ) );
   IF TextAttr<>Info.AttrOculto THEN
    BEGIN
     GotoXY(X+1+Pos('#',Info.Opciones[I]),Y+I);
     TextAttr:=Info.AttrAlt+TextAttr AND $F0;
     Write(Info.Opciones[I,Pos('#',Info.Opciones[I])+1]);
    END;
  END;
 TextAttr:=Info.AttrMenu;
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
 P.Salvar;
 CursorOff;
 SaveAttr:=TextAttr;
 Barra:=1;
 Next;
 Show;
 FOR Explor:=0 TO info.long+3 DO SetAttr(X+2+Explor,Y+Info.Nopciones+2,8);
 FOR Explor:=1 TO Info.NOpciones+1 DO
  BEGIN
   SetAttr(X+Info.long+4,y+explor,8);
   SetAttr(1+X+Info.long+4,y+explor,8);
  END;
 Ch:='¯';
 REPEAT
 IF i THEN BEGIN
            IF ((XR DIV 8+1) IN [X+1..X+1+info.long]) AND
               ((YR DIV 8+1) IN [Y+1..Y+1+Info.NOpciones])
                THEN Ch:=Teclas[YR DIV 8-Y];
           END;
 IF Tomatecla(Ch,extend,explor,camb) THEN TimerCount:=Timer;
 GotoXY(70,24);
 IF Timer>TimerCount+540 THEN SalvaPantallas;
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
   IF UpCase(Ch) IN ['A'..'Z','0'..'9'] THEN
    BEGIN
     FOR Explor:=1 To Info.NOpciones DO
      IF (UpCase(Teclas[Explor])=Upcase(Ch)) AND BTST(Info.Activas,Explor) THEN BEGIN
                                         Barra:=Explor;
                                         Ch:=#13;
                                         Show;
                                        END;
    END;

 UNTIL Salida;
 P.Recuperar;
 IF CH=#27 THEN Menu:=0
           ELSE IF Ch=#13 THEN Menu:=Barra
            ELSE IF Explor=75 THEN Menu:=-1
            ELSE IF Explor=59 THEN Menu:=-3  (* Ayuda *)
                              ELSE Menu:=-2;
 CursorOn;
 TextAttr:=SaveAttr;
END;

PROCEDURE IDLE; Far;
BEGIN
END;


BEGIN
 P.Inicializar(80,25);
 InstalarSalvaPantallas(IDLE);
END.
