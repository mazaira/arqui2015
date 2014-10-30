*------------------AUTORES------------------*
*       David Páez Alderete (q080063)   	*
*       Jose Mascaró Perez (q080087)		*
*-------------------------------------------*

* Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000         * Pila
        DC.L    INICIO     	  * PC
		
* Definición de equivalencias
*********************************

MR1A    EQU     $effc01       * de modo A (escritura)
SRA     EQU     $effc03       * de estado A (lectura)
CRA     EQU     $effc05       * de control A (escritura)
TBA     EQU     $effc07       * buffer transmision A (escritura)
RBA     EQU     $effc07       * buffer recepcion A  (lectura)
ACR		EQU		$effc09	      * de control auxiliar
IMR     EQU     $effc0B       * de mascara de interrupcion A (escritura)
MR1B	EQU		$effc11		  * de modo B (escritura)
SRB		EQU		$effc13		  * de estado B (lectura)
CRB		EQU		$effc15		  * de control B (escritura)
TBB     EQU     $effc17       * buffer transmision B (escritura)
RBB     EQU     $effc17       * buffer recepcion B (lectura)
IVR     EQU     $effc19       * del vector de interrupción

* Zona de datos en memoria
*********************************		
        ORG     $400

punSA:			DS.B	4
punSB:			DS.B	4
punPA:			DS.B	4
punPB: 			DS.B	4		
punSARTI:		DS.B	4
punSBRTI:		DS.B	4
punPARTI:		DS.B	4
punPBRTI:		DS.B	4			
buffSA:			DS.B	2000
buffSB:			DS.B	2000
buffPA:			DS.B	2000
buffPB:			DS.B	2000
finPB:			DS.B	4
emptySA:		DS.B	1
emptySB:		DS.B	1
fullPA:			DS.B	1
fullPB:			DS.B	1

IMRcopia:
		DS.B	2

**************************** INIT *************************************************************
INIT:
        MOVE.B          #%00000011,MR1A     * 8 bits por carac. en A y solicita una int. por carac.
		MOVE.B          #%00000000,MR1A     * Eco desactivado en A
		MOVE.B          #%00000011,MR1B     * 8 bits por caract. en B y solicita una int. por carac.
		MOVE.B          #%00000000,MR1B     * Eco desactivado en B
        MOVE.B          #%11001100,SRA     	* Velocidad = 38400 bps.
		MOVE.B          #%11001100,SRB		* Velocidad = 38400 bps.
        MOVE.B          #%00000000,ACR      * Selección del primer conjunto de velocidades.
        MOVE.B          #%00000101,CRA      * Transmision y recepcion activados en A.
		MOVE.B          #%00000101,CRB      * Transmision y recepcion activados en B.
		MOVE.B			#$40,IVR			* Vector de interrupción 40.
		MOVE.B 			#%00100010,IMR 		* Habilitar las interrupciones
		MOVE.B          #%00100010,IMRcopia * Habilitamos las interrupciones en la copia de IMR
		LEA				RTI,A1				* Dirección de la tabla de vectores
		MOVE.L          #$100,A2			* $100 es la dirección siguiente al V.I.
		MOVE.L          A1,(A2)				* Actualización de la dirección de la tabla de vectores
		LEA				buffSA,A1			* Dirección de buffSA -> A1
		MOVE.L			A1,punSA			* punSA apunta al primero del buffSA
		MOVE.L			A1,punSARTI			* puntero para la RTI
		MOVE.B			#1,emptySA			* El buffSA inicialmente no está lleno
		LEA				buffSB,A1			* Dirección de buffSB -> A1
		MOVE.L			A1,punSB			* punSB apunta al primero del buffSB
		MOVE.L			A1,punSBRTI			* puntero para la RTI
		MOVE.B			#1,emptySB			* El buffSB inicialmente no está lleno
		LEA				buffPA,A1			* Dirección de buffPA -> A1
		MOVE.L			A1,punPA			* punPA apunta al primero del buffPA
		MOVE.L			A1,punPARTI			* puntero para la RTI
		MOVE.B			#0,fullPA			* El buffPA inicialmente no está lleno
		LEA				buffPB,A1			* Dirección de buffPB -> A1
		MOVE.L			A1,punPB			* punPB apunta al primero del buffPB
		MOVE.L			A1,punPBRTI			* puntero para la RTI
		MOVE.B			#0,fullPB			* El buffPB inicialmente no está lleno
		LEA				finPB,A1			* Dirección fin de buffPB -> A1
		MOVE.L			A1,finPB			* finPB apunta al último elemento del buffPB
        RTS
