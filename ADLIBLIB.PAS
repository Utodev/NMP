(***************************************************************************)
(*                                                                         *)
(* Nombre Unidad: ADLIB LIBRARY                                            *)
(*                                                                         *)
(* Autor        : Carlos S nchez                                           *)
(*                                                                         *)
(* Objetivo     : Controlar la m£sica FM de la tarjeta Adlib.              *)
(*                                                                         *)
(* Compilador   : TP 6.0 o superior                                        *)
(*                                                                         *)
(***************************************************************************)
(*                                                                         *)
(*                      TODOS LOS DERECHOS RESERVADOS                      *)
(*                               ... pero ....                             *)
(*     Dominio P£blico: C¡tame si las usas y no me responsabilizo de nada  *)
(***************************************************************************)

UNIT ADLIBLIB;

INTERFACE

USES CRT;

TYPE InstType=ARRAy[$24..$33] OF Byte;
     (* Definici¢n de instrumento,se puede encontrar en el offset 24h de
        cualquier fichero SBI, o bien en la definici¢n de instrumentos de
        un fichero CMF *)


CONST SONIDO_DEFECTO:InstType=(32,17,144,0,245,244,158,91,0,0,12,0,0,0,0,0);
      (* Instrumento por defecto : bajo el‚ctrico (m s o menos) *)

VAR AdlibPresent:Boolean; (* Se pone a TRUE si hay una Adlib en el sistema *)
                          (* (o compatible, Sound Blaster por ejemplo).    *)

PROCEDURE NoteOn(Canal:Byte;Escala,Nota:Byte);
(* Toca nota en canal, escala y nota especificados *)

PROCEDURE NoteOff(Canal:Byte);
(* Para nota en canal: escala y nota especificados no hacen nada*)

PROCEDURE LoadInstrument(Canal:byte;I:InstType);
(* carga instrumento SBI *)

PROCEDURE Silence;
(* Silencio en todos los canales, detiene sonido *)

PROCEDURE DiskInstrument(Driver:String;Order:Word;VAR T:InstType);
(* carga un instrumento del driver especificado en instrumento T          *)
(* Un driver de instrumentos ha de ser un fichero cuyos primeros 1024     *)
(* bytes son indiferentes, y en el offset 24 comienzan las definiciones   *)
(* de instrumentos (InstType, 16 bytes cada una). El primer instrumento   *)
(* es el 1.                                                               *)

PROCEDURE WriteAdlib(Reg:Byte;Value:Byte);
(* Procedimiento de bajo nivel, escribe valor a puerto de la Adlib *)

PROCEDURE GetVolume(Canal:Byte;VAR Volumen:Byte);
(* Obtiene el volumen de un cierto canal: 63 es el m¡nimo y 0 el m ximo *)

PROCEDURE SetVolume(Canal:Byte;Volumen:Byte);
(* Indica el volumen de un cierto canal: 63 es el m¡nimo y 0 el m ximo *)


IMPLEMENTATION

CONST OFFSETS:ARRAY[1..9] OF Byte=(0,1,2,8,9,$A,$10,$11,$12);

CONST FNUMBER:ARRAY[0..12] OF Word=
(0,$16B,$181,$198,$1B0,$1Ca,$1e5,$202,$220,$241,$263,$287,$2AE);

VAR I:Byte;
    OldExit:Pointer;
    VOLUME:ARRAY[1..9] OF Byte;

PROCEDURE WriteAdlib(Reg:Byte;Value:Byte); Assembler;
ASM
 MOV DX,0388h
 MOV AL,Reg
 OUT DX,AL
 IN AL,DX
 IN AL,DX
 IN AL,DX
 IN AL,DX
 IN AL,DX
 IN AL,DX
 MOV AL,Value
 INC DX
 OUT DX,AL
 DEC DX
 MOV CX,35
@Loop:
 IN AL,DX
 DEC CX
 JNZ @Loop
END;

