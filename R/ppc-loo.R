#' LOO predictive checks
#'
#' Leave-One-Out (LOO) predictive checks. See the \strong{Plot Descriptions}
#' section below for details.
#'
#' @name PPC-loo
#' @family PPCs
#' @template args-y-yrep
#' @param ... Currently unused.
#' @param lw A matrix of (smoothed) log weights with the same dimensions as
#'   \code{yrep}. If using \pkg{loo < 2.0.0} see the \code{\link[loo]{psislw}}
#'   function in the \pkg{loo} package, which returns smoothed weights that can
#'   be used to specify \code{lw}. If using \pkg{loo >= 2.0.0} see the
#'   \code{psis} function and the associated \code{weights} method.
#' @param alpha,size,fatten Arguments passed to code geoms to control plot
#'   aesthetics. For \code{ppc_loo_pit_qq} and \code{ppc_loo_pit_overlay},
#'   \code{size} and \code{alpha} are passed to
#'   \code{\link[ggplot2]{geom_point}} and \code{\link[ggplot2]{geom_density}},
#'   respectively. For \code{ppc_loo_intervals}, \code{size} and \code{fatten}
#'   are passed to \code{\link[ggplot2]{geom_pointrange}}. For
#'   \code{ppc_loo_ribbon}, \code{alpha} and \code{size} are passed to
#'   \code{\link[ggplot2]{geom_ribbon}}.
#'
#' @template return-ggplot
#'
#' @section Plot Descriptions:
#' \describe{
#' \item{\code{ppc_loo_pit_qq,ppc_loo_pit_overlay}}{
#'  The calibration of marginal predictions can be assessed using probability
#'  integral transformation (PIT) checks. LOO improves the check by avoiding the
#'  double use of data. See the section on marginal predictive checks in Gelman
#'  et al. (2013, p. 152--153) and section 5 of Gabry et al. (2018) for an
#'  example of using \pkg{bayesplot} for these checks.
#'
#'  The LOO PIT values are asymptotically uniform (for continuous data) if the
#'  model is calibrated. The \code{ppc_loo_pit_overlay} function creates a plot
#'  comparing the density of the LOO PITs (thick line) to the density estimates
#'  of many simulated data sets from the standard uniform distribution (thin
#'  lines). See Gabry et al. (2018) for an example of interpreting the shape of
#'  the miscalibration that can be observed in these plots.
#'
#'  The \code{ppc_loo_pit_qq} function provides an alternative visualization of
#'  the miscalibration with a quantile-quantile (Q-Q) plot comparing the LOO
#'  PITs to the standard uniform distribution. Comparing to the uniform is not
#'  good for extreme probabilities close to 0 and 1, so it can sometimes be
#'  useful to set the \code{compare} argument to \code{"normal"}, which will
#'  produce a Q-Q plot comparing standardized PIT values to the standard normal
#'  distribution that can help see the (mis)calibration better for the extreme
#'  values. However, in most cases we have found that the overlaid density plot
#'  (\code{ppc_loo_pit_overlay}) function will provided a clearer picture of
#'  calibration problems that the Q-Q plot.
#' }
#' \item{\code{ppc_loo_intervals, ppc_loo_ribbon}}{
#'  Similar to \code{\link{ppc_intervals}} and \code{\link{ppc_ribbon}} but the
#'  intervals are for the LOO predictive distribution.
#' }
#' }
#'
#' @templateVar bdaRef (p. 152--153)
#' @template reference-bda
#' @template reference-vis-paper
#' @template reference-loo
#'
#' @examples
#'
#' \dontrun{
#' library(rstanarm)
#' library(loo)
#'
#' head(radon)
#' fit <- stan_lmer(
#'   log_radon ~ floor + log_uranium + floor:log_uranium
#'                + (1 + floor | county),
#'   data = radon,
#'   iter = 1000,
#'   chains = 2  # ,cores = 2
#'  )
#' y <- radon$log_radon
#' yrep <- posterior_predict(fit)
#'
#' if (packageVersion("loo") < "2.0.0") {
#'   psis1 <- psislw(-log_lik(fit), cores = 2)
#'   lw <- psis1$lw_smooth
#' } else {
#'   psis1 <- psis(-log_lik(fit), cores = 2)
#'   lw <- weights(psis1)
#' }
#'
#' # marginal predictive check using LOO probability integral transform
#' color_scheme_set("orange")
#' ppc_loo_pit_overlay(y, yrep, lw = lw, adjust = 0.9)
#'
#' ppc_loo_pit_qq(y, yrep, lw = lw)
#' ppc_loo_pit_qq(y, yrep, lw = lw, compare = "normal")
#'
#'
#' # loo predictive intervals vs observations
#' sel <- 800:900
#' ppc_loo_intervals(y[sel], yrep[, sel], psis1$lw_smooth[, sel],
#'                   prob = 0.9, size = 0.5)
#'
#' color_scheme_set("gray")
#' ppc_loo_intervals(y[sel], yrep[, sel], psis1$lw_smooth[, sel],
#'                   order = "median", prob = 0.8, size = 0.5)
#' }
#'
NULL

