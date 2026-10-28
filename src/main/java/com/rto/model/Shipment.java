package com.rto.model;

import java.math.BigDecimal;

public class Shipment {

    private int shipmentId;
    private String orderRef;
    private String customerName;
    private String city;
    private String courierName;
    private String paymentMode;
    private BigDecimal orderValue;
    private String status;
    private String createdAt;

    public Shipment() { }

    public int getShipmentId() { return shipmentId; }
    public void setShipmentId(int shipmentId) { this.shipmentId = shipmentId; }

    public String getOrderRef() { return orderRef; }
    public void setOrderRef(String orderRef) { this.orderRef = orderRef; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getCourierName() { return courierName; }
    public void setCourierName(String courierName) { this.courierName = courierName; }

    public String getPaymentMode() { return paymentMode; }
    public void setPaymentMode(String paymentMode) { this.paymentMode = paymentMode; }

    public BigDecimal getOrderValue() { return orderValue; }
    public void setOrderValue(BigDecimal orderValue) { this.orderValue = orderValue; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}