# zabbix server on centos

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjinyan2049%2Fmyazuretemplate%2Fmaster%2Fzabbix-server-centos-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a><a  target="_blank">


Built by: [jinyan2049](https://github.com/jinyan2049)

This template allows you to deploy a simple Linux VM using a few different options for the CentOS Linux version, using the latest patched version. This will deploy in East ASIA on a D3 VM Size.

Below are the parameters that the template expects:

| Name   | Description    |
|:--- |:---|
| newStorageAccountName  | Unique DNS Name for the Storage Account where the Virtual Machine's disks will be placed. |
| adminUsername  | Username for the Virtual Machine  |
| adminPassword  | Password for the Virtual Machine  |
| dnsNameForPublicIP  | Unique DNS Name for the Public IP used to access the Virtual Machine. |
| centosOSVersion  | The Ubuntu version for the VM. This will pick a fully patched image of this given CentOS version. Allowed values: 6.5, 6.6, 6.7, 7.0, 7.1 |
