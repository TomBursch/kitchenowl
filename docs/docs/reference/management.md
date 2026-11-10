# Server Management

To make things easier there is a script that allows you to change settings on your server and manage users and households.
Just run:
``` bash
docker exec -it BACKEND_CONTAINER_NAME python manage.py
```
Which will prompt you for what you want to do:
```
Manage KitchenOwl
---
What do you want to do?
1.  Manage users
2.  Manage households
3.  Manage images/files
4.  Run all jobs
(q) Exit
Your selection (q):
```
Follow the instructions and everything should be self-explanatory.
Some things that you can do with this:

- Add/Update/Remove users 
- Add users to households
- Send verification or updated terms mails to users
- Import files, delete unused files/empty households, and generate missing blur-hashes
- Run jobs like regenerating item orderings and suggestions

## Command Line Flags

You can also run specific tasks non-interactively by passing flags to `manage.py`:

``` bash
docker exec -it BACKEND_CONTAINER_NAME python manage.py --run-jobs
```

| Flag | Description |
| --- | --- |
| `-h`, `--help` | Show help message and exit |
| `--run-jobs` | Run all periodic jobs (monthly, daily, half-hourly) |
| `--send-terms-mail` | Send updated terms mail to all users with a verified email |
| `--send-verification-mail` | Send verification mail to unverified users |
| `--delay <seconds>` | Delay between sending mails in seconds (default: `0`) |
| `--import-files` | Import files from the upload folder |
| `--delete-unused-files` | Delete unused files |
| `--recalculate-blurhashes` | Generate missing blur-hashes for files |
| `--delete-empty-households` | Delete empty households |
