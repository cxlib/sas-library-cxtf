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

   %* note: temporary data sets using prefix _cxtfwrk.__cxtf_err_* ;


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
    
    
    %* -- post message to log ;
    data _null_;
      set sashelp.vmacro ;
      
      %* - note offset = 0 .. only first 200 characters ;      
      where ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and
            ( upcase(strip(name)) = "MESSAGE" ) and
            ( offset = 0 )
      ;
    
    
      if ( _n_ > 1 ) then do;
        put "ER" "ROR: (cxtf) More than one record returned with message";
      end;
      
    
      length _msg $ 200 _str $ 250 ;
    
      %* - default message ;
      _msg = catx( " ", cats("Er", "ror"), "message not specified" ) ;
      
      
      if ( not missing(kstrip(value)) ) then 
        _msg = kstrip(value);
        
      
      %* - add message to log ;
      _str = catx( ": ", cats( "ER", "ROR"), catx( " ", "(cxtf)", _msg ) );
      put _str;
      
    run;
    
    
    
    %* -- register message with results ;
    
    %* - expecting framework work library  ;
    %if ( %sysfunc(libref(_cxtfwrk)) ^= 0 ) %then %do;
      %put %str(ER)ROR: (cxtf) Framework work library does not exist ;
      %_cxtf_stacktrace(); 
      %goto macro_exit;
    %end;
    
    
    %* - expecting results data set ;
    %if ( %sysfunc(exist( _cxtfrsl.cxtfresults )) = 0 ) %then %do;
        %put %str(ER)ROR: (cxtf) Results data set does not exist ;
        %_cxtf_stacktrace(); 
        %goto macro_exit;
    %end;
    
    
    
    %* - determine qualified message ;
    
    data _cxtfwrk.__cxtf_err_msg ; 
      set sashelp.vmacro  end = eof ;

      %* - note offset = 0 .. only first 200 characters ;      
      where ( upcase(strip(name)) in ( "CXTF_TESTID",  "MESSAGE", "_CXTF_ERR_CALLING_MACRO" ) ) and
            ( offset = 0 )
      ;
   
   
      length testid $ 50 result $ 5 assertion message $ 200 ;
      retain testid result assertion message ;
    
      %* - defaults ;
      if ( _n_ = 1 ) then do ;
      
        %* - defensive initialise as empty ;
        call missing( testid, result, assertion, message );
      
        testid = "undefined" ;
        result = "fail";
        assertion = "undefined";
        message = catx( " ", cats("Er", "ror"), "message not specified" );
      end;

      %* - test ID ;      
      if ( ( upcase(strip(scope)) = "GLOBAL" ) and 
           ( upcase(strip(name)) = "CXTF_TESTID" ) and 
           not missing(kstrip(value)) ) then 
        testid = kstrip(value);
      
      %* - assertion ... calling macro ;  
      if ( ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and 
           ( upcase(strip(name)) = "_CXTF_ERR_CALLING_MACRO" ) and
           not missing(kstrip(value)) ) then 
        assertion = kstrip(value);
        
        
      %* - message ;  
      if ( ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and 
           ( upcase(strip(name)) = "MESSAGE" ) and 
           not missing(kstrip(value)) ) then 
        message = kstrip(value);
        
      
      %* - keep last record ... note retain ;
      if eof then output;
    
      keep testid result assertion message ;
    run;
    
    
    
    %* - register results ;
    
    proc sql noprint;
    
      insert into _cxtfrsl.cxtfresults
        select kstrip(testid), result, kstrip(assertion), kstrip(message)  
          from _cxtfwrk.__cxtf_err_msg 
      ;
    
    quit; 

    


    %* -- macro exit point;
    %macro_exit:


    %if ( %upcase(&_cxtf_debug_flg) = FALSE ) %then %do;
      proc datasets  library = _cxtfwrk nolist nodetails;
        delete __cxtf_err_: ; run;
      quit;
    %end;



    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
    
      %let syscc = &_cxtf_syscc;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do;
          %let sysmsg = &_cxtf_sysmsg;
      %end;
          
    %end;
    

%mend;