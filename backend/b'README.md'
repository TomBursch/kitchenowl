<p align="center">
  <a>
    <img alt="KitchenOwl" src="docs/icon.png" width="128" />
  </a>
</p>
<p align="center">
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/TomBursch/KitchenOwl" />
  </a>
  <a href="https://hub.docker.com/repository/docker/tombursch/kitchenowl">
    <img alt="Docker pulls" src="https://img.shields.io/docker/pulls/TomBursch/KitchenOwl" />
  </a>
</p>
<h1 align="center">
  KitchenOwl
</h1>

<h3 align="center">
  A grocery list and recipe manager
</h3>
<p align="center">
  KitchenOwl is a self-hosted grocery list and recipe manager. The backend is made with Flask and the frontend with Flutter. Easily add items to your shopping list before you go shopping. You can also create recipes and add items based on what you want to cook.
</p>

<h3 align="center">
 🍫 🥘 🍽
</h3>

## ✨ Features

The following features have been implemented:

- Add items to your shopping list and sync it with multiple users
- Partial offline support so you don't lose track of what to buy even when there is no signal
- Manage recipes and add items directly from a recipe.
- Mobile/Web/Desktop apps

This project is still in development, so some options may not be fully implemented yet.

For a list of planned features, check out the [Roadmap](https://github.com/TomBursch/KitchenOwl/wiki/Roadmap)!

## 🤖 Install

You can either install only the backend or add the web-app to it. [Docker](https://docs.docker.com/engine/install/) is required.

### Backend only
Using docker cli:
```
docker volume create kitchenowl_data
```
```
docker run -d -p 5000:5000 --name=kitchenowl --restart=unless-stopped -v kitchenowl_data:/data tombursch/kitchenowl:latest
```

### Backend and Web-app
Recommended using [docker-compose](https://docs.docker.com/compose/):
1. Download the [docker-compose.yml](docker-compose.yml)
2. Change default values such as `JWT_SECRET_KEY` and the URLs (corresponding to the ones your instance will be running on)
3. Run `docker-compose up -d`

## 🙌 Contributing

From opening a bug report to creating a pull request: every contribution is appreciated and welcomed. If you're planning to implement a new feature or change the API please create an issue first. This way we can ensure your work is not in vain. For more information see [Contributing](https://github.com/TomBursch/KitchenOwl/CONTRIBUTING.md)

## 📚 Related
- [KitchenOwl App](https://github.com/TomBursch/KitchenOwl-app) Repository
- [DockerHub](https://hub.docker.com/repository/docker/tombursch/kitchenowl)
- Icons modified from [Those Icons](https://www.flaticon.com/authors/those-icons) and [Freepik](https://www.flaticon.com/authors/freepik)

### 🔨 Built With
- [Flask](https://flask.palletsprojects.com/en/1.1.x/)
- [Flutter](https://flutter.dev/)
- [Docker](https://docs.docker.com/)