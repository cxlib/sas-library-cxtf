/*
* Assert that a variable exists in a data set
*
* @param data Data set
* @param variables List of variable names
* @param variablescope Scope of variable
* @param not Negate the assertion
*
* @description 
*
* The not parameter takes values TRUE and FALSE. If TRUE, the assertion
* is negated, i.e. variable is not expected to exist in the specified 
* scope. 
*
*
*/

%macro cxtf_expect_varexists( data = , variables = , not = FALSE );
                                                     
    %* note: temporary data sets using prefix _cxtfwrk._cxtf_expect_varexist_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_ds_ref
           _cxtf_varlst _cxtf_var  
           _cxtf_expect_hit _cxtf_actual_hit
           _cxtf_missing
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
      delete _cxtf_expect_varexist_: ; run;
    quit;


    %* -- data set must exist ;
    %if ( %sysfunc(exist( &data )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Data set %upcase(&data) does not exist );
      %goto macro_exit;
    %end;


    %* -- permitted not:s ;
    %if ( %sysfunc(findw( TRUE FALSE, %scan(&not, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for NOT specified );
      %goto macro_exit;
    %end;


    %* -- determine full data set reference ;

    %let _cxtf_ds_ref = %upcase(&data) ;

    %if ( %index( &_cxtf_ds_ref, %str(.)) = 0 ) %then %do;
      %* -- assume WORK if lib not specified  ;
      %let _cxtf_ds_ref = %upcase(WORK.&data) ;
    %end;


    %* -- get variables ;
    %*    note: expecting one record per variable ;

    data _cxtfwrk._cxtf_expect_varexist_varlst ;
      set sashelp.vmacro (rename = ( name = var_name )) ;
      where ( upcase(strip(scope)) = upcase(strip(symget('sysmacroname'))) ) and
            ( upcase(strip(var_name)) = "VARIABLES" ) ;

      length name $ 200 ;


      do _i = 1 to 100 ;  %* <- avoid endless queue ;

        name = upcase(strip( scan( strip(value), _i, " " ) ));

        if missing(name) then leave ;

        output;
      end;

      keep name ;
    run;
       

    proc sql noprint;

      create table _cxtfwrk._cxtf_expect_varexist_vars as
        select * from dictionary.columns
           where ( upcase(strip(libname)) = scan( strip(symget('_cxtf_ds_ref')), 1, "." ) ) and
                 ( upcase(strip(memname)) = scan( strip(symget('_cxtf_ds_ref')), 2, "." ) ) and
                 ( upcase(strip(name)) in (select distinct name from _cxtfwrk._cxtf_expect_varexist_varlst) )
      ;

    quit;



    %* -- assert list of variables ;

    %let _cxtf_varlst = ;

    proc sql noprint;
      select upcase(name) into: _cxtf_varlst separated by ' ' from _cxtfwrk._cxtf_expect_varexist_varlst ;
    quit;


    %do _cxtf_i = 1 %to 100 ;
      
      %let _cxtf_var = %scan( %upcase(&variables), &_cxtf_i, %str( ));
     
      %if ( &_cxtf_var = %str() ) %then %goto var_loop_exit;


      %let _cxtf_expect_hit = 0 ;

      proc sql noprint;
        select count(*) into: _cxtf_expect_hit separated by ' ' from _cxtfwrk._cxtf_expect_varexist_vars
          where ( upcase(strip(name)) = upcase(strip(symget('_cxtf_var'))) )
        ;
      quit;


      %if ( (%upcase(&not) = FALSE) and ( &_cxtf_expect_hit = 0 ) ) %then %do;
        %_cxtf_assert_fail( message = Variable %upcase(&_cxtf_var) does not exist in %upcase(&_cxtf_ds_ref) );
        %goto var_loop_continue;
      %end;

      %if ( (%upcase(&not) = TRUE) and ( &_cxtf_expect_hit = 1 ) ) %then %do;
        %_cxtf_assert_fail( message = Variable %upcase(&_cxtf_var) exists in %upcase(&_cxtf_ds_ref) );
        %goto var_loop_continue;
      %end;


      %* pass ;
      %_cxtf_assert_pass();

      %* do-loop continue;
      %var_loop_continue:
    %end;

    %* do-loop exit point;
    %var_loop_exit:




    %* -- macro exit point;
    %macro_exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails;
        delete _cxtf_expect_varexist_: ; run;
      quit;

    %end;                 


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
