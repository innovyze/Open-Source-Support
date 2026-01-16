# Copy Network Version

Copy a specific version/commit of a network to a new independent network (without commit history). This mimics the 'Copy' button that is available in the UI in the commit history window.

## Configuration

Edit the configuration section at the top of `EX_Script.rb`:

```ruby
DATABASE_PATH = nil              # Leave nil for most recent database
NETWORK_ID = 123                 # Required: ID of network to copy
NEW_NETWORK_NAME = "My Copy"     # Optional: Leave nil to use original name
COMMIT_ID = nil                  # Optional: Leave nil for latest commit
```

## Usage

1. Edit configuration values in the script
2. Run: `IExchange.exe --script=EX_Script.rb`

## How It Works

1. Branches from the specified commit
2. Copies the branch to create an independent network
3. Cleans up temporary branch
4. Validates the copied network

## Notes

- Creates truly independent network (not a branched network)
- Works with cloud, workgroup, and standalone databases
- Temporary branch is automatically deleted after copying
