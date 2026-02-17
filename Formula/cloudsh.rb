class Cloudsh < Formula
  desc "Your servers, any device — self-hosted terminal access"
  homepage "https://cloudsh.io"
  url "https://github.com/JongoDB/cloudsh/archive/v0.10.1.tar.gz"
  sha256 "041cfcb4b0aa10ef263e854e365e3b25b2de7bb096d20af648977835f4cd04cb"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "cloudflare/cloudflare/cloudflared"
  depends_on "python@3.12"
  depends_on "tmux"

  def install
    # Stage the server source for post_install (pip install happens there
    # to avoid Homebrew's dylib-ID rewrite on cryptography's Rust .abi3.so)
    (libexec / "src").install Dir["packages/server/*"]

    # Create wrapper script (PATH ensures launchd services find Homebrew deps)
    (bin / "cloudsh").write <<~EOS
      #!/bin/bash
      export PATH="#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:$PATH"
      exec "#{libexec}/venv/bin/cloudsh" "$@"
    EOS
  end

  def post_install
    # Build venv and pip-install in post_install so Homebrew's relocator
    # never touches the cryptography .abi3.so shared library.
    venv = libexec / "venv"
    system "python3.12", "-m", "venv", venv.to_s

    cd libexec / "src" do
      system venv / "bin" / "pip", "install", "--no-cache-dir", "-r", "requirements.txt"
      system venv / "bin" / "pip", "install", "--no-cache-dir", "."
    end
  end

  def caveats
    <<~EOS
      CloudSH has been installed!

      Start the server:
        cloudsh start

      Check status:
        cloudsh status

      Open https://app.cloudsh.io to connect.

      Remote access is enabled by default via Cloudflare tunnels.
    EOS
  end

  service do
    run [bin / "cloudsh", "start"]
    keep_alive true
    working_dir var / "cloudsh"
    log_path var / "log" / "cloudsh.log"
    error_log_path var / "log" / "cloudsh.log"
    setup_service do
      (var / "cloudsh").mkpath
    end
  end

  test do
    assert_match "usage", shell_output("#{bin}/cloudsh --help", 0)
  end
end
