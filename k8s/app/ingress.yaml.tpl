apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-test-app
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.${nlb_ip}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test-app
            port:
              number: 80