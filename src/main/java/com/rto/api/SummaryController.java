package com.rto.api;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.rto.dao.ShipmentDao;

@RestController
@RequestMapping("/api")
public class SummaryController {

    private final ShipmentDao dao;

    public SummaryController(ShipmentDao dao) {
        this.dao = dao;
    }

    @GetMapping("/summary")
    public List<Map<String, Object>> summary() {
        return dao.countByStatus();
    }
}