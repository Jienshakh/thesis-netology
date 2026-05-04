apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: atlantis
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: atlantis.${nlb_ip}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: atlantis
            port:
              number: 80