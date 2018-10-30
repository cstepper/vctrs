
<!-- README.md is generated from README.Rmd. Please edit that file -->

# vctrs <img src="man/figures/logo.png" align="right" width=120 height=139 alt="" />

[![Travis build
status](https://travis-ci.org/r-lib/vctrs.svg?branch=master)](https://travis-ci.org/r-lib/vctrs)
[![Coverage
status](https://codecov.io/gh/r-lib/vctrs/branch/master/graph/badge.svg)](https://codecov.io/github/r-lib/vctrs?branch=master)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

The goal of the vctrs package is to expose and standardise the vector
interface that sits at the heart of the R language. The vctrs framework
implements consistent combinations of vectors with well defined and
extensible coercion rules. Thanks to the consistency and genericity of
the vctrs framework, you can work with vectors in a robust and
predictable way.

Because the vctrs interface is well defined and generic, it makes it
easy to define your own vector classes with minimal efforts. Like base
classes, these custom vector classes interact consistently and
predictably with the rest of the language.

To make this possible, vctrs provides tools to think about function
invariants, properties of function that always true, regardless of the
inputs. The vctrs framework focusses on invariants related to R’s vector
data structures, partitioning their properties into two main components:
a size and a prototype. This allows us to analyse properties of a
function API, without having to think about the implementation.

For example, we might say that a function like `c()` should have two
properties:

  - the size of the output should equal the sum of size of the inputs.
    i.e. `vec_size(vec_c(x, y))` equals `vec_size(x) + vec_size(y)`

  - the type of the output shouldn’t be affected by the order of the
    inputs. i.e. `vec_type(vec_c(x, y))` equals `vec_type(vec_c(y, x))`

vctrs is a developer focused package. Understanding and extending vctrs
requires some effort from developers, but should be invisible to most
users. It’s our hope that having an underlying theory will mean that
users can build up an accurate mental model without explicitly learning
the theory. vctrs will typically be used by other packages, making it
easy for them to provide new classes of S3 vectors that are supported
throughout the tidyverse (and beyond). For that reason, vctrs has few
dependencies.

## Installation

vctrs is not currently on CRAN. Install the development version from
GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("r-lib/vctrs")
```

## Usage

``` r
library(vctrs)

vec_c(factor("a"), factor("b"))
#> [1] a b
#> Levels: a b
vec_c(Sys.Date(), Sys.time())
#> [1] "2018-10-30 00:00:00 CDT" "2018-10-30 18:07:35 CDT"
```

## Motivation

The original motivation for vctrs from two separate, but related
problems. The first problem is that `base::c()` has rather undesirable
behaviour when you mix different S3 vectors:

``` r
# combining factors makes integers
c(factor("a"), factor("b"))
#> [1] 1 1

# combing dates and date-times give incorrect values
dt <- as.Date("2020-01-1")
dttm <- as.POSIXct(dt)

c(dt, dttm)
#> [1] "2020-01-01"    "4321940-06-07"
c(dttm, dt)
#> [1] "2019-12-31 18:00:00 CST" "1969-12-31 23:04:22 CST"
```

This behaviour arises because `c()` has dual purposes: as well as it’s
primary duty of combining vectors, it has a secondary duty of stripping
attributes. For example, `?POSIXct` suggests that you should use `c()`
if you want to reset the timezone.

The second problem is that `dplyr::bind_rows()` is not extensible by
others. Currently, it handles arbitrary S3 classes using heuristics, but
these often fail, and it feels like we really need to think through the
problem in order to build a principled solution. This intersects with
the need to cleanly support more types of data frame columns including
lists of data frames, data frames, and matrices.
