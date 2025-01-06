[Microsoft]: https://powerbi.microsoft.com/
[Azure Portal]: https://portal.azure.com/
[Azure Data Factory]: https://adf.azure.com/
[Power Automate]: https://powerautomate.microsoft.com/
[Stitch]: https://app.stitchdata.com/
[Sharepoint]: https://acesstl.sharepoint.com/sites/powerbi/Shared%20Documents/Forms/AllItems.aspx
[Bidtracer]: https://www.bidtracer.com/
[Zendesk]: https://automaticcontrols.zendesk.com/access/unauthenticated
[RegFox]: https://www.regfox.com/
[Asana]: https://app.asana.com/
[Cradlepoint]: https://accounts.cradlepointecm.com/
[Pipedrive]: https://app.pipedrive.com/auth/login
[Mailchimp]: https://login.mailchimp.com/
[Google Analytics]: https://analytics.google.com/analytics/web/
[Synchrony]: https://crn.prismhr.com/crn/auth/#/login?lang=en
[Quickbooks]: https://quickbooks.intuit.com/
[QQube]: https://clearify.com/wiki/view/6172/advanced-users-and-power-bi-developers
[Microsoft Teams]: https://www.microsoft.com/en-us/microsoft-teams/group-chat-software
[GitHub]: https://github.com/automatic-controls/powerbi
[Verizon Connect]: https://reveal.fleetmatics.com/login.aspx
[Verizon Developer Connect]: https://fim.us.fleetmatics.com/
[RClone]: https://rclone.org/onedrive/

# Power BI Documentation

