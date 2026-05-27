# 📌 Git Workflow del Proyecto

Este proyecto utiliza un flujo de trabajo basado en ramas para mantener el código ordenado, estable y escalable.

---

## 📌 Estructura de ramas

El proyecto se organiza en 3 tipos de ramas:

- **main** → contiene la versión estable del proyecto (producción)
- **development** → rama principal donde se integra todo el desarrollo
- **feature/*** → ramas temporales para desarrollar funcionalidades específicas

---

## 🚀 Inicio del proyecto (desde un clone)

Cuando clonas el repositorio, normalmente estarás en `main`:

git checkout -b development | Entra a la rama desarrollo
git push -u origin development | Conecta la rama local con el repositorio remoto

Entonces los cambios van a la rama "development", donde se pueden hacer directo o puedes crear ramas
por feature "feature/.."

para ello haremos lo siguiente

git checkout development
git pull origin development

git checkout -b feature/nombre-feature

// Para mandar cambios o usa la interfaz de vsCode
git push -u origin feature/nombre-feature