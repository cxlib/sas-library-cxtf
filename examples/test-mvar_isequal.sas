/*
*  Examples for testing if two macro variable values are equal 
*
*
*
*/


%macro test_vars_equal();

  %* -- stage ;
  %local var1 var2 ;

  %let var1 = Abc123;
  %let var2 = &var1;


  %* -- assertion;
  %cxtf_expect_mvarisequal( variable = var1, compare = var2 );


  %* -- no clean up as local variables are drestroyed at the end of the macro ;


%mend;



%macro test_vars_notequal();

  %* -- stage ;
  %local var1 var2 ;

  %let var1 = Abc123;
  %let var2 = %upcase(&var1);


  %* -- assertion;
  %cxtf_expect_mvarisequal( variable = var1, compare = var2, not = TRUE );


  %* -- no clean up as local variables are drestroyed at the end of the macro ;


%mend;


  
%macro test_vars_equal_ignorecase();

  %* -- stage ;
  %local var1 var2 ;

  %let var1 = Abc123;
  %let var2 = %upcase(&var1);


  %* -- assertion;
  %cxtf_expect_mvarisequal( variable = var1, compare = var2, ignorecase = TRUE );


  %* -- no clean up as local variables are drestroyed at the end of the macro ;


%mend;



%macro test_vars_equal_scopes();

  %* -- stage ;
  %global var1 ;
  %local var2 ;

  %let var1 = Abc123;
  %let var2 = &var1;


  %* -- assertion;
  %cxtf_expect_mvarisequal( variable = var1, variablescope = GLOBAL, compare = var2, comparescope = LOCAL );


  %* -- clean up ;
  %*    note: no clean up as local variables are drestroyed at the end of the macro ;

  %symdel var1 ;


%mend;


