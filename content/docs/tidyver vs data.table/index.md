---
title: 'Tidyverse vs data.table: 功能对比与技巧'
date: '2025-12-31'
format: hugo-md
---


本文档系统对比了 R 语言中两个主流数据处理框架 **tidyverse** (以 `dplyr` 为主) 和 **data.table** 的常用功能与技巧。

<details class="code-fold">
<summary>Code</summary>

``` r
library(tidyverse)
library(lubridate)
library(nycflights13)
library(data.table)
library(stringr)

# 准备数据
# Tidyverse 使用 tibble
flights_tbl <- flights

# data.table 需要转换
dt <- as.data.table(flights)
```

</details>

## Tip 1: 在计数或分组中创建新列 (Create new columns in a count or groupby)

在汇总数据的同时直接定义新的分组逻辑，无需预先 mutate。

### Tidyverse

在 `count()` 或 `group_by()` 中直接书写逻辑表达式。

<details class="code-fold">
<summary>Code</summary>

``` r
# 统计飞行时间是否超过 6 小时
flights_tbl |> 
  count(long_flight = air_time >= 6 * 60)
```

</details>

    # A tibble: 3 × 2
      long_flight      n
      <lgl>        <int>
    1 FALSE       322630
    2 TRUE          4716
    3 NA            9430

<details class="code-fold">
<summary>Code</summary>

``` r
# 组合字符串作为分组依据
flights_tbl |> 
  count(flight_path = str_c(origin, '->', dest), sort = TRUE) |> 
  head(5)
```

</details>

    # A tibble: 5 × 2
      flight_path     n
      <chr>       <int>
    1 JFK->LAX    11262
    2 LGA->ATL    10263
    3 LGA->ORD     8857
    4 JFK->SFO     8204
    5 LGA->CLT     6168

<details class="code-fold">
<summary>Code</summary>

``` r
# 在 group_by 中创建日期列并汇总
flights_tbl |> 
  group_by(date = make_date(year, month, day)) |> 
  summarise(
    flights_n = n(), 
    air_time_median = median(air_time, na.rm = TRUE)
  ) |> 
  ungroup() |> 
  head(5)
```

</details>

    # A tibble: 5 × 3
      date       flights_n air_time_median
      <date>         <int>           <dbl>
    1 2013-01-01       842             149
    2 2013-01-02       943             148
    3 2013-01-03       914             148
    4 2013-01-04       915             140
    5 2013-01-05       720             147

### data.table

在 `by` 参数中直接定义表达式。

<details class="code-fold">
<summary>Code</summary>

``` r
# 统计飞行时间是否超过 6 小时
dt[, .N, .(long_flight = (air_time >= 6 * 60))]
```

</details>

       long_flight      N
            <lgcl>  <int>
    1:       FALSE 322630
    2:        TRUE   4716
    3:          NA   9430

<details class="code-fold">
<summary>Code</summary>

``` r
# 组合字符串作为分组依据并排序
dt[, .N, .(flight_path = str_c(origin, '->', dest))][order(-N)] |> head(5)
```

</details>

       flight_path     N
            <char> <int>
    1:    JFK->LAX 11262
    2:    LGA->ATL 10263
    3:    LGA->ORD  8857
    4:    JFK->SFO  8204
    5:    LGA->CLT  6168

<details class="code-fold">
<summary>Code</summary>

``` r
# 复杂的 group by
dt[, 
  .(flights_n = .N, air_time_median = median(air_time, na.rm = TRUE)), 
  .(date = make_date(year, month, day))
] |> head(5)
```

</details>

             date flights_n air_time_median
           <Date>     <int>           <num>
    1: 2013-01-01       842             149
    2: 2013-01-02       943             148
    3: 2013-01-03       914             148
    4: 2013-01-04       915             140
    5: 2013-01-05       720             147

## Tip 2: 随机抽样 (Sample and randomly shuffle data)

### Tidyverse

使用 `slice_sample()` 函数，支持按数量 (`n`) 或比例 (`prop`) 抽样。

<details class="code-fold">
<summary>Code</summary>

``` r
# 随机抽取 10 行
flights_tbl |> slice_sample(n = 10)
```