- [Power BI Documentation](#power-bi-documentation)
  - [Data Flowchart](#data-flowchart)
  - [Languages](#languages)
  - [Overview](#overview)
  - [Scripts](#scripts)
    - [Stitch Integration Schedules](#stitch-integration-schedules)
    - [Script Timing Summary](#script-timing-summary)
    - [asana-ghost-clean](#asana-ghost-clean)
    - [postgresql-backup](#postgresql-backup)
    - [synchrony](#synchrony)
      - [Reports: Benefits Billing Detail, Time Sheet, Scheduled Payments](#reports-benefits-billing-detail-time-sheet-scheduled-payments)
    - [timeworksplus](#timeworksplus)
    - [qqube-sync](#qqube-sync)
    - [qqube-checker](#qqube-checker)
    - [qqube-validate](#qqube-validate)
    - [zendesk-validate](#zendesk-validate)
    - [bidtracer](#bidtracer)
    - [verizon](#verizon)
    - [regfox](#regfox)
    - [cradlepoint](#cradlepoint)
    - [cradlepoint-backup](#cradlepoint-backup)
    - [rclone-monitor](#rclone-monitor)
    - [webctrl-monitor](#webctrl-monitor)
  - [Development](#development)

## Data Flowchart

Circle nodes denote a user-facing endpoint. Cylinder nodes denote a type of data storage container. Hexagon nodes specify a data processing machanism where we have complete, fine-grained control over all steps in the procedure. Rhombus nodes indicate a data processing mechanism over which we do not have complete control. Dotted arrows represent data transfers occurring through a RESTful web API. The exception to this rule is [Quickbooks Desktop][Quickbooks] which exposes data through an SDK. However, it is our intention to migrate to [Quickbooks Online][Quickbooks] eventually, which does include a RESTful web API.

```mermaid
flowchart LR
  powerbi((Power BI\nReports))
  quickbooks((Quickbooks\nDesktop))
  asana((Asana))
  zendesk((Zendesk))
  pipedrive((Pipedrive))
  ga((Google\nAnalytics))
  mc((Mailchimp))
  excel((Excel\nSpreadsheets))
  cradlepoint((Cradlepoint))
  bidtracer((Bidtracer))
  reg_script{{Batch File\nScript}}
  sharepoint[(Sharepoint)]
  sharepoint2[(Sharepoint)]
  qq_database[(SQL Anywhere\nDatabase)]
  postgresql[(PostgreSQL\nDatabase)]
  qqube{QQube}
  stitch{Stitch}
  power_auto{{Power\nAutomate}}
  qq_dataflows{{Power BI\nDataflows}}
  qq_script{{Java Application\nScripts}}
  cradle_script{{Python Script}}
  bid_upload{{Batch File\nScript}}
  excel---->sharepoint---->powerbi-->validate>Data Validation]
  regfox((RegFox))-->reg_email{Scheduled\nEmail}-->reg_azure{{Azure Logic\nApp}}-->sharepoint
  sharepoint-->reg_script-->sharepoint
  qq_script-->validate
  quickbooks-..->qqube-->qq_database-->powerbi
  qq_database-->qq_dataflows-->powerbi
  qq_database-->qq_script-->postgresql-->powerbi
  verizon((Verizon\nConnect)) & synchrony((Synchrony))-->ver_email{Scheduled\nEmail}-->ver_azure{{Azure Logic\nApp}}-->sharepoint2-->ver_script{{Batch File\nScript}}-->postgresql
  synchrony-..->sync_java_scripts{{Java Application\nScripts}}-->postgresql
  bidtracer---->power_auto-->bid_upload-->postgresql
  cradlepoint-....->cradle_script-->postgresql
  zendesk & pipedrive & ga & mc & asana-..->stitch---->postgresql
  postgresql<==>trigger{{PL/pgSQL Trigger\nFunctions}} & process{{Java Application\nScripts}}
  asana-.->process
  process-->validate(((Data\nValidation)))
```

| Data Source | Description |
| - | - |
| [Sharepoint] | Cloud storage for Excel spreadsheets which require manual data entry |
| [Synchrony] | HR services, payroll, timecard, and insurance management |
| [Quickbooks] | Accounting software for company financial data |
| [Asana] | Task organization and planning software |
| [Bidtracer] | Sales software to track bids and proposals |
| [Zendesk] | Software to track tickets submitted by customers and technicians |
| [Pipedrive] | Sales software to track potential upcoming projects |
| [RegFox] | Software to manage customer training event registration |
| [Cradlepoint] | Network routing devices which create a VPN between remote sites and ACES |
| [Verizon Connect] | GPS tracking software to monitor ACES vehicle location and usage. |
| [Mailchimp] | Marketing software platform |
| [Google Analytics] | Analytics service which records usage statistics and web traffic on the ACES website |

## Languages

These languages are listed in approximate order of their importance. You should have a decent understanding of every language listed here if you hope to maintain and/or update the existing architecture we use for Power BI. You should also be familiar with [GitHub].

| Language | Primary Usage |
| - | - |
| [PostgreSQL PL/pgSQL](https://www.postgresql.org/docs/) | General database queries |
| [Data Analysis Expressions (DAX)](https://learn.microsoft.com/en-us/dax/) | Power BI measures |
| [Java](https://jdk.java.net/) | Desktop applications to gather, process, and organize data |
| [Power Query M Formula](https://learn.microsoft.com/en-us/powerquery-m/) | Simple data manipulation in Power BI |
| [Batch Files](https://learn.openwaterfoundation.org/owf-learn-windows-shell/) | Scripts to process and move around data |
| [Regular Expressions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet) | Parses data from text fields |
| [PowerShell](https://learn.microsoft.com/en-us/powershell/) | Scripts for operations that batch files do not support |
| [SQL Anywhere](https://help.sap.com/docs/SAP_SQL_Anywhere/93079d4ba8e44920ae63ffb4def91f5b/f3c043ea50ed48e68b1c73774e2a2608.html) | Financial database queries |
| [Python](https://www.python.org/) | Script to extract API data |
| [Markdown](https://www.markdownguide.org/) | Documentation |

## Overview

All scripts and power BI automation are based out of the **ACES-PowerBI** server. When connected to the ACES network, you can RDP into the server. Most scripts on the server are triggered using scheduled tasks.

When errors occur, scripts are typically configured to send email notifications. There are multiple places required to change the recipients of these notifications. The first place is the `error_email` variable in the *./env_vars.bat* script located at the root of this repository. The second place is in all the [Power Automate] cloud flows (*Power BI notifications forwarding* and *Bidtracer Trigger*). The third place is in all the [Power Automate] desktop flows on **ACES-PowerBI** (*Bidtracer*).

Recently, I created an email group, <pbinotify@automaticcontrols.net>, and set all locations to point to this. So you are better off just changing the members of this group to add/remove PBI notification recipients.

Most data is sent to a PostgreSQL database for processing and historical storage before Power BI reports ever touch it. I would suggest inspecting this database with [Azure Data Studio](https://azure.microsoft.com/en-us/products/data-studio/) to get familiar with its structure.

For accessing the database via command line or batch scripts, I suggest using PSQL, which can be downloaded as a stand-alone command line tool using the [PostgreSQL](https://www.postgresql.org/download/) installer. For accessing the database with a Java application, I suggest using the latest [JDBC connector](https://jdbc.postgresql.org/download/).

There is a secondary [SQL Anywhere](https://help.sap.com/docs/SAP_SQL_Anywhere) database which is only used for [Quickbooks] financial data. [QQube] synchronizes data daily from the desktop version of Quickbooks (located on **ACES-PowerBI**). This database can only be directly accessed from  **ACES-PowerBI**, so you'll have to RDP into it and use `dsn=QQubeFinancials` or `dsn=QQubeUser`. If prompted for a password, it is `Financials` and `User`, respectively for each DSN.

For convenience, there exists a Java application which synchronizes one job table in the QQube database to PostgreSQL. There are also a few [dataflows](https://learn.microsoft.com/en-us/power-bi/transform-model/dataflows/dataflows-create) which gather and preprocess particular piecees of data from the QQube database. Both of these options allow bits of the QQube database to be accessible from outside of **ACES-PowerBI**.

Note that there is a bug in Power BI when querying dataflows. The data will appear to refresh perfectly in PBI desktop, but then it will mysteriously fail when refreshed from the PBI service. The cause of this bug is a `version` tag which is automatically generated by the PBI desktop editor. This tag must be manually removed when collecting data from dataflows. See the following screenshots.

![](images/dataflow_version.png)
![](images/dataflow_no_version.png)

A few Azure logic apps are used to capture email attachments and upload them to [Sharepoint]. At which point, scheduled scripts on **ACES-PowerBI** grab the downloaded attachments with [RClone] and upload them to the PostgreSQL database. Some Excel spreadsheets are directly referenced in Power BI for data that must be manually entered. These spreadsheets typically live in [Sharepoint].

After publishing new Power BI reports, you will want to attempt to manually refresh them on the service. If any errors occur, you should go into settings to make sure the service is mapping all the data sources appropriately. Sometimes, credentials from PBI desktop do not seemlessly transfer to the service when published. Typically, you will setup all reports to have a daily scheduled refresh.

The PostgreSQL database lives on an AWS EC2 Ubuntu instance. Since Power BI does not support [client certificate authentication](https://www.postgresql.org/docs/current/auth-cert.html), all PostgreSQL queries are funneled through an [on-premises data gateway](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-onprem) located on **ACES-PowerBI**.

## Scripts

### Stitch Integration Schedules

[Stitch] is used to pull data from various RESTful web APIs into the PostgreSQL database. Stitch API requests are scheduled to occur at specific times for each data source.

| Data Source | Integration Schedule |
| - | - |
| [Asana] | Every 24 hours |
| [Zendesk] | Every 12 hours |
| [Pipedrive] | Every 12 hours |
| [Mailchimp] | Every 12 hours |
| [Google Analytics] | Disabled |

There are a few problems with the Stitch integrations. Since the Asana integration takes a long time to synchronize everything, it is on my TODO list to create a Java application which replaces this functionality. When nodes are deleted from the source, Stitch will not delete them from the database. Stitch only updates existing nodes or creates new nodes. This is most problematic for Asana, which is why I created a Java application to delete these ghost nodes from the Asana database.

### Script Timing Summary

The events shown in this table all affect **ACES-PowerBI**.

| Schedule | Script |
| - | - |
| 12:00AM Daily | [bidtracer](#bidtracer) |
| 12:30AM Daily | [asana-ghost-clean](#asana-ghost-clean) |
| 1:00AM Wednesdays | [qqube-validate](#qqube-validate) |
| 1:00AM Fridays | [zendesk-validate](#zendesk-validate) |
| 2:00AM Daily | [qqube-sync](#qqube-sync) |
| 3:00AM Daily | [timeworksplus](#timeworksplus) |
| 4:00AM Daily | [postgresql-backup](#postgresql-backup) |
| 4:30AM Daily | [cradlepoint-backup](#cradlepoint-backup) |
| 5:00AM Daily | [cradlepoint](#cradlepoint) |
| 5:30AM Daily | [qqube-checker](#qqube-checker) |
| 6:00AM Daily | [synchrony](#synchrony) |
| 7:00AM Daily | [regfox](#regfox) |
| 7:30AM Daily | [verizon](#verizon) |
| 8:00AM Daily | [rclone-monitor](#rclone-monitor) |
| 12:00PM Daily | [qqube-sync](#qqube-sync) |

### [asana-ghost-clean](./asana-ghost-clean/)

The purpose of this script is to delete ghost projects and tasks from the [Asana] schema in the PostgreSQL database.

1. A scheduled task (daily at 12:30AM) on **ACES-PowerBI** with name *script-asana-ghost-clean* executes a batch script: [*./asana-ghost-clean/exec.bat*](./asana-ghost-clean/exec.bat).
2. The batch script executes a Java application *./asana-ghost-clean/asana-ghost-clean.jar*.
3. The Java application deletes projects and tasks from the PostgreSQL database when they do not exist in [Asana] (usually indicates these items existed at one time but have since been deleted).

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./asana-ghost-clean/log.txt*.

### [postgresql-backup](./postgresql-backup/)

The purpose of this script is to backup a few important tables from the PostgreSQL database.

1. A scheduled task (daily at 4:00AM) on **ACES-PowerBI** with name *script-postgresql-backup* executes a batch script: [*./postgresql-backup/backup.bat*](./postgresql-backup/backup.bat).
2. The script exports a few tables from the PostgreSQL database as CSV files. A maximum of 5 distinct backups can be saved at the same time.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./postgresql-backup/log.txt*.

### [synchrony](./synchrony/)

The purpose of this pipeline is to gather data from [Synchrony] and upload it to the PostgreSQL database. Collected data includes payroll, employee compensation, and timecards. There are two mechanisms for retrieving data from Synchrony. The first mechanism documented here encapsulates data sent to us with scheduled emails. The second mechanism is documented in the [timeworksplus](#timeworksplus) section.

#### Reports: Benefits Billing Detail, Time Sheet, Scheduled Payments

1. <powerbi@automaticcontrols.net> typically receives three emails from Synchrony (informer@prismhr.com) for a few days every week between 4:00AM and 6:00AM. The precise schedule is related to when a payroll has been finalized, so emails could come across any day. Each email contains one report in CSV format.
2. The **synchrony-email-capture** logic app on [Azure Portal] captures emails from Synchrony with subject containing the phrase: *Scheduled Report*.
3. Attachments from captured emails are uploaded to [Sharepoint].
4. Captured emails are moved to the *deleted* mailbox.
5. A scheduled task (daily at 6:00AM) ON **ACES-PowerBI** with name *script-synchrony* executes a batch script: [*./synchrony/import.bat*](./synchrony/import.bat).
6. The batch script retrieves each attachment from [Sharepoint] using [RClone] and uploads them to the appropriate table in the PostgreSQL database: *payroll.benefits* or *payroll.compensation*. Duplicate entries are overwritten when necessary.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./synchrony/log.txt*.

### [timeworksplus](./timeworksplus/)

The purpose of this Java application script is to retrieve [Synchrony] timecard and PTO request data from the [TimeWorksPlus API](https://twpapi.payrollservers.us/swagger/ui/index#!) and upload it to the PostgreSQL database.

1. A scheduled task (daily at 3:00AM) on **ACES-PowerBI** with name *script-timeworksplus* executes a batch script: [*./timeworksplus/exec.bat*](./timeworksplus/exec.bat).
2. The batch script executes a Java application *./timeworksplus/timeworksplus.jar*.
3. The Java application queries the TimeWorksPlus API and uploads the resulting data into the PostgreSQL database.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./timeworksplus/log.txt*.

### [qqube-sync](./qqube-sync/)

The purpose of this script is to synchronize a [Quickbooks] job table from the SQL Anywhere database to the PostgreSQL database.

1. [QQube] synchronizes data from Quickbooks into the SQL Anywhere database at 2:00AM every day.
2. A scheduled task (everyday at 12:00PM) on **ACES-PowerBI** with name *script-qqube-sync* executes a batch script: [*./qqube-sync/exec.bat*](./qqube-sync/exec.bat).
3. The batch script executes a Java application *./qqube-sync/qqube-sync.jar*.
4. The Java application copies data from `QQubeUser.vd_Job` in the SQL Anywhere database to `quickbooks.jobs` in the PostgreSQL database using last-modified timestamps to determine what needs updating.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./qqube-sync/log.txt*.

### [qqube-checker](./qqube-checker/)

The purpose of this script is to send an email notification when [QQube] fails to synchronize [Quickbooks] to the SQL Anywhere database.

1. QQube is supposed to synchronize data from Quickbooks into the SQL Anywhere database at 2:00AM every day.
2. A scheduled task (everyday at 5:30AM) on **ACES-PowerBI** with name *script-qqube-checker* executes a batch script: [*./qqube-checker/exec.bat*](./qqube-checker/exec.bat).
3. The batch script executes a Java application *./qqube-checker/qqube-checker.jar*.
4. The Java application checks whether a successful QQube sync has occurred in the last 9.5 hours, corresponding to 8:00PM of the previous night.
5. If a successful sync has not occurred, the batch script sends out an email notification alerting IT that a manual sync needs to be initiated.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./qqube-checker/log.txt*.

### [qqube-validate](./qqube-validate/)

The purpose of this script is to verify job numbers and custom fields are typed into [Quickbooks] correctly.

1. A scheduled task (every Wednesday at 1:00AM) on **ACES-PowerBI** with name *script-qqube-validate* executes a batch script: [*./qqube-validate/exec.bat*](./qqube-validate/exec.bat).
2. The batch script executes a Java application *./qqube-validate/qqube-validate.jar*.
3. The Java application inspects the SQL Anywhere database for any jobs that do not meet validation requirements. These bad jobs are printed to the standard output stream. Afterwards, control is returned to the batch script.
4. The batch script redirects the standard output stream from the Java application to *./qqube-validate/log.txt*. If any bad jobs exist or any errors occur, the batch script sends email notifications with *./qqube-validate/log.txt* as an attachment.

### [zendesk-validate](./zendesk-validate/)

The purpose of this script is to ensure job numbers are typed into [Zendesk] tickets correctly. Zendesk ticket numbers are cross-validated against data from [Quickbooks].

1. A scheduled task (every Friday at 1:00AM) on **ACES-PowerBI** with name *script-zendesk-validate* executes a batch script: [*./zendesk-validate/exec.bat*](./zendesk-validate/exec.bat).
2. The batch script executes a Java application *./zendesk-validate/zendesk-validate.jar*.
3. The Java application queries a list of Quickbooks jobs and Zendesk tickets from the PostgreSQL database. A list of bad tickets (if any exist) is emailed to <dstclair@automaticcontrols.net> and <zdhom@automaticcontrols.net>.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./zendesk-validate/log.txt*.

Eventually, the intention is that bad tickets will be emailed to their creators. Emailing the entire list to Desiree and Zach is a temporary configuration to verify that all expectations are met.

### [bidtracer](./bidtracer/)

The purpose of this script is to gather data from [Bidtracer] and upload it to the PostgreSQL database. Collected data includes a list of awarded bids with contract prices and estimated hours separated by category.

1. A [Power Automate] cloud flow (*Bidtracer Trigger*) initiates a power automate desktop flow (*Bidtracer*) daily at 12:00AM.
2. The desktop flow navigates to <https://www.bidtracer.com/> and downloads XLSX report files.
3. The desktop flow initiates a batch script: [*./bidtracer/import.bat*](./bidtracer/import.bat).
4. The batch script converts the XLSX files to the CSV format and uploads them to the PostgreSQL database.
5. PostgreSQL triggers are invoked on insertion to delete duplicate rows: [*./bidtracer/trigger.sql*](./bidtracer/trigger.sql).

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./bidtracer/log.txt*.

### [verizon](./verizon/)

The purpose of this script is to gather data from [Verizon Connect] and upload it to the PostgreSQL database. Collected data includes GPS ping locations on ACES vehicles (taken every 30 seconds). Additionally, safety violations such as speeding and hard-braking are recorded.

1. <powerbi@automaticcontrols.net> receives four emails from Verizon (no-reply@verizonconnect.com) everyday between 4:00AM and 6:00AM. Each email contains one report in CSV format. Each report corresponds to one table in the PostgreSQL database: *movements*, *speeding*, *incidents*, and *services*.
2. The **verizon-email-capture** logic app on [Azure Portal] captures emails from Verizon with subject containing the phrase: *Scheduled Report*.
3. Attachments from captured emails are uploaded to [Sharepoint].
4. Captured emails are moved to the *deleted* mailbox.
5. A scheduled task (daily at 7:30AM) ON **ACES-PowerBI** with name *script-verizon* executes a batch script: [*./verizon/import.bat*](./verizon/import.bat).
6. The batch script retrieves the attachments from [Sharepoint] using [RClone] and uploads them to the appropriate table in the PostgreSQL database.
7. PostgreSQL triggers are invoked to delete duplicate rows: [*./verizon/trigger.sql*](./verizon/trigger.sql).

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./verizon/log.txt*.

### [regfox](./regfox/)

[RegFox] is software used to manage customer training event registration. The data we get from here is essentially a list of customers and employees with the classes they are registered to attend.

1. <powerbi@automaticcontrols.net> receives an email from RegFox (noreply@webconnex.com) every day a little after 6:00AM.
2. The **regfox-email-capture** logic app on [Azure Portal] captures emails from RegFox with subject: *Your RegFox Report Is Ready For Download*.
3. The body of the email is uploaded to [Sharepoint].
4. The captured email is moved to the *deleted* mailbox.
5. A scheduled task (daily at 7:00AM) on **ACES-PowerBI** with name *script-regfox* executes a batch script: [*./regfox/import.bat*](./regfox/import.bat).
6. The script retrieves the email body from [Sharepoint] using [RClone].
7. The script uses *PowerShell* ([*./regfox/parse.ps1*](./regfox/parse.ps1)) to retrieve a download URL from *./regfox/body.html*.
8. The script uses [*Curl 7.84.0*](https://curl.se/windows/) to download a CSV document from the URL.
9. The CSV document is uploaded to [Sharepoint] using [RClone].
10. The script deletes *./regfox/body.html*.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./regfox/log.txt*.

### [cradlepoint](./cradlepoint/)

The purpose of this script is to move data from the [Cradlepoint API](https://developer.cradlepoint.com/) into the PostgreSQL database.

1. A scheduled task (daily at 5:00AM) on **ACES-PowerBI** with name *script-cradlepoint* executes a batch script: [*./cradlepoint/exec.bat*](./cradlepoint/exec.bat).
2. The batch script executes a Python script: [*./cradlepoint/\_\_init\_\_.py*](./cradlepoint/__init__.py).
3. The  Python script queries data from the [Cradlepoint] API and inserts it into the PostgreSQL database.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./cradlepoint/log.txt*. In the past, this script has failed when Cradlepoint adds new columns to their API. The solution for this type of error is to add the missing columns to the appropriate tables in the PostgreSQL database.

### [cradlepoint-backup](./cradlepoint-backup/)

The purpose of this script is to backup active Cradlepoint router and group configurations.

1. A scheduled task (daily at 4:30AM) on **ACES-PowerBI** with name *script-cradlepoint-backup* executes a batch script: [*./cradlepoint-backup/exec.bat*](./cradlepoint-backup/exec.bat).
2. The batch script executes a PowerShell script, [*./cradlepoint-backup/backup.ps1*](./cradlepoint-backup/backup.ps1), which downloads router and group configurations from the [Cradlepoint API]((https://developer.cradlepoint.com/)) using [Curl](https://curl.se/).
3. A Java utility, *jar.exe*, is used to compress the JSON configurations into a ZIP file.
4. [RClone] is used to upload the ZIP file to Dropbox with 365 day backup retention.

If an error occurs at any step in the process, the batch script is configured to send email notifications. Detailed error information can be found in *./cradlepoint-backup/log.txt*.

### [rclone-monitor](./rclone-monitor/)

The purpose of this script is to ensure rclone backups continue to function as expected.

1. A scheduled task (daily at 8:00AM) on **ACES-PowerBI** with name *script-rclone-monitor* executes a batch script: [*./rclone-monitor/exec.bat*](./rclone-monitor/exec.bat).
2. The batch script checks a number of Dropbox folders using [RClone] to see if any zip files exist with a last-modified date sometime in the previous 2 days.
3. If recent zip file backups do not exist, then an email notification is sent.

### [webctrl-monitor](./webctrl-monitor/)

The purpose of this script is to continuously monitor webservers for uptime, and send email notifications when a webservers goes online or offline. This is primarily used to monitor WebCTRL servers, but a few other websites are tracked as well. A scheduled task named *script-webctrl-monitor* starts this script on system startup on **ACES-PowerBI**. Events are logged to *./webctrl-monitor/log.txt*.

## Development

This section describes a few prerequisites for getting the scripts in this repository to function correctly. Some scripts may not work outside of **ACES-PowerBI** at all, but others could have partial functionality. The location of this repository on **ACES-PowerBI** is *C:\ACES\scripts*.

1. Clone this repository to your computer.
2. Install the latest [JDK](https://jdk.java.net/), [PSQL](https://www.postgresql.org/download/), [Curl](https://curl.se/windows/), [RClone](https://rclone.org/downloads/), [Python](https://www.python.org/downloads/), and [PowerShell](https://github.com/PowerShell/PowerShell).
3. Ensure the *./bin* folder of each installation is added to your *PATH* environment variable. Also set the *JAVA_HOME* environment variable.
4. Install the Python [requests](https://pypi.org/project/requests/) and [psycopg2](https://pypi.org/project/psycopg2/) packages with *pip*.
5. Create a batch file *./env_vars.bat* in the root of this repository. Populate it with the required credentials. An example is shown below.

```bat
set "lib=%~dp0lib"
set "attempts=3"
set "pbi_email=pbi@email.com"
set "pbi_password=12345678"
set "error_email=abcdefghijk@amer.teams.ms;username@automaticcontrols.net"
set "postgresql_url=postgresql.database.net"
set "postgresql_port=5432"
set "postgresql_database=postgres"
set "postgresql_user=username"
set "postgresql_pass=12345678"
set "asana_token=1/1111111111:ffffffffffffff"
set "twp_api_secret=abcdefghijklmnopqrstuvwxyz012346789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
set "twp_site_id=000000"
set "X_CP_API_ID=234dg58723"
set "X_CP_API_KEY=b724bvsnfdcxy7y473e84c3bt68bw6ntfr34"
set "X_ECM_API_ID=n7c34ybbc-3chsgtbuytgfrvbeuy-4v5hr75hvjdf"
set "X_ECM_API_KEY=nbghregbuyfgebu43c8745ynt8nf85t43y8nf654"
```

4. Execute [*./collect.bat*](./collect.bat) to download required dependencies.
5. After making changes to source code, run the build script for each Java application script as necessary.

| Build Script |
| - |
| [*./asana-ghost-clean/build.bat*](./asana-ghost-clean/build.bat) |
| [*./qqube-checker/build.bat*](./qqube-checker/build.bat) |
| [*./qqube-sync/build.bat*](./qqube-sync/build.bat) |
| [*./qqube-validate/build.bat*](./qqube-validate/build.bat) |
| [*./zendesk-validate/build.bat*](./zendesk-validate/build.bat) |