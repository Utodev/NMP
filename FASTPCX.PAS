

UNIT FASTPCX;

{$G+} (* Requires 286+! *)

INTERFACE

PROCEDURE UNPACKPCX(SetPalette:Boolean;VAR SRC,DST;VAR Palette);

IMPLEMENTATION

PROCEDURE UNPACKPCX(SetPalette:Boolean;VAR SRC,DST;VAR Palette);  (*Debe ser un 320x200x256*) assembler;
ASM
 PUSH DS
 CLD
 XOR CH,CH      (* Important, we need CH to be zero all the time *)
 LDS SI,[SRC]
 LES DI,[DST]
 MOV DX,64000   (* My counter, as I don't use loop but DEC DX, JNZ, faster*)
 ADD SI,128
@LOOP:
 LODSB
 MOV BL,AL     (* Preserve value *)
 AND AL,0C0h
 CMP AL,0C0h
 MOV AL,BL     (*Restore value *)
 JZ @COMPRESSED (* If >=192 it is compressed *)
 STOSB
 DEC DX
 JNZ @LOOP
 JMP @PALET   (* Finished *)
@COMPRESSED:
 MOV CL,AL    (* That's why we need CH to be 0, this way CX=CL *)
 AND CL,03Fh  (* CL minus 192 *)
 SUB DX,CX
 LODSB
 REP STOSB    (* This may be optimzed for 286 or even 386, but I think
                 it's fast enough and it's not needed. If you want, do
                 it yourself *)

 OR DX,DX
 JNZ @LOOP

@PALET:
 INC SI         (* Ignore value 12 before the palette *)


 MOV CX,384        (* 768= 256*3, half is 384 *)
 LES DI,[Palette]  (* ES:DI --> Palettte *)
 REP MOVSW         (* copy palette, 384 words = 768 bytes *)

 MOV CX,384
 LDS SI,[Palette]
 MOV DI,SI
@PAL_LOOP:
 LODSW
 SHR AL,2
 SHR AH,2
 STOSW
 DEC CX
 JNZ @PAL_LOOP;          (* Put bits in its place, divide the palette by 4 *)


 MOV AL,SetPalette   (* Do I want to restore the palette? *)
 OR AL,AL            (* 0=FALSE, other =TRUE    *)
 JZ @Finish

 MOV   DX,3dah       (* wait for retrace *)
@wait1:
 IN    AL,DX
 AND   AL,08h
 JNZ   @wait1
@wait2:
 IN    AL,DX
 AND   AL,08h
 JZ    @wait2

 MOV DX,3C8h    (* Restore palette *)
 XOR AL,AL
 OUT DX,AL
 INC DX
 MOV CX,768
 SUB SI,CX
 REP OUTSB

@Finish:
 POP DS
END;

END.