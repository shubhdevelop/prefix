# File Organizer (prefix)

A Go script that automatically organizes files from a dump directory into destination directories based on filename patterns (prefix/suffix matching) defined in a YAML configuration.

# The Genesis
Idea of this script comes from the fact that Mac saves all the screenshot and screen recordings on Desktop by default and I am lazy enough to find the setting to change the destination folder. But that's not it

Morever having this also gives joy to my unonrganised ass, but OCD brain, yeah they can coexist.
More background, I love collecting PDFs white paper, anime wallpapers etc, that I might never read or use in foreseeable future.

Also, I have my hands dirty with creative designing as well, and I am well aware of concept of dump/swipe folders, where people intially dump/swipe things in that folder, and later oragnise them in their intended folders, this step of organising is unavoidable. You have do it now or later and this sometime is dauting and leds to procrastination when folders become big.

I propose a million dollar solution to add a prefix_ to the file being downloaded. Why this Works, it works because it's easier to remember to add prefix, than transversing through folder structure, everytime you download something, aas well as  categorising and moving each files one by one later. 

## Features

- Move files based on prefix and/or suffix patterns
- YAML-based configuration
- Creates destination directories automatically
- Handles cross-filesystem moves
- Prevents overwriting existing files
- Detailed logging of all operations
- Summary report after completion
- Run as a background service (macOS LaunchAgent / Linux systemd)
- Automatic file watching
- Cross-platform support (macOS and Linux)

---

## Installation

### macOS - Homebrew (Recommended)

If you have Homebrew installed, you can install `prefix` with:

```bash
# Add the tap
brew tap shubhdevelop/prefix

# Install the package
brew install prefix
```

Or install directly:
```bash
brew install shubhdevelop/prefix/prefix
```

After installation, set up your config:
```bash
# Create config directory
mkdir -p ~/.config/prefix

# Copy the example config
cp $(brew --prefix)/share/prefix/config.example.yaml ~/.config/prefix/prefix.yaml

# Edit the config file
nano ~/.config/prefix/prefix.yaml
```

### Linux - Manual Installation

1. **Download the binary from releases:**
   ```bash
   # For amd64
   wget https://github.com/shubhdevelop/prefix/releases/latest/download/prefix-linux-amd64
   chmod +x prefix-linux-amd64
   sudo mv prefix-linux-amd64 /usr/local/bin/prefix
   
   # For arm64
   wget https://github.com/shubhdevelop/prefix/releases/latest/download/prefix-linux-arm64
   chmod +x prefix-linux-arm64
   sudo mv prefix-linux-arm64 /usr/local/bin/prefix
   ```

2. **Or install to user directory:**
   ```bash
   mkdir -p ~/.local/bin
   wget https://github.com/shubhdevelop/prefix/releases/latest/download/prefix-linux-amd64 -O ~/.local/bin/prefix
   chmod +x ~/.local/bin/prefix
   # Add ~/.local/bin to your PATH if not already
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **Set up your config:**
   ```bash
   # Create config directory
   mkdir -p ~/.config/prefix
   
   # Create config file (you'll need to create this manually or copy from example)
   nano ~/.config/prefix/prefix.yaml
   ```

### Manual Installation (Build from Source)

1. Make sure you have Go installed (version 1.21 or later)

2. Install the required dependencies:
```bash
go mod download
```

3. Build the script:
```bash
# For your current platform
go build -o prefix prefix.go

# Or cross-compile for specific platforms
GOOS=linux GOARCH=amd64 go build -o prefix-linux-amd64 prefix.go
GOOS=darwin GOARCH=amd64 go build -o prefix-macos-amd64 prefix.go
```

---

## Configuration

Create a YAML configuration file with the following structure:

```yaml
dump_directory: "/path/to/dump"

destinations:
  - path: "/path/to/destination1"
    prefix: "file_"          # Optional: match files starting with this
    suffix: ".pdf"           # Optional: match files ending with this
  
  - path: "/path/to/destination2"
    prefix: "report_"
    suffix: ".xlsx"          # Both prefix and suffix (AND logic)
