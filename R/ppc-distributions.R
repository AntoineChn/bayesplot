#' PPC distributions
#'
#' Compare the empirical distribution of the data \code{y} to the distributions
#' of simulated/replicated data \code{yrep} from the posterior predictive
#' distribution. See the \strong{Plot Descriptions} section, below,
#' for details.
#'
#' @name PPC-distributions
#' @family PPCs
#'
#' @template args-y-yrep
#' @template args-hist
#' @template args-hist-freq
#' @template args-dens
#' @param size,alpha Passed to the appropriate geom to control the appearance of
#'   the \code{yrep} distributions.
#' @param ... Currently unused.
#'
#' @template details-binomial
#' @template return-ggplot-or-data
#'
#' @section Plot Descriptions:
#' \describe{
#'   \item{\code{ppc_hist, ppc_freqpoly, ppc_dens, ppc_boxplot}}{
#'    A separate histogram, shaded frequency polygon, smoothed kernel density
#'    estimate, or box and whiskers plot is displayed for \code{y} and each
#'    dataset (row) in \code{yrep}. For these plots \code{yrep} should therefore
#'    contain only a small number of rows. See the \strong{Examples} section.
#'   }
#'   \item{\code{ppc_freqpoly_grouped}}{
#'    A separate frequency polygon is plotted for each level of a grouping
#'    variable for \code{y} and each dataset (row) in \code{yrep}. For this plot
#'    \code{yrep} should therefore contain only a small number of rows. See the
#'    \strong{Examples} section.
#'   }
#'   \item{\code{ppc_dens_overlay, ppc_ecdf_overlay}}{
#'    Kernel density or empirical CDF estimates of each dataset (row) in
#'    \code{yrep} are overlaid, with the distribution of \code{y} itself on top
#'    (and in a darker shade).
#'   }
#'   \item{\code{ppc_violin_grouped}}{
#'    The density estimate of \code{yrep} within each level of a grouping
#'    variable is plotted as a violin with horizontal lines at notable
#'    quantiles. \code{y} is overlaid on the plot either as a violin, points, or
#'    both, depending on the \code{y_draw} argument.
#'   }
#' }
#'
#' @templateVar bdaRef (Ch. 6)
#' @template reference-bda
#'
#' @examples
#' color_scheme_set("brightblue")
#' y <- example_y_data()
#' yrep <- example_yrep_draws()
#' dim(yrep)
#' ppc_dens_overlay(y, yrep[1:25, ])
#' \donttest{
#' ppc_ecdf_overlay(y, yrep[sample(nrow(yrep), 25), ])
#' }
#'
#' # for ppc_hist,dens,freqpoly,boxplot definitely use a subset yrep rows so
#' # only a few (instead of nrow(yrep)) histograms are plotted
#' ppc_hist(y, yrep[1:8, ])
#'
#' \donttest{
#' color_scheme_set("red")
#' ppc_boxplot(y, yrep[1:8, ])
#'
#' # wizard hat plot
#' color_scheme_set("blue")
#' ppc_dens(y, yrep[200:202, ])
#' }
#'
#' ppc_freqpoly(y, yrep[1:3,], alpha = 0.1, size = 1, binwidth = 5)
#'
#' # if groups are different sizes then the 'freq' argument can be useful
#' group <- example_group_data()
#' ppc_freqpoly_grouped(y, yrep[1:3,], group) + yaxis_text()
#' \donttest{
#' ppc_freqpoly_grouped(y, yrep[1:3,], group, freq = FALSE) + yaxis_text()
#' }
#'
#' # don't need to only use small number of rows for ppc_violin_grouped
#' # (as it pools yrep draws within groups)
#' color_scheme_set("gray")
#' ppc_violin_grouped(y, yrep, group, size = 1.5)
#' \donttest{
#' ppc_violin_grouped(y, yrep, group, alpha = 0)
#'
#' # change how y is drawn
#' ppc_violin_grouped(y, yrep, group, alpha = 0, y_draw = "points", y_size = 1.5)
#' ppc_violin_grouped(y, yrep, group, alpha = 0, y_draw = "both",
#'                    y_size = 1.5, y_alpha = 0.5, y_jitter = 0.33)
#' }
#'
NULL



