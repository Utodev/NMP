



UNIT SBMIXER;

INTERFACE

CONST LChannel=1;
      RChannel=0;
      LRChannel=2;


         PROCEDURE MixerPort(P:Word);
         (* Indica a la unidad que puerto debe usar *)

         PROCEDURE V_Master(Canal:Byte;S:ShortInt);
         PROCEDURE V_Voice(Canal:Byte;S:ShortInt);
         PROCEDURE V_FM(Canal:Byte;S:ShortInt);
         PROCEDURE V_CD(Canal:Byte;S:ShortInt);


IMPLEMENTATION

VAR SB_Port:WorD;


         PROCEDURE MixerPort(P:Word);
         (* Indica a la unidad que puerto debe usar *)
         BEGIN
          SB_Port:=P
         END;


PROCEDURE WriteMixer(Reg,Valor:Byte);
BEGIN
 Port[SB_Port+4]:=Reg;
 Port[SB_Port+5]:=Valor;
END;

PROCEDURE ReadMixer(Reg:Byte; VAR Valor:Byte);
BEGIN
 Port[SB_Port+4]:=Reg;
 Valor:=Port[SB_Port+5];
END;

PROCEDURE V_Master(Canal:Byte;S:ShortInt);
VAR B:Byte;
    A:Byte;
BEGIN
 ReadMixer($22,B);
 IF Canal=LChannel THEN BEGIN
                         A:=(B AND $F0) SHR 4;
                         IF S>0 THEN IF A<15 THEN INC(A);
                         IF S<0 THEN IF A>0 THEN DEC(A);
                         B:=(A SHL 4) OR (B AND $0F);
                        END ELSE
 IF Canal=RChannel THEN BEGIN
                         A:=B AND $0F;
                         IF S>0 THEN IF A<15 THEN INC(A);
                         IF S<0 THEN IF A>0 THEN DEC(A);
                         B:=A OR (B AND $F0);
                        END ELSE
 IF Canal=LRChannel THEN BEGIN
                         A:=B AND $0F;
                         IF S>0 THEN IF A<15 THEN INC(A);
                         IF S<0 THEN IF A>0 THEN DEC(A);
                         B:=A OR (B AND $F0);
                         A:=(B AND $F0) SHR 4;
                         IF S>0 THEN IF A<15 THEN INC(A);
                         IF S<0 THEN IF A>0 THEN DEC(A);
                         B:=(A SHL 4) OR (B AND $0F);
                        END;
WriteMixer($22,B);
END;






PROCEDURE V_Voice(Canal:Byte;S:ShortInt);
BEGIN END;
PROCEDURE V_FM(Canal:Byte;S:ShortInt);
BEGIN END;
PROCEDURE V_CD(Canal:Byte;S:ShortInt);
BEGIN END;


BEGIN
END.