kubectl create namespace seldon-logs
kubectl label namespace seldon-logs knative-eventing-injection=enabled --overwrite=true
kubectl apply -f seldon-request-logger.yaml

JWT=$(oc serviceaccounts get-token -n openshift-logging elasticseldon)
echo -n $JWT > ./jwt-elastic.txt
kubectl create secret generic jwt-elastic -n seldon-logs --from-file=./jwt-elastic.txt --dry-run -o yaml | kubectl apply -f -
