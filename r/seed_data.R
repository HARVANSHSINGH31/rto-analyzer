# r/seed_data.R
# Generates SIMULATED shipment data with planted patterns and loads it into rto_db.
# Planted effects: courier quality, COD, incomplete address, delivery time slot.

suppressPackageStartupMessages({
  library(DBI)
  library(RMariaDB)
})
set.seed(2026)

# Credentials come from ~/.my.cnf, so no password lives in the repo
con <- dbConnect(RMariaDB::MariaDB(),
                 dbname = "rto_db",
                 default.file = path.expand("~/.my.cnf"),
                 groups = "client",
                 unix.socket = "/tmp/mysql.sock")

# ---- reset tables so the script can be re-run ----
dbExecute(con, "SET FOREIGN_KEY_CHECKS = 0")
for (t in c("analysis_results", "status_audit", "rto_costs",
            "delivery_attempts", "shipments", "customers", "couriers")) {
  dbExecute(con, paste("TRUNCATE TABLE", t))
}
dbExecute(con, "SET FOREIGN_KEY_CHECKS = 1")

# ---- couriers (fictional names) ----
couriers <- data.frame(
  courier_id   = 1:4,
  name         = c("SwiftShip", "ZoomDel", "PinPoint Couriers", "MetroDrop"),
  service_type = c("EXPRESS", "STANDARD", "STANDARD", "EXPRESS")
)
courier_eff     <- c(-0.4, 0.0, 0.6, -0.1)  # higher = more failures
courier_transit <- c(2, 3, 4, 2)            # base transit days

# ---- customers ----
n_cust   <- 1200
cities   <- c("Delhi", "Noida", "Gurugram", "Jaipur", "Lucknow", "Patna")
prefix   <- c("110", "201", "122", "302", "226", "800")
inc_rate <- c(0.15, 0.18, 0.12, 0.22, 0.28, 0.32)
ci <- sample(1:6, n_cust, replace = TRUE, prob = c(.30, .15, .15, .13, .13, .14))
customers <- data.frame(
  customer_id     = 1:n_cust,
  name            = paste("Customer", 1:n_cust),
  city            = cities[ci],
  pincode         = paste0(prefix[ci], sprintf("%03d", sample(1:99, n_cust, replace = TRUE))),
  address_quality = ifelse(runif(n_cust) < inc_rate[ci], "INCOMPLETE", "GOOD")
)

# ---- shipments ----
n      <- 2000
n_open <- 150   # newest shipments stay in progress for the live Java demo
tz     <- "Asia/Kolkata"
cust   <- sample(1:n_cust, n, replace = TRUE)
cour   <- sample(1:4, n, replace = TRUE, prob = c(.30, .30, .20, .20))
pay    <- ifelse(runif(n) < 0.55, "COD", "PREPAID")
value  <- round(rlnorm(n, log(1200), 0.6), 2)
weight <- round(runif(n, 0.2, 5), 2)
created <- as.POSIXct("2026-07-30 08:00:00", tz = tz) + sort(runif(n, 0, 88 * 86400))
status <- character(n)

slots    <- c("MORNING", "AFTERNOON", "EVENING")
slot_eff <- c(0.4, 0.0, -0.3)
slot_hr  <- c(9, 12, 16)

a_sid <- c(); a_no <- c(); a_time <- c(); a_slot <- c()
a_out <- c(); a_reason <- c(); a_rem <- c()
rto_ids <- c()

n_done <- n - n_open
for (i in seq_len(n_done)) {
  inc      <- customers$address_quality[cust[i]] == "INCOMPLETE"
  cod      <- pay[i] == "COD"
  cust_eff <- rnorm(1, 0, 1)   # same customer tends to fail repeatedly
  transit  <- courier_transit[cour[i]] + rpois(1, 1)
  day0     <- as.POSIXct(format(created[i], "%Y-%m-%d"), tz = tz)
  status[i] <- "RTO"

  for (a in 1:3) {
    s <- sample(1:3, 1, prob = c(.35, .35, .30))
    p <- plogis(-1.0 + courier_eff[cour[i]] + 0.9 * cod + 1.2 * inc + slot_eff[s] + cust_eff)
    failed <- runif(1) < p
    t_att  <- day0 + (transit + a - 1) * 86400 + (slot_hr[s] + runif(1, 0, 3.9)) * 3600

    reason <- NA
    rem    <- NA
    if (failed) {
      if (inc && runif(1) < 0.7) {
        reason <- "WRONG_ADDRESS"
      } else if (cod && runif(1) < 0.6) {
        reason <- sample(c("COD_NOT_READY", "REFUSED"), 1)
      } else {
        reason <- "CUSTOMER_UNAVAILABLE"
      }
      rem <- sprintf('{"call_attempted": %s, "rescheduled": %s}',
                     tolower(runif(1) < 0.8), tolower(a < 3))
    }

    a_sid    <- c(a_sid, i)
    a_no     <- c(a_no, a)
    a_time   <- c(a_time, format(t_att, "%Y-%m-%d %H:%M:%S"))
    a_slot   <- c(a_slot, slots[s])
    a_out    <- c(a_out, if (failed) "FAILED" else "DELIVERED")
    a_reason <- c(a_reason, reason)
    a_rem    <- c(a_rem, rem)

    if (!failed) {
      status[i] <- "DELIVERED"
      break
    }
  }
  if (status[i] == "RTO") rto_ids <- c(rto_ids, i)
}
status[(n_done + 1):n] <- sample(c("CREATED", "SHIPPED", "OUT_FOR_DELIVERY"),
                                 n_open, replace = TRUE)

shipments <- data.frame(
  shipment_id  = 1:n,
  order_ref    = sprintf("ORD%06d", 1:n),
  customer_id  = cust,
  courier_id   = cour,
  payment_mode = pay,
  order_value  = value,
  weight_kg    = weight,
  status       = status,
  created_at   = format(created, "%Y-%m-%d %H:%M:%S"),
  updated_at   = format(created, "%Y-%m-%d %H:%M:%S")
)

attempts <- data.frame(
  shipment_id    = a_sid,
  attempt_no     = a_no,
  attempt_time   = a_time,
  time_slot      = a_slot,
  outcome        = a_out,
  failure_reason = a_reason,
  remarks        = a_rem
)

fwd <- round(40 + 12 * weight[rto_ids] + rnorm(length(rto_ids), 0, 5), 2)
rto_costs <- data.frame(
  shipment_id  = rto_ids,
  forward_cost = fwd,
  return_cost  = round(fwd * 0.9 + rnorm(length(rto_ids), 0, 3), 2),
  lost_margin  = round(value[rto_ids] * 0.25, 2)
)

# ---- load into MySQL (parent tables first) ----
dbAppendTable(con, "couriers", couriers)
dbAppendTable(con, "customers", customers)
dbAppendTable(con, "shipments", shipments)
dbAppendTable(con, "delivery_attempts", attempts)
dbAppendTable(con, "rto_costs", rto_costs)

# ---- sanity check ----
print(dbGetQuery(con, "SELECT status, COUNT(*) AS n FROM shipments GROUP BY status"))
print(dbGetQuery(con, "
  SELECT payment_mode, ROUND(AVG(status = 'RTO') * 100, 1) AS rto_pct
  FROM shipments WHERE status IN ('DELIVERED','RTO')
  GROUP BY payment_mode"))

dbDisconnect(con)
cat("Seed complete.\n")