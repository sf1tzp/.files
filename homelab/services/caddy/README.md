# Combined Caddy & step-ca deployment

## Trusting the Lab Services


Download it and install per-platform:

  curl -k https://step-ca:9000/roots.pem -o lofi-root-ca.pem

  (Use -k since you don't trust it yet. Replace step-ca with the host IP if running from outside the container network, e.g. https://10.0.0.2:9000/roots.pem or
  https://localhost:9000/roots.pem.)

Linux:
  sudo cp lofi-root-ca.pem /usr/local/share/ca-certificates/lofi-root-ca.crt
  sudo update-ca-certificates

macOS:
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain lofi-root-ca.pem

Windows:
  certutil -addstore -f "ROOT" lofi-root-ca.pem

iOS: Email/host the .pem, open it, then go to Settings > General > About > Certificate Trust Settings and enable it.

Android: Settings > Security > Install a certificate > CA certificate.

Firefox (all platforms): Firefox uses its own trust store — go to Settings > Privacy & Security > Certificates > View Certificates > Import.

