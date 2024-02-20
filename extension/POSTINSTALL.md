# Using the extension

After installing the iProov Auth Firebase Extension to your project, follow the relevant documentation for the iProov Firebase SDK for your relevant front-end platform(s):

- [iOS](https://github.com/iProov/firebase/tree/master/sdk/ios)
- [Android](https://github.com/iProov/firebase/tree/master/sdk/android)
- [Flutter](https://github.com/iProov/firebase/tree/master/sdk/flutter)

# Troubleshooting

### I'm getting the error `Error: Permission 'iam.serviceAccounts.signJwt' denied on resource (or it may not exist).`

Check the following:

1. You have granted the iProov Auth extension service account the Service Account Token Creator permission. The email address of the relevant service account is **`ext-${param:EXT_INSTANCE_ID}@${param:PROJECT_ID}.iam.gserviceaccount.com`**. See the installation instructions for more detail. 

2. If you only just granted the permission, wait a few minutes and try again.

3. In Google Cloud Console, check that the [IAM Service Account Credentials API](https://console.cloud.google.com/marketplace/product/google/iamcredentials.googleapis.com) is enabled.

4. If using the emulator, [check you have set `GOOGLE_APPLICATION_CREDENTIALS` correctly](https://firebase.google.com/docs/functions/local-emulator#set_up_admin_credentials_optional).

# Monitoring

As a best practice, you can [monitor the activity](https://firebase.google.com/docs/extensions/manage-installed-extensions#monitor) of your installed extension, including checks on its health, usage, and logs.
