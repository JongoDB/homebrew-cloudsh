# Homebrew Tap for CloudSH

Install [CloudSH](https://cloudsh.io) via Homebrew.

## Install

```bash
brew tap JongoDB/cloudsh
brew install cloudsh
```

## Optional: Cloudflare Tunnel

For remote access to your server from anywhere:

```bash
brew install cloudflare/cloudflare/cloudflared
```

## Usage

```bash
cloudsh start       # Start the server
cloudsh status      # Check server status
cloudsh pair        # Generate a new pairing code
cloudsh password    # Change server password
```

Then open [app.cloudsh.io](https://app.cloudsh.io) on any device and add your server.