</details>

    # A tibble: 10 × 19
        year month   day dep_time sched_dep_time dep_delay arr_time sched_arr_time
       <int> <int> <int>    <int>          <int>     <dbl>    <int>          <int>
     1  2013     2    21     1705           1705         0     1826           1830
     2  2013     6     3      720            722        -2     1005           1053
     3  2013     9     3     2053           2100        -7     2258           2245
     4  2013     3    31      605            610        -5      837            905
     5  2013     4     2     1459           1349        70     1609           1457
     6  2013     7    10      629            630        -1      747            755
     7  2013     1    10      907            857        10     1219           1204
     8  2013     8    13     1327           1125       122     1447           1300
     9  2013     5     4      554            600        -6      836            910
    10  2013    12    25      956           1000        -4     1248           1247
    # ℹ 11 more variables: arr_delay <dbl>, carrier <chr>, flight <int>,
    #   tailnum <chr>, origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>,
    #   hour <dbl>, minute <dbl>, time_hour <dttm>

<details class="code-fold">
<summary>Code</summary>

``` r
# 随机抽取 1% 的数据
flights_tbl |> slice_sample(prop = 0.01) |> nrow()
```

</details>

    [1] 3367

<details class="code-fold">
<summary>Code</summary>

``` r
# 分组抽样：每个出发地随机抽取 3 行
flights_tbl |> 
  group_by(origin) |> 
  slice_sample(n = 3) |> 
  ungroup()
```

</details>

    # A tibble: 9 × 19
       year month   day dep_time sched_dep_time dep_delay arr_time sched_arr_time
      <int> <int> <int>    <int>          <int>     <dbl>    <int>          <int>
    1  2013     4    28     1722           1730        -8     2010           2023
    2  2013     3    12     2040           2035         5     2338           2341
    3  2013    10    16     1709           1719       -10     1907           1902
    4  2013     2     6     1439           1445        -6     1714           1744
    5  2013    12    21     1459           1429        30     1710           1655
    6  2013     9    21     1503           1510        -7     1722           1735
    7  2013     3    14     1453           1500        -7     1556           1619
    8  2013     4    10      702            700         2     1216            831
    9  2013     1    13     1344           1350        -6     1533           1545
    # ℹ 11 more variables: arr_delay <dbl>, carrier <chr>, flight <int>,
    #   tailnum <chr>, origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>,
    #   hour <dbl>, minute <dbl>, time_hour <dttm>

### data.table

使用 `sample()` 函数结合行索引 `i` 或 `.SD`。

<details class="code-fold">
<summary>Code</summary>

``` r
# 随机抽取 10 行
dt[sample(.N, 10)]
```

</details>

         year month   day dep_time sched_dep_time dep_delay arr_time sched_arr_time
        <int> <int> <int>    <int>          <int>     <num>    <int>          <int>
     1:  2013     4     4      924            929        -5     1048           1044
     2:  2013    12    21     2003           2001         2     2309           2304
     3:  2013     5     8       12           2025       227      241           2333
     4:  2013    12    20     2013           2015        -2     2128           2126
     5:  2013     1    14      747            753        -6      951           1007
     6:  2013     1     4     2014           1936        38     2129           2056
     7:  2013     2     8       NA           1505        NA       NA           1637
     8:  2013     9     3     1428           1433        -5     1554           1607
     9:  2013     4    28     1642           1647        -5     1920           1948
    10:  2013    12    25     1517           1509         8     1844           1844
        arr_delay carrier flight tailnum origin   dest air_time distance  hour
            <num>  <char>  <int>  <char> <char> <char>    <num>    <num> <num>
     1:         4      EV   4636  N14543    EWR    DCA       44      199     9
     2:         5      B6     65  N586JB    JFK    ABQ      274     1826    20
     3:       188      UA    771  N518UA    JFK    LAX      308     2475    20
     4:         2      B6    418  N266JB    JFK    BOS       39      187    20
     5:       -16      DL   2119  N338NW    LGA    MSP      162     1020     7
     6:        33      EV   5693  N828AS    LGA    IAD       46      229    19
     7:        NA      9E   3393    <NA>    JFK    DCA       NA      213    15
     8:       -13      UA    667  N830UA    EWR    CLE       64      404    14
     9:       -28      UA   1568  N76514    EWR    PBI      140     1023    16
    10:         0      UA    524  N523UA    EWR    PHX      298     2133    15
        minute           time_hour
         <num>              <POSc>
     1:     29 2013-04-04 09:00:00
     2:      1 2013-12-21 20:00:00
     3:     25 2013-05-08 20:00:00
     4:     15 2013-12-20 20:00:00
     5:     53 2013-01-14 07:00:00
     6:     36 2013-01-04 19:00:00
     7:      5 2013-02-08 15:00:00
     8:     33 2013-09-03 14:00:00
     9:     47 2013-04-28 16:00:00
    10:      9 2013-12-25 15:00:00

