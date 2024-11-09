/*
*  Examples for testing if variable exists in a data set
*
*
*
*/


%macro test_var_exists();


  %* -- stage a data set ;

  proc sql noprint;
    create table work.test_var_exists (
      variable1 char(200),
      variable2 num
    );

  quit;


  %* -- assertion ;
  %cxtf_expect_varexists( data = work.test_var_exists, variables = variable1 );


  %* -- clean up ;
  proc datasets library = work  nolist nodetails ;
    delete test_var_exists ;  run;
  quit;


%mend;



%macro test_var_not_exists();


  %* -- stage a data set ;

  proc sql noprint;
    create table work.test_var_exists (
      variable1 char(200),
      variable2 num
    );

  quit;


  %* -- assertion ;
  %cxtf_expect_varexists( data = work.test_var_exists, variables = variable99, not = TRUE );


  %* -- clean up ;
  proc datasets library = work  nolist nodetails ;
    delete test_var_exists ;  run;
  quit;


%mend;



%macro test_multivar_exists();


  %* -- stage a data set ;

  proc sql noprint;
    create table work.test_var_exists (
      variable1 char(200),
      variable2 num, 
      variable3 char(200)
    );

  quit;


  %* -- assertion ;
  %cxtf_expect_varexists( data = work.test_var_exists, variables = variable1 variable2 );


  %* -- clean up ;
  proc datasets library = work  nolist nodetails ;
    delete test_var_exists ;  run;
  quit;


%mend;

