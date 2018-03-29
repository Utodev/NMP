
CONST OddSize=4096;
TYPE ODDString=RECORD
            LEN:Word;
            TXT:ARRAY[0..OddSize-1] OF Char;
           END;

VAR OddStr:OddString;

PROCEDURE ClearOdd;
BEGIN
 OddStr.LEN:=0
END;

PROCEDURE AddOddStr(S:String);
BEGIN
 IF Byte(S[0])+OddStr.Len>OddSize THEN Byte(S[0]):=OddSize-OddStr.Len;
 MOVE(S[1],OdDStr.TXT[OddStr.Len],byte(S[0]));
 INC(oddStr.len,byte(S[0]));
END;

PROCEDURE SubOddStr(VAR S:String);
BEGIN
 IF OddStr.len<254 THEN BEGIN
                         Move(OddStr.Txt,S[1],OddStr.Len);
                         byte(S[0]):=OddStr.Len;
                         OddStr.Len:=0
                        END
                   ELSE BEGIN
                         Move(OddStr.Txt,S[1],253);
                         byte(S[0]):=253;
                         WHILE (S[0]<>#0) AND (S[Byte(S[0])]<>' ') DO DEC(byte(S[0]));
                         Dec(OddStr.Len,byte(S[0]));
                         Move(OddStr.TXT[byte(S[0])],OddStr.TXT,OddStr.Len)
                        END
END;

PROCEDURE XOROddStr;
VAR I:WORD;
BEGIN
 IF OddStr.LEN>0 THEN
  WITH Oddstr DO FOR I:=0 TO LEN-1 DO Byte(TXT[i]):=Byte(TXT[I]) XOR 71;
END;