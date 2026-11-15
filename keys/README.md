# APK repository signing key

The public key `roamd-apk.rsa.pub` is committed here and installed by `install.sh` into `/etc/apk/keys/`.

The matching private key must **never** be committed. Generate a key pair locally:

```sh
sh scripts/generate-apk-key.sh
```

Then add the complete contents of the generated private PEM file as a GitHub Actions repository secret named `APK_SIGN_KEY`:

Repository → Settings → Secrets and variables → Actions → New repository secret.

The workflow refuses to publish a feed if this secret is missing. Keep a secure backup of the private key: replacing it requires distributing the matching new public key to routers before they can trust future feed indexes.
