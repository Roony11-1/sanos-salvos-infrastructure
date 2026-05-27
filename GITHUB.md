# 📌 Git Workflow del Proyecto

Este proyecto utiliza un flujo de trabajo basado en ramas para mantener el código ordenado, estable y escalable.

---

## 📌 Estructura de ramas

El proyecto se organiza en 3 tipos de ramas:

- **main** → contiene la versión estable del proyecto (producción)
- **dev** → rama principal donde se integra todo el desarrollo
- **feature/*** → ramas temporales para desarrollar funcionalidades específicas

---

## 🚀 Inicio del proyecto (desde un clone)

Cuando clonas el repositorio, normalmente estarás en `main`:

git checkout -b dev | Entra a la rama desarrollo
git push -u origin dev | Conecta la rama local con el repositorio remoto

Entonces los cambios van a la rama "dev", donde se pueden hacer directo o puedes crear ramas
por feature "feature/.."

para ello haremos lo siguiente

git checkout dev
git pull origin dev

git checkout -b feature/nombre-feature

// Para mandar cambios o usa la interfaz de vsCode y publica la rama
git push -u origin feature/nombre-feature

luego la pasamos a dev
git checkout dev

// Actualizamos por siacaso jiji
git pull origin dev

// Unimos la rama
git merge feature/nombre-feature

// subimos los cambios o lo hacemos por vsCode
git push origin dev

// Borramos la rama feature
git branch -d feature/nombre-feature
git push origin --delete feature/nombre-feature

// o hacelo directo en dev

// para subir los cambios a main (OJO CODIGO FUNCIONANDO)
git checkout main
git pull origin main
git merge dev
git push origin main



prueba ramas