<details class="code-fold">
<summary>Code</summary>

``` r
# 随机抽取 1% 的数据
dt[sample(.N, .N / 100)] |> nrow()
```

</details>

    [1] 3367

<details class="code-fold">
<summary>Code</summary>

``` r
# 分组抽样：使用 .SD 和 chaining
# 注意：这里仅展示行数统计验证，实际输出为行数据
dt[, .SD[sample(.N, 3)], by = origin]
```

</details>

       origin  year month   day dep_time sched_dep_time dep_delay arr_time
       <char> <int> <int> <int>    <int>          <int>     <num>    <int>
    1:    EWR  2013     1     4     1839           1815        24     2000
    2:    EWR  2013     4    29     2157           2106        51       14
    3:    EWR  2013     7    22     1356           1358        -2     1643
    4:    LGA  2013     3    23     1103           1015        48     1350
    5:    LGA  2013    11    27     1750           1800       -10     1926
    6:    LGA  2013    11     5     1112           1105         7     1413
    7:    JFK  2013     1    23      655            700        -5     1037
    8:    JFK  2013     5    22      944            850        54     1107
    9:    JFK  2013     3     5     1334           1340        -6     1637
       sched_arr_time arr_delay carrier flight tailnum   dest air_time distance
                <int>     <num>  <char>  <int>  <char> <char>    <num>    <num>
    1:           1939        21      UA   1703  N27239    BOS       39      200
    2:           2334        40      EV   4631  N14902    JAX      118      820
    3:           1649        -6      UA   1152  N77261    LAX      323     2454
    4:           1325        25      EV   5485  N709EV    PBI      147     1035
    5:           1919         7      US   2191  N770UW    DCA       52      214
    6:           1335        38      WN   1250  N7740A    DEN      261     1620
    7:           1034         3      DL    763  N711ZX    LAX      356     2475
    8:           1014        53      9E   3465  N906XJ    BOS       43      187
    9:           1648       -11      B6     83  N599JB    SEA      346     2422
        hour minute           time_hour
       <num>  <num>              <POSc>
    1:    18     15 2013-01-04 18:00:00
    2:    21      6 2013-04-29 21:00:00
    3:    13     58 2013-07-22 13:00:00
    4:    10     15 2013-03-23 10:00:00
    5:    18      0 2013-11-27 18:00:00
    6:    11      5 2013-11-05 11:00:00
    7:     7      0 2013-01-23 07:00:00
    8:     8     50 2013-05-22 08:00:00
    9:    13     40 2013-03-05 13:00:00

## Tip 3: 从年月日构建日期列 (Create a date column)

### Tidyverse

使用 `mutate` 配合 `lubridate::make_date`。

<details class="code-fold">
<summary>Code</summary>

``` r
flights_tbl |> 
  select(year, month, day) |> 
  mutate(date = make_date(year, month, day)) |> 
  head(5)
```

</details>

    # A tibble: 5 × 4
       year month   day date      
      <int> <int> <int> <date>    
    1  2013     1     1 2013-01-01
    2  2013     1     1 2013-01-01
    3  2013     1     1 2013-01-01
    4  2013     1     1 2013-01-01
    5  2013     1     1 2013-01-01

### data.table

使用 `:=` 进行引用更新（原地修改），效率更高。

<details class="code-fold">
<summary>Code</summary>

``` r
# 注意：data.table 的 := 操作没有返回值（silent），
# 为了展示结果，通常在末尾加上 [] 或者显式打印
dt[, date := make_date(year, month, day)][, .(date)] |> head(5)
```

</details>

             date
           <Date>
    1: 2013-01-01
    2: 2013-01-01
    3: 2013-01-01
    4: 2013-01-01
    5: 2013-01-01

## Tip 4: 解析数字 (Parse numbers)

