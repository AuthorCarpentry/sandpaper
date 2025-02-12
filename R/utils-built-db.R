#' Get the expected hash from a set of built files
#'
#' @param path path to at least one generated markdown file
#' @param db the path to the text database
#' @return a character vector of checksums
#' @keywords internal
#' @seealso [build_status()], [get_built_db()]
get_hash <- function(path, db = fs::path(path_built(path), "md5sum.txt")) {
  opt = options(stringsAsFactors = FALSE)
  on.exit(options(opt), add = TRUE)
  db <- get_built_db(db, filter = "*")
  db$checksum[fs::path_file(db$built) %in% fs::path_file(path)]
}

#' Get the database of built files and their hashes
#'
#' @param db the path to the database.
#' @param filter regex describing files to include. 
#' @return a data frame with three columns:
#'   - file: the path to the source file
#'   - checksum: the hash of the source file to generate the built file
#'   - built: the path to the built file 
#' @keywords internal
#' @seealso [build_status()], [get_hash()]
get_built_db <- function(db = "site/built/md5sum.txt", filter = "*R?md") {
  opt <- options(stringsAsFactors = FALSE)
  on.exit(options(opt), add = TRUE)
  if (!file.exists(db)) {
    # no markdown files have been built yet
    return(data.frame(file = character(0), checksum = character(0), built = character(0)))
  }
  files <- read.table(db, header = TRUE)
  are_markdown <- grepl(filter, fs::path_ext(files[["file"]]))
  return(files[are_markdown, , drop = FALSE])
}

#' Filter reserved files from the built db
#'
#' @param db the database from [get_built_db()]
#' @return a data frame, but a bit shorter
#' @keywords internal
#' @seealso [get_built_db()]
reserved_db <- function(db) {
  reserved <- c("index", "README", "CONTRIBUTING", "learners/setup", 
    "profiles[/].*", "instructors[/]instructor-notes[.]*", "links")
  reserved <- paste(reserved, collapse = "|")
  reserved <- paste0("^(", reserved, ")[.]R?md")
  db[!grepl(reserved, db$file, perl = TRUE), , drop = FALSE]
}

write_build_db <- function(md5, db) write.table(md5, db, row.names = FALSE)

