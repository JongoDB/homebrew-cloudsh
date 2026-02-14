class Cloudsh < Formula
  desc "Your servers, any device — self-hosted terminal access"
  homepage "https://cloudsh.io"
  url "https://github.com/JongoDB/cloud-sh/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on "python@3.12"
  depends_on "tmux"
  depends_on "node@20" => :build

  def install
    # Set up Python virtual environment
    venv = libexec / "venv"
    system "python3.12", "-m", "venv", venv.to_s

    # Install Python dependencies and package
    cd "packages/server" do
      system venv / "bin" / "pip", "install", "--no-cache-dir", "-r", "requirements.txt"
      system venv / "bin" / "pip", "install", "--no-cache-dir", "."
    end

    # Build client
    system "npm", "ci", "--ignore-scripts"
    cd "packages/client" do
      system "npm", "run", "build"
    end

    # Install built client for static serving
    (libexec / "client").install Dir["packages/client/dist/*"]

    # Create wrapper script
    (bin / "cloudsh").write <<~EOS
      #!/bin/bash
      export CLOUDSH_STATIC_DIR="#{libexec}/client"
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
