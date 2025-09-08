# kubernetes-practice

## How to write manifest files

- apiVersion: The version of the Kubernetes API to use for the object. Different objects may require different API versions.
  - v1: Core API group (e.g., Pods, Services).
  - apps/v1: Applications API group (e.g., Deployments, StatefulSets).
  - batch/v1: Batch API group (e.g., Jobs, CronJobs).
  - networking.k8s.io/v1: Networking API group (e.g., Ingress
  - argoproj.io/v1alpha1: Argo Project API group (e.g., Argo Workflows, Argo Rollouts).
  - keda.sh/v1alpha1: KEDA API group (e.g., ScaledObjects, ScaledJobs).
  - cert-manager.io/v1: Cert-Manager API group (e.g., Certificates, Issuers).
- kind: The type of Kubernetes object being created (e.g., Pod, Service, Deployment).
- metadata: Metadata about the object, including its name, namespace, labels, and annotations.
- spec: The specification of the desired state of the object. This section varies depending on the type of object being created.
- status: The current status of the object. This section is typically managed by Kubernetes and is not included in the manifest file when creating an object.
- comments: Comments can be added using the `#` symbol. Comments are ignored by Kubernetes and are used for documentation purposes.

## Custom Resource Definitions (CRDs)

- CRDs allow you to define your own custom resources in Kubernetes.
- They extend the Kubernetes API to include new types of objects that are not part of the core
- e.g. Argo Rollouts, Argo Workflows, KEDA, Cert-Manager
