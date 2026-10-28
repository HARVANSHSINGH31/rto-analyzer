package com.rto.dao;

import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

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
}