```

### Configuration Options

- `dump_directory`: Source directory containing files to organize
- `destinations`: List of destination rules (processed in order)
  - `path`: Destination directory path
  - `prefix`: (Optional) Files must start with this string
  - `suffix`: (Optional) Files must end with this string
  - If both prefix and suffix are specified, files must match BOTH
  - First matching destination wins

The configuration file should be located at `~/.config/prefix/prefix.yaml` by default.

---

## Usage

### Running Manually

Run the script directly:

```bash
prefix
```

The program will:
- Load configuration from `~/.config/prefix/prefix.yaml`
- Organize existing files in the dump directory
- Watch for new files and organize them automatically
- Run until you press Ctrl+C

### Running as a Background Service

To run prefix as a background service that starts automatically on boot:

**macOS:**

1. **Install the service:**
   ```bash
   prefix-service install
   ```

2. **Check service status:**
   ```bash
   prefix-service status
   ```

3. **View logs:**
   ```bash
   prefix-service logs
   ```

4. **Manage the service:**
   ```bash
   prefix-service start    # Start the service
   prefix-service stop     # Stop the service
   prefix-service restart  # Restart the service
   prefix-service uninstall # Remove the service
   ```

The service will:
- Start automatically when you log in
- Restart automatically if it crashes
- Log to `~/Library/Logs/prefix.log`
- Run in the background without a terminal

**Linux:**
1. **Install the service:**
   ```bash
   prefix-service install
   ```

2. **Enable user services at boot (if not already enabled):**
   ```bash
   sudo loginctl enable-linger $(whoami)
   ```

3. **Check service status:**
   ```bash
   prefix-service status
   ```

4. **View logs:**
   ```bash
   prefix-service logs
   # Or use journalctl directly:
   journalctl --user -u prefix.service -f
   ```

5. **Manage the service:**
   ```bash
   prefix-service start    # Start the service
   prefix-service stop     # Stop the service
   prefix-service restart   # Restart the service
   prefix-service uninstall # Remove the service
   ```

The service will:
- Start automatically when you log in (if linger is enabled)
- Restart automatically if it crashes
- Log to `~/.config/prefix/prefix.log` and `~/.config/prefix/prefix.error.log`
- Run in the background without a terminal

**Note:** Make sure you've configured `~/.config/prefix/prefix.yaml` before installing the service.

#### Service Management Details

All service management is done through the `prefix-service` command:

**Install the Service:**
```bash
prefix-service install
```
This will:
- Create the LaunchAgent plist file
- Start the service immediately
- Configure it to start on boot

**Check Status:**
```bash
prefix-service status
```
Shows:
- Whether the service is running or stopped
- Process ID (if running)
- Config file status
- Log file locations and sizes

**View Logs:**
```bash
# Follow logs in real-time
prefix-service logs

