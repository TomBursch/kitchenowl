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

=== "Backend"
    - Go to `./backend`
    - Create a python environment `python3 -m venv venv`
    - Activate your python environment `source venv/bin/activate` (environment can be deactivated with `deactivate`)
    - Install dependencies `pip3 install -r requirements.txt`
    - Initialize/Upgrade the SQLite database with `flask db upgrade`
    - Run debug server with `python3 wsgi.py` (to make the server visible to any device add `--host=0.0.0.0` or the network IP address on which to provide the server)
    - The backend should be reachable at `localhost:5000`

    !!! danger Known Warnings
        Do not run the backend using `flask` as it won't initialize the sockets properly.

    !!! info Known Warnings
        When debugging the backend the following warning is shown:

        ```
        WARNING in __init__: WebSocket transport not available. Install gevent-websocket for improved performance.
        ```

        This only affects the backend when running in debug mode and can be ignored.

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


### Debugging
It is generally recommended opening the backend and the frontend projects in different VS Code instances.
Here are some examples of configurations that work well with VS Code and allow you to set breakpoints:

=== "Frontend"
    An example configuration for `kitchenowl/.vscode/launch.json`:

    ```
    {
        "configurations": [
            {
                "name": "kitchenowl",
                "request": "launch",
                "type": "dart"
            },
            {
                "name": "kitchenowl (profile mode)",
                "request": "launch",
                "type": "dart",
                "flutterMode": "profile"
            }
        ]
    }
    ```
=== "Backend"
    An example configuration for `backend/.vscode/launch.json`:

    ```
    {
        "configurations": [
            {
                "name": "Python Debugger: KitchenOwl",
                "type": "debugpy",
                "request": "launch",
                "program": "wsgi.py",
                "jinja": true,
                "justMyCode": true,
                "gevent": true
            }
        ]
    }
    ```

    To expose the backend to the complete network add the followig parameters:

    ```
    args: [
        "--host=0.0.0.0"
    ]
    ```

If there is need to debug the interaction between two different app instances you can run flutter multiple times for different target devices. Either by running `flutter run -d <DEVICE_ID>` or by selecting `Run without Debugging` in VS Code multiple times. Be aware that it can be confusing to understand in which instance breakpoints are being hit when debugging multiple instances in VS Code.
    
### Git Commit Message Style

This project uses the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#summary) format.

Example commit messages:

```
chore: update gqlgen dependency to v2.6.0
docs(README): add new contributing section
fix: remove debug log statements
```