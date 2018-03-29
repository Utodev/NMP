{--------------------------------------------------------------}
{                          ParaCaja                            }
{                                                              }
{      Unidad de demostraci¢n: dibujo de cajas de texto        }
{                                                              }
{                             Por Jeff Duntemann               }
{                             Turbo Pascal V5.0                }
{                             Ultima revisi¢n 13/7/88          }
{                                                              }
{--------------------------------------------------------------}


UNIT ParaCaja;


INTERFACE


USES crt;     { Para GotoXY }

TYPE
  RegGraf = RECORD
              VerticeSI,
              VerticeSD,
              VerticeII,
              VerticeID,
              BarraH,
              BarraV,
              Cruz,
              TAbajo,
              TArriba,
              TDerecha,
              TIzquierda : String[4]
            END;

VAR
  CaracGraf : RegGraf;  { Contiene las cadenas de dibujo para HacerCaja }
                        { Cualquier programa o unidad que use ParaCaja  }
                        { puede acceder a la variable CaracGraf igual   }
                        { que si estuviese definida en su propio cuerpo.}


{<<<< HacerCaja >>>>}
{ Esto es todo lo que necesita conocer el "mundo exterior" sobre      }
{ el procedimiento MakeBox. El "C¢mo" es irrelevante para utilizarlo. }

PROCEDURE HacerCaja(X,Y,Ancho,Alto   : Integer;
                    CaracGraf        : RegGraf);

PROCEDURE DefineCarac(VAR CaracGraf : RegGraf);


IMPLEMENTATION


{<<<< DefineCarac >>>>}
{ Este procedimiento es llamado desde la secci¢n de inicializaci¢n de la }
{ unidad, y se ocupa de cargar el registro CaracGraf con los caracteres  }
{ de dibujo de cajas. Es privativo de la unidad, y no puede ser llamada  }
{ desde el mundo exterior. Dado que no forma parte de INTERFACE, debemos }
{ dar aqu¡ la lista completa de par metros.                              }

PROCEDURE DefineCarac(VAR CaracGraf : RegGraf);

BEGIN
  WITH CaracGraf DO
    BEGIN
      VerticeSI  := Chr(201);
      VerticeSD  := Chr(187);
      VerticeII  := Chr(200);
      VerticeID  := Chr(188);
      BarraH     := Chr(205);
      BarraV     := Chr(186);
      Cruz       := Chr(206);
      TAbajo     := Chr(203);
      TArriba    := Chr(202);
      TDerecha   := Chr(185);
      TIzquierda := Chr(204)
    END
END;



{ <<<<HacerCaja>>>> }
{ Obs‚rvese que no es necesario repetir la l¡nea de par metros.   }
{ (Ya dimos la lista completa en la secci¢n INTERFACE).           }
{ Pero no produce ning£n perjuicio repetir aqu¡ la lista de       }
{ par metros. Esto har  m s f cil leer y entender el c¢digo       }
{ fuente de HacerCaja. }

PROCEDURE HacerCaja(X,Y,Ancho,Alto   : Integer;
                    CaracGraf        : RegGraf);

VAR
  I,J : Integer;

BEGIN
  IF X < 0 THEN X := (80-Ancho) DIV 2;    { Si X negativa, centrar caja }
  WITH CaracGraf DO
    BEGIN                                 { Dibujar la l¡nea superior }
      GotoXY(X,Y); Write(VerticeSI);
      FOR I := 3 TO Ancho DO Write(BarraH);
      Write(VerticeSD);
                                          { Dibujar la l¡nea inferior }
      GotoXY(X,(Y+Alto)-1); Write(VerticeII);
      FOR I := 3 TO Ancho DO Write(BarraH);
      Write(VerticeID);
                                          { Dibujar los lados }
      FOR I := 1 TO Alto-2 DO
        BEGIN
          GotoXY(X,Y+I); Write(BarraV);
          GotoXY((X+Ancho)-1,Y+I); Write(BarraV)
        END
    END
END;


{-------------------------------------------------------------------}
{ <<<< SECCION DE INICIALIZACION DE PARACAJA >>>>                   }
{ La secci¢n de inicializaci¢n se ejecuta antes de cualquier        }
{ programa Pascal que utilice ParaCaja. Aqu¡, la secci¢n de         }
{ inicializaci¢n carga una variable llamada  CaracGraf con carac-   }
{ teres de dibujo de cajas, de forma que la variable queda lista    }
{ para usar tan pronto como el bloque principal comienza su         }
{ ejecuci¢n. El programador no necesita conocer nada sobre el       }
{ procedimiento DefineCarac                                         }
{-------------------------------------------------------------------}

BEGIN
  DefineCarac(CaracGraf);
END.