#' @rdname PPC-distributions
#' @export
ppc_data <- function(y, yrep, group = NULL) {
  y <- validate_y(y)
  yrep <- validate_yrep(yrep, y)
  data <- melt_and_stack(y, yrep)

  if (!is.null(group)) {
    group <- validate_group(group, y)
    group_indices <- dplyr::data_frame(group, y_id = seq_along(group))
    data <- data %>%
      left_join(group_indices, by = "y_id") %>%
      select(.data$group, dplyr::everything())
  }

  data
}



#' @rdname PPC-distributions
#' @export
ppc_hist <- function(y, yrep, ..., binwidth = NULL, freq = TRUE) {
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep)
  aes_list <- set_hist_aes(freq, fill = ~ is_y_label, color = ~ is_y_label)

  ggplot(data) +
    aes_list +
    geom_histogram(size = 0.25, binwidth = binwidth) +
    scale_fill_ppc_dist() +
    scale_color_ppc_dist() +
    facet_wrap_parsed("rep_label") +
    force_axes_in_facets() +
    dont_expand_y_axis() +
    space_legend_keys() +
    yaxis_text(FALSE) +
    yaxis_title(FALSE) +
    yaxis_ticks(FALSE) +
    xaxis_title(FALSE) +
    facet_text(FALSE) +
    facet_bg(FALSE)
}



#' @rdname PPC-distributions
#' @export
#' @param notch A logical scalar passed to \code{\link[ggplot2]{geom_boxplot}}.
#'   Unlike for \code{geom_boxplot}, the default is \code{notch=TRUE}.
#'
ppc_boxplot <- function(y, yrep, ..., notch = TRUE, size = 0.5, alpha = 1) {
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep)

  ggplot(data) +
    aes_(x = ~ rep_label, y = ~ value,
         fill = ~ is_y_label, color = ~ is_y_label) +
    geom_boxplot(
      notch = notch,
      size = size,
      alpha = alpha,
      outlier.alpha = 2 / 3) +
    scale_fill_ppc_dist() +
    scale_color_ppc_dist() +
    yaxis_title(FALSE) +
    xaxis_ticks(FALSE) +
    xaxis_text(FALSE) +
    xaxis_title(FALSE)
}



#' @rdname PPC-distributions
#' @export
ppc_freqpoly <- function(y, yrep, ...,
                         binwidth = NULL,
                         freq = TRUE,
                         size = 0.25,
                         alpha = 1) {
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep)
  aes_list <- set_hist_aes(freq, fill = ~ is_y_label, color = ~ is_y_label)

  ggplot(data) +
    aes_list +
    aes_(x = ~ value, fill = ~ is_y_label, color = ~ is_y_label) +
    geom_area(stat = "bin", binwidth = binwidth, size = size, alpha = alpha) +
    scale_fill_ppc_dist() +
    scale_color_ppc_dist() +
    facet_wrap_parsed("rep_label") +
    force_axes_in_facets() +
    dont_expand_y_axis() +
    space_legend_keys() +
    yaxis_text(FALSE) +
    yaxis_title(FALSE) +
    yaxis_ticks(FALSE) +
    xaxis_title(FALSE) +
    facet_text(FALSE) +
    facet_bg(FALSE)
}

