#!/bin/bash

kafka-topics --create --if-not-exists \
  --topic reporte-registrado \
  --bootstrap-server kafka:9092 \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create --if-not-exists \
  --topic matches-detectados \
  --bootstrap-server kafka:9092 \
  --partitions 3 \
  --replication-factor 1

kafka-topics --create --if-not-exists \
  --topic new-messages \
  --bootstrap-server kafka:9092 \
  --partitions 3 \
  --replication-factor 1