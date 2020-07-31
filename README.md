
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sandpaper

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/sandpaper)](https://CRAN.R-project.org/package=sandpaper)
<!-- badges: end -->

The {sandpaper} package was created by [The
Carpentries](https://carpentries.org) to re-imagine our method of
creating lesson websites for our workshops. This package will take a
series of [Markdown](https://daringfireball.net/projects/markdown/) or
[RMarkdown](https://rmarkdown.rstudio.com/) files and generate a static
website with the features and styling of The Carpentries lessons
including customized layouts and callout blocks.

## Installation

{sandpaper} is not currently on CRAN, but it can be installed from
github via the {remotes} package:

``` r
# install.packages("remotes")
remotes::install_github("carpentries/sandpaper")
```

## Usage

There are three use-cases for {sandpaper}:

1.  Creating lessons
2.  Maintaining lessons
3.  Contributing to lessons
4.  Rendering a portable site

The functions in {sandpaper} have the following prefixes:

  - `create_` will create files or folders in your workspace
  - `build_` will build files from your source
  - `get_` will retrieve information from your source files as an R
    object

# Creating a lesson

To create a lesson with {sandpaper}, use the `create_lesson()` function:

``` r
sandpaper::create_lesson("~/Desktop/r-intermediate-penguins")
```

This will create folder on your desktop called `r-intermediate-penguins`
with the following structure:

    |-- .gitignore               # - Ignore everything in the site/ folder
    |-- .github/                 # 
    |   `-- workflows/           #
    |       `-- workshop.yaml    # - Automatically build the source files on github pages
    |-- episodes/                # - PUT YOUR MARKDOWN FILES IN THIS FOLDER
    |   |-- data/                # - Data for your lesson goes here
    |   |-- extras/              # - Supplemental lesson material goes here
    |   |-- figures/             # - All static figures and diagrams are here
    |   |-- files/               # - Additional files (e.g. handouts) 
    |   `-- 00-introducition.Rmd # - Lessons start with a two-digit number
    |-- site/                    # - This folder is where your static site will live 
    |   `-- README.md            #
    |-- config.yaml              # - Use this to configure commonly used variables
    |-- CODE_OF_CONDUCT.md       # - Carpentries Code of Conduct (REQUIRED)
    `-- README.md                # - Use this to tell folks how to contribute

Once you have your site set up, you can add your RMarkdown files in the
episodes folder. The only thing controling how these files will appear
is the name of the file themselves, no config necessary :)
