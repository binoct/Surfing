# Surfing

<h1 align="center">
  <img src="./folder/logo.svg" alt="BOXMETA" width="200">
  <br>BOXMETA<br>
</h1>

<h3 align="center">Magisk, Kernelsu, APatch</h3>

<div align="center">
    <a href="https://github.com/MoGuangYu/Surfing/releases/tag/Prerelease-Alpha">
        <img alt="Android" src="https://img.shields.io/badge/Module Latestsnapshot-F05033.svg?logo=android&logoColor=white">
    </a>
    <a href="https://github.com/MoGuangYu/Surfing/releases">
    <img alt="Downloads" src="https://img.shields.io/github/downloads/MoGuangYu/Surfing/total?label=Module%20Download&labelColor=00b56a&logo=git&logoColor=white">
</a>
</div>
<br>
<div align="center">
    <strong>English</strong> | <a href="./README_CN.md">简体中文</a>
</div>

---

This project is a [Magisk](https://github.com/topjohnwu/Magisk), [Kernelsu](https://github.com/tiann/KernelSU), [APatch](https://github.com/bmax121/APatch) module for Clash/mihomo, sing-box, v2ray, xray, hysteria. It supports REDIRECT (TCP only), TPROXY (TCP + UDP) transparent proxy, TUN (TCP + UDP), and hybrid mode REDIRECT (TCP) + TUN (UDP) proxy.

Based on upstream integration for one-stop service, ready to use. Suitable for:
- Lazy people
- Beginners

The project's theme and configuration focus on [Clash/mihomo.Meta](https://github.com/MetaCubeX/Clash.Meta).

This module needs to be used in a Magisk/Kernelsu environment. If you don't know how to configure the required environment, you might need applications like ClashForAndroid, v2rayNG, surfboard, SagerNet, AnXray.

# Surfing User Declaration and Disclaimer

Welcome to use Surfing. Before using this project, please carefully read and understand the following statements and disclaimers. By using this project, you agree to accept the following terms and conditions. Hereinafter referred to as **Surfing**.

## Disclaimer

1. **This project is an open-source project for learning and research purposes only and does not provide any form of guarantee. Users must bear full responsibility for the risks and consequences of using this project.**

2. **This project is only for the convenience of simplifying the installation and configuration of Surfing for Clash services in the Android Magisk environment. It does not make any guarantees about the functionality and performance of Surfing. The developer of this project is not responsible for any problems or losses.**

3. **The use of this projects Surfing module may violate the laws and regulations of your region or the terms of service of service providers. You need to bear the risks of using this project on your own. The developer of this project is not responsible for your actions or the consequences of use.**

4. **The developer of this project is not responsible for any direct or indirect losses or damages resulting from the use of this project, including but not limited to data loss, device damage, service interruption, personal privacy leaks, etc.**

## Instructions for Use

1. **Before using the Surfing module, please make sure you have carefully read and understood the usage instructions and related documents of Clash and Magisk and comply with their rules and terms.**

2. **Before using this project, back up your device data and related settings to prevent unexpected situations. The developer of this project is not responsible for your data loss or damage.**

3. **Please comply with local laws and regulations and respect the legitimate rights and interests of other users when using this project. It is forbidden to use this project for illegal, abusive, or infringing activities.**

4. **If you encounter any problems or have any suggestions when using this project, you are welcome to provide feedback to the developer of this project, but the developer is not obligated to resolve issues or respond to feedback.**

Please decide whether to use the Surfing module only after clearly understanding and accepting the above statements and disclaimers. If you do not agree or cannot accept the above terms, please stop using this project immediately.

## Applicable Law

**During the use of this project, you must comply with the laws and regulations of your region. In case of any disputes, interpretation and resolution should be carried out in accordance with local laws and regulations.**

## Installation

- Download the module zip file from the [Release](https://github.com/MoGuangYu/Surfing/releases) page and install it via Magisk Manager, KernelSU Manager, or APatch.
- Version changes: [📲log](changelog.md)

## Uninstallation

- Uninstall the module from the Magisk Manager, Kernelsu Manager, or APatch application. [👉🏻Removal Command](https://github.com/MoGuangYu/Surfing/blob/main/uninstall.sh#L3-L4)

## Wiki

<details>
<summary>1. First Use</summary>

- After installing the module, no need to restart the device. You can use `Toolbox` to integrate and refresh the client update status.
- After installation is complete, add your subscription address to `config.yaml` and restart the module service via the switch.
- Due to network reasons, all **rules**/**subscriptions** may not be downloaded automatically. Please manually refresh in the panel.
  - If the above fails, ensure your network environment is normal.
- Web App:
  - It is only a graphical auxiliary tool used for portable browsing and managing the backend route data, with no other unnecessary uses.

> The module has a built-in GUI that can be accessed locally via a browser or used online via the app. There is essentially no difference between the two.

</details>

#

<details>
<summary>2. Controlling Operation</summary>  

- Can be controlled via **WiFi SSID** network toggling  
- Use the module switch to enable/disable the service in real time  
- Add a control switch to the system status bar
  
<img src="./folder/KAKJFS.jpg" alt="KJFS" width="300">

[Download Apk](https://www.coolapk.com/apk/com.coolapk.market) | [Copy URL](https://raw.githubusercontent.com/MoGuangYu/Surfing/main/folder/KJFSURL.md)

<img src="./folder/BJZDY.jpg" alt="KJFS" width="300">

- Enter Settings

<img src="./folder/WLDR.jpg" alt="KJFS" width="300">

- Import URL

<img src="./folder/CTSZ.jpg" alt="KJFS" width="300">

- Add a custom tile to the status bar

</details>

#

<details>
<summary>3. Routing Rules</summary>  

GitHub Actions automatically builds updates at 6 AM Beijing time every day to ensure the latest rules. [Wiki](https://github.com/MetaCubeX/meta-rules-dat)  

> Routing rules use online links and update automatically every 24 hours.

</details>

#

<details>
<summary>4. Future Updates</summary>  

- If you use all the default configurations, updates will be seamless.  
- The module supports online updates within the client. After updating, no reboot is required; however, the module switch's enable/disable control ~~may temporarily not work and still require a reboot~~ or can be updated via Toolbox.  
- During updates, the configuration file will be backed up to:  
   - `config.yaml.bak`  
- During updates, the old user configuration files will be backed up to:  
   - `box.config.bak`  
- During updates, your subscription URLs will be automatically extracted and backed up to:  
   - `subscribe_urls_backup.txt`  
   - The backup will be automatically extracted and restored into the new configuration, applicable when using the default configuration file.  
- The module update does NOT include:  
   - Geo database files  
   - Binary files  
   - Web resources  

> Note: Updates mainly follow upstream changes and distribute some configurations.

</details>

#

<details>
<summary>5. Usage Issues</summary>

1. Proxy Specific Applications (Black/Whitelist)
- To proxy all applications except certain ones, open the `/data/adb/box_bll/scripts/box.config` file, set the `proxy_mode` value to `blacklist` (default), and add elements to the `user_packages_list` array. The format for elements is `id:package_name`, separated by spaces. For example, `user_packages_list=("id:package_name" "id:package_name")` to **not proxy** specific Android user applications.

- To only proxy specific applications, open the `/data/adb/box_bll/scripts/box.config` file, set the `proxy_mode` value to `whitelist`, and add elements to the `user_packages_list` array. The format for elements is `id:package_name`, separated by spaces. For example, `user_packages_list=("id:package_name" "id:package_name")` to **only proxy** specific Android user applications.

Android user group ID identifiers:

| Standard User | ID  |
| ------------- | --- |
| Owner         |  0  |
| Second Space  |  10 |
| App Clone     | 999 |

> Typically, you can find all user group IDs and application package names in `/data/user/`. Do not use fake-ip mode when using black/whitelist.

2. Tun Mode
- Enabled by default

> It is recommended to keep it enabled. It can be disabled if not needed, but do not use black/white lists when this mode is enabled.

3. Routing Rules
- Bypass mainland China
- It basically meets the needs of most daily usage.

> Black/whitelist is not significant unless strictly required. The module's built-in configuration is sufficient.

4. Panel Management
- Magisk Font Module

> May affect normal display of page fonts.

5. LAN Sharing
- Enable hotspot to allow other devices to connect.

> For other devices to access the console backend, just use (http://currentWiFigateway:9090/ui).

</details>

---

<a href="./LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/MoGuangYu/Surfing.svg">
</a>

## Acknowledgments

<a href="https://github.com/CHIZI-0618">
  <p align="center">
    <img src="https://github.com/CHIZI-0618.png" width="100" height="100" alt="CHIZI-0618">
    <br>
    <strong>CHIZI-0618</strong>
  </p>
</a>

<div align="center">
  <a href="https://github.com/MetaCubeX"><strong>MetaCubeX</strong></a>
</div>

<div align="center">
  <a href="https://github.com/Loyalsoldier"><strong>Loyalsoldier</strong></a>
</div>
<div align="center">
  <p> > Thanks for providing valuable foundation for the implementation of this project. < </p>
</div>