# Or view directly
tail -f ~/Library/Logs/prefix.log
cat ~/Library/Logs/prefix.error.log
```

**Start/Stop/Restart:**
```bash
prefix-service start    # Start the service
prefix-service stop     # Stop the service
prefix-service restart # Restart the service
```

**Uninstall:**
```bash
prefix-service uninstall
```
This stops and removes the LaunchAgent. The binary and config file remain installed.

#### Service Troubleshooting

**Service won't start:**
1. Check if config exists: `ls -la ~/.config/prefix/prefix.yaml`
2. Verify config is valid: `prefix` (run manually to test)
3. Check error logs: `cat ~/Library/Logs/prefix.error.log`
4. Check system logs: `log show --predicate 'process == "prefix"' --last 5m`

**Service stops unexpectedly:**
1. Check the error log: `tail -50 ~/Library/Logs/prefix.error.log`
2. Verify dump directory exists in your `~/.config/prefix/prefix.yaml` config
3. Check permissions for dump and destination directories

**"Operation not permitted" error (macOS):**
If you see errors like `operation not permitted` when accessing Desktop, Downloads, or Documents folders, you need to grant macOS permissions:

**For Service (prefix-service):**
1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **+** button
3. Press `Cmd+Shift+G` and paste: `/opt/homebrew/Cellar/prefix/0.1.1/bin/prefix`
   - Or find it by running: `readlink -f $(which prefix)`
4. Add it and enable the toggle
5. Restart the service: `prefix-service restart`

**For Terminal/Manual Run:**
1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Add **Terminal** (or iTerm, etc.) and enable the toggle
3. Restart Terminal and try again

**Alternative (Files and Folders access):**
If Full Disk Access is too broad, try:
1. **System Settings** → **Privacy & Security** → **Files and Folders**
2. Find Terminal (or your terminal app)
3. Enable **Desktop Folder** access

**Service doesn't start on boot:**
1. Verify the plist exists: `ls -la ~/Library/LaunchAgents/com.prefix.plist`
2. Check if RunAtLoad is set: `plutil -p ~/Library/LaunchAgents/com.prefix.plist | grep RunAtLoad`
3. Manually test loading: `launchctl load -w ~/Library/LaunchAgents/com.prefix.plist`

**Platform Compatibility:**
- **macOS**: Uses LaunchAgent (automatically detects bootstrap vs load methods)
  - **macOS 10.11+**: Uses `launchctl bootstrap` / `launchctl bootout`
  - **Older macOS**: Uses `launchctl load` / `launchctl unload`
- **Linux**: Uses systemd user services
  - Requires systemd (most modern Linux distributions)
  - May require `loginctl enable-linger` for services to start at boot

**Logs Location:**

**macOS:**
- **Standard output**: `~/Library/Logs/prefix.log` (LaunchAgent stdout)
- **Standard error**: `~/Library/Logs/prefix.error.log` (LaunchAgent stderr)
- **Application log**: `~/.config/prefix/app.log` (application log file)

**Linux:**
- **Standard output**: `~/.config/prefix/prefix.log` (systemd stdout)
- **Standard error**: `~/.config/prefix/prefix.error.log` (systemd stderr)
- **Application log**: `~/.config/prefix/app.log` (application log file)
- **Systemd logs**: `journalctl --user -u prefix.service` (systemd journal)

**Best Practices:**
1. Test manually first: Always test your config by running `prefix` manually before installing as a service
2. Monitor logs: Check logs after installation to ensure everything is working
3. Use status command: Regularly check `prefix-service status` to verify it's running
4. Keep config backed up: Your `~/.config/prefix/prefix.yaml` config is important - keep it backed up
5. Update carefully: When updating prefix, restart the service:
   ```bash
   brew upgrade prefix
   prefix-service restart
   ```

---

## Example

Given this configuration:

```yaml
dump_directory: "/home/user/downloads"

destinations:
  - path: "/home/user/documents/invoices"
    prefix: "invoice_"
    suffix: ".pdf"
  
  - path: "/home/user/documents/reports"
    prefix: "report_"
  
  - path: "/home/user/images"
    suffix: ".jpg"
```

Files will be organized as follows:
- `invoice_2024_01.pdf` → `/home/user/documents/invoices/`
- `invoice_2024_02.xlsx` → Stays in dump (doesn't match suffix)
- `report_quarterly.pdf` → `/home/user/documents/reports/`
- `report_annual.docx` → `/home/user/documents/reports/`
- `photo.jpg` → `/home/user/images/`
- `random.txt` → Stays in dump (no matching rule)

---

## Behavior

- Files are moved (not copied) to destination directories
- Destination directories are created automatically if they don't exist
- If a file with the same name exists in the destination, the operation is skipped
- Only the first matching destination rule is applied per file
- Directories in the dump folder are ignored
- Detailed logs show each file operation and a summary at the end

## Error Handling

The script will:
- Skip files that can't be moved and continue with others
- Log all errors for review
- Provide a summary of successful and failed operations
- Exit with an error if the dump directory doesn't exist or config is invalid

---

## Development & Contributing

### Setting Up a Homebrew Tap

This guide will help you set up a Homebrew tap so users can install `prefix` using `brew install`.

#### Option 1: Using a Homebrew Tap (Recommended)

A Homebrew tap is a GitHub repository containing Homebrew formulas. This is the easiest way to distribute your package.

**Step 1: Create a GitHub Repository for Your Tap**

1. Create a new GitHub repository named `homebrew-prefix` (or `homebrew-<your-tap-name>`)
   - The `homebrew-` prefix is a Homebrew convention
   - Make it public (Homebrew taps must be public)

2. Initialize the repository:
   ```bash
   mkdir homebrew-prefix
   cd homebrew-prefix
   git init
   ```

**Step 2: Prepare the Formula**

1. Copy the formula file to your tap repository:
   ```bash
   cp Formula/prefix.rb /path/to/homebrew-prefix/Formula/prefix.rb
   ```

2. Edit `Formula/prefix.rb` and update:
   - Replace `YOUR_USERNAME` with your GitHub username
   - Replace `v1.0.0` with your actual version tag
   - Replace `YOUR_SHA256_CHECKSUM_HERE` with the SHA256 of your release tarball
   - Update the `homepage` URL if needed

3. To get the SHA256 checksum of a release:
   ```bash
   # Download the release tarball and calculate checksum
   curl -L https://github.com/YOUR_USERNAME/prefix/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```

