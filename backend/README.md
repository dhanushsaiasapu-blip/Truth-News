# Truth news backend

This is a deployable, credential-free backend for the Truth Flutter client. It exposes `GET /news` and retrieves real articles from configured RSS feeds. No provider API key is embedded in the mobile app.

## Run

Requires Node.js 20+.

```bash
npm install
npm start
```

Then check `http://localhost:8080/health` and `http://localhost:8080/news`.

## Deploy

Deploy this directory to any Node.js HTTPS host that supports Node 20+. Set `PORT` if required by the host. After deployment, use the public HTTPS origin as the Flutter `BACKEND_BASE_URL`.

Example:

```bash
flutter build appbundle --release --dart-define=BACKEND_BASE_URL=https://YOUR-ACTUAL-HOST
```

Do not put provider credentials, private keys, or secrets into this repository. Review each upstream feed's terms before commercial publication.
