/*
* Intneral utility for cxtf to passively initialise
*
* @param reset Reset environment
*
* @decription
*
* Note that reset takes the values TRUE and FALSE, case in-sensitive 
*
*
*/


%macro cxtf_init( reset = TRUE );

    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_work 
           _cxtf_liblst _cxtf_i
           _cxtf_lib _cxtf_tmpdir 
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


    %* -- set up standard libraries ;

    %* use WORK as parent ;
    %* note: subdirectories automatically deleted when SAS session exists ;
    %let _cxtf_work = %sysfunc(pathname( WORK ));


    %let _cxtf_liblst = _cxtfwrk _cxtfrsl ;
    %let _cxtf_i = 1 ;

    %do %while ( %scan( &_cxtf_liblst, &_cxtf_i, %str( )) ^= %str() );

        %let _cxtf_lib = %scan( &_cxtf_liblst, &_cxtf_i, %str( )) ;
        %let _cxtf_i = %eval( &_cxtf_i + 1 );

        %* - create sub-work directory if not exist ;
        %if ( %sysfunc(libref( &_cxtf_lib )) ^= 0 ) %then %do;

          %let _cxtf_tmpdir=;
          %cxtf_tempfile( prefix = &_cxtf_lib._, path = &_cxtf_work, fileext = , return = _cxtf_tmpdir);

          %if ( %sysfunc(fileexist(&_cxtf_tmpdir)) = 0 ) %then   
              %let rc = %sysfunc(dcreate( %scan( &_cxtf_tmpdir, -1, %str(/)), &_cxtf_work ));

          %* - create libname ;
          %let rc = %sysfunc(libname( &_cxtf_lib, &_cxtf_tmpdir )); 

          %* - make sure it went ok ;
          %if ( %sysfunc(libref( &_cxtf_lib )) ^= 0 ) %then %do;
            %put %str(ER)ROR: Could not configure library &_cxtf_lib ;
          %end; 

        %end; 

        %if ( %upcase(&reset) = TRUE ) %then %do;
          proc datasets library = &_cxtf_lib nolist nodetails kill;
          quit;
        %end;

    %end;



    proc sql noprint;

      %* -- initiate test index ;
      %if ( %sysfunc(exist( _cxtfrsl.cxtftestidx )) = 0 ) %then %do;

        create table _cxtfrsl.cxtftestidx (
          testfile   char(4096),
          hash_sha1  char(50),
          seq        num, 
          test       char(50),
          testid     char(50),
          type       char(200),
          scope      char(50),
          scopeid    char(50),
          reference  char(200),
          cmd        char(200),
          cmdargs    char(4096)
        );

      %end;


      %* -- initiate results data set ;
      %if ( %sysfunc(exist( _cxtfrsl.cxtfresults )) = 0 ) %then %do;

        create table _cxtfrsl.cxtfresults (
          testid     char(50),
          result     char(5),
          assertion  char(200),
          message    char(200)
        );

      %end; 

    quit;



    %* -- reset cxtf macros ;
    %if ( %upcase(&reset) = TRUE ) %then %do;

      proc sql noprint;

        create table _cxtfwrk.__cxtf_init_macros as 
          select catx( ".", libname, memname) as catalog length=32, 
                 objname
          from dictionary.catalogs 
          where ( upcase(strip(libname)) = "WORK" ) and
                ( upcase(strip(memtype)) = "CATALOG" ) and
                ( upcase(strip(objtype)) = "MACRO" )
          order by catalog, objname
        ;

      quit;


      data _null_;
        set _cxtfwrk.__cxtf_init_macros ;
        by catalog ;

        where ( ( upcase(strip(objname)) =: "CXTF_" ) or
                ( upcase(strip(objname)) =: "_CXTF_" ) ) and 
              ( upcase(strip(objname)) ^= "CXTF_INIT" )
        ;

        put "NO" "TE: Deleting macro " objname +(-1) " in catalog " catalog +(-1) "." ;
        call execute( catx( " ", '%sysmacdelete', objname, '/nowarn') );

      run;

    %end;



    %* -- macro exit point ;
    %macro_exit:



    %if ( &_cxtf_debug_flg = 0 ) %then %do;
      proc datasets  library = _cxtfwrk nolist nodetails;
        delete __cxtf_init_: ; run;
      quit;
    %end;


    %* -- restore entry state ;
    %if ( ( %upcase(&reset) = FALSE ) and ( &_cxtf_syscc ^= 0 ) ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;


