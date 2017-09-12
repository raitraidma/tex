package io.github.raitraidma.timeseries;

import com.datastax.driver.core.*;

import java.io.Serializable;
import java.time.ZonedDateTime;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import static java.util.Arrays.asList;

public class TimeSeriesService {
  private String keyspace;
  private final String[] contactPoints;
  private final int port;
  private Cluster cluster;
  private Session session;
  private PreparedStatement addEvent;
  private PreparedStatement showEvents;

  public TimeSeriesService(String keyspace, String[] contactPoints, int port) {
    this.keyspace = keyspace;
    this.contactPoints = contactPoints;
    this.port = port;
    connect();
    createSchemaIfNotExists();
    prepareStatements();
  }

  private void connect() {
    cluster = Cluster.builder()
        .addContactPoints(contactPoints).withPort(port)
        .build();
    session = cluster.connect();
  }

  private void createSchemaIfNotExists() {
    session.execute(
        "CREATE KEYSPACE IF NOT EXISTS " + keyspace +
            " WITH replication = {'class':'SimpleStrategy', 'replication_factor':2};"
    );

    session.execute(
        "CREATE TABLE IF NOT EXISTS " + keyspace + ".event (" +
            "event_type text," +
            "device_id text," +
            "event_time timestamp," +
            "event_value text," +
            "PRIMARY KEY ((event_type, device_id), event_time)" +
            ") WITH CLUSTERING ORDER BY (event_time DESC);"
    );
  }

  private void prepareStatements() {
    addEvent = session.prepare("INSERT INTO " + keyspace + ".event (event_type, device_id, event_time, event_value) " +
        " VALUES (:event_type, :device_id, :event_time, :event_value)");

    showEvents = session.prepare("SELECT * FROM " + keyspace + ".event " +
        " WHERE event_type = :event_type AND device_id = :device_id");
  }

  public List<List<? extends Serializable>> getEvents(String eventType, String deviceId) {
    return session.execute(showEvents.bind()
        .setString("event_type", eventType)
        .setString("device_id", deviceId)
    ).all().stream()
        .map(event -> asList(event.getTimestamp("event_time"), event.getString("event_value")))
        .collect(Collectors.toList());
  }

  public boolean addEvent(String eventType, String deviceId, String eventValue) {
    return addEvent(eventType, deviceId, eventValue, ZonedDateTime.now());
  }

  public boolean addEvent(String eventType, String deviceId, String eventValue, ZonedDateTime eventTime) {
    BoundStatement boundStatement = addEvent.bind()
        .setString("event_type", eventType)
        .setString("device_id", deviceId)
        .setTimestamp("event_time", Date.from(eventTime.toInstant()))
        .setString("event_value", eventValue);
    return session.execute(boundStatement).wasApplied();
  }

  private void disconnect() {
    if (session != null) {
      session.close();
    }
    if (cluster != null) {
      cluster.close();
    }
  }
}
