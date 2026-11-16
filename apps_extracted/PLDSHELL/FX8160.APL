
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

;
; fx8160.apl
; -----------
;
; This file supports both halves of the 8160, using .0 and .1
; extensions on the -part argument.  If there is no extension,
; the operation is on both halves.
;

devnum := 8160
nfuses := 64208			; number of JEDEC fuses for EPX8160
defval := 0			; default state of pdb
srowbeg := 1                    ; begining row SRAM
erowbeg := 0                    ; begining row FLASH
rowend := 53                    ; ending row
f_rowend := 55                  ; ending row for FLASH
colbeg := -1                    ; beginning column
colend := -1                    ; ending column

collen := 616 			; column length
seccol := 33			; start security bit column
cmpcol := 33			; compare term column
secrow := 50			; start security bit row
cfbcolumns := 77		; number of columns per cfb
datapcktsize := 32		; size of the data part of a packet to eprom
blksperpckt := 2		; blocks per packet
cfbs := 8 			; number of cfbs
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
array ones_data[datapcktsize]	; the data for a download packet for fpgmall1
array eprompckt[epromps]	; an entire packet for download to eprom
array srampckt[collen+rasize]	; an entire packet for download to sram

array ldvect[instlen]		; load vector instruction
array fread[instlen]		; eprom read instruction
array swrite[instlen]		; sram write instruction
array sread[instlen]		; sram read instruction
array fpgmal[instlen]		; flash program all 1's instruction
array ferase[instlen]		; flash erase instruction
array fpgm[instlen]		; eprom program instruction
array idcode[instlen]		; idcode instruction
array portst[instlen]		; portst instruction
array status[instlen]		; array for status register

;
; JTAG semi-private instructions for the EPX device
;
  fpgm[4] := 1   fpgm[3] := 0   fpgm[2] := 1   fpgm[1] := 0   fpgm[0] := 1
fpgmal[4] := 1 fpgmal[3] := 0 fpgmal[2] := 0 fpgmal[1] := 1 fpgmal[0] := 0
ferase[4] := 1 ferase[3] := 0 ferase[2] := 0 ferase[1] := 0 ferase[0] := 1
 fread[4] := 0  fread[3] := 0  fread[2] := 1  fread[1] := 1  fread[0] := 0
 sread[4] := 1  sread[3] := 0  sread[2] := 0  sread[1] := 0  sread[0] := 0
swrite[4] := 0 swrite[3] := 1 swrite[2] := 1 swrite[1] := 1 swrite[0] := 1
ldvect[4] := 0 ldvect[3] := 0 ldvect[2] := 1 ldvect[1] := 0 ldvect[0] := 1
idcode[4] := 0 idcode[3] := 0 idcode[2] := 0 idcode[1] := 1 idcode[0] := 0
portst[4] := 1 portst[3] := 0 portst[2] := 1 portst[1] := 0 portst[0] := 0
status[4] := 1 status[3] := 1 status[2] := 1 status[1] := 1 status[0] := 1

for ( i := datapcktsize-1 downto 0 )
{ ; initialize ones_data
  ones_data[i] := 1
}



;
; jedtopdb( ) -- Loads a jedec file into the pdb
;
; 1 = number of fuses
; 2 = default state of pdb ( 0 | 1 )
; 3 = pointer for return of protection state
; 4 = pointer for pdb handle
;


