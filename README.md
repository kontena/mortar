# Kontena Mortar

Kubernetes manifest shooter.

## Installation

Rubygems:

`$ gem install kontena-mortar`

Docker:

`$ docker pull quay.io/kontena/mortar:latest`

## Usage

### Configuration

By default mortar looks for if file `~/.kube/config` exists and uses it as the configuration. Configuration file path can be overridden with `KUBECONFIG` environment variable.

For CI/CD use mortar also understands following environment variables:

- `KUBE_SERVER`: kubernetes api server address, for example `https://10.10.10.10:6443`
- `KUBE_TOKEN`: service account token
- `KUBE_CA`: kubernetes CA certificate (base64 encoded)

### Deploying k8s yaml manifests

```
$ mortar <deployment-name> <src-folder>
```

### Docker image

You can use mortar in CI/CD pipelines (like Drone) via `quay.io/kontena/mortar:latest` image.

Example config for Drone:

```yaml
pipeline:
  deploy:
    image: quay.io/kontena/mortar:latest
    secrets: [ kube_token, kube_ca, kube_server ]
    commands:
      - mortar my-app k8s/

```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kontena/mortar.

## License

Copyright (c) 2018 Kontena, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.