#' @rdname PPC-loo
#' @export
#' @param pit For \code{ppc_loo_pit_overlay} and \code{ppc_loo_pit_qq},
#'   optionally a vector of precomputed PIT values that can be specified instead
#'   of \code{y}, \code{yrep}, and \code{lw} (these are all ignored if
#'   \code{pit} is specified). If not specified the PIT values are computed
#'   internally before plotting.
#' @param samples For \code{ppc_loo_pit_overlay}, the number of data sets (each
#'   the same size as \code{y}) to simulate from the standard uniform
#'   distribution. The default is 100. The density estimate of each dataset is
#'   plotted as a thin line in the plot, with the density estimate of the LOO
#'   PITs overlaid as a thicker dark line.
#' @param compare For \code{ppc_loo_pit_qq}, a string that can be either
#'   \code{"uniform"} or \code{"normal"}. If \code{"uniform"} (the default) the
#'   Q-Q plot compares computed PIT values to the standard uniform distribution.
#'   If \code{compare="normal"}, the Q-Q plot compares standardized PIT values
#'   to the standard normal distribution.
#' @param trim Passed to \code{\link[ggplot2]{stat_density}}.
#' @template args-density-controls
ppc_loo_pit_overlay <-
  function(y,
           yrep,
           lw,
           pit,
           samples = 100,
           ...,
           size = 0.25,
           alpha = 0.7,
           trim = FALSE,
           bw = "nrd0",
           adjust = 1,
           kernel = "gaussian",
           n_dens = 1024) {
    check_ignored_arguments(...)
    if (!missing(pit)) {
      stopifnot(is.numeric(pit), is_vector_or_1Darray(pit))
      message("'pit' specified so ignoring 'y','yrep','lw' if specified.")
    } else {
      suggested_package("rstantools")
      y <- validate_y(y)
      yrep <- validate_yrep(yrep, y)
      stopifnot(identical(dim(yrep), dim(lw)))
      pit <- rstantools::loo_pit(object = yrep, y = y, lw = lw)
    }

    unifs <- matrix(runif(length(pit) * samples), nrow = samples)
    graph <-
      ppc_dens_overlay(
        y = pit,
        yrep = unifs,
        size = size,
        alpha = alpha,
        trim = trim,
        bw = bw,
        adjust = adjust,
        kernel = kernel,
        n_dens = n_dens
      )
    graph <- suppressMessages(
      graph + scale_color_ppc_dist(labels = c("PIT", "Unif"))
    )

    g <- ggplot_build(graph)
    xylim <- g$layout$panel_ranges[[1]]
    ymax <- 1.25 * xylim$y.range[2]

    graph +
      scale_x_continuous(breaks = seq(from = .1, to = .9, by = .2)) +
      coord_cartesian(xlim = c(0.1, 0.9), ylim = c(0, ymax))
  }


#' @rdname PPC-loo
#' @export
ppc_loo_pit_qq <-
  function(y,
           yrep,
           lw,
           pit,
           compare = c("uniform", "normal"),
           ...,
           size = 2,
           alpha = 1) {
    check_ignored_arguments(...)
    compare <- match.arg(compare)
    if (!missing(pit)) {
      stopifnot(is.numeric(pit), is_vector_or_1Darray(pit))
      message("'pit' specified so ignoring 'y','yrep','lw' if specified.")
    } else {
      suggested_package("rstantools")
      y <- validate_y(y)
      yrep <- validate_yrep(yrep, y)
      stopifnot(identical(dim(yrep), dim(lw)))
      pit <- rstantools::loo_pit(object = yrep, y = y, lw = lw)
    }

    if (compare == "uniform") {
      theoretical <- stats::qunif
      x_lab <- "Uniform"
      y_lab <- "LOO-PIT"
    } else {
      pit <- as.vector(scale(pit))
      theoretical <- stats::qnorm
      x_lab <- "Normal"
      y_lab <- "LOO-PIT (standardized)"
    }

    graph <- ggplot(data.frame(p = pit)) +
      geom_point(
        aes_(sample = ~ p),
        stat = "qq",
        distribution = theoretical,
        color = get_color("m"),
        size = size,
        alpha = alpha
      ) +
      geom_abline(
        slope = 1,
        intercept = 0,
        linetype = 2,
        color = "black"
      )

    if (compare == "uniform") {
      xylim <- c(0, 1)
    } else {
      g <- ggplot_build(graph)
      xylim <- g$layout$panel_ranges[[1]]
      xylim <- range(xylim$y.range, xylim$x.range)
    }

    graph +
      coord_fixed(xlim = xylim, ylim = xylim) +
      labs(y = y_lab, x = x_lab)
  }


#' @rdname PPC-loo
#' @export
ppc_loo_pit <-
  function(y,
           yrep,
           lw,
           pit,
           compare = c("uniform", "normal"),
           ...,
           size = 2,
           alpha = 1) {
    .Deprecated("ppc_loo_pit_qq or ppc_loo_pit_overlay")
    ppc_loo_pit_qq(
      y = y,
      yrep = yrep,
      lw = lw,
      pit = pit,
      compare = compare,
      size = size,
      alpha = alpha,
      ...
    )
  }




