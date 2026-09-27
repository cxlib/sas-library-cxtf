/*
* Examples for testing if metadata (PROC CONTENTS) of a data set is equal
*
*
*
*
*/

%macro test_ds_is_equal();

  %* -- stage  ;

  %* - stage 100 records ;
  data work.testdata;

    length str $ 200;

    do _i = 1 to 100;

      %* generate string of 100 random characters ;
      %* using substr substitution ;
      do _j = 1 to 100;
        substr( str, _j) = byte(int(rank("a")+26*ranuni(0)));
      end;

      output;
    end;

    drop _: ;
  run;

   %* - stage compare data set ;
   proc sql noprint;
      create table work.testdata_compare as
        select * from work.testdata
      ;
   quit;


   %* --  assert ;
   %cxtf_expect_dataequal( data = work.testdata, compare = work.testdata_compare );

   
   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete testdata: ; run;
   quit;

%mend;




%macro test_dsmeta_is_notequal();

  %* -- stage ;

  %* - stage 100 records ;
  data work.testdata;

    %* define label for reference variable ;
    %* note: will be modified in the compare data set ;
    length str $ 200;
    label str = "A random string";

    do _i = 1 to 100;

      %* generate string of 100 random characters ;
      %* using substr substitution ;
      do _j = 1 to 100;
        substr( str, _j) = byte(int(rank("a")+26*ranuni(0)));
      end;

      output;
    end;

    drop _: ;
  run;

   %* - stage compare data set ;
   proc sql noprint;
      create table work.testdata_compare as
        select * from work.testdata
      ;
   quit;


   
   proc datasets  library = work nolist nodetails;
     modify testdata_compare ;
       label str = "New label";
     run;
   quit;



   %* --  assert ;
  %cxtf_expect_dataequal( data = work.testdata, compare = work.testdata_compare, obs = FALSE, not = TRUE );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete testdata: ; run;
   quit;

%mend;



     
%macro test_ds_justobs_is_equal();


  %* -- stage ;

  %* - stage 100 records ;
  data work.testdata;

    %* define label for reference variable ;
    %* note: will be modified in the compare data set ;
    length str $ 200;
    label str = "A random string";

    do _i = 1 to 100;

      %* generate string of 100 random characters ;
      %* using substr substitution ;
      do _j = 1 to 100;
        substr( str, _j) = byte(int(rank("a")+26*ranuni(0)));
      end;

      output;
    end;

    drop _: ;
  run;

   %* - stage compare data set ;
   proc sql noprint;
      create table work.testdata_compare as
        select * from work.testdata
      ;
   quit;


   
   proc datasets  library = work nolist nodetails;
     modify testdata_compare ;
       label str = "New label";
     run;
   quit;




   %* --  assert ;
   %cxtf_expect_dataequal( data = work.testdata, compare = work.testdata_compare, meta = );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete testdata: ; run;
   quit;

%mend;



%macro test_ds_justobs_is_notequal();


  %* -- stage ;

  %* - stage 100 records ;
  data work.testdata;

    %* define label for reference variable ;
    %* note: will be modified in the compare data set ;
    length str $ 200;
    label str = "A random string";

    do _i = 1 to 100;

      %* generate string of 100 random characters ;
      %* using substr substitution ;
      do _j = 1 to 100;
        substr( str, _j) = byte(int(rank("a")+26*ranuni(0)));
      end;

      output;
    end;

    drop _: ;
  run;


   %* - stage compare data set ;
   %*   note: change first record ;

   data work.testdata_compare;
     set work.testdata;

     if ( _n_ = 1 ) then do;
       str = "Modified string";
     end;

   run;



   %* --  assert ;
   %*     note: making sure OBS is enabled ; 
   %cxtf_expect_dataequal( data = work.testdata, compare = work.testdata_compare, obs = TRUE, meta = , not = TRUE );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete testdata: ; run;
   quit;

%mend;

