######### Smoke Tests -

# These commands can be executed from individual k8s master node -OR- 
#	from outside of cluster i.e. home of Google Cloud shell which was configured to have kubelet remote access. (Check - 'config-kubelet-for-remote-access.sh' file)

#	Create a deployment for the nginx web server:
kubectl create deployment nginx --image=nginx

#	List the pod created by the nginx deployment:
kubectl get pods -l app=nginx -o wide

#	shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$ kubectl get deployment
#	NAME    READY   UP-TO-DATE   AVAILABLE   AGE
#	nginx   1/1     1            1           48s
#	shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$

#	shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$ kubectl get pods -l app=nginx -o wide
#	NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
#	nginx-554b9c67f9-45ws2   1/1     Running   0          12s   10.200.2.3   k8s-worker-2   <none>           <none>
#	shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$
