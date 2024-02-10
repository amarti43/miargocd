#!/bin/bash

# Definir la estructura básica
areas=("area1" "area2")
apps_area1=("app1" "app2")
apps_area2=("app3" "app4" "app5")
environments=("desarrollo" "pruebas" "produccion")

# Crear directorios para ArgoCD y las áreas
mkdir -p argocd/{area1/{app1,app2},area2/{app3,app4,app5}}
mkdir -p areas/{area1/{app1,app2},area2/{app3,app4,app5}}

# Función para generar la estructura base y overlays para una aplicación
generate_app_structure() {
    base_path=$1
    app_name=$2

    # Crear base y overlays
    mkdir -p "${base_path}/${app_name}/base"
    touch "${base_path}/${app_name}/base/deployment.yaml"
    touch "${base_path}/${app_name}/base/kustomization.yaml"
    touch "${base_path}/${app_name}/base/service.yaml"

    for env in "${environments[@]}"; do
        mkdir -p "${base_path}/${app_name}/overlays/${env}"
        touch "${base_path}/${app_name}/overlays/${env}/kustomization.yaml"
        touch "${base_path}/${app_name}/overlays/${env}/patch_deployment.yaml"
    done
}

# Función para generar archivos de configuración de Argo CD
generate_argocd_config() {
    area_path=$1
    app_name=$2

    cat > "${area_path}/${app_name}/app.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${app_name}
spec:
  project: default
  source:
    repoURL: 'https://github.com/amarti43/miargocd'
    targetRevision: HEAD
    path: areas/${area_path#*/}/${app_name}/overlays/desarrollo
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${app_name}-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

    cat > "${area_path}/${app_name}/project.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ${app_name}-project
spec:
  description: "Project for ${app_name}"
  sourceRepos:
  - '*'
  destinations:
  - namespace: ${app_name}-namespace
    server: 'https://kubernetes.default.svc'
EOF
}

# Generar estructura para area1
for app in "${apps_area1[@]}"; do
    generate_app_structure "areas/area1" "$app"
    generate_argocd_config "argocd/area1" "$app"
done

# Generar estructura para area2
for app in "${apps_area2[@]}"; do
    generate_app_structure "areas/area2" "$app"
    generate_argocd_config "argocd/area2" "$app"
done

echo "Estructura de directorios y archivos básicos generada con éxito."

