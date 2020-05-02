# Google Cloud Deployment Manager
Google Cloud Deployment Manager allows you to specify all the resources needed for your application in a declarative format using yaml. 

https://cloud.google.com/deployment-manager

# Create a Deployment Manager deployment

In Cloud Shell:
```
export MY_ZONE=us-central1-a

export DEVSHELL_PROJECT_ID=<your GCP project-id>

# At the Cloud Shell prompt, download an editable Deployment Manager template:
gsutil cp gs://cloud-training/gcpfcoreinfra/mydeploy.yaml mydeploy.yaml

# Insert your Google Cloud Platform project ID into the file in place of the string PROJECT_ID using this command:
sed -i -e 's/PROJECT_ID/'$DEVSHELL_PROJECT_ID/ mydeploy.yaml

# Insert your assigned Google Cloud Platform zone into the file in place of the string ZONE using this command:
sed -i -e 's/ZONE/'$MY_ZONE/ mydeploy.yaml

gcloud config set project $DEVSHELL_PROJECT_ID

# Build a deployment from the template:
gcloud deployment-manager deployments create my-first-depl --config mydeploy.yaml
```

Update a Deployment Manager
```
student_03_9ebb4bd46576@cloudshell:~ (qwiklabs-gcp-03-4a28f5c3a460)$ cat mydeploy.yaml | grep value -B 1
      - key: startup-script
        value: "apt-get update"
student_03_9ebb4bd46576@cloudshell:~ (qwiklabs-gcp-03-4a28f5c3a460)$

# as an example, update the add "apt-get install nginx-light -y" to the startup script
student_03_9ebb4bd46576@cloudshell:~ (qwiklabs-gcp-03-4a28f5c3a460)$ vim mydeploy.yaml                               
student_03_9ebb4bd46576@cloudshell:~ (qwiklabs-gcp-03-4a28f5c3a460)$


student_03_9ebb4bd46576@cloudshell:~ (qwiklabs-gcp-03-4a28f5c3a460)$ cat mydeploy.yaml | grep value -B 1
      - key: startup-script
        value: "apt-get update; apt-get install nginx-light -y"
student_03_9ebb4bd46576@cloudshell:~ (qwiklabs-gcp-03-4a28f5c3a460)$

# Update your deployment manager
```

