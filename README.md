# Fedora WSL Installer
## Introduction 
This installer will create a usable WSL-based Fedora version to install in your Windows.
  
## Goals
The goal of this project is to enable:

* A user to easily install as base of a Fedora as possible into WSL2

## User Installation
1. Go to the [releases page](https://github.com/greg-hellings/FedoraWSL/releases).

2. If you've never installed this package before, install download the Certificate File and add it as a trusted
  certificate authority on your system

3. Download and install the appx file there and install it. Installation should automatically create a default user with
  sudo access within the environment, as well as prompt you to update the password of that user.

4. Use the FedoraWSL app installed on your system to launch a WSL instance

## Upgrades
If you already have Fedora side-loaded through another mechanism, this will not affect that install.

If you already have an existing version of this system and want to upgrade the Fedora version, use built-in tools in Fedora to upgrade. Upgrading this app from
one version of Fedora to another will not cause your system to upgrade the installed Fedora version. You will either need to use Fedora packaging tools or do a
complete uninstall/reinstall to get the upgraded Fedora.

If you need to start fresh, you will need to uninstall the FedoraWSL app, then you can re-install any version of this app that you want. A reboot may be required
between uninstall and reinstall.

# Developing the Installer
## Getting Started
0. Prepare your system
    * Install Visual Studio Community along with the "Universal Windows Platform development" and Windows 10 SDK versions
    * Enable Developer Mode in Start -> Settings -> Update & Security -> For Developers
    * Enable WSL
        * Start Menu -> Manage Optional Features, search for Windows Subsystem for Linux and press OK
        * Open PowerShell as Administrator, type `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux`, and restart as necessary

1. Generate a test certificate by running this PowerShell script
```powershell
$Subject = "CN=Your-appxmanifest-publisher"
$Store = "Cert:\CurrentUser\My"

# Delete old certificate
Get-ChildItem $Store | Where-Object { $_.Subject -match $Subject } | Remove-Item

# Create new certificate
New-SelfSignedCertificate -Type Custom -Subject $Subject -KeyUsage DigitalSignature -FriendlyName "Fedora Test Certificate" -CertStoreLocation $Store -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
```
    * Copy the Thumbprint
    * Open DistroLauncher-Appx\DistroLauncher-Appx.vcxproj and replace the PackageCertificateThumbprint contents with the value of what you just generated
    * Export it? Somehow?
    * Open Certificate Manager, go to Trusted Root Certification Authorities, right click, All Tasks... -> Import
    * Import your exported certificate file

3. Create the install.tar.gz file by running ./get\_sources.sh
    * Requires podman installed and working
    * Creates install.tar.gz in the root of this project

4. Update the version in DistroLauncher-Appx\FedoraWSL.appxmanifest if you are bumping beyond the current version.

5. Execute .\build.bat

6. Find the installer under x64\Debug\DistroLauncher-Appx
    * Several files might be created all with the .appx extension
    * The installer will be the one whose name ends with x64\_Debug.appx

## Contents
* `fedora.exe`
  - Launches the user's default shell in the user's home directory.

* `fedora.exe install [--root]`
  - Install the distribution and do not launch the shell when complete.
    - `--root`: Do not create a user account and leave the default user set to root.

* `fedora.exe run <command line>`
  - Run the provided command line in the current working directory. If no command line is provided, the default shell is launched.
  - Everything after `run` is passed to WslLaunchInteractive.

* `fedora.exe config [setting [value]]`
  - Configure settings for this distribution.
  - Settings:
    - `--default-user <username>`: Sets the default user to <username>. This must be an existing user.

* `fedora.exe help`
  - Print usage information.

## Launcher Outline
This is the basic flow of how the launcher code is set up.

1. If the distribution is not registered with WSL, register it. Registration extracts the tar.gz file that is included in your distribution appx.
2. Once the distro is successfully registered, any other pre-launch setup is performed in `InstallDistribution()`. This is where distro-specific setup can be performed. As an example, the reference implementation creates a user account and sets this user account as the default for the distro.
    - Note: The commands used to query and create user accounts in this reference implementation are Ubuntu-specific; change as necessary to match the needs of your distro.
3. Once the distro is configured, parse any other command-line arguments. The details of these arguments are described above, in the [Introduction](#Introduction).

## Project Structure
The distro launcher is comprised of two Visual Studio projects - `launcher` and `DistroLauncher-Appx`. The `launcher` project builds the actual executable that is run when a user launches the app. The `DistroLauncher-Appx` builds the distro package with all the correctly scaled assets and other dependencies. Code changes will be built in the `launcher` project (under `DistroLauncher/`). Manifest changes are applied in the `DistroLauncher-Appx` project (under `DistroLauncher-Appx/`). 


## Setting up your Windows Environment
You will need a Windows environment to test that your app installs and works as expected. To set up a Windows environment for testing you can follow the steps from the [Windows Dev Center](https://developer.microsoft.com/en-us/windows/downloads/virtual-machines).

> Note: If you are using Hyper-V you can use the new VM gallery to easily spin up a Windows instance.

Also, to allow your locally built distro package to be manually side-loaded, ensure you've enabled Developer Mode in the Settings app (sideloading won't work without it). 

## Build and Test

To help building and testing the DistroLauncher project, we've included several scripts to automate some tasks. You can either choose to use these scripts from the command line, or work directly in Visual Studio, whatever your preference is. 

> **Note**: some sideloading/deployment steps don't work if you mix and match Visual Studio and the command line for development. If you run into errors while trying to deploy your app after already deploying it once, the easiest step is usually just to uninstall the previously sideloaded version and try again. 

### Building the Project (Command line):
To compile the project, you can simply type `build` in the root of the project to use MSBuild to build the solution. This is useful for verifying that your application compiles. It will also build an appx for you to sideload on your dev machine for testing.

> Note: We recommend that you build your launcher from the "Developer Command Prompt for Visual Studio" which can be launched from the start menu. This command-prompt sets up several path and environment variables to make building easier and smoother.

`build.bat` assumes that MSBuild is installed at one of the following paths:
`%ProgramFiles*%\MSBuild\14.0\bin\msbuild.exe` or
`%ProgramFiles*%\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe` or
`%ProgramFiles*%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe`.
and other, similar, paths for Visual Studio 2019.

If that's not the case, then you will need to modify that script.

Once you've completed the build, the packaged appx should be placed in a directory like `FedoraWSL\x64\Release\DistroLauncher-Appx` and should be named something like `DistroLauncher-Appx_1.0.0.0_x64.appx`. Simply double click that appx file to open the sideloading dialog. 

You can also use the PowerShell cmdlet `Add-AppxPackage` to register your appx:
``` powershell
powershell Add-AppxPackage x64\Debug\DistroLauncher-Appx\DistroLauncher-Appx_1.0.0.0_x64_Debug.appx
```

### Building Project (Visual Studio):

You can also easily build and deploy the distro launcher from Visual Studio. To sideload your appx on your machine for testing, all you need to do is right-click on the "Solution (DistroLauncher)" in the Solution Explorer and click "Deploy Solution". This should build the project and sideload it automatically for testing.

### Installing & Testing
You should now have a finished appx sideloaded on your machine for testing.

To install your distro package, double click on the signed appx and click "Install". Note that this only installs the appx on your system - it doesn't unzip the tar.gz or register the distro yet. 

You should now find your distro in the Start menu, and you can launch your distro by clicking its Start menu tile or executing your distro from the command line by entering its name into a Cmd/PowerShell Console.

When you first run your newly installed distro, it is unpacked and registered with WSL. This can take a couple of minutes while all your distro files are unpacked and copied to your drive. 

Once complete, you should see a Console window with your distro running inside it.

### Publishing
If you are a distro vendor and want to publish  your distro to the Windows store, you will need to complete some pre-requisite steps to ensure the quality and integrity of the WSL distro ecosystem, and to safeguard our users:

#### Publishing Pre-Requisites
1. Reach out to the WSL team to introduce your distro, yourself, and your team
1. Agree with the WSL team on a testing and publishing plan
1. Complete any required paperwork
1. Sign up for an "Company" Windows Developer Account https://developer.microsoft.com/en-us/store/register. 
    > Note: This can take a week or more since you'll be required to confirm your organization's identity with an independent verification service via email and/or telephone.

#### Publishing Code changes
You'll also need to change a few small things in your project to prepare your distro for publishing to the Windows store

1. In your appxmanifest, you will need to change the values of the Identity field to match your identity in your Windows Store account:

``` xml
<Identity Name="1234YourCompanyName.YourAppName"
          Version="1.0.1.0"
          Publisher="CN=12345678-045C-ABCD-1234-ABCDEF987654"
          ProcessorArchitecture="x64" />
```

  > **NOTE**: Visual Studio can update this for you! You can do that by right-clicking on "DistroLauncher-Appx (Universal Windows)" in the solution explorer and clicking on "Store... Associate App with the Store..." and following the wizard. 

2. You will either need to run `build rel` from the command line to generate the Release version of your appx or use Visual Studio directly to upload your package to the store. You can do this by right-clicking on "DistroLauncher-Appx (Universal Windows)" in the solution explorer and clicking on "Store... Create App Packages..." and following the wizard.

Also, make sure to check out the [Notes for uploading to the Store](https://github.com/Microsoft/WSL-DistroLauncher/wiki/Notes-for-uploading-to-the-Store) page on our wiki for more information.
