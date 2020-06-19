kubectl create namespace istio-system || true
kubectl create namespace seldon || true
kubectl label namespace seldon seldon.restricted=false --overwrite=true

kubectl apply -f subscription.yaml || true
sleep 10
kubectl apply -f servicemeshcontrolplane.yaml --validate=false
sleep 40
kubectl apply -f memberroll.yaml --validate=false
