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
             type reference cmd $ 200 cmdargs $ 4096
             __prefix $ 50 ;


      * -- read in program file ;
      infile "&path" ;
      input;
      
      lineno = _n_ ;
      pgmline = _infile_ ;


      * -- define which lines to keep for processing ;
      * note: '%macro test_' and '%test_' are test calls ;
      * note: '* @' is an annotation ;
      * note: compares are in space compressed form to allow for white-space formatting ;

      __prccess_line = 0;

      do __prefix = '%macrotest_', '%test_', '*@', '%*@' ;

        * note: intentionally working k-functions ;
        if ( ( klength(kcompress( pgmline, " " )) >= klength(strip(__prefix)) ) and
             ( lowcase( ksubstr( kcompress( pgmline, " " ), 1, klength(strip(__prefix)) ) ) =  strip(__prefix) ) ) then do;

          __prccess_line = 1;
          leave;

        end;

      end;

      if ( __prccess_line = 0 ) then   
        return ;  * <- nothing to do with this line ;



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



          output;
          return;  * <-- done proocessing this program line ;

      end;


     
      * -- process annotations ;
      if ( __prefix in ( '*@', '*%*@') ) then do;

        type = "annotation";

        __start = kfind( strip(pgmline), "@", 1);
        __end = kfind( strip(pgmline), " ", __start );

        cmd = lowcase( ksubstr( strip(pgmline), __start, __end - __start ) );
        reference = compress( cmd, "@ ");

        if ( reference not in ( "error", "errorignore", "warning", "warningignore" ) ) then
          return;

        call missing( __start, __end );

        __start = kfind( strip(pgmline), strip(cmd), 1) + klength(strip(cmd)) + 1  ;
        __end = kfind( strip(pgmline), ";", -1*klength(strip(pgmline)) );

        cmdargs = strip(ksubstr( strip(pgmline), __start, __end - __start )) ;

      end;


      * -- just keep the lines processed ;
      output;

    run;




    %* -- define scope ;
    
    proc sort data = _cxtfwrk.__cxtf_tfilemap_dsraw ;
      by descending lineno type reference;
    run;


    data _cxtfwrk.__cxtf_tfilemap_dsref ;
      set _cxtfwrk.__cxtf_tfilemap_dsraw ;
      by descending lineno type reference ;

      length scope $ 200 ;
      retain scope ;


      if first.type and type = "test" then 
        scope = reference; 
      
    run;


    proc sort data = _cxtfwrk.__cxtf_tfilemap_dsref ;
      by scope lineno ;
    run;



    %* -- generate output data set ;

    proc sql noprint;

        create table &out (
          scope char(200),
          type char(200),
          reference char(200),
          cmd char(200),
          cmdargs char(4096)
        );


        insert into &out 
           select scope, type, reference, cmd, cmdargs from _cxtfwrk.__cxtf_tfilemap_dsref
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

