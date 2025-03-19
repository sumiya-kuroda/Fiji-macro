// User defined variables
DefaultSavingLocation = "C:\\Users\\Sumiya\\Desktop\\demo";

// Show dialog
Dialog.create("MFH TurboReg Plugin");
Dialog.addString("Data path:", DefaultSavingLocation);
Dialog.addCheckbox("Use most recently acquired tif", true);
Dialog.addCheckbox("Enable Averaging", true);
Dialog.addCheckbox("Enable Turbo Reg", false);
Dialog.show();

DataPath = Dialog.getString();
UseMostRencet = Dialog.getCheckbox();
EnableAvg = Dialog.getCheckbox();
EnableReg = Dialog.getCheckbox();

// Print selected options
setBatchMode(true); 
if (UseMostRencet==1) {
	recentFile = getMostRecentTif(DataPath);
}else{
	dir = getDirectory(DataPath);
	recentFile = getMostRecentTif(dir);
}
setBatchMode(false); 

// Averaging
if (EnableAvg==1) {
    selectWindow(recentFile);	
    run("Z Project...", "projection=[Average Intensity]");
    run("Brightness/Contrast...");
    run("Enhance Contrast", "saturated=0.35");
    rename("Averaged " + recentFile);
    close(recentFile);
}else{
}

// Function to get most recently acquired tif file
function getMostRecentTif(directory) {
    list = getFileList(directory);
    if (list.length == 0) {
        exit("No files found in directory");
    }
    
    recentFile = "";
    recentTime = 0;
    
    for (i = 0; i < list.length; i++) {
        if (endsWith(list[i], ".tif")) {
            filePath = directory + File.separator + list[i];
            fileTime = File.lastModified(filePath);
            
            if (fileTime > recentTime) {
                recentTime = fileTime;
                recentFile = filePath;
            }
        }
    }
    
    if (recentFile != "") {
        showStatus("Opening most recently acquired tif file now ...");
        opt = "open=[" + recentFile + "] windowless=true autoscale view=Hyperstack";
        run("Bio-Formats Importer", opt);
        // open(recentFile);

	    return File.getName(recentFile)
    } else {
        exit("No .tif files found in directory");
    }
}