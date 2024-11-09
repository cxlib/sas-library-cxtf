/*
*  Examples for testing if data set exists 
*
*
*
*/

%macro test_data_exists();

  %* -- stage a data set ;

  proc sql noprint;

    create table work.test_data (
      variable1 char(200)
    );

  quit;


  %* -- assertion ;
  %cxtf_expect_dataexists( data = work.test_data );


  %* -- clean up ;
  proc datasets library = work  nolist nodetails ;
    delete test_data ;  run;
  quit;  


%mend;



%macro test_data_notexists();


  %* -- assertion ;
  %cxtf_expect_dataexists( data = work.test_data, not = TRUE );


%mend;





%macro test_data_notexists_2();


  %* -- assertion ;
  %cxtf_expect_dataexists( data = work.data_not_exists, not = TRUE );


%mend;



