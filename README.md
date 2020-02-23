Gunzip
======

Copyright 2015 Laurens Holst

Thanks go to Wouter Vermaelen, Louthrax and bore for support and contributions.

Project information
-------------------

Extracts files compressed with the gzip (.gz) format.

  * Author: Laurens Holst <laurens@grauw.nl>
  * Site: <http://www.grauw.nl/projects/gunzip/>
  * Source: <https://hg.sr.ht/~grauw/gunzip>
  * Support: <http://www.msx.org/forum/msx-talk/software/gunzip-msx>
  * License: Simplified BSD License


System requirements
-------------------

  * MSX, MSX2, MSX2+ or MSX turboR
  * 64K main RAM
  * 16K video RAM
  * MSX-DOS 2


Usage instructions
------------------

Run gunzip from MSX-DOS 2, specifying the gzipped file on the command line.

Usage:

    gunzip [options] <archive.gz> <outputfile>

Options:

  * `/q` Quiet, suppress messages.
    
    Suppresses the output of informational and warning messages.
    Error messages, however, are always output.

  * `/f` Fast, no checksum validation.
    
    Disables checksum validation which increases inflation speed.
    Use at your own risk.

If no output file is specified, the archive will be tested.


Development information
-----------------------

Gunzip is free and open source software. If you want to contribute to the
project you are very welcome to. Please contact me at any one of the places
mentioned in the project information section.

You are also free to re-use code for your own projects, provided you abide by
the license terms.

Building the project is easy on all modern desktop platforms. On macOS and
Linux, simply invoke `make` to build the binary and symbol files into the
`bin` directory:

    make

Windows users can open the `Makefile` and build by pasting the lines in the
`all` target to the Windows command prompt.

To launch the build in openMSX after building, put a copy of `MSXDOS2.SYS` and
`COMMAND2.COM` and some GZ files to test with in the `bin` directory, and then
invoke the `make run` command.

Note that the [glass](http://www.grauw.nl/projects/glass/) assembler which is
embedded in the project requires [Java 8](http://java.com/getjava). To check
your Java version, invoke the `java -version` command.

Additionally, [Node.js](https://nodejs.org/) is required. Download it from their
website or install it through your favourite package manager.
