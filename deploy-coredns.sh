############## Deploying the DNS Cluster Add-on
#	deploy the DNS add-on which provides DNS based service discovery, backed by CoreDNS, to applications running inside the Kubernetes cluster.


#	Deploy the coredns cluster add-on:
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

#	List the pods created by the kube-dns deployment:
kubectl get pods -l k8s-app=kube-dns -n kube-system

#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$ kubectl get pods -l k8s-app=kube-dns -n kube-system
#	NAME                     READY   STATUS    RESTARTS   AGE
#	coredns-5fb99965-8hlzc   1/1     Running   0          28s
#	coredns-5fb99965-bg8pc   1/1     Running   0          28s
#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$

#### Verify if coreDNS is working fine -

##	Step-1: Create a busybox deployment:
kubectl run --generator=run-pod/v1 busybox --image=busybox:1.28 --command -- sleep 3600

#		List the pod created by the busybox deployment:
kubectl get pods -l run=busybox

#		Retrieve the full name of the busybox pod:
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
echo $POD_NAME


##	Step-2: Execute a DNS lookup for the 'kubernetes' service inside the 'busybox' pod:
#		Synatx: kubectl exec -ti $POD_NAME -- nslookup [HOST] [SERVER]

kubectl exec -ti $POD_NAME -- nslookup kubernetes
#	The IP address for 'kubernetes' service returned by BUSYBOX Pod is same as what you can see in 'kubectl get svc'

#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$ kubectl exec -ti $POD_NAME -- nslookup kubernetes
#	Server:    10.32.0.10
#	Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local
#	
#	Name:      kubernetes
#	Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$

#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$ kubectl get svc
#	NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
#	kubernetes   ClusterIP   10.32.0.1    <none>        443/TCP   12h
#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$

###### -------- End -------------- ###########
