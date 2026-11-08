#!/usr/bin/env python3
import argparse
import sys
import time
from os import listdir
from os.path import isfile, join


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Manage KitchenOwl (starts interactive menu if no task flags are given)",
    )
    parser.add_argument(
        "--run-jobs",
        action="store_true",
        help="Run all periodic jobs (monthly, daily, half-hourly)",
    )
    parser.add_argument(
        "--send-terms-mail",
        action="store_true",
        help="Send updated terms mail to all users with a verified email",
    )
    parser.add_argument(
        "--send-verification-mail",
        action="store_true",
        help="Send verification mail to unverified users",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.0,
        help="Delay between sending mails in seconds (default: 0)",
    )
    parser.add_argument(
        "--import-files",
        action="store_true",
        help="Import files from the upload folder",
    )
    parser.add_argument(
        "--delete-unused-files",
        action="store_true",
        help="Delete unused files",
    )
    parser.add_argument(
        "--recalculate-blurhashes",
        action="store_true",
        help="Generate missing blur-hashes for files",
    )
    parser.add_argument(
        "--delete-empty-households",
        action="store_true",
        help="Delete empty households",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

import blurhash
from PIL import Image
from tqdm import tqdm

from app import app, db
from app.config import UPLOAD_FOLDER
from app.jobs import jobs
from app.models import (
    ChallengeMailVerify,
    File,
    Household,
    HouseholdMember,
    User,
)
from app.service import mail
from app.service.delete_unused import (
    deleteEmptyHouseholds,
    deleteUnusedFiles,
)
from app.service.recalculate_blurhash import recalculateBlurhashes


def importFiles():
    try:
        filesInUploadFolder = [
            f for f in listdir(UPLOAD_FOLDER) if isfile(join(UPLOAD_FOLDER, f))
        ]

        def createFile(filename: str) -> File:
            blur = None
            try:
                with Image.open(join(UPLOAD_FOLDER, filename)) as image:
                    image.thumbnail((100, 100))
                    blur = blurhash.encode(image, x_components=4, y_components=3)
            except FileNotFoundError:
                pass
            except Exception:
                pass
            return File(filename=filename, blur_hash=blur)

        files = [createFile(f) for f in filesInUploadFolder if not File.find(f)]

        db.session.bulk_save_objects(files)
        db.session.commit()
        print(f"-> Found {len(files)} new files in {UPLOAD_FOLDER}")
    except Exception as e:
        db.session.rollback()
        raise e


def sendVerificationMails(delay: float = 0):
    if not mail.mailConfigured():
        print("Mail service not configured")
        return
    for user in tqdm(
        User.query.filter(
            User.email != None,
            (User.email_verified == False) | (User.email_verified == None),
        ).all(),
        desc="Sending verification mails",
    ):
        if len(user.verify_mail_challenge) == 0:
            mail.sendVerificationMail(
                user.id, ChallengeMailVerify.create_challenge(user)
            )
            if delay > 0:
                time.sleep(delay)


def sendTermsUpdateMails(delay: float = 0):
    if not mail.mailConfigured():
        print("Mail service not configured")
        return
    for user in tqdm(
        User.query.filter(
            User.email != None,
            User.email_verified == True,
        ).all(),
        desc="Sending terms update mails",
    ):
        mail.sendTermsUpdateMail(user.id)
        if delay > 0:
            time.sleep(delay)


def runJobs():
    print("Starting jobs (might take a while)...")
    with app.app_context():
        jobs.monthly()
        jobs.daily()
        jobs.halfHourly()
    print("Done!")


def manageHouseholds():
    while True:
        print("""
What next?
    1. List all households
    2. Delete empty
    (q) Go back""")
        selection = input("Your selection (q):")
        if selection == "1":
            for h in Household.all():
                print(f"Id {h.id}: {h.name} ({len(h.member)} members)")
        if selection == "2":
            print(f"Deleted {deleteEmptyHouseholds()} unused households")
        else:
            return


def manageUsers():
    while True:
        print("""
What next?
    1. List all users
    2. Create user
    3. Update user
    4. Delete user
    5. Send verification mail to unverified users
    6. Send updated terms mail to verified users
    (q) Go back""")
        selection = input("Your selection (q):")
        if selection == "1":
            for u in User.all():
                print(f"@{u.username} ({u.email}): {u.name} (server admin: {u.admin})")
        elif selection == "2":
            username = input("Enter the username:")
            password = input("Enter the password:")
            User.create(username, password, username)
        elif selection == "3":
            username = input("Enter the username:")
            user = User.find_by_username(username)
            if not user:
                print("No user found with that username")
            else:
                updateUser(user)
        elif selection == "4":
            username = input("Enter the username:")
            user = User.find_by_username(username)
            if not user:
                print("No user found with that username")
            else:
                user.delete()
        elif selection == "5":
            delay = float(input("Delay between mails in seconds (0):") or "0")
            sendVerificationMails(delay)
        elif selection == "6":
            delay = float(input("Delay between mails in seconds (0):") or "0")
            sendTermsUpdateMails(delay)
        else:
            return


def updateUser(user: User):
    print(f"""
Settings for {user.name} (@{user.username}) (server admin: {user.admin})
    1. Update password
    2. Add to household
    3. Set server admin
    (q) Go back""")
    selection = input("Your selection (q):")
    if selection == "1":
        newPW = input("Enter new password:")
        if not newPW.strip():
            print("Password cannot be empty")
        newPWRepeat = input("Repeat new password:")
        if newPW.strip() == newPWRepeat.strip():
            user.set_password(newPW.strip())
            user.save()
        else:
            print("Passwords do not match")
    elif selection == "2":
        id = int(input("Enter the household id:"))
        household = Household.find_by_id(id)
        if not household:
            print("No household found with that id")
        elif not HouseholdMember.find_by_ids(household.id, user.id):
            hm = HouseholdMember()
            hm.user_id = user.id
            hm.household_id = household.id
            hm.save()
        else:
            print("User is already part of that household")
    elif selection == "3":
        selection = input("Set admin (y/N):")
        user.admin = selection == "y"
        user.save()
    else:
        return


def manageFiles():
    while True:
        print("""
What next?
    1. Import files
    2. Delete unused files
    3. Generate missing blur-hashes
    (q) Go back""")
        selection = input("Your selection (q):")
        if selection == "1":
            importFiles()
        elif selection == "2":
            print(f"Deleted {deleteUnusedFiles()} unused files")
        elif selection == "3":
            print(f"Updated {recalculateBlurhashes()} files")
        else:
            return


# docker exec -it [backend container name] python manage.py
if __name__ == "__main__":
    has_flag = any(
        [
            args.run_jobs,
            args.send_terms_mail,
            args.send_verification_mail,
            args.import_files,
            args.delete_unused_files,
            args.recalculate_blurhashes,
            args.delete_empty_households,
        ]
    )

    if has_flag:
        if args.import_files:
            with app.app_context():
                importFiles()
        if args.delete_unused_files:
            with app.app_context():
                print(f"Deleted {deleteUnusedFiles()} unused files")
        if args.recalculate_blurhashes:
            with app.app_context():
                print(f"Updated {recalculateBlurhashes()} files")
        if args.delete_empty_households:
            with app.app_context():
                print(f"Deleted {deleteEmptyHouseholds()} unused households")
        if args.send_verification_mail:
            with app.app_context():
                sendVerificationMails(args.delay)
        if args.send_terms_mail:
            with app.app_context():
                sendTermsUpdateMails(args.delay)
        if args.run_jobs:
            runJobs()
        sys.exit()

    while True:
        print("""
Manage KitchenOwl\n---\nWhat do you want to do?
1.  Manage users
2.  Manage households
3.  Manage images/files
4.  Run all jobs
(q) Exit""")
        selection = input("Your selection (q):")
        if selection == "1":
            with app.app_context():
                manageUsers()
        elif selection == "2":
            with app.app_context():
                manageHouseholds()
        elif selection == "3":
            with app.app_context():
                manageFiles()
        elif selection == "4":
            runJobs()
        else:
            sys.exit()
