#!/bin/bash

set -e

VERSION=$(cat version.txt | sed "s/+/-/g")

ossutil cp deployments/ "oss://suanpan-public/k3s/${VERSION}/deployments/" -rf
ossutil cp tools/deploy.sh "oss://suanpan-public/k3s/deploy.sh" -f
ossutil cp version.txt "oss://suanpan-public/suanpan-rocket/version.txt" -f
