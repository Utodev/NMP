USES CRT;


{$IFDEF TP}
const MaxBlockSize = 65528;
{$ELSE}
const MaxBlockSize = 1024 * 1000;
{$ENDIF}

type Tintas=(normal,letras,cadena,indireccion,numero,entrada,comentario,nombreproc,llave,constante);
     PChar = ^Char;

const InfoMsg1 = 'Este programa forma parte del entorno de NMP' ;
      InfoMsg2 = 'y s¢lo puede ser ejecutado de manera interna.' ;

      KEY_ESC = 27;
      KEY_RTN = 13;
      KEY_TAB = 8;
      KEY_BCK = 9;

const WindowX0 = 2;
      WindowY0 = 3;
      WindowWidth = 78;
      WindowHeight = 20;

const INKS : array[normal..constante] of byte=($1F,$1F,$16,$1C,$1E,$1A,$17,$1D,$12,$15);

var Texto : PChar;
    TextSize : Longint;
    TextMaxSize : Longint;
    Filename : String;
    X,Y : Longint;
    TextOffset : Longint;
    HaveToSave, Modified : Boolean;

procedure CreateBuffer;
begin
 TextSize := 0;
 TextMaxSize := MaxAvail;
 if TextMaxSize > MaxBlockSize then
  TextMaxSize := MaxBlockSize;
 GetMem(Texto,TextMaxSize);
end;

procedure DisposeBuffer;
begin
 FreeMem(Texto,TextMaxSize);
end;

procedure ShowInfo;
begin
 WriteLn(InfoMsg1);
 WriteLn(InfoMsg2);
 Halt(1)
end;

procedure CheckParameters;
begin
 if (ParamCount <> 2) or (ParamStr(2)<>'CSG') then ShowInfo;
 FileName := ParamStr(1);
end;

procedure LoadFile;
var TextFile : File;
    B : Byte;
begin
 Assign(TextFile,FileName);
 TextSize := 0;
 Reset(TextFile,1);
 if IOresult <> 0 then Exit;
 while not Eof(TextFile) do
  begin
   BlockRead(TextFile,B,1);
   if B in [13,32..255] then begin
    Pchar(Longint(Texto)+TextSize)^ := Char(B);
    Inc(TextSize);
   end;
  end;
 Close(TextFile);
 X := 0;
 Y := 0;
 HaveToSave := False;
 Modified := False;
 TextOffset := 0;
end;

procedure SaveFile;
var TextFile : File;
begin
 Assign(TextFile, Filename);
 Rewrite(TextFile, 1);
 BlockWrite(TextFile, Texto^, TextSize);
 Close(TextFile);
end;

function GetKey : Word;
var a : byte;
    w : Word;
begin
 a := Byte(Readkey);
 w := a;
 if a = 0 then
  begin
   w := byte(Readkey) shl 8;
  end;
 GetKey := w;
end;

procedure Repaint;
var  i : word;
begin
 for i := 0 to WindowHeight - 1 do
  begin

  end;
end;


procedure InsertChar(Ch : Char);
begin
 Move(Pointer(Longint(Texto) + TextOffset) ^,
      Pointer(Longint(Texto) + TextOffset + 1) ^,
      TextSize - TextOffset );
 PChar(Longint(Texto) + TextOffset) ^ := Ch;
 Inc(TextSize);
 Inc(TextOffset);
end;

procedure EditFile;
var IsEditing : Boolean;
    Key : Word;
begin
 IsEditing := True;
 RePaint;
 repeat
  Key := GetKey;
  case Key of
   KEY_ESC : IsEditing := False;
   KEY_RTN, KEY_TAB, 32..255 : InsertChar(Chr(Key));
  end;
 until not IsEditing;
end;


begin
 CheckParameters;
 CreateBuffer;
 LoadFile;
 EditFile;
 if HaveToSave then SaveFile;
 DisposeBuffer;
END.

