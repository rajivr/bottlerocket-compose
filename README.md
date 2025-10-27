# Bottlerocket OS (Docker) Compose Variant

This repository contains code to build and run [(Docker) Compose](https://github.com/docker/compose) [variant](https://bottlerocket.dev/en/os/1.47.x/concepts/variants/) of Bottlerocket.

If you are not familiar with Bottlerocket please visit the [official Bottlerocket website and documentation](https://bottlerocket.dev/) and its [GitHub](https://github.com/bottlerocket-os/bottlerocket/tree/develop) repository.

Bottlerocket (Docker) Compose variant provides an operating environment where you can get the [security features](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/README.md#security) of Bottlerocket to run parts of your containerized workloads that you specifically wish **not to have a dependency on an orchestrator** such as ECS or Kubernetes. For orchestrated workloads, you can use the Bottlerocket ECS and Bottlerocket EKS variants, thereby allowing you to standardize your production infrastructure on Bottlerocket OS.

Following are some use-cases where you may find it useful to use Bottlerocket (Docker) Compose variant:

* Access control infrastructure to VPCs.
* Deploying containerized stateful workloads without running into the [Kubernetes 300% problem](https://youtu.be/v4nLdCHk9ag?t=1203).
* Monitoring, logging, alerting parts of the infrastructure.
* Even applications, if it can be scaled vertically across many CPU cores and is amenable to deployment with simpler solutions such as OpenTofu with [native S3 locking](https://opentofu.org/docs/intro/whats-new/#native-s3-state-locking) and [encryption](https://opentofu.org/docs/language/state/encryption/).

## Setup

See upstream documentation [BUILDING](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/BUILDING.md) that describes:

* how to build an image
* how to register an EC2 AMI from an image

Before attempting to build `aws-compose` variant, ensure that you are able to successfully build (`cargo make -e BUILDSYS_VARIANT=aws-dev`), register (`cargo make -e BUILDSYS_VARIANT=aws-dev ami`) and launch an `aws-dev` variant AMI. `aws-dev` variant comes with [`docker`](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/variants/aws-dev/Cargo.toml#L30-L33), so please check that you are also able to `docker pull` container images after you do `sudo shelite` in the [admin container](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/README.md#admin-container). This will ensure that your EC2 instance has the required IAM permissions to pull the container images from the registry.

### Building and registering `aws-compose` image

Please see [BUILDING_AWS_COMPOSE](BUILDING_AWS_COMPOSE.md).

### Using `aws-compose` image

`aws-compose` variant supports running multiple compose applications.

The `compose.yml` file associated with the compose application should be present at `/local/compose-containers/<application_name>/compose.yml` on the host filesystem. To accomplish this, you can make use of [bootstrap containers](https://bottlerocket.dev/en/os/1.49.x/concepts/bootstrap-containers/) feature of Bottlerocket OS.

Once the `compose.yml` file is made available at `/local/compose-containers/<application_name>/compose.yml`, you can use Bottlerocket OS [settings](https://bottlerocket.dev/en/os/1.49.x/concepts/api-driven/#settings) feature to enable the compose application.

[`examples/compose-bootstrap-containers/`](examples/compose-bootstrap-containers/) directory contains an example. It has the following files.

```shell
$ tree --charset=ascii examples/compose-bootstrap-containers/
examples/compose-bootstrap-containers/
`-- nginx
    |-- Dockerfile
    |-- main.ab
    |-- main.sh
    `-- nginx
        `-- compose.yml

3 directories, 4 files
```

The file [`examples/compose-bootstrap-containers/nginx/main.ab`](examples/compose-bootstrap-containers/nginx/main.ab) is an [amber](https://amber-lang.com/) shell script.

```typescript
import { dir_exists, dir_create } from "std/fs"

main {
    const compose_directory = "/.bottlerocket/rootfs/local/compose-containers"

    // ensure that `/local/compose-containers` directory is present,
    // otherwise we might be using a non-compose variant of
    // bottlerocket.
    if not dir_exists(compose_directory) {
        exit 1
    }

    // create the required directory.
    if not dir_exists("{compose_directory}/nginx") {
        dir_create("{compose_directory}/nginx")
    }

    // copy the required files.
    $ cp nginx/compose.yml {compose_directory}/nginx $?

    exit 0
}
```

This script takes the file `nginx/compose.yml` that is present in the bootstrap container image and copies it over to `/.bottlerocket/rootfs/local/compose-containers/nginx/compose.yml`, thereby creating a file `/local/compose-containers/nginx/compose.yml` on Bottlerocket host filesystem.

**Note:** Amber script is used here only as an example. You can use any scripting language (or even natively compiled program). Also there is _no requirement_ that the `compose.yml` file be present in the bootstrap container filesystem. It can, for example be downloaded from an S3 bucket or a web server.

[`nginx/compose.yml`](examples/compose-bootstrap-containers/nginx/nginx/compose.yml) is a compose application that creates a nginx container.

```yaml
name: nginx
services:
  nginx:
    image: public.ecr.aws/nginx/nginx:alpine-slim
    ports:
      - "8080:80/tcp"
```

The [`Dockerfile`](examples/compose-bootstrap-containers/nginx/Dockerfile) used to build the bootstrap container is below. It copies the required files into the container image and sets the entrypoint.

```dockerfile
FROM public.ecr.aws/docker/library/bash:5.0-alpine3.22

WORKDIR /root

COPY nginx /root/nginx
COPY main.sh /root/main.sh

ENTRYPOINT ["/root/main.sh"]
```

Build, tag and push the bootstrap container image to the container registry.

```shell
$ cd examples/compose-bootstrap-containers/nginx/

# docker build --tag \
#   <account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest \
#   --file Dockerfile .

$ docker build --tag \
>   <account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest \
>   --file Dockerfile .
[+] Building 5.0s (10/10) FINISHED                        docker:default
 => [internal] load build definition from Dockerfile                0.0s
 => => transferring dockerfile: 189B                                0.0s
 => [internal] load metadata for public.ecr.aws/docker/library/bas  4.7s
 => [auth] aws:: docker/library/bash:pull token for public.ecr.aws  0.0s
 => [internal] load .dockerignore                                   0.1s
 => => transferring context: 2B                                     0.0s
 => [1/4] FROM public.ecr.aws/docker/library/bash:5.0-alpine3.22@s  0.0s
 => [internal] load build context                                   0.0s
 => => transferring context: 90B                                    0.0s
 => CACHED [2/4] WORKDIR /root                                      0.0s
 => CACHED [3/4] COPY nginx /root/nginx                             0.0s
 => CACHED [4/4] COPY main.sh /root/main.sh                         0.0s
 => exporting to image                                              0.0s
 => => exporting layers                                             0.0s
 => => writing image sha256:718e0e763225f82de9d4338067004ea4056a58  0.0s
 => => naming to <account>.dkr.ecr.us-east-2.amazonaws.com/<namesp  0.0s

# docker push \
#   <acccount>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest

$ docker push \
>   <account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest
The push refers to repository [<account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx]

[...]

256f393e029f: Layer already exists
latest: digest: sha256:15d0a3bb25810c2714102135b4cf3ef191bcbb7ac6a2acaf35b1f63add6c40b5 size: 1773
```

In the above example, the bootstrap container image is available at `<account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest`.

You can now use [TOML formatted `user-data`](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/README.md#using-user-data) to configure the settings. There are two settings that you need to setup.

* Bootstrap container settings
* Compose container settings

[Bootstrap container settings](https://bottlerocket.dev/en/os/1.49.x/api/settings/bootstrap-containers/) is available in all Bottlerocket variants. [Compose container settings](SETTINGS.md) is available only on `aws-compose` variant.

Following would be the bootstrap container settings.

```toml
[settings.bootstrap-containers.compose-bootstrap-nginx]
mode = "always"
source = "<account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest@sha256:15d0a3bb25810c2714102135b4cf3ef191bcbb7ac6a2acaf35b1f63add6c40b5"
essential = true
```

The above settings would let Bottlerocket OS pull and run the container image when the Bottlerocket `aws-compose` variant EC2 instance starts. Upon successful completion, a file `/local/compose-containers/nginx/compose.yml` would be placed on host filesystem.

Following would be the compose container settings.

```toml
[settings.compose-containers.nginx]
enabled = true
```

The above settings would start the the compose application specified at `/local/compose-containers/nginx/compose.yml`.

**Note** the correspondence between of `<application_name>` in the directory path `/local/compose-containers/<application_name>/compose.yml` and `[settings.compose-containers.<application_name>]` above. The `<application_name>` *must match* with the path to the `compose.yml` file. In this case the `<application_name>` is `nginx`.

Following would the complete `user-data.toml` file that you can use to launch Bottlerocket `aws-compose` variant EC2 instance.

```toml
[settings.bootstrap-containers.compose-bootstrap-nginx]
mode = "always"
source = "<account>.dkr.ecr.us-east-2.amazonaws.com/<namespace>/compose-bootstrap-nginx:latest@sha256:15d0a3bb25810c2714102135b4cf3ef191bcbb7ac6a2acaf35b1f63add6c40b5"
essential = true

[settings.compose-containers.nginx]
enabled = true
```

On the running EC2 instance, enter the host shell (by going `sudo sheltie`) in the admin container. You can do `docker-compose ls` to see `nginx` compose application.

```shell
[root@admin]# sudo sheltie

bash-5.1# docker-compose ls
NAME                STATUS              CONFIG FILES
nginx               running(1)          /local/compose-containers/nginx/compose.yml

bash-5.1# docker ps
CONTAINER ID   IMAGE                                    COMMAND                  CREATED         STATUS         PORTS                                   NAMES
1b56ee2ba640   public.ecr.aws/nginx/nginx:alpine-slim   "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   nginx-nginx-1
```

**Note:** Docker compose binary is invoked using `docker-compose` and _not_ `docker compose`.

You can also see that the launched docker container `nginx-nginx-1` is protected using [SELinux](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/SECURITY_FEATURES.md#selinux-enabled-in-enforcing-mode).

```shell
bash-5.1# docker container inspect nginx-nginx-1 | grep -e "MountLabel" -e "ProcessLabel"
        "MountLabel": "system_u:object_r:data_t:s0:c351,c386",
        "ProcessLabel": "system_u:system_r:container_t:s0:c351,c386",
```

The process label that is assigned to container `nginx` process is `system_u:system_r:container_t:s0:c351,c386`.

```shell
bash-5.1# ps -Zax | grep "c351,c386"
system_u:system_r:container_t:s0:c351,c386 1945 ? Ss    0:00 nginx: master process nginx -g daemon off;
system_u:system_r:container_t:s0:c351,c386 2011 ? S     0:00 nginx: worker process
```

The mount label that is assigned to container filesystem is `system_u:object_r:data_t:s0:c351,c386`.

```shell
bash-5.1# docker container inspect nginx-nginx-1 | grep -A 6 -e "GraphDriver"
        "GraphDriver": {
            "Data": {
                "LowerDir": "/var/lib/docker/overlay2/9d93a6e168aeaca68e10f2941a50dcbee4d84220b8cccac30df3061024f2c0a0-init/diff:/var/lib/docker/overlay2/f84aa7a2d7fa14f671bcce3c1b0847f0f6e0687ca17b6fdea2b2d64057b5f9a5/diff:/var/lib/docker/overlay2/bc583cbff0526d90d2f2d1fa4ba61d512e0ceec8e1d329ecb428976a0c2bb282/diff:/var/lib/docker/overlay2/34c487a0640653026c0ba016bfe017dd918b8fd21356696b00a89ec149a5692f/diff:/var/lib/docker/overlay2/9926d4e883f82e406c186222ab999a64d7cca5dde859c15300e16ad5e200da65/diff:/var/lib/docker/overlay2/89af0d1c14461d7b766b8adc980747ca95346916862dac9505445ccc31d0f30d/diff:/var/lib/docker/overlay2/9458a5d38a006dfcc7c0dd3a7484d5e1a63f4223893a501dc011a6dfb5ad9351/diff:/var/lib/docker/overlay2/711fe38a61e1d6cf49b2846fbb03840ae3c53b520968bd32acacae74edffbd15/diff",
                "MergedDir": "/var/lib/docker/overlay2/9d93a6e168aeaca68e10f2941a50dcbee4d84220b8cccac30df3061024f2c0a0/merged",
                "UpperDir": "/var/lib/docker/overlay2/9d93a6e168aeaca68e10f2941a50dcbee4d84220b8cccac30df3061024f2c0a0/diff",
                "WorkDir": "/var/lib/docker/overlay2/9d93a6e168aeaca68e10f2941a50dcbee4d84220b8cccac30df3061024f2c0a0/work"
            },

bash-5.1# ls -Z /var/lib/docker/overlay2/9d93a6e168aeaca68e10f2941a50dcbee4d84220b8cccac30df3061024f2c0a0/merged/
system_u:object_r:data_t:s0:c351,c386 bin
system_u:object_r:data_t:s0:c351,c386 dev
system_u:object_r:data_t:s0:c351,c386 docker-entrypoint.d
system_u:object_r:data_t:s0:c351,c386 docker-entrypoint.sh
system_u:object_r:data_t:s0:c351,c386 etc
system_u:object_r:data_t:s0:c351,c386 home
system_u:object_r:data_t:s0:c351,c386 lib
system_u:object_r:data_t:s0:c351,c386 media
system_u:object_r:data_t:s0:c351,c386 mnt
system_u:object_r:data_t:s0:c351,c386 opt
system_u:object_r:data_t:s0:c351,c386 proc
system_u:object_r:data_t:s0:c351,c386 root
system_u:object_r:data_t:s0:c351,c386 run
system_u:object_r:data_t:s0:c351,c386 sbin
system_u:object_r:data_t:s0:c351,c386 srv
system_u:object_r:data_t:s0:c351,c386 sys
system_u:object_r:data_t:s0:c351,c386 tmp
system_u:object_r:data_t:s0:c351,c386 usr
system_u:object_r:data_t:s0:c351,c386 var
```

**Congratulations!** you are now running a SELinux protected docker compose application using Bottlerocket `aws-compose` variant.
