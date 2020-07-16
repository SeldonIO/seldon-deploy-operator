cd ..
kubectl create ns seldon || true
kubectl apply -f ./prometheus-community-operator --validate=false