**************************** FIN INIT *********************************************************
**************************** LEECAR **********************************************************

LEECAR:
		*MOVEM.L		D1-D5/A0-A5,-(A7) * GUARDAMOS 		
		LINK		A6,#0
		BTST		#0,D0			* Comprobamos el bit 0
		BNE			LIN_B			* Si es 1 Linea de transmision B 
		BTST		#0,D0			* Comprobamos el bit 0
		BEQ 		LIN_A			* Si es 0 Linea de transmisión 			

LIN_A:	
		BTST		#1,D0			* Comprobamos el bit 1
		BEQ			BUFF_RA			* Si es 0 selecciona el buff de recepción
		BTST		#1,D0			* Comprobamos el bit 1
		BNE			BUFF_TA			* Si es 1 selecciona buff de transmisión	


BUFF_RA:
		MOVE.L 		punSA,A2		* Cargamos el puntero que vamos a utlizar
		MOVE.L 		punSARTI,A4		* Cargamos el puntero con el que vamos a hacer la comprobación
		LEA 		buffSB,A3		* Cargamos fin de buffer
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ 		RESET_RA
		SUB.L 		#1,A2
		CMP.L 		A2,A4
		BEQ ES_VACIO
BU_RAL:	MOVE.B		(A2)+,D0		* Metemos el caracter en D0 y lo avanzamos.
		MOVE.L		A2,punSA		* Actualizamos puntero
		BRA 		LE_FIN			* Nos vamos a fin.
	

BUFF_TA:
		MOVE.L 		punPARTI,A2		* Cargamos el puntero que vamos a utlizar
		MOVE.L		punPA,A4		* Cargamos el puntero para la comprobación
		LEA			buffPB,A3		* Cargamos direccion de fin de buff
		CMP.L 		A4,A2			* Comprobamos si el buff esta vacio
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ 		RESET_RA
		SUB.L 		#1,A2
		CMP.L 		A2,A4
		BEQ ES_VACIO
BU_TAL:	MOVE.B		(A2)+,D0		* Metemos el caracter en D0 y lo avanzamos.
		MOVE.L		A2,punPARTI		* Actualizamos puntero
		BRA 		LE_FIN			* Nos vamos a fin.
		
LIN_B:	
		BTST		#1,D0			* Comprobamos el bit 1
		BEQ			BUFF_RB			* Si es 0 selecciona el buff de recepción
		BTST		#1,D0			* Comprobamos el bit 1
		BNE			BUFF_TB			* Si es 1 selecciona buff de transmisión	

BUFF_RB:
		MOVE.L 		punSB,A2		* Cargamos el puntero que vamos a utlizar	
		MOVE.L		punSBRTI,A4		* Cargamos el puntero para la comprobación
		LEA 		buffPA,A3		* Final de buffPA
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ 		RESET_RA
		SUB.L 		#1,A2
		CMP.L 		A2,A4
		BEQ ES_VACIO
BU_RBL:	MOVE.B		(A2)+,D0		* Metemos el caracter en D0 y lo avanzamos.
		MOVE.L		A2,punSB		* Actualizamos puntero
		BRA 		LE_FIN			* Nos vamos a fin.
		
BUFF_TB:
		MOVE.L 		punPBRTI,A2		* Cargamos el puntero que vamos a utlizar
		MOVE.L		punPB,A4		* Cargamos el puntero para la comprobación
		LEA 		finPB,A3		* Cargamos la dirección para la comprobación
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ 		RESET_RA
		SUB.L 		#1,A2
		CMP.L 		A2,A4
		BEQ ES_VACIO
