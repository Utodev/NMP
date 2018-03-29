UNIT ERRORLIB;

INTERFACE

USES SEGMENT2;
PROCEDURE Error(N:Byte);

CONST ErrorLocalizado:Boolean=False;


IMPLEMENTATION

PROCEDURE Error(N:Byte);
BEGIN
 Refresh;
 IF N<>24 THEN ASM
  MOV AX,3
  INT 10h
 END;
 ErrorLocalizado:=True;
 IF NOT (N IN [0,24,34]) THEN Write('Error cr¡tico : ');
 CASE N OF
 2:WriteLn('No tiene suficiente memoria base.');
 3:WriteLn('Error leyendo fichero.');
 4:WriteLn('Fichero F.DAT no se encuentra.');
 5:WriteLn('Fichero de caracteres no se encuentra.');
 6:WriteLn('Fichero W.DAT no se encuentra.');
 7:WriteLn('Error de escritura. Probablemente disco lleno o protegido.');
 8:WriteLn('Divisi¢n por cero.');
 9:WriteLn('Falta alg£n fichero de vocabulario.');
 10:WriteLn('Fichero NMP.CON no se encuentra.');
 11:WriteLn('Uno de los objetos no tiene definida su palabra en el vocabulario.');
 12:WriteLn('Fichero O.DAT no se encuentra.');
 15:WriteLn('Fichero SBLASTER.DRV no se encuentra.');
 16:WriteLn('Conversaci¢n no se encuentra.');
 17:WriteLn('Fichero TESTER.OVR no se encontr¢ o es err¢neo.');
 18:WriteLn('Su tarjeta no soporta el modo de video requerido.');
 20:WriteLn('Protecci¢n anti-copia.');
 21:WriteLn('Strings ya creadas.');
 22:WriteLn('Font en formato antiguo.');
 23:WriteLn('Se trat¢ de acceder a string inexistente.');
 24:BEGIN END; (* Salida de -? *)
 25:WriteLn('No se puede usar PCXFAST en este modo de video.');
 26:WriteLn('Fichero PCX de m s 64K. No puede usar PCXFAST');
 27:WriteLn('Requiere un 386 o superior para ejecutar este programa.');
 28:WriteLn('N§ de frase err¢nea.');
 29:WriteLn('No existe ese men£ en la conversaci¢n.');
 30:WriteLn('No aparecieron frases en men£ de conversaci¢n.');
 31:WriteLn('Capull¢n manejando el programa, juego detenido.');
 32:WriteLn(#13,#10,'Ha pulsado usted la combinaci¢n de teclas secreta que supuestamente s¢lo el ',#13,
        #10,'programador del parser conoce.',#13,#10,
            'ESTE PROGRAMA HA SIDO CREADO USANDO EL PARSER NMP DE NM SOFT',#13,#10,
            'EL AUTOR DEL PARSER NO SE HACE RESPONSABLE DE LOS PROGRAMAS',#13,#10,
            'CREADOS CON EL PARSER, NI DE LAS PERDIDAS DE DATOS O CUALQUIER',#10,#13,
            'TIPO DE DA¥OS QUE PUDIERAN AFECTAR A SEGUNDOS O A TERCEROS.',#13,#10,#13,#10,
            'Carlos S nchez Garc¡a, autor de NMP.');
 34:BEGIN END; (* Salida de BOSS *)
 35:WriteLn('Directorio no v lido o espacio insuficiente. Use opci¢n -d.');
 36:WriteLn('No se puede inicializar buffer para puerto serie.');
 37:WriteLn('No se puede inicializar el puerto serie.');
 38:WriteLn('No se puede realizar la transimisi¢n.');
 39:WriteLn('Error en l¡nea, revise conexiones o rebaje velocidad.');
 40:WriteLn('Conexi¢n intecrrumpida.');
 41:WriteLn('Se detect¢ Sound Blaster, pero no existe'+#10+#13,'variable de entorno BLASTER');
 42:WriteLn('Fichero SFX demasiado grande.');
 END;
 halt(N);
END;

end.