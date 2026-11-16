    5105
"	VERSION 4.30 			Copyright(C) 1992 Data I/O Corp.
"==============================================================================
" constant.inc
"
Z,C,K,X,U,D,P,H,L = .Z., .C., .K., .X., .U., .D., .P., 1, 0;
TRUE, FALSE = !0, 0;


" E0320.INC

	MISER macro (a) { fuses [2912,2913] = [?a,?a]; };

	TURBO macro (a) { fuses [2914,2915] = [?a,?a]; };


" E0600.INC

	TURBO macro (a) { fuses [6480,6481] = [?a,?a]; };

" P16V8 Electronic Signature Word
SIGNATURE MACRO (string)
{
   @CONST cnt = 1;
   @CONST r1 = 2056;	" First address of signature word
   @IRPC A (?string)
   {
	@IF (cnt > 8) { @MESSAGE 'WORD TOO LONG'; @EXIT;}
   	FUSES [@EXPR r1;..@EXPR (r1+7);] = @EXPR '?A';;
	@CONST  r1 = r1 + 8;
	@CONST	cnt = cnt + 1;
   }
}
" P16Z8 Electronic Signature Word
SIGNATURE MACRO (string)
{
   @CONST cnt = 1;
   @CONST r1 = 2056;	" First address of signature word
   @IRPC A (?string)
   {
	@IF (cnt > 8) { @MESSAGE 'WORD TOO LONG'; @EXIT;}
   	FUSES [@EXPR r1;..@EXPR (r1+7);] = @EXPR '?A';;
	@CONST  r1 = r1 + 8;
	@CONST	cnt = cnt + 1;
   }
}
" P20V8 Electronic Signature Word
SIGNATURE MACRO (string)
{
   @CONST cnt = 1;
   @CONST r1 = 2568;	" First address of signature word
   @IRPC A (?string)
   {
	@IF (cnt > 8) { @MESSAGE 'WORD TOO LONG'; @EXIT;}
   	FUSES [@EXPR r1;..@EXPR (r1+7);] = @EXPR '?A';;
	@CONST  r1 = r1 + 8;
	@CONST	cnt = cnt + 1;
   }
}
" P22V10G Electronic Signature Word
SIGNATURE MACRO (string)
{
   @CONST cnt = 1;
   @CONST r1 = 5828;	" First address of signature word
   @IRPC A (?string)
   {
	@IF (cnt > 8) { @MESSAGE 'WORD TOO LONG'; @EXIT;}
   	FUSES [@EXPR r1;..@EXPR (r1+7);] = @EXPR '?A';;
	@CONST  r1 = r1 + 8;
	@CONST	cnt = cnt + 1;
   }
}
" P26CV12 Electronic Signature Word
SIGNATURE MACRO (string)
{
   @CONST cnt = 1;
   @CONST r1 = 6368;	" First address of signature word
   @IRPC A (?string)
   {
	@IF (cnt > 8) { @MESSAGE 'WORD TOO LONG'; @EXIT;}
   	FUSES [@EXPR r1;..@EXPR (r1+7);] = @EXPR '?A';;
	@CONST  r1 = r1 + 8;
	@CONST	cnt = cnt + 1;
   }
}
" P18V10G Electronic Signature Word
SIGNATURE MACRO (string)
{
   @CONST cnt = 1;
   @CONST r1 = 3476;	" First address of signature word
   @IRPC A (?string)
   {
	@IF (cnt > 8) { @MESSAGE 'WORD TOO LONG'; @EXIT;}
   	FUSES [@EXPR r1;..@EXPR (r1+7);] = @EXPR '?A';;
	@CONST  r1 = r1 + 8;
	@CONST	cnt = cnt + 1;
   }
}



"Include file - 4bcomp.inc
"4 bit comparator
"Inputs:  q3, q2, q1, q0, d3, d2, d1, d0     
"Output:  compare        

    compare = ([q3..q0] == [d3..d0]);



