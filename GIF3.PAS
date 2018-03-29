Ä [EdiNet] Aventuras (93:341/736.39) ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ EDISON.AVENTURA Ä
 Msj  : 175 de 186 -151 +181 185            Rcv                                 
 De   : David Moreno                        93:341/736      Jue 12 Mar 98 18:07 
 Para : Carlos Sanchez Garcia                               Vie 13 Mar 98 19:10 
 Tema : Cargador de GIF                                                         
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Holaps

 Pues aqui te mando la versi¢n casi-definitiva del cargador de .GIF, porque
£ltimamente ando un poco vago y no se si la optimizar‚ en tama¤o O:). Debe
de ir a la misma velocidad que antes, no colgarse y funcionar bien con
cualquier tama¤o de marco y pantalla :). ¨ Te pasar s por la quedada :-?,
por vernos todos :))

----------------------------------------------------------------------------
{$X+,I-}
USES Crt,Dos,VESA;
VAR
  buffer1:^byte;
  ytop,yabs,xlenp,xconta,xlenx,yconta,ylenx,x0x,y0x,ymax,pixel:word;
  bucle,desp,contador,bbajo,bmedio,balto,codelen:byte;
  ficherox:file;
  PALL0:array [0..767] of byte;
  tabla: array [0..4096,0..1] of word;
  asfast:array [0..256] of byte;
  cuentalo:byte;
  errorcode:byte;

procedure Lee_Paleta (inicio,final:byte);
VAR
  a:byte;
  PALETILLA:array [0..767] of byte;
begin
Seek (ficherox,13);
Blockread (ficherox,PALETILLA,768);
for a:=inicio to final do   { colocamos la PALETA }
 begin
 PALL0 [a*3] := PALETILLA [a*3] shr 2;
 PALL0 [(a*3)+1] := PALETILLA [(a*3)+1] shr 2;
 PALL0 [(a*3)+2] := PALETILLA [(a*3)+2] shr 2;

 Port[$3c8]:= a;
 Port[$3c9]:= PALL0 [a*3];
 Port[$3c9]:= PALL0 [(a*3)+1];
 Port[$3c9]:= PALL0 [(a*3)+2];
 end;
end;
function damedato:word;
VAR
 dato,dato2:word;
 index:byte;
CONST
 maskara : array [0..3] of word = ($01FF, $03FF,$07FF,$0FFF);
begin
index:=codelen - 9;
bbajo:=bmedio;
bmedio:=balto;
{blockread (ficherox,balto,1);
dec (contador);}

balto := asfast [cuentalo];
inc (cuentalo);
{if contador=0 then blockread (ficherox,contador,1);}
if cuentalo = contador then    { si ya hemos leido el buffer }
    begin
     blockread (ficherox,contador,1); { Leemos el nuevo contador }
     blockread (ficherox,asfast,contador); { Llenamos el b£ffer}
     cuentalo:=0;
    end;

dato := (bmedio shl 8) + bbajo;
dato := dato shr desp;

dato2 := balto shl 8;
dato2 := dato2 shr desp;
dato2 := dato2 shl 8;
damedato := (dato OR dato2) AND maskara[index];

desp:= desp + (index+1);
if desp>7 then { el bbajo no nos sirve para nada }
        begin
        bmedio:=balto;
        {blockread (ficherox,balto,1);}
        balto := asfast [cuentalo];
  desp:=desp-8;
        {dec (contador);}
        inc (cuentalo);
        if cuentalo = contador then    { si ya hemos leido el buffer }
       begin
          blockread (ficherox,contador,1); { Leemos el nuevo contador }
          blockread (ficherox,asfast,contador); { Llenamos el b£ffer}
                cuentalo:=0;
       end;
        end;
end;

procedure pinta (valor:word);
VAR
   indi:word;
begin

indi:=pixel;
if valor<256 then
   begin
    { mem[$A000:pixel]:=valor; }
    if xconta < xlenx then
    begin
     asm
       push   ds
        push  si
        lds   si,buffer1
        mov   ax,[indi]
        add   si,ax
        mov   ax,[valor]
        mov   ds:[si],al
        pop   si
        pop   ds
     end;
     inc (pixel);
    end;
     inc (xconta);
     if xconta = xlenp then
        begin
         xconta:=0;
         inc (yconta);
         inc (yabs);
         if yconta = ymax then
          begin
            PutImage (x0x,y0x,xlenx,ymax,buffer1^,0);
            y0x:= y0x + yconta;

            if y0x = ytop then exit; { alcanzamos el borde }

            pixel:=0;
            yconta:=0;
          end;
         end;
     end
   else
    begin
     pinta (tabla[valor][0]);
     pinta (tabla[valor][1]);
    end;
