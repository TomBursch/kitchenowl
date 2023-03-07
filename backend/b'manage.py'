from app import app
from app.models import User


def manageUsers():
    while True:
        print("""
What next?
    1. List user
    2. Reset password
    3. Delete user
    4. Go back""")
        selection = input("Your selection (4):")
        if selection == "1":
            for u in User.all():
                print(u.username)
        elif selection == "2":
            username = input("Enter the username:")
            user = User.find_by_username(username)
            if not user:
                print("No user found with that username")
            else:
                newPW = input("Enter new password:")
                if not newPW: 
                    print("Password cannot be empty")
                    continue
                newPWRepeat = input("Repeat new password:")
                if newPW == newPWRepeat:
                    user.set_password(newPW)
        elif selection == "3":
            username = input("Enter the username:")
            user = User.find_by_username(username)
            if not user:
                print("No user found with that username")
            else:
                user.delete()
        else:
            return

# docker exec -it [backend container name] python manage.py
if __name__ == "__main__":
    with app.app_context():
        while True:
            print("""
Manage KitchenOwl\n---\nWhat do you want to do?
    1.  Manage users
    (q) Exit""")
            selection = input("Your selection (q):")
            if selection == "1":
                manageUsers()
            else:
                exit()
