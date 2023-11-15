#!/usr/bin/env node

const {parseOclWrapper} = require("@octopusdeploy/ocl/dist/wrapper")
const fs = require("fs")
const path =require("path")
const {expect} = require("expect");

// This is the entry point when the file is run by Node.js
if (require.main === module) {
    /*
        Ensure the path to the directory holding the deployment_process.ocl file was passed as an argument (with the
        other 2 arguments being the node executable itself and the name of this script file).
    */
    if (process.argv.length !== 3) {
        console.log("Pass the directory holding the deployment_process.ocl file as the first argument")
        process.exit(1)
    }

    checkPr(path.join(process.argv[2], 'deployment_process.ocl'))
        .then(result => {
            process.exit(result ? 0 : 1)
        })
}

exports.checkPr = checkPr

/**
 * This function performs the validation of the Octopus CaC OCL file
 * @param ocl The OCL file to parse
 * @returns {Promise<unknown>} A promise with true if the validation succeeded, and false otherwise
 */
function checkPr(ocl) {
    // Read the file
    const fileContents = fs.readFileSync(ocl, 'utf-8')
    // Parse the file
    const deploymentProcess = parseOclWrapper(fileContents)

    // Verify the contents
    expect(deploymentProcess.step).not.toHaveLength(0)
    expect(deploymentProcess.step[0].name).toBe("Manual Intervention")
    expect(deploymentProcess.step[0].action[0].action_type).toBe("Octopus.Manual")
}