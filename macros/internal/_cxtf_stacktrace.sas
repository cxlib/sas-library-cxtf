/*
* Simple utility to generate a macro call stack trace 
*
*/

%macro _cxtf_stacktrace() ;

    %local _cxtf_i ;


    %* -- add trace to the log ;

    %put %str( );
    %put Macro stack trace;
    %put ---------------------------------------;

    %do _cxtf_i = %eval( %sysmexecdepth - 1 ) %to 1 %by -1;

      %if ( &_cxtf_i = %eval( %sysmexecdepth - 1 ) ) %then 
        %put %sysmexecname( &_cxtf_i );
      %else 
         %put ... called from %str( ) %sysmexecname( &_cxtf_i ) ;

    %end;

    %put %str( );


    %* -- macro exit point ;
    %macro_exit:   

%mend;



