#import <<|PROJECT_NAME|>/<|PROJECT_NAME|>.h>


int   main( int argc, char *argv[])
{
#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif

   // needs MulleFoundation, if this is just linked with MulleObjC this will
   // crash
   mulle_printf( "%@\n", @"VfL Bochum <missing number, please fix>");
   return( 0);
}
