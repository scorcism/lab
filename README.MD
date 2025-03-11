# HomeLab Setup Scripts - WIP

## Quick Setup  

Run the following command to set up everything:  

```sh
./setup.sh
```  

## Features  

### 1. Local File Server (Nextcloud)  
Set up a self-hosted file server with Nextcloud:  

```sh
docker-compose -f nextcloud-docker-compose.yml up -d --build
```  

### 2. Real-Time System Monitoring (Netdata)  
Lightweight and easy-to-use monitoring tool:  

```sh
./netdata.sh
```  

### 3. Automated S3 Backup  
Sync Nextcloud data to AWS S3:  

```sh
./sync-s3.sh
``` 