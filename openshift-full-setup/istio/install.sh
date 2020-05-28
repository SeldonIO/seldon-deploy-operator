cd ..
kubectl create namespace istio-system || true
kubectl apply -f ./istio --validate=false

kubectl apply -f https://raw.githubusercontent.com/SeldonIO/seldon-core/c949408dfbb05a6310d540feae3c9c7676daa561/notebooks/resources/seldon-gateway.yaml

kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "LoadBalancer"}}'
#really deploy should be on /seldon-deploy/ path of oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}'
#am avoiding that for now as it would require more code changes in deploy
