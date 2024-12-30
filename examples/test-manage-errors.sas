/*
*  Examples for testing with errors
*
*  Managing errors is through annotations
*   header annotation preceds the test macro
*   inline annotation is in the macro definition
*   one annotation per line
*   annotation is for entire macro ... no block context
*   annotations cannot wrap multiple lines 
*   ignores case ;
*   match is a starts with match ;
*
*/


* note: header @error annotation ;
*
%* @error ;
%macro test_anyerror();

  data _null_;
    set work.idonotexist ;
  run;

%mend;



* note: header @error annotation ;
*
%* @error File WORK.IDONOTEXIST.DATA does not exist ;
%macro test_specifiederror_anno();

  data _null_;
    set work.idonotexist ;
  run;

%mend;

* note: inline @error annotation ;
%macro test_specifiederror_inlineanno();

  %* @error File WORK.IDONOTEXIST.DATA does not exist ;
  data _null_;
    set work.idonotexist ;
  run;

%mend;


* note: the @error in header is any error ;
* note: the inline @error is specified as expected;
* note: the expected must exists and any can be at least one error ;
*
* @error ;
%macro test_any_and_specified_error();

  data _null_ ;
    set really.something;
  run;

  %* @error File WORK.IDONOTEXIST.DATA does not exist ;
  data _null_;
    set work.idonotexist ;
  run;

%mend;




* @error ;
%macro test_anycustom_error();

  %put %str(ER)ROR: This is my custom error ;

%mend;


* note: as inline @error annotation ;
%macro test_anycustom_inerror();

  * @error ;
  %put %str(ER)ROR: This is my custom error ;

%mend;



* @error This is my custom ;
%macro test_expectcustom_error();

  %put %str(ER)ROR: This is my custom error ;

%mend;



* note: as inline @error annotation ;
%macro test_expectcustom_inerror( a = 1 );

  * @error [1] This is my custom ;
  %put %str(ER)ROR: [&a] This is my custom error for  ;

%mend;



* note: calling a previous test with parameters use header @error annotation  ;
* note: test macro definition annotation is ignored ;
* ;
* @error [2] This is my custom error ;
%test_expectcustom_inerror( a = 2 );

