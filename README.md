# k3s-deploy
Deploy K3S in China

`Version: 0.0.23`

## Usage
``` bash
curl -sfL https://suanpan-public.oss-cn-shanghai.aliyuncs.com/k3s/deploy.sh | sh -
```

### Enable Nvidia Runtime
``` bash
export INSTALL_K3S_WITH_NVIDIA_RUNTIME=true
curl -sfL https://suanpan-public.oss-cn-shanghai.aliyuncs.com/k3s/deploy.sh | sh -
```
