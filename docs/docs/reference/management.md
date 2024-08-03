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
3.  Import files
4.  Run all jobs
(q) Exit
Your selection (q):
```
Follow the instructions and everything should be self-explanatory.
Some things that you can do with this:

- Add/Update/Remove users 
- Add users to households
- Run jobs like regenerating item orderings and suggestions
