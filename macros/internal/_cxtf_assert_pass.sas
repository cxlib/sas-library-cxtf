/*
*  Internal method to register an assertion as passed
*
*  @param message Optional clarification of result
*  @param data Optional input data set of messages
*
*  Requires the following macro variables in the parent scope
*    CXTF_TESTID
*
*/


%macro _cxtf_assert_pass( message =, data = );


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_assert_calling_macro 
    ;


    %* -- print debugging information;
    %_cxtf_debug( return = _cxtf_debug_flg  );

    
    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
      %let _cxtf_syscc = &syscc;
      %let _cxtf_sysmsg = &sysmsg;

      %let syscc = 0;
      %let sysmsg = ;

    %end;




    %* -- expecting the test is identified ;
    %if ( %symexist(cxtf_testid) = 0 ) %then %do;
      %put %str(ER)ROR: cxtf test ID not defined ;
      %_cxtf_stacktrace(); 
      %goto macro_exit;
    %end;


  %* -- expecting results data set ;
  %if ( %sysfunc(exist( _cxtfrsl.cxtfresults )) = 0 ) %then %do;
    %put %str(ER)ROR: cxtf results data set does not exist ;
    %_cxtf_stacktrace(); 
    %goto macro_exit;
  %end;


  %* -- identify calling macro ;
  %* note: expecting the assert fail macro is called from the assertion ;
  %let _cxtf_assert_calling_macro = %sysfunc(lowcase(%sysmexecname( %eval( %sysmexecdepth - 1 ) )));
 
  proc sql noprint;


  %if ( &data = %str() )  %then %do;

    insert into _cxtfrsl.cxtfresults
          ( testid, result, assertion, message )
          values ( "%sysfunc(strip(&cxtf_testid))", "pass", "%sysfunc(strip(&_cxtf_assert_calling_macro))", "&message" )
    ;

  %end;


  %if ( ( &data ^= %str() ) and %sysfunc(exist(&data)) ) %then %do;

    insert into _cxtfrsl.cxtfresults
      select "%sysfunc(strip(&cxtf_testid))", "pass", "%sysfunc(strip(&_cxtf_assert_calling_macro))", strip(message) from &data 
        where not missing( message )
    ;

  %end; 

  quit;


  %* -- macro exit point;
  %macro_exit:



  %* -- restore entry state ;
  %if ( &_cxtf_syscc ^= 0 ) %then %do;
    %let syscc = &_cxtf_syscc;
    %let sysmsg = &_cxtf_sysmsg;
  %end;



%mend;

