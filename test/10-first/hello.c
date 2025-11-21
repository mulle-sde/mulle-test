#include <stdio.h>

int   main( int argc, char *argv[])
{
   int   i;
   int   c;
   char  *sep;

   sep = "";
   for( i = 1; i < argc; i++)
   {
      printf( "%s%s", sep, argv[ i]);
      sep = " ";
   }
   if( *sep)
      printf( "\n");

    while((c = getchar()) != EOF)
    {
       putchar(c);
    }
    fflush( stdout);
    return 0;
}
