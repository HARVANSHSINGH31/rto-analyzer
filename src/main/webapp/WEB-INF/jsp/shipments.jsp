<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
  <title>Shipments | RTO Analyzer</title>
  <style>
    body { font-family: -apple-system, Segoe UI, sans-serif; margin: 0; background: #f5f6f8; color: #1d2330; }
    header { background: #1d2330; color: #fff; padding: 14px 28px; display: flex; gap: 28px; align-items: center; }
    header h1 { font-size: 20px; margin: 0; }
    header a { color: #cfd6e4; text-decoration: none; }
    main { padding: 24px 28px; }
    .filters { display: flex; gap: 10px; margin-bottom: 12px; }
    select, button { padding: 8px 10px; border-radius: 6px; border: 1px solid #c7ccd6; font-size: 14px; }
    button { background: #2f6fed; color: #fff; border: none; cursor: pointer; }
    .muted { color: #6b7280; font-size: 13px; }
    table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; }
    th, td { padding: 10px 12px; text-align: left; font-size: 14px; border-bottom: 1px solid #eceef2; }
    th { background: #eef1f6; }
    .badge { padding: 3px 8px; border-radius: 10px; font-size: 12px; font-weight: 600; background: #e5e7eb; }
    .DELIVERED { background: #d1fae5; color: #065f46; }
    .RTO { background: #fee2e2; color: #991b1b; }
    .ATTEMPT_FAILED { background: #fef3c7; color: #92400e; }
    .OUT_FOR_DELIVERY { background: #dbeafe; color: #1e40af; }
  </style>
</head>
<body>
<header>
  <h1>RTO Analyzer</h1>
  <a href="/shipments">Shipments</a>
</header>
<main>
  <form method="get" action="/shipments" class="filters">
    <select name="status">
      <option value="">All statuses</option>
      <c:forEach var="st" items="${statuses}">
        <option value="${st}" ${st == selStatus ? 'selected' : ''}>${st}</option>
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

  <p class="muted">Showing ${shipments.size()} most recent shipments</p>

  <table>
    <thead>
      <tr><th>Order</th><th>Customer</th><th>City</th><th>Courier</th>
          <th>Payment</th><th>Value (₹)</th><th>Status</th><th>Created</th></tr>
    </thead>
    <tbody>
      <c:forEach var="s" items="${shipments}">
        <tr>
          <td>${s.orderRef}</td>
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