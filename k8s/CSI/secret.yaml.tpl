apiVersion: v1
kind: Secret
metadata:
  name: yc-csi-sa-key
  namespace: kube-system
type: Opaque
data:
  sa-key.json: ${sa_key_json}