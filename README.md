# About Project
This project is Part **1 of a 3**-part series exploring practical applications of network scanning and penetration testing concepts through automation.

The **goal** here was to take foundational knowledge of *scanning and *reconnaissance techniques and translate it into a working script

## Features
- Scans a target IP or a CIDR open ports for both TCP and UDP connect scanning 
- Identify running services, service versions, state services are in
- Display potential vulnerabilities using NSEs and Searchsploit
- Output scan results to a readable report
- Automate repetitives Nmap-style scans and Masscan that would have been manually run
- Automate Hydra after user provides necessary information
- Provide suggested list of command to search for information

## Tech Stack
 - **Language:** Bash 
 - **Tools referenced/wrapped:** Nmap,Masscan,Hydra,Metasploit, 
 - **Environment:** Developed and tested on Kali Linux

## Installation

1. Clone the repository:
```bash
   git clone https://github.com/Extremejoker/your-repo-name.git
   cd your-repo-name
```

2. Ensure required tools are installed (most come pre-installed on Kali Linux):
```bash
   sudo apt update
   sudo apt install nmap masscan hydra metasploit-framework
```

3. Make the script executable:
```bash
   chmod +x scriptname.sh
```

4. Run the script:
```bash
   ./scriptname.sh
```

## Usage

Run the script:

```bash
./scriptname.sh
```

**Hydra credential attacks:**
Place your wordlists in the same directory as the script before running. The script expects files named `user.lst` and `smaller.txt` (or update these filenames in the script to match your own lists):

```bash
hydra -L user.lst -P smaller.txt $USER_IP ssh
```

**Note:** This tool does not include wordlists — you must supply your own. Kali Linux includes common lists at `/usr/share/wordlists/` (e.g. `rockyou.txt`) that can be copied or renamed to match, or you can use custom lists relevant to your authorized test scope.


**Note:** This tool does not include wordlists. Common ones like `rockyou.txt` (built into Kali at `/usr/share/wordlists/`) or custom lists can be used. Ensure lists are relevant to your authorized test scope.

## Reason for Building
Security tooling is only useful if I understand what it's doing underneath. Building this script from theoretical concepts helped translate abstract knowledge (how scans work, what a pentest methodology looks like) into practical, functioning code while also saving time on tasks that would otherwise needed to be type from scratch repeatedly.

As someone currently working towards blue team and threat intelligence work, I believe in the importance of undrstanding  offensive **techniques** and **tools** firsthand. This project reflects my mindset of approaching security holistically by learning how attacks are built, not just how to detect them, in line with a purpose-driven "purple team" approach to analysis.

**Disclaimer:** This is to deepen my understanding of offensive security fundamentals. It's intended for learning, portfolio demonstration, and authorized testing only.


