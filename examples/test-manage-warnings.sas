/*
*  Examples for testing with warnings
*
*  Managing wanrings is through annotations
*   header annotation preceds the test macro
*   inline annotation is in the macro definition
*   one annotation per line
*   annotation is for entire macro ... no block context
*   annotations cannot wrap multiple lines 
*   ignores case ;
*   match is a starts with match ;
*
*/

* @warning ;
%macro test_anywarning();

   %put &idonotexist; 

%mend;



%macro test_anywarning_inline();

   * @warning ;
   %put &idonotexist; 

%mend;


* @warning Apparent symbolic reference IDONOTEXIST not resolved ;
%macro test_expectedwarning();

   %put &idonotexist; 

%mend;



%macro test_expectedwarning_inline();

   * @warning Apparent symbolic reference IDONOTEXIST not resolved ;
   %put &idonotexist; 

%mend;




* @warning ;
%macro test_anycustom_warn();

  %put %str(WA)RNING: This is my custom warning ;

%mend;


* note: as inline @warning annotation ;
%macro test_anycustom_inwarn();

  * @warning ;
  %put %str(WA)RNING: This is my custom warning ;

%mend;



* @warning This is my custom ;
%macro test_expectcustom_warn();

  %put %str(WA)RNING: This is my custom warning ;

%mend;



* note: as inline @warning annotation ;
%macro test_expectcustom_inwarn( a = 1 );

  * @warning [1] This is my custom ;
  %put %str(WA)RNING: [&a] This is my custom warning ;

%mend;


* note: calling a previous test with parameters use header @warning annotation  ;
* note: test macro definition annotation is ignored ;
* ;
* @warning [2] This is my custom ;
%test_expectcustom_inwarn( a = 2 );