#' @rdname PPC-distributions
#' @export
#' @template args-group
#'
ppc_freqpoly_grouped <- function(y, yrep, group, ..., binwidth = NULL,
                                 freq = TRUE, size = 0.25, alpha = 1) {
    check_ignored_arguments(...)
    data <- ppc_data(y, yrep, group)
    aes_list <- set_hist_aes(freq)

    ggplot(data) +
      aes_list +
      geom_area(aes_(color = ~ is_y_label, fill = ~ is_y_label),
                stat = "bin", size = size, alpha = alpha,
                binwidth = binwidth, na.rm = TRUE) +
      facet_grid(rep_label ~ group, scales = "free") +
      scale_fill_ppc_dist() +
      scale_color_ppc_dist() +
      dont_expand_y_axis(c(0.005, 0)) +
      force_axes_in_facets() +
      space_legend_keys() +
      xaxis_title(FALSE) +
      yaxis_text(FALSE) +
      yaxis_ticks(FALSE) +
      yaxis_title(FALSE) +
      facet_bg(FALSE) +
      theme(strip.text.y = element_blank())
  }


#' @rdname PPC-distributions
#' @export
ppc_dens <- function(y, yrep, ..., trim = FALSE, size = 0.5, alpha = 1) {
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep)

  ggplot(data) +
    aes_(x = ~ value, fill = ~ is_y_label, color = ~ is_y_label) +
    geom_density(size = size, alpha = alpha, trim = trim) +
    scale_fill_ppc_dist() +
    scale_color_ppc_dist() +
    facet_wrap_parsed("rep_label") +
    force_axes_in_facets() +
    dont_expand_y_axis() +
    space_legend_keys() +
    yaxis_text(FALSE) +
    yaxis_title(FALSE) +
    yaxis_ticks(FALSE) +
    xaxis_title(FALSE) +
    facet_text(FALSE) +
    facet_bg(FALSE)
}

#' @rdname PPC-distributions
#' @export
#' @template args-density-controls
ppc_dens_overlay <- function(y, yrep, ...,
                             size = 0.25,
                             alpha = 0.7,
                             trim = FALSE,
                             bw = "nrd0",
                             adjust = 1,
                             kernel = "gaussian",
                             n_dens = 1024) {
  
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep)

  ggplot(data) +
    aes_(x = ~ value) +
    stat_density(
      aes_(group = ~ rep_id, color = "yrep"),
      data = function(x) dplyr::filter(x, !.data$is_y),
      geom = "line",
      position = "identity",
      size = size,
      alpha = alpha,
      trim = trim,
      bw = bw,
      adjust = adjust,
      kernel = kernel,
      n = n_dens
    ) +
    stat_density(
      aes_(color = "y"),
      data = function(x) dplyr::filter(x, .data$is_y),
      geom = "line",
      position = "identity",
      lineend = "round",
      size = 1,
      trim = trim,
      bw = bw,
      adjust = adjust,
      kernel = kernel,
      n = n_dens
    ) +
    scale_color_ppc_dist() +
    xlab(y_label()) +
    dont_expand_axes() +
    yaxis_title(FALSE) +
    xaxis_title(FALSE) +
    yaxis_text(FALSE) +
    yaxis_ticks(FALSE)
}






#' @export
#' @rdname PPC-distributions
#' @param pad A logical scalar passed to \code{\link[ggplot2]{stat_ecdf}}.
ppc_ecdf_overlay <- function(y, yrep, ..., pad = TRUE, size = 0.25,
                             alpha = 0.7) {
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep)

  ggplot(data) +
    aes_(x = ~ value) +
    hline_at(c(0, 0.5, 1), size = c(0.2, 0.1, 0.2),
             linetype = 2, color = get_color("dh")) +
    stat_ecdf(
      data = function(x) dplyr::filter(x, !.data$is_y),
      mapping = aes_(group = ~ rep_id, color = "yrep"),
      geom = "line",
      size = size,
      alpha = alpha,
      pad = pad) +
    stat_ecdf(
      data = function(x) dplyr::filter(x, .data$is_y),
      mapping = aes_(color = "y"),
      geom = "line",
      size = 1,
      pad = pad) +
    scale_color_ppc_dist() +
    xlab(y_label()) +
    scale_y_continuous(breaks = c(0, 0.5, 1)) +
    yaxis_title(FALSE) +
    xaxis_title(FALSE) +
    yaxis_ticks(FALSE)
}

