Thanks for wanting to contribute to KitchenOwl!

### Where do I go from here?

So you want to contribute to KitchenOwl? Great!

If you have noticed a bug, please [create an issue](https://github.com/TomBursch/KitchenOwl/issues/new) before starting any work on a pull request or get in contact by joining our [Matrix space](https://matrix.to/#/#kitchenowl:matrix.org).

### Fork & create a branch

If there is something you want to fix or add, the first step is to fork the repository.
[:fontawesome-brands-github: Frontend](https://github.com/TomBursch/KitchenOwl){ .md-button }
[:fontawesome-brands-github: Website](https://github.com/TomBursch/KitchenOwl-website){ .md-button }

Next is to create a new branch with an appropriate name. You can use the following format:

``` bash
git checkout -b '<type>/<description>'
```

The `type` is the same as the `type` that you will use for [your commit message](https://www.conventionalcommits.org/en/v1.0.0/#summary).

The `description` is a descriptive summary of the change the PR will make.

### General Rules

- One PR per fix or feature
- All PRs should be rebased (with main) and commits squashed prior to the final merge process

### Setup & Install
=== "Frontend"
    - [Install flutter](https://flutter.dev/docs/get-started/install)
    - Go to `./kitchenowl`
    - Install dependencies: `flutter packages get`
    - Create empty environment file: `touch .env`
    - Run app: `flutter run`

==== Debugging

An example configuration (for launch.json) for debugging in VS Code when opening the root folder in the editor:

```
{
    "name": "kitchenowl",
    "cwd": "kitchenowl",
    "request": "launch",
    "type": "dart"
},
{
    "name": "kitchenowl (profile mode)",
    "request": "launch",
    "type": "dart",
    "flutterMode": "profile"
}
```

For an easier debug setup see the section below.


=== "Backend"
    - Go to `./backend`
    - Create a python environment `python3 -m venv venv`
    - Activate your python environment `source venv/bin/activate` (environment can be deactivated with `deactivate`)
    - Install dependencies `pip3 install -r requirements.txt`
    - Initialize/Upgrade the sqlite database with `flask db upgrade`
    - Run debug server with `python3 wsgi.py` (to make the the server visible to any device add `--host=0.0.0.0` or the network IP address on which to provide the server)
    - The backend should be reachable at `localhost:5000`

    **Do not run the backend using `flask` as it won't initialize the sockets properly.**

==== Debugging

An example configuration (for launch.json) for debugging in VS Code when opening the root folder in the editor:

```
{
    "name": "Python Debugger: KitchenOwl",
    "type": "debugpy",
    "request": "launch",
    "cwd": "${workspaceFolder}/backend/",
    "program": "wsgi.py",
    "jinja": true,
    "justMyCode": true,
    "gevent": true
},
```

To expose the backend to the complete network add the followig parameters:

```
args: [
    "--host=0.0.0.0"
]
```

=== "Docs"
    - Go to `./docs`
    - Create a python environment `python3 -m venv venv`
    - Activate your python environment `source venv/bin/activate` (environment can be deactivated with `deactivate`)
    - Install dependencies `pip3 install -r requirements.txt`
    - Run docs: `mkdocs serve`
=== "Website"
    - [Install Hugo](https://gohugo.io/getting-started/quick-start/)
    - Clone the website repository
    - Run website: `hugo server`
=== Debugging
==== Known Warnings

When debugging the backend the following warning is shown:

```
WARNING in __init__: WebSocket transport not available. Install gevent-websocket for improved performance.
```

This only affects the backend when running in debug mode. This means it is not necessary to add it to `requirements.txt` for the project.


=== Debugging

It is generally recommended to open the backend and the frontend projects in different VS Code instances. When developing in this way the debugging configuration for the backend must be adapted by removing `cwd`.

If there is need to debug the interaction between two different different apps (i.e. Linux native and Web Browser) they can be started on the same host by running flutter multiple times:

- `flutter run -d chrome`
- `flutter run -d linux`

The Android version can also be run by using an emulator on the same PC to avoid needing to expose the backend on the local network.

The debugger in VS Code can also be started multiple times in the same editor session. This is not recommended as it can be confusing to understand in which instance breakpoints are being hit. It is easier to start mulitple VS Code sessions.

### Git Commit Message Style

This project uses the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#summary) format.

Example commit messages:

```
chore: update gqlgen dependency to v2.6.0
docs(README): add new contributing section
fix: remove debug log statements
```