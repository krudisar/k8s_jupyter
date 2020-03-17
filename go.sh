#
K8S_DEPLOYMENT_NAME="nvidia-jupyter"
K8S_SELECTOR="run=nvidia-jupyter"
#
SVC_NAME="nvidia-jupyter"
SVC_SVC_EXTERNAL_IP=""

# create a deployment && wait till it's finished
#
kubectl apply -f nvidia-jupyter-deployment.yml
kubectl wait --for=condition=available --timeout=600s deployments/$K8S_DEPLOYMENT_NAME

sleep 30

# get corresponding pod && check if it's ready as well (... just for sure)
#
K8S_POD_NAME=$(kubectl get pods -l $K8S_SELECTOR -o json | jq -r '[.items[] | {name:.metadata.name}]' | awk '{print $2}' | tr -d \")
kubectl wait --for=condition=ready --timeout=600s pods $K8S_POD_NAME

# extract Jupyter Notebook access token from K8S pod's logs
#
LINE_WITH_TOKEN=$(kubectl logs $K8S_POD_NAME | grep "token=" -m 1)
TEMP_LINE=`echo $LINE_WITH_TOKEN 2>&1 | grep -o "token=[a-z0-9]*" | sed -n 1p`
JUPYTER_TOKEN=`echo $TEMP_LINE | cut -d'=' -f 2`

# and now it's time to expose the deployment to be accessible by end users
#
kubectl apply -f nvidia-jupyter-service.yml
# ... wait till the service gets External-IP

while [ "$SVC_EXTERNAL_IP" = "" ]; do
    SVC_EXTERNAL_IP=$(kubectl get svc $SVC_NAME --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}");
    sleep 10;
done; # -> we got our IP address

# ... and now we can share the IP and token with end users
#
#echo $SVC_EXTERNAL_IP
#echo $JUPYTER_TOKEN
#
echo "Jupyter Notebok URL: http://$SVC_EXTERNAL_IP:8888/?token=$JUPYTER_TOKEN"
