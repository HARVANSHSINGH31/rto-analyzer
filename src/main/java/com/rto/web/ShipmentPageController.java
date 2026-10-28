package com.rto.web;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.rto.dao.ShipmentDao;

@Controller
public class ShipmentPageController {

    private final ShipmentDao dao;

    public ShipmentPageController(ShipmentDao dao) {
        this.dao = dao;
    }

    @GetMapping("/")
    public String home() {
        return "redirect:/shipments";
    }

    @GetMapping("/shipments")
    public String shipments(@RequestParam(required = false) String status,
                            @RequestParam(required = false) Integer courierId,
                            Model model) {
        model.addAttribute("shipments", dao.findShipments(status, courierId));
        model.addAttribute("couriers", dao.listCouriers());
        model.addAttribute("statuses", List.of("CREATED", "SHIPPED", "OUT_FOR_DELIVERY",
                                               "ATTEMPT_FAILED", "DELIVERED", "RTO"));
        model.addAttribute("selStatus", status);
        model.addAttribute("selCourier", courierId);
        return "shipments";
    }
}