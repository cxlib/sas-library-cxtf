/*
* Simple utility to report the results of a single test
*
*
*
*/

%macro _cxtf_test_reporter();

   %* note: temporary data sets using prefix _cxtfwrk.__cxtf_[cxtf_testid]_rpt_* ;

    %local _cxtf_rc _cxtf_syscc _cxtf_sysmsg _cxtf_debug_flg
           _cxtf_rpt_colwidth
    ;

    %* -- capture entry state ;
    %let _cxtf_syscc = 0;
    %let _cxtf_sysmsg = ;

    %if ( &syscc ^= 0 ) %then %do;
      %let _cxtf_syscc = &syscc;
      %let _cxtf_sysmsg = &sysmsg;

      %let syscc = 0;
      %let sysmsg = ;

    %end;


    %_cxtf_debug( return = _cxtf_debug_flg );


    *% -- test id required ;
    %if ( %symexist(cxtf_testid) = 0 ) %then %do;
      %put Expected CXTF_TESTID not defined;
      %goto macro_exit;
    %end;


    %* -- clean up any existing artifacts ;
    proc datasets  library = _cxtfwrk nolist nodetails;
      delete __cxtf_&cxtf_testid._rpt_: ; run;
    quit;




    %* -- log report test results ;

    data _cxtfwrk.__cxtf_&cxtf_testid._rpt_mtx ;
       set _cxtfrsl.cxtftestidx  ;
       where ( strip(testid) = strip(symget( 'cxtf_testid' )) ) and
             ( strip(type) = "test" ) ;

       length result $ 5 ;

       do result = "Pass", "Fail", "Skip" ;
         output;
       end;

       keep testid test result ;
    run;


    proc sql noprint;

        create table _cxtfwrk.__cxtf_&cxtf_testid._rpt_res as 
           select a.testid, a.test, a.result, coalesce( b.resultcount, 0) as resultcount 
              from _cxtfwrk.__cxtf_&cxtf_testid._rpt_mtx a
                   left join 
                   ( select testid, result, count(*) as resultcount from _cxtfrsl.cxtfresults 
                        group by testid, result ) b
              on ( lowcase(strip(a.testid)) = lowcase(strip(b.testid)) ) and 
                 ( lowcase(strip(a.result)) = lowcase(strip(b.result)) )
        ;

    quit;

           
    data _cxtfwrk.__cxtf_&cxtf_testid._rpt_sum ;
      set _cxtfwrk.__cxtf_&cxtf_testid._rpt_res   end = eof  ;

      length rptline resstr $ 300 ;
      retain resstr ;

      if ( _n_ = 1 ) then do;

        %* - add line identifying test ;
        rptline = strip(test);
        output;

        call missing(rptline, resstr );

      end;


      %* -- build resuots line ;
      call catx( "  ", resstr, catx( ": ", propcase(strip(result)), strip(put( resultcount, 8. )) ) ); 


      if eof then do;
        %* - add line with result summary ;
        rptline = catx( "   ", "Result", resstr );
        output;
      end;

      keep rptline;
    run;


  


    data _cxtfwrk.__cxtf_&cxtf_testid._rpt_msgs ;
      set _cxtfrsl.cxtfresults ;
      where ( testid = symget( 'cxtf_testid' )) ;

      length act $ 200 ;

      select ( lowcase(strip(assertion)) );
        when ( "_cxtf_test_processlog" )   act = "Test Log";
        when ( "_cxtf_test_post" )         act = "Test";

        otherwise                          act = lowcase(strip(assertion));
      end;

      actwidth = klength(strip(act)) ;

      keep testid result act actwidth message ;
    run;


    %let _cxtf_rpt_colwidth = 20;

    proc sql noprint;
       select max(actwidth) into: _cxtf_rpt_colwidth separated by ' ' 
         from _cxtfwrk.__cxtf_&cxtf_testid._rpt_msgs 
       ;
    quit;


    data _cxtfwrk.__cxtf_&cxtf_testid._rpt_detail ;
      set _cxtfwrk.__cxtf_&cxtf_testid._rpt_msgs ;

      length rptline $ 300 ;
      retain _maxwidth 20 ;

      if ( _n_ = 1 ) then 
        _maxwidth = input( strip(symget('_cxtf_rpt_colwidth')), 8.);

      %* - if it is a pass and no additiona detail ... nothing to report ;
      if ( ( lowcase(strip(result)) = "pass" ) and
           missing(message) ) then
        return ;



      %* - add result and the assertion ; 
      rptline = catx( "   ", propcase(result), act );     

      %* - add message ;
      call catx( repeat( " ", _maxwidth - klength(strip(act)) + 3) , rptline, message );   

      %* - ensure line is not too long; 
      if ( klength(strip( rptline )) > 80 ) then 
         rptline = catx( " ", ksubstr( strip(rptline), 1, 75 ), "..." );

      output;

      keep rptline ;
    run;



    data _null_ ;
      set _cxtfwrk.__cxtf_&cxtf_testid._rpt_sum  (in = a) 
          _cxtfwrk.__cxtf_&cxtf_testid._rpt_detail (in = b)  end = eof ;


      if ( _n_ = 1 ) then 
         put " " //
             "---------------------------------------------------------------------------------" ;
      if a then 
        put rptline / " "; 

      if b then 
        put rptline ;

      if eof then 
         put " " /
             "---------------------------------------------------------------------------------" ;


    run;






    %* -- macro exit point ;
    %macro_exit:


    %if ( &_cxtf_debug_flg = 0 ) %then %do;
      proc datasets  library = _cxtfwrk nolist nodetails;
        delete __cxtf_&cxtf_testid._rpt_: ; run;
      quit;
    %end;


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
