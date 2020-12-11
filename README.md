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

---
### What is the Cloudogu EcoSystem?
The Cloudogu EcoSystem is an open platform, which lets you choose how and where your team creates great software. Each service or tool is delivered as a Dogu, a Docker container. Each Dogu can easily be integrated in your environment just by pulling it from our registry. We have a growing number of ready-to-use Dogus, e.g. SCM-Manager, Jenkins, Nexus, SonarQube, Redmine and many more. Every Dogu can be tailored to your specific needs. Take advantage of a central authentication service, a dynamic navigation, that lets you easily switch between the web UIs and a smart configuration magic, which automatically detects and responds to dependencies between Dogus. The Cloudogu EcoSystem is open source and it runs either on-premises or in the cloud. The Cloudogu EcoSystem is developed by Cloudogu GmbH under [MIT License](https://cloudogu.com/license.html).

### How to get in touch?
Want to talk to the Cloudogu team? Need help or support? There are several ways to get in touch with us:

* [Website](https://cloudogu.com)
* [myCloudogu-Forum](https://forum.cloudogu.com/topic/34?ctx=1)
* [Email hello@cloudogu.com](mailto:hello@cloudogu.com)

---
&copy; 2020 Cloudogu GmbH - MADE WITH :heart:&nbsp;FOR DEV ADDICTS. [Legal notice / Impressum](https://cloudogu.com/imprint.html)
