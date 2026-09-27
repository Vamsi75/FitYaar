package com.fityaar;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication(scanBasePackages = "com.fityaar")
@EnableJpaAuditing
public class FitYaarApplication {

	public static void main(String[] args) {
		SpringApplication.run(FitYaarApplication.class, args);
	}

}

