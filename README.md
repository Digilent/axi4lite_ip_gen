# axi4lite_ip_gen
Generates simple AXI4-lite IP for use in Vivado from JSON register specifications

## Quickstart
Use make_all.sh or make_ip.sh to generate IP from JSON files placed in the repo's specifications folder. The make_ip script generates a single IP from a specification file passed as its first argument and places the final product in the IP repo folder specified in the scripts second argument. The make_all script runs make_ip for each specification file present.

`sh ./make_all.sh ./ip_repo`

`sh ./make_ip.sh ./specifications/ExampleIp.json ./ip_repo`

## Dependencies
- Vivado (tested with 2021.1) installation with bin folder on path
- Vitis HLS (tested with 2021.1) installation with bin folder on path
- Bash-compatible shell - Git for Windows includes Git Bash
  - unzip command; see https://stackoverflow.com/a/49355978 for Windows
