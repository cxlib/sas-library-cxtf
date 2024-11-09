
cxtf is a a test framework for and written entirely in SAS


This is an initial experimental early development release (hence use with caution).

[TOC]


## Getting Started

Download the latest release of cxtf https://github.com/cxlib/sas-library-cxtf/releases/latest

<br/>

Add both the `<install direcrory>/macros` and `<install direcrory>/macros/internal` directories to `SASAUTOS`.

```
options SASAUTOS = ( "<install direcrory>/macros", "<install direcrory>/macros/internal", !SASAUTOS );
```

<br/>

Run the examples

```
* make sure it is a clea environment ;
%cxtf_init( reset = TRUE );

* run all the examples ;
%cxtf_testdir( path = <install direcrory>/examples );
```

<br/>

You can also run each test file individually.

```
%cxlib_testfile( path = <file>); 
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

Each test scenario uses the concept of assertions to verify that things are or
are not equal. The release contains a set of standard assertion macros that all
start with `cxtf_expect_*`. The `not`parameter will negate the assertion. More 
will be added with each release.

Currently, it is expected that a test scenario executes without any errors or
warnings. Support for asserting that a specific error and/or warning has been 
generated is on the roadmap.

Each test, test file and test directory execution will result in a short report 
in the log (PDF reports are in the works). The numbers for Fail, Skip and Pass 
are the number of assertions, just to get us going. 



