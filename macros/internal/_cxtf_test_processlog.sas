/*
* Post-process test log
*
*
*/

%macro _cxtf_test_processlog();

   %* note: temporary data sets using prefix _cxtfwrk.__cxtf_[cxtf_testid]_log_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _testlog  _dslog _dsresults 
           _logfail
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


    *% -- test id required ;
    %if ( %symexist(cxtf_testid) = 0 ) %then %do;
      %put Expected CXTF_TESTID not defined;
      %goto macro_exit;
    %end;


    %* -- test log ;
    %* note: naming of test log very predictable ;

    %let _testlog = %sysfunc(pathname(_cxtfwrk))/test_&cxtf_testid..log ;

    %if ( &_cxtf_debug_flg ) %then %do;
      %put %str(DEBUG): Test log &_testlog ;
    %end;


    %if ( %sysfunc(fileexist( &_testlog )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = No test log to process );
      %put %str(DEBUG): No log to process ;
      %goto macro_exit ;
    %end;


    %* -- read log ;
    data _cxtfwrk.__cxtf_&cxtf_testid._log;
       
       length logline $ 4096 ;

       infile "&_testlog" ;
       input;

       lineno = _n_ ;
       logline = _infile_ ;

    run;


 

    %* -- process log ;

    data _cxtfwrk.__cxtf_&cxtf_testid._logfail
         _cxtfwrk.__cxtf_&cxtf_testid._logpass
         _cxtfwrk.__cxtf_&cxtf_testid._logres;
      set _cxtfwrk.__cxtf_&cxtf_testid._log ;


      length classify $ 10 message $ 200;
      retain prx_err_w_code -1;

      if ( _n_ = 1 ) then
        prx_err_w_code = prxparse( cats("/^ER", "ROR [0-9-]+:/") );

      call missing( classify ) ;

 
      %* generic er.ror check ;
      if ( ( logline =: cats( "ER", "ROR:" ) ) and ( find( upcase(logline), "[CXTF_EXPECT_" ) = 0 ) ) then do;

        message = strip(ksubstr( strip(logline), klength(cats( "ER", "ROR:" )) + 1 ));
        output _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
      end;


      %* generic er.ror check with code;
      %* note: no colon in the substring ;
      if ( prxmatch( prx_err_w_code, strip(logline) ) ) then do;

        message = strip(ksubstr( strip(logline), klength(cats( "ER", "ROR" )) + 1 ));
        output _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
      end;


      %* generic wa.rning check ;
      if ( logline =: cats( "WA", "RNING:" ) ) then do;

        message = strip(ksubstr( strip(logline), klength(cats( "WA", "RNING:" )) + 1 ));
        output _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
      end;


      %* all records ;
      output _cxtfwrk.__cxtf_&cxtf_testid._logres ;
    run;


    %let _logfail = 0;
   
    proc sql noprint;
      select count(*) into: _logfail separated by  ' ' from _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
    quit;


    %if ( &_logfail ^= 0 ) %then %do;
      %_cxtf_assert_fail( data = _cxtfwrk.__cxtf_&cxtf_testid._logfail );
      %goto macro_exit ;
    %end;


    %* -- all ok in the log at this point ;
    %* %_cxtf_assert_pass();


    %* -- macro exit point ;
    %macro_exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;
      proc datasets library = _cxtfwrk nolist nodetails;
        delete __cxtf_&cxtf_testid._log: ; run;
      quit;
    %end;


    %* TODO ... remove _testlog  ;


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
