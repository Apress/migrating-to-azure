# Chapter 11
## Deployment Pipelines

One of the items that has gone through a significant amount of change in recent months is Azure Kubernetes Service.  This managed Kubernetes service has seen rapid updates with respect to version, features, and security options.  One such security option is that of adding Azure AD authentication in conjunction with role-based access control (RBAC).  RBAC is configured by default if you do not specify otherwise.  AAD authentication requires the use of two service principals: one client AAD application for the authentication request, and a server AAD application to validate against.
The easiest way to achieve this is to use the following to create a native application registration, followed by a Web app/API registration, and then grant permissions as needed to each.  More information on the full setup of this authentication pairing can be found [here](https://docs.microsoft.com/en-us/azure/aks/aad-integration).
To get started, use the following Azure CLI commands to create the two app registrations you need.

```
az ad app create --display-name app-k8s-client-auth --native-app
az ad app create --display-name app-k8s-server-auth
```