BU_TBL:	MOVE.B		(A2)+,D0		* Metemos el caracter en D0 y lo avanzamos.
		MOVE.L		A2,punPBRTI		* Actualizamos puntero
		BRA 		LE_FIN			* Nos vamos a fin.
		
RESET_TA:
		LEA buffPA,A5
		MOVE.L A5,A2
		BRA BU_RAL

RESET_RA:
		LEA buffSA,A5
		MOVE.L A5,A2
		BRA BU_TAL
RESET_RB:
		LEA buffSB,A5
		MOVE.L A5,A2
		BRA BU_RBL

RESET_TB:
		LEA buffPB,A5
		MOVE.L A5,A2
		BRA BU_TBL



ES_VACIO:
		MOVE.L		#$FFFFFFFF,D0	* Si no ERROR
		BRA			LE_FIN
LE_FIN:
		*MOVEM.L (A7)+,D1-D5/A0-A5	* RECUPERAMOS
		UNLK A6
		RTS

**************************** FIN LEECAR ******************************************************

**************************** ESCCAR **********************************************************

ESCCAR:
		*MOVEM.L		D1-D5/A0-A5,-(A7) * GUARDAMOS 
		LINK A6,#0
		BTST		#0,D0			* Comprobamos el bit 0
		BNE			LI_B			* Si es 1 Linea de transmision B
		BTST		#0,D0			* Comprobamos el bit 0
		BEQ 		LI_A			* Si es 0 Linea de transmisión A			

LI_A:	
		BTST		#1,D0			* Comprobamos el bit 1
		BEQ			BU_RA			* Si es 0 selecciona el buff de recepción
		BTST		#1,D0			* Comprobamos el bit 1
		BNE			BU_TA			* Si es 1 selecciona buff de transmisión	

BU_RA:	MOVE.L		punSARTI,A2		* Cargamos el puntero que vamos a utilizar
		MOVE.L 		punSA,A4		* Cargamos el puntero de SCAN
		LEA 		buffSB,A3		* Cargamos el final del buff		
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ			RST_RA
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		SUB.L 		#1,A2
CONT_RA:
		MOVE.B 		D1,(A2)+
		MOVE.L 		A2,punSARTI
		CLR.L 		D0
		BRA 		ES_FIN		
		

BU_TA:	MOVE.L		punPA,A2		* Cargamos el puntero que vamos a utilizar
		MOVE.L		punPARTI,A4		* Cargamos puntero de lectura
		LEA			buffPB,A3		* Cargamos direccion de final de buff.
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ			RST_TA
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		SUB.L 		#1,A2
CONT_TA:
		MOVE.B 		D1,(A2)+
		MOVE.L 		A2,punPA
		CLR.L 		D0
		BRA 		ES_FIN		
		
LI_B:	
		BTST		#1,D0			* Comprobamos el bit 1
		BEQ			BU_RB			* Si es 0 selecciona el buff de recepción
		BTST		#1,D0			* Comprobamos el bit 1
		BNE			BU_TB			* Si es 1 selecciona buff de transmisión	
BU_RB:	MOVE.L 		punSBRTI,A2		* Cargamos el puntero que vamos a utilizar
		MOVE.L		punSB,A4		* Cargamos la dirección para comprobar si los punteros son iguales.
		LEA 		buffPA,A3		* Cargamos la direccion del fin de buff
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ			RST_RB
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		SUB.L 		#1,A2
CONT_RB:
		MOVE.B 		D1,(A2)+
		MOVE.L 		A2,punSBRTI
		CLR.L 		D0
		BRA 		ES_FIN		

BU_TB:
		MOVE.L 		punPB,A2		* Cargamos el puntero que vamos a utilizar
		MOVE.L		punPBRTI,A4		* Cargamos la dirección para comprobar si estamos al final del buff.
		LEA			finPB,A3		* Cargamos direccion de find e puntero
		ADD.L 		#1,A2
		CMP.L 		A2,A3
		BEQ			RST_TB
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		SUB.L #1,A2
CONT_TB:
		MOVE.B 		D1,(A2)+

		MOVE.L 		A2,punPB
		CLR.L 		D0
		BRA 		ES_FIN		

		**************


