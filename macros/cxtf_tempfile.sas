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


    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug
           _str
    ;

    %* print debug details ;
    %_cxtf_debug();


    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
      %let _cxtf_syscc = &syscc;
      %let _cxtf_sysmsg = &sysmsg;

      %let syscc = 0;
      %let sysmsg = ;

    %end;


    %* -- generate string ;

    data _null_ ;

      length root $ 4096 
             str $ 1024 ;

      %* -- identify parent path ;
      %* note: if not specified, using path of WORK library ;
      root = symget('path');

      if ( missing(root) ) then
        root = pathname('WORK');


      %* initililze with prefix ;
      str = strip(symget('prefix'));


      %* force first character to be A-Z-ish (thanks SAS) ;
      if missing(str) then 
         str = byte( mod( floor(100*rand("uniform")), 26) + rank("A") - 1 ) ; 

      %* add random string ;
      call cats( str, hashing( "crc32", catx( "-", symget('sysjobid'), symget('sysprocessid'), put( rand("uniform"), best32.), put( datetime(), datetime23.3) ) ) );


      %* add file extension;
      if ( not missing( symget('fileext') ) ) then 
        call catx( '.', str, symget('fileext') );


      %* assign output value ;
      call symput( symget('return'), translate( catx( "/", root, lowcase(str) ), "/", "\") );

    run;


    %* -- macro exit point ;
    %macro_exit:



    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;

