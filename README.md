Gunzip
======

Copyright 2015 Laurens Holst

Project information
-------------------

Author: Laurens Holst <laurens.nospam@grauw.nl>  
Site: <https://bitbucket.org/grauw/gunzip>  
Issues: <https://bitbucket.org/grauw/gunzip/issues>  
License: Simplified BSD License

Extracts files compressed with the gzip (.gz) format.


System Requirements
-------------------

  * MSX, MSX2, MSX2+ or MSX turboR
  * 16kB video RAM
  * 128kB main RAM
  * MSX-DOS 2


Usage instructions
------------------

Run gunzip from MSX-DOS 2, specifying the gzipped file on the command line.

Usage:

    gunzip [options] <archive.gz> <outputfile>

Options:

  * `/t` Test the checksum after deflating.
    
    The gzip format includes a checksum, however by default this is not checked
    for performance reasons. Specify this option to perform the file integrity
    check after deflation.

If no output file is specified, the archive will be tested.

To configure Multi Mente to extract gz files, add the following line to
MMRET.DAT:

    .GZ     GUNZIP $T


Development information
-----------------------

Gunzip is free and open source software. If you want to contribute to the
project you are very welcome to. Please contact me at any one of the places
mentioned in the project information section.

You are also free to re-use code for your own projects, provided you abide by
the license terms.

Building the project with some of your own modifications is really easy on all
modern desktop platforms. On Mac OS X and Linux, simply invoke `make` to build
the binary and symbol files into the `bin` directory:

    make

Windows users can open the `Makefile` and build by pasting the line in the `all`
target into the Windows command prompt.

To launch the build in openMSX after building, put a copy of `MSXDOS2.SYS` and
`COMMAND2.COM` and some GZ files to test with in the `bin` directory, and then
invoke the `make run` command.

Note that the [glass](https://bitbucket.org/grauw/glass) assembler which is
embedded in the project requires [Java 7](http://java.com/getjava). To check
your Java version, invoke the `java -version` command.
