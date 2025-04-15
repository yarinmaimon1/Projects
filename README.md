
PT Project – Automated Vulnerability Assessment Tool
Overview
PT_project.sh is a Bash script designed for penetration testing and security assessments. It automates network scanning, service enumeration, and vulnerability identification using Nmap, Masscan, Hydra, and SearchSploit. This tool helps evaluate SOC monitoring capabilities and identify security weaknesses.

Features
✔ Network Scanning – Uses Nmap and Masscan to detect open ports and services.
✔ Vulnerability Analysis – Employs SearchSploit to find known exploits for discovered services.
✔ Password Auditing – Leverages Hydra for brute-force attacks on SSH, FTP, RDP, and Telnet.
✔ Custom Wordlists – Supports user-imported lists or generates passwords dynamically using Crunch.
✔ Automated Logging & Reporting – Saves all findings for further analysis.
✔ Flexible Scanning Options – Provides Basic and Full scan modes for different depth levels.

Disclaimer
This tool is intended for ethical hacking and authorized security testing only. Unauthorized use against systems without explicit permission is illegal.

------------------------------------------------------
Forensic File Carving & Memory Analysis Script
Overview
This Bash script automates forensic file analysis by extracting hidden files, network data, and memory artifacts from disk images and memory dumps. It leverages Volatility, Binwalk, Foremost, and Bulk Extractor to identify critical evidence for digital forensics and incident response (DFIR).

Features
✔ File Carving – Uses Foremost and Binwalk to recover deleted or hidden files.
✔ Memory Analysis – Runs Volatility to extract processes, network connections, registry hives, and more.
✔ String Extraction – Searches for passwords, usernames, and executable file paths.
✔ Network Artifact Detection – Identifies PCAP files and extracts network data for further analysis.
✔ Automated Reporting – Generates a summary of findings and stores results in a ZIP file.

Disclaimer
This tool is designed for ethical forensic investigations and authorized security analysis only. Unauthorized use against systems without permission is illegal.
