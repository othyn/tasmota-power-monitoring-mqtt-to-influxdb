# Tasmota Power Monitoring MQTT InfluxDB Exporter

A useful Docker image that subscribes to Tasmota MQTT topics and exports the attached data to InfluxDB, in both `linux/amd64` and `linux/arm64` flavours.

## Setting up InfluxDB

First we need to connect to the database, in which I'll be doing from a macOS host for this example. We need access to the `influx` binary on our local host to connect to the database on the remote host. This binary can easily be installed on macOS via [`brew`](https://brew.sh/), `brew install influxdb`. Running `which influx` should then yeild something like `/opt/homebrew/bin/influx`.

Next, we need to connect to the remote host InfluxDB host, in which can be done using the command:

```sh
# influx -host <ip or hostname> -port <port>
influx -host 10.40.0.40 -port 8086
# Connected to http://10.40.0.40:8086 version 1.8.4
# InfluxDB shell version: 1.10.0
# >
```

Next, we want to check the existing databases via the `SHOW DATABASES` command. The guide will continue assuming a `tasmota` database doesn't already exist.

To create the necessary database, run the `CREATE DATABASE tasmota` command and then enter the database using the `USE tasmota` command. I like to setup a retention policy on the data so that InfluxDB will auto rotate the data every 7 days.

To setup the custom retention policy, run the command `SHOW RETENTION POLICIES` which should show only one existing default `autogen` policy that gets automatically created along with the database. The following commands will setup an automatic retention policy of 7 days with a shard every day:

```sh
> CREATE RETENTION POLICY "one_week" ON "tasmota" DURATION 7d REPLICATION 1 SHARD DURATION 1d DEFAULT

> DROP RETENTION POLICY "autogen" ON "tasmota"
```

Now if we run `SHOW RETENTION POLICIES` again, the only retention policy should be the `one_week` one we created:

```sh
> SHOW RETENTION POLICIES
name     duration shardGroupDuration replicaN default
----     -------- ------------------ -------- -------
one_week 168h0m0s 24h0m0s            1        true
```

Finished! Enter the command `exit` to exit and return to your local host shell session.

## Setting up the container

There is an example [docker-compose.yml](docker-compose.yml) in the project root directory to get you started, customise to your setup as necessary.

The primary environment variables are as follows (commented out variables are optional, with the example showing their default values):

```sh
INFLUXDB_HOST=influxdb
INFLUXDB_DB=tasmota
# INFLUXDB_PORT=8086
INFLUXDB_USER=
INFLUXDB_PASSWORD=
# INFLUXDB_SSL=false
# INFLUXDB_NO_VERIFY_SSL=true

MQTT_HOST=mqtt
# MQTT_PORT=

BASE_TOPIC=tele/

# LOGLEVEL=INFO
# TIMEZONE=Z
```

**NOTE** this repo will tack on a `#` to the end of your `BASE_TOPIC` value to wildcard all topics within the given topic, so only use the parent topic with a trailing slash. For example, my plugs are by default in the `tele/*` topic namespace, things like `tele/downstairs-theatre`, so I set the environment to use `BASE_TOPIC: "tele/"` (docker-compose) (`BASE_TOPIC=tele/` (env)).

To find your `BASE_TOPIC` value, I found it easiest to use [MQTT Explorer](https://mqtt-explorer.com/). Plug in your MQTT server details and connect to it, then browse the available topics on the server to find the one you require.

If you are in the UK (Type G plugs) or Europe (Type E/F plugs), I highly recommend the Tasmota plugs from [LocalBytes](https://www.mylocalbytes.com/products/smart-plug-pm), they'll run you around £10-15 but are completely plug-and-play and have been rock solid for me, coming pre flashed with Tasmota.
