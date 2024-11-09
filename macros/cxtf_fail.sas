/*
* Register test as obviously failed
*
* @param message Optional message 
*
*
*
*
*/

%macro cxtf_check_fail( message = );

  %_cxtf_assert_fail( message = &message );


%mend;
