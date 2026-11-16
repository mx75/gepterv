
/*
 * **************************  ALTERA PROPRIETARY  ***************************
 *
 *       --------------------  DO NOT REPRODUCE  ----------------------
 *
 *   Copyright (C) 1994 by Altera Corporation.
 *   All rights reserved. No part of this program or publication may be 
 *   reproduced, transmitted, transcribed, stored in a retrieval system, or
 *   translated into any language or computer language, in any form or by any
 *   means, electronic, mechanical, magnetic, optical,  chemical,  manual, or
 *   otherwise,  without the prior written permission of  Altera Corporation,
 *   2610 Orchard Parkway,  San Jose,  California 95134-2020.
 *
 * ***************************************************************************
 */


/************************************************************************/
/*        Program name:         fx_ims.c                                */
/*        Version Number:       0                                       */
/*        Author:               Richard Vireday                         */
/*        Date:                 March 1993                              */
/*        $Revision: 1.2 $                                              */
/************************************************************************/

/************************************************************************/
/*        Description:  This program will translate the 'pengn' Bitmap  */
/*        file format into EPROM and SRAM test vectors for the IMS.     */
/************************************************************************/

/* standard includes */
#include <stdio.h>

#define MAXLINE 1000                       /* maximum input line length */
#define MAXNAME 100                        /* maximum filename length */

#define EOS '\0'
#define EOL '\n'

/* equates for packet information and file types */
#define SRAM_TYPE 0
#define EPROM_TYPE 1

#define SRAM_LEN 606        
#define EPROM_LEN 43

/* function to write a JTAG vector, such as an instruction */
wr_vector(format, comment, vector, outfile)
char *format;
char *comment;
char *vector;
FILE *outfile;
{
    char *v = vector;

    fprintf(outfile, format, *v++);
    fprintf(outfile, " {%s, %s}\n",comment, vector);
    while (*v != EOS)
    {
	fprintf(outfile, format, *v++);
	fputc(EOL, outfile);
    }
}

