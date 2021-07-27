# Ruby in InfoAsset Manager

This directory contains examples of tasks that can be performed using Ruby scripts. These are stored in sub-directories prefixed with a counter and a brief README.md description. They can be either IAM UI scripts or IAMExchange scripts.

## UI scripts
Scripts with `UI` within the name are run from within the InfoAsset Manager interface. A quick way to get started is:
1. Create a `test.rb` file in a known location, preferably close to the drive root and without special characters in the path.
2. Create an Action which points at the `test.rb` script.
3. Copy paste the code you are testing from GitHub into this file using a plain-text editor.
4. Run it in IAM in a relevant network using: Network > Run Ruby Script....