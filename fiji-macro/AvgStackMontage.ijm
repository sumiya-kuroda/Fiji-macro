// -----------------------------------------------------------------------
// AvgStackMontage
//
// Reads the most recent tif file from your saving location and produces
// a tiled montage image showing all N planes in a single window.
// Each plane sub-stack is averaged independently before tiling.
// Does NOT produce a scrollable stack.
// TurboReg motion correction is NOT implemented yet (too slow for quick check).
// -----------------------------------------------------------------------

// User defined variables
DefaultSavingLocation = "D:\\SuKu_RawData";

// Show dialog
Dialog.create("AvgStackMontage");
Dialog.addString("Data path:", DefaultSavingLocation);
Dialog.addCheckbox("Use most recently acquired tif", true);
Dialog.addChoice("Number of channels", newArray("1", "2"), "1");
Dialog.addChoice("Number of planes", newArray("1", "2", "3", "4", "5", "6", "7", "8"), "4");
Dialog.show();

DataPath = Dialog.getString();
UseMostRencet = Dialog.getCheckbox();
numChannels = parseInt(Dialog.getChoice());
numPlanes = parseInt(Dialog.getChoice());

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

    // Average each plane sub-stack
    for (p = 1; p <= numPlanes; p++) {
        selectWindow(recentFile + " #" + p);
        run("Z Project...", "projection=[Average Intensity]");
        rename("avg_plane_" + p);
        close(recentFile + " #" + p);
    }

    // Make montage directly from averaged planes
    makeMontageFromAveraged("avg_plane_", numPlanes, "Montage " + recentFile);

} else {
    selectWindow(recentFile);
    run("Deinterleave", "how=" + (2 * numPlanes));

    // Green: odd slots (1, 3, 5, ...)
    for (p = 0; p < numPlanes; p++) {
        slotIdx = 1 + p * 2;
        selectWindow(recentFile + " #" + slotIdx);
        run("Z Project...", "projection=[Average Intensity]");
        rename("avg_green_plane_" + (p+1));
        close(recentFile + " #" + slotIdx);
    }
    makeMontageFromAveraged("avg_green_plane_", numPlanes, "Montage Green " + recentFile);

    // Red: even slots (2, 4, 6, ...)
    for (p = 0; p < numPlanes; p++) {
        slotIdx = 2 + p * 2;
        selectWindow(recentFile + " #" + slotIdx);
        run("Z Project...", "projection=[Average Intensity]");
        rename("avg_red_plane_" + (p+1));
        close(recentFile + " #" + slotIdx);
    }
    makeMontageFromAveraged("avg_red_plane_", numPlanes, "Montage Red " + recentFile);
}

// -----------------------------------------------------------------------
// Average individual plane images into a temporary stack then make montage
// -----------------------------------------------------------------------
function makeMontageFromAveraged(prefix, nPlanes, finalName) {
    if (nPlanes == 1) {
        selectWindow(prefix + "1");
        run("Enhance Contrast", "saturated=0.35");
        rename(finalName);
    } else {
        // Concatenate averaged planes into a temporary stack
        str = "open ";
        for (p = 1; p <= nPlanes; p++) {
            str += "image" + p + "=[" + prefix + p + "] ";
        }
        run("Concatenate...", str);
        run("Enhance Contrast", "saturated=0.35");

        // Make montage then close the temporary stack
        cols = Math.ceil(Math.sqrt(nPlanes));
        rows = Math.ceil(nPlanes / cols);
        run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=5");
        rename(finalName);

        // Close the temporary concatenated stack
        close("Untitled");
    }
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