kubectl create ns knative-serving || true
cd ..
kubectl apply -f ./knative-serving --validate=false
