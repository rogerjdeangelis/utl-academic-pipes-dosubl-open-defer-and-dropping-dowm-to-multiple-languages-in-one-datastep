Academic pipes dosubl open defer and dropping dowm to multiple languages in one datastep

Doing the following in just one datastep

       PIPES
       DOSUBL
       OPEN=DEFER
       MUTIPLE LANGUAGES

Thanks to Rick Langston

github
https://tinyurl.com/y53wkp5f
https://github.com/rogerjdeangelis/utl-academic-pipes-dosubl-open-defer-and-dropping-dowm-to-multiple-languages-in-one-datastep

macros
https://tinyurl.com/y9nfugth
https://github.com/rogerjdeangelis/utl-macros-used-in-many-of-rogerjdeangelis-repositories

SOAPBOX ON
  If SAS ever decides to document and enhance DOSUBL it could LIMIT the need for programmers
  deleve into complex bloated software. Less is More. Theoretically this technique, can be much faster
  then multiple individual daatasteps? Right now is very slow?
  SAS needs to beef up the data step compiler?
SOAPBOX OFF

 PROCESS

      1. Change all missing values to 0
      2. Sort row elements ie x1=smallest of (x1,x2,x3), x2=next smallest of (x1,x2,x3)..
      3. Sort rows by sex  (Females first then Males)
      4. In another language ie R, Python or Perl
            Add two additional rows one for males and one for females
            For sex set x1=min(of all x1s rows), x2=max(of all x2 rows) and x3=mean of x3
      5. Finally add a column with the sum of (x1,x2,x3) for all data

  What's going on is a series of pipes (could replace some subprocesses with views)

    PIPES

      1.  proc stdize data=have missing=0 reponly out=sd1.MISS_TO_ZERO  miss to 0 >>;
      2.  Call Sort (x1,x2,x3)                     >>
      3.  Proc sort by sex                         >>
      4.  Proc sql min, max  and mean by sex       >>
      5.  Operate on the resulting tableOperate on the resulting table
*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;

* just in case cleal all tables in the schema;
libname sd1 "d:/sd1";
proc datasets lib=sd1 kill;
run;quit;

data have;
 retain seq sum_x1_x2_x3 0 action;

 do sex="M","F";
   do rec=1 to 4;
      do i = 1 to 3;
         array xs[3] x1-x3;
         if uniform(4737)< .25 then xs[i]=.;
         else xs[i]=int(100*uniform(4567));
      end;
      seq+1;
      select (rec);
         when (1) action="MISS_TO_ZERO >>            ";
         when (2) action="SORT_WITHIN_ROW >>         ";
         when (3) action="SORT_BY_SEX >>             ";
         when (4) action="MINX1_MAX2_MEANX3_BY_SEX >>";
         otherwise;
      end; /* leave off otherwise to force error */;
      output;
   end;
 end;

 drop i rec;
run;quit;


/*
 SEQ    ACTION

  1     MISS_TO_ZERO
  2     SORT_WITHIN_ROW
  3     SORT_BY_SEX
  4     MINX1_MAX2_MEANX3_BY_SEX

WORK.HAVE total obs=8

  SEQ    ACTION                      SEX    X1    X2    X3

   1     MISS_TO_ZERO                 M      .    96    63
   2     SORT_WITHIN_ROW              M      9    87    11
   3     SORT_BY_SEX                  M     52    42    36
   4     MINX1_MAX2_MEANX3_BY_SEX     M      .    96     .
   5     MISS_TO_ZERO                 F     87    81    74
   6     SORT_WITHIN_ROW              F     68    24    15
   7     SORT_BY_SEX                  F      .     .    36
   8     MINX1_MAX2_MEANX3_BY_SEX     F     91     .    42

*/

*            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;


SD1.WANT total obs=10
                                                   Ordered Miss=0
                                                   -----------------
Obs    SEQ    ACTION                         SEX    X1    X2      X3   SUM_X1_X2_X3

  1      5    MISS_TO_ZERO >>                 F     74    81    87.00    242.00    FEMALES SORTED FIRST
  2      6    SORT_WITHIN_ROW >>              F     15    24    68.00    107.00
  3      7    SORT_BY_SEX >>                  F      0     0    36.00     36.00
  4      8    MINX1_MAX2_MEANX3_BY_SEX >>     F      0    42    91.00    133.00

                                                    MIN  MAX     MEAN    SUM_X1_X2_X3
  5     99    RESULT OF ACTIONS ABOVE         F      0    81    70.50    151.50



  6      1    MISS_TO_ZERO >>                 M      0    63    96.00    159.00
  7      2    SORT_WITHIN_ROW >>              M      9    11    87.00    107.00
  8      3    SORT_BY_SEX >>                  M     36    42    52.00    130.00
  9      4    MINX1_MAX2_MEANX3_BY_SEX >>     M      0     0    96.00     96.00

 10     99    RESULT OF ACTIONS ABOVE         M      0    63    82.75    145.75

*
 _ __  _ __ ___   ___ ___  ___ ___
| '_ \| '__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|
;

libname sd1 "d:/sd1";

data sd1.want (drop=rc);

  set have(obs=4) sd1.minx1_max2_meanx3_by_sex(in=b) open=defer;


   select (action);
        when ("MISS_TO_ZERO >>") do; rc=dosubl('
            libname sd1 "d:/sd1";
            proc stdize data=have out=sd1.MISS_TO_ZERO missing=0 reponly;
            run;quit;
            libname sd1 clear;
            run;quit;
            ');
        end;

        when ("SORT_WITHIN_ROW >>") do; rc=dosubl('
            libname sd1 "d:/sd1";
            data sd1.SORT_WITHIN_ROW;
              set sd1.MISS_TO_ZERO;
              call sort(of x:);
            run;quit;
            libname sd1 clear;
            run;quit;
            ');
        end;
        when ("SORT_BY_SEX >>") do; rc=dosubl('
            libname sd1 "d:/sd1";
            proc sort data=sd1.SORT_WITHIN_ROW  out=sd1.SORT_BY_SEX;
            by sex;
            run;quit;
            libname sd1 clear;
            run;quit;
            ');
        end;
        when ("MINX1_MAX2_MEANX3_BY_SEX >>") do; rc=dosubl('
            %utl_submit_wps64(%nrstr(
            libname sd1 "d:/sd1";
            proc sql;
               create
                  table sd1.MINX1_MAX2_MEANX3_BY_SEX as
               select
                  sex
                 ,seq
                 ,action
                 ,x1
                 ,x2
                 ,x3
               from
                  sd1.SORT_BY_SEX
               union
                  corr
               select
                   sex
                  ,99 as seq
                  ,"RESULT OF ACTIONS ABOVE"  as action
                  ,sum_x1_x2_x3
                  ,min(x1) as x1
                  ,max(x2) as x2
                  ,mean(x3) as x3
               from
                  sd1.SORT_BY_SEX
               group
                  by 1,2,3,4
            ;quit;
            libname sd1 clear;
            run;quit;
              ));
            ');
        end;
        otherwise putlog "***ERROR UNKNOWN CATEGORY***" ACTION=;
   end;

   sum_x1_x2_x3=sum(x1,x2,x3);

   if b then output;

run;quit;