使用 `readr::parse_number` (tidyverse 的一部分) 提取字符串中的数值。

<details class="code-fold">
<summary>Code</summary>

``` r
# 模拟数据
numbers_1 <- tibble(number_col = c("#1", "#2", "#3"))
numbers_2 <- tibble(number_col = c("Number 5", "#6", "7"))
numbers_3 <- tibble(number_col = c("1.2%", "2.5%", "50.9%"))

dt1 <- as.data.table(numbers_1)
```

</details>

### Tidyverse

<details class="code-fold">
<summary>Code</summary>

``` r
numbers_1 |> mutate(val = parse_number(number_col))
```

</details>

    # A tibble: 3 × 2
      number_col   val
      <chr>      <dbl>
    1 #1             1
    2 #2             2
    3 #3             3

<details class="code-fold">
<summary>Code</summary>

``` r
numbers_2 |> mutate(val = parse_number(number_col))
```

</details>

    # A tibble: 3 × 2
      number_col   val
      <chr>      <dbl>
    1 Number 5       5
    2 #6             6
    3 7              7

<details class="code-fold">
<summary>Code</summary>

``` r
numbers_3 |> mutate(val = parse_number(number_col))
```

</details>

    # A tibble: 3 × 2
      number_col   val
      <chr>      <dbl>
    1 1.2%         1.2
    2 2.5%         2.5
    3 50.9%       50.9

### data.table

data.table 本身没有专门的解析函数，通常混合使用 `parse_number` 或正则。

<details class="code-fold">
<summary>Code</summary>

``` r
dt1[, .(val = parse_number(number_col))]
```

</details>

         val
       <num>
    1:     1
    2:     2
    3:     3

## Tip 5: 按名称模式选择列 (Select columns with starts_with, etc.)

### Tidyverse

`dplyr::select` 提供了丰富的辅助函数：`starts_with`, `ends_with`, `contains`, `everything` 等。

<details class="code-fold">
<summary>Code</summary>

``` r
# 选择以 dep_ 开头的列
flights_tbl |> select(starts_with('dep_')) |> head(2)
```

</details>

    # A tibble: 2 × 2
      dep_time dep_delay
         <int>     <dbl>
    1      517         2
    2      533         4

<details class="code-fold">
<summary>Code</summary>

``` r
# 将 dep_ 开头的列移到最前，其他列保留
flights_tbl |> select(starts_with('dep_'), everything()) |> head(2)
```

</details>

    # A tibble: 2 × 19
      dep_time dep_delay  year month   day sched_dep_time arr_time sched_arr_time
         <int>     <dbl> <int> <int> <int>          <int>    <int>          <int>
    1      517         2  2013     1     1            515      830            819
    2      533         4  2013     1     1            529      850            830
    # ℹ 11 more variables: arr_delay <dbl>, carrier <chr>, flight <int>,
    #   tailnum <chr>, origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>,
    #   hour <dbl>, minute <dbl>, time_hour <dttm>

### data.table

使用 `grep` 配合 `with = FALSE` 或者 `..var` 语法。

<details class="code-fold">
<summary>Code</summary>

``` r
# 查找以 _time 结尾的列名
selected_cols <- grep('_time$', colnames(dt), value = TRUE)

# 方式 1: 使用 .. 语法
dt[, ..selected_cols] |> head(2)
```

</details>

       dep_time sched_dep_time arr_time sched_arr_time air_time
          <int>          <int>    <int>          <int>    <num>
    1:      517            515      830            819      227
    2:      533            529      850            830      227

<details class="code-fold">
<summary>Code</summary>

``` r
# 方式 2: 使用 with = FALSE
dt[, selected_cols, with = FALSE] |> head(2)
```

</details>

       dep_time sched_dep_time arr_time sched_arr_time air_time
          <int>          <int>    <int>          <int>    <num>
    1:      517            515      830            819      227
    2:      533            529      850            830      227

<details class="code-fold">
<summary>Code</summary>

``` r
# 类似 everything() 的效果：重新排列列
selected_dep <- grep('^dep_', colnames(dt), value = TRUE)
cols_reordered <- c(selected_dep, setdiff(names(dt), selected_dep))
dt[, ..cols_reordered] |> head(2)
```

