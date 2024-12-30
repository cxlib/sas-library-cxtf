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


 

    %* -- parse log ;

    data _cxtfwrk.__cxtf_&cxtf_testid._logfail
         _cxtfwrk.__cxtf_&cxtf_testid._logpass
         _cxtfwrk.__cxtf_&cxtf_testid._logres;
      set _cxtfwrk.__cxtf_&cxtf_testid._log ;

      %*    note: psuedo line key ;
      key = _n_ ;

      length msgclass $ 10 message $ 200;
      retain prx_err_w_code -1;

      if ( _n_ = 1 ) then
        prx_err_w_code = prxparse( cats("/^ER", "ROR [0-9\-]+:/") );

      call missing( msgclass ) ;

 
      %* generic er.ror check ;
      if ( ( logline =: cats( "ER", "ROR:" ) ) and ( find( upcase(logline), "[CXTF_EXPECT_" ) = 0 ) ) then do;
        msgclass = cats( "er", "ror") ;
        message = strip(ksubstr( strip(logline), klength(cats( "ER", "ROR:" )) + 1 ));
        output _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
      end;


      %* generic er.ror check with code;
      %* note: no colon in the substring ;
      if ( prxmatch( prx_err_w_code, strip(logline) ) ) then do;
        msgclass = cats( "er", "ror");
        message = strip(ksubstr( strip(logline), kfindc(strip(logline), ":") + 1 ));
        output _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
      end;


      %* generic wa.rning check ;
      if ( logline =: cats( "WA", "RNING:" ) ) then do;
        msgclass = cats( "wa", "rning");
        message = strip(ksubstr( strip(logline), klength(cats( "WA", "RNING:" )) + 1 ));
        output _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
      end;


      %* all records ;
      output _cxtfwrk.__cxtf_&cxtf_testid._logres ;
    run;



    %* -- check for log failures ;
    %*    note: no hits ... then exit ;

    %let _logfail = 0;
   
    proc sql noprint;
      select count(*) into: _logfail separated by  ' ' from _cxtfwrk.__cxtf_&cxtf_testid._logfail ;
    quit;

    %if ( &_logfail = 0 ) %then %goto assert_log_pass ;



    %* <-- from here we have log failures ;


    %* -- get annotations for test ;
    %*    note: only interested in e.r.r.o.r.s and w.a.r.n.i.n.g.s ;

    proc sql noprint;

      create table _cxtfwrk.__cxtf_&cxtf_testid._anno as
        select testid, type, reference, cmdargs from _cxtfrsl.cxtftestidx 
          where ( strip(testid) = strip("&cxtf_testid") ) and
                ( strip(type) = "annotation" ) and
                ( strip(reference) in ( "error", "warning" ) ) 
     ;

    quit;


    %* -- process log entries with missing annotations ;

    %let _logfail = 0 ;

    proc sql noprint;

      create table _cxtfwrk.__cxtf_&cxtf_testid._noanno as
        select distinct message from _cxtfwrk.__cxtf_&cxtf_testid._logfail
          where ( strip(msgclass) in ( "error", "warning" ) ) and 
                ( strip(msgclass) not in (select distinct strip(reference) from _cxtfwrk.__cxtf_&cxtf_testid._anno) )
      ;

      select count(*) into: _logfail separated by " " from _cxtfwrk.__cxtf_&cxtf_testid._noanno ;

    quit;


    %if ( &_logfail ^= 0 ) %then %do;
      %_cxtf_assert_fail( data = _cxtfwrk.__cxtf_&cxtf_testid._noanno);
      %goto macro_exit ;
    %end;



    %* -- process log entries with annotations ;

    data _cxtfwrk.__cxtf_&cxtf_testid._annohits ;

      %*    reverse lookup ;
      %*    note: we want to know if expected messages are there ;

      %*    set up hash object ;
      %*    note: iterating over actual log messages ;
      length msgclass $ 10 message $ 200 ;

      if ( _n_ = 1 ) then do;
          declare hash obj( dataset: "_cxtfwrk.__cxtf_&cxtf_testid._logfail" );
          obj.definekey( 'key');
          obj.definedata( 'msgclass', 'message');
          obj.definedone();

          call missing( key, msgclass, message );

          %*    note: iterating over the hash table ;
          declare hiter iterobj('obj');
      end;


      %*    read in expected messages ;
      set _cxtfwrk.__cxtf_&cxtf_testid._anno ;

      expected_any = 0 ;
      expected_msg = 0 ;

      rc = iterobj.first();

      do until( rc ^= 0 );

        %*    message not the same class as in our reference ;
        %*    note: example e.r.r.o.r versus w.a.r.n.i.n.g ;
        if ( strip(msgclass) ^= strip(reference) ) then do;
          call missing( key, msgclass, message );
          rc = iterobj.next();
          continue;
        end; 

        %*    if no specific message is specified, at least one is expected whatever message ;
        if ( missing(cmdargs) ) then do ;
          expected_any = 1;
          call missing( key, msgclass, message );
          rc = iterobj.next();
          continue;
        end;


        %*    message is shorter than expected ... i.e. expected has more information;
        %*    note: regexp coming .. just not yet ;
        if ( klength(strip(message)) < klength(strip(cmdargs)) ) then do;
          call missing( key, msgclass, message );
          rc = iterobj.next();
          continue;
        end;

        %*     message is expected ;
        %*     note: ignore case ;
        %*     note: matching as starts with expected message ;
        if ( lowcase(ksubstr( strip(message), 1, klength(strip(cmdargs)) )) = lowcase(strip(cmdargs)) ) then 
          expected_msg = 1 ;


        %*    move pointer to next message ;
        call missing( key, msgclass, message );
        rc = iterobj.next();
      end;

      keep testid reference type cmdargs expected_msg expected_any ;

    run;


    %*    when the specified message is expected ;

    data _cxtfwrk.__cxtf_&cxtf_testid._expfail ;
      set _cxtfwrk.__cxtf_&cxtf_testid._annohits  ;
      where ( expected_msg ^= 1 ) and ( expected_any = 0 );

      length str $ 4096 message $ 200 ;

      str = catx( " ", "Expecting ", reference, strip(cmdargs) ) ;

      if ( klength(strip(str)) <= 200 ) then 
        message = strip(str) ;
      else
        message = catx( " ", ksubstr( strip(str), 1, 195 ), "..." );

    run;


    %let _logfail = 0 ;

    proc sql noprint;
      select count(*) into: _logfail separated by " " from _cxtfwrk.__cxtf_&cxtf_testid._expfail ;
    quit;

    %if ( &_logfail ^= 0 ) %then %do;
      %_cxtf_assert_fail( data = _cxtfwrk.__cxtf_&cxtf_testid._expfail );
      %goto macro_exit ;
    %end;


    %*    when any message is expected ;

    data _cxtfwrk.__cxtf_&cxtf_testid._anyfail ;
      set _cxtfwrk.__cxtf_&cxtf_testid._annohits  ;
      where missing(cmdargs) and 
           ( expected_any ^= 1 );

      length message $ 200 ;

      message = catx( " ", "Expected at least one ", reference ) ;

    run;


    %let _logfail = 0 ;

    proc sql noprint;
      select count(*) into: _logfail separated by " " from _cxtfwrk.__cxtf_&cxtf_testid._anyfail ;
    quit;

    %if ( &_logfail ^= 0 ) %then %do;
      %_cxtf_assert_fail( data = _cxtfwrk.__cxtf_&cxtf_testid._anyfail );
      %goto macro_exit ;
    %end;


    %* -- all ok in the log at this point ;
    %_cxtf_assert_pass();


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
