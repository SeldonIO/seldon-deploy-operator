cd ..
kubectl create namespace istio-system || true
kubectl apply -f ./istio --validate=false

kubectl apply -f https://raw.githubusercontent.com/SeldonIO/seldon-core/c949408dfbb05a6310d540feae3c9c7676daa561/notebooks/resources/seldon-gateway.yaml

#kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "LoadBalancer"}}'
#no need to expose loadbalancer as it gets a Route and deploy is on the /seldon-deploy/ path of the host of that Route