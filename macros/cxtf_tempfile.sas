/*
* Utility macro to generate a temporary file name in a specified directory
*
* @param prefix Prefix of file name
* @param path Parent directory
* @param fileext File extension
* @param return Return name 
*
* @description
*
* Returns a semi-random string unique in the directory path
*
*/

%macro cxtf_tempfile( prefix = __cxtf, path = , fileext = , return = );


    %local _cxtf_tmpf_rc _cxtf_tmpf_syscc _cxtf_tmpf_sysmsg _cxtf_tmpf_debug_flg
    ;

    %* print debug details ;
    %cxtf_debug( return = _cxtf_tmpf_debug_flg );


    %* -- capture entry state ;
    %let _cxtf_tmpf_syscc = 0;
    %let _cxtf_tmpf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
    
      %let _cxtf_tmpf_syscc = &syscc;
      %let syscc = 0;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do; 
	      %let _cxtf_tmpf_sysmsg = &sysmsg;
	      %let sysmsg = ;
	  %end;

    %end;


    %* -- return ;
    %if ( %symexist(&return) ^= 1 ) %then %do;
      %_cxtf_error( message = A RETURN macro variable name not specified or it does not exist );   
      %_cxft_stacktrace();
      %goto macro_exit;
    %end;





    %* -- generate string ;

    data _null_ ;

      length root $ 4096 
             str $ 1024 
             xpath $ 5888;

      %* -- identify parent path ;
      %* note: if not specified, using path of WORK library ;
      root = symget('path');

      if ( missing(root) ) then
        root = pathname('WORK');


      %* initililze with prefix ;
      str = kstrip(symget('prefix'));


      %* force first character to be A-Z-ish (thanks SAS) ;
      if missing(str) then 
         str = byte( mod( floor(100*rand("uniform")), 26) + rank("A") - 1 ) ; 

      %* add random string ;
      call cats( str, hashing( "crc32", catx( "-", symget('sysjobid'), symget('sysprocessid'), put( rand("uniform"), best32.), put( datetime(), datetime23.3) ) ) );


      %* add file extension;
      if ( not missing( symget('fileext') ) ) then 
        call catx( '.', str, symget('fileext') );

      
      %* complete path;
      xpath = translate( catx( "/", root, klowcase(str) ), "/", "\") ;
      


      %* debug message;
      if ( upcase(strip(symget( '_cxtf_tmpf_debug_flg' ))) = "TRUE" ) then do ;
        put "(DEBUG)";
        put "(DEBUG) Temporary file path " xpath;
        put "(DEBUG)";
      end ;
      

      %* assign output value ;
      call symput( symget('return'), kstrip(xpath) );

    run;


    %* -- macro exit point ;
    %macro_exit:



    %* -- restore entry state ;
    %if ( &_cxtf_tmpf_syscc ^= 0 ) %then %do;
    
      %let syscc = &_cxtf_tmpf_syscc;
      
      %if ( %symexist(SYSMSG) = 1 ) %then %do;
	      %let sysmsg = &_cxtf_tmpf_sysmsg;
	  %end;
	      
    %end;


%mend;

