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

# magic-wormhole
curl -LO https://github.com/magic-wormhole/magic-wormhole.rs/releases/download/0.7.6/magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz
tar zxvf magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz
mv wormhole-rs /usr/local/bin/
