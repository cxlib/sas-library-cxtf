/*
*  Internal method to register an assertion as failed
*
*  @param message Optional clarification of result
*  @param data Optional input data set of messages
*
*  Requires the following macro variables in the parent scope
*    CXTF_TESTID
*
*
*/

%macro _cxtf_assert_fail( message = , data = );

    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_assert_calling_macro
           _cxtf_assert_fail_count 
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




  %* -- expecting results data set ;
  %if ( %sysfunc(exist( _cxtfrsl.cxtfresults )) = 0 ) %then %do;
    %put %str(ER)ROR: cxtf results data set does not exist ;
    %_cxtf_stacktrace(); 
    %goto macro_exit;
  %end;


  %* -- identify calling macro ;
  %* note: expecting the assert fail macro is called from the assertion ;
  %let _cxtf_assert_calling_macro = %sysfunc(lowcase(%sysmexecname( %eval( %sysmexecdepth - 1 ) )));
 

  %*    direct run ;
  %if ( %symexist(cxtf_testid) = 0 ) %then %do;

     %put %str( ) ;
     %put ------------------------------------------------------------------------------- ;
     %put %sysmexecname( 1 ) %str(  ) Development mode ;
     %put %sysmexecname( 1 ) %str(  ) [%upcase(&_cxtf_assert_calling_macro)] %str(  ) Fail;
     %put ------------------------------------------------------------------------------- ;
     %put %str( ) ;

     %goto macro_exit;
  %end;




  %* -- using macro parameters ;

  %if ( &data = %str() )  %then %do;

    proc sql noprint;

      insert into _cxtfrsl.cxtfresults
            ( testid, result, assertion, message )
            values ( "%sysfunc(strip(&cxtf_testid))", "fail", "%sysfunc(strip(&_cxtf_assert_calling_macro))", "&message" )
      ;

    quit;

    %*    note failure in log ;
    %put %str(ER)ROR: [%upcase(&_cxtf_assert_calling_macro)] &message ;

  %end;



  %* -- using input data set ;

  %if ( ( &data ^= %str() ) and %sysfunc(exist(&data)) ) %then %do;

    %*    check if there are records to process ;

    %let _cxtf_assert_fail_count = 0 ;

    proc sql noprint;
      select count(distinct(message)) into: _cxtf_assert_fail_count separated by ' ' from &data 
        where not missing(message)
      ;
    quit;

    %if ( &_cxtf_assert_fail_count = 0 ) %then %goto macro_exit;


    %*    process records ;

    proc sql noprint;

      insert into _cxtfrsl.cxtfresults
        select distinct "%sysfunc(strip(&cxtf_testid))", "fail", "%sysfunc(strip(&_cxtf_assert_calling_macro))", strip(message) from &data 
          where not missing( message )
      ;

    quit;


    data _null_ ;
      set &data ;
      where not missing( message ) ;

      length calling_macro $ 50 ;
      retain calling_macro ;

      if ( _n_ = 1 ) then 
        calling_macro = upcase(strip(symget('_cxtf_assert_calling_macro')));

      put "ER" "ROR: [" calling_macro +(-1) "] " message ;

    run;


  %end; 


  %* -- macro exit point;
  %macro_exit:



  %* -- restore entry state ;
  %if ( &_cxtf_syscc ^= 0 ) %then %do;
    %let syscc = &_cxtf_syscc;
    %let sysmsg = &_cxtf_sysmsg;
  %end;


%mend;
