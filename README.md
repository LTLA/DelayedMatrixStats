
<!-- README.md is generated from README.Rmd. Please edit that file -->

# DelayedMatrixStats

[![Travis-CI Build
Status](https://travis-ci.org/PeteHaitch/DelayedMatrixStats.svg?branch=master)](https://travis-ci.org/PeteHaitch/DelayedMatrixStats)
[![Coverage
Status](https://codecov.io/gh/PeteHaitch/DelayedMatrixStats/branch/master/graph/badge.svg)](https://codecov.io/gh/PeteHaitch/DelayedMatrixStats)

**DelayedMatrixStats** is a port of the
[**matrixStats**](https://CRAN.R-project.org/package=matrixStats) API to
work with *DelayedMatrix* objects from the
[**DelayedArray**](http://bioconductor.org/packages/DelayedArray/)
package.

For a *DelayedMatrix*, `x`, the simplest way to apply a function, `f()`,
from **matrixStats** is`matrixStats::f(as.matrix(x))`. However, this
“*realizes*” `x` in memory as a *base::matrix*, which typically defeats
the entire purpose of using a *DelayedMatrix* for storing the data.

The **DelayedArray** package already implements a clever strategy called
“block-processing” for certain common “matrix stats” operations (e.g. 
`colSums()`, `rowSums()`). This is a good start, but not all of the
**matrixStats** API is currently supported. Furthermore, certain
operations can be optimized with additional information about `x`. I’ll
refer to these “seed-aware” implementations.

## Installation

You can install **DelayedMatrixStats** from Bioconductor with:

``` r
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("DelayedMatrixStats")
```

## Example

This example compares two ways of computing column sums of a
*DelayedMatrix* object:

1.  `DelayedMatrix::colSums()`: The ‘block-processing strategy’,
    implemented in the **DelayedArray** package. The block-processing
    strategy works for any *DelayedMatrix* object, regardless of the
    type of *seed*.
2.  `DelayedMatrixStats::colSums2()`: The ‘seed-aware’ strategy,
    implemented in the **DelayedMatrixStats** package. The seed-aware
    implementation is optimized for both speed and memory but only for
    *DelayedMatrix* objects with certain types of *seed*.

``` r
library(DelayedMatrixStats)
library(sparseMatrixStats)
library(microbenchmark)
library(profmem)
```

``` r
set.seed(666)

# Fast column sums of DelayedMatrix with matrix seed
dense_matrix <- DelayedArray(matrix(runif(20000 * 600), nrow = 20000,
                                    ncol = 600))
class(seed(dense_matrix))
#> [1] "matrix" "array"
dense_matrix
#> <20000 x 600> matrix of class DelayedMatrix and type "double":
#>                [,1]       [,2]       [,3] ...     [,599]     [,600]
#>     [1,]  0.7743685  0.6601787  0.4098798   . 0.89118118 0.05776471
#>     [2,]  0.1972242  0.8436035  0.9198450   . 0.31799523 0.63099417
#>     [3,]  0.9780138  0.2017589  0.4696158   . 0.31783791 0.02830454
#>     [4,]  0.2013274  0.8797239  0.6474768   . 0.55217184 0.09678816
#>     [5,]  0.3612444  0.8158778  0.5928599   . 0.08530977 0.39224147
#>      ...          .          .          .   .          .          .
#> [19996,] 0.19490291 0.07763570 0.56391725   . 0.09703424 0.62659353
#> [19997,] 0.61182993 0.01910121 0.04046034   . 0.59708388 0.88389731
#> [19998,] 0.12932744 0.21155070 0.19344085   . 0.51682032 0.13378223
#> [19999,] 0.18985573 0.41716539 0.35110782   . 0.62939661 0.94601427
#> [20000,] 0.87889047 0.25308041 0.54666920   . 0.81630322 0.73272217
microbenchmark(DelayedArray::colSums(dense_matrix),
               DelayedMatrixStats::colSums2(dense_matrix),
               times = 10)
#> Unit: milliseconds
#>                                        expr      min       lq      mean
#>         DelayedArray::colSums(dense_matrix) 56.38951 64.86599 133.35052
#>  DelayedMatrixStats::colSums2(dense_matrix) 13.17369 13.42267  16.13503
#>    median       uq       max neval
#>  69.60622 99.45897 387.84531    10
#>  13.62974 19.31188  26.88653    10
profmem::total(profmem::profmem(DelayedArray::colSums(dense_matrix)))
#> [1] 96105416
profmem::total(profmem::profmem(DelayedMatrixStats::colSums2(dense_matrix)))
#> [1] 166120

# Fast, low-memory column sums of DelayedMatrix with sparse matrix seed
sparse_matrix <- seed(dense_matrix)
zero_idx <- sample(length(sparse_matrix), 0.6 * length(sparse_matrix))
sparse_matrix[zero_idx] <- 0
sparse_matrix <- DelayedArray(Matrix::Matrix(sparse_matrix, sparse = TRUE))
class(seed(sparse_matrix))
#> [1] "dgCMatrix"
#> attr(,"package")
#> [1] "Matrix"
sparse_matrix
#> <20000 x 600> sparse matrix of class DelayedMatrix and type "double":
#>               [,1]      [,2]      [,3] ...     [,599]     [,600]
#>     [1,] 0.7743685 0.0000000 0.0000000   . 0.89118118 0.00000000
#>     [2,] 0.1972242 0.0000000 0.9198450   . 0.00000000 0.00000000
#>     [3,] 0.9780138 0.0000000 0.4696158   . 0.31783791 0.00000000
#>     [4,] 0.0000000 0.8797239 0.6474768   . 0.55217184 0.00000000
#>     [5,] 0.3612444 0.0000000 0.0000000   . 0.08530977 0.39224147
#>      ...         .         .         .   .          .          .
#> [19996,] 0.1949029 0.0776357 0.0000000   . 0.09703424 0.00000000
#> [19997,] 0.0000000 0.0000000 0.0000000   . 0.00000000 0.88389731
#> [19998,] 0.0000000 0.2115507 0.1934408   . 0.00000000 0.00000000
#> [19999,] 0.1898557 0.0000000 0.3511078   . 0.62939661 0.94601427
#> [20000,] 0.8788905 0.2530804 0.0000000   . 0.00000000 0.73272217
microbenchmark(DelayedArray::colSums(sparse_matrix),
               DelayedMatrixStats::colSums2(sparse_matrix),
               times = 10)
#> Unit: milliseconds
#>                                         expr       min         lq       mean
#>         DelayedArray::colSums(sparse_matrix) 244.80755 283.351854 462.626259
#>  DelayedMatrixStats::colSums2(sparse_matrix)   5.88743   6.336195   9.073628
#>     median        uq       max neval
#>  447.99469 570.09305 899.81807    10
#>    6.47515  14.54563  16.28401    10
profmem::total(profmem::profmem(DelayedArray::colSums(sparse_matrix)))
#> [1] 249647176
profmem::total(profmem::profmem(DelayedMatrixStats::colSums2(sparse_matrix)))
#> [1] 7400

# Fast column sums of DelayedMatrix with Rle-based seed
rle_matrix <- RleArray(Rle(sample(2L, 200000 * 6 / 10, replace = TRUE), 100),
                       dim = c(2000000, 6))
class(seed(rle_matrix))
#> [1] "SolidRleArraySeed"
#> attr(,"package")
#> [1] "DelayedArray"
rle_matrix
#> <2000000 x 6> matrix of class RleMatrix and type "integer":
#>            [,1] [,2] [,3] [,4] [,5] [,6]
#>       [1,]    2    2    1    1    1    2
#>       [2,]    2    2    1    1    1    2
#>       [3,]    2    2    1    1    1    2
#>       [4,]    2    2    1    1    1    2
#>       [5,]    2    2    1    1    1    2
#>        ...    .    .    .    .    .    .
#> [1999996,]    1    2    2    1    1    1
#> [1999997,]    1    2    2    1    1    1
#> [1999998,]    1    2    2    1    1    1
#> [1999999,]    1    2    2    1    1    1
#> [2000000,]    1    2    2    1    1    1
microbenchmark(DelayedArray::colSums(rle_matrix),
               DelayedMatrixStats::colSums2(rle_matrix),
               times = 10)
#> Unit: milliseconds
#>                                      expr        min         lq     mean
#>         DelayedArray::colSums(rle_matrix) 556.293150 560.138822 586.0082
#>  DelayedMatrixStats::colSums2(rle_matrix)   4.113903   4.299225  13.5635
#>     median       uq       max neval
#>  577.59867 598.8189 639.46499    10
#>    4.71228  14.2334  72.94384    10
profmem::total(profmem::profmem(DelayedArray::colSums(rle_matrix)))
#> [1] 168002536
profmem::total(profmem::profmem(DelayedMatrixStats::colSums2(rle_matrix)))
#> [1] 1640
```

## Benchmarking

An extensive set of benchmarks is under development at
<http://peterhickey.org/BenchmarkingDelayedMatrixStats/>.

## API coverage

-   ✔ = Implemented in **DelayedMatrixStats**
-   ☑️ = Implemented in
    [**DelayedArray**](http://bioconductor.org/packages/DelayedArray/)
    or
    [**sparseMatrixStats**](http://bioconductor.org/packages/sparseMatrixStats/)
-   ❌: = Not yet implemented

| Method                 | Block processing | *base::matrix* optimized | *Matrix::dgCMatrix* optimized | *Matrix::lgCMatrix* optimized | *DelayedArray::RleArray* (*SolidRleArraySeed*) optimized | *DelayedArray::RleArray* (*ChunkedRleArraySeed*) optimized | *HDF5Array::HDF5Matrix* optimized | *base::data.frame* optimized | *S4Vectors::DataFrame* optimized |
|:-----------------------|:-----------------|:-------------------------|:------------------------------|:------------------------------|:---------------------------------------------------------|:-----------------------------------------------------------|:----------------------------------|:-----------------------------|:---------------------------------|
| `colAlls()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colAnyMissings()`     | ✔                | ❌                        | ❌                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colAnyNAs()`          | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colAnys()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colAvgsPerRowSet()`   | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colCollapse()`        | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colCounts()`          | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colCummaxs()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colCummins()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colCumprods()`        | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colCumsums()`         | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colDiffs()`           | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colIQRDiffs()`        | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colIQRs()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colLogSumExps()`      | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colMadDiffs()`        | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colMads()`            | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colMaxs()`            | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colMeans2()`          | ✔                | ✔                        | ✔                             | ✔                             | ✔                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colMedians()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colMins()`            | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colOrderStats()`      | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colProds()`           | ✔                | ✔                        | ✔                             | ✔                             | ✔                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colQuantiles()`       | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colRanges()`          | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colRanks()`           | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colSdDiffs()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colSds()`             | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colsum()`             | ☑️               | ❌                        | ❌                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colSums2()`           | ✔                | ✔                        | ✔                             | ✔                             | ✔                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colTabulates()`       | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colVarDiffs()`        | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colVars()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colWeightedMads()`    | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colWeightedMeans()`   | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colWeightedMedians()` | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colWeightedSds()`     | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `colWeightedVars()`    | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowAlls()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowAnyMissings()`     | ✔                | ❌                        | ❌                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowAnyNAs()`          | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowAnys()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowAvgsPerColSet()`   | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowCollapse()`        | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowCounts()`          | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowCummaxs()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowCummins()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowCumprods()`        | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowCumsums()`         | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowDiffs()`           | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowIQRDiffs()`        | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowIQRs()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowLogSumExps()`      | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowMadDiffs()`        | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowMads()`            | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowMaxs()`            | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowMeans2()`          | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowMedians()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowMins()`            | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowOrderStats()`      | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowProds()`           | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowQuantiles()`       | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowRanges()`          | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowRanks()`           | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowSdDiffs()`         | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowSds()`             | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowsum()`             | ☑️               | ❌                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowSums2()`           | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowTabulates()`       | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowVarDiffs()`        | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowVars()`            | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowWeightedMads()`    | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowWeightedMeans()`   | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowWeightedMedians()` | ✔                | ✔                        | ✔                             | ❌                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowWeightedSds()`     | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
| `rowWeightedVars()`    | ✔                | ✔                        | ✔                             | ✔                             | ❌                                                        | ❌                                                          | ❌                                 | ❌                            | ❌                                |
