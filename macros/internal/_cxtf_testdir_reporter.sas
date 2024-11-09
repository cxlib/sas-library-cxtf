/*
* Simple utility to report the results of test files in a test directory
*
* @param path Test directory path 
*
*
*/

%macro _cxtf_testdir_reporter( path = );

   %* note: temporary data sets using prefix _cxtfwrk.__cxtf_testdir_rpt_* ;

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


    %* -- clean up any existing artifacts ;
    proc datasets  library = _cxtfwrk nolist nodetails;
      delete __cxtf_testdir_rpt_: ; run;
    quit;



    %* -- baseline reporting scope ;
    %*    note: contains list of test files in test directory ;

    data _cxtfwrk.__cxtf_testdir_rpt_scope;
      set _cxtfrsl.cxtftestidx ;

      length param_path parent_dir $ 4096 ;
      retain param_path ;

      if ( _n_ = 1 ) then 
        param_path = translate( strip(symget('path')), "/", "\" );

      parent_dir = ksubstr( strip(testfile), 1, klength(strip(testfile)) - klength(scan( strip(testfile), -1, "/" )) - 1 ); 

      if ( lowcase(strip(parent_dir)) = lowcase(strip(param_path)) ) then 
         output;

    run;


    %* -- log report test results ;

    data _cxtfwrk.__cxtf_testdir_rpt_mtx ;

       length result $ 5 ;

       resultn = 0;

       do result = "Pass", "Skip", "Fail" ;
         resultn = resultn + 1 ;
         output;
       end;

    run;


    proc sql noprint;

        create table _cxtfwrk.__cxtf_testdir_rpt_results as
          select * from _cxtfrsl.cxtfresults
            where ( testid in (select testid from  _cxtfwrk.__cxtf_testdir_rpt_scope ) ) 
        ;


        create table _cxtfwrk.__cxtf_testdir_rpt_res as 
           select a.resultn, a.result, coalesce( b.resultcount, 0) as resultcount 
              from _cxtfwrk.__cxtf_testdir_rpt_mtx a
                   left join 
                   ( select result, count(*) as resultcount from _cxtfwrk.__cxtf_testdir_rpt_results 
                        group by result ) b
              on ( lowcase(strip(a.result)) = lowcase(strip(b.result)) )
              order by resultn, result
        ;

    quit;

           
    data _cxtfwrk.__cxtf_testdir_rpt_sum ;
      set _cxtfwrk.__cxtf_testdir_rpt_res   end = eof  ;

      length rptline resstr $ 300 ;
      retain resstr ;

      if ( _n_ = 1 ) then do;

        %* - add line identifying test file ;
        rptline = catx( " ", "Test directory", translate(symget('path'), "/", "\") );
        output;

        %* - reset ;
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



    proc sql noprint;
      create table _cxtfwrk.__cxtf_testdir_rpt_msgsbyfile as
        select a.testfile, a.hash_sha1, a.test, a.testid, b.assertion, b.result, b.message
          from _cxtfwrk.__cxtf_testdir_rpt_scope a 
               left join
               (select testid, assertion, result, message from _cxtfrsl.cxtfresults where not missing(message)) b
          on ( strip(a.testid) = strip(b.testid) )
          order by testfile, test, testid 
      ;
    quit; 



    data _cxtfwrk.__cxtf_testdir_rpt_msgs ;
      set _cxtfwrk.__cxtf_testdir_rpt_msgsbyfile ;
      by testfile test testid ;

      length act $ 200 ;

      select ( lowcase(strip(assertion)) );
        when ( "_cxtf_test_processlog" )   act = "Test Log";
        when ( "_cxtf_test_post" )         act = "Test";

        otherwise                          act = lowcase(strip(assertion));
      end;

      actwidth = klength(strip(act)) ;

      keep testfile hash_sha1 test testid result act actwidth message ;
    run;


    %let _cxtf_rpt_colwidth = 20;

    proc sql noprint;
       select max(actwidth) into: _cxtf_rpt_colwidth separated by ' ' 
         from _cxtfwrk.__cxtf_testdir_rpt_msgs 
       ;
    quit;


    data _cxtfwrk.__cxtf_testdir_rpt_detail ;
      set _cxtfwrk.__cxtf_testdir_rpt_msgs ;
      by testfile test testid ;

      length rptline $ 300 ;
      retain _maxwidth 20 ;

      if ( _n_ = 1 ) then 
        _maxwidth = input( strip(symget('_cxtf_rpt_colwidth')), 8.);

      %* - if it is a pass and no additiona detail ... nothing to report ;
      if missing(message) then
        return ;


      if first.testfile then do;

        call missing(rptline);
        output;

        rptline = catx( " ", "Test file", scan(strip(testfile), -1, "/") ) ;
        output;

        rptline = "---------------------------------------" ;
        output;

      end;


      if first.testid then do ;

        call missing(rptline);
        output;

        rptline = catx( " ", "Test", test, cats("(", catx( " ", "ID", testid), "):" ) );
        output;

        call missing(rptline);
      end;


      %* - add result and the assertion ; 
      rptline = catx( "   ", propcase(result), act );     

      %* - add message ;
      call catx( repeat( " ", _maxwidth - klength(strip(act)) + 3) , rptline, message );   

      %* - ensure line is not too long; 
      if ( klength(strip( rptline )) > 80 ) then 
         rptline = catx( " ", ksubstr( strip(rptline), 1, 75 ), "..." );

      output;


      if last.testfile then do;
        call missing(rptline);
        output; output;
      end;
         

      keep rptline ;
    run;



    data _null_ ;
      set _cxtfwrk.__cxtf_testdir_rpt_sum  (in = a) 
          _cxtfwrk.__cxtf_testdir_rpt_detail (in = b)  end = eof ;


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
        delete __cxtf_testdir_rpt_: ; run;
      quit;
    %end;


    %* -- restore entry state ;
    %if ( &_cxtf_syscc ^= 0 ) %then %do;
      %let syscc = &_cxtf_syscc;
      %let sysmsg = &_cxtf_sysmsg;
    %end;


%mend;
