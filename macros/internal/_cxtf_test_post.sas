/*
* Post-processing for test 
*
*
*/


%macro _cxtf_test_post();

   %* note: temporary data sets using prefix _cxtfwrk.__cxtf_[cxtf_testid]_post_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _dspreinv _dsmtx _dsresults
           _testlog
           _test_numassertions
    ;




    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
      %let _cxtf_syscc = &syscc;
      %let _cxtf_sysmsg = &sysmsg;

      %let syscc = 0;
      %let sysmsg = ;

    %end;


    *% -- diable test log ;
    proc printto ;
    run;


    %_cxtf_debug( return = _cxtf_debug_flg );


    *% -- test id required ;
    %if ( %symexist(cxtf_testid) = 0 ) %then %do;
      %put Expected CXTF_TESTID not defined;
      %goto macro_exit;
    %end;


    %* -- replay test log ;
    %let _testlog = %sysfunc(pathname(_cxtfwrk))/test_&cxtf_testid..log ;

    %if ( &_cxtf_debug_flg ) %then %do;
      %put %str(DEBUG): Test log &_testlog ;
    %end;


    %if ( %sysfunc(fileexist( &_testlog )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = No test log );
      %put %str(ER)ROR: No log to process ;
      %goto macro_exit ;
    %end;




    data _cxtfwrk.__cxtf_&cxtf_testid._post_log;
       
       length logline $ 4096 ;

       infile "&_testlog" ;
       input;

       logline = _infile_ ;

       keep logline ;
    run;


    data _null_;
      set _cxtfwrk.__cxtf_&cxtf_testid._post_log  end = eof ; 

      if ( _n_ = 1 ) then 
         put "----------                       ----------------------------------------------------------" /
             "----------   begin of test log   ----------------------------------------------------------" /
             "----------                       ----------------------------------------------------------";

      put logline ;

      if eof then 
         put "----------                       ----------------------------------------------------------" /
             "----------   end of test log     ----------------------------------------------------------" /
             "----------                       ----------------------------------------------------------";
    run;


    %* -- inventory WOEK.SASMAC* ;

    %let _dspreinv = _cxtfwrk.test_&cxtf_testid._pre ;

    proc sql noprint;

       create table _cxtfwrk.__cxtf_&cxtf_testid._post_inv as 
         select catx( ".", libname, memname) as catalog length=32, objname as name, catx( ".", libname, memname, objname) as ref length=200 from dictionary.catalogs 
           where ( upcase(strip(libname)) = "WORK" ) and
                 ( upcase(strip(memtype)) = "CATALOG" ) and
                 ( upcase(strip(objtype)) = "MACRO" )
       ;

       create table _cxtfwrk.__cxtf_&cxtf_testid._post_diff as 
          select catalog, name, ref from _cxtfwrk.__cxtf_&cxtf_testid._post_inv
             where ( ref not in ( select ref from &_dspreinv ) )
             order by catalog
       ;

    quit;



    %* -- clean up macro caches ;

    data _null_;
      set _cxtfwrk.__cxtf_&cxtf_testid._post_diff ;
      where ( not( upcase(strip(name)) =: "CXTF_" or
                   upcase(strip(name)) =: "_CXTF_" ) );
      by catalog ;

      if first.catalog then do;
        call execute( catx( " ", "proc catalog  catalog = ", strip(catalog), " entrytype= macro ;" ) );
        call execute( "  delete " );
      end;

      call execute( "  " || strip(name) ); 

      if last.catalog then do;
        call execute( "  ; run;" );
        call execute( "quit;" );
      end;

    run;



    %* -- test log;
    %_cxtf_test_processlog();


    %* -- check for empty test ;
    %let _test_numassertions = 0 ;

    proc sql noprint;
       select count(*) into: _test_numassertions separated by ' ' 
         from (select * from _cxtfrsl.cxtfresults
                 where ( testid = symget( 'cxtf_testid' ) ) )
       ;
    quit;



    %if ( &_test_numassertions = 0 ) %then %do;
      %_cxtf_assert_fail( message = Empty test );
      %put %str(ER)ROR: Empty test;
    %end; 




    %* -- add test report to the log ;
    %_cxtf_test_reporter();



    %* -- macro exit point ;
    %macro_exit:

    
    %* -- clean up ;
    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets  library = _cxtfwrk nolist nodetails ;
        delete __cxtf_&cxtf_testid._: ; run;
        delete test_&cxtf_testid._pre ; run;
      quit;

    %end;

    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;

%mend;
