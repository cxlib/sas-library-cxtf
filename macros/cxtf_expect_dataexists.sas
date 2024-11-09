/*
* Assert that a data set exists 
*
* @param data Data set
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

%macro cxtf_expect_dataexists( data = , not = FALSE );
                            
    %* note: temporary data sets using prefix _cxtfwrk._cxtf_expect_dsexist_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_ds_ref
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


    %* -- check if it exists ;
    %*    note: exist() returns 1 if data set exists and 0 if not ;

    %if ( (%upcase(&not) = FALSE) and ( %sysfunc(exist( &_cxtf_ds_ref )) = 0 ) ) %then %do;
      %_cxtf_assert_fail( message = Data set %upcase(&_cxtf_ds_ref) does not exist);
      %goto macro_exit;
    %end;


    %if ( (%upcase(&not) = TRUE) and ( %sysfunc(exist( &_cxtf_ds_ref )) = 1 ) ) %then %do;
      %_cxtf_assert_fail( message = Data set %upcase(&_cxtf_ds_ref) exists);
      %goto macro_exit;
    %end;


    %* -- pass ;
    %_cxtf_assert_pass();



    %* -- macro exit point;
    %macro_exit:


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
