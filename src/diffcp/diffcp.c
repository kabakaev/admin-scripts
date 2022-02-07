/*

Written by ridgy, see https://unix.stackexchange.com/a/343834/151923
License: MIT
SPDX-License-Identifier: MIT
See also https://meta.stackexchange.com/questions/271080

Small program to blockwise compare two files and write different
blocks from file1 to file2.

This program is useful for regular backup of disk images:
- Incremental backup of entire drive is possible if a backup target is saved on an LVM volume with a snapshot.
- Backup to a USB3 spinning disk is 2 times faster, because reading is much faster (200MB/s) than writing (90MB/s).
- Backup to an SSD disk will not override unchanged blocks, which prevents unnecessary wear.

Arguments: file1, file2, blocksize in bytes
If blocksize is not given, it is set to 512 (minimum)

No error checking, no intensive tests run - use at your own risk! 

Compile:
  gcc -o diffcp diffcp.c
This command will create a "diffcp" file in the current folder.

*/

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

int main(argc, argv)
int argc;
char *argv[];
{

  char *fnamein;                  /* Input file name */
  char *fnameout;                 /* Output file name */
  char *bufin;                    /* Input buffer */
  char *bufout;                   /* Output buffer */
  int bufsize;                    /* Buffer size (blocksize) */
  int fdin;                       /* Input file descriptor*/
  int fdout;                      /* Output file descriptor*/
  int cnt;                        /* Current block # */

  /* Argument processing */

  if (argc < 3 || argc > 4) {
    fprintf(stderr,"Usage: %s infile outfile [bufsize]\n", argv[0]);
    exit(1);
  }

  fnamein = argv[1];
  fnameout = argv[2];
  if (argc == 4) {
    bufsize = atoi(argv[3]);
    if (bufsize < 512) {
      fprintf(stderr,"Error: Illegal value for [bufsize]: %s\n", argv[3]);
      exit(1);
    }
  } else {
    bufsize = 512;
  }

  fprintf(stderr, "Copying differing blocks from '%s' to '%s', blocksize is %i\n", fnamein, fnameout, bufsize);

  if (! ((bufin = malloc(bufsize)) && (bufout = malloc(bufsize)))) {
    fprintf(stderr,"Error: Can't allocate buffers: %i\n", bufsize);
    exit(1);  
  }
  fdin = open(fnamein, O_RDONLY);
  if (fdin < 0) {
    fprintf(stderr,"Error: Can't open input file: %s\n", fnamein);
    exit(1);  
  }

  fdout = open(fnameout, O_RDWR | O_SYNC);
  if (fdout < 0) {
    fprintf(stderr,"Error: Can't open ouput file: %s\n", fnameout);
    exit(1);  
  }

  cnt = 0;
  while (read(fdin, bufin, bufsize) == bufsize) {
    if (read(fdout, bufout, bufsize) == bufsize) {
      if (memcmp(bufin, bufout, bufsize) != 0) {
        fprintf(stderr, "Differing blocks at block # %i; writing block to %s\n", cnt, fnameout);
        if (lseek(fdout, -bufsize, SEEK_CUR) > -1) {
          if (write(fdout, bufin, bufsize) != bufsize) {
            fprintf(stderr,"Error: Unable to write to output file %s block # %i\n", fnameout, cnt);
            exit(1);
          }
        } else {
          fprintf(stderr,"Error: Unable to seek to output file %s block # %i\n", fnameout, cnt);
          exit(1);
        }
      }
    } else {
      fprintf(stderr,"Error: Unable to read from ouput file %s block # %i\n", fnameout, cnt);
      exit(1);
    }
    cnt++;
  }

  exit(0);
}