RST_TA:
		LEA buffPA,A5
		MOVE.L A5,A2
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		BRA CONT_TA		

RST_RA:
		LEA buffSA,A5
		MOVE.L A5,A2
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		BRA CONT_RA
RST_RB:
		LEA buffSB,A5
		MOVE.L A5,A2
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		BRA CONT_RB

RST_TB:
		LEA buffPB,A5
		MOVE.L A5,A2
		CMP.L 		A2,A4
		BEQ 		ES_LLENO
		BRA CONT_TB
		
ES_LLENO:
		MOVE.L		#$FFFFFFFF,D0	* Si no ERROR
		BRA			ES_FIN
ES_FIN:
		*MOVEM.L (A7)+,D1-D5/A0-A5	* RECUPERAMOS
		UNLK A6
		RTS
		
**************************** ESCCAR ************************************************************
**************************** SCAN ************************************************************
SCAN:	LINK		A6,#0
		MOVE.L		8(A6),A1		* Dir. del buffer.
		MOVE.W		12(A6),D1		* Descriptor --> D1
		MOVE.W		14(A6),D2		* Tamaño --> D2
		MOVE.L		#0,D4			* Inicializo contador
		MOVE.L		#0,D0
		CMP.L		#0,D2			* Si tamaño = 0
		BEQ			SCAN_FIN
		CMP.B		#0,D1
		BEQ			SCAN_A			* Si descriptor = 0 lee de A
		CMP.B		#1,D1
		BEQ			SCAN_B			* Si descriptor = 1 lee de B
		MOVE.L		#$FFFFFFFF,D0	* Si no ERROR
		BRA			SCAN_FIN		* y sale de SCAN
		

SCAN_A:	
		CMP.L		D4,D2			* Compruebo contadores
		BEQ			SC_AA			* Si son iguales nos salimos
		MOVE.L		#0,D0			* Un 0 en D0 para asegurarnos que esta vacio	
		BSR 		LEECAR			* Saltamos a leecar con los dos bits a 0.
		CMP.L		#$FFFFFFFF,D0	* Si d0 = #$FFFFFFFF buffer vacio
		BEQ			SC_AA			* Nos salimos si error.
		MOVE.B		D0,(A1)+		* El caracter leido,D0, lo metemos en A1
		ADD.L		#1,D4			* +1 en contador.
		BRA			SCAN_A			* Vuelvo a Scan
		
SC_AA:
		MOVE.L		D4,D0			* Ponemos el contador en D0, indica el nº de caracteres leidos.
		BRA			SCAN_FIN		* FIN
		
SCAN_B:
		CMP.L		D4,D2			* Compruebo contadores
		BEQ			SC_BB			* Si son iguales nos salimos
		MOVE.L		#0,D0			* Un 0 en D0 para asegurarnos que esta vacio
		MOVE.B 		#1,D0			* 
		BSR			LEECAR			* Salto a leecar.
		CMP.L		#$FFFFFFFF,D0	* Si d0 = #$FFFFFFFF buffer vacio
		BEQ			SC_BB			* Nos salimos si error.
		MOVE.B		D0,(A1)+		* El caracter leido,D0, lo metemos en A.
		ADD.L		#1,D4			* +1 en contador.
		BRA			SCAN_B			* Vuelvo a Scan

SC_BB:
		MOVE.L		D4,D0			* Ponemos el contador en D0, indica el nº de caracteres leidos.
		BRA			SCAN_FIN		* FIN
		
SCAN_FIN:
		UNLK		A6
		RTS  


		
