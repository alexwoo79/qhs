library(tidyverse)
library(lubridate)

library(nycflights13)
flights
library(data.table)
dt <- data.table::as.data.table(flights)
dt
str(dt)

# Tip 1 Create new columns in a count  or groupby

#tidyverse
flights |>
  mutate(long_flight = (air_time >= 6 * 60)) |>
  count(long_flight)

# simple
flights |> count(long_flight = air_time >= 6 * 60)


#data.table
dt[, .N, .(long_flight = (air_time >= 6 * 60))]


# simple 2
flights |>
  count(flight_path = str_c(origin, '->', dest), sort = TRUE)

#data.table
dt[, .N, .(flight_path = str_c(origin, '->', dest))][order(-N)]


#group_by (new col)
flights |>
  group_by(date = make_date(year, month, day)) |>
  summarise(flights_n = n(), air_time_median = median(air_time, na.rm = T)) |>
  ungroup()

#data.table
dt[,
  #i
  .(flights_n = .N, air_time_median = median(air_time, na.rm = T)), #j
  .(date = make_date(year, month, day)) #by
]


# Tip 2 Sample and randomly shuffle data with slice_sample()

flights |>
  slice_sample(n = 10)

dt[sample(.N, 10)]

flights |>
  slice_sample(prop = 0.01)

dt[sample(.N, (.N / 100))]

flights |>
  slice_sample(prop = 1)
dt[sample(.N, (.N))]

flights |>
  group_by(origin) |>
  slice_sample(n = 3) |> # Each group sample 3 rows to show
  ungroup()
#data.table  .SD and chaining
dt[, .SD[sample(.N, 3)], by = origin][, nrow(.SD)]

# Tip3 Create a date column specifying year,month and day
flights |>
  select(year, month, day) |>
  mutate(date = make_date(year, month, day))

dt[, .(date = make_date(year, month, day))]

# data.table 中 ：= 不显示数据，
dt[, date := make_date(year, month, day)][, .(date)] # 后面的[,.(date)] 是列的显示


# Tip 4 Parse numbers with pars_number()

numbers_1 <- tibble(number_col = c("#1", "#2", "#3"))
numbers_2 <- tibble(number_col = c("Number 5", "#6", "7"))
numbers_3 <- tibble(number_col = c("1.2%", "2.5%", "50.9%"))

numbers_1 |>
  mutate(number_col = parse_number(number_col))
numbers_2 |>
  mutate(number_col = parse_number(number_col))
numbers_3 |>
  mutate(number_col = parse_number(number_col))

dt1 <- as.data.table(numbers_1)
dt1[, .(number_col = parse_number(number_col))]


# Tip 5 Select columns with starts_with ,ends_with ,etc:
flights |>
  select(starts_with('dep_'))

# 选择以'_time'结尾的列
selected_cols <- grep('_time$', colnames(dt), value = T)


dt[, ..selected_cols]


dt[, c(grep('_time$', colnames(dt), value = F)), with = F]

# everything()

flights |>
  select(starts_with('dep_'), everything())

#data.table 类似

selected <- grep('^dep_', colnames(dt), value = T)
dt[, c(selected, setdiff(names(dt), selected)), with = F]

# Tip 6 case_when to create or change a column when conditions are met
flights |>
  mutate(
    origin = case_when(
      origin == 'EWR' ~ 'Newark International Airport',
      origin == 'JFK' ~ 'John F. Kennedy International Airport',
      origin == 'LGA' ~ 'LaGuardia Airport'
    )
  ) |>
  count(origin)

# 使用fifelse函数进行类似case_when的操作
dt[,
  .(
    origin = fifelse(
      origin == 'EWR',
      'Newark International Airport',
      fifelse(
        origin == 'JFK',
        'John F. Kennedy International Airport',
        fifelse(origin == 'LGA', 'LaGuardia Airport', origin)
      )
    )
  )
]

# 统计每个机场出现的次数
result <- dt[, .N, by = origin]
result

dt$origin

# recode

flights %>%
  mutate(
    origin = recode(
      origin,
      EWR = 'Newark International Airport',
      JFK = 'John F. Kennedy International Airport',
      LGA = 'LaGuardia Airport'
    )
  ) %>%
  count(origin)
# data.table, fcase
dt[,
  .(
    origin = fcase(
      origin == 'EWR' , 'Newark International Airport'          ,
      origin == 'JFK' , 'John F. Kennedy International Airport' ,
      origin == 'LGA' , 'LaGuardia Airport'
    )
  )
][, .N, by = origin]


# Tip 7 str_replace_all to find and replace multiple options at once
library(stringr)
library(tidyverse)
flights |>
  mutate(
    origin = str_replace_all(
      origin,
      c(
        '^EWR$' = 'Newark International Airport',
        '^JFK$' = 'John F. Kennedy International Airport',
        '^LGA$' = 'LaGuardia Airport'
      )
    )
  ) |>
  count(origin)

# Tip 8 Transmute to create or change columns and keep only those columns

flights |>
  transmute(date = make_date(year, month, day), tailnum)

dt[, date := make_date(year, month, day)][, .(date, tailnum)]

names(dt)

dt[, 'tailnum', with = F] # data.table
#with = FALSE 明确指定不使用 data.table 特殊的查找列名方式，而是将 'tailnum' 严格当作列名来处理。这样可以避免在复杂环境中列名查找可能出现的混淆。
dt[, .(tailnum)] # data.table
#这里使用了 .( ) 结构，它可以用于组合多个列或计算结果。在这种情况下，只指定了 tailnum 列。
dt[, tailnum] #vector
#当不使用 with = FALSE 且不使用 .( ) 结构时，data.table 会尝试在 j 部分的求值环境中查找列名，并以向量形式返回该列的值（如果列存在）。

