/*
* Assert that two macro variables are equal 
*
* @param variable First macro variable name
* @param variablescope Scope of variable
* @paran compare Second macro variable name
* @param comparescope Scope of compare variable 
* @paran ígnorecase Ignore case in comparison
* @param not Negate the assertion
*
* @description 
*
* Leading and trailing spaces are removed when comparing the variable value
* to the specified value.
*
* The scopes variablescope and comparescope takes the values LOCAL or GLOBAL with 
* the LOCAL scope representing the test macro.
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

%macro cxtf_expect_mvarisequal( variable = , variablescope = local, compare = , comparescope = local, ignorecase = FALSE, not = FALSE );
                                                     
    %* note: temporary data sets using prefix _cxtfwrk._cxtf_expect_mvariseq_* ;


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
      delete _cxtf_expect_mvariseq_: ; run;
    quit;



    %* -- permitted variablescope ;
    %if ( %sysfunc(findw( GLOBAL LOCAL, %scan(&variablescope, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for VARIABLESCOPE specified );
      %goto macro_exit;
    %end;

    %* -- permitted comparescope ;
    %if ( %sysfunc(findw( GLOBAL LOCAL, %scan(&comparescope, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for COMPARESCOPE specified );
      %goto macro_exit;
    %end;

    
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


    %* -- reference for this macro ;
    %let _cxtf_this_macro = &sysmacroname ;


    %* -- define scope reference for variable ;  
    %let _cxtf_var_scope = %sysmexecname( %eval( %sysmexecdepth - 1 ) );

    %if ( %upcase(&variablescope) = GLOBAL ) %then 
      %let _cxtf_var_scope = GLOBAL;


    %* -- define scope reference for compare ;  
    %let _cxtf_cmp_scope = %sysmexecname( %eval( %sysmexecdepth - 1 ) );

    %if ( %upcase(&comparescope) = GLOBAL ) %then 
      %let _cxtf_cmp_scope = GLOBAL;



    %* -- get macro variables ;
    %*    note: expecting two records ;
    proc sql noprint;

      create table _cxtfwrk._cxtf_expect_mvariseq_mvars as
        select * from dictionary.macros
           where ( ( ( upcase(strip(scope)) = upcase(strip(symget('_cxtf_var_scope'))) ) and
                     ( upcase(strip(name)) = scan( upcase(strip(symget('variable'))), 1, " ") ) ) or
                   ( ( upcase(strip(scope)) = upcase(strip(symget('_cxtf_cmp_scope'))) ) and
                     ( upcase(strip(name)) = scan( upcase(strip(symget('compare'))), 1, " ") ) ) )
      ;

    quit;



    %* -- verify two distinct variables ;
    %*    note: allowing same name in two scopes ;
    %let _cxtf_expect_hit = 0;

    proc sql noprint;
      select count(*) into: _cxtf_expect_hit separated by ' ' from _cxtfwrk._cxtf_expect_mvariseq_mvars ;
    quit;


    %* -- fail if variable or compare does not exist in respective scopes ;
    %if ( &_cxtf_expect_hit < 2 ) %then %do;
      %_cxtf_assert_fail( message = One or more of the specified macro variables do not exist );
      %goto macro_exit;
    %end;



    %* -- check value ;

    %let _cxtf_expect_hit = 0;

    proc sql noprint;

      %if ( %upcase(&ignorecase) = FALSE ) %then %do;

      select count(distinct(strip(value))) into: _cxtf_expect_hit separated by ' ' 
        from _cxtfwrk._cxtf_expect_mvariseq_mvars
      ; 

      %end;


      %if ( %upcase(&ignorecase) = TRUE ) %then %do;

      select count(distinct(strip(lowcase(value)))) into: _cxtf_expect_hit separated by ' ' 
        from _cxtfwrk._cxtf_expect_mvariseq_mvars
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
    %_cxtf_assert_fail( message = Macro variable %scan(%upcase(&variable), 1, %str( )) and compare variable %scan(%upcase(&compare), 1, %str( )) values are not equal  );



    %* -- macro exit point;
    %macro_exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails;
        delete _cxtf_expect_mvariseq_: ; run;
      quit;

    %end;                 


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
