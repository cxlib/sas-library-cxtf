/*
* Internal utility macro for pre-processing test file
*
* @param path Test file
*
*
*/


%macro _cxtf_testfile_pre( path = );

    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_tfilepre_* ;

    %global CXTF_TESTID ;

    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_tempfile 
    ;


    %cxtf_debug( return = _cxtf_debug_flg );


    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
    
      %let _cxtf_syscc = &syscc;
      %let syscc = 0;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do; 
          %let _cxtf_sysmsg = &sysmsg;
          %let sysmsg = ;
      %end;

    %end;



    %* -- clean previous artifacts ;
    proc datasets library = _cxtfwrk nolist nodetails ;
      delete testfile_pre; run;
      delete __cxtf_tfilepre_: ;  run;
    quit;



    %* -- inventory WOEK.SASMAC* ;

    proc sql noprint;

       create table _cxtfwrk.testfile_pre as 
         select catx( ".", libname, memname) as catalog length=32, objname as name, catx( ".", libname, memname, objname) as ref length=200 from dictionary.catalogs 
           where ( upcase(strip(libname)) = "WORK" ) and
                 ( upcase(strip(memtype)) = "CATALOG" ) and
                 ( upcase(strip(objtype)) = "MACRO" )
       ;

    quit;



    %* -- process test file ;
    %* -- note: make %test_*() inert ;


    %* - read in test file;

    data _cxtfwrk.__cxtf_tfilepre_tstfile ;
      
      length pgmline outline $ 4096 
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

      __prefix = '%test_' ;

      if ( ( klength(kcompress( pgmline, " " )) >= klength(strip(__prefix)) ) and
           ( lowcase( ksubstr( kcompress( pgmline, " " ), 1, klength(strip(__prefix)) ) ) =  strip(__prefix) ) ) then do;

        %* make %test_* inert ;
        outline = catx( " ", "/*", strip(pgmline), "*/" );

      end; else do;

        %* keep lines as is ;
        outline = strip(pgmline);

      end;


      keep lineno pgmline outline ;
    run;



    %* - output test file ;

    %cxtf_tempfile( prefix = testfile, fileext = sas, return = _cxtf_tempfile );

    %if ( &_cxtf_debug_flg = TRUE ) %then
      %put %str(DEBUG) Inert source file for test scenarios is &_cxtf_tempfile;


    data _null_;
      set _cxtfwrk.__cxtf_tfilepre_tstfile ;

      file "&_cxtf_tempfile";

      put outline ;
    run;



    %* -- source test file ;
    data _null_;
      set sashelp.vmacro ;
      where ( upcase(scope) = upcase(symget('sysmacroname')) ) and
            ( upcase(name) = "_CXTF_TEMPFILE" ) ;

      if ( symget( '_cxtf_debug_flg' ) = "TRUE" ) then 
         put "DEBUG Temporary file " value ; 

      call symput( '_cxtf_rc', '0' );

      cmd = catx( " ", '%include', quote(strip(value)), " ; " );
      call execute( cmd );

    run;


    %* -- list inventory of defined tests in debug mode ;
    %if ( &_cxtf_debug_flg = TRUE ) %then %do;
    
      proc sql noprint;
  
         create table _cxtfwrk.__cxtf_tfilepre_inv as 
           select catx( ".", libname, memname) as catalog length=32, 
                  objname as name, 
                  catx( ".", libname, memname, objname) as ref length=200 from dictionary.catalogs 
             where ( upcase(strip(libname)) = "WORK" ) and
                   ( upcase(strip(memtype)) = "CATALOG" ) and
                   ( upcase(strip(objtype)) = "MACRO" )
         ;    
    
      quit;
      
      data _null_;
        set _cxtfwrk.__cxtf_tfilepre_inv ;
        by catalog ;
  
        where ( not ( ( upcase(strip(name)) =: "CXTF_" ) or
                      ( upcase(strip(name)) =: "_CXTF_" ) ) ) ;
                      
        if ( _n_ = 1 ) then 
          put "DEBUG List of imported macros" /
              "DEBUG ----------------------------------------" ;
          
        put "DEBUG " name ; 
        
      run;      
      
    %end;



    %* -- macro exit point ;
    %macro_exit:


    %* -- clean up ;

    %if ( %upcase(&_cxtf_debug_flg) = FALSE ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails ;
        delete __cxtf_tfilepre_: ;  run;
      quit;

    %end;



    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
    
      %let syscc = &_cxtf_syscc;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do;
          %let sysmsg = &_cxtf_sysmsg;
      %end;
          
    %end;




%mend;
