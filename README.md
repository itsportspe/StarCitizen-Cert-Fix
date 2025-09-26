# StarCitizen-Cert-Fix
A portable, one-click PowerShell + CMD utility that automatically retrieves, exports, and installs the missing TLS certificate chain required for Star Citizen authentication — fixing common errors like CODE 19000 without needing Git Bash, OpenSSL, or manual certificate imports. Star Citizen 4.3.1

📜 Repository Name

StarCitizen-CertFix — Automatic TLS Certificate Fetcher & Importer for Star Citizen (No OpenSSL Required)

🧠 Short Description

A portable, one-click PowerShell + CMD utility that automatically retrieves, exports, and installs the missing TLS certificate chain required for Star Citizen authentication — fixing common errors like CODE 19000 without needing Git Bash, OpenSSL, or manual certificate imports.

📦 Overview

Star Citizen’s launcher sometimes fails to authenticate with the backend (often showing CODE 19000 or silently refusing to log in) because Windows does not trust the TLS certificate chain for *.cloudimperiumgames.com. This repository provides a fully automated solution to fetch and install those certificates.

The script connects directly to the backend server, retrieves the entire certificate chain (leaf, intermediate, and root), writes a .crt PEM bundle, and imports them into the correct Windows certificate stores — all with a single double-click.

✅ Features

🔐 Automatic certificate retrieval — No OpenSSL or Git Bash needed

🖥️ One-click installer — Double-click a .cmd file and everything runs

📁 Portable — Works from any folder (Desktop, Downloads, USB, etc.)

🪪 Automatic import — Installs intermediate and root certificates into Windows

🧪 Self-verifying — Generates a detailed log (StarCitizenCertFix.log)

🛠️ No admin setup — Just run, click “Yes” to UAC, and the fix is applied

🚀 Usage

Download or clone this repository.

Place Run_StarCitizenCertFix.cmd and get_and_import_cig_cert.ps1 in the same folder.

Right-click → Run as administrator on Run_StarCitizenCertFix.cmd.

Wait for the script to finish and then launch Star Citizen.

If successful, the script will report imported certificates and generate two files in the same directory:

cacert.crt — Full certificate bundle

StarCitizenCertFix.log — Import log with timestamps and chain info

🧪 Verified Results

❌ Before: Launcher failed to authenticate (CODE 19000)

✅ After: Launcher successfully logged in after one script execution

⚠️ Notes

The script checks if ISRG Root X1 is already trusted and skips it if present.

Works on Windows 10/11 with PowerShell 5.1+ (default on most systems).

Requires admin privileges for system-wide certificate import.