******************************* FIN SCAN *****************************************************
****************************  PRINT  *********************************************************
PRINT:  LINK		A6,#0
		MOVE.L		8(A6),A1		* Dirección del buffer.
		MOVE.W		12(A6),D1		* Descriptor --> D1
		MOVE.W		14(A6),D2		* Tamaño --> D2
		MOVE.L		#0,D4			* Inicialización D4 = 0
		MOVE.L		#0,D0			* Limpio D0
		CMP.W		#0,D2			* Si tamaño = 0
		BEQ			PRINT_FIN	
		CMP.W		#0,D1
		BEQ			PRINT_A			* Si descriptor = 0 escribe en A
		CMP.W		#1,D1
		BEQ			PRINT_B			* Si descriptor = 1 escribe en B
		MOVE.L		#$FFFFFFFF,D0	* Si no ERROR,
		BRA			PRINT_FIN		* y sale de PRINT.
		
PRINT_A:
		CMP.L		D2,D4			* Comprobamos el numero de caracteres leido.
		BEQ			PR_FIN			* Si es igual nos salimos.
		MOVE.L		#0,D0			* Un 0 en D0 para asegurarnos que esta vacio
		MOVE.L		#1,D0			*BSET.B 		#1,D0// BIT 0 = 0, BIT 1 = 1;
		MOVE.L		#0,D1			* Limpiamos el D1
		MOVE.B		(A1)+,D1		* D1 caracter a escribir por ESCCAR
		BSR 		ESCCAR			* saltamos a ESCCAR
		CMP.L		#$FFFFFFFF,D0	* Si d0 = #$FFFFFFFF buffer lleno
		BEQ			PR_FIN			* Nos salimos
		ADD.L		#1,D4			* Contador ++
		CMP.W		D2,D4			* Comparamos con nº de car. a escribir.
		BNE			PRINT_A			* Si no son iguales, vamos a comprobar los punteros para seguir.
		BRA			FIN_PA			* si son iguales nos vamos.


FIN_PA:
		MOVE.W		#$2700,SR		* Inhibimos interrupciones
		BSET.B		#0,IMRcopia		* Habilitamos las interrupciones en A
		MOVE.B		IMRcopia,IMR	* Actualizamos IMR
		MOVE.W		#$2000,SR		* Permitimos de nuevo las interrupciones        
		BRA			PR_FIN

PRINT_B:
		CMP.L		D2,D4			* Comprobamos el numero de caracteres leido.
		BEQ			PR_FIN			* Si es igual nos salimos
        MOVE.L		#0,D0			* Un 0 en D0 para asegurarnos que esta vacio
        MOVE.B 		#3,D0			* BSET.B		#1,D0 //BIT 0 = 1, BIT 1 = 1;
        MOVE.L		#0,D1			* Limpiamos d1.
        MOVE.B		(A1)+,D1		* D1 caracter a escribir por ESCCAR
        BSR			ESCCAR			* saltamos a ESCCAR
        CMP.L		#$FFFFFFFF,D0	* Si d0 = #$FFFFFFFF buffer lleno
		BEQ			PR_FIN			* 
		ADD.L		#1,D4			* Contador ++
		CMP.L		D2,D4			* Comparamos con nº de car. a escribir.
		BNE			PRINT_B		* Si no son iguales, vamos a comprobar los punteros para seguir.
		BRA			FIN_PB			* Si son iguales salimos.

FIN_PB:
        MOVE.W		#$2700,SR		* Inhibimos interrupciones
		BSET.B		#4,IMRcopia		* Habilitamos las interrupciones en A
		MOVE.B		IMRcopia,IMR	* Actualizamos IMR
		MOVE.W		#$2000,SR		* Permitimos de nuevo las interrupciones        
		BRA			PR_FIN
		
PR_FIN:	MOVE.L D4,D0
PRINT_FIN:
		UNLK		A6
		RTS      
