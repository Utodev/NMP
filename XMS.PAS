(* UNIDAD: XMS, para la gesti¢n de memoria extendida para Turbo Pascal 6.0+

  Fecha: Mayo-1994

  Garant¡a: No hay ninguna garant¡a impl¡cita ni expl¡cita, si usa estas
            rutinas ser  a su propio riesgo. No nos hacemos responsables
            de da¤os o perdidas de datos que pudiera sufrir por el uso de
            estas rutinas. En si mismo no nos hacemos responsables de nada.
*)

UNIT XMS;

{$I-,S-R-,X+}

INTERFACE

TYPE XMSHandle=Word;

VAR ExistXMS:Boolean;
(* Actualizada en inicializaci¢n de unidad. Es TRUE si hay XMS,
   aunque no haya nada libre *)

PROCEDURE GetXMSVersionNumber(VAR version,internal:Word;VAR HMAexist:Boolean);
(* Devuelve valores BCD del n§ de versi¢n, revisi¢n interna, y si existe el HMA *)

FUNCTION MemXMSAvail:Word;
(* Devuelve el n§ de K de memoria extendida libres *)

FUNCTION MaxXMSAvail:Word;
(* Devuelve el  tama¤o en Ks del mayor bloque de memoria extendida libre *)

FUNCTION GetXMSMem(VAR Handle:XMShandle;Size:Word):Byte;
(* Intenta reservar una zona de XMS del tama¤o indicado en Ks *)
(* Si tiene exito devuelve el handle y la funci¢n devuelve 1  *)
(* en caso contrario el handle es puesto a 0 y la funci¢n     *)
(* devuelve :                                                 *)
(* $80 si la funci¢n no est  implementada                     *)
(* $81 si se detect¢ un dispositivo VDISK                     *)
(* $A0 si no queda XMS libre                                  *)
(* $A1 si no quedan handles libres de XMS                     *)

FUNCTION FreeXMSMem(VAR Handle:XMShandle):Byte;
(* Intenta liberar la zona de XMS indicada por el handle      *)
(* Si tiene exito devuelve 1 , en caso contrario el handle es *)
(* puesto a 0 y la funci¢n devuelve :                         *)
(* $80 si la funci¢n no est  implementada                     *)
(* $81 si se detect¢ un dispositivo VDISK                     *)
(* $A2 si el handle no es valido                              *)
(* $AB si el handle est  bloqueado                            *)
(*                                                            *)
(* Usted *debe* liberar todos los bloques de memoria antes de *)
(* salir, pues estos no son liberados autom ticamente como en *)
(* los de memoria convencional.                               *)

FUNCTION XMSMove( SRCHandle:Word;SRCOffset:LongInt;
                  DSTHandle:Word;DSTOffset:Longint;length:Longint):Byte;
(* Mueve un bloque de memoria de XMS a XMS, o de XMS a Memoria Base           *)
(* Si se indica handle 0 el offset correspondiente es interpretado como un    *)
(* puntero en memoria base. La longitud es altamente recomendable que sea par.*)
(* Si la funci¢n devuelve 1 no hubo error, si no los errores posibles son:    *)
(*  $80 si la funci¢n no est  implementada                                    *)
(*  $81 si se encontr¢ un dispositivo VDISK                                   *)
(*  $82 si ocurri¢ un error de linea A20                                      *)
(*  $A3 si el handle fuente es invalido                                       *)
(*  $A4 si el offset de fuente es invalido                                    *)
(*  $A5 si el handle destino es inv lido                                      *)
(*  $A6 si el offset de destino es invalido                                   *)
(*  $A7 si la longitud es invalida                                            *)
(*  $A8 si el movimiento tiene un solapamiento inv lido                       *)
(*  $A9 error de paridad                                                      *)
(*                                                                            *)
(*  Si el MOVE se solapa s¢lo funcionar  bien si es hacia delante             *)
(*  SCRxxx son el handle y offset del bloque fuente (source)                  *)
(*  DSTxxx son el handle y offset del bloque destino                          *)
(*  L¢gicamente si ambos handles son especificados 0 se mueve de memoria base *)
(*  a memoria base, pero desde luego no se recomienda.                        *)


(* Nota importante:  Es altamente recomendable que el tama¤o de los XMSMove
                     sea m£ltiplo de 4 *)

