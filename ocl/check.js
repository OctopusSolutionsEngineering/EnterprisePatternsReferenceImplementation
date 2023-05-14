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

    // Test that the first step has the correct name
    const name = ast[0].children.filter(c =>
        c.type === NodeType.ATTRIBUTE_NODE &&
        c.name.value === "name")

    if (name.length === 0) {
        console.log("Failed to find the name of the first step")
        process.exit(1)
    }

    if (name[0].value.value.value !== FirstStepName) {
        console.log("First step must be called " + FirstStepName + " (was " + name[0].value.value.value + ")")
        process.exit(1)
    }

    // Test that the first step is of the correct type
    let foundManualIntervention = false
    for (const block of ast[0].children) {
        if (block.name.value === "action") {
            for (const actionBlock of block.children) {
                if (actionBlock.name.value === "action_type" &&
                    actionBlock.value.value.value === ManualInterventionType) {
                    foundManualIntervention = true
                    break
                }
            }
        }
    }

    if (!foundManualIntervention) {
        console.log("First step must be a manual intervention step")
        process.exit(1)
    }

    console.log("All tests passed!")
    process.exit(0)
})

function blockEquals(a, b) {
    if (a.type !== NodeType.BLOCK_NODE || b.type !== NodeType.BLOCK_NODE) {
        return false
    }

    if (a.name.type !== b.name.type) {
        return false
    }

    if (a.name.value !== b.name.value) {
        return false
    }

    if (a.children.length !== b.children.length) {
        return false
    }

    for (let i = 0; i < a.children.length; ++i) {
        if (a.children[i].type === NodeType.BLOCK_NODE) {
            if (!blockEquals(a.children[i], b.children[i])) {
                return false
            }
        }

        if (a.children[i].type === NodeType.ATTRIBUTE_NODE) {
            if (!attributeEquals(a.children[i], b.children[i])) {
                return false
            }
        }
    }
}

function attributeEquals(a, b) {
    if (a.type !== NodeType.ATTRIBUTE_NODE || b.type !== NodeType.ATTRIBUTE_NODE) {
        return false
    }

    if (a.name.type !== b.name.type) {
        return false
    }

    if (a.name.value !== b.name.value) {
        return false
    }

    if (a.value.value.value !== b.value.value.value) {
        return false
    }

    return true
}