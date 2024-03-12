# IMPORTANT: You must add the `Service Account Token Creator` role to your Extension's service account!

[Supported roles for Firebase Extensions](https://firebase.google.com/docs/extensions/publishers/access#supported-roles) does not currently include `projects.serviceAccounts.signJwt` which is required for this Extension to work.

Therefore, you must complete the following manual steps to finalize the Extension setup process:

1. [Open the Google Cloud Console IAM Admin page](https://console.cloud.google.com/iam-admin/iam).

2. Press the blue "GRANT ACCESS" button.

3. In the side panel, in the "New Principles" box, enter **`ext-${param:EXT_INSTANCE_ID}@${param:PROJECT_ID}.iam.gserviceaccount.com`**.

4. In the "Select a role" dropdown, enter the role "Service Account Token Creator".

5. Click "Save".

6. Wait a few minutes for the changes to fully propagate.

# Start using the iProov Firebase SDKs

After completing the iProov Auth Firebase Extension setup, follow the relevant documentation for the iProov Firebase SDK for your relevant front-end platform(s):

- [iOS](https://github.com/iProov/firebase/tree/master/sdk/ios)
- [Android](https://github.com/iProov/firebase/tree/master/sdk/android)
- [Flutter](https://github.com/iProov/firebase/tree/master/sdk/flutter)

# Limitations

### User deletion

Currently, if you delete a user from Firebase Auth, this will not automatically delete the user from the iProov database.

There are two consequences of this that you need to be aware of:

1. **Biometric data will not be automatically erased** - instead, biometric data will be erased according to the applicable retention policy defined for your Service Provider.

2. **The User ID will not be available for reuse** - since the user still exists in the iProov database even if deleted from Firebase Auth, you will be unable to reuse the same User ID for subsequent account (re)creation.

Automatic synchronization of user deletion across Firebase Auth and iProov will be added in a future release of the iProov Firebase Extension.

Until then, you can [manually call the relevant iProov REST API endpoint](https://eu.rp.secure.iproov.me/docs.html#operation/userDelete) if you require the ability to delete user accounts.

# Troubleshooting

### I'm getting the error `Error: Permission 'iam.serviceAccounts.signJwt' denied on resource (or it may not exist).`

Check the following:

1. Check you followed the post-install steps at the top of this page.

2. If you only just granted the permission, wait a few minutes and try your request again.

3. In Google Cloud Console, check that the [IAM Service Account Credentials API](https://console.cloud.google.com/marketplace/product/google/iamcredentials.googleapis.com) is enabled.

4. If using the emulator, [check you have set `GOOGLE_APPLICATION_CREDENTIALS` correctly](https://firebase.google.com/docs/functions/local-emulator#set_up_admin_credentials_optional).

# Monitoring

As a best practice, you can [monitor the activity](https://firebase.google.com/docs/extensions/manage-installed-extensions#monitor) of your installed extension, including checks on its health, usage, and logs.