**************************** FIN PRINT ******************************************************
**************************** RTI ************************************************************
RTI:
		MOVE.W		D0,-(A7)		* Guardamos los registros utilizados en SCAN y PRINT
		MOVE.W		D1,-(A7)
		MOVE.W		D2,-(A7)
		MOVE.W		D3,-(A7)
		MOVE.W		D4,-(A7)
		MOVE.W		D5,-(A7)
		MOVE.L		A1,-(A7)
		MOVE.L		A2,-(A7)
		MOVE.L		A3,-(A7)
		MOVE.L		A4,-(A7)
		MOVE.B		IMRcopia,D1		* D1 <-- copia de la máscara de interrupción
		AND.B		IMR,D1			* D1 <-- IMR ^ IMRcopia
		BTST		#0,D1			* Comprobamos el bit 0
		BNE			T_RDY_A			* Si es 1 transmitir por linea A
		BTST		#1,D1			* Comprobamos el bit 1
		BNE			R_RDY_A			* Si es 1 recibir por linea A
		BTST		#4,D1			* Comprobamos el bit 4
		BNE			T_RDY_B			* Si es 1 transmitir por linea B
		BTST		#5,D1			* Comprobamos el bit 5
		BNE			R_RDY_B			* Si es 1 recibir por linea B
		BRA			RTI_FIN			* Si no esta activo ninguno saltar a RTI_FIN
T_RDY_A:
		MOVE.L		#0,D0			* D0 = 0
		BSET		#1,D0			* BIT 0 = 0, BIT 1 = 1; 
		BSR 		LEECAR			* Salto a leecar.
		CMP.L		#$FFFFFFFF,D0	* Si d0 = #$FFFFFFFF buffer vacio
		BEQ 		FIN_TA			* Si error fin.
		MOVE.B		D0,TBA			* Introducimos el caracter en la linea A de transmisión.	
		BRA 		RTI_FIN			* Si son iguales hemos terminado

FIN_TA:        	
		BCLR.B		#0,IMRcopia		* Deshabilitamos interrupciones en la linea A
		MOVE.B		IMRcopia,IMR	* Actualizamos IMR
		MOVE.L		#0,D0			* Limpiamos D0 al volver de vacio
		BRA			RTI_FIN			* Saltamos al final de la rti
		
T_RDY_B:
		MOVE.L		#0,D0			* D0 = 0
		BSET		#1,D0			* BIT 0 = 1, BIT 1 = 1
		BSET 		#0,D0			*	
		BSR 		LEECAR			* Salto a LEECAR
		CMP.L		#$FFFFFFFF,D0	* Si d0 = #$FFFFFFFF buffer vacio
		BEQ			FIN_TB			* Si error, fin.
		MOVE.B 		D0,TBB			* Introducimos el caracter en la linea B de transmisión.
		BRA 		RTI_FIN			*
		
FIN_TB:       
		BCLR.B		#4,IMRcopia		* Deshabilitamos interrupciones en la linea A
		MOVE.B		IMRcopia,IMR	* Actualizamos IMR
		MOVE.L		#0,D0			* Limpiamos D0 al volver de D0
		BRA			RTI_FIN			* Saltamos al final de la rti

R_RDY_A:
		MOVE.L		#0,D1			* D1 = 0, para cargar el car a leer en un reg vacio.
		MOVE.B		RBA,D1			* Cogemos el caracter del puerto de recepción
		MOVE.L		#0,D0			* D0 = 0
		BSR			ESCCAR			* Vamos a rutina ESCCAR
		BRA			RTI_FIN			* Si error, fin.


R_RDY_B:
		MOVE.L		#0,D1			* D1 = 0, para cargar el car a leer en un reg vacio.
		MOVE.B		RBB,D1			* Cogemos el caracter del puerto de recepción
		MOVE.W		#0,D0			* Reseteamos D0
		BSET		#0,D0			* BIT 0 = 1
		BSR			ESCCAR			* Vamos a rutina ESCCAR
		BRA			RTI_FIN			* si error fin.

RTI_FIN:
		MOVE.L		(A7)+,A4		* Restauramos los registros
		MOVE.L		(A7)+,A3
		MOVE.L		(A7)+,A2
		MOVE.L		(A7)+,A1
		MOVE.W		(A7)+,D5
		MOVE.W		(A7)+,D4
		MOVE.W		(A7)+,D3
		MOVE.W		(A7)+,D2
		MOVE.W		(A7)+,D1
		MOVE.W		(A7)+,D0
		RTE
**************************** FIN RTI ********************************************************


**************************** PROGRAMAS PRINCIPALES **********************************************

