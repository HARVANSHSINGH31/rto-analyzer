package com.rto.model;

import java.util.EnumSet;
import java.util.Set;

public enum ShipmentStatus {
    CREATED, SHIPPED, OUT_FOR_DELIVERY, ATTEMPT_FAILED, DELIVERED, RTO;

    // Transitions a user can trigger with a button.
    // DELIVERED, ATTEMPT_FAILED and RTO happen ONLY through a logged delivery attempt.
    public Set<ShipmentStatus> manualNext() {
        return switch (this) {
            case CREATED -> EnumSet.of(SHIPPED);
            case SHIPPED -> EnumSet.of(OUT_FOR_DELIVERY);
            case ATTEMPT_FAILED -> EnumSet.of(OUT_FOR_DELIVERY);
            default -> EnumSet.noneOf(ShipmentStatus.class);
        };
    }
}