#' Identify what files need to be rebuilt and what need to be removed
#'
#' This takes in a vector of files and compares them against a text database of
#' files with checksums. It's been heavily adapted from blogdown to provide 
#' utilities for removal and updating of the old database.
#'
#' @details
#'
#' If you supply a single file into this function, we assume that you want that
#' one file to be rebuilt, so we will _always_ return that file in the `$build`
#' element and update the md5 sum in the database (if it has changed at all).
#'
#' If you supply multiple files, you are indicating that these are the _only_
#' files you care about and the database will be updated accordingly, removing
#' entries missing from the sources.
#'
#' @param sources a character vector of ALL source files OR a single file to be
#'   rebuilt. These must be *absolute paths*
#' @param db the path to the database
#' @param rebuild if the files should be rebuilt, set this to TRUE (defaults to
#'   FALSE)
#' @param write if TRUE, the database will be updated, Defaults to FALSE,
#' meaning that the database will remain the same. 
#' @return a list of the following elements
#'   - *build* absolute paths of files to build
#'   - *new* a new data frame with three columns: 
#'      - file the relative path to the source file
#'      - checksum the md5 sum of the source file
#'      - built the relative path to the built file
#'   - *remove* absolute paths of files to remove. This will be missing if there
#'      is nothing to remove
#'   - *old* old database (for debugging). This will be missing if there is no
#'     old database or if a single file was rebuilt.
#' @keywords internal
#' @seealso [get_resource_list()], [get_built_db()], [get_hash()]
build_status <- function(sources, db = "site/built/md5sum.txt", rebuild = FALSE, write = FALSE) {
  # Modified on 2021-03-10 from blogdown::filter_md5sum version 1.2
  # Original author: Yihui Xie
  # My additional commands use arrows.
  opt = options(stringsAsFactors = FALSE)
  on.exit(options(opt), add = TRUE)
  # To make this portable, we want to record relative paths. The sources coming
  # in will be absolute paths, so this will check for the common path and then
  # trim it.
  build_one <- length(sources) == 1L

  # If we have a single source passed in, this means that we want to update it
  # in the database and force it to rebuild
  if (build_one) {
    root_path <- root_path(sources)
  } else {
    root_path <- fs::path_common(sources)
  }
  sources    <- fs::path_rel(sources, start = root_path)
  built_path <- fs::path_rel(fs::path_dir(db), root_path)
  # built files are flattened here
  built <- fs::path(built_path, fs::path_file(sources))
  built <- ifelse(
    fs::path_ext(built) %in% c("Rmd", "rmd"),
    fs::path_ext_set(built, "md"), built
  )
  date <- format(Sys.Date(), "%F")
  md5 = data.frame(
    file     = sources,
    checksum = tools::md5sum(fs::path(root_path, sources)),
    built    = built,
    date     = date,
    stringsAsFactors = FALSE
  )
  if (!file.exists(db)) {
    fs::dir_create(dirname(db))
    md5$date <- date
    if (write)
      write_build_db(md5, db)
    return(list(build = fs::path(root_path, sources), new = md5))
  }
  # old checksums (2 columns: file path and checksum)
  old = read.table(db, header = TRUE)
  # insert current date if it does not exist
  old <- if (is.null(old$date)) data.frame(old, list(date = date), stringsAsFactors = FALSE) else old
  # BUILD ONLY ONE FILE --------------------------------------------------------
  if (build_one) {
    new <- old
    to_build <- old$file == md5$file
    if (any(to_build)) {
      new$checksum[to_build] <- md5$checksum
      new$built[to_build]    <- md5$built
    } else {
      new <- rbind(old, md5)
    }
    return(list(build = fs::path(root_path, sources), new = new))
  }
  # FILTERING ------------------------------------------------------------------
  #
  # Here we determine the files to keep and the files to remove. This creates
  # a 7-column data frame that contains the following fields:
  #
  # 1. file - the data merged on the file name
  # 2. checksum, the NEW checksum values for these files (NA if the file no
  #    no longer exists)
  # 3. built the relative path to the built file (NA if the file no longer exists)
  # 4. date today's date
  # 5. checksum.old the old checksum values
  # 6. built.old the old built path
  # 7. date.old the date the files were previously built
  one = merge(md5, old, 'file', all = TRUE, suffixes = c('', '.old'), sort = FALSE)
  newsum <- names(one)[2]
  oldsum <- paste0(newsum, ".old")
  # Find the files that need to be removed because they don't exist anymore.
  # TODO: add a switch to _not_ remove these files, because we want to rebuild
  #       a subset of the files.
  to_remove <- one[['built.old']][is.na(one[[newsum]])]
  # merge destroys the order, so we need to reset it. Consequently, it will
  # also remove the files that no longer exist in the sources list.
  one <- one[match(sources, one$file), , drop = FALSE]
  # TODO: see if we can have rebuild be a vector matching the sources so that
  #       we can indicate a vector of files to rebuild. 
  if (rebuild) {
    files = one[['file']]
    to_remove <- old[['built']]
  } else {
    # exclude files from the build order if checksums are not changed
    unchanged <- one[[newsum]] == one[[oldsum]]
    # do not overwrite the dates
    one[["date"]][which(unchanged)] <- one[["date.old"]][which(unchanged)]
    files = setdiff(sources, one[['file']][unchanged])
  }
  if (write) {
    write_build_db(one[, 1:4], db)
  }
  # files and to_remove need absolute paths so that subprocesses can run them
  files     <- fs::path_abs(files, start = root_path)
  to_remove <- fs::path_abs(to_remove, start = root_path)

  list(
    build = files,
    remove = to_remove,
    new = one[, 1:4],
    old = old
  )
}


