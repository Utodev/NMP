UNIT ILBM256;
{
	ILBM256
	- by Bjarke Viksoe

	Converts IFF/ILBM image file in format 320*200 in 256 colours to
	a raw image.
	No IO checking. No picturesize checking. Picture must be compressed.
}

INTERFACE

USES
	DEMOINIT, PICTURE;


function LoadPix(buffer : pScreen; filename : string):boolean;
function ConvertIFF(p : pScreen; v : pBuffer):boolean;


(*--------------------------------------*)

IMPLEMENTATION

TYPE
	string4 = string[4];

procedure IFFcmap(v : pBuffer; i, clength : word);
{extract colour map from file buffer}
var
	j : integer;
begin
	for j:=1 to clength do begin
		CMAP[j]:=v^[i] SHR 2;
		inc(i);
	end;
end;


procedure IFFbody(VAR p,v; VAR done : boolean);
{Decompress packed image from file buffer}
begin
	asm
		push	ds
		les	di,[p]
		lds	si,[v]
		xor	dx,dx
		cld
@IFF_loop:
		xor	ah,ah
		lodsb
		or		al,al
		js		@IFF_lower
		inc	ax
		add	dx,ax
		mov	cx,ax
		rep movsb
		cmp	dx,(320*200)
		jb		@IFF_loop
		jmp	NEAR PTR @IFF_done
@IFF_lower:
		neg	al
		inc	ax
		add	dx,ax
		mov	cx,ax
		lodsb
		rep stosb
		cmp	dx,(320*200)
		jb		@IFF_loop
@IFF_done:
		pop	ds
	end;

	done:=TRUE;
end;


function GetChunkName(v : pBuffer; VAR i : word) : string4;
begin
	GetChunkName:=ConCat(char(v^[i]),char(v^[i+1]),char(v^[i+2]),char(v^[i+3]));
	inc(i,4);
end;

function GetChunkSize(v : pBuffer; VAR i : word) : word;
var
	size : word;
begin
	size:=v^[i] SHL 8;
	inc(size,v^[i+1]); size:=size SHL 8;
	inc(size,v^[i+2]); size:=size SHL 8;
	inc(size,v^[i+3]);
	inc(i,4);
	GetChunkSize:=size;
end;


function ConvertIFF(p : pScreen; v : pBuffer):boolean;
{scan through ilbm-structure.
 'CMAP' and 'BODY' structures are pinned out and processed}
var
	i : word;
	done : boolean;
	flength : word;
	clength : word;
	chunkname : string4;
begin
        convertIff:=False;
	i:=1;
	if (GetChunkName(v,i)<>'FORM') then exit;
	flength:=GetChunkSize(v,i);
	if (GetChunkName(v,i)<>'PBM ') then exit;

	done:=FALSE;
	repeat
		chunkname:=GetChunkName(v,i);
		clength:=GetChunkSize(v,i);

		if (chunkname='CMAP') then IFFcmap(v, i,clength);
		if (chunkname='BODY') then IFFbody(p^,v^[i],done);
		if Odd(clength) then inc(clength);
		inc(i,clength);
	until (i > flength) OR done;
 convertiff:=true
end;


function LoadPix(buffer : pScreen; filename : string):Boolean;
var
	pFileMem: pBuffer;
	FileHandle : file;
	size : longint;
begin
	Assign(FileHandle, filename);
	Reset(FileHandle, 1);
	size := filesize(FileHandle);
	GetMem(pFileMem, size);
	BlockRead(FileHandle, pFileMem^, size);
	Close(FileHandle);
	Loadpix:=ConvertIFF(buffer, pFileMem);
	FreeMem(pFileMem, size);
end;


end.
