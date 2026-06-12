/*
*  Internal utility macro to register an internal error
*
*  @param message Error message
*
*  Requires the following macro variables in the parent scope
*    CXTF_TESTID
*
*  An internal error is interpreted as a test scenario failure
*
*
*/


%macro _cxtf_error( message = );


    %local _cxtf_syscc _cxtf_sysmsg 
           _cxtf_debug_flg
           _cxtf_err_calling_macro
           _cxtf_err_sighup
    ;


    %* -- print debugging information;
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
    
    
    
    %* -- identify calling macro ;
    %* note: expecting the assert fail macro is called from the assertion ;
    %let _cxtf_err_calling_macro = %sysmexecname( %eval( %sysmexecdepth - 1 ) );
    
    
    %* -- direct run ;
    %if ( %sysfunc(upcase(&_cxtf_err_calling_macro)) = %str(OPEN CODE) ) %then %do;
    
        %put %str( ) ;
        %put ------------------------------------------------------------------------------- ;
        %put %sysfunc(upcase(&sysmacroname)) %str(  ) Development mode ;
        %put ------------------------------------------------------------------------------- ;
        %put %str( ) ;
    
    %end;
    


    %* -- expecting results data set ;
    %if ( %sysfunc(exist( _cxtfrsl.cxtfresults )) = 0 ) %then %do;
        %put %str(ER)ROR: (cxtf) Results data set does not exist ;
        %_cxtf_stacktrace(); 
        %goto macro_exit;
    %end;


    
    %* -- test id not defined ;
    %if ( %symexist(cxtf_testid) = 0 ) %then %do;
        %put %str(ER)ROR: (cxtf) Test ID (CXTF_TESTID) not defined ;
        %_cxtf_stacktrace(); 
        %goto macro_exit;
    %end;
    
    
    
    %* -- message required ;
    
    %let _cxtf_err_sighup = FALSE ;
    
    data _null_;
      set sashelp.vmacro ;
      
      %* note: use same mechanism that registers message with results ;
      
      where ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and
            ( upcase(strip(name)) = "MESSAGE" ) and
            ( offset = 0 )
      ;
      
      %* note: expecting a single record from where statement ;
      %* note: not missing, i.e. has value, DATA step exits ;
      if not missing(strip(value)) then do ;
        _str = catx( ": ", cats( "ER", "ROR"), catx( " ", "(cxtf)", value ) );
        put _str;
        return;
      end; 
      
      %* note: interrupt ;
      call symput( '_cxtf_err_sighup', "TRUE" ) ;
          
    run;      
    
    %if ( &_cxtf_err_sighup = TRUE ) %then %do;
    
      %* -- record as missing message ;
      proc sql noprint;
      
        insert into _cxtfrsl.cxtfresults
          select kstrip("&cxtf_testid"), "fail", kstrip("&_cxtf_err_calling_macro"), cats( "Er", "ror recorded with message not specified or message is an empty value" )   
            from dictionary.macros 
            where ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and
                  ( upcase(strip(name)) = "MESSAGE" ) and
                  ( offset = 0 )
        ;
      
      quit; 
    
      %put %str(ER)ROR: (cxtf) Parameter MESSAGE not specified or an empty value ; 
      
      %_cxtf_stacktrace();
      
      %goto macro_exit;
    %end;

    
    %* -- record message ;
    proc sql noprint;
    
      insert into _cxtfrsl.cxtfresults
        select kstrip("&cxtf_testid"), "fail", kstrip("&_cxtf_err_calling_macro"), kstrip(value)  
          from dictionary.macros 
          where ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and
                ( upcase(strip(name)) = "MESSAGE" ) and
                ( offset = 0 )
      ;
    
    quit; 



    %* -- macro exit point;
    %macro_exit:


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
    
      %let syscc = &_cxtf_syscc;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do;
          %let sysmsg = &_cxtf_sysmsg;
      %end;
          
    %end;
    

%mend;