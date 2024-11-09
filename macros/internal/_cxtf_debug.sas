/*
* Internal utility to post debug information
*
*

*/

%macro _cxtf_debug( return = );


  %global cxtf_options ;

  %local ___debug_flag 
         
  ;


  %* -- derive flag variable ;
  %let ___debug_flag = %eval( %sysfunc(findw( &cxtf_options, %str(DEBUG))) > 0 ) ;

  %if ( &return ^= %str() ) %then %do;
    %let &return = &___debug_flag ;
  %end;

  
  %* -- no debug here ;
  %if ( &___debug_flag = 0 ) %then %goto macro_exit ;



  %put %str(DEBUG) ------------------------------------------------------------;
  %put %str(DEBUG) Macro %str( ) %sysmexecname( %eval(%sysmexecdepth - 1) );

  %if ( %sysmexecdepth > 1 ) %then 
    %put %str(DEBUG) Called from %str( ) %sysmexecname( %eval(%sysmexecdepth - 2) );

  %put %str(DEBUG) SYSCC=&syscc;
  %put %str(DEBUG) SYSMSG=&sysmsg;
  %put %str(DEBUG) ------------------------------------------------------------;




  %* -- macro exit point ;
  %macro_exit:


%mend;

