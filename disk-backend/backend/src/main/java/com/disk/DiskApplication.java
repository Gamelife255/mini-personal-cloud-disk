package com.disk;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class DiskApplication {
    public static void main(String[] args) {
        SpringApplication.run(DiskApplication.class, args);
    }
}
