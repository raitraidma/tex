package io.github.raitraidma.timeseries;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.Serializable;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;

import static org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME;

@RestController
@RequestMapping
public class TimeSeriesController {
  private TimeSeriesService timeSeriesService;

  @Autowired
  public TimeSeriesController(TimeSeriesService timeSeriesService) {
    this.timeSeriesService = timeSeriesService;
  }

  @RequestMapping(value = "/add")
  public Boolean add(@RequestParam("eventType") String eventType,
                     @RequestParam("deviceId") String deviceId,
                     @RequestParam("eventValue") String eventValue,
                     @RequestParam(value = "eventTime", required = false) @DateTimeFormat(iso = DATE_TIME) ZonedDateTime eventTime) {
    if (eventTime == null) {
      return timeSeriesService.addEvent(eventType, deviceId, eventValue);
    }
    return timeSeriesService.addEvent(eventType, deviceId, eventValue, eventTime);
  }

  @RequestMapping(value = "/get")
  public List<List<? extends Serializable>> get(@RequestParam("eventType") String eventType,
                                                @RequestParam("deviceId") String deviceId) {
    return timeSeriesService.getEvents(eventType, deviceId);
  }
}