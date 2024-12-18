## To build:

``` <!---sh-->
    make all
```


## To use:

``` <!---sh-->
    cat august.c test.oc | ./august > test.oo
    ./august < test.oo
```


The above should print a `!` followed by a newline.


## Try:

``` <!---sh-->
    ./try.sh
```


## Judges' remarks:

This entry can feed on itself.  If you C pre-process the source,
you can compile the interpreter:

``` <!---sh-->
    make august.oc
```

We can now compile the interpreter as follows:

``` <!---sh-->
    cat august.c august.oc | ./august > august.oo
```

and use the compiled interpreter to execute some previously
compiled code:

``` <!---sh-->
    cat august.oo test.oo | ./august
```

And we can have the compiled interpreter interpret itself which
in turn compiles the test program:

``` <!---sh-->
    cat august.oo august.oo fac.oo | ./august
```

And if you have lots of spare time, you can recurse one level deeper:

``` <!---sh-->
    cat august.oo august.oo august.oo fac.oo | ./august
```

We (the judges) recommend that you spend some time studying this
entry as it surely will make the 'best of the IOCCC' list.  It was
very well received by those who attended the [IOCCC BOF](../../faq.html#ioccc_bof).


## Author's remarks:

This program is a bytecode interpreter.  This fact is not
particularly obfuscated; any experienced C programmer can see that
in about a minute.

The interpreter reads the bytecode from the standard input.  What
remains of the standard input after this is left as standard input for
the interpreted program.

Having an interpreter but no code isn't any fun.  But within a comment
in the beginning of the interpreter is a sequence of bytes that is
code that the interpreter understands.  It is in fact the code for a
compiler that compiles from OC (Obfuscated C, a subset of C) into the
byte code that the interpreter understands.

The language the compiler understands is a subset of C (the grammar
is below) with the functions `getchar(3)` and `putchar(3)`
available.  The subset has the types `int`, `char`, and pointers to
those (it has function pointers too, but not with the proper
syntax).  Arrays can only be global.  There is a rather limited set
of operators, and control constructs.

The compiler has absolutely no error checking, so things
can go wrong.  But this is what seasoned C programmers are used to.

Assume that the interpreter has been compiled (source in [august.c](%%REPO_URL%%/1996/august/august.c)
and binary in august) and that we have this in a file named `test.oc`:

``` <!---c-->
    main() { putchar('!'); putchar('\n'); exit(0); }
```

We can then compile by

``` <!---sh-->
    cat august.c test.oc | ./august > test.oo
```

And run the compiled program by

``` <!---sh-->
    ./august < test.oo
```

Or even simpler:

``` <!---sh-->
    cat august.c test.oc | ./august | ./august
```

A larger example is included [fac.oc](%%REPO_URL%%/1996/august/fac.oc).

The compiler for OC is naturally written in OC (where did you think the byte
code came from?).  It is in the file [parse.oc](%%REPO_URL%%/1996/august/parse.oc).

Hmm...  So now we have an interpreter written in OC and a compiler for OC, can
we compile the interpreter?  Yes, we can!  The OC compiler does not have a
preprocessor (hey, what do you expect from a program that is this small), so we
need to use an external one.  To pre-process [august.c](%%REPO_URL%%/1996/august/august.c) use the
command from the Makefile, but add the `-E` flag and change 60000 to 40000,
i.e.:

``` <!---sh-->
    cc -E -DZ=40000 .... august.c > august.oc
```

If `august.oc` contain some junk line starting with a `#` (most likely
it does) then remove it like:

``` <!---sh-->
    sed -i'' '/^#/d' august.oc
```

OK, we can now compile the interpreter:

``` <!---sh-->
    cat august.c august.oc | ./august > august.oo
```

And we can run it:

``` <!---sh-->
    cat august.oo test.oo | ./august
```

Here we have the interpreter interpreting another interpreter that runs
the program.  Did you think that was too fast?  Just throw in another
level of interpretation:

``` <!---sh-->
    cat august.oo august.oo test.oo | ./august
```

And another...

``` <!---sh-->
    cat august.oo august.oo august.oo test.oo | ./august
```

<hr>

Fitting the byte code for the compiler into the initial comment
was a challenge.  I had to strip the compiler/interpreter of
a lot of functionality to bring down their sizes.  The initial
version had a full set of binary operators as well as prefix `&`.
Given a handful more bytes it would be easy to put them back.

Anyway, the bytecode from the compiler is first optimized in
an external optimizer (not supplied here); this brings down the
size of it by about 30%.  The remaining code is then LZ-compressed
(roughly) with a sliding window of 255 bytes.  The most common
occurring bytes are then encoded using `" \n\t;{}"` to avoid having
them counted as significant.  About 200 bytes of the interpreter
handles the unpacking of the byte code (this is a lot, but it pays
off).

Despite all this work I still had to put a lot of code in the
compilation command.  This disturbs me.  It is possible to compress
the code further with a better entropy coder (e.g. an arithmetic
coder), but decompression then takes up too much code.  Maybe this
would be a way to fit it all into the 1536 bytes, but I don't have
time to try it.

<hr>

Execution starts at `main()`.  Nothing can be used before it is
defined.  `getchar()` and `putchar()` are predefined functions.

Below is a description of the OC grammar.

### OC grammar

Terminals are in quotes, `()` is used for bracketing.

```
    program:    decl*

    decl:       vardecl
                    fundecl

    vardecl:    type NAME ;
                    type NAME "[" INT "]" ;

    fundecl:    type NAME "(" args ")" "{" body "}"

    args:       /*empty*/
                    ( arg "," )* arg

    arg:        type NAME

    body:       vardecl* stmt*

    stmt:       ifstmt
                    whilestmt
                    dowhilestmt
                    "return" expr ";"
                    expr ";"
                    "{" stmt* "}"
                    ";"

    ifstmt:     "if" "(" expr ")" stmt
                    "if" "(" expr ")" stmt "else" stmt

    whilestmt:  "while" "(" expr ")" stmt

    dowhilestmt:"do" stmt "while" "(" expr ")" ";"

    expr:       expr binop expr
                    unop expr
                    expr "[" expr "]"
                    "(" expr ")"
                    expr "(" exprs ")"
                    NAME
                    INT
                    CHAR
                    STRING

    exprs:      /*empty*/
                    (expr ",")* expr

    binop:      "+" | "-" | "*" | "/" | "%" |
                    "=" |
                    "<" | "==" | "!="

    unop:       "!" | "-" | "*"

    type:       "int" stars
                    "char" stars

    stars:      "*"*
```

<hr>


Well, that is enough ranting for now.


<!--

    Copyright © 1984-2024 by Landon Curt Noll. All Rights Reserved.

    You are free to share and adapt this file under the terms of this license:

        Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)

    For more information, see:

        https://creativecommons.org/licenses/by-sa/4.0/

-->
