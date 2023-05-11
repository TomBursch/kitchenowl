from os import listdir
from os.path import isfile, join
from app import app, db
from app.config import UPLOAD_FOLDER
from app.jobs import jobs
from app.models import User, File

def importFiles():
    try:
        filesInUploadFolder = [f for f in listdir(UPLOAD_FOLDER) if isfile(join(UPLOAD_FOLDER, f))]
        files = [File(filename=f) for f in filesInUploadFolder if not File.find(f)]

        db.session.bulk_save_objects(files)
        db.session.commit()
        print(f"-> Found {len(files)} new files in {UPLOAD_FOLDER}")
    except Exception as e:
        db.session.rollback()
        raise e

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
                if not newPW.strip(): 
                    print("Password cannot be empty")
                    continue
                newPWRepeat = input("Repeat new password:")
                if newPW.strip() == newPWRepeat.strip():
                    user.set_password(newPW.strip())
                    user.save()
                else:
                    print("Passwords do not match")
                    continue
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
    while True:
        print("""
Manage KitchenOwl\n---\nWhat do you want to do?
1.  Manage users
2.  Import files
3.  Run all jobs
(q) Exit""")
        selection = input("Your selection (q):")
        if selection == "1":
            with app.app_context():
                manageUsers()
        elif selection == "2":
            with app.app_context():
                importFiles()
        elif selection == "3":
            print("Starting jobs (might take a while)...")
            jobs.daily()
            jobs.halfHourly()
            print("Done!")
        else:
            exit()
