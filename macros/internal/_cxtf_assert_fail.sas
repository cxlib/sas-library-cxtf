/*
*  Internal utility macro to register an assertion as failed
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

    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg 
           _cxtf_debug_flg
           _cxtf_assert_calling_macro
           _cxtf_assert_fail_count 
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
    




    %* -- expecting results data set ;
    %if ( %sysfunc(exist( _cxtfrsl.cxtfresults )) = 0 ) %then %do;
        %put %str(ER)ROR: (cxtf) cxtf results data set does not exist ;
        %_cxtf_stacktrace(); 
        %goto macro_exit;
    %end;
    
    
    %* -- identify calling macro ;
    %* note: expecting the assert fail macro is called from the assertion ;
    %let _cxtf_assert_calling_macro = %sysmexecname( %eval( %sysmexecdepth - 1 ) );
    
    
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
    
    
    
    
    %* -- capture messages ;
    proc sql noprint;
      create table _cxtfwrk.__cxtf_&cxtf_testid._failmsgs (
        message char(200)
      );
    quit;


    %* -- pass through call no message and no data ;
    %if ( &message = %str() ) and ( &data = %str() ) %then %do;
        
      proc sql ;
        insert into _cxtfwrk.__cxtf_&cxtf_testid._failmsgs 
          ( message ) 
          values ( "" )
        ;
      quit;  
    
    %end;
    
   
    
    %* - message string as argument ;
    %if ( &message ^= %str() ) %then %do;

      proc sql noprint;

        %* note: assumption is that dictionary variable value is 200 characters or less in length ;
        %* note: offset = 0 means only the first 200 characters of the message is retained ;
      
        insert into _cxtfwrk.__cxtf_&cxtf_testid._failmsgs
          select strip(value) from dictionary.macros 
            where ( upcase(strip(scope)) = upcase(strip("&sysmacroname")) ) and
                  ( upcase(strip(name)) = "MESSAGE" ) and 
                  ( offset = 0 )
        ;
      
      quit;
    
    %end;
    
    
    
    
    %* -- source data set specified ;

    %if ( &data ^= %str() ) %then %do;
    
        %if ( %sysfunc(exist(&data)) = 0 ) %then %do;
            %put %str(ER)ROR: (cxtf) The internal data set %upcase(&data) does not exist;
            %_cxtf_stacktrace();
            %goto macro_exit;
        %end;    

        data _cxtfwrk.__cxtf_&cxtf_testid._fail_ds ;
          set _cxtfwrk.__cxtf_&cxtf_testid._failmsgs (where = ( 0 ) )     
              &data (rename = ( message = _msg ) );

          %* message string less than or equal to 200 characters;
          if ( klength(kstrip(_msg)) <= 200 ) then do; 
            message = kstrip(_msg);
            return;
          end;
          
          %* message string longer than 200 characters;
          message = ksubstr( kstrip(_msg), 1, 200 );
          
          keep message ;        
        run;
        
        proc sql noprint;
        
          insert into _cxtfwrk.__cxtf_&cxtf_testid._failmsgs
            select strip(message) from _cxtfwrk.__cxtf_&cxtf_testid._fail_ds
          ;
        
        quit;        
    
    %end;

    

    %* -- save messages as result ;
    
    data _cxtfwrk.__cxtf_&cxtf_testid._failrslt ;
      set _cxtfrsl.cxtfresults (where = ( 0 ) )
          _cxtfwrk.__cxtf_&cxtf_testid._failmsgs
      ;
      
      %* note: lengths and variable order set by _cxtfrsl.cxtfresults ;
            
      testid = strip(symget('cxtf_testid'));
      result = 'fail';
      assertion = strip(symget('_cxtf_assert_calling_macro'));
      
      keep testid result assertion message ;
    run;
    
    
    proc sql noprint;
        
      insert into _cxtfrsl.cxtfresults
        select testid, result, assertion, message  
          from _cxtfwrk.__cxtf_&cxtf_testid._failrslt 
          where not missing( testid ) and not missing(result)
      ;
    
    quit;



    %* -- macro exit point;
    %macro_exit:


    %* -- clean up ;
    %if ( %upcase(&_cxtf_debug_flg) = FALSE ) %then %do;

      proc datasets  library = _cxtfwrk nolist nodetails ;
        delete __cxtf_&cxtf_testid._fail: ; run;
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
