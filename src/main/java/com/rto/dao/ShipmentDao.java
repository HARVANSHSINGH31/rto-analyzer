package com.rto.dao;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import com.rto.model.Shipment;
import com.rto.model.ShipmentStatus;

@Repository
public class ShipmentDao {

    private static final String BASE_SELECT =
        "SELECT s.shipment_id, s.order_ref, c.name AS customer_name, c.city, " +
        "k.name AS courier_name, s.payment_mode, s.order_value, s.status, " +
        "DATE_FORMAT(s.created_at, '%d %b %Y %H:%i') AS created_at " +
        "FROM shipments s " +
        "JOIN customers c ON c.customer_id = s.customer_id " +
        "JOIN couriers k ON k.courier_id = s.courier_id ";

    private final JdbcTemplate jdbc;

    public ShipmentDao(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private Shipment mapShipment(ResultSet rs, int rowNum) throws SQLException {
        Shipment s = new Shipment();
        s.setShipmentId(rs.getInt("shipment_id"));
        s.setOrderRef(rs.getString("order_ref"));
        s.setCustomerName(rs.getString("customer_name"));
        s.setCity(rs.getString("city"));
        s.setCourierName(rs.getString("courier_name"));
        s.setPaymentMode(rs.getString("payment_mode"));
        s.setOrderValue(rs.getBigDecimal("order_value"));
        s.setStatus(rs.getString("status"));
        s.setCreatedAt(rs.getString("created_at"));
        return s;
    }

    // ---------- reads ----------

    public List<Map<String, Object>> countByStatus() {
        return jdbc.queryForList(
            "SELECT status, COUNT(*) AS total FROM shipments GROUP BY status ORDER BY total DESC");
    }

    public List<Map<String, Object>> listCouriers() {
        return jdbc.queryForList("SELECT courier_id, name FROM couriers ORDER BY name");
    }

    // Parameterized query: user input never gets concatenated into SQL (prevents SQL injection)
    public List<Shipment> findShipments(String status, Integer courierId) {
        StringBuilder sql = new StringBuilder(BASE_SELECT).append("WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (status != null && !status.isBlank()) {
            sql.append(" AND s.status = ?");
            params.add(status);
        }
        if (courierId != null) {
            sql.append(" AND s.courier_id = ?");
            params.add(courierId);
        }
        sql.append(" ORDER BY s.created_at DESC LIMIT 100");
        return jdbc.query(sql.toString(), this::mapShipment, params.toArray());
    }

    public Shipment findById(int id) {
        return jdbc.queryForObject(BASE_SELECT + "WHERE s.shipment_id = ?", this::mapShipment, id);
    }

    public List<Map<String, Object>> findAttempts(int id) {
        return jdbc.queryForList(
            "SELECT attempt_no, DATE_FORMAT(attempt_time, '%d %b %Y %H:%i') AS attempt_time, " +
            "time_slot, outcome, failure_reason, remarks " +
            "FROM delivery_attempts WHERE shipment_id = ? ORDER BY attempt_no", id);
    }

    public List<Map<String, Object>> findAudit(int id) {
        return jdbc.queryForList(
            "SELECT old_status, new_status, DATE_FORMAT(changed_at, '%d %b %Y %H:%i:%s') AS changed_at " +
            "FROM status_audit WHERE shipment_id = ? ORDER BY audit_id", id);
    }

    public List<Map<String, Object>> findRtoCost(int id) {
        return jdbc.queryForList(
            "SELECT forward_cost, return_cost, lost_margin, " +
            "(forward_cost + return_cost + lost_margin) AS total_loss " +
            "FROM rto_costs WHERE shipment_id = ?", id);
    }

    // ---------- writes (always called inside a @Transactional service method) ----------

    // SELECT ... FOR UPDATE locks the row until the transaction ends,
    // so two users cannot log attempts on the same shipment at the same time.
    public ShipmentStatus lockStatus(int id) {
        String s = jdbc.queryForObject(
            "SELECT status FROM shipments WHERE shipment_id = ? FOR UPDATE", String.class, id);
        return ShipmentStatus.valueOf(s);
    }

    public void updateStatus(int id, ShipmentStatus status) {
        jdbc.update("UPDATE shipments SET status = ? WHERE shipment_id = ?", status.name(), id);
    }

    public int nextAttemptNo(int id) {
        Integer n = jdbc.queryForObject(
            "SELECT COALESCE(MAX(attempt_no), 0) + 1 FROM delivery_attempts WHERE shipment_id = ?",
            Integer.class, id);
        return n == null ? 1 : n;
    }

    public void insertAttempt(int id, int attemptNo, String timeSlot, String outcome, String reason) {
        jdbc.update(
            "INSERT INTO delivery_attempts " +
            "(shipment_id, attempt_no, attempt_time, time_slot, outcome, failure_reason, remarks) " +
            "VALUES (?, ?, NOW(), ?, ?, ?, JSON_OBJECT('logged_via', 'web'))",
            id, attemptNo, timeSlot, outcome, reason);
    }

    // Set-based insert: cost is computed inside the database from the shipment row
    public void insertRtoCost(int id) {
        jdbc.update(
            "INSERT INTO rto_costs (shipment_id, forward_cost, return_cost, lost_margin) " +
            "SELECT shipment_id, ROUND(40 + 12 * weight_kg, 2), " +
            "ROUND((40 + 12 * weight_kg) * 0.9, 2), ROUND(order_value * 0.25, 2) " +
            "FROM shipments WHERE shipment_id = ?", id);
    }

    public int insertShipment(String orderRef, int customerId, int courierId,
                              String paymentMode, BigDecimal value, BigDecimal weight) {
        KeyHolder keys = new GeneratedKeyHolder();
        jdbc.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                "INSERT INTO shipments (order_ref, customer_id, courier_id, payment_mode, order_value, weight_kg) " +
                "VALUES (?, ?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, orderRef);
            ps.setInt(2, customerId);
            ps.setInt(3, courierId);
            ps.setString(4, paymentMode);
            ps.setBigDecimal(5, value);
            ps.setBigDecimal(6, weight);
            return ps;
        }, keys);
        return keys.getKey().intValue();
    }
}