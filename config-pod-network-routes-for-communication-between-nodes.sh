###### Provisioning Pod Network Routes
# 	Pods scheduled to a node receive an IP address from the node's Pod CIDR range. 
#	At this point pods can not communicate with other pods running on different nodes due to missing network routes.

#	Using following commands, we will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address


#	This command will dump following IP addresses for each K8s worker node -
#		<Internal network interface IP address> 	<Pod CIDR for that node>

for instance in k8s-worker-0 k8s-worker-1 k8s-worker-2; do
  gcloud compute instances describe  --zone us-west1-a ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done

#	Sample output -
#		10.240.0.20 	10.200.0.0/24
#		10.240.0.21 	10.200.1.0/24
#		10.240.0.22 	10.200.2.0/24


# 	Note: Before executing following commands (to add routes to reach each worker node), there are no such routes - 
#		shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$ gcloud compute routes list --filter "network: k8s-cluster-vpc"
#		NAME                            NETWORK          DEST_RANGE     NEXT_HOP                  PRIORITY
#		default-route-cf3ff9c090d3fdc1  k8s-cluster-vpc  0.0.0.0/0      default-internet-gateway  1000
#		default-route-d239316b08b5b7a6  k8s-cluster-vpc  10.240.0.0/24  k8s-cluster-vpc           1000
#		shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$

# AND 
#		shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$ gcloud compute routes list
#		NAME                            NETWORK          DEST_RANGE     NEXT_HOP                  PRIORITY
#		default-route-02b95106c55ddd64  default          10.174.0.0/20  default                   1000
#		default-route-0872209f393ea64c  default          10.172.0.0/20  default                   1000
#		default-route-2116faed12c1c7dc  default          10.170.0.0/20  default                   1000
#		default-route-430d314e537f70aa  default          10.146.0.0/20  default                   1000
#		default-route-6201ad98f532aca4  default          10.158.0.0/20  default                   1000
#		default-route-6bb3916d8dc647d6  default          10.154.0.0/20  default                   1000
#		default-route-73119adef7bea43f  default          10.140.0.0/20  default                   1000
#		default-route-7d5595377b02bd23  default          10.160.0.0/20  default                   1000
#		default-route-7e39baf8c07294ab  default          10.150.0.0/20  default                   1000
#		default-route-7e730bae11a1b83f  default          10.168.0.0/20  default                   1000
#		default-route-89b256e03f55de82  default          10.166.0.0/20  default                   1000
#		default-route-8e90e8f86b7942d4  default          10.164.0.0/20  default                   1000
#		default-route-b15d29735416acf7  default          10.152.0.0/20  default                   1000
#		default-route-b39ea1cc77703907  default          10.138.0.0/20  default                   1000
#		default-route-b8b724a15f3a52c9  default          10.162.0.0/20  default                   1000
#		default-route-bc76f50ebd26649d  default          10.180.0.0/20  default                   1000
#		default-route-bccd9be5f3ee1aff  default          10.148.0.0/20  default                   1000
#		default-route-cbc098281c37bbc2  default          10.178.0.0/20  default                   1000
#		default-route-cf3ff9c090d3fdc1  k8s-cluster-vpc  0.0.0.0/0      default-internet-gateway  1000
#		default-route-d239316b08b5b7a6  k8s-cluster-vpc  10.240.0.0/24  k8s-cluster-vpc           1000
#		default-route-dc1489a28b025358  default          10.142.0.0/20  default                   1000
#		default-route-e5d28b989b3bea87  default          10.132.0.0/20  default                   1000
#		default-route-ef7dbdc48874ee1e  default          0.0.0.0/0      default-internet-gateway  1000
#		default-route-f25477e24033d0a5  default          10.128.0.0/20  default                   1000
#		default-route-fd2ab42fab49322c  default          10.156.0.0/20  default                   1000
#		shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$

########## Next step -
#	On 'k8s-cluster-vpc' VPC network, create network routes for each worker instance:
# 		This command will add routes that tell - what is the next-hop to reach each worker node 
#		i.e. to reach <k8s-worker-X's POD CIDR IP address range> , the next-hop would be that k8s-worker-X's internal network interface IP address
#		Example : In 'k8s-cluster-vpc' VPC network, for destination range = 10.200.0.0/24  the next-hop is 10.240.0.20 
# Note: the IP addresses hard-coded in following cmds should match each worker node's internal network interface IP address and that node's POD CIDR range.
for i in 0 1 2; do
  gcloud compute routes create k8s-cluster-vpc-route-10-200-${i}-0-24 \
    --network k8s-cluster-vpc \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done

#	After adding above routes, you can see the routes to reach each worker node -
gcloud compute routes list --filter "network: k8s-cluster-vpc"
#		shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$ gcloud compute routes list --filter "network: k8s-cluster-vpc"
#		NAME                                 NETWORK          DEST_RANGE     NEXT_HOP                  PRIORITY
#		default-route-cf3ff9c090d3fdc1       k8s-cluster-vpc  0.0.0.0/0      default-internet-gateway  1000
#		default-route-d239316b08b5b7a6       k8s-cluster-vpc  10.240.0.0/24  k8s-cluster-vpc           1000
#		k8s-cluster-vpc-route-10-200-0-0-24  k8s-cluster-vpc  10.200.0.0/24  10.240.0.20               1000
#		k8s-cluster-vpc-route-10-200-1-0-24  k8s-cluster-vpc  10.200.1.0/24  10.240.0.21               1000
#		k8s-cluster-vpc-route-10-200-2-0-24  k8s-cluster-vpc  10.200.2.0/24  10.240.0.22               1000
#		shreyans_mulkutkar@cloudshell:~ (smulkutk-project-1)$

####### ---------------- End ----------------- #######
