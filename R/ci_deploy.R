#' (INTERNAL) Build and deploy the site with continous integration
#'
#' @param path path to the lesson
#' @param md_branch the branch name that contains the markdown outputs
#' @param site_branch the branch name that contains the full HTML site
#' @param remote the name of the git remote to which you should deploy.
#' @param reset if `TRUE`, the site cache is cleared before rebuilding, this
#'   defaults to `FALSE` meaning that the cache in the md_branch will be used
#' @return Nothing, invisibly. This is used for it's side-effect
#'
#' @note this function is not for interactive use. It requires git to be
#'   installed on your machine and will destroy anything you have in the
#'   `site/` folder. 
#' 
#' @keywords internal
ci_deploy <- function(path = ".", md_branch = "md-outputs", site_branch = "gh-pages", remote = "origin", reset = FALSE) {

  if (interactive() && is.null(getOption('sandpaper.test_fixture'))) {
    stop("This function is for use on continuous integration only", call. = FALSE)
  }

  # Enforce git user exists
  check_git_user(path, name = "GitHub Actions", email = "actions@github.com")

  validate_lesson(path)

  # Step 1: build markdown source files
  del_md <- ci_build_markdown(path, branch = md_branch, remote = remote, reset = reset)
  on.exit(eval(del_md), add = TRUE)

  # Step 2: build the site from the source files
  ci_build_site(path, branch = site_branch, md = md_branch, remote = remote, reset = reset)

  invisible()
}

