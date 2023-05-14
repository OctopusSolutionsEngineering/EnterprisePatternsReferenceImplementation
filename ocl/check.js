#!/usr/bin/env node

import {Lexer, NodeType, Parser, TokenType} from "@octopusdeploy/ocl"
import * as fs from "fs";
import * as path from "path";

const FirstStepName = "\"Manual Intervention\""
const ManualInterventionType = "\"Octopus.Manual\""

/*
    Ensure the path to the directory holding the deployment_process.ocl file was passed as an argument (with the
    other 2 arguments being the node executable itself and the name of this script file).
 */
if (process.argv.length !== 3) {
    console.log("Pass the directory holding the deployment_process.ocl file as the first argument")
    process.exit(1)
}

// Read the deployment process OCL file
fs.readFile(path.join(process.argv[2], 'deployment_process.ocl'), 'utf8', (err, data) => {
    // Any error reading the file fails the script
    if (err) {
        console.error(err)
        process.exit(1)
    }

    // These come from the @octopusdeploy/ocl dependency
    const lexer = new Lexer(data)
    const parser = new Parser(lexer)
    const ast = parser.getAST()

    // Test that we have any steps at all
    if (ast.length === 0) {
        console.log("Deployment process can not be empty")
        process.exit(1)
    }

    const firstStepName = getPropertyValue(getProperty(ast[0], "name"))

    if (!firstStepName) {
        console.log("Failed to find the name of the first step")
        process.exit(1)
    }

    if (firstStepName !== FirstStepName) {
        console.log("First step must be called " + FirstStepName + " (was " + firstStepName + ")")
        process.exit(1)
    }

    const action = getProperty(ast[0], "action")
    const actionType = getPropertyValue(getProperty(action, "action_type"))

    if (actionType !== ManualInterventionType) {
        console.log("First step must be a manual intervention step")
        process.exit(1)
    }

    console.log("All tests passed!")
    process.exit(0)
})

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

function getPropertyValue(ast) {
    if (!ast) {
        return undefined
    }

    return ast.value.value.value
}