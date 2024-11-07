package main

// Jun Su Lee ( junsulee@au1.ibm.com )
// To find an unused IP address in the same subnet. Need this for my few projects especially finding a VIP for a cluster.

import (
	"flag"
	"fmt"
	"net"
	"os"
	"os/exec"

	"strconv"
)

var verbose bool // use for debug option

// ping checks if an IP address is reachable by sending a single ICMP packet.

func pingChk(ip string) bool {
	cmd := exec.Command("ping", "-c", "1", "-W", "1", ip)
	err := cmd.Run()
	return err == nil //return 'true' if no error
}

// findAvailableIP looks for an unused IP address in the same subnet as the given IP.
func findAvailableIP(ip net.IP, ipNet *net.IPNet) (string, error) {
	// Iterate through each IP in the subnet range.

	//ip.Mask(ipNet.Mask) : apply the mask and the 1st address of the network. ip is reset to the 1st network.
	//  on mac, it gets 1st ip address fine but for Linux x86 compilation, it gets 1st broadcase IP.
	//  Therefore, put this out of for loop and go to nextIP as the start point to avoid getting the broadcase IP.
	ip.Mask(ipNet.Mask)
	nextIP(ip)

	/*
	 In Go, omitting the initialization statement in a for loop is valid and can be useful for readability or specific logic.
	 When the initialization statement is omitted in this code, ip retains its current state and doesn’t need to be reset within the loop itself,
	 as it's already correctly set before the loop starts
	*/
	for ; ipNet.Contains(ip); nextIP(ip) { // //'Contains' reports whether the network includes ip. Loop until nextIP is stil within the subnet
		if !pingChk(ip.String()) { // not true means. ping failed. meaning the ip is not used.
			return ip.String(), nil
		}
	}
	return "", fmt.Errorf("no available IP found in the subnet")
}

// nextIP : increments the given IP address to the next address.
func nextIP(ip net.IP) {
	// type IP []byte. a slice of bytes. IPv4 is 4 bytes. 1 byte is 8 bits (0~255), 0xFF(255)
	for j := len(ip) - 1; j >= 0; j-- { // len(ip) is 4. 4-1=3. As IP is the bytes array [0,1,2,3], the loop starts at the end of the byte slice.
		ip[j]++        // next value in the last byte slice.  xxx.xxx.xxx.here
		if ip[j] > 0 { // if the next value is greater than zero, break.
			break
		}
	}
}

func main() {

	// to add verbose mode option
	// Using flag.BoolVar, the program now supports -v and --verbose as options for enabling debug messages.
	flag.BoolVar(&verbose, "v", false, "enable verbose output")
	flag.BoolVar(&verbose, "verbose", false, "enable verbose output")
	flag.Parse()

	// use os.Exit(X) so that caller bash shell check the return value
	// Code before adding verbose option
	/*
		if len(os.Args) < 3 {
			fmt.Println("")
			fmt.Println("Find an available IP address within the subnet of the IP/subnet mask (bug report to junsulee@au1.ibm.com) ")
			fmt.Println("")
			fmt.Println("Usage: " + os.Args[0] + "  <IP_ADDRESS> <SUBNET_PREFIX_LENGTH>")
			fmt.Println("ex) " + os.Args[0] + " 192.168.1.114 24")

			os.Exit(1)
		}

		curAddr := os.Args[1]
		subnetPrefix := os.Args[2]
	*/

	if len(flag.Args()) < 2 {

		fmt.Println("")
		fmt.Println("Find an available IP address within the subnet of the IP/subnet mask (bug report to junsulee@au1.ibm.com) ")
		fmt.Println("")
		fmt.Println("Usage: " + os.Args[0] + " [-v|--verbose]  <IP_ADDRESS> <SUBNET_PREFIX_LENGTH>")
		fmt.Println("ex) " + os.Args[0] + " 192.168.1.114 24\n")

		os.Exit(1)

	}
	curAddr := flag.Arg(0)
	subnetPrefix := flag.Arg(1)

	if verbose {
		fmt.Println("Looking for an unused IP address within the same subnet of the given IP/subnet mask : " + curAddr + "/" + subnetPrefix)
	}

	// Validate the subnet prefix value
	iSubnetPrefix, err := strconv.Atoi(subnetPrefix) // change string to integer
	if err != nil {
		fmt.Println("Error converting the subnet prefix: ", err)
		os.Exit(1)
	} else if iSubnetPrefix < 0 || iSubnetPrefix > 32 {
		fmt.Println("Invalid subnet prefix length. Reference range ( 0 ~ 32 )")
		os.Exit(1)
	} else {
		if verbose {
			fmt.Println("Input Subnet Prefix validation successful: ", iSubnetPrefix)
		}
	}

	// Combine IP address and subnet prefix length to create CIDR notation.
	// CIDR notation consists of an IP address followed by a forward slash and a number (the prefix length)
	cidr := fmt.Sprintf("%s/%d", curAddr, iSubnetPrefix)
	if verbose {
		fmt.Println("cidr : ", cidr)
	}

	ip, ipNet, err := net.ParseCIDR(cidr) // func ParseCIDR(s string) (ip *net.IP, ipNet *net.IPNet, err error)
	// https://pkg.go.dev/net@go1.23.3#ParseCIDR
	if err != nil {
		fmt.Println("Invalid IP Address or Subnet mask: ", err)
		os.Exit(1)
	}
	if verbose {
		fmt.Println("ip " + ip.String() + " is in the network " + ipNet.String())
	}

	freeIP, err := findAvailableIP(ip, ipNet)

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	if verbose {
		fmt.Print("Got the first free IP address : ")
	}
	fmt.Println(freeIP)

	os.Exit(0)

}
