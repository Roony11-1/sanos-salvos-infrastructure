# Git Workflow (Explicado)

Este documento explica cómo se organiza el flujo de trabajo con Git en este repositorio, usando ramas para mantener el código ordenado y estable.

---

## 📌 Estructura de ramas

El proyecto se organiza en 3 tipos de ramas:

- **main** → contiene la versión estable del proyecto (producción)
- **development** → rama principal donde se integra todo el desarrollo
- **feature/*** → ramas temporales para desarrollar funcionalidades específicas

---

## 🚀 Inicio del proyecto (crear development)

Primero se crea la rama de desarrollo a partir de `main`.

```bash
git checkout main
git pull origin main

git checkout -b development | -b = "create branch + switch to it"
git push -u origin development | “A partir de ahora, esta rama local development sigue a origin/development”