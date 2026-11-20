        께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께�
        께                                                             께
        께             ChipMaster 7100XP       S O F T W A R E       께
        께                                                             께
        께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께�


                            Version 1.0A Release
                              December 18, 1996


A. OPERATION OF SOFTWARE


   1. Install ChipMaster 7100XP software on your hard drive:

     A) Place the installation disk into disk drive A: or B:. The installation
	disk contains five files: INSTALL.EXE, SP680BIN.EXE, SP680LIB.EXE and
	SP680ALG.EXE.

     B) Start the installation program, INSTALL.EXE, by typing "A:SETUP
        <CR>". (Replace A with B if the disk is in the B: drive.)

     C) Once the installation program starts, it will display a default
	drive and path, "C:\SP680".  You can change this if you would like.

     D) Press "<CR>" to accept the drive and directory currently displayed.

     E) The installation program will decompress the software files into
        the directory that you specified.

     F) At the end of installation you will be asked if you would like the 
        software to add a pathname to AUTOEXEC.BAT. If AUTOEXEC.BAT 
        does not exist, it will be created. 

   2. To invoke ChipMaster 7100XP software:

     A) Simply type "SP680" in any directory if you have added the path name in
        AUTOEXEC.BAT

     or

     B) Change to the directory where the software was installed. (Default
	directory is C:\SP680\BIN.) Then type "SP680<CR>" at the DOS prompt.

	      Example:    C:>CD \SP680\BIN <CR>
			  C:\SP680\BIN>SP680 <CR>

     or

     C) Type the full path where SP680.EXE file resides

	      Example:    C:>\SP680\BIN\SP680 <CR>

   3. The software is installed in three different directories:

              For example:

	      C:\SP680\BIN ....... Program files (Executable, Help, Readme,
                                    Device List)
	      C:\SP680\LIB ....... Library files (Main Device Library)
	      C:\SP680\ALGO....... All current Algorithm files

         *Note: The path names listed above are the default directories.
                If you specified a different directory at installation,
                the root directory will be the one that you specified.

   4. View or print ChipMaster 7100XP Device or Adapter List.

        You can view or print the ChipMaster 7100XP Device List DEVICE.LST and
        adapter list ADAPTER.LST using any DOS edit or print tool.

	Example:  C:\SP680\BIN>print device.lst <CR>
	Example:  C:\SP680\BIN>edit device.lst <CR>

        There are also Ms-Word format device list and adapter list, You can
        view it by open the file *.DOC under WinWord (version 6.0c or upper)


B. SOFTWARE PACKING LIST


    The following files were copied to the respective directories
    during the software installation.

Subdirectory:   BIN (system directory)

	SP680.EXE         SP680.HLP      (SUPERPRO executables)

Subdirectory:   LIB (library directory)

        EPROM.REZ       EPROM.LST       EPROM1.REZ      EPROM1.LST
        BPROM.REZ       BPROM.LST       BPROM1.REZ      BPROM1.LST
        DSRAM.REZ       DSRAM.LST       DSRAM1.REZ      DSRAM1.LST
        PAD.REZ         PAD.LST         PAD1.REZ        PAD1.LST
        MIC.REZ         MIC.LST         MIC1.REZ        MIC1.LST
        ENCRYPT.REZ     SPUSE.REZ       TEST.LIB        ROMID.LIB
        SPAD.LIB        DEVICE.TXT
Subdirectory:   ALGO (algorithm directory)

	All Algorithm (.SP6&.INI) files.

