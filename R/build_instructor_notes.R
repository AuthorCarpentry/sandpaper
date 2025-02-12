#' @rdname build_agg
#' @param built a vector of markdown documents that have recently been rebuilt
#'   (for future use)
build_instructor_notes <- function(pkg, pages = NULL, built = NULL, quiet) {
  path <- root_path(pkg$src_path)
  this_lesson(path)
  outpath <- fs::path(pkg$dst_path, "instructor-notes.html")
  already_built <- template_check$valid() && 
    fs::file_exists(outpath) && 
    !is.null(built) && 
    !"instructor-notes" %in% get_slug(built)
  if (!already_built) {
    page_globals <- setup_page_globals()
    inote <- .resources$get()[["instructors"]]
    inote <- inote[get_slug(inote) == "instructor-notes"]
    html <- render_html(inote)
    if (html != '') {
      html  <- xml2::read_html(html)
      fix_nodes(html)
    }

    this_dat <- list(
      this_page = "instructor-notes.html",
      body = use_instructor(html),
      pagetitle = "Instructor Notes"
    )

    page_globals$instructor$update(this_dat)

    this_dat$body = use_learner(html)
    page_globals$learner$update(this_dat)

    page_globals$meta$update(this_dat)

    build_html(template = "extra", pkg = pkg, nodes = html,
      global_data = page_globals, path_md = "instructor-notes.html", quiet = TRUE)
  }
  build_agg_page(pkg = pkg, 
    pages = pages, 
    title = this_dat$pagetitle, 
    slug = "instructor-notes", 
    aggregate = "/div[contains(@class, 'instructor-note')]//div[@class='accordion-body']", 
    append = "section[@id='aggregate-instructor-notes']",
    prefix = FALSE, 
    quiet = quiet)
}

#' Make a section of aggregated instructor notes
#'
#' This will append instructor notes from the inline sections of the lesson to
#' the instructor-notes page, separated by section and `<hr>` elements. 
#'
#' @param name the name of the section, (may or may not be prefixed with `images-`)
#' @param contents an `xml_nodeset` of figure elements from [get_content()]
#' @param parent the parent div of the images page 
#' @return the section that was added to the parent
#' @note On the learner view, instructor notes will not be present
#'
#' @keywords internal
#' @seealso [build_instructor_notes()], [get_content()]
#' @examples
#' if (FALSE) {
#' lsn <- "/path/to/lesson"
#' pkg <- pkgdown::as_pkgdown(fs::path(lsn, "site"))
#' 
#' # read in the All in One page and extract its content
#' notes <- get_content("instructor-notes", content =
#'   "section[@id='aggregate-instructor-notes']", pkg = pkg, instructor = TRUE)
#' agg <- "/div[contains(@class, 'instructor-note')]//div[@class='accordion-body']"
#' note_content <- get_content("01-introduction", content = agg, pkg = pkg)
#' make_instructornotes_section("01-introduction", contents = note_content, 
#'   parent = notes)
#'
#' # NOTE: if the object for "contents" ends with "_learn", no content will be
#' # appended
#' note_learn <- note_content
#' make_instructornotes_section("01-introduction", contents = note_learn, 
#'   parent = notes)
#'
#' }
make_instructornotes_section <- function(name, contents, parent) {
  # Since we have hidden the instructor notes from the learner sections,
  # there is no point to iterate here, so we return early.
  the_call <- match.call()
  is_learner <- endsWith(as.character(the_call[["contents"]]), "learn")
  if (is_learner) {
    return(invisible(NULL))
  }
  title <- names(name)
  uri <- sub("^instructor-notes-", "", name)
  new_section <- "<section id='{name}'>
  <h2 class='section-heading'><a href='{uri}.html'>{title}</a></h2>
  <hr class='half-width'/>
  </section>"
  section <- xml2::read_xml(glue::glue(new_section))
  for (element in contents) {
    for (child in xml2::xml_children(element)) {
      xml2::xml_add_child(section, child)
    }
    xml2::xml_add_child(section, "hr")
  }
  xml2::xml_add_child(parent, section)
}
