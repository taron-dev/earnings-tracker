package sk.taron.earningstracker;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class EarningsTrackerApplication {

	public static void main(String[] args) {
		SpringApplication.run(EarningsTrackerApplication.class, args);
	}

}
