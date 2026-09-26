/*
* Simple utility to generate a macro call stack trace 
*
*/

%macro _cxtf_stacktrace() ;

    %local _cxtf_i ;


    %* -- add trace to the log ;

    %put %str( );
    %put %str(ER)ROR: (cxtf) Macro stack trace;
    %put %str(ER)ROR: (cxtf) ---------------------------------------;

    %do _cxtf_i = %eval( %sysmexecdepth - 1 ) %to 1 %by -1;

      %if ( &_cxtf_i = %eval( %sysmexecdepth - 1 ) ) %then 
        %put %str(ER)ROR: (cxtf) %sysmexecname( &_cxtf_i );
      %else 
         %put %str(ER)ROR: (cxtf) ... called from %str( ) %sysmexecname( &_cxtf_i ) ;

    %end;

    %put %str( );


    %* -- macro exit point ;
    %macro_exit:   

%mend;



