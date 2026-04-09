// User defined variables
DefaultSavingLocation = "D:\\SuKu_RawData";

// Show dialog
Dialog.create("MFH Plugin");
Dialog.addString("Data path:", DefaultSavingLocation);
Dialog.addCheckbox("Use most recently acquired tif", true);
Dialog.addChoice("Number of channels", newArray("1", "2"), "1");
Dialog.addChoice("Number of planes", newArray("1", "2", "3", "4", "5", "6", "7", "8"), "4");
Dialog.addCheckbox("Enable Averaging", true);
Dialog.show();

DataPath = Dialog.getString();
UseMostRencet = Dialog.getCheckbox();
numChannels = parseInt(Dialog.getChoice());
numPlanes = parseInt(Dialog.getChoice());
EnableAvg = Dialog.getCheckbox();

// Open tif file
setBatchMode(true); 
if (UseMostRencet==1) {
    recentFile = getMostRecentTif(DataPath);
} else {
    dir = getDirectory(DataPath);
    recentFile = getMostRecentTif(dir);
}
setBatchMode(false);

if (numChannels==1) {
    selectWindow(recentFile);
    if (numPlanes > 1) {
        run("Deinterleave", "how=" + numPlanes);
    } else {
        rename(recentFile + " #1");
    }

    if (EnableAvg==1) {
        for (p = 1; p <= numPlanes; p++) {
            selectWindow(recentFile + " #" + p);
            run("Z Project...", "projection=[Average Intensity]");
            rename("avg_plane_" + p);
            close(recentFile + " #" + p);
        }
        combineAveragedPlanes("avg_plane_", numPlanes, "Averaged " + recentFile);
        makeMontage("Averaged " + recentFile, numPlanes);
    } else {
        combineRawPlanes(recentFile, numPlanes, "Stack " + recentFile);
        makeMontage("Stack " + recentFile, numPlanes);
    }

} else {
    selectWindow(recentFile);
    run("Deinterleave", "how=" + (2 * numPlanes));

    processChannel(recentFile, numPlanes, "Green", 1);
    processChannel(recentFile, numPlanes, "Red",   2);

    if (EnableAvg==1) {
        makeMontage("Averaged Green " + recentFile, numPlanes);
        makeMontage("Averaged Red " + recentFile, numPlanes);
    } else {
        makeMontage("Green " + recentFile, numPlanes);
        makeMontage("Red " + recentFile, numPlanes);
    }
}

// -----------------------------------------------------------------------
// Process one colour channel: average per plane if needed, then stack
// -----------------------------------------------------------------------
function processChannel(baseName, nPlanes, color, startIdx) {
    step = 2;

    if (EnableAvg==1) {
        for (p = 0; p < nPlanes; p++) {
            slotIdx = startIdx + p * step;
            selectWindow(baseName + " #" + slotIdx);
            run("Z Project...", "projection=[Average Intensity]");
            rename("avg_" + color + "_plane_" + (p+1));
            close(baseName + " #" + slotIdx);
        }
        combineAveragedPlanes("avg_" + color + "_plane_", nPlanes, "Averaged " + color + " " + baseName);
        run("Brightness/Contrast...");
        run("Enhance Contrast", "saturated=0.35");
    } else {
        combineRawPlanes2(baseName, nPlanes, startIdx, step, color + " " + baseName);
    }
}

// -----------------------------------------------------------------------
// Combine averaged single-frame images into a scrollable stack
// -----------------------------------------------------------------------
function combineAveragedPlanes(prefix, nPlanes, finalName) {
    if (nPlanes == 1) {
        selectWindow(prefix + "1");
        rename(finalName);
    } else {
        str = "open ";
        for (p = 1; p <= nPlanes; p++) {
            str += "image" + p + "=[" + prefix + p + "] ";
        }
        run("Concatenate...", str);
        rename(finalName);
    }
    run("Brightness/Contrast...");
    run("Enhance Contrast", "saturated=0.35");
}

// -----------------------------------------------------------------------
// Combine raw plane sub-stacks (single channel) into one stack
// -----------------------------------------------------------------------
function combineRawPlanes(baseName, nPlanes, finalName) {
    if (nPlanes == 1) {
        selectWindow(baseName + " #1");
        rename(finalName);
    } else {
        str = "open ";
        for (p = 1; p <= nPlanes; p++) {
            str += "image" + p + "=[" + baseName + " #" + p + "] ";
        }
        run("Concatenate...", str);
        rename(finalName);
    }
}

// -----------------------------------------------------------------------
// Combine raw plane sub-stacks (two-channel, interleaved slots)
// -----------------------------------------------------------------------
function combineRawPlanes2(baseName, nPlanes, startIdx, step, finalName) {
    if (nPlanes == 1) {
        selectWindow(baseName + " #" + startIdx);
        rename(finalName);
    } else {
        str = "open ";
        for (p = 0; p < nPlanes; p++) {
            slotIdx = startIdx + p * step;
            str += "image" + (p+1) + "=[" + baseName + " #" + slotIdx + "] ";
        }
        run("Concatenate...", str);
        rename(finalName);
    }
}

// -----------------------------------------------------------------------
// Make a montage from a stack, grid sized to fit N planes
// -----------------------------------------------------------------------
function makeMontage(windowName, nPlanes) {
    cols = Math.ceil(Math.sqrt(nPlanes));
    rows = Math.ceil(nPlanes / cols);
    selectWindow(windowName);
    run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=5");
    rename("Montage " + windowName);
}

// -----------------------------------------------------------------------
// Function to get most recently acquired tif file
// -----------------------------------------------------------------------
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
        return File.getName(recentFile);
    } else {
        exit("No .tif files found in directory");
    }
}