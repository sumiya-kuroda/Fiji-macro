// User defined variables
DefaultSavingLocation = "C:\\Users\\Sumiya\\Desktop\\demo";

// Show dialog
Dialog.create("MFH TurboReg Plugin");
Dialog.addString("Data path:", DefaultSavingLocation);
Dialog.addCheckbox("Use most recently acquired tif", true);
Dialog.addChoice("Number of channels", newArray("1", "2"), "1")
Dialog.addCheckbox("Enable Averaging", true);
Dialog.addToSameRow()
Dialog.addCheckbox("Enable Turbo Reg", false);
Dialog.show();

DataPath = Dialog.getString();
UseMostRencet = Dialog.getCheckbox();
numChannels = parseInt(Dialog.getChoice()); // TODO: allow this to be set by user or auto-detected
EnableAvg = Dialog.getCheckbox();
EnableReg = Dialog.getCheckbox();

// Open tif file
setBatchMode(true); 
if (UseMostRencet==1) {
	recentFile = getMostRecentTif(DataPath);
}else{
	dir = getDirectory(DataPath);
	recentFile = getMostRecentTif(dir);
}
setBatchMode(false); 
if (numChannels==1) {
    selectWindow(recentFile);
}else{
    selectWindow(recentFile);	
    run("Deinterleave", "how=2");
}

// Averaging
if (EnableAvg==1) {
    if (numChannels==1) {
        selectWindow(recentFile);	
        run("Z Project...", "projection=[Average Intensity]");
        run("Brightness/Contrast...");
        run("Enhance Contrast", "saturated=0.35");
        rename("Averaged " + recentFile);
    }else{
        selectWindow(recentFile + " #1");	
        run("Z Project...", "projection=[Average Intensity]");
        run("Brightness/Contrast...");
        run("Enhance Contrast", "saturated=0.35");
        rename("Averaged Green " + recentFile);

        selectWindow(recentFile + " #2");
        run("Z Project...", "projection=[Average Intensity]");
        run("Brightness/Contrast...");
        run("Enhance Contrast", "saturated=0.35");
        rename("Averaged Red " + recentFile);
    }
}else{
}

// TurboReg

// Clear unnecessary figures
if (numChannels==1) {
    close(recentFile);
}else{
    close(recentFile + " #1");
    close(recentFile + " #2");
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