<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head><title>${s.orderRef} | RTO Analyzer</title></head>
<body>
<%@ include file="common.jspf" %>
<main>
  <a href="/shipments" class="muted">&larr; All shipments</a>
  <h2>${s.orderRef} <span class="badge ${s.status}">${s.status}</span></h2>

  <div class="grid">
    <div class="card">
      <h3>Details</h3>
      <p><b>Customer:</b> <c:out value="${s.customerName}"/> (${s.city})</p>
      <p><b>Courier:</b> ${s.courierName}</p>
      <p><b>Payment:</b> ${s.paymentMode} &middot; ₹${s.orderValue}</p>
      <p><b>Created:</b> ${s.createdAt}</p>
    </div>

    <div class="card">
      <h3>Actions</h3>
      <c:forEach var="t" items="${manualNext}">
        <form method="post" action="/shipments/${s.shipmentId}/advance" style="display:inline">
          <input type="hidden" name="target" value="${t}">
          <button type="submit">Move to ${t}</button>
        </form>
      </c:forEach>

      <c:if test="${canAttempt}">
        <form method="post" action="/shipments/${s.shipmentId}/attempt" class="stack">
          <label>Time slot
            <select name="timeSlot">
              <option>MORNING</option>
              <option>AFTERNOON</option>
              <option>EVENING</option>
            </select>
          </label>
          <label>Outcome
            <select name="outcome" required>
              <option value="" selected disabled>Choose outcome</option>
              <option value="DELIVERED">Delivered</option>
              <option value="FAILED">Failed</option>
            </select>
          </label>
          <label>Failure reason (if failed)
            <select name="reason">
              <option value="">-</option>
              <c:forEach var="r" items="${reasons}"><option>${r}</option></c:forEach>
            </select>
          </label>
          <button type="submit">Log delivery attempt</button>
        </form>
      </c:if>

      <c:if test="${empty manualNext and not canAttempt}">
        <p class="muted">No actions available. ${s.status} is a final state.</p>
      </c:if>
    </div>
  </div>

  <div class="card">
    <h3>Delivery attempts</h3>
    <c:choose>
      <c:when test="${empty attempts}"><p class="muted">No attempts yet.</p></c:when>
      <c:otherwise>
        <table>
          <tr><th>#</th><th>Time</th><th>Slot</th><th>Outcome</th><th>Reason</th><th>Remarks (JSON)</th></tr>
          <c:forEach var="a" items="${attempts}">
            <tr>
              <td>${a.attempt_no}</td><td>${a.attempt_time}</td><td>${a.time_slot}</td>
              <td><span class="badge ${a.outcome}">${a.outcome}</span></td>
              <td>${a.failure_reason}</td><td><code>${a.remarks}</code></td>
            </tr>
          </c:forEach>
        </table>
      </c:otherwise>
    </c:choose>
  </div>

  <div class="card">
    <h3>Status audit trail <span class="muted">(written automatically by a MySQL trigger)</span></h3>
    <c:choose>
      <c:when test="${empty audit}"><p class="muted">No status changes recorded yet.</p></c:when>
      <c:otherwise>
        <table>
          <tr><th>From</th><th>To</th><th>Changed at</th></tr>
          <c:forEach var="x" items="${audit}">
            <tr><td>${x.old_status}</td><td>${x.new_status}</td><td>${x.changed_at}</td></tr>
          </c:forEach>
        </table>
      </c:otherwise>
    </c:choose>
  </div>

  <c:if test="${not empty rtoCost}">
    <div class="card">
      <h3>RTO cost breakdown (₹)</h3>
      <table>
        <tr><th>Forward shipping</th><th>Return shipping</th><th>Lost margin</th><th>Total loss</th></tr>
        <tr>
          <td>${rtoCost[0].forward_cost}</td><td>${rtoCost[0].return_cost}</td>
          <td>${rtoCost[0].lost_margin}</td><td><b>${rtoCost[0].total_loss}</b></td>
        </tr>
      </table>
    </div>
  </c:if>
</main>
</body>
</html>