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
* Siemens/Altair SAS Language Compiler (SLC)
* -------------------------------------------------------
* Option MCACHE is forced equal to 0 to disable and purge macro 
* memory cache
*
*/


%macro cxtf_init( reset = TRUE );

    %local _cxtf_init_rc _cxtf_init_syscc _cxtf_init_sysmsg _cxtf_init_debug_flg
           _cxtf_init_opt_mcache
           _cxtf_init_work 
           _cxtf_init_liblst _cxtf_init_i
           _cxtf_init_lib _cxtf_init_tmpdir 
    ;


    %cxtf_debug( return = _cxtf_init_debug_flg );

    

    %* -- capture entry state ;
    %let _cxtf_init_syscc = 0;
    %let _cxtf_init_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
    
      %let _cxtf_init_syscc = &syscc;
      %let syscc = 0;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do; 
	      %let _cxtf_init_sysmsg = &sysmsg;
	      %let sysmsg = ;
      %end;
	  %end;



    %* -- error SYNTAXCHECK mode ;
    %*    note: NOSYNTAXCHECK normal operation ;
    %if ( %sysfunc(getoption( SYNTAXCHECK)) = SYNTAXCHECK ) %then %do;
      %put %str(ER)ROR: (cxtf) SYNTAXCHECK enabled. The macro %upcase(&sysmacroname) will not execute. ;
      %goto macro_exit;
    %end; 


    
    
    %* -- disable and purge macro memory cache ;
    %let _cxtf_init_opt_mcache = %sysfunc(getoption(mcache));
    
    %if ( &_cxtf_init_opt_mcache ^= %str() ) %then %do;
        %put %str(NO)TE: MCACHE set to 0 to clear and disable macro memory cache;
        options MCACHE = 0;
    %end;



    %* -- set up standard libraries ;

    %* use WORK as parent ;
    %* note: subdirectories automatically deleted when SAS session exists ;
    %let _cxtf_init_work = %sysfunc(pathname( WORK ));


    %let _cxtf_init_liblst = _cxtfwrk _cxtfrsl ;
    %let _cxtf_init_i = 1 ;

    %do %while ( %scan( &_cxtf_init_liblst, &_cxtf_init_i, %str( )) ^= %str() );

        %let _cxtf_init_lib = %scan( &_cxtf_init_liblst, &_cxtf_init_i, %str( )) ;
        %let _cxtf_init_i = %eval( &_cxtf_init_i + 1 );

        %* - create sub-work directory if not exist ;
        %if ( %sysfunc(libref( &_cxtf_init_lib )) ^= 0 ) %then %do;

          %let _cxtf_init_tmpdir=;
          %cxtf_tempfile( prefix = &_cxtf_init_lib._, path = &_cxtf_init_work, fileext = , return = _cxtf_init_tmpdir);

          %if ( %sysfunc(fileexist(&_cxtf_init_tmpdir)) = 0 ) %then   
              %let rc = %sysfunc(dcreate( %scan( &_cxtf_init_tmpdir, -1, %str(/)), &_cxtf_init_work ));

          %* - create libname ;
          %let rc = %sysfunc(libname( &_cxtf_init_lib, &_cxtf_init_tmpdir )); 

          %* - make sure it went ok ;
          %if ( %sysfunc(libref( &_cxtf_init_lib )) ^= 0 ) %then %do;
            %put %str(ER)ROR: (cxtf) Could not configure library &_cxtf_init_lib ;
          %end; 

        %end; 

        %if ( %upcase(&reset) = TRUE ) %then %do;
          proc datasets library = &_cxtf_init_lib nolist nodetails kill;
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






    %* -- macro exit point ;
    %macro_exit:



    %if ( %upcase(&_cxtf_init_debug_flg) = FALSE ) %then %do;
      proc datasets  library = _cxtfwrk nolist nodetails;
        delete __cxtf_init_init_: ; run;
      quit;
    %end;


    %* -- restore entry state ;
    %if ( ( %upcase(&reset) = FALSE ) and ( &_cxtf_init_syscc ^= 0 ) ) %then %do;
    
      %let syscc = &_cxtf_init_syscc;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do; 
	      %let sysmsg = &_cxtf_init_sysmsg;
	    %end;
      
    %end;


%mend;


