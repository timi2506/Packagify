# Packagify

## Showcase


https://github.com/user-attachments/assets/8276d0fd-a65c-4890-a6ff-c158b58c472c


## What does this App do?
Packagify provides a simple way to create Swift Packages, you can either drop in your written Package Code or generate an Empty Package with the Informations you provide. Packagify will handle the Rest and provide you with a finished Package Configuration and Project Structure

## Where's the Download?
[Here](https://github.com/timi2506/Packagify/releases/latest)

## URL Scheme
Packagify Comes with 3 URL Schemes, you can also use "[packagify://](packagify://)" without any subpath to just open the App

### folder
Opens Packagify and imports the Folder passed

**Usage:**
 
by folderPath: packagify://folder?path=/path/to/folder
 
by folderURL: packagify://folder?url=file:///path/to/folder

### file
Opens Packagify and imports the File passed

**Usage:**

by filePath: packagify://folder?path=/path/to/file.swift

by fileURL: packagify://folder?url=file:///path/to/file.swift

### newFile
Opens Packagify and Starts with an Empty File

**Usage:**

packagify://newFile

## Requirements
macOS 14+ on an Apple Silicon or Intel Mac
