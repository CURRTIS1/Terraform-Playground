# 450promgrafana layer

This creates a test ECS service, Prometheus ECS service and a Grafana ECS service using module:
prometheus_grafana

The test ECS service puts out metrics into the actuator that is picked up by Prometheus

### In order access Prometheus and Grafana

#### Prometheus
```
http://<public-ip>:9090
```

#### Grafana
```
http://<public-ip>:3000
```
##### Note: The user/password for Grafana upon first deployment is admin/admin