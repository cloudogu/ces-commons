![Cloudogu logo](https://cloudogu.com/images/logo.png)

# Ces-commons
https://cloudogu.com

This package holds scripts, templates and configuration files for the Cloudogu EcoSystem.

## Add content

Content can be added to this package by placing the corresponding files inside one of the subfolders of `deb`.

* Configuration files and templates should be placed in a subfolder of `etc`.
* Scripts should be placed inside `/usr/local/bin/`.
* Make sure the scripts are executable.

## Building

To build a Debian package from this repository just execute `make`.
The package is generated and placed inside the `target` folder; a sha256sum is generated and signed.