{ Ejemplo XMSMOVE:

   VAR XMS1,XMS2:XMSHandle;
       P:Pointer;
       A:ARRAY[0..7] OF Byte;

   BEGIN
    GetXMSMem(XMS1,8); (* Cojo 8K de memoria XMS *)
    GetXMSMem(XMS2,16); (* 16K en XMS2 *)
    getMem(P,8192);  (* 8K de memoria del Heap *)


    (* Copiar de XMS a XMS *)
    XMSMove(XMS1,0,XMS2,0,8192); (* Copia 8Ks de XMS1 en primeros 8Ks de XMS2 *)
    XMSMove(XMS2,8192,XMS1,0,8192); (* Copia segundos 8Ks de XMS2 en XMS1 *)
    XMSMove(XMS2,527,XMS1,1890,500); (* Copia 500 bytes desde el n§ 527 de
                                        XMS2 en la posici¢n 1890 del bloque
                                        indicado por XMS1 *)

    (* Copiar de XMS a memoria principal *)

    XMSMove(XMS1,0,0,longint(p),8192); (* Copio bloque de 8K de XMS1 en
                                          direcci¢n apuntada por el puntero
                                          P *)
    XMSMove(XMS2,500,0,longint(@A),8); (* Copio 8 bytes de la posici¢n 500
                                          del bloque XMS2 en array A *)
    XMSMove(XMS1,0,0,longint(@a)+4,4); (* Copio 4 bytes desde bloque XMS1 en
                                          A[4] *)


    (* Para copiar de memoria principal a XMS basta con intercambiar fuente
       y destino *)

    FreeXMS(XMS1);
    FreeXMS(XMS2);
    FreeMem(P,8192);



    }



FUNCTION GetNumhandles(Q:XMSHandle):Byte;
(* Devuelve el n§ de handles libres en el sistema *)



IMPLEMENTATION

VAR XMSProc:procedure;
    MemMove:RECORD
             Length:Longint;
             SourceHandle:Word;
             SourceOffset:LongInt;
             DestHandle:Word;
             DestOffset:LongInt
            END;

PROCEDURE XMSError(N:Byte);
BEGIN
 CASE N OF
  1:WriteLn('Error en petici¢n de memoria : No hay suficiente XMS libre.');
 END;
 Halt(N)
END;

FUNCTION GetNumhandles(Q:XMSHandle):Byte; Assembler;
ASM
 MOV AH,0Eh
 MOV DX,Q
 CALL DWORD PTR XMSproc
 XOR AH,AH
 MOV AL,BL
END;

FUNCTION MemXMSAvail:Word; Assembler;
ASM
 MOV AH,8
 CALL DWORD PTR XMSProc
 MOV AX,DX
END;

FUNCTION MaxXMSAvail:Word; Assembler;
ASM
 MOV AH,8
 CALL DWORD PTR XMSProc
END;



PROCEDURE GetXMSVersionNumber(VAR version,internal:Word;VAR HMAexist:Boolean);
BEGIN
 ASM
  XOR Ah,AH
  call dword ptr XMSProc
  LES DI,[version]
  STOSW
  LES DI,[internal]
  MOV AX,BX
  STOSW
  MOV AX,DX
  LES DI,[HMAExist]
  STOSB
 END;
END;

FUNCTION GetXMSMem(VAR Handle:XMShandle;Size:Word):Byte; Assembler;
ASM
 MOV AH,09h
 MOV DX,Size
 CALL DWORD PTR XMSProc
 LES DI,[Handle]
 MOV ES:[DI],DX
 CMP AX,1
 JZ @FIN
 XOR BH,BH
 MOV AX,BX
 @FIN:
END;

FUNCTION FreeXMSMem(VAR Handle:XMShandle):Byte; Assembler;
ASM
 MOV AH,0Ah
 LES SI,[handle]
 MOV DX,ES:[SI]
 CALL DWORD PTR XMSProc
 CMP AX,1
 JZ @FIN
 XOR BH,BH
 MOV AX,BX
 @FIN:
END;

FUNCTION XMSMove(SRCHandle:Word;SRCOffset:LongInt;DSTHandle:Word;DSTOffset:Longint;length:Longint):Byte;
VAR Aux:Byte;
BEGIN
 MemMove.SourceHandle:=SRCHandle;
 MemMove.SourceOffset:=SRCOffset;
 MemMove.length:=length;
 MemMove.DestHandle:=DSTHandle;
 MemMove.DestOffset:=DSTOffset;
 ASM
  PUSH DS
  MOV SI,Offset MemMove
  MOV AX,SEG MemMove
  MOV DS,AX
  MOV AH,0Bh
  CALL DWORD PTR XMSProc
  CMP AX,1
  JZ @FIN
  XOR BH,BH
  MOV AX,BX
  @FIN:
  MOV Aux,AL
  POP DS
 END;
 XMSMove:=Aux;
END;

BEGIN
 ExistXMS:=False;
 ASM
  mov     ax,4300h
  int     2Fh
  cmp     al,80h
  jne     @NoXMSDriver
  mov     ExistXMS,1
  @NoXMSDriver:
 END;
 IF ExistXMS THEN
  ASM
   mov     ax,4310h
   int     2Fh
   mov     word ptr [XMSProc],bx
   mov     word ptr [XMSProc+2],es
  END;

{ WriteLn('XMS Runtime CopyRight NM Software 1994');}
END.

