package com.rto.service;

import java.io.File;
import java.nio.charset.StandardCharsets;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class AnalysisService {

    public record RunResult(int exitCode, String output, long millis) { }

    @Value("${rto.rscript:Rscript}")
    private String rscript;

    // Java launches R as a separate OS process (ProcessBuilder),
    // R reads MySQL, writes results back to MySQL, and Java displays them.
    public RunResult run() throws Exception {
        long start = System.currentTimeMillis();
        ProcessBuilder pb = new ProcessBuilder(rscript, "r/analysis.R");
        pb.directory(new File(System.getProperty("user.dir")));
        pb.redirectErrorStream(true);
        Process process = pb.start();
        String out = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        int code = process.waitFor();
        return new RunResult(code, out, System.currentTimeMillis() - start);
    }
}