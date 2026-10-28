package com.rto.dao;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import com.rto.model.Shipment;

@Repository
public class ShipmentDao {

    private final JdbcTemplate jdbc;

    public ShipmentDao(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> countByStatus() {
        return jdbc.queryForList(
            "SELECT status, COUNT(*) AS total FROM shipments GROUP BY status ORDER BY total DESC");
    }

    public List<Map<String, Object>> listCouriers() {
        return jdbc.queryForList("SELECT courier_id, name FROM couriers ORDER BY name");
    }

    // Parameterized query: user input never gets concatenated into SQL (prevents SQL injection)
    public List<Shipment> findShipments(String status, Integer courierId) {
        StringBuilder sql = new StringBuilder(
            "SELECT s.shipment_id, s.order_ref, c.name AS customer_name, c.city, " +
            "k.name AS courier_name, s.payment_mode, s.order_value, s.status, " +
            "DATE_FORMAT(s.created_at, '%d %b %Y %H:%i') AS created_at " +
            "FROM shipments s " +
            "JOIN customers c ON c.customer_id = s.customer_id " +
            "JOIN couriers k ON k.courier_id = s.courier_id " +
            "WHERE 1=1");
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

        return jdbc.query(sql.toString(), (rs, rowNum) -> {
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
        }, params.toArray());
    }
}