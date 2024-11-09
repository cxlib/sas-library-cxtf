/*
* Post-processing for test file
*
* @param path Test file path 
*
*
*
*/


%macro _cxtf_testfile_post( path = );


    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_tfilepost_* ;


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg ;


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


    
    %* -- clean previous artifacts ;
    proc datasets library = _cxtfwrk nolist nodetails ;
      delete __cxtf_tfilepost_: ;  run;
    quit;


    %* -- post test file inventory ;
    
    proc sql noprint;

       create table _cxtfwrk.__cxtf_tfilepost_inv as 
         select catx( ".", libname, memname) as catalog length=32, 
                objname as name, 
                catx( ".", libname, memname, objname) as ref length=200 from dictionary.catalogs 
           where ( upcase(strip(libname)) = "WORK" ) and
                 ( upcase(strip(memtype)) = "CATALOG" ) and
                 ( upcase(strip(objtype)) = "MACRO" )
       ;


       create table _cxtfwrk.__cxtf_tfilepost_diff as 
          select catalog, name, ref from _cxtfwrk.__cxtf_tfilepost_inv
             where ( ref not in ( select ref from _cxtfwrk.testfile_pre ) )
             order by catalog
       ;

    quit;



    %* -- clean up macro caches ;

    data _null_;
      set _cxtfwrk.__cxtf_tfilepost_diff ;
      by catalog ;

      where ( not ( ( upcase(strip(name)) =: "CXTF_" ) or
                    ( upcase(strip(name)) =: "_CXTF_" ) ) ) ;

*      if ( not ( ( upcase(strip(name)) =: "CXTF_" ) or
*                 ( upcase(strip(name)) =: "_CXTF_" ) ) ) then return;


      if first.catalog then do;
        call execute( catx( " ", "proc catalog  catalog = ", strip(catalog), " entrytype= macro ;" ) );
        call execute( "  delete " );
      end;

      call execute( "  " || strip(name) ); 

      if last.catalog then do;
        call execute( "  ; run;" );
        call execute( "quit;" );
      end;

    run;


    %* -- report results on testfile ;
    %_cxtf_testfile_reporter( path = &path );


    %* -- macro exit point ;
    %macro_exit:

    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails ;
        delete __cxtf_tfilepost_: ;  run;
        delete testfile_pre; run;
      quit;

    %end;


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