*** Prueba básica:

	BUFFER: DS.B    2000				* Buffer para lectura y escritura de caracteres
	PARDIR: DC.L    0					* Direcci ́on que se pasa como par ́ametro
	PARTAM: DC.W    0					*Tama~noquesepasacomopar ́ametro
	CONTC:  DC.W    0					* Contador de caracteres a imprimir
	DESA: 	EQU 	0					* Descriptor l ́ınea A
	DESB: 	EQU 	1					* Descriptor l ́ınea B
	TAMBS:  EQU     2					* Tama~no de bloque para SCAN 
	TAMBP:  EQU     2				* Tama~no de bloque para PRINT


 * Manejadores de excepciones
INICIO:
		MOVE.L  #BUS_ERROR,8    	* Bus error handler
        MOVE.L  #ADDRESS_ER,12  	* Address error handler
        MOVE.L  #ILLEGAL_IN,16  	* Illegal instruction handler
        MOVE.L  #PRIV_VIOLT,32  	* Privilege violation handler
        MOVE.L  #ILLEGAL_IN,40  	* Illegal instruction handler
        MOVE.L  #ILLEGAL_IN,44  	* Illegal instruction handler

		BSR     INIT
		MOVE.W  #$2000,SR			* Permite interrupciones

BUCPR:  MOVE.W	#TAMBS,PARTAM		* Inicializa par ́ametro de tama~no
        MOVE.L  #BUFFER,PARDIR		*Par ́ametroBUFFER=comienzodelbuffer	
OTRAL:  MOVE.W	PARTAM,-(A7)		*Tama~nodebloque
        MOVE.W  #DESA,-(A7)			* Puerto A
		MOVE.L  PARDIR,-(A7)		*Direcci ́ondelectura
ESPL:   BSR 	SCAN
        ADD.L   #8,A7				* Restablece la pila
        ADD.L   D0,PARDIR			*Calcula la nueva direcci ́ondelectura
        SUB.W   D0,PARTAM			* Actualiza el n ́umero de caracteres le ́ıdos
        BNE     OTRAL				* Si no Se han leIdo todas los caracteres  
        							* del bloque se vuelve a leer
        
        MOVE.W  #TAMBS,CONTC		* Inicializa contador de caracteres a imprimir
        MOVE.L  #BUFFER,PARDIR		*Par ́ametroBUFFER=comienzodelbuffer

OTRAE:  MOVE.W  #TAMBP,PARTAM		* Tama~no de escritura = Tama~no de bloque

ESPE:
		MOVE.W	PARTAM,-(A7) 		*Tama~no de escritura
		MOVE.W 	#DESB,-(A7)			* Puerto B
        MOVE.L  PARDIR,-(A7)		*Direcci ́ondeescritura
        BSR     PRINT
        ADD.L   #8,A7				* Restablece la pila
        ADD.L   D0,PARDIR			* Calcula la nueva Direcci ́ondelbuffer
        SUB.W   D0,CONTC			* Actualiza el contador de caracteres
        BEQ     SALIR				* Si no quedan caracteres se acaba
        SUB.W   D0,PARTAM			* Actualiza el tama~no de escritura
        BNE     ESPE				* Si no se ha escrito todo el bloque se insiste	
        CMP.W   #TAMBP,CONTC		* Si el no de caracteres que quedan es menor que 
        							* el tama~no establecido se imprime ese n ́umero
		BHI     OTRAE				* Siguiente bloque
        MOVE.W  CONTC,PARTAM
        BRA		ESPE				* Siguiente bloque

SALIR:  BRA		BUCPR

BUS_ERROR: 		BREAK
				NOP					* Bus error handler
ADDRESS_ER:		BREAK
				NOP					* Address error handler
ILLEGAL_IN:		BREAK
				NOP					* Illegal instruction handler
PRIV_VIOLT:		BREAK
				NOP					* Privilege violation handler
**************************** FIN PROGRAMAS PRINCIPALES ******************************************		


*$BSVC/68kasm -la es_int_2810.s
*$BSVC/bsvc /usr/local/bsvc/samples/m68000/practica.setup