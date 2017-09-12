# Cassandra
Simple time-series project to Demonstrate cassandra.

## Environment setup
```sh
vagrant up
```

### Connection parameters
- Host: 127.0.0.1
- Port: 2222
- Username: vagrant
- Password: vagrant


## Docker container
https://hub.docker.com/_/cassandra/


### Important environmental variables
- `CASSANDRA_BROADCAST_ADDRESS` - This variable is for controlling which IP address to advertise to other nodes.
- `CASSANDRA_SEEDS` - This variable is the comma-separated list of IP addresses used by gossip for bootstrapping new nodes joining a cluster.
- `CASSANDRA_CLUSTER_NAME` - This variable sets the name of the cluster and must be the same for all nodes in the cluster.
- `MAX_HEAP_SIZE`
- `HEAP_NEWSIZE`


### Build demo application and run cassandra in cluster
- Connect to vagrant machine
- `cd /vagrant/cassandrademo`
- `mvn clean package docker:build`
- `cd /vagrant`
- `./deploy-services.sh`


## Demo application

### Example queries
Run from host machine

#### Add
- http://localhost:8000/timeseries/add?eventType=demo&deviceId=666&eventValue=1
- http://localhost:8000/timeseries/add?eventType=demo&deviceId=666&eventValue=2&eventTime=2017-09-10T00:55:59Z
- http://localhost:8000/timeseries/add?eventType=demo&deviceId=666&eventValue=3&eventTime=2017-09-10T00:55:59.000Z
- http://localhost:8000/timeseries/add?eventType=demo&deviceId=666&eventValue=4&eventTime=2017-09-10T00:55:59.000%2B03:00

Create 100 events for 10 devices:
```sh
curl -XGET -s "http://localhost:8000/timeseries/add?eventType=demo&deviceId=[1-10]&eventValue=[1-100]"
```

#### Get device events
http://localhost:8000/timeseries/get?eventType=demo&deviceId=666

## How Cassandra works

### Architecture
Client read or write requests can be sent to any node in the cluster because all nodes in Cassandra are peers. When a client connects to a node and issues a read or write request, that node serves as the coordinator for that particular client operation.

### Data model
- Model around your queries (you must know your queries in advance)
    - Determine What Queries to Support
    - Try to create a table where you can satisfy your query by reading (roughly) one partition
- No JOINs
- To get the most efficient reads, you often need to duplicate data.
    - Writes are cheaper than reads

### Keyspace
- Top-level namespace (schema)
- Sets replica placement strategy
    - SimpleStrategy: Use only for a single data center and one rack
        - Places the first replica on a node determined by the partitioner
        - Additional replicas are placed on the next nodes clockwise in the ring without considering topology
    - NetworkTopologyStrategy: When you plan to have your cluster deployed across multiple datacenters
        - Places replicas in the same data center by walking the ring clockwise until reaching the first node in another rack
- Sets replication factor

```cql
CREATE KEYSPACE xxx WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };
```

### Primary key
- Spread Data Evenly Around the Cluster (hash of the partition key)
- Minimize the Number of Partitions Read
    - Partitions are groups of rows that share the same partition key
    - Each partition may reside on a different node
- Queries based on primary key are very fast.
- A compound primary key includes the partition key and one or more clustering columns
    - Partition key determines on which node data is stored
    - Clustering column specifies the order that the data is arranged inside the partition
- If you have too much data in a partition and want to spread the data over multiple nodes, use a composite partition key

```cql
CREATE TABLE xxx (
  ...
  PRIMARY KEY ((partition_key_part_1, partition_key_part_2), clustering_column_1, clustering_column_2)
);
```

If we want to control the sort order as a default of the data model, we can specify that at table creation time using the `CLUSTERING ORDER BY` clause:

```cql
CREATE TABLE xxx (
   ...
) WITH CLUSTERING ORDER BY (clustering_column_1 DESC, clustering_column_2 ASC);
```

### Materialized Views
- New in Cassandra 3.0
- Handle automated server-side denormalization
- Only simple SELECT statements are supported
- The columns of the source table's primary key must be part of the materialized view's primary key
- Only one new column can be added to the materialized view's primary key

### Indexing
- Provides a means to access data in Cassandra using attributes other than the partition key.
- When you attempt a potentially expensive query, such as searching a range of rows, Cassandra requires the `ALLOW FILTERING` directive.

```cql
CREATE INDEX xxx ON table_name( column_name );
```
## Alternatives to Cassandra
- [Scylla](http://www.scylladb.com/)