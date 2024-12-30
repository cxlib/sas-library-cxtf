/*
* Utility macro to parse a test file and return a run-map
*
* @param path File path
* @param out Output data est
*
*
'
*
*
*/

%macro _cxtf_testfile_map( path = , out = );

    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_tfilemap_* ;


    %local rc _syscc _sysmsg _cxtf_debug_flg;

    %* -- capture entry state ;
    %let _syscc = 0;
    %let _sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
      %let _syscc = &syscc;
      %let _sysmsg = &sysmsg;

      %let syscc = 0;
      %let sysmsg = ;

    %end;


    %* -- debug information ;
    %_cxtf_debug( return = _cxtf_debug_flg );


    %* -- clean previous artifacts ;
    proc datasets library = _cxtfwrk nolist nodetails ;
      delete __cxtf_tfilemap_: ;  run;
    quit;


    %if ( %sysfunc(fileexist( &path )) = 0 ) %then %do;
      %put %str(ER)ROR: The specified file &path does not exist;
      %goto exit;
    %end;



    %* -- parse test program file ;


    data _cxtfwrk.__cxtf_tfilemap_dsraw ;
      
      length pgmline $ 4096 
             __prefix $ 50 ;


      * -- read in program file ;
      infile "&path" ;
      input;
      
      lineno = _n_ ;
      pgmline = _infile_ ;


      * -- define which lines to keep for processing ;
      * note: '%macro test_' and '%test_' are test calls ;
      * note: '* @' is an annotation ;
      * note: '%macro' and '%mend' are macro definitions
      * note: compares are in space compressed form to allow for white-space formatting ;

      __prccess_line = 0;

      do __prefix = '%macrotest_', '%test_', '*@', '%*@', '%macro', '%mend' ;

        * note: intentionally working k-functions ;
        if ( ( klength(kcompress( pgmline, " " )) >= klength(strip(__prefix)) ) and
             ( lowcase( ksubstr( kcompress( pgmline, " " ), 1, klength(strip(__prefix)) ) ) =  strip(__prefix) ) ) then do;

          __prccess_line = 1;
          leave;

        end;

      end;

      if ( __prccess_line = 1 ) then 
        output;

      drop __prccess_line ;
    run;


    data _cxtfwrk.__cxtf_tfilemap_defmap ;
      set _cxtfwrk.__cxtf_tfilemap_dsraw ;

      length __macrodef __macrodefid $ 50 ;
      retain __macrodef __macrodefid ;

      if ( __prefix in ( '%mend' ) ) then do;
        call missing( __macrodef, __macrodefid  ) ;
        return;
      end;

      if ( __prefix in ( '%macro' ) ) then do;
        __macrodef = "__ignore__" ;
        call missing( __macrodefid ) ;
        return;
      end;

      if ( __prefix in ( '%macrotest_', '%test_') ) then do;

          __start = kfind( strip(pgmline), "test_", 1);
          __end = kfind( strip(pgmline), "(", 1 );
          __w = klength(strip(pgmline));

          __macrodef = lowcase(ksubstr( strip(pgmline), __start, __end - __start ));
          __macrodefid = lowcase(hashing( "crc32", cats( symget('path'), put(lineno, 8.-L), __macrodef) ));

      end;

      drop __start __end __w ;

    run;


    proc sort  data = _cxtfwrk.__cxtf_tfilemap_defmap ;
      by descending lineno __macrodefid __macrodef;
    run;


    data _cxtfwrk.__cxtf_tfilemap_scope ;
      set _cxtfwrk.__cxtf_tfilemap_defmap ;
      where ( strip(__prefix) ^= '%mend' ) ;

      length scope scopeid $ 50 ;
      retain scope scopeid ;


*      if ( not missing(__macrodefid) ) then do;
      if ( not missing(__macrodef) ) then do;
        scope = strip(__macrodef) ;
        scopeid = strip(__macrodefid) ;
      end;

     drop __macrodef __macrodefid ;      
    run;


    proc sort data = _cxtfwrk.__cxtf_tfilemap_scope ;
      by lineno ;
    run;


    data _cxtfwrk.__cxtf_tfilemap_map ;
      set _cxtfwrk.__cxtf_tfilemap_scope ;
      where ( strip(scope) ^= "__ignore__" );

      length type reference cmd $ 200 cmdargs $ 4096  ;

      * -- process test references ;
      if ( __prefix in ( '%macrotest_', '%test_') ) then do;

          type = "test";

          __start = kfind( strip(pgmline), "test_", 1);
          __end = kfind( strip(pgmline), "(", 1 );
          __w = klength(strip(pgmline));

          reference = lowcase(ksubstr( strip(pgmline), __start, __end - __start ));
          cmd = strip(reference) ;


          __end = kfind( strip(pgmline), ";", -1*__w );
          cmdargs = ksubstr( strip(pgmline), __start, __end - __start);
      end;


     
      * -- process annotations ;
      if ( __prefix in ( '*@', '%*@') ) then do;

        type = "annotation";

        __start = kfindc( strip(pgmline), "@", 1);
        __end = kfindc( strip(pgmline), " ;", "", __start );

        cmd = lowcase( ksubstr( strip(pgmline), __start, __end - __start ) );
        reference = compress( cmd, "@ ;");

        if ( reference not in ( "error", "errorignore", "warning", "warningignore" ) ) then
          return;

        call missing( __start, __end, cmdargs );

        __start = kfind( strip(pgmline), strip(cmd), 1) + klength(strip(cmd)) + 1  ;
        __end = kfind( strip(pgmline), ";", -1*klength(strip(pgmline)) );

        if ( __start < __end ) then
          cmdargs = strip(ksubstr( strip(pgmline), __start, __end - __start )) ;

      end;

      drop __start __end __w  pgmline __prefix lineno;
    run;




    %* -- generate output data set ;

    proc sql noprint;

        create table &out (
          scopeid char(50),
          scope char(50),
          type char(200),
          reference char(200),
          cmd char(200),
          cmdargs char(4096)
        );


        insert into &out 
           select scopeid, scope, type, reference, cmd, cmdargs from _cxtfwrk.__cxtf_tfilemap_map
        ;

    quit;


 

    %* -- macro exit point ;
    %exit:


    %* -- clean temporary data sets ;
    %if ( &_cxtf_debug_flg = 0 ) %then %do;
      proc datasets library = _cxtfwrk nolist nodetails ;
        delete __cxtf_tfilemap_: ;  run;
      quit;
    %end;



    %* -- restore entry state ;
    %if ( &_syscc ^= 0 ) %then %do;
      %let syscc = &_syscc;
      %let sysmsg = &_sysmsg;
    %end;



%mend;

