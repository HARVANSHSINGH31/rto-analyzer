<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html>
<head>
  <title>Analytics | RTO Analyzer</title>
  <style>
    .kpis { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
    .kpi .label { color: #6b7280; font-size: 13px; }
    .kpi .num { font-size: 28px; font-weight: 700; margin-top: 6px; }
    .charts { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .charts img { width: 100%; border-radius: 6px; }
    .insights li { margin: 8px 0; line-height: 1.45; }
    .topbar { display: flex; justify-content: space-between; align-items: center; }
  </style>
</head>
<body>
<%@ include file="common.jspf" %>
<main>
  <div class="topbar">
    <h2>Analytics <span class="muted">
      <c:if test="${not empty lastRun}">Last run: ${lastRun}</c:if></span></h2>
    <form method="post" action="/analytics/run">
      <button type="submit">Run R Analysis</button>
    </form>
  </div>

  <c:if test="${empty rows}">
    <div class="card"><p class="muted">No results yet. Click "Run R Analysis".</p></div>
  </c:if>

  <c:if test="${not empty rows}">
    <div class="kpis">
      <div class="card kpi"><div class="label">Overall RTO rate</div>
        <div class="num"><fmt:formatNumber value="${kpi['Descriptive|overall|rto_rate']}" type="percent" maxFractionDigits="1"/></div></div>
      <div class="card kpi"><div class="label">COD RTO rate</div>
        <div class="num"><fmt:formatNumber value="${kpi['CI for proportion (95%)|COD|rto_rate']}" type="percent" maxFractionDigits="1"/></div></div>
      <div class="card kpi"><div class="label">Prepaid RTO rate</div>
        <div class="num"><fmt:formatNumber value="${kpi['CI for proportion (95%)|PREPAID|rto_rate']}" type="percent" maxFractionDigits="1"/></div></div>
      <div class="card kpi"><div class="label">Total RTO loss</div>
        <div class="num">₹<fmt:formatNumber value="${kpi['Multiple linear regression|loss ~ weight + value|total_rto_loss_rs']}" maxFractionDigits="0"/></div></div>
    </div>

    <div class="card">
      <h3>Key insights</h3>
      <ul class="insights">
        <c:forEach var="i" items="${insights}"><li>${i}</li></c:forEach>
      </ul>
    </div>

    <div class="charts">
      <div class="card"><img src="/charts/rto_by_payment.png?v=${v}" alt="RTO by payment"></div>
      <div class="card"><img src="/charts/fail_by_courier.png?v=${v}" alt="Failure by courier"></div>
      <div class="card"><img src="/charts/fail_by_slot.png?v=${v}" alt="Failure by slot"></div>
      <div class="card"><img src="/charts/days_by_courier.png?v=${v}" alt="Days by courier"></div>
      <div class="card"><img src="/charts/regression_residuals.png?v=${v}" alt="Residuals"></div>
    </div>

    <div class="card">
      <h3>All statistical results (from R, stored in MySQL)</h3>
      <table>
        <tr><th>Test</th><th>Dimension</th><th>Statistic</th><th>Value</th></tr>
        <c:forEach var="r" items="${rows}">
          <tr><td>${r.test_name}</td><td>${r.dimension}</td><td>${r.statistic}</td>
              <td><fmt:formatNumber value="${r.value}" maxFractionDigits="4"/></td></tr>
        </c:forEach>
      </table>
    </div>
  </c:if>
</main>
</body>
</html>