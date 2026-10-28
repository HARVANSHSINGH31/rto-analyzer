package com.rto.web;

import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;

@Component
public class RequestTimingFilter implements Filter {

    private static final Logger log = LoggerFactory.getLogger(RequestTimingFilter.class);

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        long start = System.nanoTime();
        chain.doFilter(req, res);
        HttpServletRequest http = (HttpServletRequest) req;
        long ms = (System.nanoTime() - start) / 1_000_000;
        log.info("{} {} took {} ms", http.getMethod(), http.getRequestURI(), ms);
    }
}