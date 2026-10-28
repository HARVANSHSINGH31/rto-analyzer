package com.rto.service;

import java.math.BigDecimal;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.rto.dao.ShipmentDao;
import com.rto.model.ShipmentStatus;

@Service
public class ShipmentService {

    public static final int MAX_ATTEMPTS = 3;

    private final ShipmentDao dao;

    public ShipmentService(ShipmentDao dao) {
        this.dao = dao;
    }

    @Transactional
    public void advance(int shipmentId, ShipmentStatus target) {
        ShipmentStatus current = dao.lockStatus(shipmentId);
        if (!current.manualNext().contains(target)) {
            throw new InvalidTransitionException(
                "Illegal transition: " + current + " -> " + target);
        }
        dao.updateStatus(shipmentId, target);
    }

    // All steps commit together or roll back together (atomicity)
    @Transactional
    public String logAttempt(int shipmentId, String timeSlot, boolean delivered, String reason) {
        ShipmentStatus current = dao.lockStatus(shipmentId);
        if (current != ShipmentStatus.OUT_FOR_DELIVERY) {
            throw new InvalidTransitionException(
                "Attempts can only be logged when OUT_FOR_DELIVERY (current: " + current + ")");
        }
        if (!delivered && (reason == null || reason.isBlank())) {
            throw new InvalidTransitionException("Select a failure reason for a failed attempt");
        }

        int attemptNo = dao.nextAttemptNo(shipmentId);
        dao.insertAttempt(shipmentId, attemptNo, timeSlot,
                          delivered ? "DELIVERED" : "FAILED",
                          delivered ? null : reason);

        ShipmentStatus next;
        if (delivered) {
            next = ShipmentStatus.DELIVERED;
        } else if (attemptNo >= MAX_ATTEMPTS) {
            next = ShipmentStatus.RTO;
            dao.insertRtoCost(shipmentId);
        } else {
            next = ShipmentStatus.ATTEMPT_FAILED;
        }
        dao.updateStatus(shipmentId, next);
        return "Attempt " + attemptNo + " logged. Status is now " + next;
    }

    @Transactional
    public int create(int customerId, int courierId, String paymentMode,
                      BigDecimal value, BigDecimal weight) {
        String orderRef = "WEB" + System.currentTimeMillis();
        return dao.insertShipment(orderRef, customerId, courierId, paymentMode, value, weight);
    }
}