kubectl create ns knative-eventing || true
cd ..
kubectl apply -f ./knative-eventing --validate=false

sleep 30
kubectl label namespace seldon-logs knative-eventing-injection=enabled --overwrite=true || true