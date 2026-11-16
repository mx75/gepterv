
;/*
; * **************************  ALTERA PROPRIETARY  ***************************
; *
; *       --------------------  DO NOT REPRODUCE  ----------------------
; *
; *   Copyright (C) 1994 by Altera Corporation.
; *   All rights reserved. No part of this program or publication may be 
; *   reproduced, transmitted, transcribed, stored in a retrieval system, or
; *   translated into any language or computer language, in any form or by any
; *   means, electronic, mechanical, magnetic, optical,  chemical,  manual, or
; *   otherwise,  without the prior written permission of  Altera Corporation,
; *   2610 Orchard Parkway,  San Jose,  California 95134-2020.
; *
; * ***************************************************************************
; */
;
;

devnum := 780
nfuses := 31704			; number of JEDEC fuses for EPX780
defval := 0			; default state of pdb
rowbeg := 1			; begining row
erowend := 54			; ending row EPROM
srowend := 53			; ending row SRAM
colbeg := 0			; begining col
colend := 599			; ending col
collen := 600			; column length
seccol := 33			; start security bit column
cmpcol := 33			; compare term column
secrow := 50			; start security bit row
cfbcolumns := 75		; number of columns per cfb
datapcktsize := 32		; size of the data part of a packet to eprom
blksperpckt := 2		; blocks per packet
cfbs := 8			; number of cfbs
nblocks := (cfbs/blksperpckt)	; number of packet blocks
rasize := 6			; row address size
casize := 3			; column address size
basize := 2			; block address size
instlen := 5			; instruction length
epromps := ( rasize +
              casize +
              basize +
              datapcktsize )	; eprom packet size

array raddr[rasize]		; row address packet
array physrow[collen]		; an entire physical row
array tmprow[collen]		; temporary physical row
array data[datapcktsize]	; the data for a download packet to eprom
array eprompckt[epromps]	; an entire packet for download to eprom
array srampckt[collen+rasize]	; an entire packet for download to sram

array ldvect[instlen]		; load vector instruction
array fread[instlen]		; eprom read instruction
array swrite[instlen]		; sram write instruction
array sread[instlen]		; sram read instruction
array fpgm[instlen]		; eprom program instruction
array idcode[instlen]		; idcode instruction
array portst[instlen]		; portst instruction
array status[instlen]		; array for status register

;
; JTAG semi-private instructions for the EPX device
;
  fpgm[4] := 1   fpgm[3] := 0   fpgm[2] := 1   fpgm[1] := 0   fpgm[0] := 1
 fread[4] := 0  fread[3] := 0  fread[2] := 1  fread[1] := 1  fread[0] := 0
 sread[4] := 1  sread[3] := 0  sread[2] := 0  sread[1] := 0  sread[0] := 0
swrite[4] := 0 swrite[3] := 1 swrite[2] := 1 swrite[1] := 1 swrite[0] := 1
ldvect[4] := 0 ldvect[3] := 0 ldvect[2] := 1 ldvect[1] := 0 ldvect[0] := 1
idcode[4] := 0 idcode[3] := 0 idcode[2] := 0 idcode[1] := 1 idcode[0] := 0
portst[4] := 1 portst[3] := 0 portst[2] := 1 portst[1] := 0 portst[0] := 0
status[4] := 1 status[3] := 1 status[2] := 1 status[1] := 1 status[0] := 1

;
; jedtopdb( ) -- Loads a jedec file into the pdb
;
; 1 = number of fuses
; 2 = default state of pdb ( 0 | 1 )
; 3 = pointer for return of protection state
; 4 = pointer for pdb handle
;
func jedtopdb( ) {

	ier := 0
	@$4 := pdbopen( $1, $2, &ier )		; open pdb
	if ( ier < 0 ) {
     	     err := pengn_err( ier )
	     return ier
	}

	ier := jedread( @$4, &$3 )		; read the JEDEC on into pdb
	if ( ier < 0 ) {
     	     err := pengn_err( ier )
	     return ier
	}
	return ier
}

