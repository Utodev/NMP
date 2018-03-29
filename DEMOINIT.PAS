UNIT DEMOINIT;
{
  DEMOINIT
  - unit programmed by Bjarke Viksoe

  Started at: mar 1994
  Last revised: 28. nov 1994
}

INTERFACE

{$S-,F-,B-}

uses
	CRT,DOS;

const
	{screen constants}
	WIDTH = 80;
	HEIGHT = 200;
	SCRSIZE = 65528;
	{assmebler '386 opcodes/prefixes}
	FS = $64;
	GS = $65;
	LONG = $66;
	PUSHA = $60;
	POPA = $61;
	{screen modes}
	MODE320x200x256 = $13;
	MODE320x200x16 = $D;
	TEXTMODE = $3;

type
	pScreen = ^ScreenType;
	ScreenType = array[0..SCRSIZE] of byte;


function IsVGA : boolean;
procedure SetScreenMode(x : word);
procedure OpenScreen;
procedure Get400Lines;
procedure InModeX;
procedure CloseScreen;
procedure ClearWholeScreen;
procedure VBLANK;
procedure VBLANK_QUICK;
procedure Screen_On;
procedure Screen_Off;
procedure SetAddress(a : pointer);
procedure SetRGB(colour : integer; r,g,b : byte);

procedure SetDisplayWidth(count : byte);
procedure SetPelPan(count : byte);
procedure SetReadMap(value : byte);
procedure SetBitplanes(planes : byte);
inline(
	$BA/$C4/$03/	{mov	dx,$3C4}
	$58/				{pop	ax}
	$88/$C4/			{mov	ah,al}
	$B0/$02/			{mov	al,$02}
	$EF);				{out	dx,ax}
procedure SetWriteMode(m : byte);
procedure SetDataRotateRegister(f,r : byte);
procedure SetLineRepeat(nr : Byte);
procedure SetSetReset(x : byte);
inline(
	$BA/$CE/$03/	{mov	dx,$3CE}
	$58/				{pop	ax}
	$88/$C4/			{mov	ah,al}
	$B0/$00/			{mov	al,$00}
	$EF);				{out	dx,ax}
procedure SetESetReset(x : byte);
inline(
	$BA/$CE/$03/	{mov	dx,$3CE}
	$58/				{pop	ax}
	$88/$C4/			{mov	ah,al}
	$B0/$01/			{mov	al,$01}
	$EF);				{out	dx,ax}
procedure SetBitMaskRegister(x : byte);
inline(
	$BA/$CE/$03/	{mov	dx,$3CE}
	$58/				{pop	ax}
	$88/$C4/			{mov	ah,al}
	$B0/$08/			{mov	al,$08}
	$EF);				{out	dx,ax}

procedure CLI; inline($FA);
procedure STI; inline($FB);

procedure SetPixel(pageoffset : word; x,y : integer; colour : byte);

procedure SetAllInterrupts;
procedure RestoreAllInterrupts;
procedure SetKbdInterrupt;
procedure RestoreKbdInterrupt;
procedure SetTimerInterrupt;
procedure RestoreTimerInterrupt;

function  KeyPressed : boolean;
function ReadTimer : integer;

function LongDiv(x : longint; y : integer) : integer;
inline($59/$58/$5A/$F7/$F9);
function LongMul(x, y : integer) : longint;
inline($5A/$58/$F7/$EA);


const
	{Vertival Retrace Timer setup...
	 Set timeout to 0 to auto-sync to vblank
	 Another value will make n interrupts per frame. Use TIMESLACK to
	 give interrupt some time to process. Eg. TIMEOUT=1, TIMESLACE=-300}
	TIMEOUT : word = 0;			 {number of interrupts pr frame}
	TIMESLACK : integer = -300; {interrupt timer slack}
	EXECBIOSTIMER : boolean = TRUE; {still execute bios timer interrupt?}
	{$IFNDEF VER70}
		SEGA000 : word = $A000; {emulate BP7.0 SEGA000 variabel for real-mode}
	{$ENDIF}

var
	Key : char;
	ytabel : array[0..240] of word; {ytabel with mul #80}
	KeyHit : array[0..127] of boolean; {array of hit keys}
	{vertical retrace counter}
	retraces : word;
	total_retraces : word;
	{pointer to user-interrupt hook}
	timerproc : procedure;
	{store old interrupt-pointers}
	Int08Save : procedure;
	Int09Save : procedure;


(*-----------------------------------------*)

IMPLEMENTATION

const
	keymap : string = ' e1234567890-=  QWERTYUIOP[]  ASDFGHJKL;`\  ZXCVBNM,./                                                   ';

var
	OldScreenMode : byte;
	OldExitProc : pointer;

	SpecialKeys : byte;
	TimeSet : word;
	timercount : integer;
	bioscount : word;

	KeyInstalled : boolean;
	TimerInstalled : boolean;


(*-----------------------------------------*)

{$F+}
procedure ScreenExitProc;
{$F-}
begin
	ExitProc:=OldExitProc;
	if (ExitCode<>0) then CloseScreen; {if runtime error, restore screen}
end;

function IsVGA : boolean; assembler;
asm
	mov	ax,$1A00
	int	$10
	cmp	al,$1A
	je		@ok
	mov	ax,FALSE
	jmp	@done
@ok:
	mov	ax,TRUE
@done:
end;

procedure SetScreenMode(x : word); assembler;
asm
	mov	ax,x
	xor	ah,ah
	int	$10
end;

procedure OpenScreen;
{Setup Tweak-VGA screen}
var
	i : integer;
begin
	for i:=0 to 240 do ytabel[i]:=i*WIDTH;

	asm
		mov	ah,$0F					{ Fetch the current videomode }
		int	$10						{ and save it }
		mov	[OldScreenMode],al
	end;

	SetScreenMode($13);

	{Setup tweaked vga mode - or unchained mode 320x200x256}
	CLI;
	PortW[$3C4]:=$0604; {turn off chain-4}
	ClearWholeScreen;
	PortW[$3D4]:=$0014; {turn off doubleword mode}
	PortW[$3D4]:=$E317; {turn off word-mode}
	STI;

	OldExitProc:=ExitProc;
	ExitProc:=@ScreenExitProc;
end;

procedure Get400Lines;
{After calling OpenScreen, you can call this to get 320x400x256}
begin
	PortW[$3D4]:=$4009;
end;

procedure InModeX;
{Put screen in tweaked 320x240x256, also called ModeX.
 OpenScreen must be called previously}
begin
	CLI;
	Port[$3C2]:=$E3;
	PortW[$3D4]:=$2C11;
	PortW[$3D4]:=$0D06;
	PortW[$3D4]:=$3E07;
	PortW[$3D4]:=$EA10;
	PortW[$3D4]:=$AC11;
	PortW[$3D4]:=$DF12;
	PortW[$3D4]:=$E715;
	PortW[$3D4]:=$0616;
	STI;
end;


procedure CloseScreen;
begin
{	SetScreenMode(OldScreenMode);}
	SetScreenMode(TEXTMODE);
	Writeln;
	Writeln('A small piece of code by Bjarke Viksíe...');
end;


(*-----------------------------------------*)

procedure VBLANK; assembler;
{Wait for the next vertical retrace}
asm
	cmp	[TimerInstalled],TRUE
	je		@timerinstalled
	mov	dx,$3DA
@wait1: {if we are in retrace, wait 'till we are not...}
	in		al,dx
	test	al,8
	jnz	@wait1
@wait2: {wait for a new retrace}
	in		al,dx
	test	al,8
	jz		@wait2
	jmp	NEAR PTR @done

@timerinstalled:
	mov	ax,[total_retraces]
@wait3:
	cmp	ax,[total_retraces]
	je		@wait3
@done:
end;

procedure VBLANK_QUICK; assembler;
{Wait 'till we are in a vertical retrace}
asm
	cmp	[TimerInstalled],TRUE
	je		@timerinstalled
	mov	dx,$3DA
@wait1: {wait for a new retrace}
	in		al,dx
	test	al,8
	jz		@wait1
	jmp	NEAR PTR @done

@timerinstalled:
	mov	ax,[total_retraces]
@wait2:
	cmp	ax,[total_retraces]
	je		@wait2
@done:
end;

procedure SCREEN_OFF; assembler;
{Turn screen off. Give maximum bandwith to CPU!}
asm
	cli
	mov	dx,$3C4
	mov	al,$01
	out	dx,al
	inc	dx
	in		al,dx
	or		al,$20
	out	dx,al
	sti
end;

procedure SCREEN_ON; assembler;
{Turn screen on again after a "SCREEN_OFF"}
asm
	cli
	mov	dx,$3C4
	mov	al,$01
	out	dx,al
	inc	dx
	in		al,dx
	and	al,NOT $20
	out	dx,al
	sti
end;

procedure SetAddress(a : pointer); assembler;
{Set the start offset for VGA display.
 Segment in "a" discarded. Only offset is used!}
asm
	mov	ax,WORD PTR [a]
	mov	dx,$3D4
	mov	bh,al
	mov	al,$C
	mov	bl,$D
	out	dx,ax
	mov	ax,bx
	out	dx,ax
end;

procedure SetPelPan(count : byte);
{Set pel panning register}
var
	i : byte;
begin
	i:=Port[$3DA]; {reset ATC addressing, dummy input}
	Port[$3C0]:=$33; {palette address source=1; index=$13}
	Port[$3C0]:=count;
end;

procedure SetDisplayWidth(count : byte);
{Set number of bytes pr. virtual display row}
begin
	Port[$3D4]:=$13;
	Port[$3D5]:=count;
end;

procedure SetReadMap(value : byte);
{Set the "read map selector" register}
begin
	Port[$3CE]:=$04;
	Port[$3CF]:=value;
end;

procedure SetRGB(colour : integer; r,g,b : byte); assembler;
{Set a colour's RGB values. Colour is [0..255], r,g and b is [0..63]!}
asm
	mov	dx,$3C8
	mov	ax,[colour]
	out	dx,al
	inc	dx
	mov	al,[r]
	out	dx,al
	mov	al,[g]
	out	dx,al
	mov	al,[b]
	out	dx,al
end;


procedure SetPixel(pageoffset : word; x,y : integer; colour : byte); assembler;
{Put a pixel on a tweaked screen}
asm
	mov	dx,$3C4
	mov	ax,$0102
	mov	cx,[x]
	mov	di,cx
	and	cl,3
	shl	ah,cl
	out	dx,ax

	mov	es,[SEGA000]
	mov	bx,[y]
	add	bx,bx
	mov	ax,[OFFSET ytabel+bx]
	add	ax,[pageoffset]
	shr	di,2
	add   di,ax
	mov	al,[colour]
	mov	[es:di],al
end;

procedure SetLineRepeat(nr:Byte);
{Set VGA scan-line repeat}
begin
	Port[$3D4]:=9;
	Port[$3D5]:=Port[$3D5] AND $F0+nr;
end;

procedure SetWriteMode(m : byte);
begin
	Port[$3CE]:=$05;
	Port[$3CF]:=(Port[$3CF] AND $FC) OR (m AND 3);
end;

procedure SetDataRotateRegister(f,r : byte);
{Set the Data Rotate Register}
begin
	Port[$3CE]:=$03;
	Port[$3CF]:=(f SHL 3) OR r;
end;


(*-----------------------------------------*)


procedure ClearWholeScreen; assembler;  { clear video memory }
asm
	mov	dx,$3C4
	mov	ax,$0F02
	out	dx,ax

	mov	es,[SEGA000]
	xor	di,di
	xor	ax,ax
	mov	cx,$10000/2
	cld
	rep stosw
end;

procedure SetTimer(x : word); assembler;
asm
	cli
	mov	al,$36
	out	$43,al
	jmp	@1
@1:mov	ax,[x]
	out	$40,al
	jmp	@2
@2:mov	al,ah
	out	$40,al
	jmp	@3
@3:sti
end;

function ReadTimer : integer; assembler;
asm
	cli
	xor	al,al
	out	$43,al
	in		al,$40
	mov	ah,al
	in		al,$40		{ read timer count - time between }
	xchg	al,ah       { two Vertical Retraces }
	neg	ax
	sti
end;


(*-----------------------------------------*)

{$F+}
procedure KbdHandler; interrupt; assembler;
{$F-}
asm
	in		al,$60
	mov	bl,al

	in		al,$61
	or		al,$80
	out	$61,al
	and	al,$7F
	out	$61,al

	cmp	bl,$E0
	jne	@notE0
	add	[SpecialKeys],1
	jmp   NEAR PTR @done
@notE0:
	cmp	bl,$E1
	jne	@notE1
	add	[SpecialKeys],2
	jmp	NEAR PTR @done
@notE1:
	cmp	[SpecialKeys],0
	jz		@nospeckey
	dec	[SpecialKeys]
	jmp	NEAR PTR @done
@nospeckey:

	mov	al,bl
	and	bx,$7F	{remove hitstatus bit and clear BH}
	inc	bx			{skip string-length byte}
	cmp	bl,110	{array is only about 110 chars long...}
	ja		@done
	and	al,al
	jns	@pressing
	mov	BYTE PTR [bx+OFFSET keyhit],FALSE
	mov	al,[bx+OFFSET keymap]
	mov	[Key],al
	jmp	NEAR PTR @done
@pressing:
	mov	BYTE PTR [bx+OFFSET keyhit],TRUE
@done:
	mov	al,$20
	out	$20,al
end;

{$F+,S-}
procedure TimerHandler; interrupt; assembler;
{$F-}
asm
	cli
	inc	[timercount]
	mov	ax,[TIMEOUT]
	cmp	[timercount],ax
	jb		@noretrace
	mov	[timercount],0

	{wait for a vertical retrace}
	mov	dx,$3DA
@vblank:
	in		al,dx
	test	al,8
	jz		@vblank

	{set timer again}
	mov	al,$36
	out	$43,al
	jmp	@1
@1:mov	ax,[TimeSet]
	out	$40,al
	jmp	@2
@2:mov	al,ah
	out	$40,al

	{increase timer counters}
	inc	[retraces]
	inc	[total_retraces]

	{should we call user-defined hook?}
	mov	ax,WORD PTR [TimerProc]
	or		ax,WORD PTR [TimerProc+2]
	jz		@nouserproc
	sti
	call	DWORD PTR [TimerProc]
	cli
@nouserproc:

	cmp	[execbiostimer],FALSE
	je		@nobiostimer
	mov	ax,[TimeSet]
	add	[bioscount],ax
	jno	@nobiostimer
	sti
	pushf
	call	DWORD PTR [Int08Save]
	jmp	NEAR PTR @xit
@nobiostimer:

@noretrace:
	mov	al,$20
	out	$20,al
	sti
@xit:
end;


function GetTime : word; assembler;
{Find time between two vertical retraces...}
asm
	mov	dx,$3DA   {wait for a vertical retrace to begin}
@wait1a:
	in		al,dx
	test	al,8
	jnz	@wait1a
@wait1b:
	in		al,dx
	test	al,8
	jz		@wait1b

	mov	al,$36
	out	$43,al
	xor	al,al		{ reset the timer }
	out	$40,al
	out	$40,al

	mov	dx,$3DA   {wait for a new vertical retrace to begin}
@wait2a:
	in		al,dx
	test	al,8
	jnz	@wait2a
@wait2b:
	in		al,dx
	test	al,8
	jz		@wait2b

	xor	al,al
	out	$43,al
	in		al,$40
	mov	ah,al
	in		al,$40		{ read timer count - time between }
	xchg	al,ah       { two Vertical Retraces }
	neg	ax
end;


function SyncTimerToVBLANK : word; assembler;
const
	FRAMEPERCENT = 975; {returned time will be 97.5% of measured value}
asm
@GetFrameTime:
	cli									{ Don't bother us while timing things }
	call	GetTime
	push	ax
	call	GetTime
	pop	dx
	sti
	sub	dx,ax
	cmp  	dx,5                    { If the difference between the two }
	jg		@GetFrameTime           { values read was >5, read again }
	cmp	dx,-5
	jl		@GetFrameTime

	mov	bx,FRAMEPERCENT
	mul	bx
	mov	bx,1000
	div	bx
	shr	ax,1
end;


procedure SetTimerInterrupt;
begin
	retraces:=0; total_retraces:=0; timercount:=0;
	TimeSet:=$FFFF;
	GetIntVec($08,@Int08Save);
	SetIntVec($08,addr(TimerHandler));
	if (TIMEOUT<>0) then TimeSet := ($1234DD DIV 70 DIV TIMEOUT)+TIMESLACK
	else TimeSet:=SyncTimerToVBLANK;
	SetTimer(TimeSet);
	TimerInstalled:=TRUE;
end;

procedure RestoreTimerInterrupt;
begin
	if NOT TimerInstalled then exit;
	SetIntVec($08,@Int08Save);
	SetTimer(0);
	TimerInstalled:=FALSE;
end;

procedure SetKbdInterrupt;
var
	i : integer;
begin
	Key:=#0;
	SpecialKeys:=0;
	for i:=1 to sizeof(KeyHit) do KeyHit[i]:=FALSE;
	GetIntVec($09,@Int09Save);
	SetIntVec($09,addr(KbdHandler));
	KeyInstalled:=TRUE;
end;

procedure RestoreKbdInterrupt;
begin
	if NOT KeyInstalled then exit;
	SetIntVec($09,@Int09Save);
	KeyInstalled:=FALSE;
end;

procedure SetAllInterrupts;
begin
	SetTimerInterrupt;
	SetKbdInterrupt;
(*	Port[$21]:=$5C; {Turns off IRQ 2,3,4, and 6}*)
end;

procedure RestoreAllInterrupts;
begin
	RestoreTimerInterrupt;
	RestoreKbdInterrupt;
(*	Port[$21]:=0; {Give life back to IRQs}*)
end;

function KeyPressed : boolean;
{Test if a key has been struck}
begin
	if (KeyInstalled) then KeyPressed:=Key<>#0
	else KeyPressed:=CRT.KeyPressed;
end;


(*-----------------------------------------*)


begin
	TimerProc:=NIL;
	TimerInstalled:=FALSE;
	KeyInstalled:=FALSE;
end.

