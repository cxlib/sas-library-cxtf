
cxtf is a a test framework for and written entirely in SAS


This is an initial experimental early development release (hence use with caution).



## Getting Started

Download the latest release of cxtf https://github.com/cxlib/sas-library-cxtf/releases/latest

<br/>

Add both the `<install directory>/macros` and `<install directory>/macros/internal` directories to `SASAUTOS`.

```
options SASAUTOS = ( "<install directory>/macros", "<install directory>/macros/internal", !SASAUTOS );
```

<br/>

Run the examples

```
* make sure it is a clea environment ;
%cxtf_init( reset = TRUE );

* run all the examples ;
%cxtf_testdir( path = <install directory>/examples );
```

<br/>

You can also run each test file individually.

```
%cxtf_testfile( path = <file>); 
```

<br/>

You can enable or disable a simple debug mode.

```
* -- enable debug ;
%cxtf_options( options = debug );

* -- disable debug ;
%cxtf_options( options = nodebug );
```

<br/>
<br/>

## How It Works
The tests are defined across test programs that start with the prefix `test-` or
`test_` and end in the file extension `.sas`, all lower case for now. The test
programs are executed alphabetically in natural sort order. 

Each test program can contain one or more test scenarios. The test scenario is 
written as a SAS macro with its name starting with `test_*`. 

```
%macro test_mytest();

 %* test code goes here ;
 
%mend;
```

You do not have to call a defined test scenario macro to run it, the definition
is enough.

<br/>

A test can also be parameterised using regular macro parameters for the test 
scanario macro. The test scenario is first executed using all defaults and
then each subsequent call to the test scenario macro.

```
* -- first test that runs ;
%macro test_mytest( a = 1, b = 2 );

 %* test code goes here ;
 
%mend;

* -- second test that runs ;
%test_mytest( a = 99, b = 88 );
```

<br/>

### Assertions

Each test scenario uses the concept of assertions to verify that things are or
are not equal. The release contains a set of standard assertion macros that all
start with `cxtf_expect_*`. 

```
%macro test_vars_equal();

  %* -- stage ;
  %local var1 var2 ;

  %let var1 = Abc123;
  %let var2 = &var1;


  %* -- assertion;
  %cxtf_expect_mvarisequal( variable = var1, compare = var2 );


  %* -- no clean up as local variables are drestroyed at the end of the macro ;


%mend;
```

<br/>

The `not`parameter will negate the assertion. 

```
%macro test_vars_notequal();

  %* -- stage ;
  %local var1 var2 ;

  %let var1 = Abc123;
  %let var2 = %upcase(&var1);


  %* -- assertion;
  %cxtf_expect_mvarisequal( variable = var1, compare = var2, not = TRUE );


  %* -- no clean up as local variables are drestroyed at the end of the macro ;


%mend;
```

<br/>
The current list of assertions 

Assertion macro            | Description
---------------------------| -------------------------------------------------
cxtf_expect_mvarexists     | Macro variable exists in scope
cxtf_expect_mvarequal      | Macro variable is equal to a specified value
cxtf_expect_mvarisequal    | Two macro variable values are equal
cxtf_expect_dataexists     | Data set exists
cxtf_expect_dataequal      | Compare two data sets
cxtf_expect_varexists      | Variables exist in a data set


<br/>

### Assessing test scenario logs
The log for each test scenario is assessed. 

Currently, it is expected that a test scenario executes without any errors or
warnings. Support for asserting that a specific error and/or warning has been 
generated is on the roadmap.


<br/>

### Reporting
Each test, test file and test directory execution will result in a short report 
in the log.

```
---------------------------------------------------------------------------------
Test directory <directory>

Result   Pass: 24  Skip: 0  Fail: 0


---------------------------------------------------------------------------------
```

The numbers for Fail, Skip and Pass are the number of assertions, just to get us
going. 

More comprehensive reporting is in the plans.



