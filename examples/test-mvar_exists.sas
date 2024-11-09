/*
*  Examples for testing if a macro variable exists
*
*
*
*/


/*
* Global macro variables 
*/

%macro test_global_variable();

  %* -- only need it to exist in the global scope;
  %global myglobal ;


  %* -- assertion;
  %cxtf_expect_mvarexists( variable = myglobal, scope = global );


  %* -- clean up ;
  %symdel myglobal ;


%mend;



%macro test_not_global_variable();

  %* -- only need it to exist in the global scope;
  %local myglobal ;


  %* -- assertion;
  %*    note: if it is not global, then it must be local ;
  %cxtf_expect_mvarexists( variable = myglobal, scope = global, not = TRUE );


  %* -- no clean up as local variables are destroyed at macro exist ;


%mend;




%macro test_global_variable_notexist();

  %* -- only need it to exist in the global scope;
  %global myglobal ;


  %* -- assertion;
  %cxtf_expect_mvarexists( variable = idonotexist, scope = global, not = TRUE );


  %* -- clean up ;
  %symdel myglobal ;


%mend;



/*
* Local macro variables 
*/


%macro test_local_variable();

  %* -- only need it to exist in the local scope;
  %local mylocal ;


  %* -- assertion;
  %cxtf_expect_mvarexists( variable = mylocal, scope = local );


  %* -- no clean up as local variables are destroyed at macro exist ;
 

%mend;



%macro test_not_local_variable();

  %* -- only need it to exist in the local scope;
  %global mylocal ;


  %* -- assertion;
  %*    note: if it is not local, then it must be global ;
  %cxtf_expect_mvarexists( variable = mylocal, scope = local, not = TRUE );


  %* -- clean up ;
  %symdel mylocal ;

%mend;





%macro test_local_variable_notexist();

  %* -- only need it to exist in the local scope;
  %local mylocal ;


  %* -- assertion;
  %cxtf_expect_mvarexists( variable = idonotexist, scope = local, not = TRUE );


  %* -- no clean up as local variables are destroyed at macro exist ;
 

%mend;