**Step 3: Create a Release on GitHub**

1. Create a git tag for your release:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. This will trigger your GitHub Actions workflow to create a release with binaries.

3. GitHub will also create a source tarball automatically at:
   `https://github.com/YOUR_USERNAME/prefix/archive/refs/tags/v1.0.0.tar.gz`

**Step 4: Commit and Push the Formula**

```bash
cd /path/to/homebrew-prefix
git add Formula/prefix.rb
git commit -m "Add prefix formula"
git remote add origin https://github.com/YOUR_USERNAME/homebrew-prefix.git
git push -u origin main
```

**Step 5: Test the Installation**

Users can now install your package with:

```bash
brew tap YOUR_USERNAME/prefix
brew install prefix
```

Or in one command:
```bash
brew install YOUR_USERNAME/prefix/prefix
```

#### Option 2: Local Installation (For Testing)

You can test the formula locally before setting up the tap:

```bash
# Install from local formula file
brew install --build-from-source Formula/prefix.rb

# Or create a local tap
mkdir -p $(brew --repository)/Library/Taps/YOUR_USERNAME/homebrew-prefix/Formula
cp Formula/prefix.rb $(brew --repository)/Library/Taps/YOUR_USERNAME/homebrew-prefix/Formula/
brew install YOUR_USERNAME/prefix/prefix
```

#### Option 3: Submit to Homebrew Core (Advanced)

If your project becomes popular, you can submit it to the official Homebrew core repository. This allows users to install with just `brew install prefix` without needing a tap.

Requirements:
- Project must be stable and maintained
- Must have at least 30 stars on GitHub
- Must have been tagged for at least 30 days
- Must have a clear license

See: https://docs.brew.sh/Adding-Software-to-Homebrew

#### Formula Customization

**Using Pre-built Binaries (Alternative):**

If you want to use the pre-built binaries from GitHub releases instead of building from source, you can modify the formula:

```ruby
def install
  # Download the appropriate binary for the system
  if Hardware::CPU.intel?
      bin_name = "prefix-macos-amd64"
    else
      bin_name = "prefix-macos-arm64"
    end
    
    # Download from GitHub release
    url = "https://github.com/YOUR_USERNAME/prefix/releases/download/v#{version}/#{bin_name}"
    system "curl", "-L", "-o", bin/"prefix", url
    chmod 0755, bin/"prefix"
  
  pkgshare.install "config.example.yaml"
end
```

**Adding Dependencies:**

If your project needs additional system dependencies, add them to the formula:

```ruby
depends_on "some-package"
```

**Updating the Formula:**

When you release a new version:

1. Update the `url` and `sha256` in the formula
2. Update the version tag
3. Commit and push the changes
4. Users can update with: `brew upgrade prefix`

**Example Complete Formula (Using Source Build):**

Here's a complete example with all fields filled in (replace with your actual values):

```ruby
class Prefix < Formula
  desc "Automatically organizes files from a dump directory based on filename patterns"
  homepage "https://github.com/johndoe/prefix"
  url "https://github.com/johndoe/prefix/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "abc123def456..." # Get this from: curl -L <url> | shasum -a 256
  license "MIT"
  head "https://github.com/johndoe/prefix.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-ldflags=-s -w", "-o", bin/"prefix", "."
    pkgshare.install "config.example.yaml"
  end

  test do
    assert_match "File organizer starting", shell_output("#{bin}/prefix 2>&1", 1)
  end

  def caveats
    <<~EOS
      To get started:
      1. Create config directory: mkdir -p ~/.config/prefix
      2. Copy the example config: cp #{pkgshare}/config.example.yaml ~/.config/prefix/prefix.yaml
      3. Edit ~/.config/prefix/prefix.yaml with your dump directory and destinations
      3. Run: prefix
    EOS
  end
end
```

**Troubleshooting:**

- **Formula fails to install**: Check that the URL and SHA256 are correct, verify the GitHub release exists, check Homebrew logs: `brew install --verbose prefix`
- **Binary not found**: Ensure the binary is built correctly, check that `bin/"prefix"` path is correct
- **Config file not found**: Verify `config.example.yaml` exists in the repository, check the `pkgshare.install` path