</details>

       dep_time dep_delay  year month   day sched_dep_time arr_time sched_arr_time
          <int>     <num> <int> <int> <int>          <int>    <int>          <int>
    1:      517         2  2013     1     1            515      830            819
    2:      533         4  2013     1     1            529      850            830
       arr_delay carrier flight tailnum origin   dest air_time distance  hour
           <num>  <char>  <int>  <char> <char> <char>    <num>    <num> <num>
    1:        11      UA   1545  N14228    EWR    IAH      227     1400     5
    2:        20      UA   1714  N24211    LGA    IAH      227     1416     5
       minute           time_hour       date
        <num>              <POSc>     <Date>
    1:     15 2013-01-01 05:00:00 2013-01-01
    2:     29 2013-01-01 05:00:00 2013-01-01

## Tip 6: 条件赋值 (case_when / fifelse / fcase)

### Tidyverse

使用 `case_when` 进行多条件判断。

<details class="code-fold">
<summary>Code</summary>

``` r
flights_tbl |> 
  mutate(
    origin_name = case_when(
      origin == 'EWR' ~ 'Newark Intl',
      origin == 'JFK' ~ 'John F. Kennedy Intl',
      origin == 'LGA' ~ 'LaGuardia',
      TRUE ~ origin # 默认情况
    )
  ) |> 
  count(origin_name)
```

</details>

    # A tibble: 3 × 2
      origin_name               n
      <chr>                 <int>
    1 John F. Kennedy Intl 111279
    2 LaGuardia            104662
    3 Newark Intl          120835

<details class="code-fold">
<summary>Code</summary>

``` r
# 另一种方式：recode (主要用于值的重映射)
flights_tbl |> 
  mutate(
    origin_name = recode(origin,
      EWR = 'Newark Intl',
      JFK = 'JFK Intl',
      LGA = 'LaGuardia'
    )
  ) |> 
  count(origin_name)
```

</details>

    # A tibble: 3 × 2
      origin_name      n
      <chr>        <int>
    1 JFK Intl    111279
    2 LaGuardia   104662
    3 Newark Intl 120835

### data.table

使用 `fifelse` (类似 ifelse 但更快且处理 NA 更严格) 或 `fcase` (类似 case_when)。

<details class="code-fold">
<summary>Code</summary>

``` r
# 使用嵌套 fifelse
dt[, origin_name := fifelse(origin == 'EWR', 'Newark Intl',
      fifelse(origin == 'JFK', 'John F. Kennedy Intl',
        fifelse(origin == 'LGA', 'LaGuardia', origin)
      )
    )]
dt[, .N, by = origin_name]
```

</details>

                origin_name      N
                     <char>  <int>
    1:          Newark Intl 120835
    2:            LaGuardia 104662
    3: John F. Kennedy Intl 111279

<details class="code-fold">
<summary>Code</summary>

``` r
# 使用 fcase (推荐，更清晰)
dt[, origin_name_fcase := fcase(
      origin == 'EWR', 'Newark Intl',
      origin == 'JFK', 'John F. Kennedy Intl',
      origin == 'LGA', 'LaGuardia',
      default = origin
   )]
dt[, .N, by = origin_name_fcase]
```

</details>

          origin_name_fcase      N
                     <char>  <int>
    1:          Newark Intl 120835
    2:            LaGuardia 104662
    3: John F. Kennedy Intl 111279

## Tip 7: 批量替换字符串 (str_replace_all)

当需要一次性替换多个模式时。

### Tidyverse

`str_replace_all` 支持命名向量作为映射表。

<details class="code-fold">
<summary>Code</summary>

``` r
flights_tbl |> 
  mutate(
    origin_desc = str_replace_all(
      origin,
      c(
        '^EWR$' = 'Newark International Airport',
        '^JFK$' = 'John F. Kennedy International Airport',
        '^LGA$' = 'LaGuardia Airport'
      )
    )
  ) |> 
  count(origin_desc)
```

</details>

    # A tibble: 3 × 2
      origin_desc                                n
      <chr>                                  <int>
    1 John F. Kennedy International Airport 111279
    2 LaGuardia Airport                     104662
    3 Newark International Airport          120835

### data.table

同样可以结合 `stringr::str_replace_all` 使用，或者使用 data.table 的更新语法。

<details class="code-fold">
<summary>Code</summary>

