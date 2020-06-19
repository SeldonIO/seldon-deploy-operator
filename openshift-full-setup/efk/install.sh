oc apply -f eo-namespace.yaml
oc apply -f clo-namespace.yaml
oc apply -f eo-og.yaml
oc apply -f eo-csc.yaml
oc apply -f eo-sub.yaml
oc apply -f eo-rbac.yaml
#oc get csv --all-namespaces
#oc project openshift-operators-redhat
oc apply -f clo-og.yaml
oc apply -f clo-sub.yaml
oc apply -f clo-instance.yaml
#oc get pods -n openshift-logging

oc create serviceaccount -n openshift-logging elasticseldon
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-logging:elasticseldon
JWT=$(oc serviceaccounts get-token -n openshift-logging elasticseldon)
echo -n $JWT > ./jwt-elastic.txt
kubectl create secret generic jwt-elastic -n seldon --from-file=./jwt-elastic.txt --dry-run -o yaml | kubectl apply -f -
kubectl create namespace seldon-logs || true
kubectl create secret generic jwt-elastic -n seldon-logs --from-file=./jwt-elastic.txt --dry-run -o yaml | kubectl apply -f -