---

### Creating Releases

This guide explains how to create version tags and get the SHA256 checksum needed for your Homebrew formula.

#### Overview

When you create and push a git tag, two things happen:
1. **GitHub automatically creates a source tarball** at: `https://github.com/USERNAME/prefix/archive/refs/tags/v1.0.0.tar.gz`
2. **Your GitHub Actions workflow** builds binaries and creates a release

For Homebrew, you need the **SHA256 checksum of the source tarball** (not the binaries).

#### Step-by-Step Process

**Step 1: Create a Version Tag**

Version tags should follow semantic versioning (e.g., `v1.0.0`, `v1.0.1`, `v2.0.0`).

```bash
# Make sure you're on the main branch and everything is committed
git checkout main
git pull origin main

# Create an annotated tag (recommended)
git tag -a v1.0.0 -m "Release version 1.0.0"

# Or create a lightweight tag (simpler)
git tag v1.0.0
```

**Annotated vs Lightweight Tags:**
- **Annotated tags** (`-a`): Store extra metadata (author, date, message) - recommended
- **Lightweight tags**: Just a pointer to a commit - simpler but less info

**Step 2: Push the Tag to GitHub**

```bash
# Push a single tag
git push origin v1.0.0

# Or push all tags at once
git push origin --tags
```

**Step 3: Wait for GitHub Actions**

After pushing the tag:
1. Go to your GitHub repository
2. Click on the **"Actions"** tab
3. You'll see a workflow run triggered by the tag push
4. Wait for it to complete (usually 5-10 minutes)
5. Once complete, go to **"Releases"** tab - you'll see a new release

**Step 4: Get the SHA256 Checksum**

GitHub automatically creates a source tarball when you push a tag. The URL format is:
```
https://github.com/USERNAME/prefix/archive/refs/tags/v1.0.0.tar.gz
```

**Method 1: Using curl and shasum (macOS/Linux)**
```bash
# Replace USERNAME and VERSION with your values
curl -L https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
```

**Method 2: Download first, then calculate**
```bash
# Download the tarball
curl -L -o prefix-v1.0.0.tar.gz https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz

# Calculate checksum
shasum -a 256 prefix-v1.0.0.tar.gz

# Clean up
rm prefix-v1.0.0.tar.gz
```

**Method 3: Using openssl (alternative)**
```bash
curl -L https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz | openssl dgst -sha256
```

**Method 4: Using Homebrew's built-in tool**
```bash
# Homebrew has a built-in command for this
brew fetch --build-from-source https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz
# This will show the SHA256 in the output
```

**Step 5: Update Your Formula**

Once you have the checksum, update `Formula/prefix.rb`:

```ruby
url "https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz"
sha256 "abc123def456..."  # Paste your checksum here (without spaces)
```

#### Where to Find the Checksum

**Option 1: Calculate it yourself (Recommended)**
Use the commands above to calculate from the GitHub tarball URL.

**Option 2: Check GitHub Release Page**
1. Go to: `https://github.com/shubhdevelop/prefix/releases/tag/v1.0.0`
2. Look for "Source code" download
3. Right-click → Copy link
4. Use that URL with the curl command above

**Option 3: Use the Helper Script**
Use the script `create-release.sh` that automates this process:
```bash
./create-release.sh v1.0.0
```

#### Example: Complete Release Process

Here's a complete example for releasing v1.0.0:

```bash
# 1. Make sure everything is committed
git status
git add .
git commit -m "Prepare for v1.0.0 release"

# 2. Create and push tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 3. Wait 5-10 minutes for GitHub Actions to complete
#    (Check Actions tab on GitHub)

# 4. Get SHA256 checksum
curl -L https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256

# Output will look like:
# abc123def4567890abcdef1234567890abcdef1234567890abcdef1234567890  -

# 5. Copy the checksum (first part, without the "  -" at the end)
# 6. Update Formula/prefix.rb with the checksum
```

#### Verifying the Checksum

After updating your formula, you can verify it works:

```bash
# Test the formula locally
brew install --build-from-source Formula/prefix.rb

# Or check if Homebrew can fetch it
brew fetch --build-from-source https://github.com/shubhdevelop/prefix/archive/refs/tags/v1.0.0.tar.gz
```

