<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head><title>Shipments | RTO Analyzer</title></head>
<body>
<%@ include file="common.jspf" %>
<main>
  <form method="get" action="/shipments" class="filters">
    <select name="status">
      <option value="">All statuses</option>
      <c:forEach var="st" items="${statuses}">
        <option value="${st}" ${st.name() == selStatus ? 'selected' : ''}>${st}</option>
      </c:forEach>
    </select>
    <select name="courierId">
      <option value="">All couriers</option>
      <c:forEach var="k" items="${couriers}">
        <option value="${k.courier_id}" ${k.courier_id == selCourier ? 'selected' : ''}>${k.name}</option>
      </c:forEach>
    </select>
    <button type="submit">Filter</button>
  </form>

  <p class="muted">Showing ${shipments.size()} most recent shipments. Click an order to manage it.</p>

  <table>
    <thead>
      <tr><th>Order</th><th>Customer</th><th>City</th><th>Courier</th>
          <th>Payment</th><th>Value (₹)</th><th>Status</th><th>Created</th></tr>
    </thead>
    <tbody>
      <c:forEach var="s" items="${shipments}">
        <tr>
          <td><a href="/shipments/${s.shipmentId}">${s.orderRef}</a></td>
          <td><c:out value="${s.customerName}"/></td>
          <td>${s.city}</td>
          <td>${s.courierName}</td>
          <td>${s.paymentMode}</td>
          <td>${s.orderValue}</td>
          <td><span class="badge ${s.status}">${s.status}</span></td>
          <td>${s.createdAt}</td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</main>
</body>
</html>