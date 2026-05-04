apiVersion: v1
kind: ConfigMap
metadata:
  name: yc-csi-config
  namespace: kube-system
data:
  folderId: ${folder_id}