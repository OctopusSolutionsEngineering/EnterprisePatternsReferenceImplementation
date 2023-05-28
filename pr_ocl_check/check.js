#!/usr/bin/env node

const {Lexer, NodeType, Parser, TokenType} = require("@octopusdeploy/ocl")
const fs = require("fs")
const path =require("path")

const FirstStepName = "Manual Intervention"
const ManualInterventionType = "Octopus.Manual"

/**
 * This function performs the validation of the Octopus CaC OCL file
 * @param ocl The OCL file to parse
 * @returns {Promise<unknown>} A promise with true if the validation succeeded, and false otherwise
 */
function checkPr(ocl) {
    return new Promise((resolve, reject) => {
        // Read the deployment process OCL file
        fs.readFile(ocl, 'utf8', (err, data) => {
            // Any error reading the file fails the script
            if (err) {
                console.error(err)
                resolve(false)
                return
            }

            // These come from the @octopusdeploy/ocl dependency
            const lexer = new Lexer(data)
            const parser = new Parser(lexer)
            const steps = parser.getAST()

            // Test that we have any steps at all
            if (steps.length === 0) {
                console.log("Deployment process can not be empty")
                resolve(false)
                return
            }

            const firstStepName = getUnquotedPropertyValue(getProperty(steps[0], "name"))

            if (!firstStepName) {
                console.log("Failed to find the name of the first step")
                resolve(false)
                return
            }

            if (firstStepName !== FirstStepName) {
                console.log("First step must be called " + FirstStepName + " (was " + firstStepName + ")")
                resolve(false)
                return
            }

            const action = getBlock(steps[0], "action")
            const actionType = getUnquotedPropertyValue(getProperty(action, "action_type"))

            if (actionType !== ManualInterventionType) {
                console.log("First step must be a manual intervention step (was " + actionType + ")")
                resolve(false)
                return
            }

            console.log("All tests passed!")
            resolve(true)
        })
    })
}

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

/**
 * Returns the attribute node with the supplied name
 * @param ast The block to search
 * @param name The attribute name
 * @returns {undefined|any} The attribute node, or undefined if no match was found
 */
function getProperty(ast, name) {
    if (!ast) {
        return undefined
    }

    return ast.children
        .filter(c =>
            c.type === NodeType.ATTRIBUTE_NODE &&
            c.name.value === name)
        .pop()
}

/**
 * Returns the block node with the supplied name
 * @param ast The block to search
 * @param name The block name
 * @returns {undefined|any} The block node, or undefined if no match was found
 */
function getBlock(ast, name) {
    if (!ast) {
        return undefined
    }

    return ast.children
        .filter(c =>
            c.type === NodeType.BLOCK_NODE &&
            c.name.value === name)
        .pop()
}

/**
 * Returns the attribute node with the supplied name and value
 * @param ast The block to search
 * @param name The attribute name
 * @value name The attribute value
 * @returns {undefined|any} The attribute node, or undefined if no match was found
 */
function getPropertyWithValue(ast, name, value) {
    if (!ast) {
        return undefined
    }

    return ast.children
        .filter(c =>
            c.type === NodeType.ATTRIBUTE_NODE &&
            c.name.value === name &&
            c.value.value.value === value)
        .pop()
}


/**
 * Gets the value of the attribute node
 * @param ast The attribute node
 * @returns {undefined|*} The attribute node value, or undefined if ast was falsy or not an attribute
 */
function getPropertyValue(ast) {
    if (!ast || !ast.type === NodeType.ATTRIBUTE_NODE) {
        return undefined
    }

    return ast.value.value.value
}

/**
 * Gets the unquoted value of the attribute node
 * @param ast The attribute node
 * @returns {undefined|*} The attribute node value with surrounding quotes removed, or undefined if ast was falsy or not an attribute
 */
function getUnquotedPropertyValue(ast) {
    if (!ast || !ast.type === NodeType.ATTRIBUTE_NODE) {
        return undefined
    }

    const value = ast.value.value.value
    const result = value.match(`"(.*?)"`)

    return result === null ? value : result[1]
}

exports.checkPr = checkPr