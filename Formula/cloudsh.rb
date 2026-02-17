class Cloudsh < Formula
  desc "Your servers, any device — self-hosted terminal access"
  homepage "https://cloudsh.io"
  url "https://github.com/JongoDB/cloudsh/archive/v0.9.5.tar.gz"
  sha256 "65717dc5d5863ea27767ee62f65b2a8dbe63c88238cb0116c8fef998e262edfc"
  license "MIT"

  # The cryptography package contains a Rust-compiled .abi3.so whose Mach-O
  # header is too small for Homebrew's dylib-ID rewrite.  Skipping relocation
  # for the entire venv avoids the "Failed changing dylib ID" error.
  skip_clean "libexec"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "python@3.12"
  depends_on "tmux"

  def install
    # Set up Python virtual environment
    venv = libexec / "venv"
    system "python3.12", "-m", "venv", venv.to_s

    # Install Python dependencies and package
    cd "packages/server" do
      system venv / "bin" / "pip", "install", "--no-cache-dir", "-r", "requirements.txt"
      system venv / "bin" / "pip", "install", "--no-cache-dir", "."
    end

    # Create wrapper script
    (bin / "cloudsh").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/venv/bin/cloudsh" "$@"
    EOS
  end

  def caveats
    <<~EOS
      CloudSH has been installed!

      Start the server:
        cloudsh start

      Check status:
        cloudsh status

      Open https://app.cloudsh.io to connect.

      For Cloudflare tunnel support (remote access):
        brew install cloudflare/cloudflare/cloudflared
    EOS
  end

  service do
    run [bin / "cloudsh", "start"]
    keep_alive true
    working_dir var / "cloudsh"
    log_path var / "log" / "cloudsh.log"
    error_log_path var / "log" / "cloudsh.log"
  end

  test do
    assert_match "usage", shell_output("#{bin}/cloudsh --help", 0)
  end
end
