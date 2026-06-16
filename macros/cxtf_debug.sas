/*
* Utility macro to post debug information in the log
*
* @param return (optinal) Macro variable name to return debug 
*               setting
*
* @decription
*
* The debug setting returned by cxtf_debug is equal to TRUE if
* debug mode is enabled (DEBUG option set with cxtf_options)
* and FALSE if debug mode is disabled (NODEBUG option set 
* with cxtf_options).  
*
*

*/

%macro cxtf_debug( return = );


  %global cxtf_options ;

  %local ___cxtf_debug_flag
         ___cxtf_mname
         ___cxtf_i 
  ;



  %* -- derive flag variable ;
  %let ___cxtf_debug_flag = FALSE ; 
  
  %if ( %sysfunc(findw( &cxtf_options, %str(DEBUG))) > 0 ) %then 
	  %let ___cxtf_debug_flag = TRUE ;
	  

  %* -- return debug flag ;
  %*    note: TRUE represents debug mode enabled ;
  %*    note: FALSE represents debug mode disabled (default) ;
  
  %if ( &return ^= %str() ) %then %do;
    %let &return = &___cxtf_debug_flag ;
  %end;

  
  %* -- no debug here ;
  %if ( &___cxtf_debug_flag = FALSE ) %then %goto macro_exit ;



  %* -- debug mode ;
  
  %let ___cxtf_mname = %sysmexecname( %eval( %sysmexecdepth - 1) ) ;


  %put %str(DEBUG) ------------------------------------------------------------;

  %if ( %sysfunc(upcase(&___cxtf_mname)) = %str(OPEN CODE) ) %then %do;
  
    %* - direct run ;
    %put %str(DEBUG) Development mode ;
    
  %end; %else %do;
  
    %* - nested call ;
    %put %str(DEBUG) Macro %str( ) &___cxtf_mname ;

    %if ( %sysmexecdepth > 2 ) %then %do;
      
        %do ___cxtf_i = %eval( %sysmexecdepth - 2 ) %to 1 %by -1;
            %put %str(DEBUG) ... called from %str( ) %sysmexecname( &___cxtf_i ) ;
        %end;
        
    %end;
    
  %end;
  
  %put %str(DEBUG) ;
  
  
  %* -- system condition code ;
  
  %put %str(DEBUG) SYSCC = &syscc;
  
  %if ( %symexist(SYSMSG) = 1 ) %then %do; 
	  %put %str(DEBUG) SYSMSG = &sysmsg;
  %end;
  
  %put %str(DEBUG) ;
  
  
  %* -- test id ;
  
  %if ( %symexist(cxtf_testid) = 1 ) %then %do;
    %* - defined test id ;
    
    %if ( &cxtf_testid ^= %str() ) %then %do;
      %put %str(DEBUG) Test ID (CXTF_TESTID) equal to %sysfunc(upcase(&cxtf_testid)) ;
    %end; %else %do;
      %put %str(DEBUG) Test ID (CXTF_TESTID) has no value assigned ;
    %end; 
  
  %end; %else %do;
  
    %* - test id not defined ;
    %put %str(DEBUG) Test ID (CXTF_TESTID) not defined ;
    
  %end;
  
  
  %put %str(DEBUG) ------------------------------------------------------------;


  %* -- macro exit point;
  %macro_exit:


%mend;