end;
function Carga_gif
(nombre:string;X0,Y0,XF,YF:word;palx:Boolean;inicio,final:byte):byte;
VAR
        memoria:longint;
        index,b,a,xlen,ylen:integer;
  pause,dato:byte;
        c,dato2,dato1,codigo:word;
begin
pause:=0;
Assign (ficherox,nombre);
Reset (ficherox,1);
if ioresult<>0 then
 begin
  Carga_gif:=2; { Fichero no se encuentra }
  exit;
 end;
Seek (ficherox,6);
Blockread (ficherox,xlen,2); { ancho }
Blockread (ficherox,ylen,2); { alto  }
if palx = True then Lee_Paleta (inicio,final);

{ comprobaci¢n de m rgenes y ajuste de memoria }
yabs:=0;
xlenp:=xlen;
if xf-x0 < xlen then xlen:=xf - x0;
if yf-y0 < ylen then ylen:=yf - y0;

if (MaxAvail < xlen*2) then
 begin
 Carga_gif := 1; { No hay bastante memoria ... }
 exit;
 end;
if MaxAvail>65528 then ymax:=65528 div xlen
      else ymax:= MaxAvail div xlen;
if ymax > ylen then ymax:=ylen;
getmem (pointer(buffer1),(xlen*ymax));
{ Inicio de las variables }
ytop:=y0 + ylen; { Tope de Y }
x0x := x0;
y0x := y0;
ylenx:=ylen;
yconta:=0;
xlenx:=xlen;
xconta:=0;
Seek (ficherox,792);
Blockread (ficherox,contador,1);  { Contador de bytes }
{Blockread (ficherox,bmedio,1);}
{Blockread (ficherox,balto,1);}
Blockread (ficherox,asfast,contador); { Llenamos el b£ffer }
cuentalo:=0;
bmedio:=asfast [cuentalo];
inc (cuentalo);
balto :=asfast [cuentalo];
inc (cuentalo);
{contador:=contador - 2;}
codelen:= 9;
desp:=0;
index:=258;
for a:= 0 to 255 do tabla[a][0]:=a;
dato2:= damedato; { CLEAR CODE }
dato2:= damedato; { La chicha }
pixel:=0;
while dato2 <> 257 do

begin

  dato1:=dato2;
  dato2:=damedato;

  if dato2=256 then {CLEAR CODE}
   begin
    codelen:=9;
    index:=258;
    pinta (dato1);
    dato1:=damedato;
    dato2:=damedato;
  end;

  if dato1<>257 then
  begin
  tabla[index][0]:=dato1;

  {tabla[index][1]:=buscadena (tabla[dato2][0]);}

  c:=dato2;
  while tabla[c][0] > 255 do c:=tabla[c][0];
  tabla[index][1]:=tabla[c][0];

  { Aqui es donde se pinta :-) }
  pinta (dato1);
  inc(index);
  if (index=512) OR (index=1024) OR (index=2048) then inc(codelen);
  end;
if yabs = ylen then dato2:=257;
end;
if (y0x < yf) AND (y0x <> ytop) then PutImage (x0,y0x,xlen,yconta,buffer1^,0);
freemem (pointer(buffer1),xlen*ymax);
Close (ficherox)
end;

begin
setVESAmode ($101,640);
errorcode := Carga_gif ('marcox.gif',0,0,640,240,True,0,255);
Readkey;
{modo_texto;}
asm
  mov  ax,3
        int   $10
end;
if errorcode = 2 then WriteLn ('Fichero no se encuentra');
if errorcode = 1 then WriteLn ('No hay bastante memoria');
end.
--------------------------------------------------------------------------

Un saludo
þ S a i m a z o o m þ ALIEN soft (KNO & KMBR) MALTA:48% saimazoom@hotmail.com

... Erase un humano a un desastre pegado.
---
 * Origin: * EDiSoN's TeMPLe * +341 40-60-372 * 24H * 33k6 V34+ * (93:341/736)

