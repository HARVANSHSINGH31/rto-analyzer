<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head><title>New Shipment | RTO Analyzer</title></head>
<body>
<%@ include file="common.jspf" %>
<main>
  <div class="card">
    <h3>Create shipment</h3>
    <form method="post" action="/shipments/new" class="stack">
      <label>Customer ID (1-1200)
        <input type="number" name="customerId" min="1" required>
      </label>
      <label>Courier
        <select name="courierId">
          <c:forEach var="k" items="${couriers}">
            <option value="${k.courier_id}">${k.name}</option>
          </c:forEach>
        </select>
      </label>
      <label>Payment mode
        <select name="paymentMode"><option>COD</option><option>PREPAID</option></select>
      </label>
      <label>Order value (₹)
        <input type="number" name="orderValue" step="0.01" min="0.01" required>
      </label>
      <label>Weight (kg)
        <input type="number" name="weightKg" step="0.01" min="0.01" required>
      </label>
      <button type="submit">Create shipment</button>
    </form>
  </div>
</main>
</body>
</html>