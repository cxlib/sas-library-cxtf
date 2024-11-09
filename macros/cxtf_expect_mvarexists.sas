/*
* Assert that the macro variable exists in scope
*
* @param variable Macro variable name
* @param scope Variable scope
* @param not Negate the assertion
*
* @description 
*
* Scope is either global or local. Local scope is the scope of the
* test macro.
*
* The not parameter takes values TRUE and FALSE. If TRUE, the assertion
* is negated, i.e. variable is not expected to exist in the specified 
* scope. 
*
*
*/

%macro cxtf_expect_mvarexists( variable = , scope = local, not = FALSE );


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_expect_scope  
           _cxtf_expect_hit 
    ;

    
    %_cxtf_debug( return = _cxtf_debug_flg );


    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
      %let _cxtf_syscc = &syscc;
      %let _cxtf_sysmsg = &sysmsg;

      %let syscc = 0;
      %let sysmsg = ;

    %end;


    %* -- permitted scopes ;
    %if ( %sysfunc(findw( GLOBAL LOCAL, %scan(&scope, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid macro variable scope specified );
      %goto macro_exit;
    %end;


    %* -- permitted not:s ;
    %if ( %sysfunc(findw( TRUE FALSE, %scan(&not, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for NOT specified );
      %goto macro_exit;
    %end;


    %* -- define look-up scope reference ;  
    %let _cxtf_expect_scope = GLOBAL; 

    %if ( %upcase(&scope) = LOCAL ) %then %do;
      %let _cxtf_expect_scope = %sysmexecname( %eval( %sysmexecdepth - 1 ) );
    %end;


    %* -- check if macro variable exists in scope ;

    %let _cxtf_expect_hit = 0;

    proc sql noprint;
      select count(*) into: _cxtf_expect_hit separated by ' ' from dictionary.macros
        where ( strip(upcase(scope)) = strip(upcase(symget('_cxtf_expect_scope'))) ) and
              ( strip(upcase(name)) = scan( strip(upcase(symget('variable'))), 1, " ") )
      ;
    quit;


    %* -- pass ; 

    %if ( ( ( %upcase(&not) = FALSE ) and ( &_cxtf_expect_hit > 0 ) ) or 
          ( ( %upcase(&not) = TRUE ) and ( &_cxtf_expect_hit = 0 ) ) ) %then %do;
      %_cxtf_assert_pass();
      %goto macro_exit;
    %end;        
              

    %* -- if not obvious pass, fail the assertion;
    %_cxtf_assert_fail( message = Macro variable does not exist in &scope scope );



    %* -- macro exit point;
    %macro_exit:


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
