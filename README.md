# axi4lite_ip_gen
Generates simple AXI4-lite IP for use in Vivado from JSON register specifications

## Dependencies
- Vivado (tested with 2021.1) installation with bin folder on path
- Vitis HLS (tested with 2021.1) installation with bin folder on path
- Bash-compatible shell - Git for Windows includes Git Bash
  - unzip command; see https://stackoverflow.com/a/49355978 for Windows

## Quickstart
If you are familiar enough with Vivado and Vitis then this may be all you need to know to get started. Otherwise, check out the Instructions section, below.

Use make_all.sh or make_ip.sh to generate IP from JSON files placed in the repo's specifications folder. Add your own spec files to this folder. The make_ip script generates a single IP from a specification file passed as its first argument and places the final product in the IP repo folder specified in the script's second argument. The make_all script runs make_ip for each specification file present in the specifications folder.

`sh ./make_all.sh ./ip_repo`

`sh ./make_ip.sh ./specifications/ExampleIp.json ./ip_repo`

Also, check out the "IP Drivers" section, below, for some more info on how to use the software drivers.

Note that the ip_repo folder also contains the vivado-library repo, with many other Digilent IP. If this is not desired, you should change the output path arguments.

## Instructions
- Download the source code for this repository, either by cloning it, or by downloading the source ZIP archive.
- Create a new specification file in the specifications folder of the repo. The examples folder contains an example which covers most of the functionality implemented by the generator.
  This example provides:
    - Two clock domains, one for the AXI interface and one for the ports
    - Two registers, one that supports read and write, and another that is read only, 
- Run the make_ip script:
  `sh ./make_ip.sh ./specifications/ExampleIp.json ./ip_repo`
- In a Vivado project that you want to use the IP in, add the ip_repo folder to the project's IP repositories
  - Click Project Manager -> Settings
  - Navigate to Project Settings -> IP -> Repository
  - Click the plus button, then navigate to the ip_repo folder and click Select
  - Click OK to confirm that your IP has been added to the project
  - Click OK to confirm the Settings changes
- Use the IP in a Vivado design, connect it up to a processor by using Connection Automation, and connect it's ports to the outside world, either by making them external, or by manually wiring them to another IP or an RTL module.
- Build your design, export an XSA file, and create a software application using it. See the "Software Drivers" section, below, for more information on how user software can access IP registers.

If you're unfamiliar, see [Getting Started with Vivado and Vitis for Baremetal Software Projects](https://digilent.com/reference/programmable-logic/guides/getting-started-with-ipi) on Digilent Reference for a more detailed walkthrough of the basic process of creating a project.

Note, a quick way to check that the generator is working correctly is to generate the ExampleIp in examples, and wire it up to a processor, and connect all of its output ports to its input ports.

## Specification Description
This section details the structure of the  JSON specifications.

In general, string fields should not use TCL special characters like [, { and whitespace.

- vendor, ip_name, version: User-defined, make up the IP's unique VLNV in Vivado.
- underscore_name: Arbitrary, a differently formatted version of the IP name used in the names of macros in the software drivers.
- fpga_part: The part number for the FPGA you want to use this IP with. (Ignorable) critical warnings are likely to appear if the IP is used with any other part.
- target_clk_period: Used to determine the target clock period of the HLS IP that the AXI4lite core is pulled out of. Unused by the final generated IP, so does not need to be changed.
- axi4lite_interface: Extra info about the interface itself
  - name: The name of the axi4lite interface port on the IP block
  - clock_domain: The name of the clock that the axi4lite interface is synchronous with
  - reserved addresses: The number of 32-bit register addresses which must be preserved for built-in functionality - user registers start above this range. In 2021.1, this must be minimum 4.
  - reset: The name of the reset port associated with the axi4lite interface.
- clocks: A list of clocks that will be provided to the IP
  - name: The name of the clock.
  - prefix: A prefix which will be applied to all of the top level IP ports associated with that clock. For example, a "Start" bitfield associated with a clock with the prefix "r" will be tied to a top level port with the name "rStart".
- registers: A list of all of the 32-bit user registers which will be implemented, in ascending order of address.
  - name: The register name, used to identify it in the software drivers.
  - access_type: "ro" or "rw", standing for read-only and read/write. Note that at the time of writing, read/write access means that values written into the register can be read back - additional IP ports are not provided.
  - bitfields: A list of the actual IP ports associated with the register. If the register is read-write, each bitfield corresponds to an input port. If the register is write-only, each bitfield corresponds to an output port.
    - name: The base name of the port. A prefix is applied to the actual port name. This name is also used in software macros describing each bitfield.
    - high_bit and low_bit: The range of bits in the register tied to that particular port. High 0 and Low 0 corresponds to a one-bit port. Bitfields in the same register should not overlap.
    - clock_domain: The name of the clock that the port is synchronous with. User logic connected to this port should also be synchronous with this clock.

## Software Drivers
The HLS core used introduces some properties of the register interface which you must be aware of when working with these software drivers. Before any read and after any write, an AP_START command must be issued to the HLS core, which will trigger the clock domain crossing mechanisms to transfer data from IP ports to the AXI interface's registers and vice versa. An "XXX_IssueApStart" function is provided in the drivers to accomplish this.

A basic read would look like:
```
IssueApStart(InstPtr);
value = IP_ReadReg(InstPtr->BaseAddr, IP_PORT_REG_OFFSET);
```

A basic write would look like:
```
IP_WriteReg(InstPtr->BaseAddr, IP_PORT_REG_OFFSET, value);
IssueApStart(InstPtr);
```

IssueApStart affects all user registers in the core, so calling it to send a new register value to hardware can inadvertently cause other registers to also be updated. This also means that in order to, for example, pull a bit high and then low again, its register must be written to twice and ApStart must be issued twice. It's recommended to use control logic with basic handshake protocols in connected HDL modules or IP to ensure that the processor won't miss relevant events.

This basic API is provided through the XXX.h header and implemented in the corresponding .c file. Register offsets and bitfield masks are provided in the XXX_hw.h header. Both of these headers are provided to software applications through a hardware platform explorted from Vivado. Base addresses are provided through xparameters.h.

## Known Issues and Potential Improvements
- Vitis HLS and shell script dependencies could be removed by implementing a template for a fully custom AXI4Lite core. This would allow the generator to be run from within Vivado.
- Access type specifications could be moved to the bitfield level instead of teh register level through the use of a custom core. The same goes for removing some of the restrictions on register addresses, and the requirement to use the ap_start mechanism to transfer data from registers to ports and vice versa.
- Multiple ports cannot currently share the same bitfield, or partially overlap their bitfields - modifying the generator to allow this in situations where only one bitfield sharing a bit provides read access to the host is possible. This would allow, for example, a read-only and a write-only port to share the same address.
- The axi4lite core does not assert error conditions when invalid accesses are performed - for example, writing to a read-only register is ignored. Throwing errors could either be added as optional or default functionality. Also requires a custom core to replace the HLS core.
- Some form of generated IP documentation would be useful