# Tip 9 Use pipes including mutates

airlines |>
  mutate(
    name = name |>
      str_to_upper() |>
      str_replace_all(' (INC|CO)\\.?$', "") |>
      str_replace_all(' AIR ?(LINES|WAYS)?( CORPORATION)?$', "") |>
      str_to_title() |>
      str_replace_all('\\bUs\\b', 'US')
  ) |>
  count(name)


# 定义一个函数来处理字符串
process_name <- function(x) {
  x <- str_to_upper(x)
  x <- str_replace_all(x, ' (INC|CO)\\.?$', "")
  x <- str_replace_all(x, ' AIR ?(LINES|WAYS)?( CORPORATION)?$', "")
  x <- str_to_title(x)
  x <- str_replace_all(x, '\\bUs\\b', 'US')
  return(x)
}

dt2 <- as.data.table(airlines)
# 应用函数到name列
dt2[, name := process_name(name)]

# 统计每个name出现的次数
result <- dt2[, .N, by = name]

print(result)


# Tip 10 Filter groups without making a new column

flights |>
  count(carrier, sort = TRUE)

flight_top_carriers <- flights |>
  group_by(carrier) |>
  filter(n() >= 10000) |>
  ungroup()

flight_top_carriers |>
  count(carrier, sort = TRUE)

# data.table
dt[, if (.N >= 10000) .SD, by = carrier][, .N, by = carrier]

dt[, .(count = .N), by = carrier][count >= 10000 & order(-count)]


# Tip 11 Split a string into columns based on a regular expression

airlines |>
  count(name)

airlines |>
  extract(
    name,
    into = c('short_name', 'reminder'),
    regex = '^([^\\s]+) (.*)$',
    remove = FALSE
  )

dt2 <- as.data.table(airlines)


dt2[, .(
  short_name = dt2[, tstrsplit(name, ' ', keep = 1)]
)]

strings <- c("apple,banana,orange", "dog cat")
result <- tstrsplit(strings, ",| ")
print(result)
result[[1]][1]


library(stringr)
strings2 <- c("apple,banana,orange", "dog cat")
result2 <- str_split(strings, ",| ")
print(result2)


# unlike ifelse, fifelse preserves attributes, taken from the 'yes' argument
dates = as.Date(c(
  "2011-01-01",
  "2011-01-02",
  "2011-01-03",
  "2011-01-04",
  "2011-01-05"
))
ifelse(dates == "2011-01-01", dates - 1, dates)
fifelse(dates == "2011-01-01", dates - 1, dates)

# Tip 12 semi-join two diff  dataframe to merge 用第一个表的符合条件的数据 ，在第二个表中过滤数据

airways_beginning_with_a <- airlines |>
  filter(name |> str_detect('^A'))

flights |>
  semi_join(airways_beginning_with_a, by = 'carrier') |>
  count(carrier)

# Tip 13 anti_join in 1st not in  2nd, 用第一个表符合条件的数据 ，返回第二个表不符合这些数据的结果
airways_beginning_with_a <- airlines |>
  filter(name |> str_detect('^A'))

flights |>
  anti_join(airways_beginning_with_a, by = 'carrier') |>
  count(carrier)


# use data.table
library(data.table)
library(stringr)

# 假设airlines和flights是data.frame，转换为data.table
airlines_dt <- as.data.table(airlines)
flights_dt <- as.data.table(flights)

# 筛选以'A'开头的航空公司
airways_beginning_with_a <- airlines_dt[str_detect(name, '^A')]

# 从航班数据中排除与这些航空公司相关的航班并统计剩余航空公司的航班数量
result <- flights_dt[
  !carrier %in% airways_beginning_with_a$carrier,
  .N,
  by = carrier
]
print(result)

#Tip 14 fct_reorder()

flights_with_airline_names <- flights |>
  left_join(airlines, by = 'carrier')

flights_with_airline_names |>
  count(name) |>
  ggplot(aes(name, n)) +
  geom_col()

flights_with_airline_names |>
  count(name) |>
  mutate(name = fct_reorder(name, n)) |>
  ggplot(aes(name, n)) +
  geom_col() +
  coord_flip()

# Tip 16 fct_lump() to lump some factor level  to "other"

flights_with_airline_names |>
  mutate(name = fct_lump(name, 5)) |> #保留五个
  count(name) |>
  mutate(name = fct_reorder(name, n)) |>
  ggplot(aes(name, n)) +
  geom_col() +
  coord_flip()


#  Tip 交叉集

crossing(
  customer_channel = c('Online', 'Physical store'),
  customer_status = c('New', 'Repeat'),
  spend_range = c('$0-$100', '$00-$200', '$200-$500', '$500+')
)


#data.table 中的 CJ() 函数可用于生成笛卡尔积
CJ(
  customer_channel = c('Online', 'Physical store'),
  customer_status = c('New', 'Repeat'),
  spend_range = c('$0-$100', '$00-$200', '$200-$500', '$500+'),
  unique = TRUE
)


# Tip 18 col_summary()
col_summary <- function(data, col_names, na.rm = TRUE) {
  data %>%
    # 对col_names指定的列，批量计算统计量
    summarise(across(
      {{ col_names }}, # 用{{}}注入列名
      list(
        min = min, # 最小值
        max = max, # 最大值
        median = median, # 中位数
        mean = mean # 均值
      ),
      na.rm = na.rm, # 传递na.rm参数（控制是否忽略缺失值）
      .names = "{col}_{fn}"
    ))
}

flights |>
  col_summary(c(air_time))
