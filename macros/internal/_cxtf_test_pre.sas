/*
* Internal utility macro for pre-processing test scenario 
*
*
*/


%macro _cxtf_test_pre();

    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_[cxtf_testid]_pre* ;

    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _dstestinv
           _testlog
    ;

    %cxtf_debug( return = _cxtf_debug_flg );


    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
    
      %let _cxtf_syscc = &syscc;
      %let syscc = 0;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do; 
          %let _cxtf_sysmsg = &sysmsg;
          %let sysmsg = ;
      %end;

    %end;


    *% -- test id required ;
    %if ( %symexist(cxtf_testid) = 0 ) %then %do;
      %put %str(ER)ROR: (cxtf) Expected CXTF_TESTID not defined;
      %_cxtf_stacktrace();
      %goto macro_exit;
    %end;


    %* -- clean prior artifacts ;
    proc datasets  library = _cxtfwrk nolist nodetails ;
      delete test_&cxtf_testid._: ; run;
    quit;



    %* -- inventory WOEK.SASMAC* ;

    %let _dstestinv = _cxtfwrk.test_&cxtf_testid._pre ;

    proc sql noprint;

       create table &_dstestinv as 
         select catx( ".", libname, memname) as catalog length=32, objname as name, catx( ".", libname, memname, objname) as ref length=200 from dictionary.catalogs 
           where ( upcase(strip(libname)) = "WORK" ) and
                 ( upcase(strip(memtype)) = "CATALOG" ) and
                 ( upcase(strip(objtype)) = "MACRO" )
       ;

    quit;


    %* -- test log ;
    %* note: naming of test log very predictable ;

    %let _testlog = %sysfunc(pathname(_cxtfwrk))/test_&cxtf_testid..log ;

    %if ( %upcase(&_cxtf_debug_flg) = TRUE ) %then 
      %put %str(DEBUG) Test log is &_testlog ;
 

    proc printto log = "&_testlog";
    run;


    %* -- macro exit point ;
    %macro_exit:



    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
    
      %let syscc = &_cxtf_syscc;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do;
          %let sysmsg = &_cxtf_sysmsg;
      %end;
          
    %end;



%mend;
