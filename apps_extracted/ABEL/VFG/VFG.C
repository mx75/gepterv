/* Video Frane Grabber Control Program                */
/* Copyright 1990   Michael Holley and David Pellerin */

/* Written for MicroSoft C version 5.1 */

#include <conio.h>
#include <stdio.h>

#define FILESIZE 131071L

char name_buf[45];

main()
{
    int ch;

    print_menu();
    while(1)
    {
        ch = getch();
        switch(toupper(ch))
        {
            case 'F':   outp(0x316,0);  /* Freeze Picture */
                        break;

            case 'L':   outp(0x314,0);  /* Live Picture */
                        break;

            case 'W':   save_RAM();     /* Write Image */
                        break;

            case 'R':   load_RAM();     /* Read Image */
                        break;

            case 'Q':   exit(0);        /* Quit Program */
                        break;

            default:    print_menu();
                        break;
        }
    }
}

print_menu()
{
    printf("\nFreeze video frame grabber\n");
    printf("Press 'L' for live image\n");
    printf("Press 'F' to freeze image\n");
    printf("Press 'W' to write image RAM to disk file\n");
    printf("Press 'R' to read disk file into image RAM\n");
    printf("Press 'Q' to return to DOS\n");
}

/* Copy image in VFG RAM to disk file */
save_RAM()
{
    unsigned char data;
    long i;
    FILE *fp;

    name_buf[0] = '\0';
    printf("\nEnter file name: ");
    scanf("%40s",name_buf);
    if( (fp = fopen(name_buf,"wb") ) == NULL)
    {
        fprintf(stderr,"can't open output file '%s'\n",name_buf);
        return;
    }

    outp(0x313,0);    /* Clear address counter */

    for (i=1L; i < FILESIZE; i++)
    {
        outp(0x313,0);     /* Next Address */
        outp(0x312,0);     /* Hold Address */
        data = inp(0x300);
        putc(data,fp);
    }

    outp(0x316,0);         /* Freeze Picture */
    close(fp);
}

/* Copy a saved image from disk into VFG RAM for playback */
load_RAM()
{
    unsigned char data;
    long i;
    FILE *fp;

    name_buf[0] = '\0';
    printf("\nEnter file name: ");
    scanf("%40s",name_buf);
    if( (fp = fopen(name_buf,"rb") ) == NULL)
    {
        fprintf(stderr,"can't open input file '%s'\n",name_buf);
        return;
    }

    outp(0x313,0);         /* Clear address counter */

    for (i=1L; i < FILESIZE; i++)
    {
        outp(0x313,0);     /* Next Address */
        outp(0x312,0);     /* Hold Address */
        data = getc(fp);
        outp(0x300,data);
    }

    outp(0x316,0);         /* Freeze Picture */
    close(fp);
}

