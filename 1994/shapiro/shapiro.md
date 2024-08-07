# HINTS

For the first program, [shapiro.c](%%REPO_URL%%/1994/shapiro/shapiro.c):


This is a very simple program:

```
     1. #include <stdio.h>
     2. main()
     3. {
     4. int K,L,M=0;
     5. FILE *J;
     6. J=fopen(__FILE__,"r");
     7. for(;
     8.     (L=getc(J))>=0;
     9.     L>='J'&&L<='J'+15 &&
    10.     ((M=!M)?K=L:putchar(K-'J'|(L-'J'<<4)))
    11.    );
    12. exit(0);}
```

Lines 1-5 are basic stuff. Line 6 opens the source code for input. Line 7 is the
loop. Line 8 reads in each character in the file (placed in `L`) while not >= 0.
Line 9 is an `if` expression which filters out all characters not between `J`
and `J + 15`. Line 10 uses `M` to execute two different paths; the first just
stores the character in `K` and the second path combines the last two characters
read in as high and low nibbles of a byte and outputs them. In effect this is a
very poor ASCII to binary decoder.  The last line is necessary so that make will
not stop when it executes this program.

The second program is encoded into this format and then included (mostly)
as a comment.

Notice that it is impossible to write this program while leaving 16
contiguous ASCII characters free for the encoding. Because of this the
second program is mostly included as a comment. However, some of the
characters of the encoded program are also source code for the decoder.


### For the second program (with time.h):

```
     1  #include <stdio.h>
     2  #include <time.h>
     3  #define o(j,k,m,n,l) {fprintf(j,a[k],m,n,a[l]);fflush(j);}
     4  char *a[]={"%c+------------+\n","%c+%3d %-8s+\n","seconds","minutes",
     5             "hours","%s\n","\0337\033[%d;65;H%s\0338"};
     6  int b[]={0,0,17,14,11,0};
     7  main(v,c)
     8  int v;
     9  char ** c;
    10  {
    11    char d[40],*e,f=6;
    12    time_t g;
    13    FILE *h,*i;
    14    while (--f && !pipe(d) && !fork());
    15    h=fdopen(6-f<<1,"a");
    16    i=fdopen((6-f<<1)+1,"r");
    17    for(;;){
    18      if(f){
    19        fgets(d,40,i);
    20        d[strlen(d)-1]='\0';
    21        if(*d=='0'+f){ sprintf(*c,"%s\n",d+1); o(stdout,6,6-f,d+1,0) }
    22        if(*d>'0'+f) o(h,5,d,0,0)
    23      }else{
    24        time(&g);
    25        e=asctime(localtime(&g));
    26        for(v=1;v<6;v++) o(h,v!=1&&v!=6-1,v+'0',atoi(e+b[v]),v)
    27        sleep(1);
    28    }}}
```

Lines 1 and 2 have to be there. Think of `o` in line 3 as send message with
`j`,`k` and `m` as where, format and what. Lines 4 and 5 are all the text
strings. Line 6 is the offsets into the time string for the hours, minutes and
seconds. Lines 7-13 are basic stuff. Line 14 is the crux of the biscuit. 14
forks off `f` (6) processes each of which is connected to the ones above and
below it with a Unix pipe. It was too difficult to recover the actual FD numbers
for the pipe ends in line 14 so I regenerate them and `fdopen()` them (for use
with the standard C library functions) on lines 15 and 16. Now we have six
almost identical processes each of which has two files open, `h` and `i` (up and
down). The only difference in each process is the value of `f` (`0 <= f < 6`).
The five processes where `f !=0` are the slave processes and `f == 0` is the
master. Line 17 says we are going to do this forever. Lines 18 and 23
differentiate between the master and the slaves.

Lines 19 to 22 are the slave code. Here we read in a line of text from
`i` (down, line 19) and remove the newline char (line 20). On line
21 if this message is for us (if the first character is our number, `f`,
in ASCII) we do two things:

1. We copy the text of the message to `*c` which is really `argv[0]`.  If you are
on the correct flavor of Unix this will change the output of the `ps(1)` command
to the string we just put there.
2. We send the message (not including the number) to `stdout` with format number 6
(`"\0337\033[%d;65;H%s\0338"`) If you can read VTxxx (and I read books printed
as ANSI/VTxxx codes for fun :-) ) you know this is the sequence for:

> remember where we are,<br>
> go somewhere else,<br>
> print the message,<br>
> and return to where we started.

Line 22 says if this message is not for us (the number is bigger than ours)
send it to `h` (up).

Lines 24 to 27 are the master code. Here we get the time and convert it
to an ASCII format (lines 24 and 25). Then on line 26 we build and send
each of the messages for the slaves. The message uses a different control
string for the different slaves. For the first and last slave the message
text is just `"%c+------------+\n"` (slave number, text, newline.) For the
other slaves it is `"%c+%3d %-8s+\n"` (slave number, number, units, newline).
The slave number is `v+'0'`. The number (if used) is `atoi(e+b[v])` and the
units are just the string in the slave number position.


<hr style="width:10%;text-align:left;margin-left:0">

Jump to: [top](#)


<!--

    Copyright © 1984-2024 by Landon Curt Noll. All Rights Reserved.

    You are free to share and adapt this file under the terms of this license:

        Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)

    For more information, see:

        https://creativecommons.org/licenses/by-sa/4.0/

-->