#### Common Issues

**Issue: Tag already exists**
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0

# Create new tag
git tag v1.0.0
git push origin v1.0.0
```

**Issue: Checksum doesn't match**
- Make sure you're using the source tarball URL, not the release binaries
- Verify the tag exists on GitHub
- Try downloading and calculating again
- Make sure there are no extra spaces in the checksum

**Issue: GitHub Actions didn't create release**
- Check Actions tab for errors
- Verify workflow file is in `.github/workflows/`
- Check that tag starts with "v" (required by workflow trigger)
- Ensure you have `contents: write` permission

#### Quick Reference

**Tag URL format:**
```
https://github.com/USERNAME/REPO/archive/refs/tags/VERSION.tar.gz
```

**Commands:**
```bash
# Create tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Push tag
git push origin v1.0.0

# Get checksum
curl -L https://github.com/USERNAME/REPO/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256

# List all tags
git tag -l

# Delete tag (if needed)
git tag -d v1.0.0
git push origin --delete v1.0.0
```

---

### GitHub Actions Workflow

This project includes a GitHub Actions workflow to automatically build macOS executables using a matrix build strategy.

#### Workflow: `build.yaml`

Uses a build matrix to build for both macOS architectures.

#### Supported Platforms

The workflow builds for:
- **macOS**: amd64 (Intel), arm64 (Apple Silicon/M1/M2/M3)
- **Linux**: amd64, arm64

#### Triggers

The workflows run on:
1. **Pull requests to main** - Validates builds work before merging
2. **Git tags** (v*) - Creates a GitHub Release with all binaries
3. **Manual trigger** - Can be run from GitHub Actions tab

#### Usage

**For Regular Development:**

1. Create a pull request to `main` branch
2. GitHub Actions will automatically build all platforms
3. Review build status in the PR checks
4. Download artifacts from the Actions tab if needed
5. Once PR is merged, changes are in main

**For Releases:**

1. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions will:
   - Build binaries for macOS (Intel and Apple Silicon) and Linux (amd64 and arm64)
   - Generate SHA256 checksums
   - Create a GitHub Release
   - Attach all binaries and checksums to the release

**Manual Trigger:**

1. Go to the "Actions" tab in your repository
2. Select the workflow
3. Click "Run workflow"
4. Choose the branch and click "Run workflow"

#### Build Artifacts

After each build, you can download artifacts from:
- Repository → Actions → Select workflow run → Artifacts section

For tagged releases, binaries are available in:
- Repository → Releases section

#### Build Options

The builds use these optimizations:
- `-trimpath`: Remove file system paths for reproducible builds
- `-ldflags="-s -w"`: Strip debug info to reduce binary size
- `CGO_ENABLED=0`: Static linking for better portability

#### File Naming Convention

Binaries are named as:
```
prefix-{os}-{arch}
```

Examples:
- `prefix-macos-amd64` (Intel Macs)
- `prefix-macos-arm64` (Apple Silicon: M1, M2, M3)
- `prefix-linux-amd64` (Linux x86_64)
- `prefix-linux-arm64` (Linux ARM64)

#### Requirements

No setup needed! The workflow:
- Set up Go automatically
- Download dependencies
- Build for macOS and Linux (multiple architectures)
- Upload artifacts

#### Permissions

The workflow requires `contents: write` permission to create releases. This is already configured in the workflow files.

#### Customization

**Adding More Platforms:**

To add Windows or other platforms, add to the matrix in `build.yaml`:
```yaml
- arch: amd64
  goos: windows
  goarch: amd64
  output: prefix-windows-amd64.exe
```

**Changing Go Version:**

Update the `go-version` in the "Set up Go" step:
```yaml
- name: Set up Go
  uses: actions/setup-go@v5
  with:
    go-version: '1.22'  # Change this
```

#### Troubleshooting

**Build Fails:**
- Check the Actions tab for error logs
- Ensure `go.mod` is committed
- Verify all dependencies are available

**Release Not Created:**
- Ensure you pushed a tag starting with 'v'
- Check workflow has `contents: write` permission
- Verify GITHUB_TOKEN has necessary permissions

**Artifacts Not Uploading:**
- Check artifact names are unique
- Ensure file paths are correct
- Verify retention days are set (default: 5)

---

## License

[Add your license here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
