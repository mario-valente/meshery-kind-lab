# meshery-kind-lab

Laboratório local do [Meshery](https://docs.meshery.io) gerenciando **dois clusters kind**.

| Cluster | Papel |
|---|---|
| `kind-meshery-a` | Roda o Meshery (Helm, `PROVIDER=None`, UI em NodePort 30081 → `localhost:9081`) + app demo |
| `kind-meshery-b` | Cluster gerenciado remotamente + app demo |

Os dois clusters estão na rede docker `kind`, então o pod do Meshery alcança
`meshery-b-control-plane:6443`. Por isso o kubeconfig enviado ao Meshery é o
`--internal` (`out/kubeconfig-internal.yaml`), não o do host.

## Uso

```bash
./scripts/up.sh     # cria clusters, instala Meshery, registra os 2 clusters
open http://localhost:9081
./scripts/down.sh   # destrói tudo
```

Pré-requisitos: docker, kind, kubectl, helm.

> Clusters de 1 nó porque os limites padrão de inotify (`max_user_instances=128`)
> fazem o join de workers falhar com vários clusters. Com sudo dá para aumentar:
> `sudo sysctl fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=512`
> e adicionar `- role: worker` em `kind/*.yaml`.

## O que explorar na UI

- **Lifecycle → Connections**: os 2 clusters, ping, (des)conectar, deploy do Meshery Operator/MeshSync.
- **Lifecycle → Environments**: agrupe as conexões (ex.: `dev` com os 2 clusters).
- **Dashboard**: recursos descobertos via MeshSync (namespace `demo`: `web` + `redis`), filtro por cluster no seletor de contexto (topo).
- **Configuration → Designs**: importe `manifests/sample-app.yaml`, visualize no designer (Kanvas) e faça *deploy* escolhendo o(s) cluster(s) alvo — ótimo para testar multi-cluster.
- **Registry**: modelos/componentes suportados (CRDs, operadores, meshes).
- **Lifecycle → Service Mesh / Adapters**: habilite adapters no Helm (`--set meshery-istio.enabled=true`) para instalar Istio etc.
- **Performance**: testes de carga (ex.: contra `web.demo.svc`).

Tutoriais oficiais: https://docs.meshery.io/guides/tutorials/