``` r
# 直接在 j 中调用函数
dt[, origin_desc := str_replace_all(origin, c(
    '^EWR$' = 'Newark International Airport',
    '^JFK$' = 'John F. Kennedy International Airport',
    '^LGA$' = 'LaGuardia Airport'
  ))
]
dt[, .N, by = origin_desc]
```

</details>

                                 origin_desc      N
                                      <char>  <int>
    1:          Newark International Airport 120835
    2:                     LaGuardia Airport 104662
    3: John F. Kennedy International Airport 111279

## Tip 8: Transmute (创建新列并只保留新列)

### Tidyverse

`transmute` = `mutate` + `select`。

<details class="code-fold">
<summary>Code</summary>

``` r
flights_tbl |> 
  transmute(date = make_date(year, month, day), tailnum) |> 
  head(3)
```

</details>

    # A tibble: 3 × 2
      date       tailnum
      <date>     <chr>  
    1 2013-01-01 N14228 
    2 2013-01-01 N24211 
    3 2013-01-01 N619AA 

### data.table

在 `j` 参数中只返回需要的列。

<details class="code-fold">
<summary>Code</summary>

``` r
# 方式 1: 创建并选择
dt[, .(date = make_date(year, month, day), tailnum)] |> head(3)
```

</details>

             date tailnum
           <Date>  <char>
    1: 2013-01-01  N14228
    2: 2013-01-01  N24211
    3: 2013-01-01  N619AA

<details class="code-fold">
<summary>Code</summary>

``` r
# 引用列的几种方式对比
# dt[, 'tailnum', with = FALSE] # 返回 data.table
# dt[, .(tailnum)]            # 返回 data.table
# dt[, tailnum]               # 返回 vector
```

</details>

## Tip 9: 管道中的复杂 Mutate (String processing)

处理复杂的字符串清洗逻辑。

<details class="code-fold">
<summary>Code</summary>

``` r
# 准备 airlines 数据
dt2 <- as.data.table(airlines)
```

</details>

### Tidyverse

利用管道 `|>` 将多个字符串处理步骤串联。

<details class="code-fold">
<summary>Code</summary>

``` r
airlines |> 
  mutate(
    name_clean = name |> 
      str_to_upper() |> 
      str_replace_all(' (INC|CO)\\.?$', "") |> 
      str_replace_all(' AIR ?(LINES|WAYS)?( CORPORATION)?$', "") |> 
      str_to_title() |> 
      str_replace_all('\\bUs\\b', 'US')
  ) |> 
  select(name, name_clean)
```

</details>

    # A tibble: 16 × 2
       name                        name_clean    
       <chr>                       <chr>         
     1 Endeavor Air Inc.           Endeavor      
     2 American Airlines Inc.      American      
     3 Alaska Airlines Inc.        Alaska        
     4 JetBlue Airways             Jetblue       
     5 Delta Air Lines Inc.        Delta         
     6 ExpressJet Airlines Inc.    Expressjet    
     7 Frontier Airlines Inc.      Frontier      
     8 AirTran Airways Corporation Airtran       
     9 Hawaiian Airlines Inc.      Hawaiian      
    10 Envoy Air                   Envoy         
    11 SkyWest Airlines Inc.       Skywest       
    12 United Air Lines Inc.       United        
    13 US Airways Inc.             US            
    14 Virgin America              Virgin America
    15 Southwest Airlines Co.      Southwest     
    16 Mesa Airlines Inc.          Mesa          

### data.table

可以定义函数或在 `:=` 中嵌套调用。

<details class="code-fold">
<summary>Code</summary>

``` r
process_name <- function(x) {
  x |> 
    str_to_upper() |> 
    str_replace_all(' (INC|CO)\\.?$', "") |> 
    str_replace_all(' AIR ?(LINES|WAYS)?( CORPORATION)?$', "") |> 
    str_to_title() |> 
    str_replace_all('\\bUs\\b', 'US')
}

dt2[, name_clean := process_name(name)]
dt2[, .(name, name_clean)]
```