;
; setprotect( ) -- Sets the security bits in the physical device database
;
; 1 = the pdb handle
; 2 = the protect data
;
func setprotect( ) {

	ier := 0
	i := seccol
        data[0] := $2
        message "Setting Device Security!\n"
	while ( i < collen ) { 		; traverse the security bit row
	    if ( debug ) {
	         message "  SP [%d][%d]=%d\n",secrow,i,$2
	    }
	    ier := ppdbrcdata( $1, secrow, i, &data )
	    if ( ier < 0 ) {
	         return ier
	    }
	    i := i + cfbcolumns		; inc to next cfb
	}
	return ier	
}

;
; getprotect( ) -- Gets the security bits in the physical device database
;
; 1 = the pdb handle
; 2 = pointer to the protect data
;
func getprotect( ) {

	ier := 0
	i := seccol
        data[0] := $2
	while ( i < collen ) {
	    if ( debug ) {
	         message "  SP [%d][%d]=%d\n",secrow,i,$2
	    }
	    ier := gpdbrcdata( $1, secrow, i, &data )
	    if ( ier < 0 ) {
	         return ier
	    }
	    if ( data[0] == 0 ) {
	         @$2 := 0		; device is not protected     
		 return ier
	    }
	    i := i + cfbcolumns
	}
	@$2 := 1			; device is protected
	return ier	
}

;
; check_status( ) -- querys the JTAG instruction status registers
;                 -- soft-boots device until valid or time-out on retries.
;
; 1 - the JTAG handle
;
func check_status( ) {

	ier := rsreg( handle, &status, instlen )
        if ( ier < 0 ) {
             return ier
        }
	message "Device Status Reg =  "
	rps_i := instlen - 1
	while ( rps_i >= 0 ) {
	      message "%d", status[rps_i]
	      rps_i := rps_i - 1
	}
	message "b "

	retry := 10
        while ( ((status[4] != 0) || 
                 (status[3] != 0) || 
                 (status[2] != 0)) && (retry > 0) ) {
             ;
             ; power-up did fail...perform soft-boot
             ;
             ier := jtag_xsi( handle, &portst, instlen )
	     if ( ier < 0 ) {
                  return ier
             }
	     ier := rsti( LPT )
             if ( ier < 0 ) {
                  return ier
             }

	     ;
	     ; reset status variable and check device's status register
             ;
             status[0] := 1 status[1] := 1 
             status[2] := 1 status[3] := 1 status[4] := 1
	     ier := rsreg( handle, &status, instlen )
             if ( ier < 0 ) {
                  return ier
             }
	     retry := retry - 1
	}

	;
	; if we timed-out then the device is bad
	;
	if ( retry == 0 ) {
             return READDEVFAILED
        }
	
	;
	; everything good....print the registers
	;
        if ( retry == 10 ) {
             message "OK\n\n"
        }
	else {
	     message "Initialization Required ... Reg = "
	     rps_i := instlen - 1
	     while ( rps_i >= 0 ) {
	           message "%d", status[rps_i]
	           rps_i := rps_i - 1
	     }
	     message "b OK\n\n"
        }

	return ier
}

;
; report_id( ) -- querys the JTAG device for the IDCODE
;
; 1 - the JTAG handle
;
func report_id( ) {

        ier := jtag_xsi( $1, &idcode, instlen )		; get into IDCODE mode
        if ( ier == 0 ) {
	     ier := jtag_rd( $1, &data, datapcktsize )	; read out IDCODE
	     if ( ier == 0 ) {
	          id := 0
	          ri_i := 0
	          while ( ri_i < 16 ) {		; make a number
	                id := (id | (data[ri_i] << ri_i))
	                ri_i := ri_i + 1
	          }

	          idy := 0
	          while ( ri_i < datapcktsize ) {	; make a number
	                idy := (idy | (data[ri_i] << ri_i-16))
	                ri_i := ri_i + 1
	          }
		  ; Because of a bug in the interpreter, treat
		  ; the 32 bit IDCODE as 2 16 bit halves.
	          message "Target Device ID  = %x%xh\n", idy, id
	     }
	}

	return ier
}

