kubectl create namespace seldon-system || true 
kubectl apply -f clusterserviceversion.yaml --validate=false
kubectl apply -f subscription.yaml --validate=false
#TODO: do this other way round - should be able to put something in the namespace to add it to member role
kubectl apply -f memberroll.yaml --validate=false
kubectl apply -f https://raw.githubusercontent.com/SeldonIO/seldon-core/c949408dfbb05a6310d540feae3c9c7676daa561/notebooks/resources/seldon-gateway.yaml