</details>

                               name     name_clean
                             <char>         <char>
     1:           Endeavor Air Inc.       Endeavor
     2:      American Airlines Inc.       American
     3:        Alaska Airlines Inc.         Alaska
     4:             JetBlue Airways        Jetblue
     5:        Delta Air Lines Inc.          Delta
     6:    ExpressJet Airlines Inc.     Expressjet
     7:      Frontier Airlines Inc.       Frontier
     8: AirTran Airways Corporation        Airtran
     9:      Hawaiian Airlines Inc.       Hawaiian
    10:                   Envoy Air          Envoy
    11:       SkyWest Airlines Inc.        Skywest
    12:       United Air Lines Inc.         United
    13:             US Airways Inc.             US
    14:              Virgin America Virgin America
    15:      Southwest Airlines Co.      Southwest
    16:          Mesa Airlines Inc.           Mesa

## Tip 10: 过滤分组而不创建新列 (Filter groups)

筛选出符合特定条件（如组内计数大于某值）的分组。

### Tidyverse

`group_by()` -\> `filter()` -\> `ungroup()`。

<details class="code-fold">
<summary>Code</summary>

``` r
# 筛选出航班数 >= 10000 的航空公司
flights_tbl |> 
  group_by(carrier) |> 
  filter(n() >= 10000) |> 
  ungroup() |> 
  count(carrier, sort = TRUE)
```

</details>

    # A tibble: 9 × 2
      carrier     n
      <chr>   <int>
    1 UA      58665
    2 B6      54635
    3 EV      54173
    4 DL      48110
    5 AA      32729
    6 MQ      26397
    7 US      20536
    8 9E      18460
    9 WN      12275

### data.table

使用 `.SD` 结合 `if` 或在 `by` 之后进行过滤。

<details class="code-fold">
<summary>Code</summary>

``` r
# 方式 1: 在 j 中使用 if
# 如果组内行数 .N >= 10000，则返回该组所有数据 (.SD)
dt[, if (.N >= 10000) .SD, by = carrier][, .N, by = carrier]
```

</details>

       carrier     N
        <char> <int>
    1:      UA 58665
    2:      AA 32729
    3:      B6 54635
    4:      DL 48110
    5:      EV 54173
    6:      MQ 26397
    7:      US 20536
    8:      WN 12275
    9:      9E 18460

<details class="code-fold">
<summary>Code</summary>

``` r
# 方式 2: 先聚合再筛选 (如果只需要聚合结果)
dt[, .(count = .N), by = carrier][count >= 10000][order(-count)]
```

</details>

       carrier count
        <char> <int>
    1:      UA 58665
    2:      B6 54635
    3:      EV 54173
    4:      DL 48110
    5:      AA 32729
    6:      MQ 26397
    7:      US 20536
    8:      9E 18460
    9:      WN 12275

## Tip 11: 拆分字符串到多列 (Split string into columns)

### Tidyverse

使用 `extract` (正则表达式) 或 `separate` (分隔符)。

<details class="code-fold">
<summary>Code</summary>

``` r
airlines |> 
  tidyr::extract(
    name,
    into = c('short_name', 'reminder'),
    regex = '^([^\\s]+) (.*)$',
    remove = FALSE
  ) |> 
  head(3)
```

</details>

    # A tibble: 3 × 4
      carrier name                   short_name reminder     
      <chr>   <chr>                  <chr>      <chr>        
    1 9E      Endeavor Air Inc.      Endeavor   Air Inc.     
    2 AA      American Airlines Inc. American   Airlines Inc.
    3 AS      Alaska Airlines Inc.   Alaska     Airlines Inc.

### data.table

使用 `tstrsplit`。

<details class="code-fold">
<summary>Code</summary>

``` r
dt2 <- as.data.table(airlines)

# 使用 tstrsplit 按空格拆分，keep=1 取第一部分
dt2[, short_name := tstrsplit(name, ' ', keep = 1)]
dt2[, .(name, short_name)] |> head(3)
```

</details>

                         name short_name
                       <char>     <char>
    1:      Endeavor Air Inc.   Endeavor
    2: American Airlines Inc.   American
    3:   Alaska Airlines Inc.     Alaska

<details class="code-fold">
<summary>Code</summary>

``` r
# 多个拆分示例
strings <- c("apple,banana,orange", "dog cat")
tstrsplit(strings, ",| ")
```

</details>

    [[1]]
    [1] "apple" "dog"  

    [[2]]
    [1] "banana" "cat"   

    [[3]]
    [1] "orange" NA      
