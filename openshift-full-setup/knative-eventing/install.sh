kubectl create ns knative-eventing || true
cd ..
kubectl apply -f ./knative-eventing --validate=false
