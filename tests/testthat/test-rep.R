# ------------------------------------------------------------------------------
# vec_rep()

test_that("`vec_rep()` can repeat vectors", {
  expect_identical(vec_rep(1:2, 5), rep(1:2, 5))
  expect_identical(vec_rep(list(1, "x"), 5), rep(list(1, "x"), 5))
})

test_that("`vec_rep()` repeats data frames row wise", {
  x <- data.frame(x = 1:2, y = 3:4)
  expect_identical(vec_rep(x, 2), vec_slice(x, c(1:2, 1:2)))
})

test_that("`vec_rep()` can repeat 0 `times`", {
  expect_identical(vec_rep(1, 0), numeric())
})

test_that("`vec_rep()` errors on long vector output", {
  # Exact error message may be platform specific
  expect_error(vec_rep(1:2, .Machine$integer.max), "output size must be less than")
})

test_that("`vec_rep()` validates `times`", {
  expect_error(vec_rep(1, "x"), class = "vctrs_error_incompatible_cast")
  expect_error(vec_rep(1, c(1, 2)))
  expect_error(vec_rep(1, -1))
  expect_error(vec_rep(1, NA_integer_))
})

# ------------------------------------------------------------------------------
# vec_rep_each()

test_that("`vec_rep_each()` can repeat each element of vectors", {
  expect_identical(vec_rep_each(1:2, 5), rep(1:2, each = 5))
  expect_identical(vec_rep_each(list(1, "x"), 5), rep(list(1, "x"), each = 5))
})

test_that("`vec_rep_each()` `times` is vectorized", {
  expect_identical(vec_rep_each(1:2, 1:2), rep(1:2, times = 1:2))
})

test_that("`vec_rep_each()` repeats data frames row wise", {
  x <- data.frame(x = 1:2, y = 3:4)
  expect_identical(vec_rep_each(x, c(2, 1)), vec_slice(x, c(1, 1, 2)))
})

test_that("`vec_rep_each()` can repeat 0 `times`", {
  expect_identical(vec_rep_each(1:2, 0), integer())
})

test_that("`vec_rep_each()` errors on long vector output", {
  # Exact error message may be platform specific
  expect_error(vec_rep_each(1:2, .Machine$integer.max), "output size must be less than")
})

test_that("`vec_rep_each()` validates `times`", {
  expect_error(vec_rep_each(1, "x"), class = "vctrs_error_incompatible_cast")
  expect_error(vec_rep_each(1, -1))
  expect_error(vec_rep_each(c(1, 2), c(1, -1)))
  expect_error(vec_rep_each(1, NA_integer_))
  expect_error(vec_rep_each(c(1, 2), c(1, NA_integer_)))
})

test_that("`vec_rep_each()` uses recyclying errors", {
  expect_error(vec_rep_each(1:2, 1:3), class = "vctrs_error_recycle_incompatible_size")
})

# ------------------------------------------------------------------------------

test_that("rep functions generate informative error messages", {
  verify_output(test_path("error", "test-rep.txt"), {
    "# `vec_rep()` validates `times`"
    vec_rep(1, "x")
    vec_rep(1, c(1, 2))
    vec_rep(1, -1)
    vec_rep(1, NA_integer_)

    "# `vec_rep_each()` validates `times`"
    vec_rep_each(1, "x")
    vec_rep_each(1, -1)
    vec_rep_each(c(1, 2), c(1, -1))
    vec_rep_each(1, NA_integer_)
    vec_rep_each(c(1, 2), c(1, NA_integer_))

    "# `vec_rep_each()` uses recyclying errors"
    vec_rep_each(1:2, 1:3)
  })
})
