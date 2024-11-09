/*
* Execute tests in a specified file
*
* @param path Test file
*
*
*/


%macro cxtf_testfile( path = );

    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_tfile_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_testfile_path
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
      delete __cxtf_tfile_: ;  run;
    quit;


    %if ( %sysfunc(fileexist( &path )) = 0 ) %then %do;
      %put %str(ER)ROR: The specified file &path does not exist;
      %goto macro_exit;
    %end;


    %* -- standardise path reference ;
    %let _cxtf_testfile_path = %sysfunc(lowcase(%sysfunc(translate( &path, /, \))));


    %* -- remove test file entries from index and associated results ;
    proc sql noprint;

        delete from _cxtfrsl.cxtfresults
          where ( strip(testid) in ( select strip(testid) from _cxtfrsl.cxtftestidx where ( strip(testfile) = strip(symget('_cxtf_testfile_path')) ) ) )
        ;

        delete from _cxtfrsl.cxtftestidx
          where ( strip(testfile) = strip( symget('_cxtf_testfile_path') ) )
        ;

    quit;


    %* -- import test map ;
    %_cxtf_testfile_map( path = &_cxtf_testfile_path, out = _cxtfwrk.__cxtf_tfile_dsimpmap );


    %* -- generate test map ;

    data _cxtfwrk.__cxtf_tfile_dsmap ;
      set _cxtfwrk.__cxtf_tfile_dsimpmap ( rename = (reference = _test )) ;

      length testfile $ 4096
             hash_sha1 test testid $ 50
      ;

      retain testfile hash_sha1 ;

      if ( _n_ = 1 ) then do;
          %* test file ;
          %* note: use forward slash as internal reference ;
          testfile = strip(symget('_cxtf_testfile_path'));

          %* test file hash ;
          hash_sha1 = hashing_file( "sha1", strip(testfile) );
      end;


      if ( type = "test" ) then do;

        %* test sequence ;
        seq = _n_;

        %* getting length right ;
        test = strip(_test);

        %* -- generate test ID ;
        testid = lowcase( hashing( "crc32", cats( testfile, hash_sha1, test, cmd, cmdargs, put( datetime(), best32. ), put( rand("uniform"), best32.) ) ) );

      end;

    run;



    %* -- append to test index ;
    proc sql noprint;

      insert into _cxtfrsl.cxtftestidx
        select testfile, hash_sha1, seq, test, testid, cmdargs as testcmd from _cxtfwrk.__cxtf_tfile_dsmap
          where ( type = "test" )
      ;

    quit;

    proc sort data = _cxtfrsl.cxtftestidx ;
      by testfile seq test testid ;
    run;


    %* -- initiate test file ;
    %_cxtf_testfile_pre( path = &_cxtf_testfile_path );


    %* -- engine room ;

    data _null_ ;
      set _cxtfrsl.cxtftestidx  ;
      where ( strip(testfile) = strip(symget('_cxtf_testfile_path')) );

      length cmdstr $ 4096 ;
      
      call missing( cmdstr );


      %* - add test id ;
      call catx( " ; ", cmdstr, cats( '%let CXTF_TESTID=', strip(testid) ) );

      %* - pre-process test ;
      call catx( " ; ", cmdstr, '%_cxtf_test_pre()' );


      %*- test ;
      call catx( " ; ", cmdstr, cats('%', testcmd) );


      %* - post-process test ;
      call catx( " ; ", cmdstr, '%_cxtf_test_post()' );


      %* - disable test id ;
      call catx( " ; ", cmdstr, cats( '%symdel CXTF_TESTID;' ) );



      %* - add terminating semi-colon ;
      call cats( cmdstr, ";" );

      %* - run test ;
      put " " /
          "---------------------------------------------------------------------" /
          "Begin test ID " testid /
          testcmd /
          "---------------------------------------------------------------------" /
          " ";

      if ( symget( '_cxtf_debug_flg' ) = "1" ) then 
         put "(DEBUG) Test command string " cmdstr ;


      rc = dosubl( cmdstr );

      put " " /
          "---------------------------------------------------------------------" /
          "End test ID " testid /
          "---------------------------------------------------------------------" /
          " " ;


    run;


    %* -- complete test file ;
    %_cxtf_testfile_post( path = &_cxtf_testfile_path );



    %* -- macro exit point ;
    %macro_exit:


    %* -- clean temporary data sets ;
    %if ( &_cxtf_debug_flg = 0 ) %then %do;
      proc datasets library = _cxtfwrk nolist nodetails ;
        delete __cxtf_tfile_: ;  run;
      quit;
    %end;


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
