
context("memo")

library(magrittr)
library(testthat)

# environment used to mark memo execution
current.test.env <- function () test.env

# memo execution key
key.executed <- "executed"

##
# Helper to insert expression into function to be executed before the current body.
#
insert.before <- function (f, expr) {
  
  expr.rest <- function (expr) {
    
    expr.list <- expr %>% as.list()
    
    if (length(expr.list) == 1) expr.list else rest(expr.list)
  }
  
  body(f) <- c(`{`, expr.rest(expr), expr.rest(body(f))) %>% as.call()
  
  f
}

##
# marks memo execution in environment
#
mark.executed <- function () assign(key.executed, TRUE, envir=test.env)

## 
# inserts code to mark environment with execution flag before memoising the function
#
test.memo <- function (f, ...) f %>% insert.before(quote({mark.executed()})) %>% memo(...)

##
# do memo test
#
do.test <- function (f, params, expected, executed) {

  assign("test.env", test_env(), envir = environment(current.test.env))
  expect_true(identical(do.call(f, params), expected))
  expect_equal(mget(key.executed, envir=current.test.env(), inherits=FALSE, ifnotfound=FALSE)[[1]], executed)
}

test_that("
  Given a simple function which has been memoised, 
  When I evaluate the memo, 
  Then the result is cached for the same parameters after the first call", {
  
  memo <- (function (value) value) %>% test.memo()
  
  do.test(memo, list(10), 10, TRUE)
  do.test(memo, list(10), 10, FALSE)
  do.test(memo, list(10), 10, FALSE)
  do.test(memo, list(20), 20, TRUE)
  do.test(memo, list(20), 20, FALSE)
})

test_that("
  Given a simple function which has been memoised,
  When I evaluate the memo and specifiy the force parameter,
  Then the memo is executed if force is TRUE
  And the new value is cached", {
  
  memo <- (function (value) value) %>% test.memo()
  
  do.test(memo, list(10, memo.force=FALSE), 10, TRUE)
  do.test(memo, list(10, memo.force=TRUE), 10, TRUE)
  do.test(memo, list(10, memo.force=FALSE), 10, FALSE)
  do.test(memo, list(10, memo.force=TRUE), 10, TRUE)
})

test_that("
  Given a simple function that has no return value
  And has been memoised with the default arguments,
  When I evaluate the memo,
  Then it will always execute", {
    
  memo <- (function (value) return(NULL)) %>% test.memo()
  
  do.test(memo, list(10), NULL, TRUE)
  do.test(memo, list(10), NULL, TRUE)
  do.test(memo, list(20), NULL, TRUE)
  do.test(memo, list(10, memo.force=TRUE), NULL, TRUE)
  
  memo <- (function (value) return(NULL)) %>% test.memo(allow.null=FALSE)
  
  do.test(memo, list(10), NULL, TRUE)
  do.test(memo, list(10), NULL, TRUE)
  do.test(memo, list(20), NULL, TRUE)
  do.test(memo, list(20), NULL, TRUE)
  do.test(memo, list(10, memo.force=TRUE), NULL, TRUE)
})

test_that("
  Given a simple function that has no arguments,
  And has been memoised,
  When I evaluate the memo,
  Then it will cache the result as expected", {
    
  memo <- (function () 10) %>% test.memo()
  
  do.test(memo, list(), 10, TRUE)
  do.test(memo, list(), 10, FALSE)
})

test_that("
  Given a simple function that has no return value
  And has been memoised indicating that null results are allowed,
  When I evaluate the memo,
  Then it will cache NULL results as normal", {
    
  memo <- (function (value) return(NULL)) %>% test.memo(allow.null=TRUE)
  
  do.test(memo, list(10), NULL, TRUE)
  do.test(memo, list(10), NULL, FALSE)
  do.test(memo, list(20), NULL, TRUE)
  do.test(memo, list(20), NULL, FALSE)
  do.test(memo, list(10, memo.force=TRUE), NULL, TRUE)
})

## TODO what happens if the function returns an invisible value
## TODO what happens if the function returns NA or "" ??

## TODO show that different memos do not share cached values

test_that("
  Given a memo,
  When I ask for the cache,
  Then I get the cache", {
    
  memo <- (function (value) value) %>% memo() 
  memo %>% memo.cache() %>% is.null() %>% expect_false()
})

test_that("
  Given a memo,
  When I ask for the function,
  Then I get the original function", {
    
  memo <- (function (value) value) %>% memo() 
  memo %>% memo.function() %>% hash() %>% expect_equal(hash(function (value) value))
})

test_that("
  Given a memo,
  When I memo the memo,
  Then I get an error", {
    
  expect_error((function (value) value) %>% memo() %>% memo())
})

test_that("
  Given a memo,
  When I call it with the dry run argument set to TRUE,
  Then it returns TRUE if the memoed function would be executed and FALSE if the value would have been 
  retrived from the cache,
  And it doesn't store these values in the cache", {

  memo <- (function (value) value) %>% memo()
  
  memo(10, memo.dryrun = TRUE) %>% expect_true()
  memo(10, memo.dryrun = TRUE) %>% expect_true()
  memo(10, memo.dryrun = FALSE) %>% expect_equal(10)
  memo(10, memo.dryrun = TRUE) %>% expect_false()
  memo(10, memo.force = TRUE, memo.dryrun = TRUE) %>% expect_true()
  memo(10, memo.dryrun = FALSE) %>% expect_equal(10)
  memo(10, memo.force = TRUE, memo.dryrun = FALSE) %>% expect_equal(10)
  memo(10) %>% expect_equal(10)
  
})