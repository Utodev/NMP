
USES VESA;

FUNCTION HEX(C:Word):String;
VAR S:String;
    B:Word;
BEGIN
 S:='';
 WHILE C<>0 DO
  BEGIN
   B:=C MOD 16;
   C:=C DIV 16;
   IF B<10 THEN S:=char(B+48)+S
           ELSE S:=char(B+55)+S
  END;
 S:=Copy('0000',1,4-byte(S[0]))+S;
 HEX:=S
END;

FUNCTION DOSALA(N:Word):Longint;
BEGIN
 DOSALA:=1 SHL N;
END;


PROCEDURE CheckModes(M0,M1:Word);
VAR IB:ModeInfoBlock;
    C:Word;
BEGIN
 FOR C:=M0 TO M1 DO
  BEGIN
   IF ValidMode(C) THEN Write(HEX(C),'h : ');
   GetModeInfo(C,IB);
   IF ValidMode(C) THEN Write(IB.Xresolution:4,'x',IB.Yresolution:4,' ',DOSALA(IB.BitsPerPixel):10 ,' colores.');
   IF ValidMode(C) THEN WriteLn;
  END;
END;

BEGIN
 WriteLn;
 WriteLn;
 WriteLn('VESAINFO (C) 1995 NM Software. -  MADRID');
 WriteLn;
 IF NOT IsVESA THEN BEGIN
                     WriteLn('BIOS VESA no detectada.');
                     Halt
                    END;
 WriteLn('Firma fabricante : ',GetOEMString);
 WriteLn('Video RAM : ',VideoRamSize,'K');
 WriteLn;
 CheckModes($100,$107);
 CheckModes($10D,$11B);
END.