PROCEDURE DiskInstrument(Driver:String;Order:Word;VAR T:InstType);
VAR F:FILE;
BEGIN
 Assign(F,Driver);
 Reset(F,1);
 Seek(F,1024+(Order-1)*16);
 BlockRead(F,T,16);
 Close(F);
END;

PROCEDURE Silence;
VAR A:Byte;
BEGIN
 FOR I:=1 TO 9 DO
    BEGIN
     A:=Volume[I];
     A:=A OR $3F;
     WriteAdlib($43+OFFSETS[i]+3,A);
     Noteoff(I);
    END;
END;

PROCEDURE InitCard;
BEGIN
 WriteAdlib($1,0);
 WriteAdlib($BD,$C0);
END;


FUNCTION IsAdlib:Boolean;
VAR A,B:Byte;
BEGIN
 WriteAdlib(4,$60);
 WriteAdlib(4,$80);
 A:=Port[$388];
 WriteAdlib(2,$FF);
 WriteAdlib(4,$21);
 Delay(1);
 B:=Port[$388];
 WriteAdlib(4,$60);
 WriteAdlib(4,$80);
 A:=A AND $E0;
 B:=B AND $E0;
 ISAdlib:=(A=0) AND (b=$c0);
end;



PROCEDURE NOTEON(Canal:Byte;Escala,Nota:Byte);
BEGIN
 If (Escala>7) OR (Nota>12) THEN Exit;
 WriteAdlib($AF+Canal,0); (* paro nota por si acaso *)
 WriteAdlib($9F+Canal,LO(FNUMBER[Nota]));
 WriteAdlib($AF+Canal,$20 + (Escala shl 2) + Hi(FNUMBER[Nota]));
END;

PROCEDURE NOTEOFF(Canal:Byte);
BEGIN
 WriteAdlib($AF+Canal,0);
END;

PROCEDURE LoadInstrument(Canal:byte;I:Insttype);
VAR Ofs:Word;
BEGIN
 Ofs:=Offsets[Canal];

 WriteAdlib($AF+canal,0); (* Paro nota en canal por si acaso *)

 WriteAdlib($20+ofs,I[$24]); (* Ampl-vibr-eg-ksr-mfm *)
 WriteAdlib($40+ofs,I[$26]); (* LKS-Total Level *)
 WriteAdlib($60+ofs,I[$28]); (* Attack - Decay *)
 WriteAdlib($80+ofs,I[$2A]); (* Sustain - release *)
 WriteAdlib($E0+ofs,I[$2C]); (* WaveSelect *)

 WriteAdlib($23+ofs,I[$25]); (* Ampl-vibr-eg-ksr-mfm *)
 WriteAdlib($43+ofs,I[$27]); (* LKS-Total Level *)
 WriteAdlib($63+ofs,I[$29]); (* Attack - Decay *)
 WriteAdlib($83+ofs,I[$2B]); (* Sustain - release *)
 WriteAdlib($E3+ofs,I[$2D]); (* WaveSelect *)

 WriteAdlib($BF+Canal,I[$2E]);
 Volume[Canal]:=I[$27];
END;


PROCEDURE GetVolume(Canal:Byte;VAR Volumen:Byte);
BEGIN
 Volumen:=VOLUME[Canal] AND $3F;
END;

PROCEDURE SetVolume(Canal:Byte;Volumen:Byte);
VAR Aux:Byte;
BEGIN
 Aux:=(VOLUME[CANAL] AND $C0) OR (Volumen AND $3F);
 WriteAdlib($43+Offsets[Canal],Aux);
 Volume[Canal]:=Aux;
END;

PROCEDURE ExitProcedure; far;
BEGIN
 Silence;
 ExitProc:=OldExit;
END;


BEGIN
 AdlibPresent:=IsAdlib;
 IF AdlibPresent THEN BEGIN
                       InitCard;
                       FOR I:=1 TO 9 DO LoadInstrument(I,SONIDO_DEFECTO);
                      END;
 OldExit:=ExitProc;
 Exitproc:=@ExitProcedure;
END.
