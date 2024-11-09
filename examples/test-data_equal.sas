/*
* Examples for testing if metadata (PROC CONTENTS) of a data set is equal
*
*
*
*
*/

%macro test_ds_is_equal();

   %* -- stage data ;
   proc copy  in = sashelp  out = work ;
     select cars ; 
   run;

   %* -- stage compare data set ;
   proc sql noprint;
      create table work.cars_compare as
        select * from work.cars
      ;
   quit;

   


   %* --  assert ;
   %cxtf_expect_dataequal( data = work.cars, compare = work.cars_compare );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete cars: ; run;
   quit;

%mend;




%macro test_dsmeta_is_notequal();

   %* -- stage data ;
   proc copy  in = sashelp  out = work ;
     select cars ; 
   run;

   %* -- stage compare data set ;
   proc sql noprint;
      create table work.cars_compare as
        select * from work.cars
      ;
   quit;

   
   proc datasets  library = work nolist nodetails;
     modify cars_compare ;
       label cylinders = "NO Cylinders";
     run;
   quit;



   %* --  assert ;
   %cxtf_expect_dataequal( data = work.cars, compare = work.cars_compare, obs = FALSE, not = TRUE );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete cars: ; run;
   quit;

%mend;



     
%macro test_ds_justobs_is_equal();

   %* -- stage data ;
   proc copy  in = sashelp  out = work ;
     select cars ; 
   run;

   %* -- stage compare data set ;
   proc sql noprint;
      create table work.cars_compare as
        select * from work.cars
      ;
   quit;

   
   proc datasets  library = work nolist nodetails;
     modify cars_compare ;
       label cylinders = "NO Cylinders";
     run;
   quit;



   %* --  assert ;
   %cxtf_expect_dataequal( data = work.cars, compare = work.cars_compare, meta = );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete cars: ; run;
   quit;

%mend;



%macro test_ds_justobs_is_notequal();

   %* -- stage data ;
   proc copy  in = sashelp  out = work ;
     select cars ; 
   run;

   %* -- stage compare data set with difference ;
   data work.cars_compare ;
     set work.cars ;

     %* lets pick on the first record of cylinders ;
     if ( _n_ = 1 ) then do;
       _orig_value = cylinders;
       cylinders = 10*cylinders ;

       %* add note to log ;
       _str_note = catx( " ", "Changing first record of CYLINDERS from", put( _orig_value, best32. ), "to", put( cylinders, best32.) );
       put "NOTE: " _str_note ;

     end;

     drop _orig_value _str_note ;
   run;

   


   %* --  assert ;
   %*     note: making sure OBS is enabled ; 
   %cxtf_expect_dataequal( data = work.cars, compare = work.cars_compare, obs = TRUE, meta = , not = TRUE );
   


   %* -- clean up ;
   proc datasets library = work nolist nodetails ;                                                
     delete cars: ; run;
   quit;

%mend;