;
; gen_eprom_bitmap( ) -- traverses the pdb while creating
;                        an EPROM bitmap file
;
; 1 = the pdb handle
;
func gen_eprom_bitmap( ) {

	ier := 0
	message "Generating an EPX%d EPROM Bitmap file\n", devnum
	ier := bitmopen( 0 )
	if ( ier < 0 ) {
	     return ier
	}

        gbm_cnt := 0

        physchunk := (cfbcolumns * blksperpckt)
	halfdata  := (datapcktsize / 2)

        message "          %d : ", gbm_cnt
	for gbm_i := rowbeg to erowend {		; for each row in pdb
	    ier := gpdbrow( $1, gbm_i, 0, &physrow, collen )
	    if ( ier < 0 ) {
		 message "\n"
		 err := pengn_err( ier )
	         return GENBITMAPFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    gbm_k := 0
            while ( gbm_k < nblocks ) {		; for each pckt block
	        for gbm_j := 0 to 4 {		; for each pckt
		    gbm_x := 0
	            gbm_s := gbm_k * physchunk
	            gbm_e := gbm_s + physchunk
	            while ( gbm_s < gbm_e ) {		; for each column
		        data[gbm_x] := physrow[gbm_s+gbm_j] 
			gbm_x := gbm_x + 1
                        gbm_s := gbm_s + 5
		        if ( (gbm_x == (halfdata-1)) ||
                             (gbm_x == (datapcktsize-1)) ) {
			     data[gbm_x] := 0
			     gbm_x := gbm_x + 1
			}
                    }
		    ier := make_fxep_packet( gbm_i, rasize, gbm_j, casize,
                                             gbm_k, basize, &data, datapcktsize,
                                             &eprompckt )
		    if ( ier < 0 ) {
			 message "\n"
		         err := pengn_err( ier )
			 return GENBITMAPFAILED
		    }

		    ier := bitmwrite( &eprompckt, epromps )
		    if ( ier < 0 ) {
			 message "\n"
		         err := pengn_err( ier )
			 return GENBITMAPFAILED
		    }
	        }
	        gbm_k := gbm_k + 1
	    }
	    message "." ier:= fflush( )
	    gbm_cnt := gbm_cnt + 1
	    if ( gbm_cnt == 10 ) {
	         message "\n"
		 if ( gbm_i < 10 ) {
                      message "          %d : ", (gbm_i+1)
		 }
		 else {
                      message "          %d: ", (gbm_i+1)
		 }
		 gbm_cnt := 0
	    }
        }

	message "\n"
	message "          %d: Done!\n\n", (gbm_i-1)
        ier := bitmclose( )
        return ier
}

;
; gen_sram_bitmap( ) -- traverses the pdb while creating
;                       an SRAM bitmap file
;
; 1 = the pdb handle
;
func gen_sram_bitmap( ) {

	ier := 0
	message "Generating an EPX%d SRAM Bitmap file\n", devnum
	ier := bitmopen( 1 )
	if ( ier < 0 ) {
	     return ier
	}

        gbm_cnt := 0
        message "          %d : ", rowbeg
	for gbm_i := rowbeg to srowend {		; for each row in pdb
	    ier := gpdbrow( $1, gbm_i, 0, &physrow, collen )
	    if ( ier < 0 ) {
		 message "\n"
		 err := pengn_err( ier )
	         return GENBITMAPFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    ier := make_fxsr_packet( gbm_i, rasize,
                                     &physrow, collen, &srampckt )
	    if ( ier < 0 ) {
		 message "\n"
	         err := pengn_err( ier )
		 return GENBITMAPFAILED
	    }
	    ier := bitmwrite( &srampckt, (collen+rasize) )
	    if ( ier < 0 ) {
		 message "\n"
	         err := pengn_err( ier )
		 return GENBITMAPFAILED
	    }
	    message "." ier:= fflush( )
	    gbm_cnt := gbm_cnt + 1
	    if ( gbm_cnt == 10 ) {
	         message "\n"
                 message "          %d: ", (gbm_i+1)
	         gbm_cnt := 0
	    }
       }

       message "\n"
       message "          %d: Done\n\n", (gbm_i-1)
       ier := bitmclose( )
       return ier
}

;
; verifydev( ) -- reads the eprom or sram and verifys to pdb 
;
; 1 = eprom or sram ( 1= eprom 0 = sram )
; 2 = jtag handle
;             
;
func verifydev( ) {

	message "Verify of EPX%d's ", devnum
	if ( $1 == 1 ) {
           message "EPROM\n"
           ending := erowend
        }
	else {
           message "SRAM\n"
           ending := srowend
        }

        message "          %d : ", rowbeg

	idx := 0
	for i := rowbeg to ending {		; for each row in pdb
	    ier := gpdbrow( pdb, i, 0, &physrow, collen )
	    if ( ier < 0 ) {
		 message "\n"
                 err := pengn_err( ier )
	         return VERIFYFAILED
	    }

	    ier := make_fxra_packet( i, rasize, &raddr )
	    if ( ier < 0 ) {
		 message "\n"
                 err := pengn_err( ier )
	         return VERIFYFAILED
	    }

	    if ( $1 == 1 )			; send read instruction
	         ier := jtag_xid( $2, &fread, instlen, &raddr, rasize )
	    else
	         ier := jtag_xid( $2, &sread, instlen, &raddr, rasize )

	    if ( ier < 0 ) {
	         message "\n"
                 err := pengn_err( ier )
		 return VERIFYFAILED
	    }

	    ier := jtag_rd( $2, &tmprow, collen ) ; read the data
	    if ( ier < 0 ) {
	         message "\n"
                 err := pengn_err( ier )
		 return VERIFYFAILED
	    }

	    k := colend
	    for j := 0 to (collen - 1) {		; for each col of row
	        if ( physrow[j] != tmprow[k] ) {	; compare to pdb
		     ;
		     ; if there not equal...check to see if valid location
		     ;
                     if ( cpdbexrecs( pdb, i, j ) == FALSE ) {
	                  message "\n"
                          err := pengn_err( ier )
		          return VERIFYFAILED
                     }
	        }
                k := k - 1
	    }
	    
	    message "." ier:= fflush( )
	    idx := idx + 1
	    if ( idx == 10 ) {
	         message "\n"
                 message "          %d: ", (i+1)
	         idx := 0
	    }
	}

	message "\n"
	message "          %d: Done\n\n", (i-1)

	return ier
}

;
; progeprom( ) -- Loads a jedec file into the pdb 
;                  and programs the eprom of an EPX780
;
func progeprom( ) {

	protect := 0
	pdb := -1
	ier := jedtopdb( nfuses, defval, &protect, &pdb ) 
	if ( ier < 0 ) {
	     return ier
	}
	if ( protect == SEC_ON ) {
	     ier := setprotect( pdb, protect )
	     if ( ier < 0 ) {
                  err := pengn_err( ier )
	          return PROGEPROMFAILED
	     }
	}

	ier := jtag_string( LPT, LOC, &handle )
	if ( ier < 0 ) {
	     return ier
	}
	ier := vpp_on( LPT )
        delay( 50 )  ; delay 50 ms to give time to reach Vpp
	if ( vpp_sts( LPT ) == 0 ) {
             ier := vpp_off( LPT )
	     return VPPNOTENABLED
	}
	ier := jtag_open( handle )
	if ( ier < 0 ) {
	     return ier
	}

	ier := report_id( handle )
        if ( ier < 0 ) {
             err := pengn_err( ier )
	     ier := jtag_close( handle )
             return PROGEPROMFAILED
        }

	ier := check_status( handle )
        if ( ier < 0 ) {
             err := pengn_err( ier )
	     ier := jtag_close( handle )
             return PROGEPROMFAILED
        }

	message "Writing to EPX%d's EPROM\n", devnum
        message "          %d : ", rowbeg
	idx := 0

        physchunk := (cfbcolumns * blksperpckt)
	halfdata  := (datapcktsize / 2)

	for i := rowbeg to erowend {
	    ier := gpdbrow( pdb, i, 0, &physrow, collen )
	    if ( ier < 0 ) {
		 err := pengn_err( ier )
	         ier := jtag_close( handle )
	         return PROGEPROMFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    k := 0
            while ( k < nblocks ) {		; for each pckt block
	        for j := 0 to 4 {		; for each pckt
		    x := 0
	            s := k * physchunk
	            e := s + physchunk
	            while ( s < e ) {		; for each column
		        data[x] := physrow[s+j] 
			x := x + 1
                        s := s + 5
		        if ( (x == (halfdata-1)) ||
                             (x == (datapcktsize-1)) ) {
			     data[x] := 0
			     x := x + 1
			}
                    }
		    ier := make_fxep_packet( i, rasize, j, casize, k, basize,
                                             &data, datapcktsize, &eprompckt )
		    if ( ier < 0 ) {
			 message "\n"
			 err := pengn_err( ier )
			 ier := jtag_close( handle )
			 return PROGEPROMFAILED
		    }
	            ier := jtag_xid( handle, &ldvect, instlen, 
                                             &eprompckt, epromps )
		    if ( ier < 0 ) {
			 message "\n"
			 err := pengn_err( ier )
			 ier := jtag_close( handle )
			 return PROGEPROMFAILED
		    }
                    inc := 0
                    done := 0			; quick-pulse programming
                    while ( !done ) {

	                 if ((vpp_sts( LPT ) == 0)) {
	                      message "\n"
			      ier := vpp_off( LPT )
			      ier := jtag_close( handle )
	                      return DVCNOPOWER
	                 }

		         ier := jtag_xsi( handle, &fpgm, instlen )
		         if ( ier < 0 ) {
			      message "\n"
			      err := pengn_err( ier )
			      ier := jtag_close( handle )
			      return PROGEPROMFAILED
		         }
		         ier := jtag_rd( handle, &data, 1 )
		         if ( ier < 0 ) {
			      message "\n"
			      err := pengn_err( ier )
			      ier := jtag_close( handle )
			      return PROGEPROMFAILED
		         }
	                 if ( data[0] == 1 ) {	; passed!
			      done := 1
			 }
			 else {
			      inc := inc + 1
                              if ( inc == 25 ) {
				   message "\n"
			           ier := vpp_off( LPT )
			           ier := jtag_close( handle )
				   return PROGFAILROW
			      }
			 }
		    }
	        }
	        k := k + 1
	    }
	    message "." ier:= fflush( )
	    idx := idx + 1
	    if ( idx == 10 ) {
	         message "\n"
		 if ( i < 10 ) {
                      message "          %d : ", (i+1)
		 }
		 else {
                      message "          %d: ", (i+1)
		 }
		 idx := 0
	    }
        }

	message "\n"
	message "          %d: Done!\n\n", (i-1)

	ier := vpp_off( LPT )

        ier := jtag_xsi( handle, &portst, instlen )	; power-on test
	if ( ier < 0 ) {
	     err := pengn_err( ier )
	     ier := jtag_close( handle )
	     return PROGFAILROW
	}
	ier := rsti( LPT )				; reset the device

	if ( $2 == 1 ) {
	     ier := verifydev( 1, handle )
	     if ( ier < 0 ) {
	          err := pengn_err( ier )
	     }
	}

	ier := jtag_close( handle )

	if ( $1 == 1 ) {			; create the bitmap file
	     ier := gen_eprom_bitmap( pdb )
	}
        else if ( $1 == 0 ) {
	     ier := gen_sram_bitmap( pdb )
        }

        ier := pdbclose( pdb )
        return ier
}

;
; progsram( ) -- Loads a jedec file into the pdb 
;                and programs the sram of an EPX780
;
func progsram( ) {

	protect := 0
	pdb := -1
	ier := jedtopdb( nfuses, defval, &protect, &pdb ) 
	if ( ier < 0 ) {
	     return ier
	}
	if ( protect == SEC_ON ) {
	     ier := setprotect( pdb, protect )
             if ( ier < 0 ) {
	          err := pengn_err( ier )
                  return PROGSRAMFAILED
	     }
	}

	ier := jtag_string( LPT, LOC, &handle )
	if ( ier < 0 ) {
	     return ier
	}
	ier := vpp_off( LPT )
	ier := jtag_open( handle )
	if ( ier < 0 ) {
	     return ier
	}

	ier := report_id( handle )
        if ( ier < 0 ) {
             err := pengn_err( ier )
             return PROGSRAMFAILED
        }

	ier := check_status( handle )
        if ( ier < 0 ) {
             err := pengn_err( ier )
	     ier := jtag_close( handle )
             return PROGSRAMFAILED
        }


	message "Writing to EPX%d's SRAM\n", devnum
        message "          %d : ", rowbeg
        idx := 0
	first := TRUE
	for i := rowbeg to srowend {
	    ier := gpdbrow( pdb, i, 0, &physrow, collen )
	    if ( ier < 0 ) {
		 err := pengn_err( ier )
	         return PROGSRAMFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    ier := make_fxsr_packet( i, rasize, &physrow, collen, &srampckt )
	    if ( ier < 0 ) {
		 err := pengn_err( ier )
	         return PROGSRAMFAILED
	    }

	    if ( first ) {
	         ier := jtag_xid(handle, &swrite, instlen, 
                                         &srampckt, collen+rasize)
	         if ( ier < 0 ) {
	              return ier
                 }
		 first := FALSE
	    }
	    else {
	         ier := jtag_xd(handle, &srampckt, collen+rasize)
	         if ( ier < 0 ) {
	              return ier
                 }
	    }

	    message "." ier:= fflush( )
	    idx := idx + 1
	    if ( idx == 10 ) {
	         message "\n"
                 message "          %d: ", (i+1)
	         idx := 0
	    }
        }

	message "\n"
	message "          %d: Done\n\n", (i-1)

	if ( $2 == 1 ) {
	     ier := verifydev( 0, handle )
	     if ( ier < 0 ) {
	          err := pengn_err( ier )
	     }
	}

	ier := jtag_close( handle )

	if ( $1 == 0 ) {			; create the bitmap file
	     ier := gen_sram_bitmap( pdb )
	}
	else if ( $1 == 1 ) {
	     ier := gen_eprom_bitmap( pdb )
        }

        ier := pdbclose( pdb )
        return ier
}

;
; readdev( ) - opens up the pdb and reads either eprom or sram in
;
; 1 = (1 == eprom; 0 == sram)
; 2 = generate bitmap?
;
func readdev( ) {

	pdb := pdbopen( nfuses, defval, &ier )
	if ( ier < 0 ) {
	     err := pengn_err( ier )
	     return READDEVFAILED
	}

	ier := jtag_string( LPT, LOC, &handle )
	if ( ier < 0 ) {
	     return ier
	}
	ier := vpp_off( LPT )
	ier := jtag_open( handle )
	if ( ier < 0 ) {
	     return ier
	}

	ier := report_id( handle )
        if ( ier < 0 ) {
             err := pengn_err( ier )
             return READDEVFAILED
        }

	ier := check_status( handle )
        if ( ier < 0 ) {
             err := pengn_err( ier )
	     ier := jtag_close( handle )
             return READDEVFAILED
        }

	message "Reading from EPX%d's ", devnum
	if ( $1 == 1 ) {
	     message "EPROM\n"
             ending := erowend
	}
	else {
	     message "SRAM\n"
             ending := srowend
	}

        message "          %d : ", rowbeg
        idx := 0
	for i := rowbeg to ending {
	    ;
	    ; create download packet
	    ;
	    ier := make_fxra_packet( i, rasize, &raddr )
	    if ( ier < 0 ) {
	         message "\n"
	         err := pengn_err( ier )
	         return READDEVFAILED
	    }

	    if ( $1 == 1 )
	         ier := jtag_xid( handle, &fread, instlen, &raddr, rasize )
	    else
	         ier := jtag_xid( handle, &sread, instlen, &raddr, rasize )

	    if ( ier < 0 ) {
	         message "\n"
	         err := pengn_err( ier )
	         return READDEVFAILED
	    }

	    ier := jtag_rd( handle, &tmprow, collen )
	    if ( ier < 0 ) {
	         message "\n"
	         err := pengn_err( ier )
	         return READDEVFAILED
	    }

	    ;
	    ; reorder by swapping
            ;
	    swp_i := colbeg
	    swp_j := colend
	    while ( swp_i < collen ) {
                 physrow[swp_i] := tmprow[swp_j]
                 swp_i := swp_i + 1
                 swp_j := swp_j - 1
            }
	    ier := ppdbrow( pdb, i, 0, &physrow, collen )
	    if ( ier < 0 ) {
	         message "\n"
	         err := pengn_err( ier )
	         return READDEVFAILED
	    }
	    
	    message "." ier:= fflush( )
	    idx := idx + 1
	    if ( idx == 10 ) {
	         message "\n"
                 message "          %d: ", (i+1)
	         idx := 0
	    }
        }

	message "\n"
	message "          %d: Done\n\n", (i-1)

	ier := jtag_close( handle )

	protect := 0
	ier := getprotect( pdb, &protect )
        if ( ier < 0 ) {
	     err := pengn_err( ier )
	     pdbclose( pdb )
             return READDEVFAILED
	}

	ier := jedwrite( pdb, protect )
	if ( ier < 0 ) {
	     err := pengn_err( ier )
	     pdbclose( pdb )
	     return READDEVFAILED
	}

	if ( $2 == 0 ) {			; create the bitmap file
	     ier := gen_sram_bitmap( pdb )
	     if ( ier < 0 ) {
	          pdbclose( pdb )
	          return ier
	     }
	}
	else if ( $2 == 1 ) {
	     ier := gen_eprom_bitmap( pdb )
	     if ( ier < 0 ) {
	          pdbclose( pdb )
	          return ier
	     }
        }

        ier := pdbclose( pdb )
        return ier
}

;
; flow control based on user requested actions
;
;
ier := 0
if ( eprom_or_sram == 1 ) {			; is eprom
    ier := cable_sts( LPT );
    if ( ier != TRUE ) {
         err := pengn_err( CABLEBAD );
         exit
    }
    if ( prog_or_read ) {			; is program
	 ier := progeprom( create_bitmap, verify ) 
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
    else {					; is read
	 ier := readdev( eprom_or_sram, create_bitmap )
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
}
else if ( eprom_or_sram == 0 ) {		; is sram
    ier := cable_sts( LPT );
    if ( ier != TRUE ) {
         err := pengn_err( CABLEBAD );
         exit
    }
    if ( prog_or_read ) {			; is program
	 ier := progsram( create_bitmap, verify ) 
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
    else {					; is read
	 ier := readdev( eprom_or_sram, create_bitmap )
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
}
else {						; just create bitmap
    pdb := -1
    protect := -1
    if ( create_bitmap == 1 ) {			; is eprom
	 ier := jedtopdb( nfuses, defval, &protect, &pdb ) 
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
              exit
	 }
	 if ( protect == SEC_ON ) {
	      ier := setprotect( pdb, protect )
	      if ( ier < 0 ) {
	           err := pengn_err( ier )
	           exit
	      }
	 }
	 ier := gen_eprom_bitmap( pdb ) 
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
              exit
	 }
         ier := pdbclose( pdb )
    }
    else if ( create_bitmap == 0 ) {		; is sram
	 ier := jedtopdb( nfuses, defval, &protect, &pdb ) 
	 if ( ier < 0 ) {
              exit
	 }
	 if ( protect == SEC_ON ) {
	      ier := setprotect( pdb, protect )
	      if ( ier < 0 ) {
	           err := pengn_err( ier )
	           exit
	      }
	 }
	 ier := gen_sram_bitmap( pdb ) 
	 if ( ier < 0 ) {
	      err := pengn_err( ier )
              exit
	 }
         ier := pdbclose( pdb )
    }
}

exit			 			; return to the caller
