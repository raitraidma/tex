package io.github.raitraidma.timeseries;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.TimeZone;

@SpringBootApplication
@EnableConfigurationProperties
@Configuration
public class TimeSeries {
  static {
    TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
  }

  public static void main(String[] args) {
    SpringApplication.run(TimeSeries.class, args);
  }

  @Bean
  public TimeSeriesService getTimeSeriesService(@Value("${time-series.cassandra.keyspace}") String keyspace,
                                                @Value("${time-series.cassandra.contact-points}") String contactPoints,
                                                @Value("${time-series.cassandra.port}") int port) {
    return new TimeSeriesService(keyspace, contactPoints.split(","), port);
  }
}