#' @export
#' @rdname PPC-distributions
#' @param probs A numeric vector passed to \code{\link[ggplot2]{geom_violin}}'s
#'   \code{draw_quantiles} argument to specify at which quantiles to draw
#'   horizontal lines. Set to \code{NULL} to remove the lines.
#' @param y_draw For \code{ppc_violin_grouped}, a string specifying how to draw
#'   \code{y}: \code{"violin"} (default), \code{"points"} (jittered points), or
#'   \code{"both"}.
#' @param y_jitter,y_size,y_alpha For \code{ppc_violin_grouped}, if
#'   \code{y_draw} is \code{"points"} or \code{"both"} then \code{y_size},
#'   \code{y_alpha}, and \code{y_jitter} are passed to to the \code{size},
#'   \code{alpha}, and \code{width} arguments of
#'   \code{\link[ggplot2]{geom_jitter}} to control the appearance of \code{y}
#'   points. The default of \code{y_jitter=NULL} will let \pkg{ggplot2}
#'   determine the amount of jitter.
#'
ppc_violin_grouped <- function(y, yrep, group, ..., probs = c(0.1, 0.5, 0.9),
                               size = 1, alpha = 1,
                               y_draw = c("violin", "points", "both"),
                               y_size = 1, y_alpha = 1, y_jitter = 0.1) {
  check_ignored_arguments(...)
  data <- ppc_data(y, yrep, group)

  y_draw <- match.arg(y_draw)
  y_violin <- y_draw %in% c("violin", "both")
  y_points <- y_draw %in% c("points", "both")

  args_violin_yrep <- list(
    data = function(x) dplyr::filter(x, !.data$is_y),
    aes_(fill = "yrep", color = "yrep"),
    draw_quantiles = probs,
    alpha = alpha,
    size = size
  )

  args_violin_y <- list(
    data = function(x) dplyr::filter(x, .data$is_y),
    aes_(fill = "y", color = "y"),
    show.legend = FALSE,
    alpha = 0
  )

  args_jitter_y <- list(
    data = function(x) dplyr::filter(x, .data$is_y),
    aes_(fill = "y", color = "y"),
    shape = 21,
    alpha = y_alpha,
    size = y_size,
    width = y_jitter,
    height = 0,
    show.legend = FALSE
  )

  violin_y_func <- if (y_violin) geom_violin else geom_ignore
  jitter_y_func <- if (y_points) geom_jitter else geom_ignore

  layer_violin_yrep <- do.call(geom_violin, args_violin_yrep)
  layer_violin_y <- do.call(violin_y_func, args_violin_y)
  layer_jitter_y <- do.call(jitter_y_func, args_jitter_y)

  ggplot(data) +
    aes_(x = ~ group, y = ~ value) +
    layer_violin_yrep +
    layer_violin_y +
    layer_jitter_y +
    scale_fill_ppc_dist(values = c(NA, get_color("l"))) +
    scale_color_ppc_dist() +
    labs(x = "Group", y = yrep_label()) +
    yaxis_title(FALSE) +
    xaxis_title(FALSE)
}


# internal ----------------------------------------------------------------
scale_color_ppc_dist <- function(name = NULL, values = NULL, labels = NULL) {
  scale_color_manual(
    name = name %||% "",
    values = values %||% get_color(c("dh", "lh")),
    labels = labels %||% c(y_label(), yrep_label())
  )
}
scale_fill_ppc_dist <- function(name = NULL, values = NULL, labels = NULL) {
  scale_fill_manual(
    name = name %||% "",
    values = values %||% get_color(c("d", "l")),
    labels = labels %||% c(y_label(), yrep_label())
  )
}
