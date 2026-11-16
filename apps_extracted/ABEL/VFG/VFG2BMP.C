/*******************************************************************
* Program 2 - Format Video Image and translate to a Windows BMP file
* Copyright 1993  Michael Holley and David Pellerin
*/

/* Written for MicroSoft C Version 5.1 */

#include <stdio.h>
#include <conio.h>

#define XMAX      360  /* Number of pixel in X direction (width) */
#define YMAX      230  /* Number of pixel in Y direction (lines) */
#define TOP_SKIP   1   /* Scan lines skipped at top of frame */
#define SIDE_SKIP  0   /* Samples skipped at start of scan line */

FILE *outfile;
FILE *infile;


/*********************************************
* Open the file specified on the command line
* and convert to a .BMP file. Output file name
* is PRTFILE.BMP.
*/
main(argc,argv)
int  argc;
char *argv[];
{
    int x, y;
    int sample;

    printf("Process video frame grabber disk file\n");

    /* Open data file */

    if(argc > 1)
    {
        printf("Opening input file '%s'\n",argv[1]);
	    if( (infile = fopen(argv[1],"rb") ) == NULL)
        {
            fprintf(stderr,"can't open input file '%s'",argv[1]);
            exit(1);
        }
    }
    else
    {
        printf("Opening input file 'temp'\n");
        if( (infile = fopen("temp","rb") ) == NULL)
        {
            fprintf(stderr,"can't open input file '%s'","temp");
            exit(1);
        }
    }

    /* Open output file */

    printf("Opening output file 'prtfile.bmp'\n");
    if( (outfile = fopen("prtfile.bmp","wb") ) == NULL)
    {
        fprintf(stderr,"can't open output file '%s'","prtfile");
        exit(1);
    }

    init_plot();

    for(y=0; y < TOP_SKIP; y++)
    {
        find_hsync();
    }

    /* Read scan lines */

    for(y = 0; y < YMAX; y++)
    {
        for(x = 0; x < XMAX; x++)
        {
            sample = getc(infile);
            fprintf(outfile,"%c",sample);
        }
        find_hsync();   /* Find start of next scan line */
    }

    close(infile);
    close(outfile);
    exit(0);
}

/**********************************************
* Find Horizontal sync pulse
*/
find_hsync()
{
    int sync_cnt;
    unsigned char sample;

    sync_cnt = 0;

    /* Look for 20 samples of zero (synclevel) */

    while(sync_cnt < 20)
    {
        sync_cnt++;
        sample = getc(infile);
        if(sample != 0)
        {
            sync_cnt = 0;
        }
    }

    /* Skip color burst samples */

    while(sync_cnt < SIDE_SKIP)
    {
        sample = getc(infile);
        sync_cnt++;
    }
}

/*********************************************
* Initialize plot
*/
init_plot()
{
    long total_size,width,heigth;
    long offset;
    int	 i,blue,green,red;

    /* write header */

    width = XMAX;
    heigth = YMAX;
    offset = 12L + 40L + (256L * 4L);
    total_size = width * heigth + offset;

    /* BitMapFileHeader	*/

    fprintf(outfile,"BM");
    write_long(outfile,total_size);     /* Total size of file   */
    write_short(outfile,0);             /* Set to 0             */
    write_short(outfile,0);             /* Set to 0             */
    write_long(outfile,offset);         /* Offset to bitmap     */

    /* BitMapInfoHeader	*/

    write_long(outfile,40L);            /* Size of structure    */
    write_long(outfile,width);          /* Width of bitmap      */
    write_long(outfile,heigth);         /* Heigth of bitmap     */
    write_short(outfile,1);             /* Set to 1             */
    write_short(outfile,8);             /* Color bits per pixel */
    write_long(outfile,0L);             /* Compression scheme   */
    write_long(outfile,0L);             /* Size of bitmap       */
    write_long(outfile,0L);             /* Horizontal res       */
    write_long(outfile,0L);             /* Vertical res         */
    write_long(outfile,0L);             /* Number of colors     */
    write_long(outfile,0L);             /* Important colors     */

    /* RGBQUAD */

    for(i = 0; i < 256; i++)
    {
        blue  = i & 0xFE;
        green = i & 0xFE;
        red   = i & 0xFE;
        fprintf(outfile,"%c%c%c%c",blue,green,red,0);
    }
}

/*********************************************
*/
write_long(fp,lnum)
FILE  *fp;
long  lnum;
{
    int b0,b1,b2,b3;
     
    b0 = (lnum & 0x00ff);
    lnum = lnum >> 8;
    b1 = (lnum & 0x00ff);
    lnum = lnum >> 8;
    b2 = (lnum & 0x00ff);
    lnum = lnum >> 8;
    b3 = (lnum & 0x00ff);
    lnum = lnum >> 8;

    fprintf(fp,"%c%c%c%c",b0,b1,b2,b3);
}

/*********************************************
*/
write_short(fp,num)
FILE  *fp;
int   num;
{
    int b0,b1;
     
    b0 = (num & 0x00ff);
    num = num >> 8;
    b1 = (num & 0x00ff);

    fprintf(fp,"%c%c",b0,b1);
}


