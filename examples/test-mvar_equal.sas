/*
*  Examples for testing if a macro variable value is equal to a specified value
*
*
*
*/



%macro test_value_equal();

  %local mvar ;

  %let myvar = 10 ;

  %* -- assertion;
  %cxtf_expect_mvarequal( variable = myvar, value = 10 );


%mend;



%macro test_value_equal_ignorecase();

  %local mvar ;

  %let myvar = MyValue ;

  %* -- assertion;
  %cxtf_expect_mvarequal( variable = myvar, value = MYVALUE, ignorecase = TRUE );


%mend;



%macro test_value_notequal();

  %local mvar ;

  %let myvar = MyValue ;

  %* -- assertion;
  %cxtf_expect_mvarequal( variable = myvar, value = MYVALUE, ignorecase = FALSE, not = TRUE );


%mend;



