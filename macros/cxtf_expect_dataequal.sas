/*
* Assert that two data sets are equal
*
* @param data First data set
* @param compare Second data set
* @param obs Compare observations
* @param meta Metadata to compare
* @param not Negate the assertion
*
*
* @description
*
*
* The OBS parameter takes values TRUE and FALSE. If TRUE, data set observations
* are included in the compare. Otherwise, only the structure is compared.
*
* Data set observations are compared by-value based on variable name and type.
*
* The META parameter specified which metadata/structures to inlcude in the compare.
* Variable name and type are always compared. The following keywords modify the
* comparison.
*
*   LENGTH   Variable length
*   ORDER    Variable order
*   SORT     Data set sort order
*   LABEL    Variable label
*   FORMAT   Variable format
*
*
* The NOT parameter takes values TRUE and FALSE. If TRUE, the assertion
* is negated, i.e. variable is not expected to exist in the specified
* scope.
*
*
*/


%macro cxtf_expect_dataequal( data = , compare = , obs = TRUE, meta = LENGTH ORDER SORT LABEL FORMAT, not = FALSE );


    %* note: temporary data sets using prefix _cxtfwrk._cxtf_expect_dseq_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_sighup
           _cxtf_i _cxtf_metaopt
           _cxtf_metaopts _cxtf_metalst
           _cxtf_dsbase _cxtf_dscompare
           _cxtf_expect_hits
           _cxtf_obs_varlst 
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
      delete _cxtf_expect_dseq_: ; run;
    quit;



    %* -- permitted meta opts;
    %let _cxtf_sighup = 0;
    %let _cxtf_chkopts = ;

    %do _cxtf_i = 1 %to 100;

      %let _cxtf_metaopt = %scan( &meta, &_cxtf_i, %str( ) );

      %if ( &_cxtf_metaopt = %str() ) %then %goto doloop_meta_continue;

      %if ( %sysfunc(findw( LENGTH ORDER SORT LABEL FORMAT, &_cxtf_metaopt, , ies )) = 0 ) %then %do;
        %_cxtf_assert_fail( message = Invalid option %upcase(&_cxtf_metaopt) for META );
        %let _cxtf_sighup = 1 ;
      %end; %else %do;
        %let _cxtf_chkopts = &_cxtf_chkopts %upcase(_cxtf_metaopt);
      %end;

      %doloop_meta_continue:
    %end;

    %if ( &_cxtf_sighup = 1 ) %then
      %goto macro_exit;


    %* -- permitted obs:s ;
    %if ( %sysfunc(findw( TRUE FALSE, %scan(&obs, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for OBS specified );
      %goto macro_exit;
    %end;

    %* -- permitted not:s ;
    %if ( %sysfunc(findw( TRUE FALSE, %scan(&not, 1, %str( )), , ies )) = 0 ) %then %do;
      %_cxtf_assert_fail( message = Invalid value for NOT specified );
      %goto macro_exit;
    %end;




    %* -- determine full data set reference ;
    %let _cxtf_dsbase = %upcase(&data) ;

    %if ( %index( &_cxtf_dsbase, %str(.)) = 0 ) %then %do;
      %* -- assume WORK if lib not specified  ;
      %let _cxtf_dsbase = %upcase(WORK.&data) ;
    %end;



    %let _cxtf_dscompare = %upcase(&compare) ;

    %if ( %index( &_cxtf_dscompare, %str(.)) = 0 ) %then %do;
      %* -- assume WORK if lib not specified  ;
      %let _cxtf_dscompare = %upcase(WORK.&compare) ;
    %end;


    %* -- build meta check list ;
    %let _cxtf_metalst = name type;

    %if ( (&_cxtf_chkopts ^= %str() ) and ( %sysfunc(findw( &_cxtf_chkopts, LENGTH, , ies )) = 0 ) ) %then
      %let _cxtf_metalst = &_cxtf_metalst length;

    %if ( (&_cxtf_chkopts ^= %str() ) and ( %sysfunc(findw( &_cxtf_chkopts, ORDER, , ies )) = 0 ) ) %then
      %let _cxtf_metalst = &_cxtf_metalst varnum;

    %if ( (&_cxtf_chkopts ^= %str() ) and ( %sysfunc(findw( &_cxtf_chkopts, SORT, , ies )) = 0 ) ) %then
      %let _cxtf_metalst = &_cxtf_metalst sortedby;

    %if ( (&_cxtf_chkopts ^= %str() ) and ( %sysfunc(findw( &_cxtf_chkopts, LABEL, , ies )) = 0 ) ) %then
      %let _cxtf_metalst = &_cxtf_metalst label;

    %if ( (&_cxtf_chkopts ^= %str() ) and ( %sysfunc(findw( &_cxtf_chkopts, FORMAT, , ies )) = 0 ) ) %then
      %let _cxtf_metalst = &_cxtf_metalst format;



    %* -- compare meta data ;

    proc sql noprint;

      create table _cxtfwrk._cxtf_expect_dseq_mdata as
        select %sysfunc(translate( &_cxtf_metalst, %str(,), %str( ))) from dictionary.columns
           where ( upcase(strip(libname)) = scan( upcase(strip(symget('_cxtf_dsbase'))), 1, ".") ) and
                 ( upcase(strip(memname)) = scan( upcase(strip(symget('_cxtf_dsbase'))), 2, ".") )
           order by %sysfunc(translate( &_cxtf_metalst, %str(,), %str( )))
      ;


      create table _cxtfwrk._cxtf_expect_dseq_mcmp as
        select %sysfunc(translate( &_cxtf_metalst, %str(,), %str( ))) from dictionary.columns
           where ( upcase(strip(libname)) = scan( upcase(strip(symget('_cxtf_dscompare'))), 1, ".") ) and
                 ( upcase(strip(memname)) = scan( upcase(strip(symget('_cxtf_dscompare'))), 2, ".") )
           order by %sysfunc(translate( &_cxtf_metalst, %str(,), %str( )))
      ;

    quit;

    proc compare data = _cxtfwrk._cxtf_expect_dseq_mdata
                 compare = _cxtfwrk._cxtf_expect_dseq_mcmp
                 out = _cxtfwrk._cxtf_expect_dseq_mout
                 outnoequal noprint
    ;
    run;



    data _cxtfwrk._cxtf_expect_dseq_mcat ;
      set _cxtfwrk._cxtf_expect_dseq_mout ;


      %* -- variable list for metadata ;
      length _cxtf_varlst $ 1024 
             qvar $ 200;
      ;
      retain _cxtf_varlst;

      if ( _n_ = 1 ) then
         _cxtf_varlst = upcase(symget('_cxtf_metalst'));


      array _cxtf_char _CHARACTER_ ;
      array _cxtf_num  _NUMERIC_ ;



      %* character meta variables ;

      do _cxtf_i = 1 to dim(_cxtf_char);

        qvar = vname( _cxtf_char(_cxtf_i) ) ;

        if ( ( substr( qvar, 1, 1 ) = "_" ) or
             ( findw( _cxtf_varlst, strip(qvar), " ", "ies" ) = 0 ) or  
             ( missing( compress( _cxtf_char(_cxtf_i), ". " ) ) ) ) then continue ;

        output;
      end;


      %* numeric meta variables ;

      do _cxtf_i = 1 to dim(_cxtf_num);

        qvar = vname( _cxtf_num(_cxtf_i) ) ;

        if ( ( substr( qvar, 1, 1 ) = "_" ) or
             ( findw( _cxtf_varlst, strip(qvar), " ", "ies" ) = 0 ) or  
             ( missing( compress( put( _cxtf_num(_cxtf_i), best32.), ". E" ) ) ) ) then continue ;

        output;
      end;

    run;


    %* -- meta assertion ;

    %let _cxtf_expect_hits = 0 ;

    proc sql noprint;
      select count(*) into: _cxtf_expect_hits separated by ' ' from _cxtfwrk._cxtf_expect_dseq_mcat ;
    quit;


    %if ( ( %upcase(&not) = FALSE ) and ( &_cxtf_expect_hits > 0 ) ) %then %do; 
         
      data _null_ ;
        set _cxtfwrk._cxtf_expect_dseq_mcat ;

        call execute( catx( " ", '%_cxtf_assert_fail( message = Variable', upcase(qvar), 'not equal in', upcase(symget('_cxtf_dsbase')), 'and', upcase(symget('_cxtf_dscompare')), ');') );
      run;

      %* - futility ... if meta is not equal, then obs will never be ;
      %goto macro_exit ;

    %end;


    %if ( ( &meta ^= %str() ) and ( %upcase(&not) = TRUE ) and ( &_cxtf_expect_hits = 0 ) ) %then %do; 
      %_cxtf_assert_fail( message = The data sets %upcase(_cxtf_dsbase) and %upcase(&_cxtf_dscompare) are equal );
      %goto macro_exit;
    %end;

    
    %* -- if only meta, then we are done ;
    %if ( %upcase(&obs) = FALSE ) %then %do;
      %_cxtf_assert_pass();
      %goto macro_exit ;
    %end;

    %let _cxtf_expect_hits =  ;


    %* -- start comparing observations ;


    proc sql noprint;

      create table _cxtfwrk._cxtf_expect_dseq_obsvar as
        select distinct name, type, length from dictionary.columns
           where ( ( upcase(strip(libname)) = scan( upcase(strip(symget('_cxtf_dsbase'))), 1, ".") ) and
                   ( upcase(strip(memname)) = scan( upcase(strip(symget('_cxtf_dsbase'))), 2, ".") ) )
                 or 
                 ( ( upcase(strip(libname)) = scan( upcase(strip(symget('_cxtf_dscompare'))), 1, ".") ) and
                   ( upcase(strip(memname)) = scan( upcase(strip(symget('_cxtf_dscompare'))), 2, ".") ) )
           order by name, type
      ;


      create table _cxtfwrk._cxtf_expect_dseq_obsvardef as
        select name, type, max(length) as maxlength from _cxtfwrk._cxtf_expect_dseq_obsvar
           group by name, type 
      ;

    quit;



    data _null_ ;
      set _cxtfwrk._cxtf_expect_dseq_obsvardef  end = eof ;

      length vardef $ 200;
      
      if ( _n_ = 1 ) then do;
        call execute( "proc sql noprint;" );
        call execute( "  create table _cxtfwrk._cxtf_expect_dseq_obshell (" );
      end;


      %* variable definition ;
      vardef = strip( name ) ;

      if ( upcase(type) = "CHAR" ) then 
        call catx( " ", vardef, cats( "char(", put(maxlength, 8.), ")" ) );
      else 
        call catx( " ", vardef, "num" );


      if not eof then 
        call cats( vardef, "," );

      call execute( vardef );


   
      if eof then do;
        call execute( "  );" );
        call execute( "quit;" );
      end;

    run;


    %let _cxtf_obs_varlst = ;

    proc sql noprint;

      create table _cxtfwrk._cxtf_expect_dseq_obsvarlst as
        select name, varnum from dictionary.columns 
         where ( ( strip(upcase(libname)) = "_CXTFWRK" ) and
                 ( strip(upcase(memname)) = "_CXTF_EXPECT_DSEQ_OBSHELL" ) )
        order by varnum 
      ;



      select name into: _cxtf_obs_varlst separated by ", " 
        from _cxtfwrk._cxtf_expect_dseq_obsvarlst
      ;


      %* -- left side of compare ;
      create table _cxtfwrk._cxtf_expect_dseq_obsbase as
         select &_cxtf_obs_varlst from _cxtfwrk._cxtf_expect_dseq_obshell
           order by &_cxtf_obs_varlst
      ;

      insert into _cxtfwrk._cxtf_expect_dseq_obsbase
        (&_cxtf_obs_varlst)
        select &_cxtf_obs_varlst from &_cxtf_dsbase
      ;



      %* -- right side of compare ;
      create table _cxtfwrk._cxtf_expect_dseq_obscompare as
         select &_cxtf_obs_varlst from _cxtfwrk._cxtf_expect_dseq_obshell
           order by &_cxtf_obs_varlst
      ;

      insert into _cxtfwrk._cxtf_expect_dseq_obscompare
        (&_cxtf_obs_varlst)
        select &_cxtf_obs_varlst from &_cxtf_dscompare
      ;

    quit; 
                         


    %* -- obs compare ;
    proc compare data = _cxtfwrk._cxtf_expect_dseq_obsbase
                 compare = _cxtfwrk._cxtf_expect_dseq_obscompare
                 out = _cxtfwrk._cxtf_expect_dseq_obsout
                 outnoequal noprint
    ;
    run;



    data _cxtfwrk._cxtf_expect_dseq_obscat ;
      set _cxtfwrk._cxtf_expect_dseq_obsout ;


      %* -- variable list for metadata ;
      length _cxtf_varlst $ 1024 
             qvar $ 200;
      ;
      retain _cxtf_varlst;

      if ( _n_ = 1 ) then do;
         _cxtf_varlst = translate( compress( upcase(symget('_cxtf_obs_varlst')), " " ), " ", "," );
      end;



      array _cxtf_char _CHARACTER_ ;
      array _cxtf_num  _NUMERIC_ ;



      %* character variables ;

      do _cxtf_i = 1 to dim(_cxtf_char);

        qvar = vname( _cxtf_char(_cxtf_i) ) ;

        if ( ( substr( qvar, 1, 1 ) = "_" ) or
             ( findw( _cxtf_varlst, strip(qvar), " ", "ies" ) = 0 ) or  
             ( missing( compress( _cxtf_char(_cxtf_i), ". " ) ) ) ) then continue ;

        output;
      end;


      %* numeric variables ;

      do _cxtf_i = 1 to dim(_cxtf_num);

        qvar = vname( _cxtf_num(_cxtf_i) ) ;

        if ( ( substr( qvar, 1, 1 ) = "_" ) or
             ( findw( _cxtf_varlst, strip(qvar), " ", "ies" ) = 0 ) or  
             ( missing( compress( put( _cxtf_num(_cxtf_i), best32.), ". E" ) ) ) ) then continue ;

        output;
      end;

    run;


    %* -- meta assertion ;

    %let _cxtf_expect_hits = 0 ;

    proc sql noprint;
      select count(*) into: _cxtf_expect_hits separated by ' ' from _cxtfwrk._cxtf_expect_dseq_obscat ;
    quit;


    %if ( ( %upcase(&not) = FALSE ) and ( &_cxtf_expect_hits > 0 ) ) %then %do; 
         
      data _null_ ;
        set _cxtfwrk._cxtf_expect_dseq_obscat ;

        call execute( catx( " ", '%_cxtf_assert_fail( message = Variable', upcase(qvar), 'not equal in', upcase(symget('_cxtf_dsbase')), 'and', upcase(symget('_cxtf_dscompare')), ');') );
      run;

      %* - futility ... if meta is not equal, then obs will never be ;
      %goto macro_exit ;

    %end;


    %if ( ( %upcase(&not) = TRUE ) and ( &_cxtf_expect_hits = 0 ) ) %then %do; 
      %_cxtf_assert_fail( message = The observations in the data sets %upcase(&_cxtf_dsbase) and %upcase(_cxtf_dscompare) are equal );
      %goto macro_exit;
    %end;

    
    %* -- obviously not failed ... so pass  ;
    %_cxtf_assert_pass();





    %* -- macro exit point;
    %macro_exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails;
        delete _cxtf_expect_dseq_: ; run;
      quit;

    %end;


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;



%mend;
