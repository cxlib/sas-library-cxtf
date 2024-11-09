/*
* Enable or disable CXTF options
*
* @param options Options to enable or disable
*
* @description
*
* An option is a single word keyword. An option specified 
* as NO<option> disables.
*
*   DEBUG      Enable debug mode
*
*
*/


%macro cxtf_options( options = );

  %global CXTF_OPTIONS ;

  %local _cxtf_known_opts
         _cxtf_i _cxtf_opt _cxtf_subopt
         _cxtf_opt_toadd _cxtf_opt_toremove _cxtf_opt_lst
  ;

  %* -- set up a list of known options ; 
  %let _cxtf_known_opts = DEBUG VERBOSE;


  %let _cxtf_i = 1 ;

  %do %while ( %scan( &options, &_cxtf_i, %str( ) ) ^= %str() );
    
    %* get option and move pointer ; 
    %let _cxtf_opt = %scan( &options, &_cxtf_i, %str( ) ) ;
    %let _cxtf_i = %eval( &_cxtf_i + 1 );

    %* next iteration as it is too small ;
    %if ( %length(&_cxtf_opt) < 2 ) %then %goto continue_w_options ;

    %* asses if it the intent is to disable the option ;
    %if ( %upcase(%substr( &_cxtf_opt, 1, 2 )) = NO ) %then %do;

        %let _cxtf_subopt = %substr( &_cxtf_opt, 3 );

        %* the option to disable is not known ;
        %if ( %sysfunc(findw( &_cxtf_known_opts, &_cxtf_subopt, , ies )) = 0 ) %then %do;
          %goto continue_w_options ;
        %end;

        %* add the option to the remove list ;
        %let _cxtf_opt_toremove = &_cxtf_opt_toremove &_cxtf_subopt ;

        %goto continue_w_options;
    %end;

    %* not known ;
    %if ( %sysfunc(findw( &_cxtf_known_opts, &_cxtf_opt, , ies )) = 0 ) %then %do;
      %put %str(ER)ROR: Option %upcase(&_cxtf_opt) is not known ;
      %goto continue_w_options ;
    %end;

    %* add the option to the add list ;
    %let _cxtf_opt_toadd = &_cxtf_opt_toadd &_cxtf_opt ;


    %* do-loop next iteration ;
    %continue_w_options:
  %end;


  %* -- build new list of options ;
  %let _cxtf_opt_lst = ;

  %let _cxtf_i = 1 ;

  %do %while ( %scan( &CXTF_OPTIONS &_cxtf_opt_toadd, &_cxtf_i, %str( ) ) ^= %str() );

    %* get option and move pointer ; 
    %let _cxtf_opt = %scan( &CXTF_OPTIONS &_cxtf_opt_toadd, &_cxtf_i, %str( ) ) ;
    %let _cxtf_i = %eval( &_cxtf_i + 1 );

    %* futility ... option not known;
    %if ( %sysfunc(findw( &_cxtf_known_opts, &_cxtf_opt, , ies )) = 0 ) %then %do;
      %put %str(ER)ROR: Option %upcase(&_cxtf_opt) is not known ;
      %goto continue_w_list ;
    %end;

    %* disabled;
    %if ( ( &_cxtf_opt_toremove ^= %str()) and ( %sysfunc(findw( &_cxtf_opt_toremove, &_cxtf_opt, , ies )) > 0 ) ) %then %do;
      %goto continue_w_list ;
    %end;

    %* duplicate ;
    %if ( ( &_cxtf_opt_lst ^= %str() ) and ( %sysfunc(findw( &_cxtf_opt_lst, &_cxtf_opt, , ies )) > 0 ) ) %then %do;
      %goto continue_w_list ;
    %end;


    %* finally ... we can add it ;
    %let _cxtf_opt_lst = &_cxtf_opt_lst %upcase(&_cxtf_opt);


    %* do-loop next iteration ;
    %continue_w_list:
  %end;



  %* -- save options ;
  %let cxtf_options = &_cxtf_opt_lst;
 
%mend; 


