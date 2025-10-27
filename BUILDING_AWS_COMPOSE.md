# Building and registering `aws-compose` image

Launch an [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/) EC2 instance with the following [user data script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-api-cli).

```sh
#!/bin/bash

yum install -y docker gcc git make lz4

# `ssm-user` does not exist at this stage, so add `ec2-user` to `docker` group.
usermod -aG docker ec2-user
systemctl start docker

# rust
su - ec2-user -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

su - ec2-user -c 'mkdir -p /home/ec2-user/bin'

# cargo-make
su - ec2-user -c 'curl -LO https://github.com/sagiegurari/cargo-make/releases/download/0.37.24/cargo-make-v0.37.24-x86_64-unknown-linux-musl.zip'
su - ec2-user -c 'unzip cargo-make-v0.37.24-x86_64-unknown-linux-musl.zip'
su - ec2-user -c 'mv cargo-make-v0.37.24-x86_64-unknown-linux-musl/cargo-make bin/'
su - ec2-user -c 'rm -rf cargo-make-v0.37.24-x86_64-unknown-linux-musl*'
```

Clone this repository and change directory to `bottlerocket-compose/`.

```shell
$ git clone https://github.com/rajivr/bottlerocket-compose.git
$ cd bottlerocket-compose/
```

Create an [`Infra.toml`](https://github.com/bottlerocket-os/bottlerocket/blob/v1.49.0/tools/pubsys/Infra.toml.example#L35-L38) file to specify the regions where you want `aws-compose` variant AMI to be published. For example, if you want your AMI to be available in `us-east-2` region, you would create the following `Infra.toml` file in `bottlerocket-compose/` directory.

```toml
[aws]
regions = ["us-east-2"]
```

Invoke `cargo make -e BUILDSYS_UPSTREAM_SOURCE_FALLBACK=true -e BUILDSYS_VARIANT=aws-compose` to build `aws-compose` variant.

**Note:** It is important to use `-e BUILDSYS_UPSTREAM_SOURCE_FALLBACK=true` flag. Otherwise, the build will fail.

```shell
$ cargo make -e BUILDSYS_UPSTREAM_SOURCE_FALLBACK=true -e BUILDSYS_VARIANT=aws-compose
[cargo-make] INFO - cargo make 0.37.24
[cargo-make] INFO -
[cargo-make] INFO - Build File: Makefile.toml
[cargo-make] INFO - Task: default
[cargo-make] INFO - Profile: development
[cargo-make] INFO - Running Task: install-twoliter
Installing Twoliter from binary release.
Checking binary checksum...
twoliter.tar.xz: OK
[cargo-make] INFO - Execute Command: "/home/ec2-user/bottlerocket-compose/tools/twoliter/twoliter" "--log-level=info" "fetch" "--project-path=/home/ec2-user/bottlerocket-compose/Twoliter.toml" "--arch=x86_64"

[...]

[cargo-make][1] INFO - Running Task: cargo-metadata
[cargo-make][1] INFO - Running Task: validate-kits
[cargo-make][1] INFO - Running Task: build-variant
   Compiling compose-containers v0.1.0 (/home/ec2-user/bottlerocket-compose/packages/compose-containers)
   Compiling settings-plugins v0.1.0 (/home/ec2-user/bottlerocket-compose/packages/settings-plugins)
   Compiling docker-compose v0.1.0 (/home/ec2-user/bottlerocket-compose/packages/docker-compose)
   Compiling settings-defaults v0.1.0 (/home/ec2-user/bottlerocket-compose/packages/settings-defaults)
   Compiling aws-compose v0.1.0 (/home/ec2-user/bottlerocket-compose/variants/aws-compose)
    Finished `dev` profile [optimized] target(s) in 3m 35s
[cargo-make][1] INFO - Build Done in 382.48 seconds.
[cargo-make] INFO - Build Done in 416.28 seconds.
```

Once the build completes, you can call `cargo make -e BUILDSYS_UPSTREAM_SOURCE_FALLBACK=true -e BUILDSYS_VARIANT=aws-compose ami` to publish the `aws-compose` variant AMI to your account.

```shell
$ cargo make -e BUILDSYS_UPSTREAM_SOURCE_FALLBACK=true -e BUILDSYS_VARIANT=aws-compose ami

[...]

12:17:35 [INFO] Using default amispec for AMI properties
12:17:35 [INFO] Registering 'bottlerocket-aws-compose-x86_64-v1.48.0-c7a277f' in us-east-2
12:17:35 [INFO] Registering 'root' snapshot in region 'us-east-2'
12:17:35 [INFO] Registering 'data' snapshot in region 'us-east-2'
12:17:52 [INFO] Using default amispec for AMI properties
12:17:52 [INFO] Making register image call in us-east-2
12:17:52 [INFO] Registered AMI 'bottlerocket-aws-compose-x86_64-v1.48.0-c7a277f' in us-east-2: ami-040f57013f362ec4c
12:17:52 [INFO] Wrote AMI data to /home/ec2-user/bottlerocket-compose/build/images/x86_64-aws-compose/1.48.0-c7a277f/bottlerocket-aws-compose-x86_64-1.48.0-c7a277f-amis.json
[cargo-make][1] INFO - Build Done in 18.71 seconds.
[cargo-make] INFO - Build Done in 19.70 seconds.
```

In the above example, an AMI with an ID of `ami-040f57013f362ec4c` was registered in your AWS account's `us-east-2` region.
