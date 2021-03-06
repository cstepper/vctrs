context("test-c")

test_that("zero length input returns NULL", {
  expect_equal(vec_c(), NULL)
  expect_equal(vec_c(NULL), NULL)
  expect_equal(vec_c(NULL,), NULL)
  expect_equal(vec_c(NULL, NULL), NULL)
})

test_that("NULL is idempotent", {
  expect_equal(vec_c(NULL, 1L), 1L)
  expect_equal(vec_c(1L, NULL), 1L)
})

test_that("NA is idempotent", {
  expect_equal(vec_c(NA, 1L), c(NA, 1L))
  expect_equal(vec_c(NA, "x"), c(NA, "x"))
  expect_equal(vec_c(NA, factor("x")), factor(c(NA, "x")))
  expect_equal(vec_c(NA, new_date(0)), new_date(c(NA, 0)))
  expect_equal(vec_c(NA, new_datetime(0)), new_datetime(c(NA, 0)))
  expect_equal(vec_c(NA, new_duration(0)), new_duration(c(NA, 0)))
})

test_that("NA is logical if no other types intervene", {
  expect_equal(vec_c(logical()), logical())
  expect_equal(vec_c(NA), NA)
  expect_equal(vec_c(NA, NA), c(NA, NA))
})


test_that("different types are coerced to common", {
  expect_equal(vec_c(TRUE, 1L, 1), c(1, 1, 1))
  expect_equal(vec_c(TRUE, 2:4), 1:4)
})

test_that("specified .ptypes do not allow more casts", {
  expect_error(
    vec_c(TRUE, .ptype = character()),
    class = "vctrs_error_incompatible_cast"
  )
})

test_that("combines outer an inner names", {
  expect_equal(vec_c(x = 1), c(x = 1))
  expect_equal(vec_c(c(x = 1)), c(x = 1))

  expect_equal(vec_c(c(x = 1:2)), c(x1 = 1, x2 = 2))
  expect_error(vec_c(y = c(x = 1)), "Please supply")
})

test_that("can bind data.frame columns", {
  df <- data.frame(x = NA, y = 1:2)
  df$x <- data.frame(a = 1:2)

  expected <- data.frame(x = NA, y = c(1:2, 1:2))
  expected$x <- data.frame(a = c(1:2, 1:2))

  expect_equal(vec_c(df, df), expected)
})

test_that("vec_c() handles matrices", {
  m <- matrix(1:4, nrow = 2)
  dimnames(m) <- list(c("foo", "bar"), c("baz", "quux"))

  # FIXME: `vec_ptype_common(m, m)` doesn't return dimension names
  exp <- matrix(c(1:2, 1:2, 3:4, 3:4), nrow = 4)
  rownames(exp) <- c("foo", "bar", "foo", "bar")

  expect_identical(vec_c(m, m), exp)

  expect_error(vec_c(outer = m), "Please supply")
})

test_that("vec_c() includes index in argument tag", {
  df1 <- tibble(x = tibble(y = tibble(z = 1)))
  df2 <- tibble(x = tibble(y = tibble(z = "a")))

  expect_known_output(file = test_path("test-type-vec-c-error.txt"), {
    try2(vec_c(df1, df2))
    try2(vec_c(df1, df1, df2))
    try2(vec_c(foo = df1, bar = df2))
  })
})

test_that("vec_c() handles record classes", {
  local_rational_class()

  out <- vec_c(rational(1, 2), 1L, NA)

  expect_true(vec_is(out, rational(1, 2)))
  expect_size(out, 3)
  expect_identical(vec_proxy(out), data.frame(n = c(1L, 1L, NA), d = c(2L, 1L, NA)))
})

test_that("can mix named and unnamed vectors (#271)", {
  expect_identical(vec_c(c(a = 1), 2), c(a = 1, 2))
  expect_identical(vec_c(0, c(a = 1), 2, b = 3), c(0, a = 1, 2, b =3))
})

