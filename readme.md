## What is Pssdiag/Sqldiag Manager?
Pssdiag/Sqldiag Manager is a graphic interface that provides customization capabilities to collect data for SQL Server using sqldiag collector engine. The data collected can be used by [SQL Nexus tool](http://sqlnexus.codeplex.com/)  which help you troubleshoot SQL Server performance problems.  This is the same tool Microsoft SQL Server support engineers use to for data collection to troubleshoot customer's performance problems.

## Current Release
 Build 13.0.1600.32

#### **What's New**
This version support SQL Server 2016 as well previous versions
[More in wiki...](https://github.com/Microsoft/DiagManager/wiki/What's-New)

#### **Requirements**
1. Diag Manager requirements
  - Windows 7 or Windows 10 (32 or 64 bit)
  - .NET 4.5 
2. Data collection
  - The collector can only run on a machine that has SQL Server with targeted version (either client tools only or full version) installed

### **Installation**
Download it from release tab or [Click here](https://github.com/Microsoft/DiagManager/files/690279/DiagManager13.0.1600.32.zip) to download.  Source files are also included in the release tab.
### **Known Issues**
[see known issues wiki](Known Issues)

## **How to use DiagManager**
[See getting started wiki](https://github.com/Microsoft/DiagManager/wiki/Getting-Started)

## How it works
This tool lets you customize what you want to collect and then let you create a data collection package. You extract the package and run SQLdiag data collector engine on the SQL Server you are troubleshooting.

## Feature Highlights

1. **Powerful data collection capabilities: ** The tool relies on SQLdiag collector engine to provide collection of perfmon, profiler trace, msinfo32, errorlogs, Windows event logs, TSQL script output and registry exports.
2. **Default templates/scenarios** : You can choose SQL Server version and platform (32 bit or 64 bit). The tool will automatically choose a default template for the combination. This will have default set of perfmon counters, profiler traces.
3. **Shipped with ready to use Custom collectors** :  Most commonly used [custom collectors](http://diagmanager.codeplex.com/wikipage?title=Custom%20Collector)include SQL Server 2005, 2008 or 2008 R2 performance collector.
4. **Customization/Extensibility: ** You can customize what perfmon and profiler trace events you want to collect.   Additionally, you can create your own custom collectors with TSQL Scripts, batch files and utilities.   See [customization guide](http://diagmanager.codeplex.com/wikipage?title=Creating%20Custom%20Collectors).
5. **Packaging:** With a single click of save, the tool will package all your files into a single cab so that you can ship to the machine where you intend to run on.
6. **Integration with SQL Nexus** :  The custom collectors shipped will collect data that can be analyzed by [SQL Nexus Tool](http://sqlnexus.codeplex.com/).

## Common Tasks

1. [Gettting Started](https://github.com/Microsoft/DiagManager/wiki/Getting-Started):  This page tells you how to use the tool including installation, configuration and running the tool
2. [Customization guide](http://diagmanager.codeplex.com/wikipage?title=Creating%20Custom%20Collectors):  This page tells you how you can create you own custom collector to use in addition to default collectors shipped.
4. [Frequently Asked Questions (FAQ](http://diagmanager.codeplex.com/wikipage?title=FAQ)):  This page will answer most commonly asked questions.
5. [Common Issues](https://github.com/Microsoft/DiagManager/wiki/Known-Issues):  this page will document most commonly encoutered issues and errors



## License Agreement

Microsoft Public License (Ms-PL) <br/>
This license governs use of the accompanying software. If you use the software, you accept this license. If you do not accept the license, do not use the software.<br/>
1. Definitions<br/>
The terms "reproduce," "reproduction," "derivative works," and "distribution" have the same meaning here as under U.S. copyright law.<br/>
A "contribution" is the original software, or any additions or changes to the software.<br/>
A "contributor" is any person that distributes its contribution under this license.<br/>
"Licensed patents" are a contributor's patent claims that read directly on its contribution.<br/>
2. Grant of Rights<br/>
(A) Copyright Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free copyright license to reproduce its contribution, prepare derivative works of its contribution, and distribute its contribution or any derivative works that you create.<br/>
(B) Patent Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free license under its licensed patents to make, have made, use, sell, offer for sale, import, and/or otherwise dispose of its contribution in the software or derivative works of the contribution in the software.<br/>
3. Conditions and Limitations<br/>
(A) No Trademark License- This license does not grant you rights to use any contributors' name, logo, or trademarks.<br/>
(B) If you bring a patent claim against any contributor over patents that you claim are infringed by the software, your patent license from such contributor to the software ends automatically.<br/>
(C) If you distribute any portion of the software, you must retain all copyright, patent, trademark, and attribution notices that are present in the software.<br/>
(D) If you distribute any portion of the software in source code form, you may do so only under this license by including a complete copy of this license with your distribution. If you distribute any portion of the software in compiled or object code form, you may only do so under a license that complies with this license.<br/>
(E) The software is licensed "as-is." You bear the risk of using it. The contributors give no express warranties, guarantees or conditions. You may have additional consumer rights under your local laws which this license cannot change. To the extent permitted under your local laws, the contributors exclude the implied warranties of merchantability, fitness for a particular purpose and non-infringement. <br/>
