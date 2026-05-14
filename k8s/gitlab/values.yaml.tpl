global:
  hosts:
    domain: ${nlb_ip}.nip.io
    https: false

  ingress:
    enabled: true
    configureCertmanager: false
    tls:
      enabled: false
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"

  certmanager:
    install: false

  pdb:
    enabled: false

  minio:
    enabled: true

  registry:
    enabled: true

kas:
  enabled: false

gitlab-exporter:
  enabled: false

toolbox:
  enabled: false

prometheus:
  install: false

grafana:
  enabled: false

gitlab-runner:
  install: false

postgresql:
  primary:
    persistence:
      size: 2Gi
    resources:
      requests:
        cpu: 100m
        memory: 256Mi

redis:
  master:
    persistence:
      size: 512Mi
    resources:
      requests:
        cpu: 50m
        memory: 128Mi

  replica:
    replicaCount: 0

gitaly:
  persistence:
    size: 5Gi
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

minio:
  persistence:
    enabled: true
    size: 2Gi
  resources:
    requests:
      cpu: 50m
      memory: 128Mi

gitlab:
  kas:
    minReplicas: 1
    maxReplicas: 1
  registry:
    maxReplicas: 1
    minReplicas: 1
  gitlab-shell:
    maxReplicas: 1
    minReplicas: 1
  sidekiq:
    maxReplicas: 1
    minReplicas: 1
  webservice:
    maxReplicas: 1
    minReplicas: 1