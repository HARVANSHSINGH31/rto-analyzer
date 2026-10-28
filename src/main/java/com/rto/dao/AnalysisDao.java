package com.rto.dao;

import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AnalysisDao {

    private final JdbcTemplate jdbc;

    public AnalysisDao(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT test_name, dimension, statistic, value FROM analysis_results ORDER BY id");
    }

    public String lastRun() {
        return jdbc.queryForObject(
            "SELECT DATE_FORMAT(MAX(run_at), '%d %b %Y %H:%i:%s') FROM analysis_results", String.class);
    }
}