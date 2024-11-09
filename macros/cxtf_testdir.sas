/*
* Execute tests in a specified directory
*
* @param path Directory path
* 
* @description
*
* The macro will execute tests defined in files that start with 
* test- or test_ and has the file extension sas.
*
*
*
*
*/


%macro cxtf_testdir( path = ) ;


    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_tdir_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
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


    %* -- passively initialize ;
    %cxtf_init( reset = FALSE );


    %* -- clean previous artifacts ;
    proc datasets library = _cxtfwrk nolist nodetails ;
      delete __cxtf_tdir_: ;  run;
    quit;


    %if ( %sysfunc(fileexist( &path )) = 0 ) %then %do;
      %put %str(ER)ROR: The specified file &path does not exist;
      %goto exit;
    %end;


    %* -- generate inventory of directory ;
    %_cxtf_dirinventory( path = &path, out = _cxtfwrk.__cxtf_tdir_inv );


    %* -- identify test files ;
    %* note: test file starts with test-* or test_* ;
    %* note: test file has file extension *.sas ;
  
    data _cxtfwrk.__cxtf_tdir_files ;
      set _cxtfwrk.__cxtf_tdir_inv ;
      where ( strip(lowcase(type)) = "file" ) ;

      prx = prxparse( "/.*\/test[-_][a-z0-9-_.]+.sas$/" );

      if ( prxmatch( prx, lowcase(strip(path)) ) ) then 
        output; 

    run; 


    %if ( &_cxtf_debug_flg ) %then %do;

      data _null_;
        set _cxtfwrk.__cxtf_tdir_files   end = eof ;

        if ( _n_ = 1 ) then 
          put "DEBUG ---------------------------------------------------------------" /
              "DEBUG Identified test files" /
              "DEBUG";

        put "DEBUG " path ;

        if eof then 
           put "DEBUG ---------------------------------------------------------------" ;

      run;

    %end;



    %* -- process test files ;
    %* note: natural sort order ;

    proc sort data = _cxtfwrk.__cxtf_tdir_files  ;
      by path ;
    run;

    data _null_ ;
      set _cxtfwrk.__cxtf_tdir_files ;

      %* use call execute to queue up the macro calls ;
      rc = dosubl( catx( " ", '%cxtf_testfile( path = ', path, ');' ) );

    run;





    %* -- report results on test directory ;
    %_cxtf_testdir_reporter( path = &path );




    %* -- macro exit point ;
    %macro_exit:


    %* -- clean up ;
    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails ;
        delete __cxtf_tdir_: ;  run;
      quit;

    %end;


    
    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