main(argc, argv)
int     argc;  /* number of command line args */
char  **argv;  /* command line ptr string */
{
	FILE *infile;                    /* input file */
	FILE *outfile;                   /* output file */
	FILE *fopen();

	char *inname;                    /* input filename */ 
	char *outname;                   /* output filename */

	char c;                          /* process variables */

	int  type_of_file;               /* to indicate type */

	int i;                           /* index variable */
	int no_rows;                     /* the number of rows processed */

	int data_len;                    /* the length of data in a packet */

	/* Standard IMS Vector Format. '*' starts a new vector */
	char *vecfmt = " * 10%c * 0";
	/*                 :::    :...TCK signal (in next vector)
	 *                 :::...TDI
	 *                 ::...TMS
	 *                 :...TCK signal
	 */


/************************************************************************/
/*                      Parse command line arguments                    */
/************************************************************************/

    inname  = NULL;                   /* initialize filename strings */
    outname = NULL;

    i=1;
    while (i < argc)
    {
	if (inname == NULL)
	    inname = argv[i];       /* get file names */
	else if (outname == NULL)
	    outname = argv[i];

	/* else all other arguments ignored */
	i++;
    }

/************************************************************************/
/*                      Check command line arguments                    */
/************************************************************************/

    if (inname == NULL)
    {
	printf("%s:  Error, source bit filename not specified.\n",argv[0]);
	exit(1);
    }
    if (outname == NULL)
    {
	printf("%s:  Error, output pattern filename not specified.\n",argv[0]);
	exit(1);
    }

/************************************************************************/
/*                      Open files for processing                        */
/************************************************************************/

    if ((infile = fopen(inname,"r")) == NULL)
    {
	printf("%s:  Error opening source bit pattern filename %s\n",
								argv[0],inname);
	exit(1);
    }
    if ((outfile = fopen(outname,"w")) == NULL)
    {
	printf("%s:  Error opening output pattern filename %s\n",
								argv[0],outname);
	exit(1);
    }

/************************************************************************/
/*                Preliminary processing of source bit pattern file     */
/************************************************************************/
/* First we determine the length of the vectors, and what type of file  */
/* is being used.  Then we know what instruction to use. SWRITE or FPGM */

    data_len = 0;
    while ((c = getc(infile)) != EOF)
    {
	if (c == ':')                /* enter comment state */ 
	{
	    while ((c = getc(infile)) != EOL)
	    {
		if (c == EOF)
		    break;
	    }
	}

	if (c != EOL)
	{
	    while ((c = getc(infile)) != '*')
	    {
		if (c == EOF) break;

		if (c == ';') break;

		if (c != EOL)
		   data_len++;
	    }
	    break;
	}
    }

    rewind(infile);   /* reset to re-read again */

    switch (data_len) 
    {
	case SRAM_LEN:
	    printf("SRAM vectors in %s, vector length %d\n", inname, data_len);
	    type_of_file = SRAM_TYPE;
	    break;
	case EPROM_LEN:
	    printf("EPROM vectors in %s, vector length %d\n", inname, data_len);
	    type_of_file = EPROM_TYPE;
	    break;
	default:
	    printf("WARNING: Unknown vectors in %s, vector length %d\n", 
							inname, data_len);
	    printf("Assuming SRAM type.\n");
	    type_of_file = SRAM_TYPE;
	    break;
    }

/************************************************************************/
/*                Add Initial Information to output pattern             */
/************************************************************************/
/* Comments are in { }, and show the JTAG TAP Controller state the	*/
/* vector will put the device into.					*/

    for (i = 0 ; i < 8; i++)
	fprintf(outfile, "* 000 * 0\n");
    fprintf(outfile, "* 110 * 0 Repeat 15 times\n");   /* to initialize */
    fprintf(outfile, "* 100 * 0 { Run Test Idle }\n"); 
    fprintf(outfile, "* 110 * 0 { Select DR Scan }\n"); 
    fprintf(outfile, "* 110 * 0 { Select IR Scan }\n"); 
    fprintf(outfile, "* 100 * 0 { Capture IR }\n"); 

    if (type_of_file == EPROM_TYPE)
	wr_vector(vecfmt, "Shift IR, for FPGM Instr. LSB..MSB", "10101", outfile);
    else
	wr_vector(vecfmt, "Shift IR, for SWrite Instr. LSB..MSB", "11110", outfile);

    fprintf(outfile, "* 110 * 0 { opcode entered, exit IR }\n"); 
    fprintf(outfile, "* 110 * 0 { Update IR }\n");
    fprintf(outfile, "* 110 * 0 { Select DR Scan }\n");
    fprintf(outfile, "* 100 * 0 { Capture DR Scan }\n");
    fprintf(outfile, "* 100 * 0 { Shift DR Scan }\n");
    
/************************************************************************/
/*                Begin processing of source bit pattern file           */
/************************************************************************/
/* JTAG TAP Controller is now in Shift-DR state.  Next vectors will     */
/* begin pumping the Bitmap data in.                                    */

    i = 0;    /* number of bits read */
    no_rows = 0;
    data_len = data_len - 1;

    while ((c = getc(infile)) != EOF)
    {
	    if (c == ':')                /* process comment */ 
	    {
		fprintf(outfile, "{ ");

		while ((c = getc(infile)) != EOL)
		{
		    if (c == EOF) break;

		    fputc(c,outfile);
		}

		fprintf(outfile, " }\n");
	    }
	    else if (c == '*')
	    {
		while ((c = getc(infile)) != ';')
		{
		    if (c == EOF) break;
		    if (c == EOL) continue;

		    /* if not on final bit, print it */
		    if (i < data_len)
			fprintf(outfile, " * 10%c * 0\n",c);
		    else
			/* put in pattern transition for final address */
			fprintf(outfile, " * 11%c * 0 { end of row %d}\n",
								c,no_rows);

		    i++;                /* increment bit count */
		}
	    }

	    if (c == ';')
	    {
		i=0;
		no_rows++;

		/* write the transition pattern for the next vector */
		fprintf(outfile, "* 110 * 0 { Update DR }\n");
		fprintf(outfile, "* 100 * 0 { Run Test Idle }\n");
		fprintf(outfile, "* 100 * 0 { Run Test Idle (again) }\n");
		fprintf(outfile, "* 110 * 0 { Select DR Scan }\n");
		fprintf(outfile, "* 100 * 0 { Capture DR Scan }\n");
		fprintf(outfile, "* 100 * 0 { Shift DR Scan }\n");
		/* note: both Run-Test-Idle states are necessary for
		   SRAM and EPROM configurations. */
	    }
    }

    printf("The number of converted rows:  %d\n",no_rows);

/************************************************************************/
/*                Write the final closing vector patterns               */
/************************************************************************/

    fprintf(outfile, "* 110 * 0 { Update DR }\n");
    fprintf(outfile, "* 100 * 0 { Run Test Idle }\n");

    /* if necessary, uncomment these vectors go to Test-Logic-Reset */
    /* for (i = 0; i < 5; i++) */
	/* fprintf(outfile, "* 110 * 0 { Test-Logic-Reset }\n"); */

/************************************************************************/
/*                Close all files                                         */
/************************************************************************/

    fclose(infile);
    fclose(outfile);
}        
