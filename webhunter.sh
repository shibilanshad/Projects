#!/bin/bash


RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

banner() {
    echo -e "${GREEN}"
    echo "======================================="
    echo "        WebHunter - Pentest Toolkit     "
    echo "         Created by Shibil Anshad       "
    echo "======================================="
    echo -e "${NC}"
}

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ 'jq' is required but not installed. Install it with: sudo apt install jq${NC}"
    exit 1
fi

if ! command -v nmap &> /dev/null; then
    echo -e "${RED}❌ 'nmap' is not installed. Install it with: sudo apt install nmap${NC}"
    exit 1
fi

if ! command -v dirb &> /dev/null; then
    echo -e "${RED}❌ 'dirb' is not installed. Install it with: sudo apt install dirb${NC}"
    exit 1
fi



menu() {
    echo -e "${BLUE}Choose an option:${NC}"
    echo "1. Subdomain Finder"
    echo "2. Port Scanner"
    echo "3. Directory Bruteforce"
    echo "4. XSS/SQLi Basic Test"
    echo "5. Admin Panel Finder"
    echo "0. Exit"
}


subdomain_finder() {
    read -p "Enter domain (e.g., example.com): " domain

    if [[ -z "$domain" ]]; then
        echo -e "${RED}❌ Domain input cannot be empty.${NC}"
        return
    fi

    echo -e "${BLUE}🔍 Searching for subdomains of $domain...${NC}"

    response=$(curl -s --max-time 10 "https://crt.sh/?q=%25.$domain&output=json")
    if [[ -z "$response" || "$response" == "[]" ]]; then
        echo -e "${RED}❌ No subdomains found or invalid domain.${NC}"
        return
    fi

    echo "$response" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > subdomains.txt

    echo -e "${GREEN}✅ Found $(wc -l < subdomains.txt) subdomains. Saved to subdomains.txt${NC}"
    cat subdomains.txt
}


port_scanner() {
	read -p "Enter target IP or domain :" target
	echo -e "${BLUE}⚡ Scanning ports on $target...${NC}"

	if [[ -z "$target" ]]; then
        echo -e "${RED}❌ Input cannot be empty.${NC}"
        return
    fi

    # Ping test to check if target is alive
    ping -c 1 -W 2 $target &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Target $target is not reachable. Please check the IP/domain.${NC}"
        return
    fi

    # Quick scan with service detection
    nmap -sS -sV -T4 $target -oN portscan_$target.txt

    echo -e "${GREEN}✅ Scan complete! Results saved in: portscan_$target.txt${NC}"
    cat portscan_$target.txt | grep "open"
}

dir_bruteforce() {
    read -p "Enter target URL (e.g., http://example.com): " url
    wordlist="/usr/share/wordlists/dirb/common.txt"

    echo -e "${BLUE}🔍 Bruteforcing directories on $url...${NC}"

    if [ ! -f "$wordlist" ]; then
        echo -e "${RED}❌ Wordlist not found: $wordlist${NC}"
        echo "You can install it using: sudo apt install dirb"
        return
    fi

    dirb $url $wordlist -o dirb_result.txt

    echo -e "${GREEN}✅ Directory scan complete! Results saved to dirb_result.txt${NC}"
    cat dirb_result.txt | grep "CODE:200"
}

xss_sqli_test() {
    read -p "Enter vulnerable-looking URL (with parameter) [e.g., http://site.com/page.php?id=1]: " target

    echo -e "${BLUE}🧪 Testing for XSS and SQLi on $target...${NC}"

    # XSS Payload
    xss_payload="<script>alert(1)</script>"
    xss_response=$(curl -s "$target$xss_payload")

    if echo "$xss_response" | grep -q "$xss_payload"; then
        echo -e "${GREEN}⚠️ Reflected XSS Detected!${NC}"
    else
        echo -e "${RED}❌ No XSS reflection.${NC}"
    fi

    # SQLi Payload
    sqli_payload="' OR 1=1--"
    sqli_response=$(curl -s "$target$sqli_payload")

    if echo "$sqli_response" | grep -E -i "SQL syntax|mysql_fetch|ORA-00933|Warning.*mysql|You have an error"; then
        echo -e "${GREEN}⚠️ Possible SQL Injection Detected!${NC}"
    else
        echo -e "${RED}❌ No SQL error detected.${NC}"
    fi
}

admin_finder() {
    read -p "Enter base URL (e.g., http://example.com): " url
    wordlist="wordlists/admin-panels.txt"

    if [ ! -f "$wordlist" ]; then
        echo -e "${RED}❌ Wordlist not found: $wordlist${NC}"
        echo "Creating basic wordlist..."
        mkdir -p wordlists
        cat <<EOF > $wordlist
admin
admin/login
adminpanel
admin_area
cpanel
administrator
login
backend
EOF
    fi

    echo -e "${BLUE}🔎 Bruteforcing admin panel paths...${NC}"
    while read path; do
        full_url="$url/$path"
        status=$(curl -s -o /dev/null -w "%{http_code}" "$full_url")
        if [ "$status" = "200" ]; then
            echo -e "${GREEN}[200] Found: $full_url${NC}"
        else
            echo -e "${RED}[$status] $full_url${NC}"
        fi
    done < "$wordlist"
}




banner 
menu

read -p "Enter choice :" choice
case $choice in
    1) subdomain_finder ;;
    2) port_scanner ;;
    3) dir_bruteforce ;;
    4) xss_sqli_test ;;
    5) admin_finder ;;
    0) echo "Exiting..." && exit 0 ;;
    *) echo "Invalid choice." ;;
esac







