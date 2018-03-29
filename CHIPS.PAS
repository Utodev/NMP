UNIT CHIPS;

{$r-,s-,i-,O+,g+}


INTERFACE


 FUNCTION AMDCPUID:String;

 FUNCTION QUECHIP:String;
 (* Devuelve cadena con el nombre de la CPU : 8086, 286, 386, 486, Pentium,
    si detecta una CPU superior a Pentium devolver  la cadena "Procesador"
    superior a Pentium" *)

 FUNCTION CHIPTYPE:INTEGER;
 (* devuelve:
    >580 ES UN Pentium o m s
    >480 SI ES UN 486
    >=380 SI ES UN 386
    >=280 SI ES UN 286
    <280 SI ES 8086/8088
   *)



IMPLEMENTATION

 FUNCTION getCPU:Byte; (* Funcion interna *)
{
   0 = 8086
   1 = 80186/80286
   2 = 80386
   3 = 80386
   4 = 80486
   5 = Pentium
   6 = ??

}
 begin
  if (Test8086 = 2) then
  asm
             inc    Test8086
             mov    bx, sp
             and    sp, not 3
    db $66;  pushf
    db $66;  pop    ax
    db $66;  mov    cx, ax
    db $66, $35; dd $40000
    db $66;  push   ax
    db $66;  popf
    db $66;  pushf
    db $66;  pop    ax
    db $66;  xor    ax, cx
             je @@1
             and    sp, not 3
    db $66;  push   cx
    db $66;  popf
             mov    sp, bx
             mov  Test8086, 4

    db $66;  mov    ax, cx
    db $66, $35; dd $200000
    db $66;  push   ax
    db $66;  popf
    db $66;  pushf
    db $66;  pop    ax
    db $66;  xor    ax, cx
             je @@1
    db $66;  xor    ax, ax
    db $f,$a2
    db $66;  cmp    ax, 1
             jl @@1
    db $66;  xor    ax, ax
    db $66;  inc    ax
    db $f,$a2
             and    ax, $f00
             shr    ax, 8
             mov    Test8086, al
   @@1:
  end;
  GetCPU:=Test8086;
 end;




 FUNCTION CHIPTYPE:INTEGER;
 BEGIN
  CASE GetCPU OF
   0..1:ChipTYpe:=100;
   2:ChipType:=300;
   3:ChipType:=400;
   4:ChipType:=500;
   5:ChipType:=600;
   6:ChipType:=700;
  END;
 END;

 FUNCTION QUECHIP:String;
 BEGIN
  CASE CHIPTYPE OF
   681..32767:QueCHIP:='Pentium II';
   581..680:QUECHIP:='Pentium';
   481..580:QUECHIP:='486';
   380..480:QUECHIP:='386';
   280..379:QUECHIP:='286';
   0..279:QUECHIP:='8086'
  END
 END;

 FUNCTION AMDCPUID:String;
 var signature:word;
 BEGIN
  asm
   {mov eax,1}              db 66h;mov ax,1
   {cpuid}                  db 0fh, 0a2h
   and ax,0FF0h
   mov signature, ax
  end;
  case signature of
   $0500, $0510, $0520, $0530: AMDCPUID := 'AMD K5';
   $0560 : AMDCPUID := 'AMD K6'
   else AMDCPUID := '';
  end;
 END;

END.
