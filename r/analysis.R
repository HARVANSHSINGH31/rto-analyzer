# r/analysis.R
# Statistical analysis of delivery failures. Every method used is from the
# Statistics with R syllabus. Results go to the analysis_results table,
# charts go to src/main/webapp/charts/ so the Java dashboard can show them.

suppressPackageStartupMessages({
  library(DBI)
  library(RMariaDB)
})

con <- dbConnect(RMariaDB::MariaDB(),
                 dbname = "rto_db",
                 default.file = path.expand("~/.my.cnf"),
                 group = "client",
                 unix.socket = "/tmp/mysql.sock")

chart_dir <- "src/main/webapp/charts"
dir.create(chart_dir, recursive = TRUE, showWarnings = FALSE)

results <- data.frame(test_name = character(), dimension = character(),
                      statistic = character(), value = numeric())
add <- function(test, dim, stat, val) {
  results <<- rbind(results, data.frame(test_name = test, dimension = dim,
                                        statistic = stat, value = as.numeric(val)))
}

# ---------------- data ----------------
ship <- dbGetQuery(con, "
  SELECT s.shipment_id, s.payment_mode, s.order_value, s.weight_kg, s.status,
         k.name AS courier, c.address_quality
  FROM shipments s
  JOIN couriers k  ON k.courier_id  = s.courier_id
  JOIN customers c ON c.customer_id = s.customer_id
  WHERE s.status IN ('DELIVERED', 'RTO')")
ship$order_value <- as.numeric(ship$order_value)
ship$rto <- as.integer(ship$status == "RTO")

att <- dbGetQuery(con, "
  SELECT a.shipment_id, a.attempt_no, a.time_slot, a.outcome, k.name AS courier,
         TIMESTAMPDIFF(HOUR, s.created_at, a.attempt_time) / 24 AS days_to_attempt
  FROM delivery_attempts a
  JOIN shipments s ON s.shipment_id = a.shipment_id
  JOIN couriers k  ON k.courier_id  = s.courier_id")
att$days_to_attempt <- as.numeric(att$days_to_attempt)
att$failed <- as.integer(att$outcome == "FAILED")

# ---------------- 1. descriptive statistics ----------------
add("Descriptive", "overall", "shipments_analysed", nrow(ship))
add("Descriptive", "overall", "rto_rate", mean(ship$rto))
add("Descriptive", "order_value", "mean", mean(ship$order_value))
add("Descriptive", "order_value", "median", median(ship$order_value))
add("Descriptive", "order_value", "sd", sd(ship$order_value))
add("Descriptive", "attempts", "attempt_failure_rate", mean(att$failed))

# ---------------- 2. binomial: are failures independent? ----------------
# If every attempt failed independently with probability p,
# P(RTO) = P(3 failures in 3 trials) = dbinom(3, 3, p)
p_fail <- mean(att$failed)
add("Binomial", "independence check", "p_attempt_fail", p_fail)
add("Binomial", "independence check", "expected_rto_rate", dbinom(3, 3, p_fail))
add("Binomial", "independence check", "observed_rto_rate", mean(ship$rto))

# ---------------- 3. CI for proportions + two-sample test ----------------
tab_pay <- table(ship$payment_mode, ship$rto)
x_pay <- tab_pay[, "1"]
n_pay <- rowSums(tab_pay)
for (m in names(x_pay)) {
  ci <- prop.test(x_pay[m], n_pay[m])$conf.int
  add("CI for proportion (95%)", m, "rto_rate", x_pay[m] / n_pay[m])
  add("CI for proportion (95%)", m, "ci_low", ci[1])
  add("CI for proportion (95%)", m, "ci_high", ci[2])
}
pt <- prop.test(x_pay, n_pay)
add("Two-sample proportion test", "COD vs PREPAID", "chi_sq", pt$statistic)
add("Two-sample proportion test", "COD vs PREPAID", "p_value", pt$p.value)

# ---------------- 4. k-sample proportion tests ----------------
tab_cour <- table(att$courier, att$failed)
pk <- prop.test(tab_cour[, "1"], rowSums(tab_cour))
add("k-sample proportion test", "failure ~ courier", "p_value", pk$p.value)
for (k in rownames(tab_cour)) {
  add("Failure rate by courier", k, "rate", tab_cour[k, "1"] / sum(tab_cour[k, ]))
}

tab_slot <- table(att$time_slot, att$failed)
ps <- prop.test(tab_slot[, "1"], rowSums(tab_slot))
add("k-sample proportion test", "failure ~ time slot", "p_value", ps$p.value)
for (s in rownames(tab_slot)) {
  add("Failure rate by time slot", s, "rate", tab_slot[s, "1"] / sum(tab_slot[s, ]))
}

# ---------------- 5. ANOVA: days to first attempt by courier ----------------
first <- att[att$attempt_no == 1, ]
fit_aov <- aov(days_to_attempt ~ courier, data = first)
aov_tab <- summary(fit_aov)[[1]]
add("ANOVA", "days to 1st attempt ~ courier", "F", aov_tab[["F value"]][1])
add("ANOVA", "days to 1st attempt ~ courier", "p_value", aov_tab[["Pr(>F)"]][1])
means <- tapply(first$days_to_attempt, first$courier, mean)
for (k in names(means)) add("Mean days to 1st attempt", k, "days", means[k])

# ---------------- 6. multiple linear regression: RTO loss ----------------
loss <- dbGetQuery(con, "
  SELECT r.forward_cost + r.return_cost + r.lost_margin AS total_loss,
         s.weight_kg, s.order_value
  FROM rto_costs r JOIN shipments s ON s.shipment_id = r.shipment_id")
loss[] <- lapply(loss, as.numeric)
fit_lm <- lm(total_loss ~ weight_kg + order_value, data = loss)
sm <- summary(fit_lm)
add("Multiple linear regression", "loss ~ weight + value", "r_squared", sm$r.squared)
add("Multiple linear regression", "loss ~ weight + value", "adj_r_squared", sm$adj.r.squared)
add("Multiple linear regression", "loss ~ weight + value", "F", sm$fstatistic[1])
add("Multiple linear regression", "loss ~ weight + value", "coef_weight_kg", coef(fit_lm)["weight_kg"])
add("Multiple linear regression", "loss ~ weight + value", "coef_order_value", coef(fit_lm)["order_value"])
add("Multiple linear regression", "loss ~ weight + value", "total_rto_loss_rs", sum(loss$total_loss))

# ---------------- charts (base R plotting) ----------------
save_png <- function(name, expr) {
  png(file.path(chart_dir, name), width = 900, height = 520, res = 120)
  par(mar = c(5, 5, 3, 1))
  expr
  invisible(dev.off())
}

save_png("rto_by_payment.png", {
  barplot(x_pay / n_pay * 100, col = c("#e4572e", "#4c9f70"),
          main = "RTO rate by payment mode", ylab = "RTO rate (%)", ylim = c(0, 40))
})

save_png("fail_by_courier.png", {
  r <- sort(tab_cour[, "1"] / rowSums(tab_cour) * 100, decreasing = TRUE)
  barplot(r, col = "#2f6fed", main = "Attempt failure rate by courier",
          ylab = "Failure rate (%)", ylim = c(0, max(r) * 1.25))
})

save_png("fail_by_slot.png", {
  r <- tab_slot[c("MORNING", "AFTERNOON", "EVENING"), "1"] /
       rowSums(tab_slot[c("MORNING", "AFTERNOON", "EVENING"), ]) * 100
  barplot(r, col = "#f0a202", main = "Attempt failure rate by time slot",
          ylab = "Failure rate (%)", ylim = c(0, max(r) * 1.25))
})

save_png("days_by_courier.png", {
  boxplot(days_to_attempt ~ courier, data = first, col = "#cfe0ff",
          main = "Days to first delivery attempt (ANOVA)", ylab = "Days", xlab = "")
})

save_png("regression_residuals.png", {
  plot(fitted(fit_lm), resid(fit_lm), pch = 19, col = "#1d233080",
       main = "MLR residuals vs fitted", xlab = "Fitted loss (Rs)", ylab = "Residual")
  abline(h = 0, col = "red", lwd = 2)
})

# ---------------- save results for Java ----------------
invisible(dbExecute(con, "DELETE FROM analysis_results"))
invisible(dbAppendTable(con, "analysis_results", results))
dbDisconnect(con)

print(transform(results, value = round(value, 4)), row.names = FALSE)
cat("\nAnalysis complete. Charts saved to", chart_dir, "\n")