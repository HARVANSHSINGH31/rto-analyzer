package com.rto.web;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.rto.dao.AnalysisDao;
import com.rto.service.AnalysisService;

@Controller
public class AnalyticsController {

    private final AnalysisDao dao;
    private final AnalysisService analysis;

    public AnalyticsController(AnalysisDao dao, AnalysisService analysis) {
        this.dao = dao;
        this.analysis = analysis;
    }

    @GetMapping("/analytics")
    public String analytics(Model model) {
        List<Map<String, Object>> rows = dao.findAll();
        Map<String, Double> kpi = new HashMap<>();
        String worstCourier = "-", worstSlot = "-", slowCourier = "-";
        double worstCourierRate = -1, worstSlotRate = -1, slowDays = -1;

        for (Map<String, Object> r : rows) {
            String test = (String) r.get("test_name");
            String dim = (String) r.get("dimension");
            double v = ((Number) r.get("value")).doubleValue();
            kpi.put(test + "|" + dim + "|" + r.get("statistic"), v);

            if (test.equals("Failure rate by courier") && v > worstCourierRate) { worstCourierRate = v; worstCourier = dim; }
            if (test.equals("Failure rate by time slot") && v > worstSlotRate) { worstSlotRate = v; worstSlot = dim; }
            if (test.equals("Mean days to 1st attempt") && v > slowDays) { slowDays = v; slowCourier = dim; }
        }

        List<String> insights = new ArrayList<>();
        if (!rows.isEmpty()) {
            double cod = kpi.getOrDefault("CI for proportion (95%)|COD|rto_rate", 0.0);
            double pre = kpi.getOrDefault("CI for proportion (95%)|PREPAID|rto_rate", 0.0);
            double pPay = kpi.getOrDefault("Two-sample proportion test|COD vs PREPAID|p_value", 1.0);
            insights.add(String.format("COD orders return %.1f%% of the time vs %.1f%% for prepaid. %s",
                cod * 100, pre * 100, pPay < 0.05 ? "Statistically significant (p < 0.05)." : "Not significant."));

            insights.add(String.format("%s has the highest attempt failure rate (%.1f%%), and the %s slot is the worst (%.1f%%).",
                worstCourier, worstCourierRate * 100, worstSlot, worstSlotRate * 100));

            double obs = kpi.getOrDefault("Binomial|independence check|observed_rto_rate", 0.0);
            double exp = kpi.getOrDefault("Binomial|independence check|expected_rto_rate", 0.0);
            insights.add(String.format("Observed RTO rate %.1f%% vs %.1f%% expected if attempts were independent: "
                + "failures cluster on the same customers, so verify the address after the first failure.",
                obs * 100, exp * 100));

            double fAov = kpi.getOrDefault("ANOVA|days to 1st attempt ~ courier|F", 0.0);
            insights.add(String.format("Couriers differ in speed (ANOVA F = %.1f). Slowest: %s at %.1f days to first attempt.",
                fAov, slowCourier, slowDays));

            double perKg = kpi.getOrDefault("Multiple linear regression|loss ~ weight + value|coef_weight_kg", 0.0);
            double perVal = kpi.getOrDefault("Multiple linear regression|loss ~ weight + value|coef_order_value", 0.0);
            insights.add(String.format("Each extra kg adds about Rs %.0f to RTO loss; each Rs 100 of order value adds about Rs %.0f.",
                perKg, perVal * 100));
        }

        model.addAttribute("rows", rows);
        model.addAttribute("kpi", kpi);
        model.addAttribute("insights", insights);
        model.addAttribute("lastRun", rows.isEmpty() ? null : dao.lastRun());
        model.addAttribute("v", System.currentTimeMillis()); // cache-buster for chart images
        return "analytics";
    }

    @PostMapping("/analytics/run")
    public String run(RedirectAttributes ra) {
        try {
            AnalysisService.RunResult r = analysis.run();
            if (r.exitCode() == 0) {
                ra.addFlashAttribute("msg", "R analysis finished in " + r.millis() / 1000.0 + " s");
            } else {
                String out = r.output();
                ra.addFlashAttribute("error", "R failed (exit " + r.exitCode() + "): "
                    + out.substring(Math.max(0, out.length() - 400)));
            }
        } catch (Exception e) {
            ra.addFlashAttribute("error", "Could not start Rscript: " + e.getMessage());
        }
        return "redirect:/analytics";
    }
}