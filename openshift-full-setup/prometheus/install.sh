cd ..
kubectl create ns seldon || true
kubectl apply -f ./prometheus --validate=false
