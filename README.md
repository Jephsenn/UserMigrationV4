<h1 align="center">UserMigrationV4</h1>
Welcome to the UserMigrationV4 script! This is a script designed to help IT technicians saving and restoring backups to and from MacOS devices. This script has the capability of saving data from a specified folder (typically the user folder) to another (can be on an external drive), and to restore data from a backup to their specified user folder (NetID). This script has several checks built into it, including confirming there is enough space on each destination directory, ensuring the machine is connected to power, and that both the source and destination directory exist. Additionally, this script will calculate progress during the transfer to give the technician a visual representation of how long to expect it to take. Pictured below is the GUI which the technician is prompted with, and some of the errors you may see while running the script.
<br><br>
This script saves and restores data using rsync. While saving data, the script will take the entire user folder and exclude 'Library/CloudStorage'. While restoring data, the script provides the technician the option to include standard library files or not, and will adjust the permissions of the transferred files.

<h2 align="center">Initial GUI:</h2>
<div align="center"><img width="712" alt="Screenshot 2024-06-11 at 1 47 21 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/92143c0c-d712-4eb8-bb5e-ab9a8e58f1b5"></div>

<h2 align="center">Before (Backup) selection:</h2>
<div align="center"><img width="712" alt="Screenshot 2024-06-11 at 1 47 40 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/ff0c3cd3-5d9b-443a-b80e-ac202bfd12c4"></div>

<h2 align="center">After (Restore) selection:</h2>
<div align="center"><img width="712" alt="Screenshot 2024-06-11 at 1 47 47 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/90047325-7bed-4b5e-8a20-42582ce239a6"></div>

<h2 align="center">Successful inputs, transfer beginning (calculating total files to be transferred):</h2>
<div align="center"><img width="727" alt="Screenshot 2024-06-11 at 1 49 18 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/1a7d5ecc-6424-466e-8515-399e0b550913"></div>

<h2 align="center">Transfer in progress:</h2>
<div align="center"><img width="1440" alt="Screenshot 2024-06-11 at 1 49 38 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/ed22f397-4478-47dd-8983-260b30ab9b49"></div>

<h2 align="center">Power Check:</h2>
<div align="center"><img width="412" alt="Screenshot 2024-06-11 at 1 47 26 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/06073bf6-e3e9-4920-b383-2bfe0d41ce67"></div>

<h2 align="center">Directory does not exist:</h2>
<div align="center"><img width="412" alt="Screenshot 2024-06-11 at 2 05 13 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/5c83324b-a5f1-4a3d-a580-fcc5e4610abb"></div>

<h2 align="center">Not enough storage:</h2>
<div align="center"><img width="412" alt="Screenshot 2024-06-11 at 2 08 53 PM" src="https://github.com/Jephsenn/UserMigrationV4/assets/77135997/c03fd4c1-7581-4cdf-ae1d-5a38c3716439"></div>