"Include file - 4bcount.inc
"4 bit counter 
"Inputs: clock, hold, reset
"Outputs: q3, q2, q1, q0

    q3,q2,q1,q0 pin istype 'reg,buffer';
    count = [q3..q0];

equations

    count.clk = clock;  "clock input
    count.ar = reset;   "asynchronous reset

       when (hold)  then count := count.fb;
  else when (!hold) then count := count.fb + 1;




"Include file - 4binreg.inc
"4 input registers in a group. 
"Inputs: load, in3, in2, in1, in0
"Outputs:  d3, d2, d1, d0 

    d3,d2,d1,d0 node istype 'reg,buffer';
    inputs = [in3..in0];
    inreg = [d3..d0];


equations

    inreg.clk = load;
    inreg := inputs;


"ispGDS MACROs

GDS_DEVICE_INIT MACRO
{
	FUSES
	[ 0..10] = ^b11111111111;
	[11..21] = ^b11111111111;
	[22..32] = ^b11111111111;
	[33..43] = ^b11111111111;
	[44..54] = ^b11111111111;
	[55..65] = ^b11111111111;
	[66..76] = ^b11111111111;
	[77..87] = ^b11111111111;
	[88..98] = ^b11111111111;
	[99..109] = ^b11111111111;
	[110..120] = ^b11111111111;
}

GDS_IO MACRO (Group, MCnum, Type)
{
@ifniden(?Group,A)
 {@ifniden(?Group,B)
    {@message 'Invalid Group, must be A or B'; @exit}}

@if((?MCnum<0)#(?MCnum>10))  
    {@message 'Invalid Macrocell_Number, must be between 0 and 10'; @exit}

@ifiden(?Group,A){
    @const c0 = 174 - ?MCnum;
    @const c1 = 196 - ?MCnum;
    @const c2 = 218 - ?MCnum;}

@ifiden(?Group,B){
    @const c0 = 153 + ?MCnum;
    @const c1 = 175 + ?MCnum;
    @const c2 = 197 + ?MCnum;}

@const Bits = ^B110; "set illegal value
@ifiden(?Type,INPUT)	{@const Bits = ^B101;}
@ifiden(?Type,OUT_NOINV){@const Bits = ^B011;}
@ifiden(?Type,OUT_INV)	{@const Bits = ^B001;}
@ifiden(?Type,TTL_1)	{@const Bits = ^B010;}
@ifiden(?Type,TTL_0)	{@const Bits = ^B000;}
@ifiden(?Type,OUT_TRI)	{@const Bits = ^B111;}
" if illegal value never changed, then Type was not valid
@if (Bits == ^B110)
  {@message 'Invalid Macrocell Type'; @exit}

[@expr c0;,@expr c1;,@expr c2;] = Bits;
} 

 
GDS_CONNECT MACRO (Group, MCout, MCin)
{

@ifniden(?Group,A)
 {@ifniden(?Group,B)
    {@message 'Invalid Group, must be A or B'; @exit}}

@if((?MCout<0)#(?MCout>10))
    {@message 'Invalid Output macrocell number'; @exit}
@if((?MCin<0)#(?MCin>10))  
    {@message 'Invalid Input macrocell number'; @exit}

@ifiden(?Group,A){
    @const Fuse = (10 + (?MCout * 11)) - ?MCin;
    @expr Fuse; = 0;}

@ifiden(?Group,B){
    @const Fuse = (10 - ?MCout) + (?MCin * 11);
    @expr Fuse; = 0;}

}
14 
4BCOMP.INC 2424 159 ""
4BCOUNT.INC 2592 351 ""
4BINREG.INC 2962 271 ""
CONSTANT.INC 143 100 ""
E0320.INC 248 118 ""
E0600.INC 373 66 ""
GDS.INC 3251 1780 ""
P16V8.INC 444 316 ""
P16Z8.INC 773 316 ""
P18V10G.INC 2093 318 ""
P20V8.INC 1102 316 ""
P22V10G.INC 1431 318 ""
P26CV12.INC 1762 318 ""
VERSION.INC 10 131 ""
