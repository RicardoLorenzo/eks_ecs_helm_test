# EKS/ECR terraform+helm definition

Please provision the EKS cluster by executing the following:

```bash
cd scripts
bash docker_build
bash push_docker_image_to_ecr.sh
bash install.sh
```
