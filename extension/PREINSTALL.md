# Introduction

The iProov Firebase Extension lets you register (enroll) and sign-in (verify) users with iProov Biometrics.

> **NOTE:** The iProov Firebase Extension is currently available as a technical preview (beta) service which means that there may be missing/broken functionality, and the API is still subject to change. We would welcome [your feedback](mailto:support@iproov.com) regarding the iProov Credentials Flutter SDK preview.

# Prerequisites

The iProov Firebase Extension can be used in two separate modes:

## Sandbox Mode

If you don't yet have an API Key & Secret from iProov, you may use the iProov Firebase Extension in our free-to-use "sandbox" environment. **IMPORTANT: The sandbox is strictly for development and testing only.** Apps pointing at the sandbox **MUST NOT** be released to production. The sandbox has strict limits on usage, only stores data for 30 days and has no guarantee of availability.

To setup the extension for sandbox usage, just leave the API key & secret empty during installation.

You can move to Standard Mode at any time by [contacting iProov](mailto:support@iproov.com).

## Standard Mode

Once you have completed your evaluation of iProov in the sandbox environment, you can [contact iProov](mailto:support@iproov.com) to obtain an API Key & Secret.

With these credentials, you can then switch to "Standard Mode". In Standard Mode, the sandbox restrictions are lifted and your usage of the service is governed by the terms of your agreement with iProov.

You will have your own API key designated to your own dedicated Service Provider for further development, testing or production.

# Installation

1. [Install this Extension into your Firebase app](https://console.firebase.google.com/project/_/extensions/install?ref=iproov/auth-iproov). Leave API key & secret empty to use the free-to-use sandbox environment.

   You can also install using the Firebase CLI:

   ```sh
   firebase ext:install iproov/auth-iproov --project=[your-project-id]
   ```

2. After installation is complete, you need to manually grant the extension's service account the necessary permission to generate signed authentication tokens. See the [post-install instructions](POSTINSTALL.md) for further details.

3. [Install the relevant iProov Firebase SDK for your mobile app](https://github.com/iProov/firebase/tree/master/sdk) (iOS, Android or Flutter) and follow the documentation to create and sign-in users.

# Billing

This extension uses other Firebase or Google Cloud Platform services which may have associated charges:

- Cloud Functions
- Auth
- Secrets

When you use Firebase Extensions, you're only charged for the underlying resources that you use. A paid-tier billing plan is only required if the extension uses a service that requires a paid-tier plan, for example calling to a Google Cloud Platform API or making outbound network requests to non-Google services. All Firebase services offer a free tier of usage. [Learn more about Firebase billing.](https://firebase.google.com/pricing)
