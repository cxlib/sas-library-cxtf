/*
* Assert that the macro variable is equal to a specified value
*
* @param variable Macro variable name
* @param value Variable scope
* @paran ígnorecase Ignore case in comparison
* @param not Negate the assertion
*
* @description 
*
* Leading and trailing spaces are removed when comparing the variable value
* to the specified value.
*
* The ignorecase parameter takes the values TRUE and FALSE. If TRUE, case
* is ignored in the comparison.
*
* The not parameter takes values TRUE and FALSE. If TRUE, the assertion
* is negated, i.e. variable is not expected to exist in the specified 
* scope. 
*
*
*/

%macro cxtf_expect_mvarequal( variable = , value = , ignorecase = FALSE, not = FALSE );
                                                     
    %* note: temporary data sets using prefix _cxtfwrk._cxtf_expect_mvareq_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_this_macro _cxtf_local_scope
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


    %* -- clean up previous artefacts ;
    proc datasets library = _cxtfwrk nolist nodetails;
      delete _cxtf_expect_mvareq_: ; run;
    quit;


    
    %* -- permitted ignorecase ;
    %if ( %sysfunc(findw( TRUE FALSE, %scan(&ignorecase, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for IGNORECASE specified );
      %goto macro_exit;
    %end;

    %* -- permitted not:s ;
    %if ( %sysfunc(findw( TRUE FALSE, %scan(&not, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for NOT specified );
      %goto macro_exit;
    %end;

    %* -- this macro ;
    %let _cxtf_this_macro = &sysmacroname ;


    %* -- define calling scope reference ;  
    %let _cxtf_local_scope = %sysmexecname( %eval( %sysmexecdepth - 1 ) );


    %* -- check if macro variable exists ;

    %let _cxtf_expect_hit = 0;

    proc sql noprint;
      select count(*) into: _cxtf_expect_hit separated by ' ' from dictionary.macros
        where ( strip(upcase(name)) = scan( strip(upcase(symget('variable'))), 1, " ") )
      ;
    quit;


    %* -- fail if variable does not exist;
    %if ( &_cxtf_expect_hit = 0 ) %then %do;
      %_cxtf_assert_fail( message = Macro variable does not exist );
      %goto macro_exit;
    %end;


    %* -- check value ;

    %let _cxtf_expect_hit = 0;

    proc sql noprint;

      %* note: use "union"-trick of force order of precedence between test macro and global scope  ; 
      create table _cxtfwrk._cxtf_expect_mvareq_varval as
        select value from dictionary.macros
           where ( upcase(strip(scope)) = upcase(strip(symget('_cxtf_local_scope'))) ) and
                 ( upcase(strip(name)) = scan( upcase(strip(symget('variable'))), 1, " " ) )
        union all
        select value from dictionary.macros
           where ( upcase(strip(scope)) = "GLOBAL" ) and
                 ( upcase(strip(name)) = scan( upcase(strip(symget('variable'))), 1, " " ) )
      ;

      %* note: just read the first observation from above union ;
      create table _cxtfwrk._cxtf_expect_mvareq_varcmp as
        select value from dictionary.macros
           where ( upcase(strip(scope)) = upcase(strip(symget('_cxtf_this_macro'))) ) and
                 ( upcase(strip(name)) = "VALUE" )
        union all
        select value from _cxtfwrk._cxtf_expect_mvareq_varval (obs = 1)
      ;


      %if ( %upcase(&ignorecase) = FALSE ) %then %do;

      select count(unique(strip(value))) into: _cxtf_expect_hit separated by ' ' 
        from _cxtfwrk._cxtf_expect_mvareq_varcmp
      ; 

      %end;


      %if ( %upcase(&ignorecase) = TRUE ) %then %do;

      select count(unique(strip(lowcase(value)))) into: _cxtf_expect_hit separated by ' ' 
        from _cxtfwrk._cxtf_expect_mvareq_varcmp
      ; 

      %end;


    quit;



    %* -- pass ; 

    %if ( ( ( %upcase(&not) = FALSE ) and ( &_cxtf_expect_hit = 1 ) ) or 
          ( ( %upcase(&not) = TRUE ) and ( &_cxtf_expect_hit = 2 ) ) ) %then %do;
      %_cxtf_assert_pass();
      %goto macro_exit;
    %end;        
              

    %* -- if not obvious pass, fail the assertion;
    %_cxtf_assert_fail( message = Macro variable value is not equal to &value );



    %* -- macro exit point;
    %macro_exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails;
        delete _cxtf_expect_mvareq_: ; run;
      quit;

    %end;                 


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
