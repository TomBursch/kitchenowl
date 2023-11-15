# OpenID Connect

OIDC allow users to sign in with social logins or third party issuer. KitchenOwl supports three providers: Google, Apple (only on iOS & macOS), and a custom one.

For self-hosted instances the custom provider is the most interesting one.

### Setup
Inside your OIDC you need to configure a new client, with the following to redirect URIs:

- `FRONT_URL/signin/redirect`
- `kitchenowl:///signin/redirect`

You can then configure the backend using environment variables, just provide your issuer URL, client ID, and client secret:

```yaml
back:
    environment:
        - [...]
        - FRONT_URL=<URL> # front_url is requred when using oidc
        - OIDC_ISSUER=<URL> # e.g https://accounts.google.com
        - OIDC_CLIENT_ID=<ID>
        - OIDC_CLIENT_SECRET=<SECRET>
```

If everything is set up correctly you should see a *sign in with OIDC* button at the bottom of the login page.

![screenshot](/img/screenshots/oidc_button.png)

### Linking accounts

If you've already started using KitchenOwl or created an account first you can link an OIDC account to your existing KitchenOwl account. Just go to *settings* :material-arrow-right: Click on your profile at the top :material-arrow-right: *Linked Accounts* :material-arrow-right: and link your account.

Account links are permanent and can only be removed by deleting the KitchenOwl account. Users that signed in using OIDC are normal users that, after setting a password, can also sing in using their username + password. Deleting a user from your OIDC authority will not delete a user from KitchenOwl.


### Limitations
Currently only Web, Android, iOS, and macOS are supported.

### Apple & Google
These two providers will allow anyone to sing in with an Apple or Google account. They can be configured similarly to custom providers but will show up with a branded sign in with button.
It is not recommended setting up social logins for self-hosted versions as they might not work correctly.
```yaml
back:
    environment:
        - [...]
        - FRONT_URL=<URL> # front_url is requred when using oidc
        - APPLE_CLIENT_ID=<ID>
        - APPLE_CLIENT_SECRET=<SECRET>
        - GOOGLE_CLIENT_ID=<ID>
        - GOOGLE_CLIENT_SECRET=<SECRET>
```