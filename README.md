# Usage Guide

Follow the steps below to install and use the toolkit:

---

## Installed Tools List

- **Subdomain Enumeration:** subfinder, assetfinder, findomain, shuffledns, puredns  
- **DNS Tools:** dnsx, massdns, dnsdumpster  
- **HTTP/Web Tools:** httpx, httprobe, hakrawler, katana, waybackurls, gau, ffuf, wfuzz, whatweb, nikto, dirsearch, Corsy, CRLF-Injection-Scanner, smuggles  
- **Vulnerability Scanners:** nuclei, wpscan, CMSeeK  
- **Source Code Security:** SecretFinder, trufflehog, gitleaks  
- **403 Bypass:** bypass-403, nomore403, 4-ZERO-3  
- **Support/Dependency:** ruby-full, python3-pip, git, curl, unzip, pipx, jq  
- **Payloads:** SecLists

---

## 1. Install Tools

Run the following command to install all tools:
```sh
zsh ./install.sh
```
If you haven't installed `zsh`, run the following command on Linux:

```sh
sudo apt update && sudo apt install zsh -y
```

---

## 2. Recon (Subdomain enumeration, crawling, URL grouping, ...)

You can use the alias or run the script directly:

```sh
# Scan a single domain
auto_recon -u example.com
# Or
zsh ./recon.sh -u example.com

# Scan multiple domains from a file (one domain per line)
auto_recon -i domain_list.txt
# Or
zsh ./recon.sh -i domain_list.txt
```

---

## 3. Scan (Cors, CRLF, ...)

```sh
# Scan a single domain
auto_scan -u example.com
# Or
zsh ./scan.sh -u example.com

# Scan multiple domains from a file
auto_scan -i domain_list.txt
# Or
zsh ./scan.sh -i domain_list.txt
```

---

## 4. Update Tools

```sh
auto_update
# Or
zsh ./update.sh
```

---

**Note:**  

- Make sure all required tools are installed and updated before running scans.