#' @rdname PPC-loo
#' @export
#' @param psis_object If using \pkg{loo} version \code{2.0.0} or greater, an
#'   object returned by the \code{psis} function (or by the \code{loo} function
#'   with argument \code{save_psis} set to \code{TRUE}).
#' @param prob A value between 0 and 1 indicating the desired probability mass
#'   to include in the intervals. The default is 0.9.
#' @param intervals For \code{ppc_loo_intervals} and \code{ppc_loo_ribbon},
#'   optionally a matrix of precomputed LOO predictive intervals intervals with
#'   that can be specified instead of \code{yrep} and \code{lw} (these are both
#'   ignored if \code{intervals} is specified). If not specified the intervals
#'   are computed internally before plotting. If specified, \code{intervals}
#'   must be a matrix with number of rows equal to the number of data points and
#'   three columns in the following order: the first for the lower bound of the
#'   interval, the second for median (50\%), and the third for the interval
#'   upper bound (column names are ignored).
#' @param order For \code{ppc_loo_intervals}, a string indicating how to arrange
#'   the plotted intervals. The default (\code{"index"}) is to plot them in the
#'   order of the observations. The alternative (\code{"median"}) arranges them
#'   by median value from smallest (left) to largest (right).
#'
ppc_loo_intervals <-
  function(y,
           yrep,
           lw,
           psis_object,
           intervals = NULL,
           ...,
           prob = 0.9,
           size = 1,
           fatten = 3,
           order = c("index", "median")) {

    check_ignored_arguments(...)
    y <- validate_y(y)
    order_by_median <- match.arg(order) == "median"
    if (!is.null(intervals)) {
      stopifnot(is.matrix(intervals), ncol(intervals) == 3)
      message("'intervals' specified so ignoring 'yrep', 'lw', 'psis_object', if specified.")
    } else {
      suggested_package("loo")
      yrep <- validate_yrep(yrep, y)
      a <- (1 - prob) / 2
      if (utils::packageVersion("loo") >= "2.0.0") {
        stopifnot(identical(dim(psis_object), dim(yrep)))
        intervals <- suppressWarnings(t(loo::E_loo(
          x = yrep,
          psis_object = psis_object,
          type = "quantile",
          probs = sort(c(a, 0.5, 1 - a))
        )$value))
      } else {
        stopifnot(identical(dim(lw), dim(yrep)))
        intervals <- unclass(t(loo::E_loo(
          x = yrep,
          lw = lw,
          type = "quantile",
          probs = sort(c(a, 0.5, 1 - a))
        )))
      }
    }

    x <- seq_along(y)
    if (order_by_median) {
      x <- reorder(x, intervals[, 2])
    }

    graph <- .ppc_intervals(
      data = .loo_intervals_data(y, x, intervals),
      grouped = FALSE,
      style = "intervals",
      size = size,
      fatten = fatten,
      x_lab = "Data point (index)"
    )

    if (!order_by_median) {
      return(graph)
    }

    graph +
      xlab("Ordered by median") +
      xaxis_text(FALSE) +
      xaxis_ticks(FALSE)
  }

#' @rdname PPC-loo
#' @export
ppc_loo_ribbon <-
  function(y,
           yrep,
           lw,
           psis_object,
           intervals = NULL,
           ...,
           prob = 0.9,
           alpha = 0.33,
           size = 0.25) {
    check_ignored_arguments(...)
    y <- validate_y(y)
    if (!is.null(intervals)) {
      stopifnot(is.matrix(intervals), ncol(intervals) == 3)
      message("'intervals' specified so ignoring 'yrep', 'lw', 'psis_object', if specified.")
    } else {
      suggested_package("loo")
      yrep <- validate_yrep(yrep, y)
      a <- (1 - prob) / 2
      if (utils::packageVersion("loo") >= "2.0.0") {
        stopifnot(identical(dim(psis_object), dim(yrep)))
        intervals <- suppressWarnings(t(loo::E_loo(
          x = yrep,
          psis_object = psis_object,
          type = "quantile",
          probs = sort(c(a, 0.5, 1 - a))
        )$value))
      } else {
        stopifnot(identical(dim(lw), dim(yrep)))
        intervals <- t(loo::E_loo(
          x = yrep,
          lw = lw,
          type = "quantile",
          probs = sort(c(a, 0.5, 1 - a))
        ))
      }
    }
    .ppc_intervals(
      data = .loo_intervals_data(y, x = seq_along(y), intervals),
      grouped = FALSE,
      style = "ribbon",
      size = size,
      alpha = alpha,
      x_lab = "Data point (index)"
    )
  }



# internal ----------------------------------------------------------------
.loo_intervals_data <- function(y, x, intervals) {
  stopifnot(length(y) == nrow(intervals), length(x) == length(y))

  data.frame(
    y_id = seq_along(y),
    y_obs = y,
    x = x,
    lo = intervals[, 1],
    mid = intervals[, 2],
    hi = intervals[, 3])
}