test_that("vec_c() repairs names", {
  # Default minimal repair
  expect_named(vec_c(a = 1, a = 2, `_` = 3), c("a", "a", "_"))
  out <- vec_c(!!!set_names(1, NA))
  expect_named(out, "")

  expect_named(vec_c(a = 1, a = 2, `_` = 3, .name_repair = "unique"), c("a...1", "a...2", "_"))
  expect_error(vec_c(a = 1, a = 2, `_` = 3, .name_repair = "check_unique"), class = "vctrs_error_names_must_be_unique")

  expect_named(vec_c(a = 1, a = 2, `_` = 3, .name_repair = "universal"), c("a...1", "a...2", "._"))

  expect_named(vec_c(a = 1, a = 2, .name_repair = ~ toupper(.)), c("A", "A"))
})

test_that("vec_c() doesn't use outer names for data frames (#524)", {
  x <- data.frame(inner = 1)
  expect_equal(vec_c(outer = x), x)

  a <- data.frame(x = 1L)
  b <- data.frame(x = 2L)
  expect_equal(vec_c(foo = a, bar = b), data.frame(x = 1:2))
})

test_that("vec_c() preserves row names and inner names", {
  x <- data.frame(a = 1, row.names = "r1")
  y <- data.frame(a = 2, row.names = "r2")
  expect_equal(rownames(vec_c(x, y)), c("r1", "r2"))
  expect_equal(rownames(vec_c(x, x)), c("r1...1", "r1...2"))

  vec_x <- set_names(1:3, letters[1:3])
  vec_y <- c(FOO = 4L)
  oo_x <- set_names(as.POSIXlt(c("2020-01-01", "2020-01-02", "2020-01-03")), letters[1:3])
  oo_y <- as.POSIXlt(c(FOO = "2020-01-04"))
  df_x <- new_data_frame(list(x = 1:3), row.names = letters[1:3])
  df_y <- new_data_frame(list(x = 4L), row.names = "d")
  mat_x <- matrix(1:3, 3, dimnames = list(letters[1:3]))
  mat_y <- matrix(4L, 1, dimnames = list("d"))
  nested_x <- new_data_frame(
    list(df = df_x, mat = mat_x, vec = vec_x, oo = oo_x),
    row.names = c("foo", "bar", "baz")
  )
  nested_y <- new_data_frame(
    list(df = df_y, mat = mat_y, vec = vec_y, oo = oo_y),
    row.names = c("quux")
  )

  nested_out <- vec_c(nested_x, nested_y)
  expect_identical(row.names(nested_out), c("foo", "bar", "baz", "quux"))
  expect_identical(row.names(nested_out$df), c("a", "b", "c", "d"))
  expect_identical(row.names(nested_out$mat), c("a", "b", "c", "d"))
  expect_identical(names(nested_out$vec), c("a", "b", "c", "FOO"))
  expect_identical(names(nested_out$oo), c("a", "b", "c", "FOO"))
})

test_that("vec_c() outer names work with proxied objects", {
  x <- as.POSIXlt(new_datetime(0))
  exp <- set_names(x, "outer")
  expect_equal(vec_c(outer = x), exp)

  named_x <- set_names(x, "inner")
  exp <- set_names(named_x, "outer_inner")
  expect_error(vec_c(outer = named_x), "Please supply")
  expect_equal(vec_c(outer = named_x, .name_spec = "{outer}_{inner}"), exp)

  xs <- as.POSIXlt(new_datetime(c(0, 1)))
  exp <- set_names(xs, c("outer_1", "outer_2"))
  expect_error(vec_c(outer = xs), "Please supply")
  expect_equal(vec_c(outer = xs, .name_spec = "{outer}_{inner}"), exp)
})

test_that("vec_c() works with simple homogeneous foreign S3 classes", {
  expect_identical(vec_c(foobar(1), foobar(2)), vec_c(foobar(c(1, 2))))
  expect_identical(vec_c(NULL, foobar(1), foobar(2)), vec_c(foobar(c(1, 2))))
})