func jedtopdb( ) {

;        if (colbeg == -1) {
;	     return ( -1 )
;        }

	ier := 0
	@$4 := pdbopen( $1, $2, &ier )	; open pdb
	if ( ier < 0 ) {
             message "pengn_err 1\n"
     	     ier := pengn_err( ier )
	     return ier
	}

	ier := jedread( @$4, &$3 )      ; read the JEDEC on into pdb
	if ( ier < 0 ) {
             message "pengn_err 2\n"
     	     ier := pengn_err( ier )
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
	while ( i < (collen * 2) ) { ; traverse the security bit row
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
	while ( i < (collen * 2) ) {
	    ier := gpdbrcdata( $1, secrow, i, &data[0] )
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

; This function sets ues_bug to a 0 (false) if no row 0,
; column 67 or 68 bits are set in any cfb in Flash memory.  Otherwise
; it sets ues_bug to a 1 (true).  If any of these bits are set in
; row 0 (the UES code), a false power on status error will occur,
; due to a bug in the silicon.

func chk_ues_bug ( )
{
	    ;
	    ; create download packet for row 0
	    ;
	    ier := make_fxra_packet( 0, rasize, &raddr )
	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 100\n"
	         ier := pengn_err( ier )
	         return READDEVFAILED
	    }

            ier := jtag_xid( handle, &fread, instlen, &raddr, rasize )

	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 101\n"
	         ier := pengn_err( ier )
	         return READDEVFAILED
	    }

	    ier := jtag_rd( handle, &tmprow, collen )
	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 102\n"
	         ier := pengn_err( ier )
	         return READDEVFAILED
	    }

	    ;
	    ; reorder by swapping
            ;
	    swp_i := 0
	    swp_j := collen - 1
	    while ( swp_i < collen ) {
                 physrow[swp_i] := tmprow[swp_j]
                 swp_i := swp_i + 1
                 swp_j := swp_j - 1
            }
            ues_bug := 0
            for cfb_cntr := 0 to (cfbs - 1)
            {
              if( physrow[(cfb_cntr * cfbcolumns) + 67] == 1)
              {
;                message "row 0 column 67 set in cfb %d\n",cfb_cntr
                ues_bug := 1
              }
              if( physrow[(cfb_cntr * cfbcolumns) + 68] == 1)
              {
;                message "row 0 column 68 set in cfb %d\n",cfb_cntr
                ues_bug := 1
              }
            }
        return ier

} ; end func chk_ues_bug

;
; check_status( ) -- querys the JTAG instruction status registers
;                 -- soft-boots device until valid or time-out on retries.
;
; 1 - the JTAG handle
;
func check_status( ) {

        ier := chk_ues_bug( )
        if ( ier < 0 ) {
             return ier
        }

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
        while (!ues_bug && ( ((status[4] != 0) ||
                 (status[3] != 0) ||
                 (status[2] != 0)) && (retry > 0) ) ) {
             ;
             ; power-up did fail...perform soft-boot
             ;
             ier := jtag_xsi( handle, &portst, instlen )
	     if ( ier < 0 ) {
                  return ier
             }

	     ier := delay( 30 )  ; delay 30 milliseconds

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
             message " flag 000\n"
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

        ier := jtag_xsi( $1, &idcode, instlen )	; get into IDCODE mode
        if ( ier == 0 ) {
	     ier := jtag_rd( $1, &data, datapcktsize )	; read out IDCODE
	     if ( ier == 0 ) {
		  ; Because of a bug in the interpreter, treat
		  ; the 32 bit IDCODE as two 16 bit halves.
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
                  id_all := (idy * 65536) + id ; merge 16 bit values
	          message "Target Device ID  = %xh\n", id_all
;                   message "id_all = %x hex, %d decimal\n", id_all, id_all
                  if( (sec_sel != 0) && (sec_sel != 1) )
                  {
                    message "\nProgram Error - sec_sel not initialized.\n"
                  }

                  if( ( (sec_sel == 0) && (id_all != 6438931) ) ||
                      ( (sec_sel == 1) && (id_all != 6434835) )  )
                  {
                    message "\nWARNING - Target Device ID does not match EPX8160 Section %d!\n\n", sec_sel
                  }
	     }
	}

	return ier
}

;
; gen_eprom_bitmap( ) -- traverses the pdb while creating
;                        a FLASH bitmap file
;
; 1 = the pdb handle
;
func gen_eprom_bitmap( )
{
  ier := 0
  ier := bitmopen( sec_sel + 2 )
  if ( ier < 0 )
  {
    return ier
  }

  gbm_cnt := 0

  physchunk := (cfbcolumns * blksperpckt)
  halfdata  := (datapcktsize / 2)

  message "           %d: ", gbm_cnt
  for gbm_i := erowbeg to rowend
  {  ; for each row in pdb
    ier := gpdbrow( $1, gbm_i, colbeg, &physrow, collen )
    if ( ier < 0 )
    {
      message "\n"
      message "pengn_err 3\n"
      ier := pengn_err( ier )
      return GENBITMAPFAILED
    }
    ;
    ; create download packet
    ;
    gbm_k := 0
    while ( gbm_k < nblocks )
    { ; for each pckt block
      for gbm_j := 0 to 4
      { ; for each pckt
        gbm_x := 0
        gbm_s := gbm_k * physchunk
        gbm_e := gbm_s + physchunk
        while ( gbm_x < datapcktsize )
        { ; for each column
;          message "blk = %d\tpckt = %d\tcol = %d\tcolend+1 = %d\tgbm_x = %d",
;             gbm_k, gbm_j, gbm_s, gbm_e, gbm_x
          if (( (gbm_x == (halfdata-1)) || (gbm_x == (datapcktsize-1)))
                  && (gbm_j > 1) )
          { ; unused bit in data packet, force it to zero
;           message "\tnot used\n"
	    data[gbm_x] := 0
	  }
          else
          { ; used bit in data packet
;            message "\tused\n"
            data[gbm_x] := physrow[gbm_s+gbm_j]
          }
	  gbm_x := gbm_x + 1
          if(gbm_x == (datapcktsize/2) )
          { ; handle discontinuity between cfb's in block
            gbm_s := gbm_s + 2
          }
          else
          {
            gbm_s := gbm_s + 5
          }
        } ; end for each column
        ier := make_fxep_packet( gbm_i, rasize, gbm_j, casize,
                                 gbm_k, basize, &data, datapcktsize,
                                 &eprompckt )
        if ( ier < 0 )
        {
	   message "\n"
           message "pengn_err 4\n"
           ier := pengn_err( ier )
	   return GENBITMAPFAILED
        }

        ier := bitmwrite( &eprompckt, epromps )
        if ( ier < 0 )
        {
		 message "\n"
                 message "pengn_err 5\n"
                 ier := pengn_err( ier )
		 return GENBITMAPFAILED
        }
      } ; end for each pckt
      gbm_k := gbm_k + 1
    } ; end for each pckt block

    message "." ier:= fflush( )
    gbm_cnt := gbm_cnt + 1
    if ( gbm_cnt == 10 )
    {
      message "\n"
      if ( gbm_i < 10 )
      {
        message "          %d: ", (gbm_i+1)
      }
      else
      {
        message "          %d: ", (gbm_i+1)
      }
		 gbm_cnt := 0
    }
  }

  message "\n"
  message "          %d: Done!\n\n", (gbm_i-1)
  ier := bitmclose( )
  return ier
} ; end func gen_eprom_bitmap

;
; all_eprom_bitmap( ) -- generates all selected eprom bitmaps by
;                       calling gen_eprom_bitmap as required
;
; 1 = the pdb handle
;
func all_eprom_bitmap( ) {

       ier := 0
       ; default to section 0
       sec_sel := 0
       colbeg := 0                 ; beginning column
       colend := 615               ; ending column
       if (SEC == 1 ) {
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       }
       message "Generating an EPX%d Section %d FLASH Bitmap file\n",
                  devnum, sec_sel
       ier := gen_eprom_bitmap( $1 )
       if ( ier < 0 ) {
         message "pengn_err 6\n"
         ier := pengn_err( ier )
         return ier
       }
       if (SEC == -1 ) { ; do section 1, too
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       message "Generating an EPX%d Section %d FLASH Bitmap file\n",
                  devnum, sec_sel
         ier := gen_eprom_bitmap( $1 )
         if ( ier < 0 ) {
           message "pengn_err 7\n"
           ier := pengn_err( ier )
           return ier
         }
       }

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
	ier := bitmopen( sec_sel + 4 )
	if ( ier < 0 ) {
	     return ier
	}

        gbm_cnt := 0
        message "           %d: ", srowbeg
	for gbm_i := srowbeg to rowend {		; for each row in pdb
	    ier := gpdbrow( $1, gbm_i, colbeg, &physrow, collen )
	    if ( ier < 0 ) {
		 message "\n"
                 message "pengn_err 8\n"
		 ier := pengn_err( ier )
	         return GENBITMAPFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    ier := make_fxsr_packet( gbm_i, rasize,
                                     &physrow, collen, &srampckt )
	    if ( ier < 0 ) {
		 message "\n"
                 message "pengn_err 9\n"
	         ier := pengn_err( ier )
		 return GENBITMAPFAILED
	    }
	    ier := bitmwrite( &srampckt, (collen+rasize) )
	    if ( ier < 0 ) {
		 message "\n"
                 message "pengn_err 10\n"
	         ier := pengn_err( ier )
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
; all_sram_bitmap( ) -- generates all selected sram bitmaps by
;                       calling gen_sram_bitmap as required
;
; 1 = the pdb handle
;
func all_sram_bitmap( ) {

       ier := 0
       ; default to section 0
       sec_sel := 0
       colbeg := 0                 ; beginning column
       colend := 615               ; ending column
       if (SEC == 1 ) {
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       }
       message "Generating an EPX%d Section %d SRAM Bitmap file\n",
                  devnum, sec_sel
       ier := gen_sram_bitmap( $1 )
       if ( ier < 0 ) {
         message "pengn_err 11\n"
         ier := pengn_err( ier )
         return ier
       }
       if ( SEC == -1 ) { ; do section 1, too
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       message "Generating an EPX%d Section %d SRAM Bitmap file\n",
                  devnum, sec_sel
         ier := gen_sram_bitmap( $1 )
         if ( ier < 0 ) {
           message "pengn_err 12\n"
           ier := pengn_err( ier )
           return ier
         }
       }

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

	message "Verify of EPX%d Section %d ", devnum, sec_sel
	if ( $1 == 1 ) {
           message "FLASH\n"
           starting := erowbeg
        }
	else {
           message "SRAM\n"
           starting := srowbeg
        }

        message "          %d : ", starting

	idx := 0
	for i := starting to rowend {		; for each row in pdb
	    ier := gpdbrow( pdb, i, colbeg, &physrow, collen )
	    if ( ier < 0 ) {
		 message "\n"
                 message "pengn_err 13\n"
                 ier := pengn_err( ier )
	         return VERIFYFAILED
	    }

	    ier := make_fxra_packet( i, rasize, &raddr )
	    if ( ier < 0 ) {
		 message "\n"
                 message "pengn_err 14\n"
                 ier := pengn_err( ier )
	         return VERIFYFAILED
	    }

	    if ( $1 == 1 )			; send read instruction
	         ier := jtag_xid( $2, &fread, instlen, &raddr, rasize )
	    else
	         ier := jtag_xid( $2, &sread, instlen, &raddr, rasize )

	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 15\n"
                 ier := pengn_err( ier )
		 return VERIFYFAILED
	    }

	    ier := jtag_rd( $2, &tmprow, collen ) ; read the data
	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 16\n"
                 ier := pengn_err( ier )
		 return VERIFYFAILED
	    }

	    k := collen - 1     ; was k := colend
	    for j := 0 to (collen - 1) {		; for each col of row
	        if ( physrow[j] != tmprow[k] ) {	; compare to pdb
		     ;
		     ; if there not equal...check to see if valid location
		     ;
                     if ( cpdbexrecs( pdb, i, j ) == FALSE ) {
	                  message "\n"
                          message "pengn_err 17\n"
                          ier := pengn_err( ier )
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
} ; end function verifydev

;
; progeprom( ) -- programs the FLASH memory of an EPX8160
;
;

func progeprom( ) {

	message "Programming EPX%d's FLASH\n", devnum

        message "          %d : ", erowbeg
	idx := 0

        physchunk := (cfbcolumns * blksperpckt)
	halfdata  := (datapcktsize / 2)

	for i := erowbeg to rowend {
	    ier := gpdbrow( pdb, i, colbeg, &physrow, collen )
	    if ( ier < 0 ) {
                 message "pengn_err 18\n"
		 ier := pengn_err( ier )
	         ier := jtag_close( handle )
	         return PROGEPROMFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    k := 0
            while ( k < nblocks )
            { ; for each pckt block
              for j := 0 to 4
              { ; for each pckt
                x := 0
                s := k * physchunk
                e := s + physchunk
                while ( x < datapcktsize )
                { ; for each column
;                  message "blk = %d\tpckt = %d\tcol = %d\tcolend+1 = %d\tx = %d",
;                     k, j, s, e, x
                  if (( (x == (halfdata-1)) || (x == (datapcktsize-1)))
                          && (j > 1) )
                  { ; unused bit in data packet, force it to zero
;                   message "\tnot used\n"
	            data[x] := 0
	          }
                  else
                  { ; used bit in data packet
;                    message "\tused\n"
                    data[x] := physrow[s+j]
                  }
	          x := x + 1
                  if(x == (datapcktsize/2) )
                  { ; handle discontinuity between cfb's in block
                    s := s + 2
                  }
                  else
                  {
                    s := s + 5
                  }
                } ; end for each column

		    ier := make_fxep_packet( i, rasize, j, casize, k, basize,
                                             &data, datapcktsize, &eprompckt )

		    if ( ier < 0 ) {
			 message "\n"
                         message "pengn_err 19\n"
			 ier := pengn_err( ier )
			 ier := jtag_close( handle )
			 return PROGEPROMFAILED
		    }
	            ier := jtag_xid( handle, &ldvect, instlen,
                                             &eprompckt, epromps )
		    if ( ier < 0 ) {
			 message "\n"
                         message "pengn_err 20\n"
			 ier := pengn_err( ier )
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
                              message " flag 015\n"
	                      return DVCNOPOWER
	                 }

		         ier := jtag_xsi( handle, &fpgm, instlen )
		         if ( ier < 0 ) {
			      message "\n"
                              message "pengn_err 21\n"
			      ier := pengn_err( ier )
			      ier := jtag_close( handle )
			      return PROGEPROMFAILED
		         }
		         ier := jtag_rd( handle, &data, 1 )
		         if ( ier < 0 ) {
			      message "\n"
                              message "pengn_err 22\n"
			      ier := pengn_err( ier )
			      ier := jtag_close( handle )
			      return PROGEPROMFAILED
		         }
	                 if ( data[0] == 1 ) {	; passed!
			      done := 1
			 }
			 else { ; failed!
			      inc := inc + 1
                              if ( inc == 25 ) {
				   message "\n"
			           ier := vpp_off( LPT )
			           ier := jtag_close( handle )
                                   message " flag 018\n"
				   return PROGFAILROW
			      }
			 } ; end failed!
		    } ; end quick-pulse programming
	        } ; end for each pckt
	        k := k + 1
	    } ; end for each pckt block
	    message "." ier:= fflush( )
	    idx := idx + 1
	    if ( idx == 10 ) {
	         message "\n"
                 message "          %d: ", (i+1)
		 idx := 0
	    }
        } ; end row loop

	message "\n"
	message "          %d: Done!\n\n", (i-1)

        return ier
}; end function progeprom

;
; erase( ) -- erases the FLASH memory of an EPX8160 with
;             FERASE command
;
;

func erase( ) {
	message "Erasing EPX%d's FLASH\n\n", devnum
        inc := 0
        done := 0			; quick-pulse programming
        while ( !done ) {

	     if ((vpp_sts( LPT ) == 0)) {
	          message "\n"
	      ier := vpp_off( LPT )
	      ier := jtag_close( handle )
                  message " flag 019\n"
	          return DVCNOPOWER
	     }

	     ier := jtag_xsi( handle, &ferase, instlen )
	     if ( ier < 0 ) {
	      message "\n"
              message "pengn_err 23\n"
	      ier := pengn_err( ier )
	      ier := jtag_close( handle )
	      return PROGEPROMFAILED
	     }

	     ier := delay( 30 )  ; delay 30 milliseconds
	     if ( ier < 0 ) {
	      message "\n"
              message "pengn_err 24\n"
	      ier := pengn_err( ier )
	      ier := jtag_close( handle )
	      return PROGEPROMFAILED
	     }

	     ier := jtag_rd( handle, &data, 1 )
	     if ( ier < 0 ) {
	      message "\n"
              message "pengn_err 25\n"
	      ier := pengn_err( ier )
	      ier := jtag_close( handle )
	      return PROGEPROMFAILED
	     }
	     if ( data[0] == 1 ) {	; passed!
	      done := 1
	 }
	 else { ; failed!
	      inc := inc + 1
                  if ( inc == 200 ) {
		   message "\n"
	           ier := vpp_off( LPT )
	           ier := jtag_close( handle )
                   message " flag 023\n"
		   return PROGFAILROW
	      }
	 } ; end failed!
	} ; end quick-pulse programming
        return ier
}


;
; prog_all_ones( ) -- programs all 1's into the FLASH memory of
;                     an EPX8160 using the FPGMALL1 command.
;

func prog_all_ones( ) {

	message "Writing all 1's to EPX%d's FLASH\n", devnum

	idx := 0
        i := f_rowend
        message "          %d: ", i
	while( i >= 0) { ; must go through rows backwards
	    k := 0
            while ( k < nblocks )
            { ; for each pckt block
              for j := 0 to 4
              { ; for each pckt

		    ier := make_fxep_packet( i, rasize, j, casize, k, basize,
                                             &ones_data, datapcktsize, &eprompckt )

		    if ( ier < 0 ) {
			 message "\n"
                         message "pengn_err 26\n"
			 ier := pengn_err( ier )
			 ier := jtag_close( handle )
			 return PROGEPROMFAILED
		    }
	            ier := jtag_xid( handle, &ldvect, instlen,
                                             &eprompckt, epromps )
		    if ( ier < 0 ) {
			 message "\n"
                         message "pengn_err 27\n"
			 ier := pengn_err( ier )
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
                              message " flag 026\n"
	                      return DVCNOPOWER
	                 }

		         ier := jtag_xsi( handle, &fpgmal, instlen )
		         if ( ier < 0 ) {
			      message "\n"
                              message "pengn_err 28\n"
			      ier := pengn_err( ier )
			      ier := jtag_close( handle )
			      return PROGEPROMFAILED
		         }
		         ier := jtag_rd( handle, &data, 1 )
		         if ( ier < 0 ) {
			      message "\n"
                              message "pengn_err 29\n"
			      ier := pengn_err( ier )
			      ier := jtag_close( handle )
			      return PROGEPROMFAILED
		         }
	                 if ( data[0] == 1 ) {	; passed!
			      done := 1
			 }
			 else { ; failed!
			      inc := inc + 1
                              if ( inc == 25 ) {
				   message "\n"
			           ier := vpp_off( LPT )
			           ier := jtag_close( handle )
                                   message " flag 029\n"
				   return PROGFAILROW
			      }
			 } ; end failed!
		    } ; end quick-pulse programming
	        } ; end for each pckt
	        k := k + 1
	    } ; end for each pckt block
	    message "." ier:= fflush( )
	    idx := idx + 1
	    if ( idx == 10 ) {
	         message "\n"
		 if ( i < 11 ) {
                      message "          %d : ", (i-1)
		 }
		 else {
                      message "          %d: ", (i-1)
		 }
		 idx := 0
	    }
            i := i - 1 ; going through rows backwards
        } ; end row loop

	message "\n"
	message "          %d : Done!\n\n", (i+1)

        return ier
}; end function prog_all_ones

; ones_erase_prog ( ) -- this function writes all ones, erases,
;                        and programs the FLASH for the
;                        selected section.
;
; 1 = verify
;

func ones_erase_prog ( ) {

	ier := jtag_string( LPT, location , &handle )
	if ( ier < 0 ) {
	     return ier
	}
	ier := vpp_on( LPT )
        delay( 50 )  ; delay 50 ms to give time to reach Vpp
	if ( vpp_sts( LPT ) == 0 ) {
             ier := vpp_off( LPT )
             message " flag 030\n"
	     return VPPNOTENABLED
	}
	ier := jtag_open( handle )
	if ( ier < 0 ) {
	     return ier
	}

	ier := report_id( handle )
        if ( ier < 0 ) {
             message "pengn_err 30\n"
             ier := pengn_err( ier )
	     ier := jtag_close( handle )
             return PROGEPROMFAILED
        }

	ier := check_status( handle )
        if ( ier < 0 ) {
             message "pengn_err 31\n"
             ier := pengn_err( ier )
	     ier := jtag_close( handle )
             return PROGEPROMFAILED
        }

        ier := prog_all_ones ( )
        if ( ier < 0 ) {
          message "pengn_err 32\n"
          ier := pengn_err( ier )
          return ier
        }

        ier := erase ( )
        if ( ier < 0 ) {
          message "pengn_err 33\n"
          ier := pengn_err( ier )
          return ier
        }

        ier := progeprom ( )
        if ( ier < 0 ) {
          message "pengn_err 34\n"
          ier := pengn_err( ier )
          return ier
        }

	ier := vpp_off( LPT )

        ier := jtag_xsi( handle, &portst, instlen )	; power-on reset
	if ( ier < 0 ) {
             message "pengn_err 35\n"
	     ier := pengn_err( ier )
	     ier := jtag_close( handle )
	     return PROGFAILROW
	}
	ier := rsti( LPT )				; reset the device

	if ( $1 == 1 ) {
	     ier := verifydev( 1, handle )
	     if ( ier < 0 ) {
                  message "pengn_err 36\n"
	          ier := pengn_err( ier )
	     }
	}

	ier := jtag_close( handle )

        return ier
} ; end function ones_erase_prog


; all_progeprom( ) -- Programs FLASH for all selected sections as
;                     follows:
;
;                     1.  Loads a jedec file into the pdb
;                     2.  Writes all 1's to FLASH, erases FLASH,
;                         and programs FLASH by calling function
;                         ones_erase_prog.
;
; 1 = create_bitmap
; 2 = verify
;
func all_progeprom( ) {

	protect := 0
	pdb := -1
	ier := jedtopdb( nfuses, defval, &protect, &pdb )
	if ( ier < 0 ) {
	     return ier
	}
	if ( protect == SEC_ON ) {
	     ier := setprotect( pdb, protect )
	     if ( ier < 0 ) {
                  message "pengn_err 37\n"
                  ier := pengn_err( ier )
	          return PROGEPROMFAILED
	     }
	}

       ; default to section 0
       sec_sel := 0
       colbeg := 0                 ; beginning column
       colend := 615               ; ending column
       location := LOC
       if (SEC == 1 ) {
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       location := LOC + 1
       }

       message "Writing to EPX%d Section %d FLASH\n", devnum, sec_sel
       ier := ones_erase_prog( $2 )
       if ( ier < 0 ) {
         message "pengn_err 38\n"
         ier := pengn_err( ier )
         return ier
       }
       if ( SEC == -1 ) { ; do section 1, too
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       location := LOC + 1
       message "Writing to EPX%d Section %d FLASH\n", devnum, sec_sel
         ier := ones_erase_prog( $2 )
         if ( ier < 0 ) {
           message "pengn_err 39\n"
           ier := pengn_err( ier )
           return ier
         }
       }
	if ( $1 == 0 ) { ; create the bitmap file
	     ier := all_sram_bitmap( pdb )
	}
	else if ( $1 == 1 ) {
	     ier := all_eprom_bitmap( pdb )
        }

        ier := pdbclose( pdb )

       return ier
} ; end function all_progeprom

;
; progsram( ) -- programs the selected section sram of a EPX8160
;
; 1 = verify
;
func progsram( ) {


	ier := jtag_string( LPT, location, &handle )
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
             message "pengn_err 40\n"
             ier := pengn_err( ier )
             return PROGSRAMFAILED
        }

	ier := check_status( handle )
        if ( ier < 0 ) {
             message "pengn_err 41\n"
             ier := pengn_err( ier )
	     ier := jtag_close( handle )
             return PROGSRAMFAILED
        }


        message "          %d : ", srowbeg
        idx := 0
	first := TRUE
	for i := srowbeg to rowend {
	    ier := gpdbrow( pdb, i, colbeg, &physrow, collen )
	    if ( ier < 0 ) {
                 message "pengn_err 42\n"
		 ier := pengn_err( ier )
	         return PROGSRAMFAILED
	    }
	    ;
	    ; create download packet
	    ;
	    ier := make_fxsr_packet( i, rasize, &physrow, collen, &srampckt )
	    if ( ier < 0 ) {
                 message "pengn_err 43\n"
		 ier := pengn_err( ier )
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

	if ( $1 == 1 ) {
	     ier := verifydev( 0, handle )
	     if ( ier < 0 ) {
                  message "pengn_err 44\n"
	          ier := pengn_err( ier )
	     }
	}

	ier := jtag_close( handle )

        return ier
} ; end function progsram

; all_progsram( ) -- Loads a jedec file into the pdb
;                and programs all the selected srams of an EPX8160
;                by calling function progsram
;
; 1 = create_bitmap
; 2 = verify
;
func all_progsram( ) {
	protect := 0
	pdb := -1
	ier := jedtopdb( nfuses, defval, &protect, &pdb )
	if ( ier < 0 ) {
	     return ier
	}
	if ( protect == SEC_ON ) {
	     ier := setprotect( pdb, protect )
             if ( ier < 0 ) {
                  message "pengn_err 45\n"
	          ier := pengn_err( ier )
                  return PROGSRAMFAILED
	     }
	}

       ; default to section 0
       sec_sel := 0
       colbeg := 0                 ; beginning column
       colend := 615               ; ending column
       location := LOC
       if (SEC == 1 ) {
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       location := LOC + 1
       }

       message "Writing to EPX%d Section %d SRAM\n", devnum, sec_sel
       ier := progsram( $2 )
       if ( ier < 0 ) {
         message "pengn_err 46\n"
         ier := pengn_err( ier )
         return ier
       }
       if ( SEC == -1 ) { ; do section 1, too
       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       location := LOC + 1
       message "Writing to EPX%d Section %d SRAM\n", devnum, sec_sel
         ier := progsram( $2 )
         if ( ier < 0 ) {
           message "pengn_err 47\n"
           ier := pengn_err( ier )
           return ier
         }
       }
	if ( $1 == 0 ) { ; create the bitmap file
	     ier := all_sram_bitmap( pdb )
	}
	else if ( $1 == 1 ) {
	     ier := all_eprom_bitmap( pdb )
        }

        ier := pdbclose( pdb )

       return ier
} ; end function all_progsram


;
; readdev( ) - reads bitmap into pdb for either eprom or sram
;
; 1 = (1 == eprom; 0 == sram)
; 2 = generate bitmap?
;
func readdev( ) {

	ier := jtag_string( LPT, location, &handle )
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
             message "pengn_err 48\n"
             ier := pengn_err( ier )
             return READDEVFAILED
        }

	ier := check_status( handle )
        if ( ier < 0 ) {
             message "pengn_err 49\n"
             ier := pengn_err( ier )
	     ier := jtag_close( handle )
             return READDEVFAILED
        }

	message "Reading from EPX%d's ", devnum
	if ( $1 == 1 ) {
	     message "FLASH\n"
             starting := erowbeg
	}
	else {
	     message "SRAM\n"
             starting := srowbeg
	}

        message "          %d : ", starting
        idx := 0
	for i := starting to rowend {
	    ;
	    ; create download packet
	    ;
	    ier := make_fxra_packet( i, rasize, &raddr )
	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 50\n"
	         ier := pengn_err( ier )
	         return READDEVFAILED
	    }

	    if ( $1 == 1 )
	         ier := jtag_xid( handle, &fread, instlen, &raddr, rasize )
	    else
	         ier := jtag_xid( handle, &sread, instlen, &raddr, rasize )

	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 51\n"
	         ier := pengn_err( ier )
	         return READDEVFAILED
	    }

	    ier := jtag_rd( handle, &tmprow, collen )
	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 52\n"
	         ier := pengn_err( ier )
	         return READDEVFAILED
	    }

	    ;
	    ; reorder by swapping
            ;
	    swp_i := 0
	    swp_j := collen - 1
	    while ( swp_i < collen ) {
                 physrow[swp_i] := tmprow[swp_j]
                 swp_i := swp_i + 1
                 swp_j := swp_j - 1
            }

	    ier := ppdbrow( pdb, i, colbeg, &physrow, collen )
	    if ( ier < 0 ) {
	         message "\n"
                 message "pengn_err 53\n"
	         ier := pengn_err( ier )
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


        return ier
} ; end function readdev

;
; all_readdev( ) - opens up the pdb and reads in either eprom or sram
;                   for both sections

; 1 = (1 == eprom; 0 == sram)
; 2 = generate bitmap?
;
func all_readdev( ) {
  if(SEC == -1)
  { ; all sections selected - ok

	pdb := pdbopen( nfuses, defval, &ier )
	if ( ier < 0 ) {
             message "pengn_err 54\n"
	     ier := pengn_err( ier )
	     return READDEVFAILED
	}

       ; do section 0 first
       sec_sel := 0
       colbeg := 0                 ; beginning column
       colend := 615               ; ending column
       location := LOC

       message "Reading EPX%d Section %d ",
                  devnum, sec_sel
	if ( $1 == 1 ) {
	     message "FLASH"
	}
	else {
	     message "SRAM"
	}
        message " Bitmap file\n";

       ier := readdev( $1 )
       if ( ier < 0 ) {
         message "pengn_err 55\n"
         ier := pengn_err( ier )
         return ier
       }


       ; do section 1

       sec_sel := 1
       colbeg := 616               ; beginning column
       colend := 1231              ; ending column
       location := LOC + 1

       message "Reading EPX%d Section %d ",
                    devnum, sec_sel
       if ( $1 == 1 ) {
         message "FLASH"
         starting := erowbeg
       }
       else {
         message "SRAM"
         starting := srowbeg
       }
       message " Bitmap file\n";

       ier := readdev( $1 )
       if ( ier < 0 ) {
         message "pengn_err 56\n"
         ier := pengn_err( ier )
         return ier
       }

       protect := 0
       ier := getprotect( pdb, &protect )
       if ( ier < 0 ) {
         message "pengn_err 57\n"
         ier := pengn_err( ier )
         pdbclose( pdb )
         return READDEVFAILED
       }

       ier := jedwrite( pdb, protect )
       if ( ier < 0 ) {
         message "pengn_err 58\n"
         ier := pengn_err( ier )
         pdbclose( pdb )
         return READDEVFAILED
       }

       if ( $2 == 0 ) {			; create the bitmap file
         ier := all_sram_bitmap( pdb )
         if ( ier < 0 ) {
           pdbclose( pdb )
           return ier
         }
       }
       else if ( $2 == 1 ) {
        ier := all_eprom_bitmap( pdb )
	if ( ier < 0 ) {
	  pdbclose( pdb )
	  return ier
	}
      }

      ier := pdbclose( pdb )
  } ; end all sections selected - ok
  else
  { ; only 1 section selected - this is illegal for read flash or sram
    ier := MULTISECRQRD
  }
  return ier
} ; end function all_readdev


;
; flow control based on user requested actions
;
;
ier := 0
if ( eprom_or_sram == 1 ) {			; is eprom
    ier := cable_sts( LPT );
    if ( ier != TRUE ) {
         ier := pengn_err( CABLEBAD );
         exit
    }
    if ( prog_or_read ) {			; is program
	 ier := all_progeprom( create_bitmap, verify )
	 if ( ier < 0 ) {
              message "pengn_err 59\n"
	      ier := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
    else {					; is read
	 ier := all_readdev( eprom_or_sram, create_bitmap )
	 if ( ier < 0 ) {
              message "pengn_err 60\n"
	      ier := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
}
else if ( eprom_or_sram == 0 ) {		; is sram
    ier := cable_sts( LPT );
    if ( ier != TRUE ) {
         ier := pengn_err( CABLEBAD );
         exit
    }
    if ( prog_or_read ) {			; is program
	 ier := all_progsram( create_bitmap, verify )
	 if ( ier < 0 ) {
              message "pengn_err 61\n"
	      ier := pengn_err( ier )
	 }
	 ier := rsti( LPT )	; reset the device .. jtag return status to idle
    }
    else {					; is read
	 ier := all_readdev( eprom_or_sram, create_bitmap )
	 if ( ier < 0 ) {
              message "pengn_err 62\n"
	      ier := pengn_err( ier )
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
              message "pengn_err 63\n"
	      ier := pengn_err( ier )
              exit
	 }
	 if ( protect == SEC_ON ) {
	      ier := setprotect( pdb, protect )
	      if ( ier < 0 ) {
                   message "pengn_err 64\n"
	           ier := pengn_err( ier )
	           exit
	      }
	 }
	 ier := all_eprom_bitmap( pdb )
	 if ( ier < 0 ) {
              message "pengn_err 65\n"
	      ier := pengn_err( ier )
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
                   message "pengn_err 66\n"
	           ier := pengn_err( ier )
	           exit
	      }
	 }
	 ier := all_sram_bitmap( pdb )
	 if ( ier < 0 ) {
              message "pengn_err 67\n"
	      ier := pengn_err( ier )
              exit
	 }
         ier := pdbclose( pdb )
    }
}

exit			 			; return to the caller
