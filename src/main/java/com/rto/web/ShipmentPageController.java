package com.rto.web;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.rto.dao.ShipmentDao;
import com.rto.model.Shipment;
import com.rto.model.ShipmentStatus;
import com.rto.service.InvalidTransitionException;
import com.rto.service.ShipmentService;

@Controller
public class ShipmentPageController {

    private static final List<String> REASONS =
        List.of("CUSTOMER_UNAVAILABLE", "WRONG_ADDRESS", "REFUSED", "COD_NOT_READY");

    private final ShipmentDao dao;
    private final ShipmentService service;

    public ShipmentPageController(ShipmentDao dao, ShipmentService service) {
        this.dao = dao;
        this.service = service;
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
        model.addAttribute("statuses", List.of(ShipmentStatus.values()));
        model.addAttribute("selStatus", status);
        model.addAttribute("selCourier", courierId);
        return "shipments";
    }

    @GetMapping("/shipments/{id}")
    public String detail(@PathVariable int id, Model model) {
        Shipment s = dao.findById(id);
        ShipmentStatus st = ShipmentStatus.valueOf(s.getStatus());
        model.addAttribute("s", s);
        model.addAttribute("attempts", dao.findAttempts(id));
        model.addAttribute("audit", dao.findAudit(id));
        model.addAttribute("rtoCost", dao.findRtoCost(id));
        model.addAttribute("manualNext", st.manualNext());
        model.addAttribute("canAttempt", st == ShipmentStatus.OUT_FOR_DELIVERY);
        model.addAttribute("reasons", REASONS);
        return "detail";
    }

    @PostMapping("/shipments/{id}/advance")
    public String advance(@PathVariable int id, @RequestParam String target, RedirectAttributes ra) {
        try {
            service.advance(id, ShipmentStatus.valueOf(target));
            ra.addFlashAttribute("msg", "Moved to " + target);
        } catch (InvalidTransitionException | IllegalArgumentException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/shipments/" + id;
    }

    @PostMapping("/shipments/{id}/attempt")
    public String attempt(@PathVariable int id,
                          @RequestParam String timeSlot,
                          @RequestParam String outcome,
                          @RequestParam(required = false) String reason,
                          RedirectAttributes ra) {
        try {
            String result = service.logAttempt(id, timeSlot, "DELIVERED".equals(outcome), reason);
            ra.addFlashAttribute("msg", result);
        } catch (InvalidTransitionException e) {
            ra.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/shipments/" + id;
    }

    @GetMapping("/shipments/new")
    public String newForm(Model model) {
        model.addAttribute("couriers", dao.listCouriers());
        return "new";
    }

    @PostMapping("/shipments/new")
    public String create(@RequestParam int customerId,
                         @RequestParam int courierId,
                         @RequestParam String paymentMode,
                         @RequestParam BigDecimal orderValue,
                         @RequestParam BigDecimal weightKg,
                         RedirectAttributes ra) {
        try {
            int id = service.create(customerId, courierId, paymentMode, orderValue, weightKg);
            ra.addFlashAttribute("msg", "Shipment created");
            return "redirect:/shipments/" + id;
        } catch (DataAccessException e) {
            ra.addFlashAttribute("error",
                "Database rejected the shipment (check customer ID 1-1200 and value > 0)");
            return "redirect:/shipments/new";
        }
    }
}