test_that("vec_c() works with simple homogeneous foreign S4 classes", {
  joe1 <- .Counts(c(1L, 2L), name = "Joe")
  joe2 <- .Counts(3L, name = "Joe")
  expect_identical(vec_c(joe1, joe2), .Counts(1:3, name = "Joe"))
})

test_that("vec_c() fails with complex foreign S3 classes", {
  verify_errors({
    x <- structure(foobar(1), attr_foo = "foo")
    y <- structure(foobar(2), attr_bar = "bar")
    expect_error(vec_c(x, y), class = "vctrs_error_incompatible_type")
  })
})

test_that("vec_c() fails with complex foreign S4 classes", {
  verify_errors({
    joe <- .Counts(c(1L, 2L), name = "Joe")
    jane <- .Counts(3L, name = "Jane")
    expect_error(vec_c(joe, jane), class = "vctrs_error_incompatible_type")
  })
})

test_that("vec_c() falls back to c() if S3 method is available", {
  # Check off-by-one error
  expect_error(
    vec_c(foobar(1), "", foobar(2)),
    class = "vctrs_error_incompatible_type"
  )

  # Fallback when the class implements `c()`
  method <- function(...) rep_along(list(...), "dispatched")
  local_methods(
    c.vctrs_foobar = method
  )
  expect_identical(
    vec_c(foobar(1), foobar(2)),
    c("dispatched", "dispatched")
  )
  expect_identical(
    vec_c(NULL, foobar(1), NULL, foobar(2)),
    c("dispatched", "dispatched")
  )

  # Registered fallback
  s3_register("base::c", "vctrs_c_fallback", method)
  expect_identical(
    vec_c(
      structure(1, class = "vctrs_c_fallback"),
      structure(2, class = "vctrs_c_fallback")
    ),
    c("dispatched", "dispatched")
  )

  # Don't fallback for S3 lists which are treated as scalars by default
  expect_error(
    vec_c(foobar(list(1)), foobar(list(2))),
    class = "vctrs_error_scalar_type"
  )
})

test_that("vec_c() falls back to c() if S4 method is available", {
  joe1 <- .Counts(c(1L, 2L), name = "Joe")
  joe2 <- .Counts(3L, name = "Joe")

  c_counts <- function(x, ...) {
    xs <- list(x, ...)

    xs_data <- lapply(xs, function(x) x@.Data)
    new_data <- do.call(c, xs_data)

    .Counts(new_data, name = x@name)
  }

  local_s4_method("c", methods::signature(x = "vctrs_Counts"), c_counts)

  expect_identical(
    vec_c(joe1, joe2),
    .Counts(c(1L, 2L, 3L), name = "Joe")
  )

  expect_identical(
    vec_c(NULL, joe1, joe2),
    .Counts(c(1L, 2L, 3L), name = "Joe")
  )
})

test_that("vec_c() fallback doesn't support `name_spec` or `ptype`", {
  verify_errors({
    expect_error(
      with_c_foobar(vec_c(foobar(1), foobar(2), .name_spec = "{outer}_{inner}")),
      "name specification"
    )
    expect_error(
      with_c_foobar(vec_c(foobar(1), foobar(2), .ptype = "")),
      "prototype"
    )
  })
})

test_that("vec_c() has informative error messages", {
  verify_output(test_path("error", "test-c.txt"), {
    "# vec_c() fails with complex foreign S3 classes"
    x <- structure(foobar(1), attr_foo = "foo")
    y <- structure(foobar(2), attr_bar = "bar")
    vec_c(x, y)

    "# vec_c() fails with complex foreign S4 classes"
    joe <- .Counts(c(1L, 2L), name = "Joe")
    jane <- .Counts(3L, name = "Jane")
    vec_c(joe, jane)

    "# vec_c() fallback doesn't support `name_spec` or `ptype`"
    with_c_foobar(vec_c(foobar(1), foobar(2), .name_spec = "{outer}_{inner}"))
    with_c_foobar(vec_c(foobar(1), foobar(2), .ptype = ""))
  })
})
