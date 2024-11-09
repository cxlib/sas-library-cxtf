/*
* Utility to inventory a directory
*
* @param path Directory path
* @param out Output directory name
*
* @returns A data set containing the list of files in a directory
*
*
*/

%macro _cxtf_dirinventory( path = , out = );

    %* note: temporary data sets using prefix _cxtfwrk.__cxtf_dirinv_* ;

    %local rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
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


    %* -- clean previous artifacts ;
    proc datasets library = _cxtfwrk nolist nodetails ;
      delete __cxtf_dirinv_: ;  run;
    quit;




    %* -- inventoty please ... ;

    data _cxtfwrk.__cxtf_dirinv_inv ;

        length path $ 4096
               type $ 10
               hash_sha1 $ 255 
        ;

        set sashelp.vmacro (rename = ( scope = __scope  name = __param  value = __root ) );
        where ( ( lowcase(__scope) = "_cxtf_dirinventory" ) and 
                ( lowcase(__param) = "path" ) );

        if ( missing( __root) or not fileexist( __root ) ) then do;
          put "NOTE: Directory does not exist";
          return ; 
        end;



        * - file reference ;
        __rc = filename( "_cxtfinv", __root );

        * - directory handle for reading ;
        did = dopen( "_cxtfinv" );

        if ( did = 0 ) then return;


        * - process contents of directory ;

        do i = 1 to dnum(did) ;
          * - initialise all variables to keep ;
          call missing( path, type, hash_sha1 );

          * - main reference ;
          path = catx( "/", __root, dread( did, i ) );


          * - identify type ;
          * note: kind of a hack but it works ;

          __rc = filename( "_tmptmp", path );

          __tmpid = dopen( "_tmptmp" );   * <- try open as a directory ... file it fails ;

          if ( __tmpid = 0 ) then 
            type = "file" ;
          else 
            type = "directory" ;

          __rc = dclose( __tmpid );
          call missing( __tmpid );
          __rc = filename( "_tmptmp" );


          if ( type = "directory" ) then do;
            * if a directory ... nothing else to do here ;
            output;
            continue;
          end;


          * - hash reference ;
          hash_sha1 = lowcase( hashing_file( "sha1", path ) ) ;

          * - create output record ;
          output;

          * - reset all variables to keep ;
          call missing( path, type, hash_sha1 );
        end;


        * - release handle and clear file reference for directory ;
        rc = dclose(did);
        call missing( did );

        __rc = filename( "_cxtfinv" );

    run;



    %* -- save inventory to output data set ;
    %if ( &syscc = 0 ) %then %do;

      proc sql noprint;

        %* output data set ;
        create table &out (
          path         char(4096),
          type         char(10),
          hash_sha1    char(255)
        );

        insert into &out 
          select path, type, hash_sha1 from _cxtfwrk.__cxtf_dirinv_inv
             where not missing( path )
        ;

      quit;

    %end;



    %* -- macro exit point ;
    %exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;

      proc datasets library = _cxtfwrk nolist nodetails ;
        delete __cxtf_dirinv_: ;  run;
      quit;

    %end;                


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;

%mend; 


